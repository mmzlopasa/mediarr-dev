// Package app wires the HTTP API and the embedded web client together.
package app

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"

	"github.com/mmzlopasa/mediarr-app/server/internal/api"
	"github.com/mmzlopasa/mediarr-app/server/internal/webui"
)

const healthTimeout = 2 * time.Second

// Pinger reports whether the database answers a query.
type Pinger interface {
	Ping(ctx context.Context) (int32, error)
}

// NewHandler returns the root HTTP handler.
func NewHandler(pinger Pinger) http.Handler {
	r := chi.NewRouter()
	r.Use(middleware.Recoverer)
	r.NotFound(webui.Handler().ServeHTTP)
	api.HandlerFromMux(&apiServer{pinger: pinger}, r)
	return r
}

type apiServer struct {
	pinger Pinger
}

func (s *apiServer) GetHealth(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), healthTimeout)
	defer cancel()

	code, status := http.StatusOK, api.Ok
	if _, err := s.pinger.Ping(ctx); err != nil {
		slog.Error("health check failed", "error", err)
		code, status = http.StatusServiceUnavailable, api.Unavailable
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	if err := json.NewEncoder(w).Encode(api.Health{Status: status}); err != nil {
		slog.Error("write health response", "error", err)
	}
}
