package jobs

import (
	"archive/zip"
	"bufio"
	"context"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"os"
	"path"
	"path/filepath"
	"strings"
	"syscall"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/riverqueue/river"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/storage"
)

const (
	exportQueue = "export"
	// ExportPartLimit is the most a ZIP part holds, unless one file alone is larger.
	ExportPartLimit = 10 << 30
	// Finished parts wait 7 days to be downloaded: FinishExport sets when they go.
	exportSlice    = 6 * time.Hour
	exportPage     = 200
	exportPlanRows = 1000
	exportCheck    = 2 * time.Second
	// ExportMetadataName is the file with everything Mediarr knows about the library.
	ExportMetadataName = "mediarr-export.json"
	exportFormat       = "mediarr-export"
	exportVersion      = 1
	exportOriginals    = "originals"
	exportAlbums       = "albums"
	maxAlbumDepth      = 20
	// The most a ZIP file adds for one entry, beyond its name twice: the local header, the data
	// descriptor and the central directory entry, each with room for ZIP64 sizes.
	zipEntryOverhead = 200
	zipCentralEntry  = 46 + 28
	zipEndOverhead   = 22 + 56 + 20
	statusRunning    = "running"
	statusCancelled  = "cancelled"
)

// ExportArgs builds the ZIP parts of an export of a whole library.
type ExportArgs struct {
	ExportID uuid.UUID `json:"export_id"`
}

// Kind identifies the job in the queue.
func (ExportArgs) Kind() string { return "export" }

// InsertOpts gives exports a queue of their own, so that one never waits behind an import.
func (ExportArgs) InsertOpts() river.InsertOpts { return river.InsertOpts{Queue: exportQueue} }

type exportWorker struct {
	river.WorkerDefaults[ExportArgs]
	*deps
}

// Timeout is above exportSlice, because the job pauses itself between parts before it would run out.
func (w *exportWorker) Timeout(*river.Job[ExportArgs]) time.Duration {
	return exportSlice + 2*time.Hour
}

var errExportStopped = errors.New("the export was cancelled")

// errExportRefused is what trying again cannot fix.
type errExportRefused struct{ message string }

func (e *errExportRefused) Error() string { return e.message }

func (w *exportWorker) Work(ctx context.Context, job *river.Job[ExportArgs]) error {
	id := toPG(job.Args.ExportID)
	finished, err := runExport(ctx, w.deps, id, 0, time.Now().Add(exportSlice))
	var refused *errExportRefused
	switch {
	case err == nil && finished:
		return nil
	case err == nil:
		// A long export goes on in a new run, from the last finished part, without using up attempts.
		return river.JobSnooze(time.Second)
	case errors.Is(err, errExportStopped):
		return nil
	case errors.As(err, &refused):
		return w.queries.FinishExport(context.WithoutCancel(ctx), db.FinishExportParams{ID: id, Status: statusFailed, LastError: refused.message})
	case ctx.Err() == nil && job.Attempt >= maxAttempts:
		removeExportFiles(w.opts.CachePath, id)
		return w.queries.FinishExport(context.WithoutCancel(ctx), db.FinishExportParams{
			ID: id, Status: statusFailed, LastError: truncate(err.Error(), maxImportError),
		})
	}
	return err
}

// ExportOnce builds at most parts parts of an export (all of them when parts is 0) and says whether
// it is finished. The worker runs it; tests stop it part way, as a restart would.
func ExportOnce(ctx context.Context, pool *pgxpool.Pool, opts Options, id uuid.UUID, parts int) (bool, error) {
	d := &deps{pool: pool, queries: db.New(pool), opts: opts}
	return runExport(ctx, d, toPG(id), parts, time.Time{})
}

// ExportDir is where the parts of an export wait in the cache.
func ExportDir(cache string, id pgtype.UUID) string {
	return filepath.Join(cache, "exports", uuidString(id))
}

// ExportPartPath is where one finished part is.
func ExportPartPath(cache string, id pgtype.UUID, number int32) string {
	return filepath.Join(ExportDir(cache, id), fmt.Sprintf("part-%03d.zip", number))
}

func removeExportFiles(cache string, id pgtype.UUID) {
	if err := os.RemoveAll(ExportDir(cache, id)); err != nil {
		slog.Warn("the parts of an export could not be removed", "export", uuidString(id), "error", err)
	}
}

