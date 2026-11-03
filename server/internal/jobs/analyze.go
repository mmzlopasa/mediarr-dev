package jobs

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"strconv"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/riverqueue/river"
	"github.com/riverqueue/river/rivertype"

	"github.com/mmzlopasa/mediarr-app/server/db"
	"github.com/mmzlopasa/mediarr-app/server/internal/ml"
)

const (
	mlQueue                 = "ml"
	analyzeBackfillInterval = 10 * time.Minute
	// How far apart two face vectors may be for the same person. Measured on real photos: the same
	// person came out at about 0.66 and different people at about 0.97.
	sameFaceDistance = 0.7
	minFaceSide      = 40
	minFaceScore     = 0.6
	faceCropPadding  = 0.3
	faceCropSize     = 256
)

// AnalyzeArgs reads a picture for search and for faces.
type AnalyzeArgs struct {
	AssetID uuid.UUID `json:"asset_id"`
}

// Kind identifies the job in the queue.
func (AnalyzeArgs) Kind() string { return "analyze" }

// InsertOpts gives analysis its own queue, and one job per picture at a time.
func (AnalyzeArgs) InsertOpts() river.InsertOpts {
	return river.InsertOpts{
		Queue: mlQueue,
		// Includes cancelled, so a picture the service cannot read is not tried over and over.
		UniqueOpts: river.UniqueOpts{ByArgs: true, ByState: []rivertype.JobState{
			rivertype.JobStateAvailable, rivertype.JobStateCancelled, rivertype.JobStateCompleted,
			rivertype.JobStatePending, rivertype.JobStateRetryable, rivertype.JobStateRunning,
			rivertype.JobStateScheduled,
		}},
	}
}

// AnalyzeBackfillArgs queues pictures that have not been analysed, such as those from before
// analysis was turned on.
type AnalyzeBackfillArgs struct{}

// Kind identifies the job in the queue.
func (AnalyzeBackfillArgs) Kind() string { return "analyze_backfill" }

type analyzeWorker struct {
	river.WorkerDefaults[AnalyzeArgs]
	*deps
	client *ml.Client
}

func (w *analyzeWorker) Work(ctx context.Context, job *river.Job[AnalyzeArgs]) error {
	err := AnalyzeAsset(ctx, w.pool, w.queries, w.client, toPG(job.Args.AssetID))
	var status *ml.StatusError
	if errors.As(err, &status) && status.Unreadable() {
		slog.Warn("the analysis could not read a picture", "asset", job.Args.AssetID, "error", err)
		return river.JobCancel(err)
	}
	return err
}

// Timeout leaves room for the first run, when the service fetches its models.
func (w *analyzeWorker) Timeout(*river.Job[AnalyzeArgs]) time.Duration { return 30 * time.Minute }

type beginner interface {
	Begin(ctx context.Context) (pgx.Tx, error)
}

// AnalyzeAsset stores what the service finds. A photo is read from its large preview, which is
// also what a video's first frame was turned into.
func AnalyzeAsset(ctx context.Context, pool beginner, q *db.Queries, client *ml.Client, id pgtype.UUID) error {
	asset, err := q.GetAsset(ctx, id)
	if db.IsNotFound(err) {
		return nil
	}
	if err != nil {
		return err
	}
	path, err := q.GetAssetFile(ctx, db.GetAssetFileParams{AssetID: id, Kind: "thumb_large"})
	if db.IsNotFound(err) {
		return nil
	}
	if err != nil {
		return err
	}
	picture, err := os.ReadFile(path) //nolint:gosec // From the database.
	if err != nil {
		return fmt.Errorf("read preview: %w", err)
	}
	embedding, err := client.EmbedImage(ctx, picture)
	if err != nil {
		return err
	}
	faces, err := client.Faces(ctx, picture)
	if err != nil {
		return err
	}
	text, err := client.ReadText(ctx, picture)
	if err != nil {
		return err
	}

	return pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		qtx := q.WithTx(tx)
		if _, err := tx.Exec(ctx, "SET LOCAL hnsw.iterative_scan = relaxed_order"); err != nil {
			return err
		}
		if err := qtx.UpsertAssetSearch(ctx, db.UpsertAssetSearchParams{
			AssetID: id, Embedding: ml.Vector(embedding), OcrText: text,
		}); err != nil {
			return err
		}
		if err := qtx.DeleteAssetFaces(ctx, id); err != nil {
			return err
		}
		for i := range faces {
			if err := storeFace(ctx, qtx, &asset, &faces[i]); err != nil {
				return err
			}
		}
		return nil
	})
}

