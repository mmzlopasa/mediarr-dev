package jobs

import (
	"context"
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestOnlyMediaIsRead(t *testing.T) {
	for path, want := range map[string]bool{
		"/x/a.JPG": true, "/x/a.cr2": true, "/x/v.mov": true, "/x/a.txt": false, "/x/.a.jpg": false, "/x/a": false,
	} {
		if isExternalMedia(path) != want {
			t.Errorf("%s: want %v", path, want)
		}
	}
}

func TestWalkDoesNotFollowLinks(t *testing.T) {
	root := t.TempDir()
	outside := t.TempDir()
	if err := os.WriteFile(filepath.Join(outside, "secret.jpg"), []byte("x"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(outside, filepath.Join(root, "link")); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(filepath.Join(outside, "secret.jpg"), filepath.Join(root, "link.jpg")); err != nil {
		t.Fatal(err)
	}
	found, complete, err := walkExternal(root)
	if err != nil || !complete || len(found) != 0 {
		t.Fatalf("%v %v %v", found, complete, err)
	}
}

func TestWatchSeesChangesInNewFolders(t *testing.T) {
	root := t.TempDir()
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	changed := make(chan struct{}, 8)
	done := make(chan error, 1)
	go func() {
		done <- WatchExternal(ctx, root, 50*time.Millisecond, func() { changed <- struct{}{} })
	}()
	time.Sleep(100 * time.Millisecond)

	wait := func() {
		t.Helper()
		select {
		case <-changed:
		case <-time.After(5 * time.Second):
			t.Fatal("no change was noticed")
		}
	}
	sub := filepath.Join(root, "new")
	if err := os.Mkdir(sub, 0o750); err != nil {
		t.Fatal(err)
	}
	wait()
	if err := os.WriteFile(filepath.Join(sub, "a.jpg"), []byte("x"), 0o600); err != nil {
		t.Fatal(err)
	}
	wait()
	cancel()
	if err := <-done; err != nil {
		t.Fatal(err)
	}
}
