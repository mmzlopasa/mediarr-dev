package app

import (
	"context"
	"net/http"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

func day(value string) time.Time {
	parsed, err := time.Parse(dateLayout, value)
	if err != nil {
		panic(err)
	}
	return parsed
}

func TestFindTrips(t *testing.T) {
	const (
		zagrebLat, zagrebLon = 45.81, 15.98
		hvarLat, hvarLon     = 43.17, 16.44
		romeLat, romeLon     = 41.89, 12.48
	)
	point := func(date string, lat, lon float64, place string) tripPoint {
		return tripPoint{id: uuid.New(), at: day(date), lat: lat, lon: lon, place: place}
	}
	points := []tripPoint{
		point("2024-01-01", zagrebLat, zagrebLon, "Zagreb"),
		point("2024-01-02", zagrebLat, zagrebLon, "Zagreb"),
		point("2024-01-03", zagrebLat, zagrebLon, "Zagreb"),
		point("2024-01-04", zagrebLat, zagrebLon, "Zagreb"),
		point("2024-06-10", hvarLat, hvarLon, "Hvar"),
		point("2024-06-11", hvarLat, hvarLon, "Hvar"),
		point("2024-06-12", hvarLat, hvarLon, "Vis"),
		// Home in between ends a trip.
		point("2024-06-20", zagrebLat, zagrebLon, "Zagreb"),
		// More than a few days apart makes two journeys, and one photo is not a journey.
		point("2024-08-01", romeLat, romeLon, "Rome"),
		point("2024-08-02", romeLat, romeLon, "Rome"),
		point("2024-09-01", romeLat, romeLon, "Rome"),
	}
	trips := findTrips(points)
	if len(trips) != 2 {
		t.Fatalf("%d trips: %+v", len(trips), trips)
	}
	if trips[0].From != "2024-08-01" || trips[0].To != "2024-08-02" || trips[0].Count != 2 {
		t.Fatalf("newest trip: %+v", trips[0])
	}
	if trips[1].From != "2024-06-10" || trips[1].Count != 3 || trips[1].Places[0] != "Hvar" || trips[1].Places[1] != "Vis" {
		t.Fatalf("older trip: %+v", trips[1])
	}
	if len(findTrips(nil)) != 0 {
		t.Fatal("trips from nothing")
	}
}

func TestMapShowsOnlyWhatMayBeSeen(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	other := s.user(c, "other@example.com")
	ctx := context.Background()
	if err := db.LoadPlaces(ctx, s.pool); err != nil {
		t.Fatal(err)
	}
	if err := db.LoadPlaces(ctx, s.pool); err != nil {
		t.Fatal(err)
	}
	var places int64
	if err := s.pool.QueryRow(ctx, `SELECT count(*) FROM places`).Scan(&places); err != nil || places < 100000 || places > 200000 {
		t.Fatalf("%d places, %v", places, err)
	}

	located := func(c *client, name, taken string, lat, lon float64) string {
		id := c.newPhoto(t, name, taken)
		if _, err := s.pool.Exec(ctx, `INSERT INTO exif (asset_id, latitude, longitude, raw) VALUES ($1, $2, $3, '{}')`, id, lat, lon); err != nil {
			t.Fatal(err)
		}
		return id
	}
	hvar := located(c, "hvar.jpg", "2024-06-15T10:00:00Z", 43.1729, 16.4411)
	sea := located(c, "sea.jpg", "2024-06-16T10:00:00Z", 35.0, -40.0)
	trashed := located(c, "trash.jpg", "2024-06-17T10:00:00Z", 45.0, 15.0)
	foreign := located(other, "foreign.jpg", "2024-06-18T10:00:00Z", 45.0, 15.0)
	c.newPhoto(t, "nowhere.jpg", "2024-06-19T10:00:00Z")
	c.bulk(t, "delete", trashed)

	if err := jobs.GeocodePending(ctx, db.New(s.pool)); err != nil {
		t.Fatal(err)
	}
	resp, body := c.get("/api/assets/" + hvar)
	expect(t, resp, body, http.StatusOK)
	detail := decode[api.AssetDetail](t, body)
	if detail.City == nil || *detail.City != "Hvar" || *detail.Country != "Croatia" {
		t.Fatalf("place: %s", body)
	}
	// Open sea has no name, and is not asked about again.
	resp, body = c.get("/api/assets/" + sea)
	expect(t, resp, body, http.StatusOK)
	if decode[api.AssetDetail](t, body).City != nil {
		t.Fatalf("a place in the middle of the ocean: %s", body)
	}
	var pending int
	if err := s.pool.QueryRow(ctx, `SELECT count(*) FROM exif WHERE geocoded_at IS NULL AND latitude IS NOT NULL`).Scan(&pending); err != nil || pending != 0 {
		t.Fatalf("%d pending, %v", pending, err)
	}

	resp, body = c.get("/api/map/points")
	expect(t, resp, body, http.StatusOK)
	points := decode[api.MapPoints](t, body)
	if len(points.Ids) != 2 || points.Ids[0].String() != hvar || points.Ids[1].String() != sea || points.Lats[0] < 43 {
		t.Fatalf("points: %s", body)
	}
	if foreign == hvar {
		t.Fatal("same id")
	}
	resp, body = c.get("/api/map/points?from=2024-06-16&to=2024-06-16")
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.MapPoints](t, body); len(got.Ids) != 1 || got.Ids[0].String() != sea {
		t.Fatalf("filtered: %s", body)
	}
	resp, body = c.get("/api/map/trips")
	expect(t, resp, body, http.StatusOK)

	// A link that does not show location names none either.
	album := c.newAlbum(map[string]any{"title": "Trip"})
	resp, body = c.post("/api/albums/"+album+"/assets", api.AssetIds{Ids: uuids(t, hvar)})
	expect(t, resp, body, http.StatusOK)
	link := c.newLink(album, map[string]any{})
	guest := s.client()
	resp, body = guest.get(publicPathPrefix + *link.Token + "/assets/" + hvar)
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.AssetDetail](t, body); got.City != nil || got.Country != nil {
		t.Fatalf("a link tells the place: %s", body)
	}
}

func TestMapStyleSetting(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	user := s.user(c, "user@example.com")
	resp, body := user.get("/api/map/style")
	expect(t, resp, body, http.StatusOK)
	if decode[api.MapStyle](t, body).Dark != defaultMapStyleDark {
		t.Fatalf("default: %s", body)
	}
	custom := map[string]string{"light": "https://maps.example.com/l.json", "dark": ""}
	resp, body = user.send(http.MethodPut, "/api/map/style", custom)
	expect(t, resp, body, http.StatusForbidden)
	resp, body = c.send(http.MethodPut, "/api/map/style", map[string]string{"light": "javascript:alert(1)", "dark": ""})
	expect(t, resp, body, http.StatusBadRequest)
	resp, body = c.send(http.MethodPut, "/api/map/style", custom)
	expect(t, resp, body, http.StatusOK)
	got := decode[api.MapStyle](t, body)
	if got.Light != custom["light"] || got.Dark != defaultMapStyleDark {
		t.Fatalf("saved: %s", body)
	}
}
