package app

import (
	"bytes"
	"context"
	"image"
	"image/color"
	"image/jpeg"
	"net/http"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/mediarr-app/mediarr/server/internal/api"
)

// pictureOf is a real picture that differs by its colour, so that no two are the same file.
func pictureOf(t *testing.T, shade uint8) []byte {
	t.Helper()
	canvas := image.NewRGBA(image.Rect(0, 0, 64, 48))
	for y := range 48 {
		for x := range 64 {
			canvas.Set(x, y, color.RGBA{R: shade, G: uint8(x), B: uint8(y), A: 255}) //nolint:gosec // Small numbers.
		}
	}
	var out bytes.Buffer
	if err := jpeg.Encode(&out, canvas, nil); err != nil {
		t.Fatal(err)
	}
	return out.Bytes()
}

func (c *client) startImport(t *testing.T, payload map[string]any) api.ImportEntry {
	t.Helper()
	resp, body := c.post("/api/admin/imports", payload)
	expect(t, resp, body, http.StatusCreated)
	id := decode[map[string]string](t, body)["id"]
	end := time.Now().Add(3 * time.Minute)
	for time.Now().Before(end) {
		resp, body = c.get("/api/admin/imports")
		expect(t, resp, body, http.StatusOK)
		for _, entry := range decode[[]api.ImportEntry](t, body) {
			if entry.Id.String() == id && entry.Status != api.ImportEntryStatusRunning {
				return entry
			}
		}
		time.Sleep(200 * time.Millisecond)
	}
	t.Fatal("the import never finished")
	return api.ImportEntry{}
}

func (s *stack) settle(t *testing.T) {
	t.Helper()
	end := time.Now().Add(2 * time.Minute)
	for s.count(t, "SELECT count(*) FROM assets WHERE status='processing'") > 0 {
		if time.Now().After(end) {
			t.Fatal("files are still being processed")
		}
		time.Sleep(200 * time.Millisecond)
	}
}

func TestImportsAreForAdminsAndChecked(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	user := s.user(admin, "user@example.com")
	owner := s.userID("user@example.com")
	resp, body := user.post("/api/admin/imports", map[string]any{"source": "immich", "ownerId": owner, "address": "http://x", "apiKey": "k"})
	expect(t, resp, body, http.StatusForbidden)
	for _, bad := range []map[string]any{
		{"source": "immich", "ownerId": owner},
		{"source": "immich", "ownerId": owner, "address": "file:///etc/passwd", "apiKey": "k"},
		{"source": "takeout", "ownerId": owner},
		{"source": "nonsense", "ownerId": owner},
		{"source": "immich", "ownerId": "00000000-0000-4000-8000-000000000000", "address": "http://x", "apiKey": "k"},
	} {
		resp, body = admin.post("/api/admin/imports", bad)
		expect(t, resp, body, http.StatusBadRequest)
	}
}

