package jobs

import (
	"context"
	"crypto/sha256"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"log/slog"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/fsnotify/fsnotify"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/riverqueue/river"
	"github.com/riverqueue/river/rivertype"

	"github.com/mediarr-app/mediarr/server/db"
)

const (
	externalScanTick    = time.Hour
	externalScanTimeout = 12 * time.Hour
	// ExternalSettleTime waits out a whole folder being copied, which fires many events.
	ExternalSettleTime = 30 * time.Second
	maxScanError       = 500
)

var externalMedia = map[string]bool{
	".jpg": true, ".jpeg": true, ".png": true, ".heic": true, ".heif": true, ".webp": true, ".gif": true,
	".tif": true, ".tiff": true, ".avif": true, ".jxl": true, ".mp4": true, ".mov": true, ".m4v": true, ".mkv": true,
	".avi": true, ".webm": true, ".3gp": true, ".mts": true, ".m2ts": true,
}

// isExternalMedia decides what a scan looks at. Hidden files, such as ".DS_Store", are left alone.
func isExternalMedia(path string) bool {
	if strings.HasPrefix(filepath.Base(path), ".") {
		return false
	}
	return externalMedia[strings.ToLower(filepath.Ext(path))] || isRaw(path)
}

// ExternalScanArgs looks through the external library for changes.
type ExternalScanArgs struct {
	// Scheduled goes by the administrator's interval. A scan asked for by hand always runs.
	Scheduled bool `json:"scheduled,omitempty"`
}

// Kind identifies the job in the queue.
func (ExternalScanArgs) Kind() string { return "external_scan" }

// InsertOpts keeps a single scan at a time.
func (ExternalScanArgs) InsertOpts() river.InsertOpts {
	return river.InsertOpts{UniqueOpts: river.UniqueOpts{ByArgs: true, ByState: []rivertype.JobState{
		rivertype.JobStateAvailable, rivertype.JobStatePending, rivertype.JobStateRetryable,
		rivertype.JobStateRunning, rivertype.JobStateScheduled,
	}}}
}

type externalScanWorker struct {
	river.WorkerDefaults[ExternalScanArgs]
	*deps
}

func (w *externalScanWorker) Timeout(*river.Job[ExternalScanArgs]) time.Duration {
	return externalScanTimeout
}

func (w *externalScanWorker) Work(ctx context.Context, job *river.Job[ExternalScanArgs]) error {
	library, err := w.queries.GetExternalLibrary(ctx)
	if db.IsNotFound(err) {
		return nil
	}
	if err != nil {
		return err
	}
	if job.Args.Scheduled && library.ScanFinishedAt.Valid {
		settings, err := LoadServerSettings(ctx, w.queries)
		if err != nil {
			return err
		}
		if !scanIsDue(library.ScanFinishedAt.Time, settings.ExternalScanHours, time.Now()) {
			return nil
		}
	}
	if err := w.queries.StartExternalScan(ctx, library.ID); err != nil {
		return err
	}
	result, scanErr := ScanExternal(ctx, w.pool, w.queries, &library, func(ctx context.Context, tx pgx.Tx, id uuid.UUID) error {
		_, err := w.client().InsertTx(ctx, tx, MetadataArgs{AssetID: id}, nil)
		return err
	})
	slog.Info("external library scanned", "added", result.Added, "moved", result.Moved, "changed", result.Changed,
		"same_content", result.SameContent, "missing", result.Missing, "unchanged", result.Unchanged)
	message := pgtype.Text{}
	if scanErr != nil {
		message = pgtype.Text{String: truncate(scanErr.Error(), maxScanError), Valid: true}
	}
	// Background, because a stopped worker must still be able to say the scan did not finish.
	return w.queries.FinishExternalScan(context.WithoutCancel(ctx), db.FinishExternalScanParams{ID: library.ID, ScanError: message})
}

// ScanResult counts what a scan did.
type ScanResult struct {
	Added, Moved, Changed, SameContent, Missing, Unchanged int
}

type foundFile struct {
	size  int64
	mtime time.Time
}

