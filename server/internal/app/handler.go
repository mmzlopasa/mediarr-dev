// Package app wires the HTTP API and the embedded web client together.
package app

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/jackc/pgx/v5/pgxpool"
	tusd "github.com/tus/tusd/v2/pkg/handler"

	"github.com/mmzlopasa/mediarr-app/server/db"
	"github.com/mmzlopasa/mediarr-app/server/internal/api"
	"github.com/mmzlopasa/mediarr-app/server/internal/auth"
	"github.com/mmzlopasa/mediarr-app/server/internal/jobs"
	"github.com/mmzlopasa/mediarr-app/server/internal/webui"
)

const (
	healthTimeout     = 2 * time.Second
	sessionCookie     = "mediarr_session"
	sessionLifetime   = 30 * 24 * time.Hour
	apiKeyHeader      = "X-Api-Key" //nolint:gosec // A header name, not a credential.
	loginWindow       = 15 * time.Minute
	loginFailuresUser = 10
	loginFailuresIP   = 50
	maxJSONBody       = 64 * 1024
)

// Pinger reports whether the database answers a query.
type Pinger interface {
	Ping(ctx context.Context) (int32, error)
}

// Deps are what the handlers need. Only Pinger is required for the health endpoint.
type Deps struct {
	Pinger      Pinger
	Pool        *pgxpool.Pool
	Inserter    *jobs.Inserter
	LibraryPath string
	CachePath   string
}

type apiServer struct {
	Deps
	queries       *db.Queries
	userLimiter   *auth.Limiter
	ipLimiter     *auth.Limiter
	linkPasswords *auth.Limiter
	linkUploads   *auth.Limiter
	uploads       *tusd.UnroutedHandler
	// fullPreviews limits how many full resolution previews are made at once.
	fullPreviews chan struct{}
}

// NewHandler returns the root HTTP handler.
func NewHandler(deps Deps) (http.Handler, error) {
	server := &apiServer{
		Deps:          deps,
		userLimiter:   auth.NewLimiter(loginFailuresUser, loginWindow),
		ipLimiter:     auth.NewLimiter(loginFailuresIP, loginWindow),
		linkPasswords: auth.NewLimiter(linkPasswordFailures, loginWindow),
		linkUploads:   auth.NewLimiter(linkUploadsPerHour, time.Hour),
		fullPreviews:  make(chan struct{}, 2),
	}
	if deps.Pool != nil {
		server.queries = db.New(deps.Pool)
		uploads, err := server.newUploadHandler()
		if err != nil {
			return nil, err
		}
		server.uploads = uploads
	}

	r := chi.NewRouter()
	r.Use(middleware.Recoverer)
	r.Use(requireJSONForWrites)
	if server.queries != nil {
		r.Use(server.loadUser)
	}
	r.NotFound(notFound)
	api.HandlerFromMux(server, r)
	return r, nil
}

func notFound(w http.ResponseWriter, r *http.Request) {
	if strings.HasPrefix(r.URL.Path, "/api/") {
		writeError(w, http.StatusNotFound, "not found")
		return
	}
	webui.Handler().ServeHTTP(w, r)
}

// requireJSONForWrites stops cross-site forms, which cannot send JSON, from reaching the JSON API.
func requireJSONForWrites(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodPost && strings.HasPrefix(r.URL.Path, "/api/") && r.URL.Path != "/api/uploads" && !isPublicUpload(r.URL.Path) &&
			r.ContentLength != 0 && !strings.HasPrefix(r.Header.Get("Content-Type"), "application/json") {
			writeError(w, http.StatusUnsupportedMediaType, "expected application/json")
			return
		}
		next.ServeHTTP(w, r)
	})
}

func isPublicUpload(path string) bool {
	return strings.HasPrefix(path, publicPathPrefix) && strings.HasSuffix(path, "/uploads")
}

func (s *apiServer) GetHealth(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), healthTimeout)
	defer cancel()

	code, status := http.StatusOK, api.Ok
	if _, err := s.Pinger.Ping(ctx); err != nil {
		slog.Error("health check failed", "error", err)
		code, status = http.StatusServiceUnavailable, api.Unavailable
	}
	writeJSON(w, code, api.Health{Status: status})
}

func writeJSON(w http.ResponseWriter, code int, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	if err := json.NewEncoder(w).Encode(body); err != nil {
		slog.Error("write response", "error", err)
	}
}

func writeError(w http.ResponseWriter, code int, message string) {
	writeJSON(w, code, api.Error{Message: message})
}

func internalError(w http.ResponseWriter, r *http.Request, err error) {
	path := r.URL.Path
	if strings.HasPrefix(path, publicPathPrefix) {
		path = publicPathPrefix + "…" // The token in the path opens the album, so it stays out of logs.
	}
	slog.Error("request failed", "path", path, "error", err)
	writeError(w, http.StatusInternalServerError, "something went wrong")
}

func readJSON(w http.ResponseWriter, r *http.Request, target any) bool {
	r.Body = http.MaxBytesReader(w, r.Body, maxJSONBody)
	if err := json.NewDecoder(r.Body).Decode(target); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return false
	}
	return true
}