// CleanExports removes the parts of exports that were finished a week ago, and anything in the
// cache that belongs to no export that is running or waiting to be downloaded.
func CleanExports(ctx context.Context, q *db.Queries, cache string, now time.Time) error {
	expired, err := q.ListExpiredExports(ctx, pgtype.Timestamptz{Time: now, Valid: true})
	if err != nil {
		return err
	}
	for _, id := range expired {
		removeExportFiles(cache, id)
		if err := q.DeleteExportParts(ctx, id); err != nil {
			return err
		}
		if err := q.ExpireExport(ctx, id); err != nil {
			return err
		}
	}
	kept, err := q.ListKeptExports(ctx)
	if err != nil {
		return err
	}
	keep := map[string]bool{}
	for _, id := range kept {
		keep[uuidString(id)] = true
	}
	entries, err := os.ReadDir(filepath.Join(cache, "exports"))
	if errors.Is(err, os.ErrNotExist) {
		return nil
	}
	if err != nil {
		return err
	}
	for _, entry := range entries {
		if !keep[entry.Name()] {
			if err := os.RemoveAll(filepath.Join(cache, "exports", entry.Name())); err != nil {
				return err
			}
		}
	}
	return nil
}

type exportRun struct {
	*deps
	row     db.GetExportRow
	dir     string
	limit   int64
	part    *exportPart
	next    int32
	done    db.ExportDoneRow
	checked time.Time
}

// runExport goes on from the last finished part. It returns false when it stopped after maxParts parts
// or at the deadline, to be run again.
func runExport(ctx context.Context, d *deps, id pgtype.UUID, maxParts int, deadline time.Time) (bool, error) {
	row, err := d.queries.GetExport(ctx, id)
	if db.IsNotFound(err) {
		return true, nil
	}
	if err != nil {
		return false, err
	}
	if row.Status != statusRunning {
		if row.Status == statusCancelled {
			removeExportFiles(d.opts.CachePath, id)
		}
		return true, nil
	}
	run := &exportRun{deps: d, row: row, dir: ExportDir(d.opts.CachePath, id), limit: d.opts.ExportPartLimit}
	if run.limit <= 0 {
		run.limit = ExportPartLimit
	}
	if err := os.MkdirAll(run.dir, 0o750); err != nil {
		return false, &errExportRefused{"the cache folder cannot be written: " + err.Error()}
	}
	if !row.PlannedAt.Valid {
		if err := run.plan(ctx); err != nil {
			return false, err
		}
	}
	if err := run.resume(ctx); err != nil {
		return false, err
	}
	defer run.abandon()

	built := 0
	cursor := pgtype.UUID{Valid: true}
	for {
		files, err := d.queries.ListPendingExportFiles(ctx, db.ListPendingExportFilesParams{ExportID: id, AssetID: cursor, Limit: exportPage})
		if err != nil {
			return false, err
		}
		if len(files) == 0 {
			break
		}
		for i := range files {
			file := &files[i]
			cursor = file.AssetID
			if err := run.check(ctx, false); err != nil {
				return false, err
			}
			source, err := run.open(file)
			if err != nil {
				return false, err
			}
			cost := source.cost(file.Path)
			if run.part != nil && run.part.entries > 0 && run.part.size()+cost > run.limit {
				if err := run.closePart(ctx); err != nil {
					source.close()
					return false, err
				}
				built++
				if (maxParts > 0 && built >= maxParts) || (!deadline.IsZero() && time.Now().After(deadline)) {
					source.close()
					return false, nil
				}
			}
			err = run.add(ctx, file, source)
			source.close()
			if err != nil {
				return false, err
			}
		}
	}
	if err := run.finish(ctx); err != nil {
		return false, err
	}
	return true, nil
}

// plan names every file once, so that a restart puts each where it was going to be.
func (r *exportRun) plan(ctx context.Context) error {
	rows, err := r.queries.ListExportCandidates(ctx, db.ListExportCandidatesParams{UserID: r.row.UserID, CreatedAt: r.row.CreatedAt})
	if err != nil {
		return err
	}
	names := exportNames{}
	ids := make([]pgtype.UUID, 0, len(rows))
	paths := make([]string, 0, len(rows))
	var files int32
	var bytes int64
	for i := range rows {
		name := ""
		if !rows[i].External {
			name = names.place(rows[i].LocalAt.Time, rows[i].OriginalName)
			files++
			bytes += rows[i].SizeBytes
		}
		ids = append(ids, rows[i].ID)
		paths = append(paths, name)
	}
	return pgx.BeginFunc(ctx, r.pool, func(tx pgx.Tx) error {
		q := r.queries.WithTx(tx)
		for start := 0; start < len(ids); start += exportPlanRows {
			end := min(start+exportPlanRows, len(ids))
			if err := q.AddExportFiles(ctx, db.AddExportFilesParams{ExportID: r.row.ID, AssetIds: ids[start:end], Paths: paths[start:end]}); err != nil {
				return err
			}
		}
		return q.PlanExport(ctx, db.PlanExportParams{ID: r.row.ID, TotalFiles: files, TotalBytes: bytes})
	})
}

// exportNames gives each original a path of its own: by the month it was taken, under its own name,
// and IMG_1 (2).jpg for the second IMG_1.jpg of that month. Names are compared without case, so
// that they stay apart on Windows and macOS too.
type exportNames map[string]int

