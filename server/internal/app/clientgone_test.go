package app

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestARequestTheBrowserAbandonedIsNotLoggedAsAnError(t *testing.T) {
	var logged bytes.Buffer
	previous := slog.Default()
	slog.SetDefault(slog.New(slog.NewTextHandler(&logged, &slog.HandlerOptions{Level: slog.LevelInfo})))
	t.Cleanup(func() { slog.SetDefault(previous) })

	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	gone := httptest.NewRequest(http.MethodGet, "/api/assets/x/thumbnail", http.NoBody).WithContext(ctx)
	internalError(httptest.NewRecorder(), gone, fmt.Errorf("vips: %w", context.Canceled))
	if logged.Len() != 0 {
		t.Errorf("logged: %s", logged.String())
	}

	// A canceled context the server made itself, while the browser still waits, is a real failure.
	waiting := httptest.NewRequest(http.MethodGet, "/api/assets/x/thumbnail", http.NoBody)
	recorder := httptest.NewRecorder()
	internalError(recorder, waiting, fmt.Errorf("vips: %w", context.Canceled))
	if !strings.Contains(logged.String(), "request failed") || recorder.Code != http.StatusInternalServerError {
		t.Errorf("a real failure was not logged: %q, %d", logged.String(), recorder.Code)
	}

	logged.Reset()
	internalError(httptest.NewRecorder(), gone, errors.New("disk full"))
	if !strings.Contains(logged.String(), "disk full") {
		t.Errorf("another error on a closed request was hidden")
	}
}
