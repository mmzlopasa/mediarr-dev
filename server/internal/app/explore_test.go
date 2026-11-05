package app

import (
	"context"
	"net/http"
	"testing"

	"github.com/mediarr-app/mediarr/server/internal/api"
)

func TestExploreCountsTheUsersOwnPlacesAndSkipsTheTrash(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	other := s.user(c, "other@example.com")
	ctx := context.Background()
	place := func(id, city string) {
		t.Helper()
		if _, err := s.pool.Exec(ctx, `INSERT INTO exif (asset_id, city, country, raw) VALUES ($1, $2, 'HR', '{}')
			ON CONFLICT (asset_id) DO UPDATE SET city = EXCLUDED.city, country = EXCLUDED.country`, id, city); err != nil {
			t.Fatal(err)
		}
	}
	first := c.newPhoto(t, "1.jpg", "2024-01-01T10:00:00Z")
	newest := c.newPhoto(t, "2.jpg", "2024-01-02T10:00:00Z")
	lone := c.newPhoto(t, "3.jpg", "2024-01-03T10:00:00Z")
	trashed := c.newPhoto(t, "4.jpg", "2024-01-04T10:00:00Z")
	theirs := other.newPhoto(t, "5.jpg", "2024-01-05T10:00:00Z")
	place(first, "Hvar")
	place(newest, "Hvar")
	place(lone, "Zagreb")
	place(trashed, "Split")
	place(theirs, "Rijeka")
	if _, err := s.pool.Exec(ctx, `UPDATE assets SET deleted_at = now() WHERE id = $1`, trashed); err != nil {
		t.Fatal(err)
	}

	resp, body := c.get("/api/explore/places")
	expect(t, resp, body, http.StatusOK)
	got := decode[api.ExplorePlaces](t, body).Places
	if len(got) != 2 || got[0].Name != "Hvar" || got[0].AssetCount != 2 || got[1].Name != "Zagreb" {
		t.Fatalf("places: %+v", got)
	}
	if got[0].CoverId.String() != newest {
		t.Fatalf("cover %s, want the newest %s", got[0].CoverId, newest)
	}
}