func (n exportNames) place(when time.Time, original string) string {
	folder := path.Join(exportOriginals, when.Format("2006"), when.Format("01"))
	name := storage.SafeName(original)
	ext := path.Ext(name)
	stem := strings.TrimSuffix(name, ext)
	candidate := name
	for count := 1; ; count++ {
		if count > 1 {
			candidate = fmt.Sprintf("%s (%d)%s", stem, count, ext)
		}
		// A sidecar is the name with .xmp after it, so that name is taken as well.
		key := strings.ToLower(folder + "/" + candidate)
		if n[key] == 0 && n[key+".xmp"] == 0 {
			n[key]++
			n[key+".xmp"]++
			return folder + "/" + candidate
		}
	}
}

// resume forgets a part that was being written when the worker stopped.
func (r *exportRun) resume(ctx context.Context) error {
	if err := r.queries.ForgetUnfinishedExportParts(ctx, r.row.ID); err != nil {
		return err
	}
	entries, err := os.ReadDir(r.dir)
	if err != nil {
		return err
	}
	for _, entry := range entries {
		if strings.HasSuffix(entry.Name(), ".partial") {
			if err := os.Remove(filepath.Join(r.dir, entry.Name())); err != nil {
				return err
			}
		}
	}
	parts, err := r.queries.ListExportParts(ctx, r.row.ID)
	if err != nil {
		return err
	}
	r.next = 1
	if len(parts) > 0 {
		r.next = parts[len(parts)-1].Number + 1
	}
	if r.done, err = r.queries.ExportDone(ctx, r.row.ID); err != nil {
		return err
	}
	return r.progress(ctx)
}

func (r *exportRun) progress(ctx context.Context) error {
	return r.queries.SetExportProgress(ctx, db.SetExportProgressParams{
		ID: r.row.ID, DoneFiles: r.done.Files, DoneBytes: r.done.Bytes, Missing: r.done.Missing,
	})
}

// check stops when the export was cancelled, and tells how far it has come, every few seconds.
func (r *exportRun) check(ctx context.Context, now bool) error {
	if !now && time.Since(r.checked) < exportCheck {
		return nil
	}
	r.checked = time.Now()
	status, err := r.queries.GetExportStatus(ctx, r.row.ID)
	if db.IsNotFound(err) {
		return errExportStopped
	}
	if err != nil {
		return err
	}
	if status != statusRunning {
		r.abandon()
		removeExportFiles(r.opts.CachePath, r.row.ID)
		return errExportStopped
	}
	return r.progress(ctx)
}

// exportSource is an original and its sidecar, opened. original is nil for a file that is gone.
type exportSource struct {
	original    *os.File
	sidecar     *os.File
	modified    time.Time
	size        int64
	sidecarSize int64
}

// cost is what the original and its sidecar add to a part, with their entries in the ZIP file.
func (s *exportSource) cost(name string) int64 {
	if s.original == nil {
		return 0
	}
	cost := entryCost(name, s.size)
	if s.sidecar != nil {
		cost += entryCost(name+".xmp", s.sidecarSize)
	}
	return cost
}

// entryCost is a file in a ZIP part: its data, its headers and its line in the central directory.
func entryCost(name string, size int64) int64 {
	return size + 2*int64(len(name)) + zipEntryOverhead
}

func (s *exportSource) close() {
	for _, f := range []*os.File{s.original, s.sidecar} {
		if f != nil {
			_ = f.Close()
		}
	}
}

// open reads only inside the owner's own folders of the library, and follows no link: whatever the
// database says, nothing else ends up in the export.
func (r *exportRun) open(file *db.ListPendingExportFilesRow) (*exportSource, error) {
	owner := uuidString(file.UserID)
	source := &exportSource{}
	original, info, err := openInside(filepath.Join(r.opts.LibraryPath, owner), file.OriginalPath)
	if err != nil {
		slog.Warn("an original was left out of an export", "asset", uuidString(file.AssetID), "error", err)
		return source, nil
	}
	source.original, source.modified, source.size = original, info.ModTime(), info.Size()
	if file.SidecarPath != "" {
		sidecar, info, err := openInside(filepath.Join(storage.SidecarDir(r.opts.LibraryPath), owner), file.SidecarPath)
		if err == nil {
			source.sidecar = sidecar
			source.sidecarSize = info.Size()
		}
	}
	return source, nil
}

func openInside(root, name string) (*os.File, os.FileInfo, error) {
	cleaned := filepath.Clean(name)
	rel, err := filepath.Rel(root, cleaned)
	if err != nil || rel == ".." || strings.HasPrefix(rel, ".."+string(filepath.Separator)) || filepath.IsAbs(rel) {
		return nil, nil, fmt.Errorf("%s is outside %s", cleaned, root)
	}
	f, err := os.OpenFile(cleaned, os.O_RDONLY|syscall.O_NOFOLLOW, 0) //nolint:gosec // Checked to be inside the owner's folder.
	if err != nil {
		return nil, nil, err
	}
	info, err := f.Stat()
	if err != nil || !info.Mode().IsRegular() {
		_ = f.Close()
		return nil, nil, fmt.Errorf("%s is not a file", cleaned)
	}
	return f, info, nil
}

