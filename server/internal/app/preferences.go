package app

import (
	"context"
	"encoding/json"
	"net/http"

	"github.com/jackc/pgx/v5/pgtype"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
)

const (
	minMemorySeconds = 1
	maxMemorySeconds = 60
	minFacesLow      = 1
	minFacesHigh     = 100
	maxHiddenCount   = 50
)

func defaultPreferences() api.UserPreferences {
	return api.UserPreferences{
		VideoAutoplay: true, ConfirmDelete: true, MemorySeconds: 4, MinFaces: 2,
		// Originals first: a converted version is smaller, and only a fallback.
		PhotoFull: true, VideoOriginal: true,
		AlbumOrder: api.UserPreferencesAlbumOrderNewest, HiddenSections: []string{},
	}
}

func (s *apiServer) preferences(ctx context.Context, user pgtype.UUID) (api.UserPreferences, error) {
	out := defaultPreferences()
	data, err := s.queries.GetUserPreferences(ctx, user)
	if db.IsNotFound(err) {
		return out, nil
	}
	if err != nil {
		return out, err
	}
	if err := json.Unmarshal(data, &out); err != nil {
		return defaultPreferences(), nil //nolint:nilerr // Unreadable choices are the same as none.
	}
	return out, nil
}

func (s *apiServer) GetMyPreferences(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	out, err := s.preferences(r.Context(), user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, out)
}

func (s *apiServer) SetMyPreferences(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	var body api.UserPreferences
	if !readJSON(w, r, &body) {
		return
	}
	switch {
	case body.MemorySeconds < minMemorySeconds || body.MemorySeconds > maxMemorySeconds:
		writeError(w, http.StatusBadRequest, "a picture shows for 1 to 60 seconds")
		return
	case body.MinFaces < minFacesLow || body.MinFaces > minFacesHigh:
		writeError(w, http.StatusBadRequest, "the number of faces must be between 1 and 100")
		return
	case body.AlbumOrder != api.UserPreferencesAlbumOrderNewest && body.AlbumOrder != api.UserPreferencesAlbumOrderOldest:
		writeError(w, http.StatusBadRequest, "unknown album order")
		return
	case len(body.HiddenSections) > maxHiddenCount:
		writeError(w, http.StatusBadRequest, "too many sections")
		return
	}
	data, err := json.Marshal(body)
	if err != nil {
		internalError(w, r, err)
		return
	}
	if err := s.queries.SetUserPreferences(r.Context(), db.SetUserPreferencesParams{UserID: user.ID, Data: data}); err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, body)
}
