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
	// How far apart two face vectors may be for the same person. Measured on 13 real photos of one
	// person: a chain of steps up to 0.655 connects them all, and the nearest other face was 0.839.
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
// planFace chooses who a new face belongs to. A face close to two people shows they are one, whatever
// order the photos arrived in. Only the user can say that about people they named or hid, so those
// are never merged, and a face goes to the named person rather than to a nearer unnamed one.
func planFace(near []db.PeopleNearFaceRow) (person pgtype.UUID, merge []pgtype.UUID) {
	if len(near) == 0 {
		return person, nil
	}
	target := &near[0]
	if target.Hidden {
		return target.ID, nil
	}
	for i := range near {
		if near[i].Name != "" && !near[i].Hidden {
			target = &near[i]
			break
		}
	}
	for i := range near {
		if other := &near[i]; other.ID != target.ID && other.Name == "" && !other.Hidden {
			merge = append(merge, other.ID)
		}
	}
	return target.ID, merge
}

// mergeNewlyConnected leaves apart anyone seen in one photo with the person, who cannot be the same.
func mergeNewlyConnected(ctx context.Context, q *db.Queries, person pgtype.UUID, candidates []pgtype.UUID, user pgtype.UUID) error {
	sources := []pgtype.UUID{}
	for _, candidate := range candidates {
		together, err := q.PeopleSeenTogether(ctx, db.PeopleSeenTogetherParams{First: person, Second: candidate})
		if err != nil {
			return err
		}
		if !together {
			sources = append(sources, candidate)
		}
	}
	if len(sources) == 0 {
		return nil
	}
	return MergePeople(ctx, q, person, sources, user)
}

// MergePeople makes several people one. A smart album that follows one of them follows the result.
func MergePeople(ctx context.Context, q *db.Queries, target pgtype.UUID, sources []pgtype.UUID, user pgtype.UUID) error {
	if err := q.MoveFaces(ctx, db.MoveFacesParams{Target: target, Sources: sources, UserID: user}); err != nil {
		return err
	}
	if err := q.MovePersonRules(ctx, db.MovePersonRulesParams{Target: target, Sources: sources, UserID: user}); err != nil {
		return err
	}
	return q.DeletePeople(ctx, db.DeletePeopleParams{Ids: sources, UserID: user})
}

func storeFace(ctx context.Context, q *db.Queries, asset *db.Asset, face *ml.Face) error {
	if !usableFace(face) {
		return nil
	}
	vector := ml.Vector(face.Embedding)
	near, err := q.PeopleNearFace(ctx, db.PeopleNearFaceParams{Embedding: vector, UserID: asset.UserID, MaxDistance: sameFaceDistance})
	if err != nil {
		return err
	}
	person, merge := planFace(near)
	if !person.Valid {
		if person, err = q.CreatePerson(ctx, asset.UserID); err != nil {
			return err
		}
	}
	if err := mergeNewlyConnected(ctx, q, person, merge, asset.UserID); err != nil {
		return err
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
