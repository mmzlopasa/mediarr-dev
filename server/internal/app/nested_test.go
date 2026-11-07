package app

import (
	"net/http"
	"testing"

	"github.com/mediarr-app/mediarr/server/internal/api"
)

func (c *client) albums(t *testing.T) map[string]api.Album {
	t.Helper()
	resp, body := c.get("/api/albums")
	expect(t, resp, body, http.StatusOK)
	out := map[string]api.Album{}
	for _, album := range decode[[]api.Album](t, body) {
		out[album.Title] = album
	}
	return out
}

func TestAlbumsSitInsideOthersWithoutLoopsOrSharingByAccident(t *testing.T) {
	s := newStack(t)
	owner := s.admin()
	ana := s.user(owner, "ana@example.com")

	travels := owner.newAlbum(map[string]any{"title": "Travels"})
	resp, body := owner.post("/api/albums", map[string]any{"title": "2024", "parentId": travels})
	expect(t, resp, body, http.StatusCreated)
	year := decode[api.Album](t, body).Id.String()
	japan := owner.newAlbum(map[string]any{"title": "Japan"})

	resp, body = owner.send(http.MethodPut, "/api/albums/"+japan+"/parent", map[string]any{"parentId": year})
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.Album](t, body); got.ParentId == nil || got.ParentId.String() != year {
		t.Fatalf("%s", body)
	}
	all := owner.albums(t)
	if all["Travels"].ChildCount == nil || *all["Travels"].ChildCount != 1 || all["Travels"].ParentId != nil {
		t.Fatalf("%+v", all["Travels"])
	}
	if all["2024"].ParentId == nil || all["2024"].ParentId.String() != travels {
		t.Fatalf("%+v", all["2024"])
	}

	// Never inside itself, at any depth.
	for _, into := range []string{travels, year, japan} {
		resp, body = owner.send(http.MethodPut, "/api/albums/"+travels+"/parent", map[string]any{"parentId": into})
		expect(t, resp, body, http.StatusBadRequest)
	}

	// Sharing is per album: Ana sees Japan, at the top, and nothing of what it is in.
	resp, body = owner.send(http.MethodPut, "/api/albums/"+japan+"/members/"+s.userID("ana@example.com"), map[string]string{"role": "editor"})
	expect(t, resp, body, http.StatusNoContent)
	seen := ana.albums(t)
	if len(seen) != 1 || seen["Japan"].ParentId != nil {
		t.Fatalf("%+v", seen)
	}
	// Only one's own albums go inside one's own albums.
	mine := ana.newAlbum(map[string]any{"title": "Mine"})
	resp, body = ana.send(http.MethodPut, "/api/albums/"+japan+"/parent", map[string]any{"parentId": mine})
	expect(t, resp, body, http.StatusForbidden)
	resp, body = ana.send(http.MethodPut, "/api/albums/"+mine+"/parent", map[string]any{"parentId": japan})
	expect(t, resp, body, http.StatusForbidden)
	resp, body = ana.post("/api/albums", map[string]any{"title": "Sneaky", "parentId": travels})
	expect(t, resp, body, http.StatusNotFound)
	if _, made := ana.albums(t)["Sneaky"]; made {
		t.Fatal("an album was made where it was refused")
	}

	// Back to the top, and deleting the one around keeps what was in it.
	resp, body = owner.send(http.MethodPut, "/api/albums/"+japan+"/parent", map[string]any{"parentId": nil})
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.Album](t, body); got.ParentId != nil {
		t.Fatalf("%s", body)
	}
	resp, body = owner.send(http.MethodDelete, "/api/albums/"+travels, nil)
	expect(t, resp, body, http.StatusNoContent)
	left := owner.albums(t)
	if _, ok := left["2024"]; !ok || left["2024"].ParentId != nil {
		t.Fatalf("%+v", left)
	}
}