func usableFace(face *ml.Face) bool {
	return face.Score >= minFaceScore &&
		face.Box[2]-face.Box[0] >= minFaceSide && face.Box[3]-face.Box[1] >= minFaceSide
}

// storeFace gives a face to the closest known person, or starts a new one. Starting a person
// for every stray face is fine: someone seen once and unnamed is not listed.
func storeFace(ctx context.Context, q *db.Queries, asset *db.Asset, face *ml.Face) error {
	if !usableFace(face) {
		return nil
	}
	vector := ml.Vector(face.Embedding)
	nearest, err := q.NearestPerson(ctx, db.NearestPersonParams{Embedding: vector, UserID: asset.UserID})
	if err != nil && !db.IsNotFound(err) {
		return err
	}
	person := nearest.PersonID
	if db.IsNotFound(err) || nearest.Distance > sameFaceDistance {
		if person, err = q.CreatePerson(ctx, asset.UserID); err != nil {
			return err
		}
	}
	return q.InsertFace(ctx, db.InsertFaceParams{
		AssetID: asset.ID, UserID: asset.UserID, PersonID: person,
		X1: face.Box[0], Y1: face.Box[1], X2: face.Box[2], Y2: face.Box[3],
		Score: face.Score, Embedding: vector,
	})
}

type analyzeBackfillWorker struct {
	river.WorkerDefaults[AnalyzeBackfillArgs]
	*deps
}

func (w *analyzeBackfillWorker) Work(ctx context.Context, _ *river.Job[AnalyzeBackfillArgs]) error {
	if w.opts.MLURL == "" {
		return nil
	}
	ids, err := w.queries.ListUnanalyzed(ctx)
	if err != nil || len(ids) == 0 {
		return err
	}
	params := make([]river.InsertManyParams, len(ids))
	for i, id := range ids {
		params[i] = river.InsertManyParams{Args: AnalyzeArgs{AssetID: id.Bytes}}
	}
	_, err = w.client().InsertMany(ctx, params)
	return err
}

// CropFace makes a square picture of a face, with some room around it, once.
func CropFace(ctx context.Context, source, dest string, x1, y1, x2, y2 float32) error {
	if _, err := os.Stat(dest); err == nil { //nolint:gosec // Built from the cache folder and an ID.
		return nil
	}
	if err := os.MkdirAll(filepath.Dir(dest), 0o750); err != nil {
		return err
	}
	width, err := imageDimension(ctx, source, "width")
	if err != nil {
		return err
	}
	height, err := imageDimension(ctx, source, "height")
	if err != nil {
		return err
	}
	side := max(x2-x1, y2-y1) * (1 + 2*faceCropPadding)
	left := max(int((x1+x2-side)/2), 0)
	top := max(int((y1+y2-side)/2), 0)
	size := max(min(int(side), width-left, height-top), 1)
	tmp := dest + ".tmp.webp"
	defer func() { _ = os.Remove(tmp) }()
	if _, err := runTool(ctx, "vips", "extract_area", source, tmp, strconv.Itoa(left), strconv.Itoa(top), strconv.Itoa(size), strconv.Itoa(size)); err != nil {
		return err
	}
	if _, err := runTool(ctx, "vips", "thumbnail", tmp, dest+"[Q=85,strip]", strconv.Itoa(faceCropSize)); err != nil {
		return err
	}
	return nil
}
