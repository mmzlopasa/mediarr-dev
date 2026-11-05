// Package jobs defines the background jobs. The queue lives in Postgres (River).
package jobs

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/riverqueue/river"
	"github.com/riverqueue/river/riverdriver/riverpgxv5"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/ml"
	"github.com/mediarr-app/mediarr/server/internal/storage"
)

const (
	auditKeptFor     = 365 * 24 * time.Hour
	maxAttempts      = 5
	staleUploadAge   = 7 * 24 * time.Hour
	cleanupInterval  = 6 * time.Hour
	shutdownDeadline = 30 * time.Second
	videoQueue       = "video"
	// Longer than any job's timeout, so a killed worker's jobs restart without cutting off a slow one.
	// Longer than the longest job, which would otherwise run twice. Jobs that a restart interrupted
	// do not wait for this: ReleaseInterrupted hands them back at once.
	rescueStuckAfter = externalScanTimeout + time.Hour
)

// MetadataArgs reads a file's metadata. It runs first and queues the other jobs.
type MetadataArgs struct {
	AssetID uuid.UUID `json:"asset_id"`
}

// Kind identifies the job in the queue.
func (MetadataArgs) Kind() string { return "metadata" }

// ThumbnailArgs generates thumbnails and the blurhash, then marks the asset ready.
type ThumbnailArgs struct {
	AssetID      uuid.UUID `json:"asset_id"`
	MotionOffset int64     `json:"motion_offset,omitempty"`
	IsMotion     bool      `json:"is_motion,omitempty"`
}

// Kind identifies the job in the queue.
func (ThumbnailArgs) Kind() string { return "thumbnail" }

// SidecarArgs writes an XMP sidecar.
type SidecarArgs struct {
	AssetID uuid.UUID `json:"asset_id"`
}

// Kind identifies the job in the queue.
func (SidecarArgs) Kind() string { return "sidecar" }

// TranscodeArgs makes the HLS versions and the scrub strip of a video.
type TranscodeArgs struct {
	AssetID uuid.UUID `json:"asset_id"`
}

// Kind identifies the job in the queue.
func (TranscodeArgs) Kind() string { return "transcode" }

// InsertOpts puts video work in its own queue, so it never holds up photos.
func (TranscodeArgs) InsertOpts() river.InsertOpts { return river.InsertOpts{Queue: videoQueue} }

// CleanupArgs removes abandoned uploads and expired sessions.
type CleanupArgs struct{}

// Kind identifies the job in the queue.
func (CleanupArgs) Kind() string { return "cleanup" }

// Inserter queues jobs from a client that does not run them.
type Inserter = river.Client[pgx.Tx]

// NewInserter returns a client that can only queue jobs, so the server stays light.
func NewInserter(pool *pgxpool.Pool) (*Inserter, error) {
	return river.NewClient(riverpgxv5.New(pool), &river.Config{})
}

// Options for the worker.
type Options struct {
	VideoWorkers    int
	AnalysisWorkers int
	Concurrency     int
	LibraryPath     string
	CachePath       string
	// ExternalPath is where a folder to import from is mounted, read only.
	ExternalPath string
	// DatabaseURL is what a backup reads the database with.
	DatabaseURL string
	// AllowLocalWebhooks is for tests, whose receiver is on this machine.
	AllowLocalWebhooks bool
	VideoAccel         string
	// MLURL is empty when picture analysis is not turned on.
	MLURL string
}

type deps struct {
	pool    *pgxpool.Pool
	queries *db.Queries
	client  func() *river.Client[pgx.Tx]
	opts    Options
}

