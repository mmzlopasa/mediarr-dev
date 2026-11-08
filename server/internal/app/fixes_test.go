package app

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"testing"
	"time"

	"github.com/mediarr-app/mediarr/server/internal/api"
)

// dated is a photo's local time and offset, as the timeline shows it.
func (s *stack) dated(t *testing.T, id string) (string, *int32, bool) {
	t.Helper()
	var local time.Time
	var offset *int32
	var manual bool
	err := s.pool.QueryRow(context.Background(),
		`SELECT local_at, taken_offset_minutes, manual_taken_at IS NOT NULL FROM assets WHERE id = $1`, id).
		Scan(&local, &offset, &manual)
	if err != nil {
		t.Fatal(err)
	}
	return local.Format("2006-01-02T15:04"), offset, manual
}

func (s *stack) placeAt(t *testing.T, id string, lat, lon float64) {
	t.Helper()
	_, err := s.pool.Exec(context.Background(), `INSERT INTO exif (asset_id, latitude, longitude, raw) VALUES ($1, $2, $3, '{}')
		ON CONFLICT (asset_id) DO UPDATE SET latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude`, id, lat, lon)
	if err != nil {
		t.Fatal(err)
	}
}

func (s *stack) location(t *testing.T, id string) string {
	t.Helper()
	var lat, lon *float64
	var none bool
	err := s.pool.QueryRow(context.Background(), `SELECT e.latitude, e.longitude, a.manual_location_none
		FROM assets a LEFT JOIN exif e ON e.asset_id = a.id WHERE a.id = $1`, id).Scan(&lat, &lon, &none)
	if err != nil {
		t.Fatal(err)
	}
	if lat == nil || lon == nil {
		if none {
			return "none"
		}
		return ""
	}
	return fmt.Sprintf("%.4f,%.4f", *lat, *lon)
}

func fixed(t *testing.T, c *client, path string, payload map[string]any) api.FixResult {
	t.Helper()
	resp, body := c.post(path, payload)
	expect(t, resp, body, http.StatusOK)
	return decode[api.FixResult](t, body)
}

