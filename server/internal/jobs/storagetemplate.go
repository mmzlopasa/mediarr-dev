package jobs

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/riverqueue/river"
	"github.com/riverqueue/river/rivertype"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/storage"
)

const (
	// StateStorageTemplate holds the template; empty keeps the layout originals have always had.
	StateStorageTemplate = "storage_template"
	// StateStorageReport holds what the last run over all originals did, or would do.
	StateStorageReport = "storage_template_report"
	storageBatch       = 500
	storageSamples     = 50
	storageErrors      = 20
	maxNameTries       = 100
	storageApplyLimit  = 24 * time.Hour
)

// StorageMove is one original that moves, or would.
type StorageMove struct {
	From string `json:"from"`
	To   string `json:"to"`
}

// StorageReport says what putting every original where the template says did, or would do.
type StorageReport struct {
	Template   string        `json:"template"`
	DryRun     bool          `json:"dryRun"`
	Running    bool          `json:"running"`
	StartedAt  time.Time     `json:"startedAt"`
	FinishedAt *time.Time    `json:"finishedAt,omitempty"`
	Checked    int           `json:"checked"`
	Moved      int           `json:"moved"`
	Failed     int           `json:"failed"`
	Samples    []StorageMove `json:"samples"`
	Errors     []string      `json:"errors"`
}

// LoadStorageTemplate reads the template; empty when none was chosen.
func LoadStorageTemplate(ctx context.Context, q *db.Queries) (string, error) {
	value, err := q.GetState(ctx, StateStorageTemplate)
	if db.IsNotFound(err) {
		return "", nil
	}
	return strings.TrimSpace(value), err
}

// StorageTarget is where the template puts one original: inside its owner's folder, always. ok is
// false for anything that does not move, such as a file in an external library.
func StorageTarget(ctx context.Context, q *db.Queries, library, template string, id pgtype.UUID) (from, to string, ok bool, err error) {
	facts, err := q.StorageFacts(ctx, id)
	if db.IsNotFound(err) {
		return "", "", false, nil
	}
	if err != nil {
		return "", "", false, err
	}
	rendered := storage.RenderTemplate(template, &storage.TemplateFields{
		When: facts.PlacedAt.Time, Name: facts.OriginalName, Camera: facts.Camera, Album: facts.Album,
		Checksum: facts.ChecksumHex,
	})
	root := filepath.Join(library, uuidString(facts.UserID))
	to = filepath.Join(root, rendered)
	if rel, relErr := filepath.Rel(root, to); relErr != nil || strings.HasPrefix(rel, "..") {
		return "", "", false, fmt.Errorf("the template gives a path outside the user's folder: %s", rendered)
	}
	return facts.OriginalPath, to, !placedAs(facts.OriginalPath, to), nil
}

// placedAs says whether a file already sits where the template puts it: under that name, or that
// name with -1, -2… when another file had it first. Such a file would otherwise move on every run.
func placedAs(path, target string) bool {
	if path == target {
		return true
	}
	if filepath.Dir(path) != filepath.Dir(target) {
		return false
	}
	ext := filepath.Ext(target)
	stem := strings.TrimSuffix(filepath.Base(target), ext)
	name := filepath.Base(path)
	if !strings.HasPrefix(name, stem+"-") || !strings.HasSuffix(name, ext) {
		return false
	}
	number := strings.TrimSuffix(strings.TrimPrefix(name, stem+"-"), ext)
	if number == "" {
		return false
	}
	for _, r := range number {
		if r < '0' || r > '9' {
			return false
		}
	}
	return true
}

// candidateName is the n-th name tried for a file: the name itself, then IMG_0001-1.jpg and on.
func candidateName(path string, n int) string {
	if n == 0 {
		return path
	}
	ext := filepath.Ext(path)
	return fmt.Sprintf("%s-%d%s", strings.TrimSuffix(path, ext), n, ext)
}

// moveToFreeName moves a file to the first name nobody has: two photos called IMG_0001.jpg both
// stay, the second as IMG_0001-1.jpg. The move itself refuses a taken name, so two moves running at
// once never write over each other's original.
func moveToFreeName(from, to string) (string, error) {
	for n := range maxNameTries {
		candidate := candidateName(to, n)
		err := renameNoReplace(from, candidate)
		if err == nil {
			return candidate, nil
		}
		if !errors.Is(err, os.ErrExist) {
			return "", err
		}
	}
	return "", fmt.Errorf("no free name beside %s", to)
}

// MoveOriginal renames an original to its new place on the same disk, which is atomic, and then
// records it. If recording fails, the file goes back.
func MoveOriginal(ctx context.Context, q *db.Queries, library string, id pgtype.UUID, from, to string) (string, error) {
	if err := os.MkdirAll(filepath.Dir(to), 0o750); err != nil {
		return "", fmt.Errorf("make the folder: %w", err)
	}
	target, err := moveToFreeName(from, to)
	if err != nil {
		return "", fmt.Errorf("move %s: %w", filepath.Base(from), err)
	}
	if err := q.SetOriginalPath(ctx, db.SetOriginalPathParams{ID: id, OriginalPath: target}); err != nil {
		if back := renameNoReplace(target, from); back != nil {
			slog.Error("an original could not be put back after a failed move", "from", target, "to", from, "error", back)
		}
		return "", err
	}
	removeEmptyFolders(library, filepath.Dir(from))
	return target, nil
}

