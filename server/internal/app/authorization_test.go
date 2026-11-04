package app

import (
	"context"
	"net/http"
	"regexp"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"
)

// Reachable without an account, on purpose. Anything new has to be added here knowingly.
var publicRoutes = []*regexp.Regexp{
	regexp.MustCompile(`^/api/health$`),
	regexp.MustCompile(`^/api/auth/(status|login|setup|logout|methods|oidc/.+|passkey/.+)$`),
	regexp.MustCompile(`^/api/public/`),
}

var routeParam = regexp.MustCompile(`\{[^}]+\}`)

type route struct{ method, path string }

func (s *stack) apiRoutes(t *testing.T) []route {
	t.Helper()
	routes, ok := s.handler.(chi.Routes)
	if !ok {
		t.Fatalf("the handler is a %T, which cannot list its routes", s.handler)
	}
	out := []route{}
	err := chi.Walk(routes, func(method, path string, _ http.Handler, _ ...func(http.Handler) http.Handler) error {
		if strings.HasPrefix(path, "/api/") {
			out = append(out, route{method, strings.ReplaceAll(path, "/*", "")})
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if len(out) < 50 {
		t.Fatalf("only %d routes found: the walk is not seeing the API", len(out))
	}
	return out
}

func isPublicRoute(path string) bool {
	for _, public := range publicRoutes {
		if public.MatchString(path) {
			return true
		}
	}
	return false
}

// A route added without a check on who is asking fails here, without anyone having to remember it.
func TestEveryRouteNeedsAnAccount(t *testing.T) {
	s := newStack(t)
	s.admin()
	anonymous := s.client()
	const someID = "00000000-0000-4000-8000-000000000000"
	for _, r := range s.apiRoutes(t) {
		if isPublicRoute(r.path) {
			continue
		}
		// The required query values, so that the answer is about the account and not about them.
		path := routeParam.ReplaceAllString(strings.ReplaceAll(r.path, "/jobs/{id}", "/jobs/1"), someID) + "?ids=" + someID + "&q=x"
		resp, body := anonymous.send(r.method, path, map[string]any{})
		if resp.StatusCode != http.StatusUnauthorized {
			t.Errorf("%s %s without an account: %d %s", r.method, r.path, resp.StatusCode, truncateForTest(body))
		}
	}
}

func truncateForTest(body []byte) string {
	const limit = 120
	if len(body) > limit {
		return string(body[:limit])
	}
	return string(body)
}

func TestAdminRoutesAreForAdmins(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	user := s.user(admin, "user@example.com")
	const someID = "00000000-0000-4000-8000-000000000000"
	for _, r := range s.apiRoutes(t) {
		if !strings.HasPrefix(r.path, "/api/admin/") {
			continue
		}
		resp, body := user.send(r.method, routeParam.ReplaceAllString(strings.ReplaceAll(r.path, "/jobs/{id}", "/jobs/1"), someID), map[string]any{})
		if resp.StatusCode != http.StatusForbidden {
			t.Errorf("%s %s as a plain user: %d %s", r.method, r.path, resp.StatusCode, truncateForTest(body))
		}
	}
}

// These act on the caller's own data, whatever the path says, so a success takes nothing from anyone.
// TestStrangersReachNothingOfTheOwner still checks that what the owner has stays in place.
var ownOnlyRoutes = map[string]bool{
	"GET /api/timeline/buckets/{month}":            true,
	"GET /api/collections/{scope}/buckets":         true,
	"GET /api/collections/{scope}/buckets/{month}": true,
	"PUT /api/partners/{userId}":                   true,
	"DELETE /api/partners/{userId}":                true,
	"PUT /api/partners/{userId}/timeline":          true,
	"DELETE /api/me/device-keys/{id}":              true,
	"DELETE /api/me/passkeys/{id}":                 true,
	// Tus uploads are checked by their own tests, and an id belongs to the upload in progress.
	"DELETE /api/uploads/{id}": true,
	"HEAD /api/uploads/{id}":   true,
	"PATCH /api/uploads/{id}":  true,
}

// Fills a route with what belongs to the owner, by the part of the path it is in.
func ownerPath(path string, ids map[string]string) (string, bool) {
	filled := true
	segments := strings.Split(path, "/")
	for i, segment := range segments {
		if !strings.HasPrefix(segment, "{") {
			continue
		}
		name := strings.Trim(segment, "{}")
		value, ok := ids[segments[i-1]+"/"+name]
		if !ok {
			value, ok = ids[name]
		}
		if !ok {
			filled = false
			continue
		}
		segments[i] = value
	}
	return strings.Join(segments, "/"), filled
}

// Someone with an account of their own reaches nothing of someone else's, on any route with an id.
func TestStrangersReachNothingOfTheOwner(t *testing.T) {
	service := fakeML(t)
	s := newStack(t)
	owner := s.admin()
	stranger := s.user(owner, "stranger@example.com")
	ctx := context.Background()

	photo := s.analyzed(t, owner, service, "a.jpg", "2024-07-01T10:00:00Z", "beach ana")
	album := owner.newAlbum(map[string]any{"title": "Private"})
	resp, body := owner.post("/api/albums/"+album+"/assets", map[string]any{"ids": []string{photo}})
	expect(t, resp, body, http.StatusOK)
	resp, body = owner.post("/api/assets/tags", map[string]any{"ids": []string{photo}, "name": "mine"})
	expect(t, resp, body, http.StatusOK)
	for path, payload := range map[string]map[string]any{
		"/api/albums/" + album + "/comments": {"assetId": photo, "body": "mine"},
		"/api/albums/" + album + "/links":    {},
		"/api/me/device-keys":                {"name": "phone"},
		"/api/stories":                       {"title": "Mine", "ids": []string{photo}},
	} {
		resp, body := owner.post(path, payload)
		if resp.StatusCode >= http.StatusBadRequest {
			t.Fatalf("%s: %d %s", path, resp.StatusCode, body)
		}
	}
	ids := map[string]string{
		"assets/id": photo, "albums/id": album, "assetId": photo, "month": "2024-07", "file": "master.m3u8",
		"scope": "archive", "userId": s.userID("admin@example.com"),
	}
	for name, query := range map[string]string{
		"tags/id":        "SELECT id::text FROM tags LIMIT 1",
		"people/id":      "SELECT id::text FROM people LIMIT 1",
		"commentId":      "SELECT id::text FROM album_comments LIMIT 1",
		"linkId":         "SELECT id::text FROM share_links LIMIT 1",
		"device-keys/id": "SELECT id::text FROM api_keys LIMIT 1",
		"stories/id":     "SELECT id::text FROM story_exports LIMIT 1",
	} {
		var id string
		if err := s.pool.QueryRow(ctx, query).Scan(&id); err != nil {
			t.Fatal(name, err)
		}
		ids[name] = id
	}

	checked := 0
	for _, r := range s.apiRoutes(t) {
		if isPublicRoute(r.path) || !strings.Contains(r.path, "{") || strings.HasPrefix(r.path, "/api/admin/") {
			continue
		}
		if ownOnlyRoutes[r.method+" "+r.path] {
			continue
		}
		path, filled := ownerPath(r.path, ids)
		if !filled {
			t.Errorf("no fixture for %s %s: add one, so that this route is checked", r.method, r.path)
			continue
		}
		checked++
		resp, body := stranger.send(r.method, path, map[string]any{"ids": []string{photo}, "name": "x"})
		if resp.StatusCode < http.StatusBadRequest {
			t.Errorf("%s %s reached by a stranger: %d %s", r.method, r.path, resp.StatusCode, truncateForTest(body))
		}
	}
	if checked < 30 {
		t.Fatalf("only %d routes were checked", checked)
	}
	// The owner's things are all still there after all of that.
	resp, body = owner.get("/api/assets/" + photo)
	expect(t, resp, body, http.StatusOK)
	resp, body = owner.get("/api/albums/" + album)
	expect(t, resp, body, http.StatusOK)
	var keys int
	if err := s.pool.QueryRow(ctx, "SELECT count(*) FROM api_keys").Scan(&keys); err != nil {
		t.Fatal(err)
	}
	if keys != 1 {
		t.Fatalf("the owner's key is gone: %d", keys)
	}
}
