package jobs

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/riverqueue/river"
	"github.com/riverqueue/river/rivertype"

	"github.com/mediarr-app/mediarr/server/db"
)

// sameFace is how much two boxes must overlap to be the same face in two copies of a picture.
const sameFace = 0.5

// StateResolvingPrefix holds, per user, how far resolving all duplicates has come.
const StateResolvingPrefix = "duplicates_resolving:"

// ErrNothingToKeep is a group whose kept photo is not the owner's, or is gone.
var ErrNothingToKeep = errors.New("the photo to keep was not found")

// Merged is what one group gave its kept photo.
type Merged struct {
	Trashed    int64
	FreedBytes int64
	// Facts is true when the kept photo's own facts changed, and its sidecar is written again.
	Facts bool
}

// relativeFaces are faces in parts of their picture, so two copies of different sizes compare.
func relativeFaces(ctx context.Context, q *db.Queries, faces []db.NamedFacesOfRow) map[pgtype.UUID][4]float32 {
	sizes := map[pgtype.UUID][2]float32{}
	out := make(map[pgtype.UUID][4]float32, len(faces))
	for i := range faces {
		face := &faces[i]
		size, known := sizes[face.AssetID]
		if !known {
			if path, err := q.GetAssetFile(ctx, db.GetAssetFileParams{AssetID: face.AssetID, Kind: "thumb_large"}); err == nil {
				if width, height, err := PreviewSize(path); err == nil {
					size = [2]float32{width, height}
				}
			}
			sizes[face.AssetID] = size
		}
		out[face.ID] = RelativeBox(face.X1, face.Y1, face.X2, face.Y2, size[0], size[1])
	}
	return out
}

// MergeDuplicate gives the kept photo what the others of its group have and it lacks: albums, their
// covers, comments and hearts, tags, favorite, description, the highest rating, date, place and the
// names of faces. Then the others go to the trash. Run it inside a transaction.
func MergeDuplicate(ctx context.Context, q *db.Queries, user, keep pgtype.UUID, trash []pgtype.UUID) (Merged, error) {
	var out Merged
	facts, err := q.MergeFacts(ctx, db.MergeFactsParams{UserID: user, Column2: append([]pgtype.UUID{keep}, trash...)})
	if err != nil {
		return out, err
	}
	var kept *db.MergeFactsRow
	others := []db.MergeFactsRow{}
	for i := range facts {
		if facts[i].ID == keep {
			kept = &facts[i]
		} else {
			others = append(others, facts[i])
		}
	}
	if kept == nil {
		return out, ErrNothingToKeep
	}
	if len(others) == 0 {
		return out, nil
	}
	gone := make([]pgtype.UUID, len(others))
	for i := range others {
		gone[i] = others[i].ID
		out.FreedBytes += others[i].SizeBytes
	}

	if _, err := q.CopyAlbumMemberships(ctx, db.CopyAlbumMembershipsParams{Keep: keep, Trash: gone}); err != nil {
		return out, err
	}
	if err := q.MoveAlbumCovers(ctx, db.MoveAlbumCoversParams{Keep: keep, Trash: gone}); err != nil {
		return out, err
	}
	if err := q.MoveAlbumComments(ctx, db.MoveAlbumCommentsParams{Keep: keep, Trash: gone}); err != nil {
		return out, err
	}
	if err := q.CopyAlbumHearts(ctx, db.CopyAlbumHeartsParams{Keep: keep, Trash: gone}); err != nil {
		return out, err
	}
	if _, err := q.CopyAssetTags(ctx, db.CopyAssetTagsParams{Keep: keep, Trash: gone}); err != nil {
		return out, err
	}

	favorite, caption, rating := kept.IsFavorite, kept.Caption, kept.Rating
	var takenAt *db.MergeFactsRow
	var placed *db.MergeFactsRow
	for i := range others {
		other := &others[i]
		favorite = favorite || other.IsFavorite
		if caption == "" {
			caption = other.Caption
		}
		rating = max(rating, other.Rating)
		if takenAt == nil && other.TakenAt.Valid {
			takenAt = other
		}
		if placed == nil && other.Latitude.Valid && other.Longitude.Valid {
			placed = other
		}
	}
	if favorite != kept.IsFavorite || caption != kept.Caption || rating != kept.Rating {
		out.Facts = true
		if err := q.MergeOwnFacts(ctx, db.MergeOwnFactsParams{ID: keep, Favorite: favorite, Caption: caption, Rating: rating}); err != nil {
			return out, err
		}
	}
	if !kept.TakenAt.Valid && takenAt != nil {
		out.Facts = true
		if err := q.SetManualDate(ctx, db.SetManualDateParams{
			ID: keep, ManualTakenAt: takenAt.TakenAt, ManualOffsetMinutes: takenAt.TakenOffsetMinutes,
		}); err != nil {
			return out, err
		}
	}
	// A place taken away by hand stays away.
	if !kept.Latitude.Valid && !kept.ManualLocationNone && placed != nil {
		out.Facts = true
		if err := q.SetManualLocation(ctx, db.SetManualLocationParams{ID: keep, ManualLatitude: placed.Latitude, ManualLongitude: placed.Longitude}); err != nil {
			return out, err
		}
		if err := q.SetExifLocation(ctx, db.SetExifLocationParams{AssetID: keep, Latitude: placed.Latitude, Longitude: placed.Longitude}); err != nil {
			return out, err
		}
		if err := q.GeocodeAsset(ctx, keep); err != nil {
			return out, err
		}
	}
	if err := mergeFaces(ctx, q, keep, gone); err != nil {
		return out, err
	}

	out.Trashed, err = q.SoftDeleteAssets(ctx, db.SoftDeleteAssetsParams{UserID: user, Column2: gone})
	return out, err
}

