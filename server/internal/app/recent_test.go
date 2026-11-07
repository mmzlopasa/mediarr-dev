package app

import (
	"context"
	"net/http"
	"testing"

	"github.com/mediarr-app/mediarr/server/internal/api"
)

func TestRecentlyAddedGoesByWhenPhotosCameIn(t *testing.T) {
	s := newStack(t)
	ctx := context.Background()
	admin := s.admin()
	ana := s.user(admin, "ana@example.com")
	old := ana.newPhoto(t, "old.jpg", "2009-05-01T10:00:00Z")
	fresh := ana.newPhoto(t, "fresh.jpg", "2024-07-01T10:00:00Z")
	archived := ana.newPhoto(t, "archived.jpg", "2024-07-02T10:00:00Z")
	trashed := ana.newPhoto(t, "trashed.jpg", "2024-07-03T10:00:00Z")
	// The photo taken long ago came in last.
	for id, added := range map[string]string{
		old: "2026-11-05 09:00:00+00", fresh: "2026-10-20 09:00:00+00",
		archived: "2026-11-01 09:00:00+00", trashed: "2026-11-02 09:00:00+00",
	} {
		if _, err := s.pool.Exec(ctx, "UPDATE assets SET created_at = $2 WHERE id = $1", id, added); err != nil {
			t.Fatal(err)
		}
	}
	ana.bulk(t, "archive", archived)
	ana.bulk(t, "delete", trashed)

	resp, body := ana.get("/api/collections/recent/buckets")
	expect(t, resp, body, http.StatusOK)
	buckets := decode[api.TimelineBuckets](t, body).Buckets
	if len(buckets) != 2 || buckets[0].Month != "2026-11" || buckets[0].Count != 1 || buckets[1].Month != "2026-10" {
		t.Fatalf("%s", body)
	}
	resp, body = ana.get("/api/collections/recent/buckets/2026-11")
	expect(t, resp, body, http.StatusOK)
	items := decode[api.TimelineBucket](t, body).Items
	if len(items) != 1 || items[0].Id.String() != old || items[0].LocalAt[:10] != "2026-11-05" {
		t.Fatalf("%s", body)
	}
	// The photo itself still has its own date.
	resp, body = ana.get("/api/collections/recent/assets/" + old)
	expect(t, resp, body, http.StatusOK)
	resp, body = ana.get("/api/collections/recent/assets/" + archived)
	expect(t, resp, body, http.StatusNotFound)

	// Someone else's photos are not in it.
	ivo := s.user(admin, "ivo@example.com")
	resp, body = ivo.get("/api/collections/recent/buckets")
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.TimelineBuckets](t, body).Buckets; len(got) != 0 {
		t.Fatalf("%s", body)
	}
}