func TestDatesAreShiftedSetAndZonedForManyPhotos(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	ana := s.user(admin, "ana@example.com")
	a := ana.newPhoto(t, "a.jpg", "2024-07-05T12:00:00Z")
	b := ana.newPhoto(t, "b.jpg", "2024-07-05T12:10:00Z")
	winter := ana.newPhoto(t, "winter.jpg", "2024-01-10T12:00:00Z")
	notMine := admin.newPhoto(t, "admins.jpg", "2024-07-05T12:00:00Z")

	// A preview changes nothing; someone else's photo is not even seen.
	got := fixed(t, ana, "/api/assets/dates", map[string]any{"ids": []string{a, b, notMine}, "action": "shift", "minutes": -72, "dryRun": true})
	if got.Changed != 2 || got.Changes[0].Before != "2024-07-05T12:00:00" || got.Changes[0].After != "2024-07-05T10:48:00" {
		t.Fatalf("%+v", got)
	}
	if local, _, manual := s.dated(t, a); local != "2024-07-05T12:00" || manual {
		t.Fatalf("a preview changed it: %s", local)
	}
	fixed(t, ana, "/api/assets/dates", map[string]any{"ids": []string{a, b, notMine}, "action": "shift", "minutes": -72})
	if local, _, manual := s.dated(t, b); local != "2024-07-05T10:58" || !manual {
		t.Fatalf("%s %v", local, manual)
	}
	if local, _, _ := s.dated(t, notMine); local != "2024-07-05T12:00" {
		t.Fatalf("someone else's photo moved: %s", local)
	}

	// One date for all keeps their order, a minute apart.
	fixed(t, ana, "/api/assets/dates", map[string]any{"ids": []string{b, a}, "action": "set", "takenAt": "1998-06-01T09:00:00+02:00"})
	if local, offset, _ := s.dated(t, a); local != "1998-06-01T09:00" || offset == nil || *offset != 120 {
		t.Fatalf("%s %v", local, offset)
	}
	if local, _, _ := s.dated(t, b); local != "1998-06-01T09:01" {
		t.Fatalf("%s", local)
	}

	// The zone of the place: the clock stays, summer time included; without GPS, nothing to go by.
	s.placeAt(t, winter, 45.8150, 15.9819)
	plain := ana.newPhoto(t, "plain.jpg", "2024-07-05T12:00:00Z")
	summer := ana.newPhoto(t, "summer.jpg", "2024-07-05T12:00:00Z")
	s.placeAt(t, summer, 45.8150, 15.9819)
	got = fixed(t, ana, "/api/assets/dates", map[string]any{"ids": []string{winter, summer, plain}, "action": "zoneFromPlace"})
	if got.Changed != 2 || got.Skipped != 1 {
		t.Fatalf("%+v", got)
	}
	if local, offset, _ := s.dated(t, summer); local != "2024-07-05T12:00" || *offset != 120 {
		t.Fatalf("summer: %s %v", local, *offset)
	}
	if local, offset, _ := s.dated(t, winter); local != "2024-01-10T12:00" || *offset != 60 {
		t.Fatalf("winter: %s %v", local, *offset)
	}

	// A trip: the camera stayed on Zagreb's time in Tokyo, so it shows seven hours later there.
	trip := ana.newPhoto(t, "tokyo.jpg", "2024-07-05T12:00:00Z")
	fixed(t, ana, "/api/assets/dates", map[string]any{"ids": []string{trip}, "action": "travel", "cameraZone": "Europe/Zagreb", "placeZone": "Asia/Tokyo"})
	if local, offset, _ := s.dated(t, trip); local != "2024-07-05T19:00" || *offset != 540 {
		t.Fatalf("%s %v", local, *offset)
	}

	// Back to what the file said: the hand-set date goes.
	fixed(t, ana, "/api/assets/dates", map[string]any{"ids": []string{trip}, "action": "useFile"})
	if _, _, manual := s.dated(t, trip); manual {
		t.Fatal("the hand-set date stayed")
	}

	// Bad input says why.
	for _, bad := range []map[string]any{
		{"ids": []string{a}, "action": "shift"},
		{"ids": []string{a}, "action": "set", "takenAt": "2999-01-01T00:00:00Z"},
		{"ids": []string{a}, "action": "travel", "cameraZone": "Mars/Base", "placeZone": "Asia/Tokyo"},
		{"ids": []string{}, "action": "shift", "minutes": 5},
	} {
		resp, body := ana.post("/api/assets/dates", bad)
		expect(t, resp, body, http.StatusBadRequest)
	}
}

const gpx = `<?xml version="1.0"?>
<gpx version="1.1" creator="test" xmlns="http://www.topografix.com/GPX/1/1"><trk><trkseg>
<trkpt lat="45.0000" lon="15.0000"><time>2024-07-05T10:00:00Z</time></trkpt>
<trkpt lat="45.0200" lon="15.0400"><time>2024-07-05T10:04:00Z</time></trkpt>
</trkseg></trk></gpx>`