// removeEmptyFolders tidies what a move left empty, up to the user's own folder.
func removeEmptyFolders(library, dir string) {
	for {
		rel, err := filepath.Rel(library, dir)
		// The library and each user's own folder stay.
		if err != nil || rel == "." || !strings.Contains(rel, string(filepath.Separator)) || strings.HasPrefix(rel, "..") {
			return
		}
		if os.Remove(dir) != nil {
			return
		}
		dir = filepath.Dir(dir)
	}
}

// StorageMoveArgs puts one new original where the template says.
type StorageMoveArgs struct {
	AssetID uuid.UUID `json:"asset_id"`
}

// Kind identifies the job in the queue.
func (StorageMoveArgs) Kind() string { return "storage_move" }

type storageMoveWorker struct {
	river.WorkerDefaults[StorageMoveArgs]
	*deps
}

func (w *storageMoveWorker) Work(ctx context.Context, job *river.Job[StorageMoveArgs]) error {
	template, err := LoadStorageTemplate(ctx, w.queries)
	if err != nil || template == "" {
		return err
	}
	id := toPG(job.Args.AssetID)
	from, to, ok, err := StorageTarget(ctx, w.queries, w.opts.LibraryPath, template, id)
	if err != nil || !ok {
		return err
	}
	_, err = MoveOriginal(ctx, w.queries, w.opts.LibraryPath, id, from, to)
	return err
}

// StorageApplyArgs puts every uploaded original where the template says, or with DryRun only says
// what would move.
type StorageApplyArgs struct {
	DryRun bool `json:"dry_run"`
}

// Kind identifies the job in the queue.
func (StorageApplyArgs) Kind() string { return "storage_apply" }

// InsertOpts shares the queue of long jobs, one at a time.
func (StorageApplyArgs) InsertOpts() river.InsertOpts {
	return river.InsertOpts{
		Queue: importQueue,
		// A dry run and a real one are different work; the same one twice at once is not.
		UniqueOpts: river.UniqueOpts{ByArgs: true, ByState: []rivertype.JobState{
			rivertype.JobStateAvailable, rivertype.JobStatePending, rivertype.JobStateRetryable,
			rivertype.JobStateRunning, rivertype.JobStateScheduled,
		}},
	}
}

type storageApplyWorker struct {
	river.WorkerDefaults[StorageApplyArgs]
	*deps
}

func (w *storageApplyWorker) Timeout(*river.Job[StorageApplyArgs]) time.Duration {
	return storageApplyLimit
}

func (w *storageApplyWorker) Work(ctx context.Context, job *river.Job[StorageApplyArgs]) error {
	template, err := LoadStorageTemplate(ctx, w.queries)
	if err != nil {
		return err
	}
	report := &StorageReport{
		Template: template, DryRun: job.Args.DryRun, Running: true, StartedAt: time.Now().UTC(),
		Samples: []StorageMove{}, Errors: []string{},
	}
	save := func() {
		data, err := json.Marshal(report)
		if err == nil {
			err = w.queries.SetState(ctx, db.SetStateParams{Key: StateStorageReport, Value: string(data)})
		}
		if err != nil {
			slog.Warn("the storage report was not saved", "error", err)
		}
	}
	save()
	defer func() {
		finished := time.Now().UTC()
		report.Running = false
		report.FinishedAt = &finished
		save()
	}()
	if template == "" {
		return nil
	}
	relative := func(path string) string {
		return strings.TrimPrefix(path, w.opts.LibraryPath+string(filepath.Separator))
	}
	fail := func(message string) {
		report.Failed++
		if len(report.Errors) < storageErrors {
			report.Errors = append(report.Errors, message)
		}
	}
	after := pgtype.UUID{Valid: true}
	for {
		ids, err := w.queries.UploadAssetsAfter(ctx, db.UploadAssetsAfterParams{ID: after, Limit: storageBatch})
		if err != nil {
			return err
		}
		if len(ids) == 0 {
			return nil
		}
		for _, id := range ids {
			if ctx.Err() != nil {
				return ctx.Err()
			}
			after = id
			report.Checked++
			from, to, ok, err := StorageTarget(ctx, w.queries, w.opts.LibraryPath, template, id)
			if err != nil {
				fail(err.Error())
				continue
			}
			if !ok {
				continue
			}
			if !job.Args.DryRun {
				if to, err = MoveOriginal(ctx, w.queries, w.opts.LibraryPath, id, from, to); err != nil {
					fail(err.Error())
					continue
				}
			}
			report.Moved++
			if len(report.Samples) < storageSamples {
				report.Samples = append(report.Samples, StorageMove{From: relative(from), To: relative(to)})
			}
		}
		save()
	}
}
