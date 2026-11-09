package app

import (
	"context"
	"net/http"

	"github.com/jackc/pgx/v5/pgtype"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/mediarr-app/mediarr/server/db"
)

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
