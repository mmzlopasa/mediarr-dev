package storage

import (
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestPrepareWritesMarkerOnFirstUse(t *testing.T) {
	dir := filepath.Join(t.TempDir(), "library")
	if err := Prepare(dir, false); err != nil {
		t.Fatal(err)
	}
	if err := CheckMarker(dir); err != nil {
		t.Error(err)
	}
	if err := Prepare(dir, true); err != nil {
		t.Errorf("second start failed: %v", err)
	}
}

func TestPrepareRefusesUnmountedDisk(t *testing.T) {
	err := Prepare(t.TempDir(), true)
	if !errors.Is(err, ErrMarkerMissing) {
		t.Fatalf("got %v", err)
	}
}

func TestPrepareRejectsRelativePath(t *testing.T) {
	if Prepare("relative/path", false) == nil {
		t.Error("relative path accepted")
	}
}

func TestSafeName(t *testing.T) {
	tests := map[string]string{
		"IMG_0001.HEIC":          "IMG_0001.HEIC",
		"../../etc/passwd":       "passwd",
		`..\..\windows\win.ini`:  "win.ini",
		"/abs/path/a.jpg":        "a.jpg",
		"..":                     "file",
		"":                       "file",
		"bad\x00na\nme.jpg":      "badname.jpg",
		`q?u"o*t<e>s.png`:        "quotes.png",
		"-rf.jpg":                "-rf.jpg",
		"Šišmiš na plaži č.jpeg": "Šišmiš na plaži č.jpeg",
	}
	for in, want := range tests {
		if got := SafeName(in); got != want {
			t.Errorf("SafeName(%q) = %q, want %q", in, got, want)
		}
	}
	long := SafeName(strings.Repeat("a", 500) + ".jpg")
	if len(long) != maxNameLength+4 || !strings.HasSuffix(long, ".jpg") {
		t.Errorf("long name = %d bytes", len(long))
	}
}

func TestOriginalPathStaysInsideLibrary(t *testing.T) {
	when := time.Date(2024, 3, 9, 23, 0, 0, 0, time.UTC)
	got := OriginalPath("/lib", "user", when, strings.Repeat("ab", 32), "../../x.jpg")
	want := "/lib/user/2024/03/abababababababab-x.jpg"
	if got != want {
		t.Errorf("got %s, want %s", got, want)
	}
}

func TestPublishMakesOriginalReadOnly(t *testing.T) {
	dir := t.TempDir()
	tmp := filepath.Join(dir, "tmp")
	if err := os.WriteFile(tmp, []byte("data"), 0o640); err != nil {
		t.Fatal(err)
	}
	dest := filepath.Join(dir, "a", "b", "file")
	if err := Publish(tmp, dest); err != nil {
		t.Fatal(err)
	}
	info, err := os.Stat(dest)
	if err != nil {
		t.Fatal(err)
	}
	if info.Mode().Perm()&0o222 != 0 {
		t.Errorf("mode = %v, want read-only", info.Mode())
	}
	if _, err := os.Stat(tmp); !errors.Is(err, os.ErrNotExist) {
		t.Error("temporary file still exists")
	}
}
