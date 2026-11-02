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

	"github.com/mmzlopasa/mediarr-app/server/db"
	"github.com/mmzlopasa/mediarr-app/server/internal/storage"
)

const (
	maxAttempts      = 5
	staleUploadAge   = 7 * 24 * time.Hour
	cleanupInterval  = 6 * time.Hour
	shutdownDeadline = 30 * time.Second
	// Longer than any job's timeout, so a killed worker's jobs restart without cutting off a slow one.
	rescueStuckAfter = 15 * time.Minute
)

// MetadataArgs reads a file's metadata. It runs first and queues the other jobs.
type MetadataArgs struct {
	AssetID uuid.UUID `json:"asset_id"`
}

// Kind identifies the job in the queue.
func (MetadataArgs) Kind() string { return "metadata" }

// ThumbnailArgs generates thumbnails and the blurhash, then marks the asset ready.
type ThumbnailArgs struct {
	AssetID uuid.UUID `json:"asset_id"`
}

// Kind identifies the job in the queue.
func (ThumbnailArgs) Kind() string { return "thumbnail" }

// SidecarArgs writes an XMP sidecar.
type SidecarArgs struct {
	AssetID uuid.UUID `json:"asset_id"`
}

// Kind identifies the job in the queue.
func (SidecarArgs) Kind() string { return "sidecar" }

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
	Concurrency int
	LibraryPath string
	CachePath   string
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
	river.AddWorker(workers, &cleanupWorker{deps: d})

	var err error
	client, err = river.NewClient(riverpgxv5.New(pool), &river.Config{
		MaxAttempts:          maxAttempts,
		RescueStuckJobsAfter: rescueStuckAfter,
		Queues:               map[string]river.QueueConfig{river.QueueDefault: {MaxWorkers: opts.Concurrency}},
		Workers:              workers,
		PeriodicJobs: []*river.PeriodicJob{
			river.NewPeriodicJob(river.PeriodicInterval(cleanupInterval),
				func() (river.JobArgs, *river.InsertOpts) { return CleanupArgs{}, nil },
				&river.PeriodicJobOpts{RunOnStart: true}),
		},
	})
	return client, err
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

	return pgx.BeginFunc(ctx, w.pool, func(tx pgx.Tx) error {
		q := w.queries.WithTx(tx)
		if err := q.UpdateAssetMetadata(ctx, meta.assetParams(id)); err != nil {
			return err
		}
		if err := q.UpsertExif(ctx, meta.exifParams(id)); err != nil {
			return err
		}
		client := w.client()
		if _, err := client.InsertTx(ctx, tx, ThumbnailArgs{AssetID: job.Args.AssetID}, nil); err != nil {
			return err
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
	result, err := MakeThumbnails(ctx, asset.OriginalPath, asset.Kind, dir, assetID)
	if err != nil {
		return w.failOrRetry(ctx, id, job.Attempt, err)
	}

	return pgx.BeginFunc(ctx, w.pool, func(tx pgx.Tx) error {
		q := w.queries.WithTx(tx)
		for kind, file := range map[string]ThumbFile{"thumb_small": result.Small, "thumb_large": result.Large} {
			if err := q.UpsertAssetFile(ctx, db.UpsertAssetFileParams{AssetID: id, Kind: kind, Path: file.Path, SizeBytes: file.Size}); err != nil {
				return err
			}
		}
		return q.MarkAssetReady(ctx, db.MarkAssetReadyParams{
			ID:          id,
			Blurhash:    pgtype.Text{String: result.Blurhash, Valid: true},
			AspectRatio: pgtype.Float4{Float32: result.Ratio, Valid: result.Ratio > 0},
		})
	})
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

type cleanupWorker struct {
	river.WorkerDefaults[CleanupArgs]
	*deps
}

func (w *cleanupWorker) Work(ctx context.Context, _ *river.Job[CleanupArgs]) error {
	if err := w.queries.DeleteExpiredSessions(ctx); err != nil {
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
