package app

import (
	"archive/zip"
	"io"
	"os"
	"path/filepath"
	"testing"

	"github.com/mediarr-app/mediarr/server/db"
)

func TestAZipLeavesOutALinkToAnotherFile(t *testing.T) {
	dir := t.TempDir()
	secret := filepath.Join(dir, "secret.txt")
	if err := os.WriteFile(secret, []byte("not yours"), 0o600); err != nil {
		t.Fatal(err)
	}
	link := filepath.Join(dir, "photo.jpg")
	if err := os.Symlink(secret, link); err != nil {
		t.Fatal(err)
	}
	archive := zip.NewWriter(io.Discard)
	if err := addToZip(archive, &db.Asset{OriginalPath: link, OriginalName: "photo.jpg"}, map[string]int{}); err == nil {
		t.Error("a symbolic link went into the ZIP")
	}

	plain := filepath.Join(dir, "plain.jpg")
	if err := os.WriteFile(plain, []byte("jpeg"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := addToZip(archive, &db.Asset{OriginalPath: plain, OriginalName: "plain.jpg"}, map[string]int{}); err != nil {
		t.Errorf("a plain file was refused: %v", err)
	}
}
