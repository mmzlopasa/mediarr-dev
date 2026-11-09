package app

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/mediarr-app/mediarr/server/internal/api"
)

func TestAdminSeesTheAnalysisService(t *testing.T) {
	service := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("Authorization") != "Bearer right" {
			http.Error(w, `{"detail":"no"}`, http.StatusUnauthorized)
			return
		}
		_, _ = w.Write([]byte(`{"models":[{"name":"clip-text","loaded":true,"in_use":0,"idle_seconds":1},{"name":"ocr","loaded":false,"in_use":0,"idle_seconds":null}],
			"rss_bytes":104857600,"acceleration":{"requested":"cpu","providers":["CPUExecutionProvider"]},"idle_minutes":5}`))
	}))
	t.Cleanup(service.Close)
	s := newStack(t)
	c := s.admin()
	health := func() api.AdminHealth {
		resp, body := c.get("/api/admin/health")
		expect(t, resp, body, http.StatusOK)
		return decode[api.AdminHealth](t, body)
	}

	s.useMLAt(t, service.URL, "right")
	got := health()
	if got.Ml == nil || got.Ml.State != api.Connected || got.MlRunning == nil || !*got.MlRunning {
		t.Fatalf("connected: %+v", got)
	}
	if got.Ml.Models == nil || len(*got.Ml.Models) != 2 || !(*got.Ml.Models)[0].Loaded || got.Ml.RssBytes == nil || *got.Ml.RssBytes != 104857600 ||
		got.Ml.Acceleration == nil || got.Ml.Acceleration.Requested != "cpu" {
		t.Fatalf("details: %+v", got.Ml)
	}

	s.useMLAt(t, service.URL, "wrong")
	if got := health(); got.Ml == nil || got.Ml.State != api.WrongToken || *got.MlRunning {
		t.Fatalf("wrong token: %+v", got.Ml)
	}

	dead := httptest.NewServer(http.NotFoundHandler())
	dead.Close()
	s.useMLAt(t, dead.URL, "")
	if got := health(); got.Ml == nil || got.Ml.State != api.Unreachable {
		t.Fatalf("away: %+v", got.Ml)
	}
}

func TestSearchFallsBackWhenTheServiceIsAway(t *testing.T) {
	dead := httptest.NewServer(http.NotFoundHandler())
	dead.Close()
	s := newStack(t)
	c := s.admin()
	id := c.newPhoto(t, "morning-walk.jpg", "2024-07-10T10:00:00Z")
	s.useMLAt(t, dead.URL, "")
	resp, body := c.get("/api/search?q=morning")
	expect(t, resp, body, http.StatusOK)
	result := decode[api.SearchResult](t, body)
	if result.Smart || len(result.Items) != 1 || !strings.Contains(string(body), id) {
		t.Fatalf("got %s", body)
	}
}
