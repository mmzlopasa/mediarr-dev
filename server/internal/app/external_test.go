package app

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/mmzlopasa/mediarr-app/server/db"
	"github.com/mmzlopasa/mediarr-app/server/internal/api"
	"github.com/mmzlopasa/mediarr-app/server/internal/jobs"
)

func writeFile(t *testing.T, path, content string) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(path), 0o750); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte(content), 0o600); err != nil {
		t.Fatal(err)
	}
}

// scan runs what the worker runs, without processing the pictures.
func (s *stack) scan(t *testing.T) jobs.ScanResult {
	t.Helper()
	ctx := context.Background()
	q := db.New(s.pool)
	library, err := q.GetExternalLibrary(ctx)
	if err != nil {
		t.Fatal(err)
	}
	result, err := jobs.ScanExternal(ctx, s.pool, q, &library, func(context.Context, pgx.Tx, uuid.UUID) error { return nil })
	if err != nil {
		t.Fatal(err)
	}
	return result
}

func (s *stack) setExternalOwner(t *testing.T, admin *client) {
	t.Helper()
	resp, body := admin.send(http.MethodPut, "/api/admin/external", map[string]string{"ownerId": s.userID("admin@example.com")})
	expect(t, resp, body, http.StatusOK)
}

func (s *stack) count(t *testing.T, query string, args ...any) int {
	t.Helper()
	var n int
	if err := s.pool.QueryRow(context.Background(), query, args...).Scan(&n); err != nil {
		t.Fatal(err)
	}
	return n
}

// Set EXTERNAL_SCAN_FILES=50000 for the full check of the phase's gate.
func TestRescanNeverMakesADuplicate(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	s.setExternalOwner(t, c)

	files := 2000
	if value := os.Getenv("EXTERNAL_SCAN_FILES"); value != "" {
		parsed, err := strconv.Atoi(value)
		if err != nil {
			t.Fatal(err)
		}
		files = parsed
	}
	unique := files - files/10
	for i := range files {
		// One file in ten repeats the content of another, under a different name.
		content := i
		if i >= unique {
			content = i - unique
		}
		writeFile(t, filepath.Join(s.external, fmt.Sprintf("d%03d", i%200), fmt.Sprintf("f%06d.jpg", i)), fmt.Sprintf("picture %d", content))
	}
	writeFile(t, filepath.Join(s.external, "notes.txt"), "not a picture")
	writeFile(t, filepath.Join(s.external, ".hidden.jpg"), "hidden")

	first := s.scan(t)
	if first.Added != unique || first.SameContent != files-unique {
		t.Fatalf("first scan: %+v", first)
	}
	if got := s.count(t, "SELECT count(*) FROM assets"); got != unique {
		t.Fatalf("assets after the first scan: %d", got)
	}
	started := time.Now()
	second := s.scan(t)
	t.Logf("rescan of %d files: %s", files, time.Since(started))
	if second.Added != 0 || second.SameContent != 0 || second.Unchanged != files {
		t.Fatalf("second scan: %+v", second)
	}
	if got := s.count(t, "SELECT count(*) FROM assets"); got != unique {
		t.Fatalf("assets after the rescan: %d", got)
	}
}

func TestExternalChangesAreFollowed(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	s.setExternalOwner(t, c)
	ctx := context.Background()
	keep := filepath.Join(s.external, "2024", "keep.jpg")
	moved := filepath.Join(s.external, "2024", "moved.jpg")
	edited := filepath.Join(s.external, "edited.jpg")
	writeFile(t, keep, "keep")
	writeFile(t, moved, "moved")
	writeFile(t, edited, "edited")
	if got := s.scan(t); got.Added != 3 {
		t.Fatalf("%+v", got)
	}

	// A file that moved keeps its record, and so its albums and tags.
	id := ""
	if err := s.pool.QueryRow(ctx, "SELECT id::text FROM assets WHERE original_path=$1", moved).Scan(&id); err != nil {
		t.Fatal(err)
	}
	target := filepath.Join(s.external, "2025", "new-name.jpg")
	if err := os.MkdirAll(filepath.Dir(target), 0o750); err != nil {
		t.Fatal(err)
	}
	if err := os.Rename(moved, target); err != nil {
		t.Fatal(err)
	}
	if got := s.scan(t); got.Moved != 1 || got.Added != 0 || got.Missing != 0 {
		t.Fatalf("after moving: %+v", got)
	}
	if got := s.count(t, "SELECT count(*) FROM assets WHERE id=$1 AND original_path=$2 AND original_name='new-name.jpg'", id, target); got != 1 {
		t.Fatal("the record did not follow the file")
	}

	// A file edited in place is read again, under the same record.
	writeFile(t, edited, "edited again, and longer")
	if got := s.scan(t); got.Changed != 1 || got.Added != 0 {
		t.Fatalf("after editing: %+v", got)
	}

	// A file that disappeared is flagged, not removed, and it comes back by itself.
	if err := os.Rename(keep, keep+".away"); err != nil {
		t.Fatal(err)
	}
	if got := s.scan(t); got.Missing != 1 {
		t.Fatalf("after removing: %+v", got)
	}
	if got := s.count(t, "SELECT count(*) FROM assets WHERE missing_at IS NOT NULL"); got != 1 {
		t.Fatalf("flagged: %d", got)
	}
	if got := s.count(t, "SELECT count(*) FROM assets"); got != 3 {
		t.Fatalf("records: %d", got)
	}
	var flagged string
	if err := s.pool.QueryRow(ctx, "SELECT id::text FROM assets WHERE original_path=$1", keep).Scan(&flagged); err != nil {
		t.Fatal(err)
	}
	if _, err := s.pool.Exec(ctx, `UPDATE assets SET status='ready', kind='photo', mime_type='image/jpeg' WHERE id=$1`, flagged); err != nil {
		t.Fatal(err)
	}
	resp, body := c.get("/api/assets/" + flagged)
	expect(t, resp, body, http.StatusOK)
	if detail := decode[api.AssetDetail](t, body); detail.IsMissing == nil || !*detail.IsMissing {
		t.Fatalf("detail: %s", body)
	}
	resp, body = c.get("/api/assets/" + flagged + "/original")
	expect(t, resp, body, http.StatusNotFound)

	if err := os.Rename(keep+".away", keep); err != nil {
		t.Fatal(err)
	}
	if got := s.scan(t); got.Missing != 0 || got.Added != 0 || got.Unchanged != 3 {
		t.Fatalf("after coming back: %+v", got)
	}
	if got := s.count(t, "SELECT count(*) FROM assets WHERE missing_at IS NOT NULL"); got != 0 {
		t.Fatalf("still flagged: %d", got)
	}
}

