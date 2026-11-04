package app

import (
	"context"
	"log/slog"
	"net"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/auth"
)

const (
	rateWindow   = time.Minute
	rateWrites   = 1200
	rateSearches = 120
	ratePublic   = 6000
	rateAnon     = 600
	auditPage    = 100
	maxAuditPage = 500
)

// Limits for each kind of request per minute. They stop abuse, and are far above what a person,
// a phone backing up or a page full of thumbnails ever reaches.
type rateLimits struct {
	writes, searches, public, anonymous *auth.Limiter
}

func newRateLimits() *rateLimits {
	return &rateLimits{
		writes:    auth.NewLimiter(rateWrites, rateWindow),
		searches:  auth.NewLimiter(rateSearches, rateWindow),
		public:    auth.NewLimiter(ratePublic, rateWindow),
		anonymous: auth.NewLimiter(rateAnon, rateWindow),
	}
}

// isChunkTraffic is what a backup sends for every file, and it has its own checks.
func isChunkTraffic(path string) bool {
	return strings.HasPrefix(path, "/api/uploads") || strings.HasSuffix(path, "/uploads") || path == "/api/assets/check"
}

func isWrite(method string) bool {
	return method != http.MethodGet && method != http.MethodHead && method != http.MethodOptions
}

// limiterFor picks the limit for a request, or none.
func (l *rateLimits) limiterFor(method, path string, signedIn bool) *auth.Limiter {
	switch {
	case !strings.HasPrefix(path, "/api/") || path == "/api/health" || isChunkTraffic(path):
		return nil
	case strings.HasPrefix(path, publicPathPrefix):
		return l.public
	case !signedIn:
		return l.anonymous
	case path == "/api/search":
		return l.searches
	case isWrite(method):
		return l.writes
	}
	return nil
}

type auditKey struct{}

// auditNote lets a handler name who is acting when the session does not say yet, as at sign-in.
type auditNote struct{ email string }

func noteAuditEmail(r *http.Request, email string) {
	if note, ok := r.Context().Value(auditKey{}).(*auditNote); ok {
		note.email = email
	}
}

func hostOnly(address string) string {
	if host, _, err := net.SplitHostPort(address); err == nil {
		return host
	}
	return address
}

// auditTarget names what was acted on. A link's token is left out: it is as good as a password.
func auditTarget(r *http.Request) string {
	route := chi.RouteContext(r.Context())
	if route == nil {
		return ""
	}
	parts := []string{}
	for i, key := range route.URLParams.Keys {
		if key == "*" || key == "token" || i >= len(route.URLParams.Values) {
			continue
		}
		parts = append(parts, key+"="+route.URLParams.Values[i])
	}
	return strings.Join(parts, " ")
}

// limitAndAudit applies the limits, and records every change made through the API.
func (s *apiServer) limitAndAudit(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		user := currentUser(r)
		key := hostOnly(clientIP(r))
		if user != nil {
			key = user.Email
		}
		if limiter := s.limits.limiterFor(r.Method, r.URL.Path, user != nil); limiter != nil {
			if !limiter.Allowed(key) {
				w.Header().Set("Retry-After", strconv.Itoa(int(rateWindow.Seconds())))
				writeError(w, http.StatusTooManyRequests, "too many requests, try again in a minute")
				return
			}
			limiter.Fail(key)
		}
		if !strings.HasPrefix(r.URL.Path, "/api/") || !isWrite(r.Method) || isChunkTraffic(r.URL.Path) {
			next.ServeHTTP(w, r)
			return
		}
		note := &auditNote{}
		wrapped := middleware.NewWrapResponseWriter(w, r.ProtoMajor)
		next.ServeHTTP(wrapped, r.WithContext(context.WithValue(r.Context(), auditKey{}, note)))
		// Addresses that lead nowhere are not worth keeping for a year, and could hold anything.
		if route := chi.RouteContext(r.Context()); route == nil || route.RoutePattern() == "" {
			return
		}
		s.recordAudit(r, user, note, wrapped.Status())
	})
}

func (s *apiServer) recordAudit(r *http.Request, user *db.User, note *auditNote, status int) {
	params := db.InsertAuditParams{
		UserEmail: note.email, Method: r.Method, Route: "unknown", Target: auditTarget(r),
		Status: int32(status), //nolint:gosec // An HTTP status.
		Ip:     hostOnly(clientIP(r)),
	}
	if route := chi.RouteContext(r.Context()); route != nil && route.RoutePattern() != "" {
		params.Route = route.RoutePattern()
	}
	if user != nil {
		params.UserID = pgtype.UUID{Bytes: user.ID.Bytes, Valid: true}
		params.UserEmail = user.Email
	}
	// The change has already happened, so the record is made even if the client has gone away.
	if err := s.queries.InsertAudit(context.WithoutCancel(r.Context()), params); err != nil {
		slog.Error("the audit log could not be written", "route", params.Route, "error", err)
	}
}

func (s *apiServer) ListAuditLog(w http.ResponseWriter, r *http.Request, params api.ListAuditLogParams) {
	if requireAdmin(w, r) == nil {
		return
	}
	limit := auditPage
	if params.Limit != nil && *params.Limit > 0 {
		limit = min(*params.Limit, maxAuditPage)
	}
	query := db.ListAuditParams{RowLimit: int32(limit)} //nolint:gosec // Limited above.
	if params.Before != nil {
		query.Before = pgtype.Int8{Int64: *params.Before, Valid: true}
	}
	rows, err := s.queries.ListAudit(r.Context(), query)
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := make([]api.AuditEntry, len(rows))
	for i := range rows {
		row := &rows[i]
		out[i] = api.AuditEntry{
			Id: row.ID, At: row.At.Time, UserEmail: row.UserEmail, Method: row.Method, Route: row.Route,
			Target: row.Target, Status: int(row.Status), Ip: row.Ip,
		}
	}
	writeJSON(w, http.StatusOK, out)
}