// NewWorker returns a client that runs jobs until its context ends.
func NewWorker(pool *pgxpool.Pool, opts Options) (*river.Client[pgx.Tx], error) {
	var client *river.Client[pgx.Tx]
	d := &deps{pool: pool, queries: db.New(pool), client: func() *river.Client[pgx.Tx] { return client }, opts: opts}

	workers := river.NewWorkers()
	river.AddWorker(workers, &metadataWorker{deps: d})
	river.AddWorker(workers, &thumbnailWorker{deps: d})
	river.AddWorker(workers, &sidecarWorker{deps: d})
	river.AddWorker(workers, &transcodeWorker{deps: d})
	river.AddWorker(workers, &cleanupWorker{deps: d})
	river.AddWorker(workers, &analyzeWorker{deps: d, client: ml.New(opts.MLURL)})
	river.AddWorker(workers, &analyzeBackfillWorker{deps: d})
	river.AddWorker(workers, &storyWorker{deps: d})
	river.AddWorker(workers, &organizeWorker{deps: d})
	river.AddWorker(workers, &importWorker{deps: d})
	river.AddWorker(workers, &backupWorker{deps: d})
	river.AddWorker(workers, &describeWorker{deps: d})
	river.AddWorker(workers, &describeBackfillWorker{deps: d})
	river.AddWorker(workers, &webhookWorker{deps: d})
	river.AddWorker(workers, &backupTickWorker{deps: d})
	river.AddWorker(workers, &externalScanWorker{deps: d})
	river.AddWorker(workers, &integrityWorker{deps: d})

	var err error
	client, err = river.NewClient(riverpgxv5.New(pool), &river.Config{
		MaxAttempts:          maxAttempts,
		RescueStuckJobsAfter: rescueStuckAfter,
		Queues: map[string]river.QueueConfig{
			river.QueueDefault: {MaxWorkers: opts.Concurrency},
			videoQueue:         {MaxWorkers: max(opts.VideoWorkers, 1)},
			mlQueue:            {MaxWorkers: max(opts.AnalysisWorkers, 1)},
			importQueue:        {MaxWorkers: 1},
			describeQueue:      {MaxWorkers: 1},
		},
		Workers: workers,
		PeriodicJobs: []*river.PeriodicJob{
			river.NewPeriodicJob(river.PeriodicInterval(cleanupInterval),
				func() (river.JobArgs, *river.InsertOpts) { return CleanupArgs{}, nil },
				&river.PeriodicJobOpts{RunOnStart: true}),
			river.NewPeriodicJob(river.PeriodicInterval(analyzeBackfillInterval),
				func() (river.JobArgs, *river.InsertOpts) { return AnalyzeBackfillArgs{}, nil },
				&river.PeriodicJobOpts{RunOnStart: true}),
			river.NewPeriodicJob(river.PeriodicInterval(organizeInterval),
				func() (river.JobArgs, *river.InsertOpts) { return OrganizeArgs{}, nil },
				&river.PeriodicJobOpts{RunOnStart: true}),
			river.NewPeriodicJob(river.PeriodicInterval(describeBackfillEvery),
				func() (river.JobArgs, *river.InsertOpts) { return DescribeBackfillArgs{}, nil },
				&river.PeriodicJobOpts{RunOnStart: true}),
			river.NewPeriodicJob(river.PeriodicInterval(backupTickEvery),
				func() (river.JobArgs, *river.InsertOpts) { return BackupTickArgs{}, nil }, nil),
			river.NewPeriodicJob(river.PeriodicInterval(externalScanTick),
				func() (river.JobArgs, *river.InsertOpts) { return ExternalScanArgs{Scheduled: true}, nil },
				&river.PeriodicJobOpts{RunOnStart: true}),
			river.NewPeriodicJob(river.PeriodicInterval(integrityEvery),
				func() (river.JobArgs, *river.InsertOpts) { return IntegrityArgs{}, nil }, nil),
		},
	})
	return client, err
}

// ReleaseInterrupted hands back what the previous run was doing when it stopped. An installation has
// one worker, so a job still marked as running when it starts has nobody working on it, and a job
// that allows one copy at a time would otherwise block new ones. A job that used up its attempts,
// perhaps by bringing the worker down each time, is given up on.
func ReleaseInterrupted(ctx context.Context, pool *pgxpool.Pool) error {
	_, err := pool.Exec(ctx, `
		UPDATE river_job
		SET state = CASE WHEN attempt >= max_attempts THEN 'discarded' ELSE 'available' END::river_job_state,
		    finalized_at = CASE WHEN attempt >= max_attempts THEN now() END,
		    scheduled_at = now()
		WHERE state = 'running'`)
	if err != nil {
		return fmt.Errorf("release interrupted jobs: %w", err)
	}
	return nil
}

// Run starts the worker and blocks until ctx ends, then finishes running jobs.
func Run(ctx context.Context, client *river.Client[pgx.Tx]) error {
	if err := client.Start(ctx); err != nil {
		return fmt.Errorf("start worker: %w", err)
	}
	<-ctx.Done()
	stopCtx, cancel := context.WithTimeout(context.Background(), shutdownDeadline)
	defer cancel()
	return client.Stop(stopCtx)
}