// walkExternal lists the media files. complete is false if part of the tree could not be read, and
// then nothing can be said about what is missing.
func walkExternal(root string) (found map[string]foundFile, complete bool, err error) {
	if _, err := os.ReadDir(root); err != nil {
		return nil, false, fmt.Errorf("read the external library: %w", err)
	}
	found = map[string]foundFile{}
	complete = true
	err = filepath.WalkDir(root, func(path string, entry fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			slog.Warn("part of the external library cannot be read", "path", path, "error", walkErr)
			complete = false
			if entry != nil && entry.IsDir() {
				return filepath.SkipDir
			}
			return nil
		}
		// Links are not followed: they could lead out of the library, or around in a circle.
		if !entry.Type().IsRegular() || !isExternalMedia(path) {
			return nil
		}
		info, err := entry.Info()
		if err != nil {
			complete = false
			return nil //nolint:nilerr // One unreadable file must not stop the scan.
		}
		found[path] = foundFile{size: info.Size(), mtime: info.ModTime()}
		return nil
	})
	return found, complete, err
}

func hashFile(path string) ([]byte, error) {
	file, err := os.Open(path) //nolint:gosec // Found by walking the library.
	if err != nil {
		return nil, err
	}
	defer func() { _ = file.Close() }()
	hash := sha256.New()
	if _, err := io.Copy(hash, file); err != nil {
		return nil, err
	}
	return hash.Sum(nil), nil
}

// ScanExternal brings the database in line with the folder, which it only ever reads. queue starts
// the processing of a new asset, in the same transaction that records it.
func ScanExternal(
	ctx context.Context, pool beginner, q *db.Queries, library *db.Library,
	queue func(ctx context.Context, tx pgx.Tx, id uuid.UUID) error,
) (ScanResult, error) {
	var result ScanResult
	found, complete, err := walkExternal(library.Path.String)
	if err != nil {
		return result, err
	}
	rows, err := q.ListExternalFiles(ctx, library.ID)
	if err != nil {
		return result, err
	}
	known := make(map[string]foundFile, len(rows))
	for i := range rows {
		known[rows[i].Path] = foundFile{size: rows[i].SizeBytes, mtime: rows[i].Mtime.Time}
	}
	for path, file := range found {
		if err := ctx.Err(); err != nil {
			return result, err
		}
		before, seen := known[path]
		if seen && before.size == file.size && before.mtime.Equal(file.mtime.Truncate(time.Microsecond)) {
			result.Unchanged++
			continue
		}
		if err := scanFile(ctx, pool, q, library, path, file, found, queue, &result); err != nil {
			if ctx.Err() != nil {
				return result, ctx.Err()
			}
			// A file being copied right now, for example. The next scan tries it again.
			slog.Warn("a file in the external library was skipped", "path", path, "error", err)
			complete = false
			delete(found, path)
		}
	}
	return result, markMissing(ctx, q, library.ID, found, complete, &result)
}

