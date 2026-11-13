package jobs

import (
	"os"
	"path/filepath"
	"slices"
	"testing"
)

func TestAPurgedAssetLosesItsCopiesForLinksAndTVs(t *testing.T) {
	cache := t.TempDir()
	id := "1a2b3c4d-0000-0000-0000-000000000000"
	other := "1a9999aa-0000-0000-0000-000000000000"
	files := []string{
		filepath.Join("links", "l1", id+"-thumb_large-r0.webp"),
		filepath.Join("links", "l1", "v2", id+"-lfalsectruedfalse-r1.jpg"),
		filepath.Join("tv", "1a", id+"-r0.jpg"),
		filepath.Join("tv", "1a", id+"-nolocation.mp4"),
		filepath.Join("tv", "1a", other+"-r0.jpg"),
	}
	for _, name := range files {
		path := filepath.Join(cache, name)
		if err := os.MkdirAll(filepath.Dir(path), 0o750); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(path, nil, 0o600); err != nil {
			t.Fatal(err)
		}
	}
	got, err := cachedCopies(cache, id)
	if err != nil {
		t.Fatal(err)
	}
	want := make([]string, 0, 4)
	for _, name := range files[:4] {
		want = append(want, filepath.Join(cache, name))
	}
	slices.Sort(got)
	slices.Sort(want)
	if !slices.Equal(got, want) {
		t.Errorf("copies\n%v\nwant\n%v", got, want)
	}
}
