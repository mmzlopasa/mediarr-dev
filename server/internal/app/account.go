package app

import (
	"bytes"
	"net/http"

	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/auth"
)

func currentTokenHash(r *http.Request) []byte {
	cookie, err := r.Cookie(sessionCookie)
	if err != nil {
		return nil
	}
	return auth.HashToken(cookie.Value)
}

func (s *apiServer) ListMySessions(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	rows, err := s.queries.ListUserSessions(r.Context(), user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	current := currentTokenHash(r)
	out := make([]api.UserSession, len(rows))
	for i := range rows {
		row := &rows[i]
		out[i] = api.UserSession{
			Id: openapi_types.UUID(row.ID.Bytes), UserAgent: row.UserAgent, Ip: row.Ip,
			CreatedAt: row.CreatedAt.Time, LastSeenAt: row.LastSeenAt.Time,
			Current: bytes.Equal(row.TokenHash, current),
		}
	}
	writeJSON(w, http.StatusOK, out)
}

func (s *apiServer) EndSession(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	changed, err := s.queries.DeleteUserSession(r.Context(), db.DeleteUserSessionParams{ID: pgUUID(id), UserID: user.ID})
	if err != nil {
		internalError(w, r, err)
		return
	}
	if changed == 0 {
		writeError(w, http.StatusNotFound, "not found")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) EndOtherSessions(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	if err := s.queries.DeleteOtherSessions(r.Context(), db.DeleteOtherSessionsParams{UserID: user.ID, Keep: currentTokenHash(r)}); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) GetMyStats(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	row, err := s.queries.AccountStats(r.Context(), user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, api.AccountStats{
		Photos: row.Photos, Videos: row.Videos, Favorites: row.Favorites, Archived: row.Archived,
		Trashed: row.Trashed, Albums: row.Albums, Bytes: row.Bytes,
	})
}
