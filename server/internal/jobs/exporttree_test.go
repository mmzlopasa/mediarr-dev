package jobs

import (
	"archive/zip"
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/ringsaturn/tzf"
)

func writeZip(t *testing.T, path string, files map[string]string) {
	t.Helper()
	out, err := os.Create(path) //nolint:gosec // A test file.
	if err != nil {
		t.Fatal(err)
	}
	writer := zip.NewWriter(out)
	for name, body := range files {
		entry, err := writer.Create(name)
		if err != nil {
			t.Fatal(err)
		}
		if _, err := io.WriteString(entry, body); err != nil {
			t.Fatal(err)
		}
	}
	if err := writer.Close(); err != nil {
		t.Fatal(err)
	}
	if err := out.Close(); err != nil {
		t.Fatal(err)
	}
}

func TestCleanEntryNameKeepsNamesInside(t *testing.T) {
	for name, want := range map[string]string{
		"Takeout/Google Photos/a.jpg": "Takeout/Google Photos/a.jpg",
		"Takeout\\Photos\\b.jpg":      "Takeout/Photos/b.jpg",
		"./x/./y.jpg":                 "x/y.jpg",
	} {
		if got, ok := cleanEntryName(name); !ok || got != want {
			t.Errorf("%q: %q %v", name, got, ok)
		}
	}
	for _, name := range []string{"../evil.jpg", "a/../../evil.jpg", "/etc/passwd", "", "."} {
		if _, ok := cleanEntryName(name); ok {
			t.Errorf("%q was let in", name)
		}
	}
}

func TestZipPartsJoinIntoOneExport(t *testing.T) {
	dir := t.TempDir()
	one, two := filepath.Join(dir, "takeout-001.zip"), filepath.Join(dir, "takeout-002.zip")
	writeZip(t, one, map[string]string{
		"Takeout/Google Photos/Trip/IMG_1.jpg":     "picture",
		"Takeout/Google Photos/Trip/metadata.json": `{"title":"Trip","description":"By the sea"}`,
		"../outside.jpg": "never",
	})
	writeZip(t, two, map[string]string{
		"Takeout/Google Photos/Trip/IMG_1.jpg.supplemental-metadata.json": `{"description":"Sunset"}`,
		"Takeout/Google Photos/Trip/big.json":                             strings.Repeat("x", maxSidecarBytes+1),
	})
	tree, err := newZipTree([]string{one, two})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = tree.close() }()
	if media := tree.media(); len(media) != 1 || media[0] != "Takeout/Google Photos/Trip/IMG_1.jpg" {
		t.Fatalf("media: %v", media)
	}
	names := tree.names("Takeout/Google Photos/Trip")
	sidecar := FindTakeoutSidecar("IMG_1.jpg", names)
	if sidecar != "IMG_1.jpg.supplemental-metadata.json" {
		t.Fatalf("the sidecar in the other part was not found: %q in %v", sidecar, names)
	}
	raw, err := tree.small("Takeout/Google Photos/Trip/" + sidecar)
	if err != nil {
		t.Fatal(err)
	}
	item, _, err := parseTakeoutSidecar(raw)
	if err != nil || item.caption != "Sunset" {
		t.Fatalf("%+v %v", item, err)
	}
	if _, err := tree.small("Takeout/Google Photos/Trip/big.json"); err == nil {
		t.Fatal("a file larger than a sidecar was read")
	}
	reader, size, _, err := tree.open("Takeout/Google Photos/Trip/IMG_1.jpg")
	if err != nil {
		t.Fatal(err)
	}
	body, err := io.ReadAll(reader)
	_ = reader.Close()
	if err != nil || string(body) != "picture" || size != int64(len("picture")) {
		t.Fatalf("%q %d %v", body, size, err)
	}
	meta, err := tree.small("Takeout/Google Photos/Trip/metadata.json")
	if err != nil {
		t.Fatal(err)
	}
	if title, description := TakeoutAlbum(meta); title != "Trip" || description != "By the sea" {
		t.Fatalf("%q %q", title, description)
	}
}

func TestANonZipPartIsRefused(t *testing.T) {
	path := filepath.Join(t.TempDir(), "photos.zip")
	if err := os.WriteFile(path, []byte("not a zip"), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := newZipTree([]string{path}); err == nil {
		t.Fatal("a file that is not a ZIP file was read")
	}
}

func TestICloudRowsAreFoundByFolderFirst(t *testing.T) {
	var details ICloudDetails
	details.Add("Part 1/Photos", map[string]ICloudRow{"img_1.heic": {Favorite: true}})
	details.Add("Part 2/Photos", map[string]ICloudRow{"img_1.heic": {Hidden: true}, "img_2.heic": {Deleted: true}})
	if row := details.Find("Part 2/Photos/IMG_1.HEIC"); !row.Hidden || row.Favorite {
		t.Fatalf("the row of the other folder was used: %+v", row)
	}
	if row := details.Find("Elsewhere/IMG_2.HEIC"); !row.Deleted {
		t.Fatal("a name found in one list only was not used")
	}
	if row := details.Find("Elsewhere/IMG_1.HEIC"); row.Favorite || row.Hidden {
		t.Fatal("a name in two lists was guessed")
	}
}

func TestTheTimeZoneComesFromThePlace(t *testing.T) {
	finder, err := tzf.NewDefaultFinder()
	if err != nil {
		t.Fatal(err)
	}
	summer := time.Date(2024, 7, 15, 17, 0, 0, 0, time.UTC)
	winter := time.Date(2024, 1, 15, 17, 0, 0, 0, time.UTC)
	for _, c := range []struct {
		name     string
		lat, lon float64
		when     time.Time
		want     int32
	}{
		{"Split in summer", 43.508, 16.44, summer, 120},
		{"Split in winter", 43.508, 16.44, winter, 60},
		{"New York in summer", 40.71, -74.0, summer, -240},
		{"Kolkata", 22.57, 88.36, summer, 330},
	} {
		got, ok := OffsetAt(finder, c.lat, c.lon, c.when)
		if !ok || got != c.want {
			t.Errorf("%s: %d %v", c.name, got, ok)
		}
	}
	run := &importRun{zones: finder}
	lat, lon := 43.508, 16.44
	item := &importItem{takenAt: &summer, latitude: &lat, longitude: &lon}
	run.placeInTime(item)
	if item.offset == nil || *item.offset != 120 {
		t.Fatal("the import did not place the photo in its time zone")
	}
	given := int32(-60)
	item = &importItem{takenAt: &summer, latitude: &lat, longitude: &lon, offset: &given}
	run.placeInTime(item)
	if *item.offset != -60 {
		t.Fatal("a time zone the source gave was replaced")
	}
}

func TestAnXMPBesideAPhotoIsFound(t *testing.T) {
	names := []string{"a.jpg", "a.jpg.xmp", "b.jpg", "b.xmp", "c.jpg"}
	for name, want := range map[string]string{"dir/a.jpg": "a.jpg.xmp", "dir/b.jpg": "b.xmp", "dir/c.jpg": ""} {
		if got := sidecarXMP(name, names); got != want {
			t.Errorf("%s: %q", name, got)
		}
	}
}