func TestAnUnpluggedDiskRemovesNothing(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	s.setExternalOwner(t, c)
	writeFile(t, filepath.Join(s.external, "a.jpg"), "a")
	s.scan(t)

	ctx := context.Background()
	q := db.New(s.pool)
	library, err := q.GetExternalLibrary(ctx)
	if err != nil {
		t.Fatal(err)
	}
	library.Path.String = filepath.Join(s.external, "not-mounted")
	if _, err := jobs.ScanExternal(ctx, s.pool, q, &library, func(context.Context, pgx.Tx, uuid.UUID) error { return nil }); err == nil {
		t.Fatal("a folder that cannot be read is an error")
	}
	if got := s.count(t, "SELECT count(*) FROM assets WHERE missing_at IS NULL"); got != 1 {
		t.Fatal("nothing can be said about files on a disk that cannot be read")
	}
}

func TestDeletingForGoodLeavesTheFileAlone(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	s.setExternalOwner(t, c)
	path := filepath.Join(s.external, "mine.jpg")
	writeFile(t, path, "mine")
	s.scan(t)
	ctx := context.Background()
	var id string
	if err := s.pool.QueryRow(ctx, "SELECT id::text FROM assets").Scan(&id); err != nil {
		t.Fatal(err)
	}
	if _, err := s.pool.Exec(ctx, `UPDATE assets SET status='ready', kind='photo' WHERE id=$1`, id); err != nil {
		t.Fatal(err)
	}
	c.bulk(t, "delete", id)
	if got := s.scan(t); got.Added != 0 {
		t.Fatalf("a deleted photo stays deleted: %+v", got)
	}
	resp, body := c.post("/api/assets/bulk", map[string]any{"ids": []string{id}, "action": "purge"})
	expect(t, resp, body, http.StatusOK)
	if _, err := os.Stat(path); err != nil {
		t.Fatalf("the original must stay: %v", err)
	}
	if got := s.scan(t); got.Added != 0 {
		t.Fatalf("a file deleted for good does not come back: %+v", got)
	}
}

func TestFolders(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	other := s.user(c, "other@example.com")
	s.setExternalOwner(t, c)
	for _, name := range []string{"top.jpg", "trip/a.jpg", "trip/day1/b.jpg", "home/c.jpg"} {
		writeFile(t, filepath.Join(s.external, name), name)
	}
	s.scan(t)
	if _, err := s.pool.Exec(context.Background(), `UPDATE assets SET status='ready', kind='photo', aspect_ratio=1`); err != nil {
		t.Fatal(err)
	}

	resp, body := c.get("/api/folders")
	expect(t, resp, body, http.StatusOK)
	top := decode[api.Folder](t, body)
	if !top.Available || len(top.Items) != 1 || len(top.Folders) != 2 || top.Folders[1].Name != "trip" || top.Folders[1].Count != 2 {
		t.Fatalf("top: %s", body)
	}
	resp, body = c.get("/api/folders?path=trip")
	expect(t, resp, body, http.StatusOK)
	trip := decode[api.Folder](t, body)
	if len(trip.Items) != 1 || len(trip.Folders) != 1 || trip.Folders[0].Name != "day1" {
		t.Fatalf("trip: %s", body)
	}
	// Climbing out only reaches the top of the library.
	resp, body = c.get("/api/folders?path=../../etc")
	expect(t, resp, body, http.StatusOK)
	if out := decode[api.Folder](t, body); len(out.Items) != 0 || len(out.Folders) != 0 {
		t.Fatalf("outside: %s", body)
	}
	// Someone else sees none of it.
	resp, body = other.get("/api/folders")
	expect(t, resp, body, http.StatusOK)
	if out := decode[api.Folder](t, body); out.Available || len(out.Items) != 0 {
		t.Fatalf("other: %s", body)
	}
}

func TestExternalSettingsAreForAdmins(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	other := s.user(c, "other@example.com")
	resp, body := other.get("/api/admin/external")
	expect(t, resp, body, http.StatusForbidden)
	resp, body = other.post("/api/admin/external/scan", nil)
	expect(t, resp, body, http.StatusForbidden)
	resp, body = c.post("/api/admin/external/scan", nil)
	expect(t, resp, body, http.StatusConflict)

	s.setExternalOwner(t, c)
	writeFile(t, filepath.Join(s.external, "a.jpg"), "a")
	s.scan(t)
	// Once imported, the photos cannot pass to someone else by a change of a setting.
	resp, body = c.send(http.MethodPut, "/api/admin/external", map[string]string{"ownerId": s.userID("other@example.com")})
	expect(t, resp, body, http.StatusConflict)

	resp, body = c.get("/api/admin/external")
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.ExternalLibrary](t, body); !got.Available || got.Assets != 1 {
		t.Fatalf("%s", body)
	}
}