// add puts one original and its sidecar in the part being written.
func (r *exportRun) add(ctx context.Context, file *db.ListPendingExportFilesRow, source *exportSource) error {
	if r.part == nil {
		part, err := newExportPart(r.dir, r.next)
		if err != nil {
			return err
		}
		r.part = part
	}
	packed := exportPacked{id: file.AssetID, missing: source.original == nil}
	if source.original != nil {
		if err := r.part.copy(ctx, file.Path, source.modified, source.original); err != nil {
			return err
		}
		if source.sidecar != nil {
			if err := r.part.copy(ctx, file.Path+".xmp", source.modified, source.sidecar); err != nil {
				return err
			}
			packed.sidecar = true
		}
		r.done.Files++
	} else {
		r.done.Missing++
	}
	r.done.Bytes += file.SizeBytes
	r.part.files = append(r.part.files, packed)
	return nil
}

// closePart finishes the part being written and records it with its files, in one go.
func (r *exportRun) closePart(ctx context.Context) error {
	part := r.part
	size, err := part.finish()
	if err != nil {
		return err
	}
	written := int32(0)
	for _, file := range part.files {
		if !file.missing {
			written++
		}
	}
	err = pgx.BeginFunc(ctx, r.pool, func(tx pgx.Tx) error {
		q := r.queries.WithTx(tx)
		if err := markExportFiles(ctx, q, r.row.ID, part.files, pgtype.Int4{Int32: part.number, Valid: true}); err != nil {
			return err
		}
		return q.AddExportPart(ctx, db.AddExportPartParams{ExportID: r.row.ID, Number: part.number, SizeBytes: size, Files: written})
	})
	if err != nil {
		return err
	}
	r.part = nil
	r.next++
	return r.check(ctx, true)
}

// markExportFiles records which files have a sidecar and which were gone, and the part they are in;
// without a part, the files stay to be packed again after a restart.
func markExportFiles(ctx context.Context, q *db.Queries, id pgtype.UUID, files []exportPacked, part pgtype.Int4) error {
	ids := make([]pgtype.UUID, len(files))
	sidecars := make([]bool, len(files))
	missing := make([]bool, len(files))
	for i, file := range files {
		ids[i], sidecars[i], missing[i] = file.id, file.sidecar, file.missing
	}
	return q.MarkExportFiles(ctx, db.MarkExportFilesParams{Part: part, ExportID: id, AssetIds: ids, Sidecars: sidecars, Missing: missing})
}

// abandon drops a part that was not finished.
func (r *exportRun) abandon() {
	if r.part != nil {
		r.part.discard()
		r.part = nil
	}
}

// finish adds what Mediarr knows about the library to the last part, and closes it.
func (r *exportRun) finish(ctx context.Context) error {
	if err := r.check(ctx, true); err != nil {
		return err
	}
	// The metadata says which files of the last part have a sidecar.
	if r.part != nil {
		if err := markExportFiles(ctx, r.queries, r.row.ID, r.part.files, pgtype.Int4{}); err != nil {
			return err
		}
	}
	tmp := filepath.Join(r.dir, ExportMetadataName+".partial")
	manifests, err := r.writeMetadata(ctx, tmp)
	defer func() { _ = os.Remove(tmp) }()
	if err != nil {
		return err
	}
	info, err := os.Stat(tmp)
	if err != nil {
		return err
	}
	cost := entryCost(ExportMetadataName, info.Size()) + entryCost("README.txt", int64(len(exportReadme)))
	for _, manifest := range manifests {
		cost += entryCost(manifest.path, int64(len(manifest.data)))
	}
	if r.part != nil && r.part.entries > 0 && r.part.size()+cost > r.limit {
		if err := r.closePart(ctx); err != nil {
			return err
		}
	}
	if r.part == nil {
		if r.part, err = newExportPart(r.dir, r.next); err != nil {
			return err
		}
	}
	now := time.Now()
	metadata, err := os.Open(tmp) //nolint:gosec // Written just now, in the export's own folder.
	if err != nil {
		return err
	}
	err = r.part.copy(ctx, ExportMetadataName, now, metadata)
	_ = metadata.Close()
	if err != nil {
		return err
	}
	for _, manifest := range manifests {
		if err := r.part.write(manifest.path, now, manifest.data); err != nil {
			return err
		}
	}
	if err := r.part.write("README.txt", now, []byte(exportReadme)); err != nil {
		return err
	}
	if err := r.closePart(ctx); err != nil {
		return err
	}
	return pgx.BeginFunc(ctx, r.pool, func(tx pgx.Tx) error {
		q := r.queries.WithTx(tx)
		if err := q.FinishExport(ctx, db.FinishExportParams{ID: r.row.ID, Status: statusDone}); err != nil {
			return err
		}
		// The list of files was needed only while the parts were made.
		return q.ForgetExportFiles(ctx, r.row.ID)
	})
}

