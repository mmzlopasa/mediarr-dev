package app

import (
	"bytes"
	"context"
	"encoding/json"
	"maps"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
)

func (c *client) newKey(t *testing.T, scopes ...string) string {
	t.Helper()
	resp, body := c.post("/api/me/api-keys", map[string]any{"name": "test", "scopes": scopes})
	expect(t, resp, body, http.StatusCreated)
	return decode[api.DeviceKey](t, body).Key
}

// sendWith is a JSON request with headers of its own, as an API client makes.
func (c *client) sendWith(method, path string, headers map[string]string, payload any) (*http.Response, []byte) {
	c.s.t.Helper()
	encoded, err := json.Marshal(payload)
	if err != nil {
		c.s.t.Fatal(err)
	}
	all := map[string]string{"Content-Type": "application/json"}
	maps.Copy(all, headers)
	return c.do(method, path, all, bytes.NewReader(encoded))
}

func TestAKeyCanDoOnlyWhatItWasGiven(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	photo := c.newPhoto(t, "a.jpg", "2024-01-01T10:00:00Z")
	byKey := func(key, method, path string) int {
		t.Helper()
		headers := map[string]string{apiKeyHeader: key}
		var resp *http.Response
		if isWrite(method) {
			resp, _ = s.client().sendWith(method, path, headers, map[string]any{"ids": []string{photo}, "action": "favorite"})
		} else {
			resp, _ = s.client().do(method, path, headers, nil)
		}
		return resp.StatusCode
	}
	read := c.newKey(t, "read")
	if got := byKey(read, http.MethodGet, "/api/assets/"+photo); got != http.StatusOK {
		t.Errorf("read a photo: %d", got)
	}
	if got := byKey(read, http.MethodPost, "/api/assets/bulk"); got != http.StatusForbidden {
		t.Errorf("a read key changed something: %d", got)
	}
	if got := byKey(read, http.MethodGet, "/api/admin/users"); got != http.StatusForbidden {
		t.Errorf("a read key reached admin: %d", got)
	}
	write := c.newKey(t, "write")
	if got := byKey(write, http.MethodPost, "/api/assets/bulk"); got != http.StatusOK {
		t.Errorf("a write key: %d", got)
	}
	if got := byKey(write, http.MethodGet, "/api/assets/"+photo); got != http.StatusForbidden {
		t.Errorf("a write key read something: %d", got)
	}
	admin := c.newKey(t, "admin")
	if got := byKey(admin, http.MethodGet, "/api/admin/users"); got != http.StatusOK {
		t.Errorf("an admin key: %d", got)
	}
	// However broad, no key manages the account.
	everything := c.newKey(t, "read", "upload", "write", "admin")
	for _, path := range []string{"/api/me/api-keys", "/api/me/device-keys", "/api/me/password", "/api/auth/logout"} {
		if got := byKey(everything, http.MethodPost, path); got != http.StatusForbidden {
			t.Errorf("%s by key: %d", path, got)
		}
	}
	if got := byKey(everything, http.MethodGet, "/api/me/api-keys"); got != http.StatusForbidden {
		t.Errorf("listing keys by key: %d", got)
	}
}

func TestAPhoneKeyOnlySendsFiles(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	photo := c.newPhoto(t, "a.jpg", "2024-01-01T10:00:00Z")
	resp, body := c.post("/api/me/device-keys", api.CreateDeviceKeyRequest{Name: "phone"})
	expect(t, resp, body, http.StatusCreated)
	key := decode[api.DeviceKey](t, body).Key
	guest := s.client()
	resp, body = guest.do(http.MethodGet, "/api/assets/"+photo+"/original", map[string]string{apiKeyHeader: key}, nil)
	expect(t, resp, body, http.StatusForbidden)
	resp, body = guest.sendWith(http.MethodPost, "/api/assets/check", map[string]string{apiKeyHeader: key}, map[string]any{"checksums": []string{}})
	expect(t, resp, body, http.StatusOK)
}

func TestAKeyEndsWhenItExpires(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	resp, body := c.post("/api/me/api-keys", map[string]any{"name": "short", "scopes": []string{"read"}, "expiresInDays": 1})
	expect(t, resp, body, http.StatusCreated)
	key := decode[api.DeviceKey](t, body).Key
	guest := s.client()
	resp, body = guest.do(http.MethodGet, "/api/timeline/buckets", map[string]string{apiKeyHeader: key}, nil)
	expect(t, resp, body, http.StatusOK)
	if _, err := s.pool.Exec(context.Background(), "UPDATE api_keys SET expires_at = now() - interval '1 second'"); err != nil {
		t.Fatal(err)
	}
	resp, body = guest.do(http.MethodGet, "/api/timeline/buckets", map[string]string{apiKeyHeader: key}, nil)
	expect(t, resp, body, http.StatusUnauthorized)
}

func TestOnlyAnAdminGetsAnAdminsKey(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	user := s.user(admin, "user@example.com")
	resp, body := user.post("/api/me/api-keys", map[string]any{"name": "x", "scopes": []string{"admin"}})
	expect(t, resp, body, http.StatusForbidden)
	resp, body = user.post("/api/me/api-keys", map[string]any{"name": "x", "scopes": []string{}})
	expect(t, resp, body, http.StatusBadRequest)
	resp, body = user.post("/api/me/api-keys", map[string]any{"name": "x", "scopes": []string{"everything"}})
	expect(t, resp, body, http.StatusBadRequest)
	// The list never holds the key itself.
	user.newKey(t, "read")
	resp, body = user.get("/api/me/api-keys")
	expect(t, resp, body, http.StatusOK)
	keys := decode[[]api.ApiKey](t, body)
	if len(keys) != 1 || keys[0].Name != "test" || len(keys[0].Scopes) != 1 {
		t.Fatalf("%s", body)
	}
}

func TestOnlyAnAdminKeyActsAsAdministrator(t *testing.T) {
	admin := &db.User{IsAdmin: true}
	plain := &db.User{}
	withScopes := func(scopes ...string) *http.Request {
		r := httptest.NewRequest(http.MethodPost, "/api/exports", http.NoBody)
		return r.WithContext(context.WithValue(r.Context(), scopesKey{}, scopes))
	}
	signedIn := httptest.NewRequest(http.MethodPost, "/api/exports", http.NoBody)
	cases := []struct {
		name string
		r    *http.Request
		user *db.User
		want bool
	}{
		{"administrator signed in", signedIn, admin, true},
		{"user signed in", signedIn, plain, false},
		{"administrator's admin key", withScopes(scopeRead, scopeAdmin), admin, true},
		{"administrator's write key", withScopes(scopeRead, scopeWrite), admin, false},
		{"user's key with admin scope", withScopes(scopeAdmin), plain, false},
		{"nobody", signedIn, nil, false},
	}
	for _, tc := range cases {
		if got := actsAsAdmin(tc.r, tc.user); got != tc.want {
			t.Errorf("%s: actsAsAdmin = %v, want %v", tc.name, got, tc.want)
		}
	}
}
