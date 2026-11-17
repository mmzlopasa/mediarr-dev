package app

import (
	"net/http"
	"testing"

	"github.com/mediarr-app/mediarr/server/internal/api"
)

func TestADashboardReadsTheServerWithAKeyThatOnlyReads(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	user := s.user(admin, "ana@example.com")

	resp, body := s.client().get("/api/stats")
	expect(t, resp, body, http.StatusUnauthorized)
	resp, body = user.get("/api/stats")
	expect(t, resp, body, http.StatusForbidden)

	// An empty library: no newest upload, and the jobs still a list a dashboard can add up.
	resp, body = admin.get("/api/stats")
	expect(t, resp, body, http.StatusOK)
	empty := decode[api.ServerStats](t, body)
	if empty.Photos != 0 || empty.UsageBytes != 0 || empty.LastUploadAt != nil || empty.Users != 2 {
		t.Errorf("empty: %+v", empty)
	}
	if empty.Jobs == nil || empty.DiskTotalBytes <= 0 || empty.Version == "" {
		t.Errorf("empty: %+v", empty)
	}

	admin.newPhoto(t, "a.jpg", "2024-01-01T10:00:00Z")

	// A key with only the read scope is enough, so a dashboard cannot change anything.
	key := admin.newKey(t, scopeRead)
	resp, body = s.client().do(http.MethodGet, "/api/stats", map[string]string{apiKeyHeader: key}, nil)
	expect(t, resp, body, http.StatusOK)
	stats := decode[api.ServerStats](t, body)
	if stats.Photos != 1 || stats.UsageBytes <= 0 || stats.LastUploadAt == nil {
		t.Errorf("after an upload: %+v", stats)
	}
	queued := int64(0)
	for _, job := range stats.Jobs {
		if job.Queue == "" {
			t.Errorf("a queue without a name: %+v", job)
		}
		queued += job.Queued + job.Running
	}
	if len(stats.Jobs) == 0 || queued < 0 {
		t.Errorf("jobs: %+v", stats.Jobs)
	}
	// The same key still cannot reach what is for administrators only.
	resp, body = s.client().do(http.MethodGet, "/api/admin/overview", map[string]string{apiKeyHeader: key}, nil)
	expect(t, resp, body, http.StatusForbidden)

	// A user's own key does not see the server's numbers.
	userKey := user.newKey(t, scopeRead)
	resp, body = s.client().do(http.MethodGet, "/api/stats", map[string]string{apiKeyHeader: userKey}, nil)
	expect(t, resp, body, http.StatusForbidden)
}
