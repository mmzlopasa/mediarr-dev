package app

import (
	"net/http"
	"strings"
	"testing"

	"github.com/mediarr-app/mediarr/server/internal/api"
)

func auditEntries(t *testing.T, c *client) []api.AuditEntry {
	t.Helper()
	resp, body := c.get("/api/admin/audit?limit=500")
	expect(t, resp, body, http.StatusOK)
	return decode[[]api.AuditEntry](t, body)
}

func TestChangesAreRecordedWithoutTheirContent(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	user := s.user(admin, "user@example.com")
	photo := user.newPhoto(t, "a.jpg", "2024-01-01T10:00:00Z")
	user.bulk(t, "delete", photo)

	// A failed sign-in names who was tried, and never the password.
	anonymous := s.client()
	const secret = "a-password-that-must-not-be-logged"
	resp, body := anonymous.post("/api/auth/login", api.LoginRequest{Email: "user@example.com", Password: secret})
	expect(t, resp, body, http.StatusUnauthorized)

	// Reading changes nothing, so it is not recorded.
	before := len(auditEntries(t, admin))
	resp, body = user.get("/api/assets/" + photo)
	if resp.StatusCode >= 500 {
		t.Fatalf("%s", body)
	}
	if got := len(auditEntries(t, admin)); got != before {
		t.Fatalf("a read was recorded: %d, then %d", before, got)
	}

	entries := auditEntries(t, admin)
	found := map[string]api.AuditEntry{}
	for i := range entries {
		found[entries[i].Route] = entries[i]
		joined := entries[i].Route + entries[i].Target + entries[i].UserEmail
		if strings.Contains(joined, secret) {
			t.Fatalf("the password was logged: %+v", entries[i])
		}
	}
	bulk, ok := found["/api/assets/bulk"]
	if !ok || bulk.UserEmail != "user@example.com" || bulk.Status != http.StatusOK {
		t.Fatalf("bulk: %+v", found)
	}
	refused := false
	for i := range entries {
		if entries[i].Route == "/api/auth/login" && entries[i].Status == http.StatusUnauthorized {
			refused = entries[i].UserEmail == "user@example.com"
		}
	}
	if !refused {
		t.Fatalf("the refused sign-in is not there: %+v", entries)
	}

	// Plain users do not get to read it.
	resp, body = user.get("/api/admin/audit")
	expect(t, resp, body, http.StatusForbidden)
}

func TestALinkTokenIsNeverRecorded(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	album := c.newAlbum(map[string]any{"title": "Shared"})
	resp, body := c.post("/api/albums/"+album+"/links", map[string]any{"password": "secret-word"})
	if resp.StatusCode >= http.StatusBadRequest {
		t.Fatalf("%s", body)
	}
	link := decode[api.ShareLink](t, body)
	if link.Token == nil {
		t.Fatalf("no token: %s", body)
	}
	guest := s.client()
	resp, body = guest.post("/api/public/"+*link.Token+"/unlock", map[string]any{"password": "wrong"})
	if resp.StatusCode == http.StatusOK {
		t.Fatalf("%s", body)
	}
	for _, entry := range auditEntries(t, c) {
		if strings.Contains(entry.Target+entry.Route, *link.Token) {
			t.Fatalf("the token was recorded: %+v", entry)
		}
	}
}

func TestSearchesHaveALimit(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	other := s.user(c, "other@example.com")
	for range rateSearches {
		resp, body := c.get("/api/search?q=x")
		if resp.StatusCode == http.StatusTooManyRequests {
			t.Fatalf("limited too early: %s", body)
		}
	}
	resp, body := c.get("/api/search?q=x")
	expect(t, resp, body, http.StatusTooManyRequests)
	if resp.Header.Get("Retry-After") == "" {
		t.Error("no Retry-After")
	}
	// Someone else is not affected, and other reading still works.
	resp, body = other.get("/api/search?q=x")
	if resp.StatusCode == http.StatusTooManyRequests {
		t.Fatalf("%s", body)
	}
	resp, body = c.get("/api/timeline/buckets")
	expect(t, resp, body, http.StatusOK)
}

func TestLimitsLeaveTheBackupAlone(t *testing.T) {
	limits := newRateLimits()
	for _, path := range []string{"/api/uploads", "/api/uploads/abc", "/api/assets/check", "/api/health", "/"} {
		if limits.limiterFor(http.MethodPost, path, true) != nil {
			t.Errorf("%s has a limit", path)
		}
	}
	if limits.limiterFor(http.MethodGet, "/api/assets/x/thumbnail", true) != nil {
		t.Error("thumbnails of a signed-in user have a limit")
	}
	if limits.limiterFor(http.MethodGet, "/api/assets/x/thumbnail", false) != limits.anonymous {
		t.Error("a guest without a link has no limit")
	}
	if limits.limiterFor(http.MethodGet, publicPathPrefix+"t/buckets", false) != limits.public {
		t.Error("links have their own limit")
	}
}
