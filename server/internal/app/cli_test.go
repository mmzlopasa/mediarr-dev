package app

import (
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

// buildCLI makes the command-line uploader once for the tests.
func buildCLI(t *testing.T) string {
	t.Helper()
	if _, err := exec.LookPath("go"); err != nil {
		t.Skip("go is not installed; run through `make test`")
	}
	binary := filepath.Join(t.TempDir(), "mediarr-cli")
	cmd := exec.Command("go", "build", "-o", binary, "./cmd/mediarr-cli")
	cmd.Dir = filepath.Join("..", "..")
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("%v: %s", err, out)
	}
	return binary
}

func runCLI(t *testing.T, binary, server, key string, args ...string) (string, error) {
	t.Helper()
	cmd := exec.Command(binary, args...)
	cmd.Env = append(os.Environ(), "MEDIARR_SERVER="+server, "MEDIARR_API_KEY="+key, "HOME="+t.TempDir())
	out, err := cmd.CombinedOutput()
	return string(out), err
}

func TestTheCLIUploadsAFolderOnceAndDeletesOnlyWhatTheServerHas(t *testing.T) {
	binary := buildCLI(t)
	s := newStack(t)
	admin := s.admin()
	ana := s.user(admin, "ana@example.com")
	key := ana.newKey(t, "upload", "read", "write")

	folder := t.TempDir()
	if err := os.MkdirAll(filepath.Join(folder, "inner", ".hidden"), 0o750); err != nil {
		t.Fatal(err)
	}
	for name, shade := range map[string]uint8{"a.jpg": 10, "inner/b.JPG": 20, "inner/.hidden/c.jpg": 30} {
		if err := os.WriteFile(filepath.Join(folder, name), pictureOf(t, shade), 0o600); err != nil {
			t.Fatal(err)
		}
	}
	if err := os.WriteFile(filepath.Join(folder, "notes.txt"), []byte("not a photo"), 0o600); err != nil {
		t.Fatal(err)
	}

	out, err := runCLI(t, binary, s.url, key, "upload", "--dry-run", folder)
	if err != nil || !strings.Contains(out, "Dry run: 2 would be sent, 0 are already on the server.") {
		t.Fatalf("%v: %s", err, out)
	}
	if n := s.count(t, "SELECT count(*) FROM assets"); n != 0 {
		t.Fatalf("a dry run sent %d", n)
	}

	out, err = runCLI(t, binary, s.url, key, "upload", "--album", "From the computer", folder)
	if err != nil || !strings.Contains(out, "Sent 2 (") || !strings.Contains(out, "failed 0") {
		t.Fatalf("%v: %s", err, out)
	}
	if n := s.count(t, "SELECT count(*) FROM assets"); n != 2 {
		t.Fatalf("%d assets", n)
	}
	albums := ana.albums(t)
	// No worker runs here, so the album counts nothing ready yet; what is in it is in the table.
	album, ok := albums["From the computer"]
	if !ok {
		t.Fatalf("%+v", albums)
	}
	if n := s.count(t, "SELECT count(*) FROM album_assets WHERE album_id = $1", album.Id.String()); n != 2 {
		t.Fatalf("%d in the album", n)
	}

	// The same folder again sends nothing, and makes no second album.
	out, err = runCLI(t, binary, s.url, key, "upload", "--album", "From the computer", folder)
	if err != nil || !strings.Contains(out, "Sent 0 (0 B), already on the server 2") {
		t.Fatalf("%v: %s", err, out)
	}
	if n := len(ana.albums(t)); n != 1 {
		t.Fatalf("%d albums", n)
	}

	// Deleting after keeps what the server does not have.
	extra := filepath.Join(folder, "new.jpg")
	if err := os.WriteFile(extra, pictureOf(t, 40), 0o600); err != nil {
		t.Fatal(err)
	}
	out, err = runCLI(t, binary, s.url, key, "upload", "--delete-after", folder)
	if err != nil || !strings.Contains(out, "Deleted here: 3.") {
		t.Fatalf("%v: %s", err, out)
	}
	for _, gone := range []string{"a.jpg", "inner/b.JPG", "new.jpg"} {
		if _, err := os.Stat(filepath.Join(folder, gone)); !os.IsNotExist(err) {
			t.Errorf("%s is still there", gone)
		}
	}
	for _, kept := range []string{"notes.txt", "inner/.hidden/c.jpg"} {
		if _, err := os.Stat(filepath.Join(folder, kept)); err != nil {
			t.Errorf("%s was deleted", kept)
		}
	}

	// A key without the upload right sends nothing.
	if err := os.WriteFile(extra, pictureOf(t, 50), 0o600); err != nil {
		t.Fatal(err)
	}
	readOnly := ana.newKey(t, "read")
	if out, err = runCLI(t, binary, s.url, readOnly, "upload", folder); err == nil {
		t.Fatalf("a read-only key uploaded: %s", out)
	}
	if n := s.count(t, "SELECT count(*) FROM assets"); n != 3 {
		t.Fatalf("%d assets", n)
	}
}