// mergeFaces names the kept photo's faces after the copies' named ones in the same place. A face it
// has not found yet becomes a hint, which names it once it is found.
func mergeFaces(ctx context.Context, q *db.Queries, keep pgtype.UUID, gone []pgtype.UUID) error {
	faces, err := q.NamedFacesOf(ctx, append([]pgtype.UUID{keep}, gone...))
	if err != nil {
		return err
	}
	boxes := relativeFaces(ctx, q, faces)
	var own, named []*db.NamedFacesOfRow
	for i := range faces {
		switch {
		case faces[i].AssetID == keep:
			own = append(own, &faces[i])
		case faces[i].PersonID.Valid:
			named = append(named, &faces[i])
		}
	}
	for _, face := range named {
		var best *db.NamedFacesOfRow
		bestOverlap := float32(sameFace)
		for _, mine := range own {
			if o := overlap(boxes[face.ID], boxes[mine.ID]); o >= bestOverlap {
				best, bestOverlap = mine, o
			}
		}
		box := boxes[face.ID]
		var err error
		switch {
		case best == nil:
			// Hints are kept in parts of the picture.
			err = q.AddFaceHint(ctx, db.AddFaceHintParams{AssetID: keep, PersonID: face.PersonID, X1: box[0], Y1: box[1], X2: box[2], Y2: box[3]})
		case !best.PersonID.Valid:
			best.PersonID = face.PersonID
			err = q.NameFace(ctx, db.NameFaceParams{ID: best.ID, PersonID: face.PersonID})
		}
		if err != nil {
			return err
		}
	}
	return nil
}

// DuplicateChoice is one group: what stays and what goes.
type DuplicateChoice struct {
	Keep  uuid.UUID   `json:"keep"`
	Trash []uuid.UUID `json:"trash"`
}

// ResolveProgress is how far resolving all duplicates has come.
type ResolveProgress struct {
	Done     int        `json:"done"`
	Total    int        `json:"total"`
	Finished *time.Time `json:"finished,omitempty"`
}

