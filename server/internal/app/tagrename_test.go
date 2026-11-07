package app

import (
	"net/http"
	"testing"

	"github.com/mediarr-app/mediarr/server/internal/api"
)

func (c *client) tag(t *testing.T, name string, ids ...string) {
	t.Helper()
	resp, body := c.post("/api/assets/tags", map[string]any{"ids": ids, "name": name})
	expect(t, resp, body, http.StatusOK)
}

func (c *client) tags(t *testing.T) map[string]api.Tag {
	t.Helper()
	resp, body := c.get("/api/tags")
	expect(t, resp, body, http.StatusOK)
	out := map[string]api.Tag{}
	for _, tag := range decode[[]api.Tag](t, body) {
		out[tag.Name] = tag
	}
	return out
}

func TestATagIsRenamedAndJoinedOnlyWhenAsked(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	ana := s.user(admin, "ana@example.com")
	a := ana.newPhoto(t, "a.jpg", "2024-07-01T10:00:00Z")
	b := ana.newPhoto(t, "b.jpg", "2024-07-02T10:00:00Z")
	ana.tag(t, "ljeto", a)
	ana.tag(t, "summer", a, b)
	tags := ana.tags(t)
	ljeto, summer := tags["ljeto"], tags["summer"]

	// A new name keeps the photos.
	resp, body := ana.send(http.MethodPatch, "/api/tags/"+ljeto.Id.String(), map[string]any{"name": "  Ljeto 2024 "})
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.Tag](t, body); got.Name != "Ljeto 2024" || got.AssetCount != 1 || got.Id != ljeto.Id {
		t.Fatalf("%+v", got)
	}
	// The same name written differently is a rename, not a join.
	resp, body = ana.send(http.MethodPatch, "/api/tags/"+summer.Id.String(), map[string]any{"name": "Summer"})
	expect(t, resp, body, http.StatusOK)

	// A name another tag has is refused, unless joining is asked for.
	resp, body = ana.send(http.MethodPatch, "/api/tags/"+ljeto.Id.String(), map[string]any{"name": "summer"})
	expect(t, resp, body, http.StatusConflict)
	resp, body = ana.send(http.MethodPatch, "/api/tags/"+ljeto.Id.String(), map[string]any{"name": "summer", "merge": true})
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.Tag](t, body); got.Id != summer.Id || got.AssetCount != 2 || got.Name != "Summer" {
		t.Fatalf("%+v", got)
	}
	if left := ana.tags(t); len(left) != 1 {
		t.Fatalf("%+v", left)
	}

	// Bad names, and someone else's tag, are refused.
	resp, body = ana.send(http.MethodPatch, "/api/tags/"+summer.Id.String(), map[string]any{"name": "  "})
	expect(t, resp, body, http.StatusBadRequest)
	ivo := s.user(admin, "ivo@example.com")
	resp, body = ivo.send(http.MethodPatch, "/api/tags/"+summer.Id.String(), map[string]any{"name": "mine"})
	expect(t, resp, body, http.StatusNotFound)
}
