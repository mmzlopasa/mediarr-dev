package app

import (
	"net/http"
	"net/http/httptest"
	"sync/atomic"
	"testing"
	"time"
)

func TestOpeningSearchLoadsTheModelOnceAWhile(t *testing.T) {
	var asked atomic.Int32
	service := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/clip/text" {
			asked.Add(1)
		}
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"embedding":[0.1]}`))
	}))
	t.Cleanup(service.Close)
	s := newStack(t)
	s.useML(t, service)
	c := s.admin()
	lastWarm.Store(0)

	resp, body := s.client().post("/api/search/warm", nil)
	expect(t, resp, body, http.StatusUnauthorized)
	for range 3 {
		resp, body = c.post("/api/search/warm", nil)
		expect(t, resp, body, http.StatusNoContent)
	}
	deadline := time.Now().Add(5 * time.Second)
	for asked.Load() == 0 && time.Now().Before(deadline) {
		time.Sleep(20 * time.Millisecond)
	}
	time.Sleep(100 * time.Millisecond)
	// Many open search pages ask the model once.
	if got := asked.Load(); got != 1 {
		t.Fatalf("asked %d times", got)
	}
}