func TestTakeoutComesInWithItsDatesAndAlbums(t *testing.T) {
	s := newStack(t)
	s.startWorker(t)
	c := s.admin()
	root := filepath.Join(s.external, "Takeout", "Google Photos")
	write := func(name string, data []byte) {
		t.Helper()
		path := filepath.Join(root, name)
		if err := os.MkdirAll(filepath.Dir(path), 0o750); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(path, data, 0o600); err != nil {
			t.Fatal(err)
		}
	}
	write("Photos from 2019/a.jpg", pictureOf(t, 10))
	write("Photos from 2019/a.jpg.json", []byte(`{"photoTakenTime":{"timestamp":"1561975200"},"favorited":true,"geoData":{"latitude":45.8,"longitude":15.9}}`))
	write("Photos from 2019/gone.jpg", pictureOf(t, 20))
	write("Photos from 2019/gone.jpg.json", []byte(`{"trashed":true}`))
	write("Trip/b.jpg", pictureOf(t, 30))
	write("Trip/b.jpg.supplemental-metadata.json", []byte(`{"photoTakenTime":{"timestamp":"1500000000"},"archived":true}`))
	write("Trip/metadata.json", []byte(`{"title":"Summer trip"}`))
	// A folder with no name of an album, and a file with nothing beside it.
	write("Photos from 2020/c.jpg", pictureOf(t, 40))

	owner := s.userID("admin@example.com")
	entry := c.startImport(t, map[string]any{"source": "takeout", "ownerId": owner, "folder": "Takeout"})
	if entry.Status != api.ImportEntryStatusDone || entry.Added != 3 || entry.Skipped != 1 || entry.Failed != 0 {
		t.Fatalf("%+v", entry)
	}
	s.settle(t)
	if got := s.count(t, `SELECT count(*) FROM assets WHERE original_name='a.jpg' AND is_favorite
		AND taken_at = to_timestamp(1561975200)`); got != 1 {
		t.Fatal("the date or favorite from the sidecar was lost")
	}
	if got := s.count(t, `SELECT count(*) FROM exif e JOIN assets a ON a.id=e.asset_id WHERE a.original_name='a.jpg' AND e.latitude = 45.8`); got != 1 {
		t.Fatal("the location from the sidecar was lost")
	}
	if got := s.count(t, `SELECT count(*) FROM assets WHERE original_name='b.jpg' AND archived_at IS NOT NULL`); got != 1 {
		t.Fatal("the archive state was lost")
	}
	if got := s.count(t, `SELECT count(*) FROM album_assets x JOIN albums a ON a.id=x.album_id WHERE a.title='Summer trip'`); got != 1 {
		t.Fatal("the album was lost")
	}
	if got := s.count(t, `SELECT count(*) FROM assets WHERE original_name='gone.jpg'`); got != 0 {
		t.Fatal("what was in the trash came in")
	}

	// Importing again changes nothing, and finds the same album.
	entry = c.startImport(t, map[string]any{"source": "takeout", "ownerId": owner, "folder": "Takeout"})
	if entry.Added != 0 || entry.Skipped != 4 {
		t.Fatalf("again: %+v", entry)
	}
	if got := s.count(t, "SELECT count(*) FROM assets"); got != 3 {
		t.Fatalf("assets: %d", got)
	}
	if got := s.count(t, "SELECT count(*) FROM albums"); got != 1 {
		t.Fatalf("albums: %d", got)
	}
	// A folder outside the mount does not exist as far as this goes.
	entry = c.startImport(t, map[string]any{"source": "takeout", "ownerId": owner, "folder": "../../etc"})
	if entry.Status != api.ImportEntryStatusFailed {
		t.Fatalf("outside: %+v", entry)
	}
}

func TestICloudExportComesIn(t *testing.T) {
	s := newStack(t)
	s.startWorker(t)
	c := s.admin()
	root := filepath.Join(s.external, "iCloud Photos")
	for name, data := range map[string][]byte{
		"Photos/IMG_1.jpg":         pictureOf(t, 50),
		"Photos/IMG_2.jpg":         pictureOf(t, 60),
		"Photos/IMG_3.jpg":         pictureOf(t, 70),
		"Photos/Photo Details.csv": []byte("imgName,fileChecksum,favorite,hidden,deleted,originalCreationDate\nIMG_1.jpg,a,yes,no,no,\"Monday May 1,2023 10:00 AM GMT\"\nIMG_2.jpg,b,no,no,yes,\"Monday May 1,2023 10:00 AM GMT\"\nIMG_3.jpg,c,no,yes,no,\"Monday May 1,2023 10:00 AM GMT\"\n"),
		"Albums/Family.csv":        []byte("Images\nIMG_1.jpg\n"),
	} {
		path := filepath.Join(root, name)
		if err := os.MkdirAll(filepath.Dir(path), 0o750); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(path, data, 0o600); err != nil {
			t.Fatal(err)
		}
	}
	entry := c.startImport(t, map[string]any{"source": "icloud", "ownerId": s.userID("admin@example.com"), "folder": "iCloud Photos"})
	if entry.Added != 2 || entry.Skipped != 1 || entry.Failed != 0 {
		t.Fatalf("%+v", entry)
	}
	s.settle(t)
	if got := s.count(t, `SELECT count(*) FROM assets a JOIN album_assets x ON x.asset_id=a.id JOIN albums l ON l.id=x.album_id
		WHERE a.original_name='IMG_1.jpg' AND a.is_favorite AND l.title='Family' AND a.taken_at='2023-05-01 10:00:00+00'`); got != 1 {
		t.Fatal("IMG_1 lost what the export said")
	}
	if got := s.count(t, `SELECT count(*) FROM assets WHERE original_name='IMG_3.jpg' AND archived_at IS NOT NULL`); got != 1 {
		t.Fatal("a hidden photo should be archived")
	}
}

