package ml

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync/atomic"
	"testing"
)

func serve(t *testing.T, handler http.HandlerFunc) *httptest.Server {
	t.Helper()
	server := httptest.NewServer(handler)
	t.Cleanup(server.Close)
	return server
}

func TestTheTokenIsSentOnEveryRequest(t *testing.T) {
	var auth atomic.Value
	server := serve(t, func(w http.ResponseWriter, r *http.Request) {
		auth.Store(r.Header.Get("Authorization"))
		if err := json.NewEncoder(w).Encode(map[string]any{"embedding": []float32{1}}); err != nil {
			t.Error(err)
		}
	})
	if _, err := New(server.URL, "secret").EmbedText(context.Background(), "beach"); err != nil {
		t.Fatal(err)
	}
	if got := auth.Load(); got != "Bearer secret" {
		t.Fatalf("Authorization: %v", got)
	}
	if _, err := New(server.URL, "").EmbedText(context.Background(), "beach"); err != nil {
		t.Fatal(err)
	}
	if got := auth.Load(); got != "" {
		t.Fatalf("Authorization without a token: %v", got)
	}
}

func TestTheTokenDoesNotFollowARedirect(t *testing.T) {
	var reached atomic.Bool
	elsewhere := serve(t, func(http.ResponseWriter, *http.Request) { reached.Store(true) })
	server := serve(t, func(w http.ResponseWriter, r *http.Request) {
		http.Redirect(w, r, elsewhere.URL, http.StatusFound)
	})
	if _, err := New(server.URL, "secret").Status(context.Background()); err == nil {
		t.Fatal("a redirect counted as an answer")
	}
	if reached.Load() {
		t.Fatal("the request went to another address")
	}
}

func TestAWrongTokenIsNotAnUnreachableService(t *testing.T) {
	server := serve(t, func(w http.ResponseWriter, _ *http.Request) {
		http.Error(w, `{"detail":"wrong token"}`, http.StatusUnauthorized)
	})
	_, err := New(server.URL, "secret").Status(context.Background())
	if !errors.Is(err, ErrWrongToken) {
		t.Fatalf("got %v", err)
	}
	if !strings.Contains(err.Error(), "token") {
		t.Fatalf("the message does not say what is wrong: %v", err)
	}
}

func TestWhatIsWorthWaitingFor(t *testing.T) {
	dead := httptest.NewServer(http.NotFoundHandler())
	dead.Close()
	_, unreachable := New(dead.URL, "").EmbedText(context.Background(), "x")
	cases := []struct {
		name string
		err  error
		want bool
	}{
		{"nothing answers", unreachable, true},
		{"wrong token", ErrWrongToken, true},
		{"service restarting", &StatusError{Path: "/faces", Code: http.StatusServiceUnavailable}, true},
		{"not a picture", &StatusError{Path: "/faces", Code: http.StatusUnprocessableEntity}, false},
		{"not turned on", ErrDisabled, false},
		{"no error", nil, false},
	}
	for _, c := range cases {
		if got := Unavailable(c.err); got != c.want {
			t.Errorf("%s: %v", c.name, got)
		}
	}
}

func TestStatus(t *testing.T) {
	server := serve(t, func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/status" {
			t.Errorf("path %s", r.URL.Path)
		}
		_, _ = w.Write([]byte(`{"models":[{"name":"clip-text","loaded":true,"in_use":0,"idle_seconds":3.5}],
			"rss_bytes":1234,"acceleration":{"requested":"cpu","providers":["CPUExecutionProvider"]},"idle_minutes":5}`))
	})
	status, err := New(server.URL, "").Status(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if len(status.Models) != 1 || !status.Models[0].Loaded || status.Models[0].IdleSeconds == nil || *status.Models[0].IdleSeconds != 3.5 ||
		status.RSSBytes == nil || *status.RSSBytes != 1234 || status.Acceleration.Requested != "cpu" || status.IdleMinutes != 5 {
		t.Fatalf("%+v", status)
	}
}

func TestSearchesDoNotQueueBehindADeadService(t *testing.T) {
	var calls atomic.Int32
	server := serve(t, func(w http.ResponseWriter, _ *http.Request) {
		calls.Add(1)
		w.WriteHeader(http.StatusServiceUnavailable)
	})
	cache := NewCache(New(server.URL, ""))
	if _, err := cache.Text(context.Background(), "beach"); !Unavailable(err) {
		t.Fatalf("got %v", err)
	}
	if _, err := cache.Text(context.Background(), "forest"); !errors.Is(err, ErrCoolingOff) {
		t.Fatalf("got %v", err)
	}
	if calls.Load() != 1 {
		t.Fatalf("the service was asked %d times", calls.Load())
	}
}
