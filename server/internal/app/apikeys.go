package app

import (
	"net/http"
	"slices"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/auth"
)

const (
	scopeRead   = "read"
	scopeUpload = "upload"
	scopeWrite  = "write"
	scopeAdmin  = "admin"
)

type scopesKey struct{}

// scopeFor names the right a request needs from a key. Empty means no key may do it at all: the
// account itself (password, two-factor sign-in, other keys) needs a person who signed in.
func scopeFor(method, path string) string {
	switch {
	case path == "/api/auth/status":
		return ""
	case strings.HasPrefix(path, "/api/me") || strings.HasPrefix(path, "/api/auth/"):
		return "none"
	case strings.HasPrefix(path, "/api/admin/"):
		return scopeAdmin
	case strings.HasPrefix(path, "/api/uploads") || path == "/api/assets/check":
		return scopeUpload
	case isWrite(method):
		return scopeWrite
	}
	return scopeRead
}

func keyMayDo(scopes []string, method, path string) bool {
	if !strings.HasPrefix(path, "/api/") || strings.HasPrefix(path, publicPathPrefix) || path == "/api/health" {
		return true
	}
	switch needed := scopeFor(method, path); needed {
	case "":
		return true
	case "none":
		return false
	default:
		return slices.Contains(scopes, needed)
	}
}

func (s *apiServer) ListAPIKeys(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	rows, err := s.queries.ListAPIKeys(r.Context(), user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := make([]api.ApiKey, len(rows))
	for i := range rows {
		row := &rows[i]
		scopes := make([]api.ApiKeyScopes, len(row.Scopes))
		for j, scope := range row.Scopes {
			scopes[j] = api.ApiKeyScopes(scope)
		}
		out[i] = api.ApiKey{
			Id: uuid.UUID(row.ID.Bytes), Name: row.Name, Scopes: scopes, CreatedAt: row.CreatedAt.Time,
			LastUsedAt: optional(row.LastUsedAt.Time, row.LastUsedAt.Valid),
			ExpiresAt:  optional(row.ExpiresAt.Time, row.ExpiresAt.Valid),
		}
	}
	writeJSON(w, http.StatusOK, out)
}

func (s *apiServer) CreateAPIKey(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	var body api.ApiKeyCreate
	if !readJSON(w, r, &body) {
		return
	}
	name := strings.TrimSpace(body.Name)
	if name == "" || len(name) > 100 {
		writeError(w, http.StatusBadRequest, "enter a name for the key")
		return
	}
	if len(body.Scopes) == 0 {
		writeError(w, http.StatusBadRequest, "choose at least one right")
		return
	}
	scopes := []string{}
	for _, scope := range body.Scopes {
		value := string(scope)
		if !slices.Contains([]string{scopeRead, scopeUpload, scopeWrite, scopeAdmin}, value) {
			writeError(w, http.StatusBadRequest, "unknown right: "+value)
			return
		}
		if value == scopeAdmin && !user.IsAdmin {
			writeError(w, http.StatusForbidden, "only an administrator can create an administrator's key")
			return
		}
		if !slices.Contains(scopes, value) {
			scopes = append(scopes, value)
		}
	}
	var expires pgtype.Timestamptz
	if body.ExpiresInDays != nil {
		days := *body.ExpiresInDays
		if days < 1 || days > 3650 {
			writeError(w, http.StatusBadRequest, "a key can last between 1 and 3650 days")
			return
		}
		expires = pgtype.Timestamptz{Time: time.Now().AddDate(0, 0, days), Valid: true}
	}
	key, hash, err := auth.NewToken()
	if err != nil {
		internalError(w, r, err)
		return
	}
	id, err := s.queries.CreateAPIKey(r.Context(), db.CreateAPIKeyParams{
		UserID: user.ID, Name: name, KeyHash: hash, Scopes: scopes, ExpiresAt: expires,
	})
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusCreated, api.DeviceKey{Id: uuid.UUID(id.Bytes), Key: key})
}
