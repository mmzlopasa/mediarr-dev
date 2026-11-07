package app

import (
	"context"
	"errors"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/storage"
	"github.com/mediarr-app/mediarr/server/internal/upgrade"
)

func (s *stack) schema(t *testing.T) int64 {
	t.Helper()
	current, _, err := db.SchemaVersions(context.Background(), s.dbURL)
	if err != nil {
		t.Fatal(err)
	}
	return current
}

func (s *stack) tableExists(t *testing.T, name string) bool {
	t.Helper()
	var exists bool
	if err := s.pool.QueryRow(context.Background(), "SELECT to_regclass($1) IS NOT NULL", name).Scan(&exists); err != nil {
		t.Fatal(err)
	}
	return exists
}

func TestAnUpgradeKeepsASnapshotAndCanBeUndone(t *testing.T) {
	s := newStack(t)
	ctx := context.Background()
	if err := storage.Prepare(s.library, false); err != nil {
		t.Fatal(err)
	}
	owner := s.admin()
	owner.newPhoto(t, "before.jpg", "2024-07-01T10:00:00Z")
	latest := s.schema(t)

	// Nothing to migrate, no snapshot.
	if err := upgrade.Prepare(ctx, s.dbURL, s.library, "v2", false); err != nil {
		t.Fatal(err)
	}
	if all, _ := upgrade.List(s.library); len(all) != 0 {
		t.Fatalf("%+v", all)
	}

	// The database of the version before: one migration behind.
	if err := db.MigrateDown(ctx, s.dbURL); err != nil {
		t.Fatal(err)
	}
	if err := upgrade.Prepare(ctx, s.dbURL, s.library, "v2", false); err != nil {
		t.Fatal(err)
	}
	all, err := upgrade.List(s.library)
	if err != nil || len(all) != 1 {
		t.Fatalf("%v %+v", err, all)
	}
	if snap := all[0]; snap.FromSchema != latest-1 || snap.ToSchema != latest || snap.ToVersion != "v2" || snap.SizeBytes == 0 {
		t.Fatalf("%+v", snap)
	}
	if err := db.Migrate(ctx, s.dbURL); err != nil {
		t.Fatal(err)
	}
	if err := upgrade.Done(ctx, s.dbURL, "v2"); err != nil {
		t.Fatal(err)
	}
	time.Sleep(10 * time.Millisecond)
	owner.newPhoto(t, "after.jpg", "2024-07-02T10:00:00Z")

	// The server is stopped before a rollback; it refuses while the database is in use.
	s.pool.Reset()
	var out strings.Builder
	err = upgrade.Rollback(ctx, s.dbURL, s.library, "", false, strings.NewReader("no\n"), &out)
	if err == nil || !strings.Contains(out.String(), "1 photos and videos were added since then") {
		t.Fatalf("%v %s", err, out.String())
	}
	if err := upgrade.Rollback(ctx, s.dbURL, s.library, "", true, nil, &out); err != nil {
		t.Fatal(err, out.String())
	}
	if got := s.schema(t); got != latest-1 {
		t.Fatalf("schema %d after the rollback", got)
	}
	if n := s.count(t, "SELECT count(*) FROM assets"); n != 1 {
		t.Fatalf("%d assets after the rollback", n)
	}
	if s.tableExists(t, "backup_devices") != (latest-1 >= 37) {
		t.Fatal("the newer table stayed")
	}

	// The version it was brought back from does not migrate again by itself; a newer one does,
	// and so does `mediarr migrate`.
	s.pool.Reset()
	if err := upgrade.Prepare(ctx, s.dbURL, s.library, "v2", false); !errors.Is(err, upgrade.ErrRolledBack) {
		t.Fatalf("%v", err)
	}
	if err := upgrade.Prepare(ctx, s.dbURL, s.library, "v2", true); err != nil {
		t.Fatal(err)
	}

	// No room, no upgrade.
	defer func(previous func(string) (int64, error)) { upgrade.FreeSpace = previous }(upgrade.FreeSpace)
	upgrade.FreeSpace = func(string) (int64, error) { return 1024, nil }
	if err := upgrade.Prepare(ctx, s.dbURL, s.library, "v3", false); !errors.Is(err, upgrade.ErrNoRoom) {
		t.Fatalf("%v", err)
	}
	t.Setenv(upgrade.SkipEnv, "false")
	if err := upgrade.Prepare(ctx, s.dbURL, s.library, "v3", false); err != nil {
		t.Fatalf("with snapshots off: %v", err)
	}
	t.Setenv(upgrade.SkipEnv, "")
	upgrade.FreeSpace = func(string) (int64, error) { return 1 << 40, nil }

	// The newest three stay.
	for range 3 {
		time.Sleep(1100 * time.Millisecond)
		if err := upgrade.Prepare(ctx, s.dbURL, s.library, "v3", false); err != nil {
			t.Fatal(err)
		}
	}
	all, _ = upgrade.List(s.library)
	if len(all) != upgrade.Keep {
		t.Fatalf("%d snapshots", len(all))
	}
	files, _ := filepath.Glob(filepath.Join(upgrade.Dir(s.library), "*"))
	if len(files) != 2*upgrade.Keep {
		t.Fatalf("%v", files)
	}

	// Nothing is written while the library disk is not there.
	if err := os.Remove(filepath.Join(s.library, storage.MarkerName)); err != nil {
		t.Fatal(err)
	}
	if err := upgrade.Prepare(ctx, s.dbURL, s.library, "v4", false); !errors.Is(err, storage.ErrMarkerMissing) {
		t.Fatalf("%v", err)
	}
}

func TestAdministratorsSeeAndDeleteSnapshots(t *testing.T) {
	s := newStack(t)
	ctx := context.Background()
	if err := storage.Prepare(s.library, false); err != nil {
		t.Fatal(err)
	}
	admin := s.admin()
	ana := s.user(admin, "ana@example.com")
	if err := db.MigrateDown(ctx, s.dbURL); err != nil {
		t.Fatal(err)
	}
	if err := upgrade.Prepare(ctx, s.dbURL, s.library, "v2", false); err != nil {
		t.Fatal(err)
	}
	if err := db.Migrate(ctx, s.dbURL); err != nil {
		t.Fatal(err)
	}

	resp, body := admin.get("/api/admin/upgrade-snapshots")
	expect(t, resp, body, http.StatusOK)
	list := decode[[]api.UpgradeSnapshot](t, body)
	if len(list) != 1 || list[0].ToVersion != "v2" {
		t.Fatalf("%s", body)
	}
	resp, body = ana.get("/api/admin/upgrade-snapshots")
	expect(t, resp, body, http.StatusForbidden)
	resp, body = admin.send(http.MethodDelete, "/api/admin/upgrade-snapshots/..%2F..%2Fetc", nil)
	expect(t, resp, body, http.StatusNotFound)
	resp, body = admin.send(http.MethodDelete, "/api/admin/upgrade-snapshots/"+list[0].Name, nil)
	expect(t, resp, body, http.StatusNoContent)
	if all, _ := upgrade.List(s.library); len(all) != 0 {
		t.Fatalf("%+v", all)
	}
}