func TestLocationsAreSetTakenAwayAndFoundForManyPhotos(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	ana := s.user(admin, "ana@example.com")
	phone := ana.newPhoto(t, "phone.jpg", "2024-07-05T10:00:00Z")
	s.placeAt(t, phone, 43.5081, 16.4402)
	camera := ana.newPhoto(t, "camera.jpg", "2024-07-05T10:20:00Z")
	far := ana.newPhoto(t, "far.jpg", "2024-07-05T14:00:00Z")
	walk := ana.newPhoto(t, "walk.jpg", "2024-07-05T10:02:00Z")
	notMine := admin.newPhoto(t, "admins.jpg", "2024-07-05T10:00:00Z")

	// From nearby photos: within half an hour by default.
	got := fixed(t, ana, "/api/assets/locations", map[string]any{"ids": []string{camera, far, notMine}, "action": "fromNeighbours", "dryRun": true})
	if got.Changed != 1 || got.Skipped != 1 || got.Changes[0].After != "43.50810, 16.44020" {
		t.Fatalf("%+v", got)
	}
	fixed(t, ana, "/api/assets/locations", map[string]any{"ids": []string{camera, far}, "action": "fromNeighbours"})
	if loc := s.location(t, camera); loc == "" {
		t.Fatal("no location from the phone's photo")
	}
	if loc := s.location(t, notMine); loc != "" {
		t.Fatalf("someone else's photo: %s", loc)
	}

	// From a GPX track: halfway between two points.
	got = fixed(t, ana, "/api/assets/locations", map[string]any{"ids": []string{walk, far}, "action": "fromTrack", "track": gpx})
	if got.Changed != 1 || got.Skipped != 1 || got.Changes[0].After != "45.01000, 15.02000" {
		t.Fatalf("%+v", got)
	}
	resp, body := ana.post("/api/assets/locations", map[string]any{"ids": []string{far}, "action": "fromTrack", "track": "not gpx"})
	expect(t, resp, body, http.StatusBadRequest)

	// Set by hand, taken away, and back to the file.
	fixed(t, ana, "/api/assets/locations", map[string]any{"ids": []string{far}, "action": "set", "latitude": 35.68, "longitude": 139.76})
	if loc := s.location(t, far); loc == "" || loc == "none" {
		t.Fatalf("%s", loc)
	}
	fixed(t, ana, "/api/assets/locations", map[string]any{"ids": []string{far, phone}, "action": "clear"})
	if loc := s.location(t, phone); loc != "none" {
		t.Fatalf("%s", loc)
	}
	fixed(t, ana, "/api/assets/locations", map[string]any{"ids": []string{phone}, "action": "useFile"})
	var none bool
	if err := s.pool.QueryRow(context.Background(), "SELECT manual_location_none FROM assets WHERE id = $1", phone).Scan(&none); err != nil || none {
		t.Fatalf("%v %v", err, none)
	}
	resp, body = ana.post("/api/assets/locations", map[string]any{"ids": []string{far}, "action": "set", "latitude": 95, "longitude": 0})
	expect(t, resp, body, http.StatusBadRequest)
}

func TestANewPhotoWithAPlaceButNoZoneGetsTheZoneOfThePlace(t *testing.T) {
	for _, tool := range []string{"vips", "exiftool"} {
		if _, err := exec.LookPath(tool); err != nil {
			t.Skip("media tools are not installed; run through `make test`")
		}
	}
	s := newStack(t)
	c := s.admin()
	s.startWorker(t)
	dir := t.TempDir()
	plain := filepath.Join(dir, "plain.jpg")
	placed := filepath.Join(dir, "placed.jpg")
	for _, step := range [][]string{
		{"vips", "black", plain, "64", "48"},
		// The clock of Zagreb in summer, without a zone, and where it was.
		{
			"exiftool", "-q", "-DateTimeOriginal=2024:07:05 19:30:00", "-GPSLatitude=45.815", "-GPSLatitudeRef=N",
			"-GPSLongitude=15.9819", "-GPSLongitudeRef=E", "-o", placed, plain,
		},
	} {
		if out, err := exec.Command(step[0], step[1:]...).CombinedOutput(); err != nil {
			t.Fatalf("%v: %s", err, out)
		}
	}
	data, err := os.ReadFile(placed)
	if err != nil {
		t.Fatal(err)
	}
	id := uploadedID(t, c.upload("placed.jpg", data, nil))
	waitForAsset(t, c, "placed.jpg")
	// The hour stays as it was there, and the photo knows its zone.
	if local, offset, _ := s.dated(t, id); local != "2024-07-05T19:30" || offset == nil || *offset != 120 {
		t.Fatalf("%s %v", local, offset)
	}
}