// Runs against a real Immich when given one: IMMICH_TEST_URL and IMMICH_TEST_KEY. This is a gate of the
// phase. It expects exactly 4 photos, one a favorite and one archived, an album "Ljetovanje" described
// "More" with 2 of them, and a person "Ana" with one face added by hand.
func TestImportFromARealImmich(t *testing.T) {
	address, key := os.Getenv("IMMICH_TEST_URL"), os.Getenv("IMMICH_TEST_KEY")
	if address == "" || key == "" {
		t.Skip("no Immich to import from")
	}
	s := newStack(t)
	s.startWorker(t)
	c := s.admin()
	owner := s.userID("admin@example.com")
	payload := map[string]any{"source": "immich", "ownerId": owner, "address": address, "apiKey": key}
	entry := c.startImport(t, payload)
	t.Logf("first: %+v", entry)
	if entry.Status != api.ImportEntryStatusDone || entry.Added != 4 || entry.Failed != 0 {
		t.Fatalf("%+v", entry)
	}
	s.settle(t)
	if got := s.count(t, "SELECT count(*) FROM assets WHERE status='ready'"); got != 4 {
		t.Fatalf("ready: %d", got)
	}
	if got := s.count(t, "SELECT count(*) FROM assets WHERE is_favorite"); got != 1 {
		t.Fatalf("favorites: %d", got)
	}
	if got := s.count(t, "SELECT count(*) FROM assets WHERE archived_at IS NOT NULL"); got != 1 {
		t.Fatalf("archived: %d", got)
	}
	if got := s.count(t, `SELECT count(*) FROM album_assets x JOIN albums a ON a.id=x.album_id WHERE a.title='Ljetovanje' AND a.description='More'`); got != 2 {
		t.Fatalf("album: %d", got)
	}
	if got := s.count(t, "SELECT count(*) FROM people WHERE name='Ana'"); got != 1 {
		t.Fatalf("person: %d", got)
	}
	if got := s.count(t, "SELECT count(*) FROM face_hints"); got != 1 {
		t.Fatalf("face: %d", got)
	}
	if got := s.count(t, "SELECT count(*) FROM imports WHERE secret <> ''"); got != 0 {
		t.Fatal("the key was kept after the import")
	}

	entry = c.startImport(t, payload)
	t.Logf("again: %+v", entry)
	if entry.Added != 0 || entry.Skipped != 4 {
		t.Fatalf("again: %+v", entry)
	}
	ctx := context.Background()
	for query, want := range map[string]int{
		"SELECT count(*) FROM assets":       4,
		"SELECT count(*) FROM albums":       1,
		"SELECT count(*) FROM people":       1,
		"SELECT count(*) FROM face_hints":   1,
		"SELECT count(*) FROM album_assets": 2,
	} {
		var got int
		if err := s.pool.QueryRow(ctx, query).Scan(&got); err != nil {
			t.Fatal(err)
		}
		if got != want {
			t.Errorf("%s: %d, want %d", query, got, want)
		}
	}

	// A person whose id the import remembers can be gone, and the file must still count as fine.
	if _, err := s.pool.Exec(ctx, "DELETE FROM people WHERE name='Ana'"); err != nil {
		t.Fatal(err)
	}
	entry = c.startImport(t, payload)
	if entry.Failed != 0 || entry.Added != 0 {
		t.Fatalf("after the person was gone: %+v", entry)
	}
}