const exportReadme = `This is an export of a Mediarr library.

Unpack every part of it into the same folder. Then:

  originals/YYYY/MM/   every photo and video as it was uploaded, by the month it was taken,
                       with its XMP sidecar beside it (photo.jpg.xmp) when Mediarr made one.
  albums/<album>/      album.json lists the files of the album, as paths from this folder, so
                       that no photo is in the export twice.
  mediarr-export.json  everything Mediarr knows: dates, places, descriptions, ratings, picks,
                       favourites, tags, people and their faces, albums and edits.

Edits are listed, not applied: the originals are as they were uploaded.
`

// exportPart is one ZIP file being written. It is stored, not compressed, as photos and videos are.
type exportPart struct {
	number int32
	tmp    string
	final  string
	file   *os.File
	buffer *bufio.Writer
	count  *countingWriter
	zip    *zip.Writer
	files  []exportPacked
	// entries and central count the files in the ZIP and the size of the directory at its end.
	entries int
	central int64
}

type exportPacked struct {
	id      pgtype.UUID
	sidecar bool
	missing bool
}

type countingWriter struct {
	w io.Writer
	n int64
}

func (c *countingWriter) Write(p []byte) (int, error) {
	n, err := c.w.Write(p)
	c.n += int64(n)
	return n, err
}

func newExportPart(dir string, number int32) (*exportPart, error) {
	final := filepath.Join(dir, fmt.Sprintf("part-%03d.zip", number))
	tmp := final + ".partial"
	f, err := os.OpenFile(tmp, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0o640) //nolint:gosec // The export's own folder.
	if err != nil {
		return nil, err
	}
	buffer := bufio.NewWriterSize(f, 1<<20)
	count := &countingWriter{w: buffer}
	return &exportPart{number: number, tmp: tmp, final: final, file: f, buffer: buffer, count: count, zip: zip.NewWriter(count)}, nil
}

// size is what the part comes to if it is closed now: what was written, the central directory and
// its end.
func (p *exportPart) size() int64 {
	// The ZIP writer keeps a little back until it is flushed.
	_ = p.zip.Flush()
	return p.count.n + p.central + zipEndOverhead
}

func (p *exportPart) header(name string, modified time.Time) *zip.FileHeader {
	p.entries++
	p.central += zipCentralEntry + int64(len(name))
	header := &zip.FileHeader{Name: name, Method: zip.Store, Modified: modified}
	header.SetMode(0o644)
	return header
}

func (p *exportPart) copy(ctx context.Context, name string, modified time.Time, from io.Reader) error {
	entry, err := p.zip.CreateHeader(p.header(name, modified))
	if err != nil {
		return err
	}
	_, err = io.Copy(entry, &contextReader{ctx: ctx, r: from})
	return err
}

func (p *exportPart) write(name string, modified time.Time, data []byte) error {
	entry, err := p.zip.CreateHeader(p.header(name, modified))
	if err != nil {
		return err
	}
	_, err = entry.Write(data)
	return err
}

// finish closes the ZIP file and puts it in place, durably, before it is recorded.
func (p *exportPart) finish() (int64, error) {
	if err := p.zip.Close(); err != nil {
		p.discard()
		return 0, err
	}
	if err := p.buffer.Flush(); err != nil {
		p.discard()
		return 0, err
	}
	if err := p.file.Sync(); err != nil {
		p.discard()
		return 0, err
	}
	if err := p.file.Close(); err != nil {
		_ = os.Remove(p.tmp)
		return 0, err
	}
	if err := os.Rename(p.tmp, p.final); err != nil {
		_ = os.Remove(p.tmp)
		return 0, err
	}
	return p.count.n, nil
}

func (p *exportPart) discard() {
	_ = p.file.Close()
	_ = os.Remove(p.tmp)
}

// contextReader stops a long copy when the worker shuts down.
type contextReader struct {
	ctx context.Context //nolint:containedctx // Checked on every read of a copy.
	r   io.Reader
}

func (c *contextReader) Read(p []byte) (int, error) {
	if err := c.ctx.Err(); err != nil {
		return 0, err
	}
	return c.r.Read(p)
}

// --- What the export says about the library ---

type exportManifest struct {
	path string
	data []byte
}

type exportOwner struct {
	Name  string `json:"name"`
	Email string `json:"email"`
}

type exportPerson struct {
	ID        string  `json:"id"`
	Name      string  `json:"name"`
	BirthDate *string `json:"birthDate,omitempty"`
	Hidden    bool    `json:"hidden"`
}

