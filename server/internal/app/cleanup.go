package app

import (
	"context"
	"net/http"

	"github.com/jackc/pgx/v5/pgtype"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
)

const (
	defaultBlur      = 3
	defaultVideoMB   = 500
	cleanupPage      = 120
	maxCleanupPage   = 500
	maxCleanupOffset = 1 << 30
	bytesPerMB       = 1 << 20
)

// blurBelow is how sharp a photo must be, at each level from the blurriest only to more of them. The
// measure is the variance of the Laplacian of a 512 pixel square, where a sharp photo has hundreds.
var blurBelow = [...]float32{1: 20, 2: 40, 3: 70, 4: 110, 5: 160}

func blurLevel(level *int) float32 {
	if level == nil || *level < 1 || *level >= len(blurBelow) {
		return blurBelow[defaultBlur]
	}
	return blurBelow[*level]
}

func videoBytes(mb *int) int64 {
	if mb == nil || *mb <= 0 {
		return defaultVideoMB * bytesPerMB
	}
	return int64(*mb) * bytesPerMB
}

func intOrNil[T ~int](value *T) *int {
	if value == nil {
		return nil
	}
	plain := int(*value)
	return &plain
}

func (s *apiServer) GetCleanup(w http.ResponseWriter, r *http.Request, params api.GetCleanupParams) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	ctx := r.Context()
	summary, err := s.cleanupSummary(ctx, user.ID, blurLevel(params.Blur), videoBytes(intOrNil(params.VideoMb)))
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, summary)
}

func (s *apiServer) cleanupSummary(ctx context.Context, user pgtype.UUID, below float32, atLeast int64) (api.CleanupSummary, error) {
	out := api.CleanupSummary{}
	blurry, err := s.queries.CountBlurry(ctx, db.CountBlurryParams{UserID: user, Below: below})
	if err != nil {
		return out, err
	}
	screenshots, err := s.queries.CountScreenshots(ctx, user)
	if err != nil {
		return out, err
	}
	videos, err := s.queries.CountLargeVideos(ctx, db.CountLargeVideosParams{UserID: user, AtLeast: atLeast})
	if err != nil {
		return out, err
	}
	bursts, err := s.queries.CountBursts(ctx, user)
	if err != nil {
		return out, err
	}
	pending, err := s.queries.CountUnfingerprinted(ctx, user)
	if err != nil {
		return out, err
	}
	out.Pending = pending
	out.Categories = []api.CleanupCategory{
		{Id: api.Blurry, Count: blurry.Count, Bytes: blurry.Bytes},
		{Id: api.Screenshots, Count: screenshots.Count, Bytes: screenshots.Bytes},
		{Id: api.LargeVideos, Count: videos.Count, Bytes: videos.Bytes},
		{Id: api.Bursts, Count: bursts.Count, Bytes: bursts.Bytes},
	}
	return out, nil
}

func cleanupItem(row *db.CleanupBlurryRow) api.CleanupItem {
	item := api.CleanupItem{
		Id: openapi_types.UUID(row.ID.Bytes), OriginalName: row.OriginalName, SizeBytes: row.SizeBytes,
		Kind:  api.CleanupItemKind(row.Kind),
		Width: optional(int(row.Width.Int32), row.Width.Valid), Height: optional(int(row.Height.Int32), row.Height.Valid),
		Ratio: ratioOf(row.AspectRatio, row.Width, row.Height), LocalAt: row.LocalAt.Time.Format(localTimeLayout),
		Favorite: row.IsFavorite, InAlbum: row.InAlbum,
	}
	if row.DurationMs.Valid {
		item.DurationMs = &row.DurationMs.Int64
	}
	return item
}

func (s *apiServer) ListCleanup(w http.ResponseWriter, r *http.Request, category api.CleanupCategoryId, params api.ListCleanupParams) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	limit, offset := cleanupPage, 0
	if params.Limit != nil {
		limit = min(max(*params.Limit, 1), maxCleanupPage)
	}
	if params.Offset != nil {
		offset = min(max(*params.Offset, 0), maxCleanupOffset)
	}
	ctx := r.Context()
	// One more than asked tells whether there is a next page.
	skip, want := int32(offset), int32(limit+1) //nolint:gosec // Both are bounded above.
	var rows []db.CleanupBlurryRow
	var err error
	switch category {
	case api.Blurry:
		rows, err = s.queries.CleanupBlurry(ctx, db.CleanupBlurryParams{UserID: user.ID, Below: blurLevel(params.Blur), Skip: skip, Max: want})
	case api.Screenshots:
		var found []db.CleanupScreenshotsRow
		found, err = s.queries.CleanupScreenshots(ctx, db.CleanupScreenshotsParams{UserID: user.ID, Skip: skip, Max: want})
		for i := range found {
			rows = append(rows, db.CleanupBlurryRow(found[i]))
		}
	case api.LargeVideos:
		var found []db.CleanupLargeVideosRow
		found, err = s.queries.CleanupLargeVideos(ctx, db.CleanupLargeVideosParams{
			UserID: user.ID, AtLeast: videoBytes(intOrNil(params.VideoMb)), Skip: skip, Max: want,
		})
		for i := range found {
			rows = append(rows, db.CleanupBlurryRow(found[i]))
		}
	case api.Bursts:
		var found []db.CleanupBurstsRow
		found, err = s.queries.CleanupBursts(ctx, db.CleanupBurstsParams{UserID: user.ID, Skip: skip, Max: want})
		for i := range found {
			rows = append(rows, db.CleanupBlurryRow(found[i]))
		}
	default:
		writeError(w, http.StatusBadRequest, "unknown kind of clean-up")
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	page := api.CleanupPage{Items: make([]api.CleanupItem, 0, min(len(rows), limit))}
	for i := range rows[:min(len(rows), limit)] {
		page.Items = append(page.Items, cleanupItem(&rows[i]))
	}
	if len(rows) > limit {
		next := offset + limit
		page.NextOffset = &next
	}
	writeJSON(w, http.StatusOK, page)
}

func (s *apiServer) KeepFromCleanup(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	var body api.AssetIds
	if !readJSON(w, r, &body) {
		return
	}
	if len(body.Ids) == 0 || len(body.Ids) > maxBulkIDs {
		writeError(w, http.StatusBadRequest, "choose between 1 and 1000 photos")
		return
	}
	if _, err := s.queries.KeepInCleanup(r.Context(), db.KeepInCleanupParams{UserID: user.ID, Column2: toPg(body.Ids)}); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
