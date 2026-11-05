package jobs

import (
	"context"
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"testing"
	"time"
)

func TestASidecarBesideTheFileWinsOverTheFile(t *testing.T) {
	requireTools(t)
	ctx := context.Background()
	dir := t.TempDir()
	jpeg := filepath.Join(dir, "photo.jpg")
	if out, err := exec.Command("vips", "gaussnoise", jpeg, "64", "64").CombinedOutput(); err != nil {
		t.Fatalf("%v: %s", err, out)
	}
	if out, err := exec.Command("exiftool", "-q", "-overwrite_original", "-DateTimeOriginal=2024:05:06 07:08:09", "-Rating=1", jpeg).CombinedOutput(); err != nil {
		t.Fatalf("%v: %s", err, out)
	}
	before, err := os.ReadFile(jpeg)
	if err != nil {
		t.Fatal(err)
	}
	if out, err := exec.Command("exiftool", "-q", "-o", filepath.Join(dir, "photo.xmp"), "-XMP-xmp:Rating=4",
		"-XMP-dc:Description=At the lake", "-XMP-exif:DateTimeOriginal=2001:02:03 04:05:06+02:00",
		"-XMP-exif:GPSLatitude=-45.8", "-XMP-exif:GPSLongitude=15.97").CombinedOutput(); err != nil {
		t.Fatalf("%v: %s", err, out)
	}

	meta, err := ReadMetadata(ctx, jpeg)
	if err != nil {
		t.Fatal(err)
	}
	if meta.Rating != 4 || meta.Caption != "At the lake" {
		t.Fatalf("rating %d, caption %q", meta.Rating, meta.Caption)
	}
	if meta.TakenAt == nil || !meta.TakenAt.Equal(time.Date(2001, 2, 3, 2, 5, 6, 0, time.UTC)) || *meta.OffsetMinutes != 120 {
		t.Fatalf("date %v %v", meta.TakenAt, meta.OffsetMinutes)
	}
	if meta.Latitude == nil || *meta.Latitude != -45.8 {
		t.Fatalf("latitude %v", meta.Latitude)
	}
	if after, _ := os.ReadFile(jpeg); string(after) != string(before) {
		t.Fatal("the original changed")
	}

	// A link is not followed.
	if err := os.Remove(filepath.Join(dir, "photo.xmp")); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink("/etc/passwd", filepath.Join(dir, "photo.xmp")); err != nil {
		t.Fatal(err)
	}
	if meta, err := ReadMetadata(ctx, jpeg); err != nil || meta.Rating != 1 {
		t.Fatalf("through a link: %v %+v", err, meta)
	}
}

func TestMediarrsSidecarCarriesWhatTheOwnerSaid(t *testing.T) {
	requireTools(t)
	ctx := context.Background()
	dir := t.TempDir()
	jpeg := filepath.Join(dir, "photo.jpg")
	if out, err := exec.Command("vips", "gaussnoise", jpeg, "64", "64").CombinedOutput(); err != nil {
		t.Fatalf("%v: %s", err, out)
	}
	when := time.Date(2001, 2, 3, 2, 5, 6, 0, time.UTC)
	offset := int32(120)
	lat, lon := 45.8, 15.97
	path := filepath.Join(dir, "side", "a.xmp")
	facts := &SidecarFacts{
		Rating: 5, Caption: "At the lake", TakenAt: &when, Offset: &offset,
		Latitude: &lat, Longitude: &lon, People: []string{"Ana", "Marko"}, Tags: []string{"lake"},
	}
	for range 2 {
		if size, err := WriteSidecarWithFacts(ctx, jpeg, path, facts); err != nil || size == 0 {
			t.Fatalf("sidecar: %d %v", size, err)
		}
	}
	// A file whose metadata cannot be read still gets what Mediarr knows.
	broken := filepath.Join(dir, "broken.jpg")
	if err := os.WriteFile(broken, []byte("not a picture"), 0o600); err != nil {
		t.Fatal(err)
	}
	if size, err := WriteSidecarWithFacts(ctx, broken, filepath.Join(dir, "side", "b.xmp"), facts); err != nil || size == 0 {
		t.Fatalf("sidecar of a broken file: %d %v", size, err)
	}
	out, err := exec.Command("exiftool", "-json", "-n", path).Output()
	if err != nil {
		t.Fatal(err)
	}
	var rows []map[string]any
	if err := json.Unmarshal(out, &rows); err != nil || len(rows) != 1 {
		t.Fatalf("%v %s", err, out)
	}
	row := rows[0]
	if row["Rating"] != 5.0 || row["Description"] != "At the lake" || row["DateTimeOriginal"] != "2001:02:03 04:05:06+02:00" ||
		row["GPSLatitude"] != 45.8 {
		t.Fatalf("sidecar: %v", row)
	}
	if people, _ := row["PersonInImage"].([]any); len(people) != 2 {
		t.Fatalf("people: %v", row["PersonInImage"])
	}
}
