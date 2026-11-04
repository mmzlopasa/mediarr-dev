package app

import (
	"bytes"
	"context"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"

	"github.com/mmzlopasa/mediarr-app/server/db"
	"github.com/mmzlopasa/mediarr-app/server/internal/api"
	"github.com/mmzlopasa/mediarr-app/server/internal/jobs"
)

func TestBackupDueOnceADayAtItsHour(t *testing.T) {
	at := func(hour int) time.Time { return time.Date(2026, 6, 2, hour, 10, 0, 0, time.UTC) }
	if !jobs.BackupDue(at(3), at(3).Add(-24*time.Hour), 3) {
		t.Error("due at its hour")
	}
	if jobs.BackupDue(at(4), at(3).Add(-24*time.Hour), 3) {
		t.Error("not at another hour")
	}
	if jobs.BackupDue(at(3), at(3).Add(-time.Hour), 3) {
		t.Error("not twice")
	}
}

func TestOnlyAFewKindsOfBackupAreAllowed(t *testing.T) {
	for repository, ok := range map[string]bool{
		"/backup":             true,
		"/backup/mediarr":     true,
		"/backup/../etc":      false,
		"/etc":                false,
		"s3:s3.example.com/a": true,
		"b2:bucket":           true,
		"rest:http://host/":   true,
		"sftp:user@host:/x":   false,
		"rclone:x":            false,
		"relative/path":       false,
	} {
		if got := jobs.ValidRepository(repository, "/backup") == nil; got != ok {
			t.Errorf("%s: %v", repository, got)
		}
	}
}

func TestFeaturesAreOffUntilTurnedOn(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	user := s.user(admin, "user@example.com")
	resp, body := user.get("/api/features")
	expect(t, resp, body, http.StatusOK)
	for name, on := range decode[map[string]bool](t, body) {
		if on {
			t.Errorf("%s is on by itself", name)
		}
	}
	resp, body = user.send(http.MethodPut, "/api/admin/features/kiosk", map[string]bool{"enabled": true})
	expect(t, resp, body, http.StatusForbidden)
	resp, body = admin.send(http.MethodPut, "/api/admin/features/nonsense", map[string]bool{"enabled": true})
	expect(t, resp, body, http.StatusNotFound)
	resp, body = admin.send(http.MethodPut, "/api/admin/features/kiosk", map[string]bool{"enabled": true})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = user.get("/api/features")
	expect(t, resp, body, http.StatusOK)
	if !decode[map[string]bool](t, body)["kiosk"] {
		t.Fatalf("%s", body)
	}
}

func TestBackupSecretsNeverComeBack(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	resp, body := c.post("/api/admin/backup/runs", map[string]string{"kind": "backup"})
	expect(t, resp, body, http.StatusConflict)
	resp, body = c.send(http.MethodPut, "/api/admin/backup", map[string]any{"repository": "/etc", "hour": 3})
	expect(t, resp, body, http.StatusBadRequest)
	resp, body = c.send(http.MethodPut, "/api/admin/backup", map[string]any{"repository": "s3:x/y", "hour": 3, "password": "short"})
	expect(t, resp, body, http.StatusBadRequest)
	resp, body = c.send(http.MethodPut, "/api/admin/backup", map[string]any{
		"repository": "s3:x/y", "hour": 4, "password": "a-long-backup-password", "s3Key": "key-id", "s3Secret": "key-secret",
	})
	expect(t, resp, body, http.StatusOK)
	for _, secret := range []string{"a-long-backup-password", "key-secret"} {
		if bytes.Contains(body, []byte(secret)) {
			t.Fatalf("%s came back: %s", secret, body)
		}
	}
	got := decode[api.BackupSettings](t, body)
	if !got.HasPassword || !got.HasS3Key || got.Hour != 4 {
		t.Fatalf("%s", body)
	}
	// Removing the destination forgets the secrets too.
	resp, body = c.send(http.MethodPut, "/api/admin/backup", map[string]any{"repository": "", "hour": 3})
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.BackupSettings](t, body); got.HasPassword || got.HasS3Key {
		t.Fatalf("%s", body)
	}
}

