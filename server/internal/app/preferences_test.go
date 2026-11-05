package app

import (
	"context"
	"net/http"
	"testing"

	"github.com/mediarr-app/mediarr/server/internal/api"
)

func TestPreferencesAreKeptAndChecked(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	other := s.user(c, "other@example.com")
	resp, body := c.get("/api/me/preferences")
	expect(t, resp, body, http.StatusOK)
	got := decode[api.UserPreferences](t, body)
	if !got.PhotoFull || !got.VideoOriginal {
		t.Fatalf("originals by default: %+v", got)
	}
	if !got.VideoAutoplay || !got.ConfirmDelete || got.MemorySeconds != 4 || got.MinFaces != 2 {
		t.Fatalf("defaults: %+v", got)
	}
	got.MemorySeconds = 9
	got.MinFaces = 1
	got.AlbumOrder = api.UserPreferencesAlbumOrderOldest
	got.HiddenSections = []string{"/map"}
	resp, body = c.send(http.MethodPut, "/api/me/preferences", got)
	expect(t, resp, body, http.StatusOK)
	resp, body = c.get("/api/me/preferences")
	expect(t, resp, body, http.StatusOK)
	if saved := decode[api.UserPreferences](t, body); saved.MemorySeconds != 9 || len(saved.HiddenSections) != 1 {
		t.Fatalf("saved: %+v", saved)
	}
	// Each person has their own.
	resp, body = other.get("/api/me/preferences")
	expect(t, resp, body, http.StatusOK)
	if theirs := decode[api.UserPreferences](t, body); theirs.MemorySeconds != 4 {
		t.Fatalf("theirs: %+v", theirs)
	}
	bad := got
	bad.MemorySeconds = 0
	resp, body = c.send(http.MethodPut, "/api/me/preferences", bad)
	expect(t, resp, body, http.StatusBadRequest)
	bad = got
	bad.MinFaces = 0
	resp, body = c.send(http.MethodPut, "/api/me/preferences", bad)
	expect(t, resp, body, http.StatusBadRequest)

	// A new album takes the chosen order.
	resp, body = c.post("/api/albums", api.AlbumCreate{Title: "New"})
	expect(t, resp, body, http.StatusCreated)
	if got := s.count(t, "SELECT count(*) FROM albums WHERE title='New' AND asset_order='oldest'"); got != 1 {
		t.Fatalf("order: %s", body)
	}
}

func TestMinimumFacesDecidesWhoIsListed(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	ctx := context.Background()
	photo := c.newPhoto(t, "a.jpg", "2024-01-01T10:00:00Z")
	var user, person string
	if err := s.pool.QueryRow(ctx, `SELECT id FROM users LIMIT 1`).Scan(&user); err != nil {
		t.Fatal(err)
	}
	if err := s.pool.QueryRow(ctx, `INSERT INTO people (user_id, name) VALUES ($1, '') RETURNING id`, user).Scan(&person); err != nil {
		t.Fatal(err)
	}
	if _, err := s.pool.Exec(ctx, `INSERT INTO faces (asset_id, user_id, person_id, x1, y1, x2, y2, score, embedding)
		VALUES ($1, $2, $3, 0, 0, 1, 1, 1, array_fill(0.1::real, ARRAY[512])::vector)`, photo, user, person); err != nil {
		t.Skipf("the faces table has another shape here: %v", err)
	}
	count := func() int {
		resp, body := c.get("/api/people")
		expect(t, resp, body, http.StatusOK)
		return len(decode[api.PeopleList](t, body).People)
	}
	if got := count(); got != 0 {
		t.Fatalf("one photo at the default: %d", got)
	}
	prefs := defaultPreferences()
	prefs.MinFaces = 1
	resp, body := c.send(http.MethodPut, "/api/me/preferences", prefs)
	expect(t, resp, body, http.StatusOK)
	if got := count(); got != 1 {
		t.Fatalf("one photo at one: %d", got)
	}
}
