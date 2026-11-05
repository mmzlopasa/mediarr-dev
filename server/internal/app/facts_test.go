package app

import (
	"context"
	"net/http"
	"testing"
	"time"

	"github.com/mediarr-app/mediarr/server/internal/api"
)

func TestAPhotosFactsChangeButItsFileDoesNot(t *testing.T) {
	service := fakeML(t)
	s := newStack(t)
	s.useML(t, service)
	c := s.admin()
	id := c.newPhoto(t, "1.jpg", "2024-01-01T10:00:00Z")
	path := "/api/assets/" + id + "/facts"
	ctx := context.Background()
	var before []byte
	if err := s.pool.QueryRow(ctx, `SELECT checksum FROM assets WHERE id = $1`, id).Scan(&before); err != nil {
		t.Fatal(err)
	}

	when, caption := "2001-02-03T04:05:06+02:00", "  At the lake  "
	latitude, longitude := 45.8, 15.97
	resp, body := c.send(http.MethodPatch, path, api.AssetFacts{TakenAt: &when, Latitude: &latitude, Longitude: &longitude, Caption: &caption})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = c.get("/api/assets/" + id)
	expect(t, resp, body, http.StatusOK)
	detail := decode[api.AssetDetail](t, body)
	if detail.LocalAt[:19] != "2001-02-03T04:05:06" || detail.OffsetMinutes == nil || *detail.OffsetMinutes != 120 {
		t.Fatalf("date: %s %v", detail.LocalAt, detail.OffsetMinutes)
	}
	if detail.Latitude == nil || *detail.Latitude != latitude || detail.Caption == nil || *detail.Caption != "At the lake" {
		t.Fatalf("location or caption: %+v", detail)
	}
	var after []byte
	if err := s.pool.QueryRow(ctx, `SELECT checksum FROM assets WHERE id = $1`, id).Scan(&after); err != nil {
		t.Fatal(err)
	}
	if string(before) != string(after) {
		t.Fatal("the original's checksum changed")
	}

	useFile := true
	resp, body = c.send(http.MethodPatch, path, api.AssetFacts{UseFile: &useFile})
	expect(t, resp, body, http.StatusNoContent)
	var manual *time.Time
	if err := s.pool.QueryRow(ctx, `SELECT manual_taken_at FROM assets WHERE id = $1`, id).Scan(&manual); err != nil {
		t.Fatal(err)
	}
	if manual != nil {
		t.Fatalf("still manual: %v", manual)
	}
}

func TestWrongFactsAreRefusedAndOthersPhotosUntouched(t *testing.T) {
	s := newStack(t)
	owner := s.admin()
	stranger := s.user(owner, "stranger@example.com")
	id := owner.newPhoto(t, "1.jpg", "2024-01-01T10:00:00Z")
	path := "/api/assets/" + id + "/facts"
	future := time.Now().AddDate(1, 0, 0).Format(time.RFC3339)
	words, far, half := "yesterday", 200.0, 45.0
	for name, facts := range map[string]api.AssetFacts{
		"not a date": {TakenAt: &words},
		"future":     {TakenAt: &future},
		"half":       {Latitude: &half},
		"far":        {Latitude: &far, Longitude: &half},
	} {
		resp, body := owner.send(http.MethodPatch, path, facts)
		if resp.StatusCode != http.StatusBadRequest {
			t.Errorf("%s: %d %s", name, resp.StatusCode, body)
		}
	}
	caption := "mine now"
	resp, body := stranger.send(http.MethodPatch, path, api.AssetFacts{Caption: &caption})
	expect(t, resp, body, http.StatusNotFound)
}

func TestPlacesAreFoundByTheStartOfTheirName(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	if _, err := s.pool.Exec(context.Background(), `INSERT INTO places (name, state, country, lat, lon) VALUES ('Zagreb', 'Grad Zagreb', 'HR', 45.8, 15.97)`); err != nil {
		t.Fatal(err)
	}
	resp, body := c.get("/api/places?q=zag")
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.PlaceList](t, body).Places; len(got) != 1 || got[0].Name != "Zagreb" {
		t.Fatalf("found: %+v", got)
	}
	// A wildcard is not a search for everything.
	resp, body = c.get("/api/places?q=%25%25")
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.PlaceList](t, body).Places; len(got) != 0 {
		t.Fatalf("a wildcard found: %+v", got)
	}
}