// The gate of this part: a backup comes back on an empty installation, with every file intact.
func TestABackupComesBackOnAnEmptyInstallation(t *testing.T) {
	if _, err := exec.LookPath("restic"); err != nil {
		t.Skip("restic is not installed; run through `make test`")
	}
	s := newStack(t)
	s.startWorker(t)
	c := s.admin()
	ctx := context.Background()
	data := map[string][]byte{"a.jpg": pictureOf(t, 80), "b.jpg": pictureOf(t, 90)}
	for name, content := range data {
		uploadedID(t, c.upload(name, content, nil))
	}
	s.settle(t)
	settings := &jobs.BackupSettings{Repository: filepath.Join(t.TempDir(), "repo"), Password: "a-long-backup-password"}
	files, err := jobs.RunBackup(ctx, settings, s.dbURL, s.library, s.cache)
	if err != nil {
		t.Fatal(err)
	}
	if files < 2 {
		t.Fatalf("files: %d", files)
	}

	// The test with one click: it brings it back beside the live data and compares every checksum.
	checked, err := jobs.TestRestore(ctx, settings, s.dbURL, s.cache)
	if err != nil {
		t.Fatal(err)
	}
	if checked != 2 {
		t.Fatalf("checked: %d", checked)
	}

	// A damaged backup is noticed: here, a file missing from a newer one.
	var path string
	if err := s.pool.QueryRow(ctx, "SELECT original_path FROM assets LIMIT 1").Scan(&path); err != nil {
		t.Fatal(err)
	}
	saved, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if err := os.Remove(path); err != nil {
		t.Fatal(err)
	}
	if _, err := jobs.RunBackup(ctx, settings, s.dbURL, s.library, s.cache); err != nil {
		t.Fatal(err)
	}
	if _, err := jobs.TestRestore(ctx, settings, s.dbURL, s.cache); err == nil {
		t.Fatal("a backup without a file passed the test")
	}
	if err := os.WriteFile(path, saved, 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := jobs.RunBackup(ctx, settings, s.dbURL, s.library, s.cache); err != nil {
		t.Fatal(err)
	}

	// Everything is lost: the files, and every table in the database.
	var originals []string
	rows, err := s.pool.Query(ctx, "SELECT original_path FROM assets")
	if err != nil {
		t.Fatal(err)
	}
	for rows.Next() {
		var one string
		if err := rows.Scan(&one); err != nil {
			t.Fatal(err)
		}
		originals = append(originals, one)
	}
	rows.Close()
	for _, one := range originals {
		if err := os.Remove(one); err != nil {
			t.Fatal(err)
		}
	}
	empty, err := pgx.Connect(ctx, s.dbURL)
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = empty.Close(ctx) }()
	if _, err := empty.Exec(ctx, "DELETE FROM assets"); err != nil {
		t.Fatal(err)
	}

	if err := jobs.RestoreBackup(ctx, settings, s.dbURL, s.cache); err != nil {
		t.Fatal(err)
	}
	restored, err := db.New(s.pool).ListUploadOriginals(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if len(restored) != 2 {
		t.Fatalf("restored %d", len(restored))
	}
	for i := range restored {
		content, err := os.ReadFile(restored[i].OriginalPath)
		if err != nil {
			t.Fatal(err)
		}
		if string(content) != string(data[originalNameOf(restored[i].OriginalPath)]) {
			t.Errorf("%s differs", restored[i].OriginalPath)
		}
	}
}

// Runs against S3 when given one: BACKUP_TEST_S3 ("s3:http://host:9000/bucket"), with BACKUP_TEST_KEY and
// BACKUP_TEST_SECRET. Without it the test above still covers everything but the transport.
func TestABackupWorksOverS3(t *testing.T) {
	repository := os.Getenv("BACKUP_TEST_S3")
	if repository == "" {
		t.Skip("no S3 to back up to")
	}
	s := newStack(t)
	s.startWorker(t)
	c := s.admin()
	uploadedID(t, c.upload("a.jpg", pictureOf(t, 100), nil))
	s.settle(t)
	ctx := context.Background()
	settings := &jobs.BackupSettings{
		Repository: repository, Password: "a-long-backup-password",
		S3Key: os.Getenv("BACKUP_TEST_KEY"), S3Secret: os.Getenv("BACKUP_TEST_SECRET"),
	}
	if _, err := jobs.RunBackup(ctx, settings, s.dbURL, s.library, s.cache); err != nil {
		t.Fatal(err)
	}
	checked, err := jobs.TestRestore(ctx, settings, s.dbURL, s.cache)
	if err != nil {
		t.Fatal(err)
	}
	if checked != 1 {
		t.Fatalf("checked: %d", checked)
	}
}

// originalNameOf takes the name back out of a stored path, which is "<checksum>-<name>".
func originalNameOf(path string) string {
	base := filepath.Base(path)
	for i := range len(base) {
		if base[i] == '-' {
			return base[i+1:]
		}
	}
	return base
}

func TestDocumentsAndFiltersWaitForTheirSwitch(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	other := s.user(c, "other@example.com")
	ctx := context.Background()
	letter := c.newPhoto(t, "letter.jpg", "2024-01-01T10:00:00Z")
	sign := c.newPhoto(t, "sign.jpg", "2024-01-02T10:00:00Z")
	hidden := c.newPhoto(t, "hidden.jpg", "2024-01-03T10:00:00Z")
	foreign := other.newPhoto(t, "foreign.jpg", "2024-01-04T10:00:00Z")
	long := "Poštovani, ovim putem potvrđujemo vašu narudžbu broj 42 od prošlog tjedna."
	for id, text := range map[string]string{letter: long, sign: "STOP", hidden: long, foreign: long} {
		if _, err := s.pool.Exec(ctx, `INSERT INTO asset_search (asset_id, embedding, ocr_text) VALUES ($1, array_fill(0.1::real, ARRAY[768])::vector, $2)`, id, text); err != nil {
			t.Fatal(err)
		}
	}
	if _, err := s.pool.Exec(ctx, "UPDATE assets SET vault_at=now() WHERE id=$1", hidden); err != nil {
		t.Fatal(err)
	}
	resp, body := c.get("/api/documents")
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.Documents](t, body); got.Enabled || len(got.Items) != 0 {
		t.Fatalf("while off: %s", body)
	}
	resp, body = c.send(http.MethodPut, "/api/admin/features/documents", map[string]bool{"enabled": true})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = c.get("/api/documents")
	expect(t, resp, body, http.StatusOK)
	got := decode[api.Documents](t, body)
	if !got.Enabled || len(got.Items) != 1 || got.Items[0].Id.String() != letter {
		t.Fatalf("%s", body)
	}

	resp, body = c.send(http.MethodPut, "/api/assets/"+letter+"/edits", map[string]any{"filter": "mono"})
	expect(t, resp, body, http.StatusConflict)
	resp, body = c.send(http.MethodPut, "/api/admin/features/filters", map[string]bool{"enabled": true})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = c.send(http.MethodPut, "/api/assets/"+letter+"/edits", map[string]any{"filter": "nonsense"})
	if resp.StatusCode == http.StatusNoContent {
		t.Fatalf("%s", body)
	}
	resp, body = c.send(http.MethodPut, "/api/assets/"+letter+"/edits", map[string]any{"filter": "mono"})
	expect(t, resp, body, http.StatusNoContent)
}