type exportPlace struct {
	City    string `json:"city,omitempty"`
	State   string `json:"state,omitempty"`
	Country string `json:"country,omitempty"`
}

type exportCamera struct {
	Make  string `json:"make,omitempty"`
	Model string `json:"model,omitempty"`
	Lens  string `json:"lens,omitempty"`
}

// exportBox is a face, from 0 to 1 across and down the picture as Mediarr shows it.
type exportBox struct {
	X1 float32 `json:"x1"`
	Y1 float32 `json:"y1"`
	X2 float32 `json:"x2"`
	Y2 float32 `json:"y2"`
}

type exportFace struct {
	PersonID *string `json:"personId"`
	Person   string  `json:"person,omitempty"`
	// Box is null when the preview the face was found on is gone.
	Box *exportBox `json:"box"`
}

type exportAsset struct {
	ID            string          `json:"id"`
	File          *string         `json:"file"`
	Sidecar       *string         `json:"sidecar"`
	Missing       bool            `json:"missing,omitempty"`
	ExternalPath  *string         `json:"externalPath,omitempty"`
	OriginalName  string          `json:"originalName"`
	Kind          string          `json:"kind"`
	MimeType      string          `json:"mimeType,omitempty"`
	SizeBytes     int64           `json:"sizeBytes"`
	SHA256        string          `json:"sha256"`
	TakenAt       *time.Time      `json:"takenAt"`
	OffsetMinutes *int32          `json:"timeZoneOffsetMinutes"`
	LocalDateTime string          `json:"localDateTime"`
	UploadedAt    time.Time       `json:"uploadedAt"`
	Latitude      *float64        `json:"latitude"`
	Longitude     *float64        `json:"longitude"`
	Place         *exportPlace    `json:"place,omitempty"`
	Camera        *exportCamera   `json:"camera,omitempty"`
	Width         *int32          `json:"width,omitempty"`
	Height        *int32          `json:"height,omitempty"`
	DurationMs    *int64          `json:"durationMs,omitempty"`
	Description   string          `json:"description"`
	AIDescription string          `json:"aiDescription,omitempty"`
	Rating        int16           `json:"rating"`
	Pick          *string         `json:"pick"`
	Favorite      bool            `json:"favorite"`
	Archived      bool            `json:"archived"`
	Tags          []string        `json:"tags"`
	People        []exportFace    `json:"faces"`
	Albums        []string        `json:"albums"`
	LivePhotoOf   *string         `json:"livePhotoOf,omitempty"`
	StackParent   *string         `json:"stackParent,omitempty"`
	Edits         json.RawMessage `json:"edits"`
}

type exportAlbum struct {
	ID          string          `json:"id"`
	Title       string          `json:"title"`
	Description string          `json:"description"`
	ParentID    *string         `json:"parentId"`
	CreatedAt   time.Time       `json:"createdAt"`
	Folder      string          `json:"folder"`
	Rules       json.RawMessage `json:"rules,omitempty"`
	Assets      []string        `json:"assets"`
}

type albumManifest struct {
	Title       string    `json:"title"`
	Description string    `json:"description"`
	CreatedAt   time.Time `json:"createdAt"`
	Smart       bool      `json:"smart"`
	Files       []string  `json:"files"`
}

func optionalUUID(id pgtype.UUID) *string {
	if !id.Valid {
		return nil
	}
	value := uuidString(id)
	return &value
}