// fail records a permanent failure, so bad files show an error instead of retrying forever.
func (d *deps) fail(ctx context.Context, id pgtype.UUID, cause error) error {
	if err := d.queries.MarkAssetFailed(ctx, db.MarkAssetFailedParams{
		ID:    id,
		Error: pgtype.Text{String: truncate(cause.Error(), 500), Valid: true},
	}); err != nil {
		return err
	}
	return river.JobCancel(cause)
}

// failOrRetry retries temporary errors and records the failure on the last attempt.
func (d *deps) failOrRetry(ctx context.Context, id pgtype.UUID, attempt int, cause error) error {
	var bad *badFileError
	if errors.As(cause, &bad) || attempt >= maxAttempts {
		return d.fail(ctx, id, cause)
	}
	return cause
}

func toPG(id uuid.UUID) pgtype.UUID { return pgtype.UUID{Bytes: id, Valid: true} }

func uuidString(id pgtype.UUID) string { return uuid.UUID(id.Bytes).String() }

func truncate(s string, limit int) string {
	if len(s) <= limit {
		return s
	}
	return s[:limit]
}

type metadataWorker struct {
	river.WorkerDefaults[MetadataArgs]
	*deps
}

func (w *metadataWorker) Work(ctx context.Context, job *river.Job[MetadataArgs]) error {
	id := toPG(job.Args.AssetID)
	asset, err := w.queries.GetAsset(ctx, id)
	if err != nil {
		if db.IsNotFound(err) {
			return river.JobCancel(err)
		}
		return err
	}
	meta, err := ReadMetadata(ctx, asset.OriginalPath)
	if err != nil {
		return w.failOrRetry(ctx, id, job.Attempt, err)
	}
	meta.fillFromImport(&asset)
	meta.fillFromManual(&asset)

	return pgx.BeginFunc(ctx, w.pool, func(tx pgx.Tx) error {
		q := w.queries.WithTx(tx)
		if err := q.UpdateAssetMetadata(ctx, meta.assetParams(id)); err != nil {
			return err
		}
		if err := q.UpsertExif(ctx, meta.exifParams(id)); err != nil {
			return err
		}
		if err := q.GeocodeAsset(ctx, id); err != nil {
			return err
		}
		// Live Photo files can arrive in either order, so both try to link.
		if meta.ContentID != "" {
			if err := q.LinkLivePhoto(ctx, db.LinkLivePhotoParams{UserID: asset.UserID, ContentID: pgText(meta.ContentID)}); err != nil {
				return err
			}
		}
		client := w.client()
		if _, err := client.InsertTx(ctx, tx, ThumbnailArgs{AssetID: job.Args.AssetID, MotionOffset: meta.MotionOffset, IsMotion: meta.IsMotion}, nil); err != nil {
			return err
		}
		if meta.Kind == "video" {
			if _, err := client.InsertTx(ctx, tx, TranscodeArgs{AssetID: job.Args.AssetID}, nil); err != nil {
				return err
			}
		}
		_, err := client.InsertTx(ctx, tx, SidecarArgs{AssetID: job.Args.AssetID}, nil)
		return err
	})
}

type thumbnailWorker struct {
	river.WorkerDefaults[ThumbnailArgs]
	*deps
}

func (w *thumbnailWorker) Timeout(*river.Job[ThumbnailArgs]) time.Duration { return 10 * time.Minute }