// LoadResolveProgress reads it; ok is false when nothing is running for this user.
func LoadResolveProgress(ctx context.Context, q *db.Queries, user uuid.UUID) (ResolveProgress, bool, error) {
	var progress ResolveProgress
	raw, err := q.GetState(ctx, StateResolvingPrefix+user.String())
	if db.IsNotFound(err) {
		return progress, false, nil
	}
	if err != nil {
		return progress, false, err
	}
	if err := json.Unmarshal([]byte(raw), &progress); err != nil || progress.Finished != nil {
		return progress, false, nil //nolint:nilerr // An unreadable note is the same as none.
	}
	return progress, true, nil
}

// SaveResolveProgress writes it.
func SaveResolveProgress(ctx context.Context, q *db.Queries, user uuid.UUID, progress ResolveProgress) error {
	data, err := json.Marshal(progress)
	if err != nil {
		return err
	}
	return q.SetState(ctx, db.SetStateParams{Key: StateResolvingPrefix + user.String(), Value: string(data)})
}

// ResolveDuplicatesArgs resolves many groups, each by its own choice, one transaction each.
type ResolveDuplicatesArgs struct {
	UserID uuid.UUID         `json:"user_id"`
	Groups []DuplicateChoice `json:"groups"`
}

// Kind identifies the job in the queue.
func (ResolveDuplicatesArgs) Kind() string { return "resolve_duplicates" }

// InsertOpts runs one at a time for a person.
func (ResolveDuplicatesArgs) InsertOpts() river.InsertOpts {
	return river.InsertOpts{
		Queue: importQueue,
		UniqueOpts: river.UniqueOpts{ByArgs: true, ByState: []rivertype.JobState{
			rivertype.JobStateAvailable, rivertype.JobStatePending, rivertype.JobStateRetryable,
			rivertype.JobStateRunning, rivertype.JobStateScheduled,
		}},
	}
}

type resolveDuplicatesWorker struct {
	river.WorkerDefaults[ResolveDuplicatesArgs]
	*deps
}

const resolveDuplicatesLimit = time.Hour

func (w *resolveDuplicatesWorker) Timeout(*river.Job[ResolveDuplicatesArgs]) time.Duration {
	return resolveDuplicatesLimit
}

func (w *resolveDuplicatesWorker) Work(ctx context.Context, job *river.Job[ResolveDuplicatesArgs]) error {
	user := pgtype.UUID{Bytes: job.Args.UserID, Valid: true}
	progress := ResolveProgress{Total: len(job.Args.Groups)}
	if err := SaveResolveProgress(ctx, w.queries, job.Args.UserID, progress); err != nil {
		return err
	}
	for i, group := range job.Args.Groups {
		trash := make([]pgtype.UUID, len(group.Trash))
		for j, id := range group.Trash {
			trash[j] = pgtype.UUID{Bytes: id, Valid: true}
		}
		keep := pgtype.UUID{Bytes: group.Keep, Valid: true}
		err := pgx.BeginFunc(ctx, w.pool, func(tx pgx.Tx) error {
			merged, err := MergeDuplicate(ctx, w.queries.WithTx(tx), user, keep, trash)
			if err != nil || !merged.Facts {
				return err
			}
			_, err = w.client().InsertTx(ctx, tx, SidecarArgs{AssetID: group.Keep}, nil)
			return err
		})
		// A group that changed meanwhile, such as a photo already in the trash, is left as it is.
		if err != nil && !errors.Is(err, ErrNothingToKeep) {
			return err
		}
		progress.Done = i + 1
		if progress.Done%25 == 0 {
			if err := SaveResolveProgress(ctx, w.queries, job.Args.UserID, progress); err != nil {
				return err
			}
		}
	}
	now := time.Now()
	progress.Finished = &now
	return SaveResolveProgress(ctx, w.queries, job.Args.UserID, progress)
}
