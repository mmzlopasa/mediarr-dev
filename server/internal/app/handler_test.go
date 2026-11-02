package app

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
)

type fakePinger struct{ err error }

func (f fakePinger) Ping(context.Context) (int32, error) { return 1, f.err }

func newTestHandler(t *testing.T, pinger Pinger) http.Handler {
	t.Helper()
	handler, err := NewHandler(Deps{Pinger: pinger})
	if err != nil {
		t.Fatal(err)
	}
	return handler
}

func TestHealth(t *testing.T) {
	tests := []struct {
		name     string
		pingErr  error
		wantCode int
		wantBody string
	}{
		{"database reachable", nil, http.StatusOK, `{"status":"ok"}` + "\n"},
		{"database down", errors.New("down"), http.StatusServiceUnavailable, `{"status":"unavailable"}` + "\n"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rec := httptest.NewRecorder()
			req := httptest.NewRequest(http.MethodGet, "/health", http.NoBody)

			newTestHandler(t, fakePinger{err: tt.pingErr}).ServeHTTP(rec, req)

			if rec.Code != tt.wantCode {
				t.Errorf("status = %d, want %d", rec.Code, tt.wantCode)
			}
			if got := rec.Body.String(); got != tt.wantBody {
				t.Errorf("body = %q, want %q", got, tt.wantBody)
			}
			if got := rec.Header().Get("Content-Type"); got != "application/json" {
				t.Errorf("Content-Type = %q", got)
			}
		})
	}
}

func TestPostHealthNotAllowed(t *testing.T) {
	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, "/health", http.NoBody)

	newTestHandler(t, fakePinger{}).ServeHTTP(rec, req)

	if rec.Code != http.StatusMethodNotAllowed {
		t.Errorf("status = %d, want %d", rec.Code, http.StatusMethodNotAllowed)
	}
}