// writeMetadata writes the JSON file with everything known about the library, a page of files at
// a time, and returns the album manifests. It never holds passwords, keys or sessions: it reads
// only the owner's name and email, and the owner's own photos, albums, people and tags.
func (r *exportRun) writeMetadata(ctx context.Context, name string) ([]exportManifest, error) {
	f, err := os.OpenFile(name, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0o640) //nolint:gosec // The export's own folder.
	if err != nil {
		return nil, err
	}
	defer func() { _ = f.Close() }()
	out := bufio.NewWriterSize(f, 1<<20)
	user, err := r.queries.GetUserByID(ctx, r.row.UserID)
	if err != nil {
		return nil, err
	}
	people, err := r.queries.ExportPeople(ctx, r.row.UserID)
	if err != nil {
		return nil, err
	}
	names := map[pgtype.UUID]string{}
	persons := make([]exportPerson, len(people))
	for i := range people {
		names[people[i].ID] = people[i].Name
		persons[i] = exportPerson{ID: uuidString(people[i].ID), Name: people[i].Name, Hidden: people[i].Hidden}
		if people[i].BirthDate.Valid {
			birth := people[i].BirthDate.Time.Format(time.DateOnly)
			persons[i].BirthDate = &birth
		}
	}
	tags, err := r.queries.ExportTags(ctx, r.row.UserID)
	if err != nil {
		return nil, err
	}
	albums, err := r.queries.ExportAlbums(ctx, db.ExportAlbumsParams{ExportID: r.row.ID, UserID: r.row.UserID})
	if err != nil {
		return nil, err
	}
	inAlbums := map[pgtype.UUID][]string{}
	for i := range albums {
		for _, id := range albums[i].Assets {
			inAlbums[id] = append(inAlbums[id], uuidString(albums[i].ID))
		}
	}

	head := map[string]any{
		"format": exportFormat, "version": exportVersion, "exportedAt": time.Now().UTC(),
		"owner": exportOwner{Name: user.Name, Email: user.Email}, "people": persons, "tags": nonNil(tags),
	}
	encoded, err := json.MarshalIndent(head, "", "  ")
	if err != nil {
		return nil, err
	}
	// The head is an object; the assets and albums follow in it, one asset to a line.
	if _, err := out.Write(encoded[:len(encoded)-2]); err != nil {
		return nil, err
	}
	if _, err := out.WriteString(",\n  \"assets\": ["); err != nil {
		return nil, err
	}

	files := map[pgtype.UUID]string{}
	cursor := pgtype.UUID{Valid: true}
	first := true
	for {
		page, err := r.queries.ExportAssetsPage(ctx, db.ExportAssetsPageParams{ExportID: r.row.ID, AssetID: cursor, Limit: exportPage})
		if err != nil {
			return nil, err
		}
		if len(page) == 0 {
			break
		}
		faces, err := r.faces(ctx, page, names)
		if err != nil {
			return nil, err
		}
		for i := range page {
			row := &page[i]
			cursor = row.ID
			asset := r.exportAsset(row, faces[row.ID], inAlbums[row.ID])
			if asset.File != nil {
				files[row.ID] = *asset.File
			}
			line, err := json.Marshal(asset)
			if err != nil {
				return nil, err
			}
			separator := ",\n    "
			if first {
				separator, first = "\n    ", false
			}
			if _, err := out.WriteString(separator); err != nil {
				return nil, err
			}
			if _, err := out.Write(line); err != nil {
				return nil, err
			}
		}
	}

	folders := albumFolders(albums)
	listed := make([]exportAlbum, len(albums))
	manifests := make([]exportManifest, 0, len(albums))
	for i := range albums {
		album := &albums[i]
		ids := make([]string, len(album.Assets))
		manifest := albumManifest{Title: album.Title, Description: album.Description, CreatedAt: album.CreatedAt.Time, Smart: len(album.Rules) > 0, Files: []string{}}
		for n, id := range album.Assets {
			ids[n] = uuidString(id)
			if file, ok := files[id]; ok {
				manifest.Files = append(manifest.Files, file)
			}
		}
		listed[i] = exportAlbum{
			ID: uuidString(album.ID), Title: album.Title, Description: album.Description, ParentID: optionalUUID(album.ParentID),
			CreatedAt: album.CreatedAt.Time, Folder: folders[album.ID], Assets: ids,
		}
		if len(album.Rules) > 0 {
			listed[i].Rules = album.Rules
		}
		data, err := json.MarshalIndent(manifest, "", "  ")
		if err != nil {
			return nil, err
		}
		manifests = append(manifests, exportManifest{path: folders[album.ID] + "/album.json", data: append(data, '\n')})
	}
	encoded, err = json.MarshalIndent(listed, "  ", "  ")
	if err != nil {
		return nil, err
	}
	closing := "\n  ],\n  \"albums\": "
	if first {
		closing = "],\n  \"albums\": "
	}
	if _, err := out.WriteString(closing); err != nil {
		return nil, err
	}
	if _, err := out.Write(encoded); err != nil {
		return nil, err
	}
	if _, err := out.WriteString("\n}\n"); err != nil {
		return nil, err
	}
	if err := out.Flush(); err != nil {
		return nil, err
	}
	return manifests, f.Close()
}

func nonNil[T any](items []T) []T {
	if items == nil {
		return []T{}
	}
	return items
}

// faces gives the faces of a page of files, as parts of the picture shown.
func (r *exportRun) faces(ctx context.Context, page []db.ExportAssetsPageRow, names map[pgtype.UUID]string) (map[pgtype.UUID][]exportFace, error) {
	ids := make([]pgtype.UUID, len(page))
	previews := map[pgtype.UUID]string{}
	for i := range page {
		ids[i] = page[i].ID
		previews[page[i].ID] = page[i].PreviewPath
	}
	rows, err := r.queries.ExportFacesOf(ctx, db.ExportFacesOfParams{UserID: r.row.UserID, AssetIds: ids})
	if err != nil {
		return nil, err
	}
	out := map[pgtype.UUID][]exportFace{}
	sizes := map[pgtype.UUID][2]float32{}
	for i := range rows {
		face := &rows[i]
		size, ok := sizes[face.AssetID]
		if !ok {
			// Faces are found on the preview, so their places are in its pixels.
			if width, height, err := PreviewSize(previews[face.AssetID]); err == nil {
				size = [2]float32{width, height}
			}
			sizes[face.AssetID] = size
		}
		item := exportFace{PersonID: optionalUUID(face.PersonID)}
		if size[0] > 0 && size[1] > 0 {
			box := RelativeBox(face.X1, face.Y1, face.X2, face.Y2, size[0], size[1])
			item.Box = &exportBox{X1: box[0], Y1: box[1], X2: box[2], Y2: box[3]}
		}
		if face.PersonID.Valid {
			item.Person = names[face.PersonID]
		}
		out[face.AssetID] = append(out[face.AssetID], item)
	}
	return out, nil
}