func scanFile(
	ctx context.Context, pool beginner, q *db.Queries, library *db.Library, path string, file foundFile,
	found map[string]foundFile, queue func(ctx context.Context, tx pgx.Tx, id uuid.UUID) error, result *ScanResult,
) error {
	sum, err := hashFile(path)
	if err != nil {
		return err
	}
	mtime := pgtype.Timestamptz{Time: file.mtime, Valid: true}
	return pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		qtx := q.WithTx(tx)
		if err := qtx.UpsertExternalFile(ctx, db.UpsertExternalFileParams{LibraryID: library.ID, Path: path, SizeBytes: file.size, Mtime: mtime}); err != nil {
			return err
		}
		existing, err := qtx.FindAssetByChecksum(ctx, db.FindAssetByChecksumParams{UserID: library.UserID, Checksum: sum})
		if err == nil {
			_, stillThere := found[existing.OriginalPath]
			if existing.LibraryID == library.ID && !stillThere && existing.OriginalPath != path {
				result.Moved++
				return qtx.MoveExternalAsset(ctx, db.MoveExternalAssetParams{ID: existing.ID, OriginalPath: path, OriginalName: filepath.Base(path)})
			}
			result.SameContent++
			return nil
		}
		if !db.IsNotFound(err) {
			return err
		}
		// New content at a known path: the file was edited in place.
		current, err := qtx.FindExternalAssetByPath(ctx, db.FindExternalAssetByPathParams{LibraryID: library.ID, OriginalPath: path})
		switch {
		case err == nil:
			if err := qtx.ReplaceExternalContent(ctx, db.ReplaceExternalContentParams{ID: current, Checksum: sum, SizeBytes: file.size}); err != nil {
				return err
			}
			result.Changed++
			return queue(ctx, tx, current.Bytes)
		case !db.IsNotFound(err):
			return err
		}
		id, err := qtx.InsertExternalAsset(ctx, db.InsertExternalAssetParams{
			UserID: library.UserID, LibraryID: library.ID, Checksum: sum, OriginalName: filepath.Base(path),
			OriginalPath: path, SizeBytes: file.size, CreatedAt: mtime,
		})
		if err != nil {
			return err
		}
		result.Added++
		return queue(ctx, tx, id.Bytes)
	})
}

// markMissing only flags a record: the disk may just be unplugged, and everything is back on the
// next scan. If part of the folder could not be read, nothing is flagged.
func markMissing(ctx context.Context, q *db.Queries, library pgtype.UUID, found map[string]foundFile, complete bool, result *ScanResult) error {
	rows, err := q.ListExternalAssetPaths(ctx, library)
	if err != nil {
		return err
	}
	var gone, back []pgtype.UUID
	for i := range rows {
		_, there := found[rows[i].OriginalPath]
		switch {
		case there && rows[i].MissingAt.Valid:
			back = append(back, rows[i].ID)
		case !there && complete && !rows[i].MissingAt.Valid:
			gone = append(gone, rows[i].ID)
		}
		if !there && complete {
			result.Missing++
		}
	}
	if err := q.ClearAssetsMissing(ctx, back); err != nil {
		return err
	}
	return q.SetAssetsMissing(ctx, gone)
}

// WatchExternal calls changed once things settle after a change in the folder. It is only a faster
// way to notice: on a network share no events arrive, and the periodic scan finds the changes there.
func WatchExternal(ctx context.Context, root string, settle time.Duration, changed func()) error {
	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		return err
	}
	defer func() { _ = watcher.Close() }()
	watchTree(watcher, root)

	timer := time.NewTimer(settle)
	timer.Stop()
	for {
		select {
		case <-ctx.Done():
			return nil
		case event, ok := <-watcher.Events:
			if !ok {
				return nil
			}
			if event.Has(fsnotify.Create) {
				if info, err := os.Lstat(event.Name); err == nil && info.IsDir() {
					watchTree(watcher, event.Name)
				}
			}
			timer.Reset(settle)
		case err, ok := <-watcher.Errors:
			if !ok {
				return nil
			}
			slog.Warn("watching the external library", "error", err)
		case <-timer.C:
			changed()
		}
	}
}

// watchTree is best effort: past the system's limit on watches, the periodic scan still works.
func watchTree(watcher *fsnotify.Watcher, root string) {
	err := filepath.WalkDir(root, func(path string, entry fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			return nil //nolint:nilerr // What cannot be read cannot be watched.
		}
		if entry.IsDir() {
			return watcher.Add(path)
		}
		return nil
	})
	if err != nil && !errors.Is(err, fs.SkipAll) {
		slog.Warn("the external library is only partly watched; the periodic scan still finds changes", "error", err)
	}
}

// IsExternalAvailable says whether a folder was given in the install's settings.
func IsExternalAvailable(root string) bool {
	info, err := os.Stat(root)
	return err == nil && info.IsDir()
}

// scanIsDue says whether the administrator's interval has passed since the last scan.
func scanIsDue(finished time.Time, hours int, now time.Time) bool {
	return now.Sub(finished) >= time.Duration(hours)*time.Hour
}
