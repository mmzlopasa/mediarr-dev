// Package app wires the HTTP API and the embedded web client together.
package app

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"net/url"
	"strings"
	"syscall"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/jackc/pgx/v5/pgxpool"
	tusd "github.com/tus/tusd/v2/pkg/handler"

	"github.com/mmzlopasa/mediarr-app/server/db"
	"github.com/mmzlopasa/mediarr-app/server/internal/api"
	"github.com/mmzlopasa/mediarr-app/server/internal/auth"
	"github.com/mmzlopasa/mediarr-app/server/internal/jobs"
	"github.com/mmzlopasa/mediarr-app/server/internal/ml"
	"github.com/mmzlopasa/mediarr-app/server/internal/webui"
)

const (
	healthTimeout     = 2 * time.Second
	sessionCookie     = "mediarr_session"
	sessionLifetime   = 30 * 24 * time.Hour
	apiKeyHeader      = "X-Api-Key" //nolint:gosec // A header name, not a credential.
	loginWindow       = 15 * time.Minute
	minFreeDiskBytes  = 1 << 30
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
	// ExternalPath is where the folder of EXTERNAL_LIBRARY_PATH is mounted, read only.
	ExternalPath string
	// ProxyHops is how many reverse proxies stand in front of the bundled nginx.
	ProxyHops int
	// MaxUploadBytes limits one file, if above zero.
	MaxUploadBytes int64
	// MetricsToken turns on /metrics, for whoever has it.
	MetricsToken string
	// BackupPath is where the folder of BACKUP_PATH is mounted.
	BackupPath string
	CachePath  string
	// MLURL is empty when picture analysis is not turned on.
	MLURL string
}

type apiServer struct {
	Deps
	queries           *db.Queries
	userLimiter       *auth.Limiter
	ipLimiter         *auth.Limiter
	linkPasswords     *auth.Limiter
	linkUploads       *auth.Limiter
	vaultPins         *auth.Limiter
	limits            *rateLimits
	metrics           *metrics
	oidcFlows         *shortLived[oidcFlow]
	oidcCodes         *shortLived[oidcAppCode]
	passkeyChallenges *shortLived[passkeyChallenge]
	guestBytes        *byteBudget
	uploads           *tusd.UnroutedHandler
	// fullPreviews limits how many full resolution previews are made at once.
	fullPreviews chan struct{}
	embeddings   *ml.Cache
}

// NewHandler returns the root HTTP handler.
func NewHandler(deps Deps) (http.Handler, error) {
	server := &apiServer{
		Deps:              deps,
		userLimiter:       auth.NewLimiter(loginFailuresUser, loginWindow),
		ipLimiter:         auth.NewLimiter(loginFailuresIP, loginWindow),
		linkPasswords:     auth.NewLimiter(linkPasswordFailures, loginWindow),
		linkUploads:       auth.NewLimiter(linkUploadsPerHour, time.Hour),
		vaultPins:         auth.NewLimiter(vaultPinFailures, loginWindow),
		fullPreviews:      make(chan struct{}, 2),
		limits:            newRateLimits(),
		oidcFlows:         newShortLived[oidcFlow](),
		oidcCodes:         newShortLived[oidcAppCode](),
		passkeyChallenges: newShortLived[passkeyChallenge](),
		guestBytes:        newByteBudget(),
	}
	if deps.Pool != nil {
		server.queries = db.New(deps.Pool)
		uploads, err := server.newUploadHandler()
		if err != nil {
			return nil, err
		}
		server.uploads = uploads
	}

	server.embeddings = ml.NewCache(ml.New(deps.MLURL))
	server.metrics = newMetrics(server)
	r := chi.NewRouter()
	r.Use(traced)
	r.Use(server.metrics.observe)
	r.Use(middleware.Recoverer)
	r.Use(trustProxies(deps.ProxyHops))
	r.Use(requireJSONForWrites)
	r.Use(sameOriginWrites)
	if server.queries != nil {
		r.Use(server.loadUser)
		r.Use(server.limitAndAudit)
	}
	r.NotFound(notFound)
	r.Get("/metrics", server.serveMetrics)
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

// sameOriginWrites stops another site from using the cookie of a signed-in user. A form with no
// body gets past the JSON check above, and a page on another port of the same address is same-site
// to the browser, so cookies alone do not settle it. Apps send no Origin at all.
func sameOriginWrites(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if origin := r.Header.Get("Origin"); origin != "" && isWrite(r.Method) && strings.HasPrefix(r.URL.Path, "/api/") {
			parsed, err := url.Parse(origin)
			if err != nil || !strings.EqualFold(parsed.Host, r.Host) {
				writeError(w, http.StatusForbidden, "this request came from another site")
				return
			}
		}
		next.ServeHTTP(w, r)
	})
}

// forwardedClient finds the visitor's address in X-Forwarded-For, counting from the right, because
// anything further left was written by the visitor. It returns nothing if there are too few entries.
func forwardedClient(header string, hops int) string {
	parts := strings.Split(header, ",")
	at := len(parts) - 1 - hops
	if hops <= 0 || at < 0 {
		return ""
	}
	return strings.TrimSpace(parts[at])
}

// trustProxies makes the limits and the log see the visitor instead of the user's own proxy.
func trustProxies(hops int) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if client := forwardedClient(r.Header.Get("X-Forwarded-For"), hops); client != "" {
				r.Header.Set("X-Real-IP", client)
			}
			next.ServeHTTP(w, r)
		})
	}
}

// checkDiskRoom refuses a file that would fill the disk, which would also stop the database.
func (s *apiServer) checkDiskRoom(size int64) error {
	if s.MaxUploadBytes > 0 && size > s.MaxUploadBytes {
		return tusd.NewError("ERR_TOO_LARGE", "this file is larger than this server allows", http.StatusRequestEntityTooLarge)
	}
	var disk syscall.Statfs_t
	if err := syscall.Statfs(s.LibraryPath, &disk); err != nil {
		return nil //nolint:nilerr // The upload then fails on its own if the disk really is the problem.
	}
	free := int64(disk.Bavail) * disk.Bsize //nolint:gosec // Disk sizes fit.
	if free-size < minFreeDiskBytes {
		return tusd.NewError("ERR_DISK_FULL", "the server's disk is full", http.StatusInsufficientStorage)
	}
	return nil
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