func (w *thumbnailWorker) Work(ctx context.Context, job *river.Job[ThumbnailArgs]) error {
	id := toPG(job.Args.AssetID)
	asset, err := w.queries.GetAsset(ctx, id)
	if err != nil {
		if db.IsNotFound(err) {
			return river.JobCancel(err)
		}
		return err
	}

	assetID := uuidString(id)
	dir := filepath.Join(w.opts.CachePath, "thumbs", uuidString(asset.UserID), assetID[:2])
	edits, err := ParseEdits(asset.Edits)
	if err != nil {
		return w.failOrRetry(ctx, id, job.Attempt, err)
	}
	refreshMedia(ctx, w.queries)
	result, err := MakeThumbnails(ctx, asset.OriginalPath, asset.Kind, dir, assetID, edits)
	if err != nil {
		return w.failOrRetry(ctx, id, job.Attempt, err)
	}

	// Best effort: a photo whose embedded video cannot be read is still a good photo.
	motionPath := ""
	if job.Args.IsMotion {
		dest := filepath.Join(w.opts.CachePath, "video", uuidString(asset.UserID), assetID[:2], assetID+"-motion.mp4")
		found, err := ExtractMotionVideo(asset.OriginalPath, dest, job.Args.MotionOffset)
		if err != nil {
			slog.Warn("motion video could not be extracted", "asset", assetID, "error", err)
		} else if found {
			motionPath = dest
		}
	}

	err = pgx.BeginFunc(ctx, w.pool, func(tx pgx.Tx) error {
		q := w.queries.WithTx(tx)
		if motionPath != "" {
			if err := q.UpsertAssetFile(ctx, db.UpsertAssetFileParams{AssetID: id, Kind: "motion_video", Path: motionPath}); err != nil {
				return err
			}
		}
		for kind, file := range map[string]ThumbFile{"thumb_small": result.Small, "thumb_large": result.Large} {
			if err := q.UpsertAssetFile(ctx, db.UpsertAssetFileParams{AssetID: id, Kind: kind, Path: file.Path, SizeBytes: file.Size}); err != nil {
				return err
			}
		}
		if err := q.MarkEditApplied(ctx, db.MarkEditAppliedParams{ID: id, EditApplied: asset.EditRevision}); err != nil {
			return err
		}
		if err := q.MarkAssetReady(ctx, db.MarkAssetReadyParams{
			ID:          id,
			Blurhash:    pgtype.Text{String: result.Blurhash, Valid: true},
			AspectRatio: pgtype.Float4{Float32: result.Ratio, Valid: result.Ratio > 0},
		}); err != nil {
			return err
		}
		if w.opts.MLURL == "" {
			return nil
		}
		_, err := w.client().InsertTx(ctx, tx, AnalyzeArgs{AssetID: job.Args.AssetID, Revision: asset.EditRevision}, nil)
		return err
	})
	if err != nil {
		return err
	}
	// Only a new asset is news: an edited one has been ready all along.
	if asset.Status != "ready" {
		w.emitWebhook(ctx, EventAssetReady, map[string]string{"assetId": assetID, "userId": uuidString(asset.UserID)})
	}
	return nil
}

type sidecarWorker struct {
	river.WorkerDefaults[SidecarArgs]
	*deps
}

func (w *sidecarWorker) Work(ctx context.Context, job *river.Job[SidecarArgs]) error {
	id := toPG(job.Args.AssetID)
	asset, err := w.queries.GetAsset(ctx, id)
	if err != nil {
		if db.IsNotFound(err) {
			return river.JobCancel(err)
		}
		return err
	}
	assetID := uuidString(id)
	path := filepath.Join(storage.SidecarDir(w.opts.LibraryPath), uuidString(asset.UserID), assetID[:2], assetID+".xmp")
	size, err := WriteSidecar(ctx, asset.OriginalPath, path)
	if err != nil {
		var bad *badFileError
		if errors.As(err, &bad) {
			// Not every format has metadata to export; this must not fail the asset.
			slog.Warn("no sidecar written", "asset", assetID, "error", err)
			return nil
		}
		return err
	}
	return w.queries.UpsertAssetFile(ctx, db.UpsertAssetFileParams{AssetID: id, Kind: "sidecar", Path: path, SizeBytes: size})
}

type transcodeWorker struct {
	river.WorkerDefaults[TranscodeArgs]
	*deps
}

func (w *transcodeWorker) Timeout(*river.Job[TranscodeArgs]) time.Duration { return transcodeTimeout }

