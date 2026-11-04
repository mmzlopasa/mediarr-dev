package app

import (
	"context"
	"net/http"
	"slices"

	"github.com/jackc/pgx/v5/pgtype"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

const maxDuplicateGroups = 100

// stackMain names the shot a stack hangs from. A shot that is not in a stack hangs from itself.
func stackMain(row *db.Asset) pgtype.UUID {
	if row.StackParent.Valid {
		return row.StackParent
	}
	return row.ID
}

// stackOf returns nothing for a shot that stands alone.
func (s *apiServer) stackOf(ctx context.Context, row *db.Asset) (*[]openapi_types.UUID, error) {
	ids, err := s.queries.ListStack(ctx, stackMain(row))
	if err != nil || len(ids) < 2 {
		return nil, err
	}
	out := make([]openapi_types.UUID, len(ids))
	for i, id := range ids {
		out[i] = id.Bytes
	}
	return &out, nil
}

// ownedStack finds the stack of a shot, and answers by itself if there is none.
func (s *apiServer) ownedStack(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) (pgtype.UUID, bool) {
	var none pgtype.UUID
	user := requireUser(w, r)
	if user == nil {
		return none, false
	}
	row, err := s.queries.GetOwnedAsset(r.Context(), db.GetOwnedAssetParams{ID: pgUUID(id), UserID: user.ID})
	if db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "no such asset")
		return none, false
	}
	if err != nil {
		internalError(w, r, err)
		return none, false
	}
	ids, err := s.queries.ListStack(r.Context(), stackMain(&row))
	if err != nil {
		internalError(w, r, err)
		return none, false
	}
	if len(ids) < 2 {
		writeError(w, http.StatusNotFound, "this photo is not in a stack")
		return none, false
	}
	return stackMain(&row), true
}

func (s *apiServer) SetStackMain(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	main, ok := s.ownedStack(w, r, id)
	if !ok {
		return
	}
	if err := s.queries.SetStackMain(r.Context(), db.SetStackMainParams{NewMain: pgUUID(id), OldMain: main}); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) DissolveStack(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	main, ok := s.ownedStack(w, r, id)
	if !ok {
		return
	}
	if err := s.queries.DissolveStack(r.Context(), main); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// keepOf proposes the largest picture: a favorite first, then pixels, then bytes, then sharpness.
func keepOf(items []db.ListSimilarItemsRow) pgtype.UUID {
	best := &items[0]
	pixels := func(row *db.ListSimilarItemsRow) int64 { return int64(row.Width.Int32) * int64(row.Height.Int32) }
	for i := range items[1:] {
		row := &items[i+1]
		switch {
		case row.IsFavorite != best.IsFavorite:
			if row.IsFavorite {
				best = row
			}
		case pixels(row) != pixels(best):
			if pixels(row) > pixels(best) {
				best = row
			}
		case row.SizeBytes != best.SizeBytes:
			if row.SizeBytes > best.SizeBytes {
				best = row
			}
		case row.Sharpness.Float32 > best.Sharpness.Float32:
			best = row
		}
	}
	return best.ID
}

func (s *apiServer) ListDuplicates(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	ctx := r.Context()
	pending, err := s.queries.CountUnorganized(ctx, user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	rows, err := s.queries.ListSimilarPairs(ctx, user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	pairs := make([][2]pgtype.UUID, len(rows))
	for i := range rows {
		pairs[i] = [2]pgtype.UUID{rows[i].AID, rows[i].BID}
	}
	groups := jobs.GroupPairs(pairs)
	ids := []pgtype.UUID{}
	for _, group := range groups {
		ids = append(ids, group...)
	}
	items, err := s.queries.ListSimilarItems(ctx, db.ListSimilarItemsParams{Column1: ids, UserID: user.ID})
	if err != nil {
		internalError(w, r, err)
		return
	}
	byID := make(map[pgtype.UUID]*db.ListSimilarItemsRow, len(items))
	for i := range items {
		byID[items[i].ID] = &items[i]
	}
	out := make([]api.DuplicateGroup, 0, min(len(groups), maxDuplicateGroups))
	newest := func(group []pgtype.UUID) int64 {
		latest := int64(0)
		for _, id := range group {
			latest = max(latest, byID[id].LocalAt.Time.Unix())
		}
		return latest
	}
	slices.SortStableFunc(groups, func(a, b []pgtype.UUID) int { return int(max(min(newest(b)-newest(a), 1), -1)) })
	for _, group := range groups[:min(len(groups), maxDuplicateGroups)] {
		out = append(out, duplicateGroup(group, byID))
	}
	writeJSON(w, http.StatusOK, api.Duplicates{Total: len(groups), Pending: int(pending), Groups: out})
}

func duplicateGroup(group []pgtype.UUID, byID map[pgtype.UUID]*db.ListSimilarItemsRow) api.DuplicateGroup {
	rows := make([]db.ListSimilarItemsRow, len(group))
	items := make([]api.DuplicateItem, len(group))
	for i, id := range group {
		row := byID[id]
		rows[i] = *row
		items[i] = api.DuplicateItem{
			Id: row.ID.Bytes, OriginalName: row.OriginalName, SizeBytes: row.SizeBytes,
			Width: optional(int(row.Width.Int32), row.Width.Valid), Height: optional(int(row.Height.Int32), row.Height.Valid),
			Ratio: ratioOf(row.AspectRatio, row.Width, row.Height), LocalAt: row.LocalAt.Time.Format(localTimeLayout),
		}
	}
	return api.DuplicateGroup{KeepId: openapi_types.UUID(keepOf(rows).Bytes), Items: items}
}

func (s *apiServer) DismissDuplicates(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	var body api.AssetIds
	if !readJSON(w, r, &body) {
		return
	}
	ids := make([]pgtype.UUID, len(body.Ids))
	for i, id := range body.Ids {
		ids[i] = pgUUID(id)
	}
	if err := s.queries.DismissSimilar(r.Context(), db.DismissSimilarParams{UserID: user.ID, Column2: ids}); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
