package app

import (
	"context"
	"net/http"
	"net/url"
	"slices"
	"testing"

	"github.com/mediarr-app/mediarr/server/internal/api"
)

// Every filter alone and together, with no words: they narrow the same search the words do.
func TestSearchFiltersNarrowTheResults(t *testing.T) {
	s := newStack(t)
	s.startWorker(t)
	owner := s.admin()
	friend := s.user(owner, "friend@example.com")
	ctx := context.Background()
	ids := map[string]string{}
	for i, name := range []string{"a", "b", "c", "d"} {
		ids[name] = uploadedID(t, owner.upload(name+".jpg", pictureOf(t, uint8(10+i*20)), nil))
	}
	s.settle(t)
	run := func(query string, args ...any) {
		t.Helper()
		if _, err := s.pool.Exec(ctx, query, args...); err != nil {
			t.Fatal(err)
		}
	}
	run(`UPDATE assets SET taken_at = '2024-06-01T10:00:00Z', taken_offset_minutes = 0`)
	run(`UPDATE assets SET taken_at = '2023-07-01T10:00:00Z' WHERE id = $1`, ids["a"])
	run(`UPDATE exif SET model = 'X-T5', make = 'Fujifilm', lens = 'XF35mmF1.4 R', city = 'Split', country = 'Croatia' WHERE asset_id = $1`, ids["a"])
	run(`UPDATE exif SET model = 'iPhone 15', make = 'Apple' WHERE asset_id = $1`, ids["b"])
	run(`UPDATE assets SET rating = 4 WHERE id = $1`, ids["a"])
	run(`UPDATE assets SET rating = 2 WHERE id = $1`, ids["b"])
	run(`UPDATE assets SET is_favorite = true WHERE id = $1`, ids["c"])
	run(`UPDATE assets SET kind = 'video' WHERE id = $1`, ids["d"])
	var ana, ivo string
	if err := s.pool.QueryRow(ctx, `INSERT INTO people (user_id, name) VALUES ($1, 'Ana') RETURNING id::text`, s.userID("admin@example.com")).Scan(&ana); err != nil {
		t.Fatal(err)
	}
	if err := s.pool.QueryRow(ctx, `INSERT INTO people (user_id, name) VALUES ($1, 'Ivo') RETURNING id::text`, s.userID("admin@example.com")).Scan(&ivo); err != nil {
		t.Fatal(err)
	}
	face := `INSERT INTO faces (asset_id, user_id, person_id, x1, y1, x2, y2, score, embedding)
		VALUES ($1, $2, $3, 0, 0, 0.1, 0.1, 0.9, array_fill(0.1::real, ARRAY[512])::vector)`
	run(face, ids["a"], s.userID("admin@example.com"), ana)
	run(face, ids["a"], s.userID("admin@example.com"), ivo)
	run(face, ids["b"], s.userID("admin@example.com"), ana)
	resp, body := owner.post("/api/assets/tags", map[string]any{"ids": []string{ids["a"], ids["c"]}, "name": "Summer"})
	expect(t, resp, body, http.StatusOK)
	resp, body = owner.post("/api/assets/tags", map[string]any{"ids": []string{ids["a"]}, "name": "Family"})
	expect(t, resp, body, http.StatusOK)
	album := owner.newAlbum(map[string]any{"title": "Trip"})
	resp, body = owner.post("/api/albums/"+album+"/assets", map[string]any{"ids": []string{ids["a"], ids["b"]}})
	expect(t, resp, body, http.StatusOK)

	search := func(c *client, query url.Values) []string {
		t.Helper()
		resp, body := c.get("/api/search?" + query.Encode())
		expect(t, resp, body, http.StatusOK)
		out := []string{}
		for _, item := range decode[api.SearchResult](t, body).Items {
			for name, id := range ids {
				if item.Id.String() == id {
					out = append(out, name)
				}
			}
		}
		slices.Sort(out)
		return out
	}
	for _, c := range []struct {
		name  string
		query url.Values
		want  []string
	}{
		{"two people, both on it", url.Values{"person": {ana, ivo}}, []string{"a"}},
		{"two people, any of them", url.Values{"person": {ana, ivo}, "people": {"any"}}, []string{"a", "b"}},
		{"camera", url.Values{"camera": {"x-t5"}}, []string{"a"}},
		{"lens", url.Values{"lens": {"xf35mmf1.4 r"}}, []string{"a"}},
		{"place", url.Values{"place": {"Croatia"}}, []string{"a"}},
		{"rating", url.Values{"minRating": {"3"}}, []string{"a"}},
		{"favourites", url.Values{"favorite": {"true"}}, []string{"c"}},
		{"videos", url.Values{"type": {"video"}}, []string{"d"}},
		{"photos", url.Values{"type": {"photo"}}, []string{"a", "b", "c"}},
		{"one tag", url.Values{"tag": {"summer"}}, []string{"a", "c"}},
		{"two tags, both", url.Values{"tag": {"Summer", "Family"}}, []string{"a"}},
		{"in an album", url.Values{"album": {album}}, []string{"a", "b"}},
		{"in no album", url.Values{"notInAlbum": {"true"}}, []string{"c", "d"}},
		{"dates", url.Values{"from": {"2023-01-01"}, "to": {"2023-12-31"}}, []string{"a"}},
		{"together", url.Values{"album": {album}, "minRating": {"2"}, "type": {"photo"}, "person": {ana}}, []string{"a", "b"}},
	} {
		if got := search(owner, c.query); !slices.Equal(got, c.want) {
			t.Errorf("%s: %v, want %v", c.name, got, c.want)
		}
	}

	// Searching in a shared album finds the owner's photos in it, and nothing of theirs outside it.
	resp, body = friend.get("/api/search?album=" + album)
	expect(t, resp, body, http.StatusNotFound)
	resp, body = owner.send(http.MethodPut, "/api/albums/"+album+"/members/"+s.userID("friend@example.com"), map[string]string{"role": "viewer"})
	expect(t, resp, body, http.StatusNoContent)
	if got := search(friend, url.Values{"album": {album}}); !slices.Equal(got, []string{"a", "b"}) {
		t.Fatalf("a shared album: %v", got)
	}
	if got := search(friend, url.Values{"type": {"photo"}}); len(got) != 0 {
		t.Fatalf("another person's photos outside the album: %v", got)
	}

	resp, body = owner.get("/api/search/options")
	expect(t, resp, body, http.StatusOK)
	options := decode[api.SearchOptions](t, body)
	if !slices.Contains(options.Cameras, "X-T5") || !slices.Contains(options.Lenses, "XF35mmF1.4 R") ||
		!slices.Contains(options.Places, "Split") || !slices.Contains(options.Tags, "Summer") {
		t.Fatalf("%+v", options)
	}
}