// Work is optional for the asset: until it finishes, or if it fails, the original still plays
// directly where the browser supports it. So it never marks the asset as failed.
func (w *transcodeWorker) Work(ctx context.Context, job *river.Job[TranscodeArgs]) error {
	id := toPG(job.Args.AssetID)
	asset, err := w.queries.GetAsset(ctx, id)
	if err != nil {
		if db.IsNotFound(err) {
			return river.JobCancel(err)
		}
		return err
	}
	// A long transcode can be picked up again after the crash recovery time. Then it is done already.
	if _, err := w.queries.GetAssetFile(ctx, db.GetAssetFileParams{AssetID: id, Kind: "hls"}); err == nil {
		return nil
	}

	info, err := ProbeVideo(ctx, asset.OriginalPath)
	if err != nil {
		var bad *badFileError
		if errors.As(err, &bad) {
			return river.JobCancel(err)
		}
		return err
	}
	if err := w.queries.UpdateVideoInfo(ctx, db.UpdateVideoInfoParams{
		ID:         id,
		DurationMs: pgtype.Int8{Int64: info.Duration.Milliseconds(), Valid: info.Duration > 0},
		VideoCodec: pgText(info.Codec),
	}); err != nil {
		return err
	}

	assetID := uuidString(id)
	dir := filepath.Join(w.opts.CachePath, "video", uuidString(asset.UserID), assetID[:2], assetID)
	if err := Transcode(ctx, asset.OriginalPath, dir, w.opts.VideoAccel, info); err != nil {
		var bad *badFileError
		if errors.As(err, &bad) {
			return river.JobCancel(err)
		}
		return err
	}

	sprite := filepath.Join(w.opts.CachePath, "video", uuidString(asset.UserID), assetID[:2], assetID+"-sprite.jpg")
	layout, spriteErr := MakeSprite(ctx, asset.OriginalPath, sprite, info.Duration)
	if spriteErr != nil {
		slog.Warn("scrub strip could not be made", "asset", assetID, "error", spriteErr)
	}

	return pgx.BeginFunc(ctx, w.pool, func(tx pgx.Tx) error {
		q := w.queries.WithTx(tx)
		if layout != nil {
			if err := q.UpsertAssetFile(ctx, db.UpsertAssetFileParams{AssetID: id, Kind: "sprite", Path: sprite}); err != nil {
				return err
			}
			if err := q.UpdateSprite(ctx, db.UpdateSpriteParams{
				ID:               id,
				SpriteColumns:    pgtype.Int4{Int32: int32(layout.Columns), Valid: true},                 //nolint:gosec // At most 100.
				SpriteRows:       pgtype.Int4{Int32: int32(layout.Rows), Valid: true},                    //nolint:gosec // At most 100.
				SpriteCount:      pgtype.Int4{Int32: int32(layout.Count), Valid: true},                   //nolint:gosec // At most 100.
				SpriteIntervalMs: pgtype.Int4{Int32: int32(layout.Interval.Milliseconds()), Valid: true}, //nolint:gosec // Bounded by duration.
			}); err != nil {
				return err
			}
		}
		return q.UpsertAssetFile(ctx, db.UpsertAssetFileParams{AssetID: id, Kind: "hls", Path: dir})
	})
}

type cleanupWorker struct {
	river.WorkerDefaults[CleanupArgs]
	*deps
}

func (w *cleanupWorker) Work(ctx context.Context, _ *river.Job[CleanupArgs]) error {
	if err := w.queries.DeleteExpiredSessions(ctx); err != nil {
		return err
	}
	if err := w.queries.DeleteExpiredVaultSessions(ctx); err != nil {
		return err
	}
	if err := PurgeExpiredTrash(ctx, w.queries, w.opts.CachePath, time.Now()); err != nil {
		return err
	}
	if err := GeocodePending(ctx, w.queries); err != nil {
		return err
	}
	if err := w.queries.DeleteOldAudit(ctx, pgtype.Timestamptz{Time: time.Now().Add(-auditKeptFor), Valid: true}); err != nil {
		return err
	}
	if err := w.queries.DeleteOldSecurityEvents(ctx, pgtype.Timestamptz{Time: time.Now().Add(-auditKeptFor), Valid: true}); err != nil {
		return err
	}
	if err := removeOldStories(ctx, w.queries, time.Now()); err != nil {
		return err
	}
	return removeStaleUploads(storage.TmpDir(w.opts.LibraryPath), time.Now().Add(-staleUploadAge))
}

// removeStaleUploads deletes uploads abandoned before the cutoff, so they do not fill the disk.
func removeStaleUploads(dir string, cutoff time.Time) error {
	entries, err := os.ReadDir(dir)
	if errors.Is(err, os.ErrNotExist) {
		return nil
	}
	if err != nil {
		return err
	}
	for _, entry := range entries {
		info, err := entry.Info()
		if err != nil || entry.IsDir() || !info.ModTime().Before(cutoff) {
			continue
		}
		name := entry.Name()
		if strings.HasSuffix(name, ".lock") {
			continue
		}
		if err := os.Remove(filepath.Join(dir, name)); err != nil && !errors.Is(err, os.ErrNotExist) {
			return err
		}
	}
	return nil
}

// GeocodePending names the places of photos that do not have a name yet, such as older photos.
func GeocodePending(ctx context.Context, q *db.Queries) error {
	places, err := q.CountPlaces(ctx)
	if err != nil || places == 0 {
		return err
	}
	for {
		ids, err := q.ListGeocodePending(ctx)
		if err != nil {
			return err
		}
		if len(ids) == 0 {
			return nil
		}
		for _, id := range ids {
			if err := q.GeocodeAsset(ctx, id); err != nil {
				return fmt.Errorf("name a place: %w", err)
			}
		}
	}
}