func (r *exportRun) exportAsset(row *db.ExportAssetsPageRow, faces []exportFace, albums []string) exportAsset {
	asset := exportAsset{
		ID: uuidString(row.ID), OriginalName: row.OriginalName, Kind: row.Kind, MimeType: row.MimeType,
		SizeBytes: row.SizeBytes, SHA256: hex.EncodeToString(row.Checksum), UploadedAt: row.CreatedAt.Time.UTC(),
		LocalDateTime: row.LocalAt.Time.Format("2006-01-02T15:04:05"), Description: row.Caption, AIDescription: row.AiDescription,
		Rating: row.Rating, Favorite: row.IsFavorite, Archived: row.ArchivedAt.Valid,
		Tags: nonNil(row.Tags), People: nonNil(faces), Albums: nonNil(albums),
		LivePhotoOf: optionalUUID(row.LivePhotoOf), StackParent: optionalUUID(row.StackParent), Edits: json.RawMessage("null"),
	}
	switch {
	case row.External:
		external := filepath.Base(row.OriginalPath)
		if rel, err := filepath.Rel(r.opts.ExternalPath, row.OriginalPath); err == nil && r.opts.ExternalPath != "" && !strings.HasPrefix(rel, "..") {
			external = filepath.ToSlash(rel)
		}
		asset.ExternalPath = &external
	case row.Missing:
		asset.Missing = true
	default:
		file := row.Path
		asset.File = &file
		if row.Sidecar {
			sidecar := file + ".xmp"
			asset.Sidecar = &sidecar
		}
	}
	if row.TakenAt.Valid {
		taken := row.TakenAt.Time.UTC()
		asset.TakenAt = &taken
	}
	if row.TakenOffsetMinutes.Valid {
		offset := row.TakenOffsetMinutes.Int32
		asset.OffsetMinutes = &offset
	}
	if row.Latitude.Valid && row.Longitude.Valid {
		lat, lon := row.Latitude.Float64, row.Longitude.Float64
		asset.Latitude, asset.Longitude = &lat, &lon
	}
	if row.City.String != "" || row.State.String != "" || row.Country.String != "" {
		asset.Place = &exportPlace{City: row.City.String, State: row.State.String, Country: row.Country.String}
	}
	if row.Make.String != "" || row.Model.String != "" || row.Lens.String != "" {
		asset.Camera = &exportCamera{Make: row.Make.String, Model: row.Model.String, Lens: row.Lens.String}
	}
	if row.Width.Valid {
		asset.Width = &row.Width.Int32
	}
	if row.Height.Valid {
		asset.Height = &row.Height.Int32
	}
	if row.DurationMs.Valid {
		asset.DurationMs = &row.DurationMs.Int64
	}
	switch row.Pick {
	case PickPicked:
		pick := "picked"
		asset.Pick = &pick
	case PickRejected:
		pick := "rejected"
		asset.Pick = &pick
	}
	if len(row.Edits) > 0 {
		asset.Edits = row.Edits
	}
	return asset
}

// albumFolders gives each album a folder of its own under albums/, inside the album it is in.
func albumFolders(albums []db.ExportAlbumsRow) map[pgtype.UUID]string {
	byID := map[pgtype.UUID]*db.ExportAlbumsRow{}
	for i := range albums {
		byID[albums[i].ID] = &albums[i]
	}
	out := map[pgtype.UUID]string{}
	used := map[string]int{}
	var folder func(album *db.ExportAlbumsRow, depth int) string
	folder = func(album *db.ExportAlbumsRow, depth int) string {
		if done, ok := out[album.ID]; ok {
			return done
		}
		parent := exportAlbums
		if up, ok := byID[album.ParentID]; ok && album.ParentID.Valid && depth < maxAlbumDepth {
			parent = folder(up, depth+1)
		}
		title := strings.TrimSpace(album.Title)
		if title == "" {
			title = "Album"
		}
		name := storage.SafeName(title)
		candidate := parent + "/" + name
		for count := 2; used[strings.ToLower(candidate)] > 0; count++ {
			candidate = fmt.Sprintf("%s/%s (%d)", parent, name, count)
		}
		used[strings.ToLower(candidate)]++
		out[album.ID] = candidate
		return candidate
	}
	for i := range albums {
		folder(&albums[i], 0)
	}
	return out
}
