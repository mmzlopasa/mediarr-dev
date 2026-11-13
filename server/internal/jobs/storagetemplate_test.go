package jobs

import (
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"testing"
)

func TestAFileWithANumberAddedIsAlreadyInPlace(t *testing.T) {
	for path, want := range map[string]bool{
		"/l/u/2024/a.jpg":      true,
		"/l/u/2024/a-1.jpg":    true,
		"/l/u/2024/a-12.jpg":   true,
		"/l/u/2024/a-x.jpg":    false,
		"/l/u/2024/a-.jpg":     false,
		"/l/u/2024/ab.jpg":     false,
		"/l/u/2023/a-1.jpg":    false,
		"/l/u/2024/a-1.jpg.gz": false,
	} {
		if got := placedAs(path, "/l/u/2024/a.jpg"); got != want {
			t.Errorf("%s: %v", path, got)
		}
	}
}

func TestAMoveNeverWritesOverAFileThatIsThere(t *testing.T) {
	dir := t.TempDir()
	to := filepath.Join(dir, "a.jpg")
	if err := os.WriteFile(to, []byte("first"), 0o600); err != nil {
		t.Fatal(err)
	}
	from := filepath.Join(dir, "incoming.jpg")
	if err := os.WriteFile(from, []byte("second"), 0o600); err != nil {
		t.Fatal(err)
	}
	got, err := moveToFreeName(from, to)
	if err != nil {
		t.Fatal(err)
	}
	if got != filepath.Join(dir, "a-1.jpg") {
		t.Fatalf("moved to %s", got)
	}
	for path, want := range map[string]string{to: "first", got: "second"} {
		if body, err := os.ReadFile(path); err != nil || string(body) != want {
			t.Errorf("%s holds %q (%v), want %q", path, body, err, want)
		}
	}
	if _, err := os.Lstat(from); !os.IsNotExist(err) {
		t.Errorf("the old name is still there: %v", err)
	}
}

func TestMovesAtOnceToOneNameKeepEveryOriginal(t *testing.T) {
	dir := t.TempDir()
	to := filepath.Join(dir, "IMG_0001.jpg")
	const count = 20
	var wg sync.WaitGroup
	errs := make(chan error, count)
	for i := range count {
		from := filepath.Join(dir, fmt.Sprintf("in-%d", i))
		if err := os.WriteFile(from, fmt.Appendf(nil, "%d", i), 0o600); err != nil {
			t.Fatal(err)
		}
		wg.Go(func() {
			if _, err := moveToFreeName(from, to); err != nil {
				errs <- err
			}
		})
	}
	wg.Wait()
	close(errs)
	for err := range errs {
		t.Error(err)
	}
	seen := map[string]bool{}
	for n := range count {
		body, err := os.ReadFile(candidateName(to, n))
		if err != nil {
			t.Fatalf("%s: %v", candidateName(to, n), err)
		}
		seen[string(body)] = true
	}
	if len(seen) != count {
		t.Errorf("%d different originals survived, want %d", len(seen), count)
	}
}
