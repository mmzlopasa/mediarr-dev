package app

import (
	"context"
	"encoding/json"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

func TestAKeepCodeIsReadAsGiven(t *testing.T) {
	code := jobs.KeepCode{Address: "http://192.168.1.10:9851", Token: "abc", Name: "Mum and dad"}.Encode()
	// Copied from a message, with a line break in the middle.
	parsed, err := jobs.ParseKeepCode(" " + code[:20] + "\n" + code[20:] + " ")
	if err != nil || parsed.Address != "http://192.168.1.10:9851" || parsed.Token != "abc" || parsed.Name != "Mum and dad" {
		t.Fatalf("%+v %v", parsed, err)
	}
	for _, bad := range []string{"", "hello", "mediarr-keep:%%%", jobs.KeepCode{Address: "ftp://x", Token: "a"}.Encode()} {
		if _, err := jobs.ParseKeepCode(bad); err == nil {
			t.Errorf("%q was read", bad)
		}
	}
	for address, ok := range map[string]bool{
		"https://photos.example.com": true, "http://10.0.0.2:9851/": true, "photos.example.com": false,
		"https://user:pass@example.com": false, "javascript:alert(1)": false,
	} {
		if _, err := jobs.CleanKeepAddress(address); (err == nil) != ok {
			t.Errorf("%s: %v", address, err)
		}
	}
}

func TestWhatAGuestDeletesIsKeptAndComesBack(t *testing.T) {
	library := t.TempDir()
	guest := uuid.New()
	repo := jobs.KeepRepoDir(library, guest)
	file := filepath.Join(repo, "snapshots", strings.Repeat("a", 64))
	if err := os.MkdirAll(filepath.Dir(file), 0o750); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(file, []byte("snapshot"), 0o600); err != nil {
		t.Fatal(err)
	}
	now := time.Now()
	if err := jobs.SoftDeleteKeep(library, guest, "snapshots/"+strings.Repeat("a", 64), now); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(file); !os.IsNotExist(err) {
		t.Fatal("the file is still where restic looks for it")
	}
	if used, deleted := jobs.KeepUsage(library, guest); used != 8 || deleted != 8 {
		t.Fatalf("what is deleted counts against the guest: %d %d", used, deleted)
	}
	// Not cleared before its 90 days.
	if err := jobs.PurgeKeepDeleted(library, now.Add(89*24*time.Hour)); err != nil {
		t.Fatal(err)
	}
	if restored, err := jobs.RestoreKeepDeleted(library, guest); err != nil || restored != 1 {
		t.Fatalf("%d %v", restored, err)
	}
	if _, err := os.Stat(file); err != nil {
		t.Fatal("the file did not come back")
	}
	if err := jobs.SoftDeleteKeep(library, guest, "snapshots/"+strings.Repeat("a", 64), now); err != nil {
		t.Fatal(err)
	}
	if err := jobs.PurgeKeepDeleted(library, now.Add(91*24*time.Hour)); err != nil {
		t.Fatal(err)
	}
	if used, _ := jobs.KeepUsage(library, guest); used != 0 {
		t.Fatal("what was deleted 90 days ago is still kept")
	}
}

// startBackupWorker is a worker that can also dump the database, which a backup needs.
func (s *stack) startBackupWorker(t *testing.T) {
	t.Helper()
	ctx, cancel := context.WithCancel(context.Background())
	worker, err := jobs.NewWorker(s.pool, jobs.Options{Concurrency: 2, LibraryPath: s.library, CachePath: s.cache, ExternalPath: s.external, DatabaseURL: s.dbURL})
	if err != nil {
		t.Fatal(err)
	}
	done := make(chan error, 1)
	go func() { done <- jobs.Run(ctx, worker) }()
	t.Cleanup(func() {
		cancel()
		if err := <-done; err != nil {
			t.Errorf("worker: %v", err)
		}
	})
}

func (c *client) waitForBackups(t *testing.T) []api.BackupRun {
	t.Helper()
	end := time.Now().Add(4 * time.Minute)
	for time.Now().Before(end) {
		resp, body := c.get("/api/admin/backup/runs")
		expect(t, resp, body, http.StatusOK)
		runs := decode[[]api.BackupRun](t, body)
		busy := false
		for _, run := range runs {
			busy = busy || run.Status == api.BackupRunStatusRunning
		}
		if !busy && len(runs) > 0 {
			return runs
		}
		time.Sleep(300 * time.Millisecond)
	}
	t.Fatal("the backup never finished")
	return nil
}

// A server keeps a copy of another's backup; here it is its own guest, which is allowed. The copy
// goes there, comes back in a test, and what is deleted from it is kept.
func TestAnotherMediarrKeepsACopyOfTheBackup(t *testing.T) {
	if _, err := exec.LookPath("restic"); err != nil {
		t.Skip("restic is not installed; run through `make test`")
	}
	s := newStack(t)
	s.startBackupWorker(t)
	admin := s.admin()
	stranger := s.user(admin, "stranger@example.com")
	ctx := context.Background()
	uploadedID(t, admin.upload("kept.jpg", pictureOf(t, 70), nil))
	s.settle(t)

	resp, body := stranger.post("/api/admin/keep/guests", map[string]any{"name": "x", "quotaBytes": 2 << 30, "address": s.url})
	expect(t, resp, body, http.StatusForbidden)
	resp, body = admin.post("/api/admin/keep/guests", map[string]any{"name": "Mum and dad", "quotaBytes": 2 << 30, "address": s.url})
	expect(t, resp, body, http.StatusCreated)
	invite := decode[api.KeepInvite](t, body)

	resp, body = admin.post("/api/admin/backup/destinations", map[string]string{"code": invite.Code})
	expect(t, resp, body, http.StatusCreated)
	destination := decode[api.BackupDestination](t, body)
	// A code works once.
	resp, body = admin.post("/api/admin/backup/destinations", map[string]string{"code": invite.Code})
	expect(t, resp, body, http.StatusBadGateway)

	// Only a copy at another Mediarr, with no backup in the settings: the password is still needed.
	resp, body = admin.post("/api/admin/backup/runs", map[string]string{"kind": "backup"})
	expect(t, resp, body, http.StatusConflict)
	resp, body = admin.send(http.MethodPut, "/api/admin/backup", map[string]any{"repository": "", "hour": 3, "password": "a-long-backup-password"})
	expect(t, resp, body, http.StatusOK)
	resp, body = admin.post("/api/admin/backup/runs", map[string]string{"kind": "backup"})
	expect(t, resp, body, http.StatusAccepted)
	runs := admin.waitForBackups(t)
	if runs[0].Status != api.BackupRunStatusDone || runs[0].DestinationName == nil || *runs[0].DestinationName != "Mum and dad" {
		t.Fatalf("%+v", runs[0])
	}

	resp, body = admin.get("/api/admin/keep/guests")
	expect(t, resp, body, http.StatusOK)
	guest := decode[[]api.KeepGuest](t, body)[0]
	if guest.Status != api.KeepGuestStatusActive || guest.LastBackupAt == nil || guest.UsedBytes == 0 {
		t.Fatalf("%+v", guest)
	}
	resp, body = admin.get("/api/admin/backup/destinations")
	expect(t, resp, body, http.StatusOK)
	if got := decode[[]api.BackupDestination](t, body); len(got) != 1 || got[0].LastSuccessAt == nil {
		t.Fatalf("%+v", got)
	}

	// The host cannot read it: nothing in the copy says what the photo is called.
	err := filepath.WalkDir(jobs.KeepRepoDir(s.library, guest.Id), func(path string, entry os.DirEntry, err error) error {
		if err != nil || entry.IsDir() {
			return err
		}
		raw, err := os.ReadFile(path) //nolint:gosec // A test file.
		if err == nil && strings.Contains(string(raw), "kept.jpg") {
			t.Errorf("%s holds the name of a photo in the clear", path)
		}
		return err
	})
	if err != nil {
		t.Fatal(err)
	}

	resp, body = admin.post("/api/admin/backup/runs", map[string]any{"kind": "restore_test", "destinationId": destination.Id})
	expect(t, resp, body, http.StatusAccepted)
	if test := admin.waitForBackups(t)[0]; test.Kind != api.BackupRunKindRestoreTest || test.Status != api.BackupRunStatusDone {
		t.Fatalf("the test of bringing the copy back: %+v", test)
	}

	// Someone with the guest's credentials deletes the snapshots, as an attacker would.
	var secret string
	if err := s.pool.QueryRow(ctx, "SELECT secret FROM backup_destinations").Scan(&secret); err != nil {
		t.Fatal(err)
	}
	keep := func(method, path, user, password string) (*http.Response, []byte) {
		request, err := http.NewRequestWithContext(ctx, method, s.url+"/api/keep/"+guest.Id.String()+path, nil)
		if err != nil {
			t.Fatal(err)
		}
		request.SetBasicAuth(user, password)
		response, err := http.DefaultClient.Do(request)
		if err != nil {
			t.Fatal(err)
		}
		defer func() { _ = response.Body.Close() }()
		var raw json.RawMessage
		_ = json.NewDecoder(response.Body).Decode(&raw)
		return response, raw
	}
	if resp, _ := keep(http.MethodGet, "/snapshots/", guest.Id.String(), "wrong"); resp.StatusCode != http.StatusUnauthorized {
		t.Fatalf("a wrong secret: %d", resp.StatusCode)
	}
	if resp, _ := keep(http.MethodGet, "/snapshots/", uuid.NewString(), secret); resp.StatusCode != http.StatusUnauthorized {
		t.Fatalf("another guest's name: %d", resp.StatusCode)
	}
	resp, raw := keep(http.MethodGet, "/snapshots/", guest.Id.String(), secret)
	expect(t, resp, raw, http.StatusOK)
	var snapshots []string
	if err := json.Unmarshal(raw, &snapshots); err != nil || len(snapshots) == 0 {
		t.Fatalf("%s %v", raw, err)
	}
	for _, name := range snapshots {
		if resp, _ := keep(http.MethodDelete, "/snapshots/"+name, guest.Id.String(), secret); resp.StatusCode != http.StatusOK {
			t.Fatalf("delete: %d", resp.StatusCode)
		}
	}
	resp, raw = keep(http.MethodGet, "/snapshots/", guest.Id.String(), secret)
	expect(t, resp, raw, http.StatusOK)
	if err := json.Unmarshal(raw, &snapshots); err != nil || len(snapshots) != 0 {
		t.Fatalf("the snapshots were still listed: %s", raw)
	}
	resp, body = admin.post("/api/admin/keep/guests/"+guest.Id.String()+"/restore-deleted", nil)
	expect(t, resp, body, http.StatusOK)
	if restored := decode[api.KeepRestored](t, body); restored.Restored == 0 {
		t.Fatal("nothing came back")
	}
	resp, raw = keep(http.MethodGet, "/snapshots/", guest.Id.String(), secret)
	expect(t, resp, raw, http.StatusOK)
	if err := json.Unmarshal(raw, &snapshots); err != nil || len(snapshots) == 0 {
		t.Fatal("the snapshots did not come back")
	}

	// More than it may keep is refused, and a stopped guest sends nothing.
	if _, err := s.pool.Exec(ctx, "UPDATE keep_guests SET quota_bytes = 1"); err != nil {
		t.Fatal(err)
	}
	resp, body = admin.post("/api/admin/backup/runs", map[string]string{"kind": "backup"})
	expect(t, resp, body, http.StatusAccepted)
	if run := admin.waitForBackups(t)[0]; run.Status != api.BackupRunStatusFailed {
		t.Fatalf("a backup larger than allowed went through: %+v", run)
	}
	resp, body = admin.send(http.MethodPatch, "/api/admin/keep/guests/"+guest.Id.String(), map[string]any{"quotaBytes": 2 << 30, "status": "stopped"})
	expect(t, resp, body, http.StatusOK)
	if resp, _ := keep(http.MethodGet, "/snapshots/", guest.Id.String(), secret); resp.StatusCode != http.StatusForbidden {
		t.Fatalf("a stopped guest: %d", resp.StatusCode)
	}

	// Removing it needs its name again.
	resp, body = admin.send(http.MethodDelete, "/api/admin/keep/guests/"+guest.Id.String()+"?name=wrong", nil)
	expect(t, resp, body, http.StatusBadRequest)
	resp, body = admin.send(http.MethodDelete, "/api/admin/keep/guests/"+guest.Id.String()+"?name=Mum%20and%20dad", nil)
	expect(t, resp, body, http.StatusNoContent)
	if _, err := os.Stat(jobs.KeepGuestDir(s.library, guest.Id)); !os.IsNotExist(err) {
		t.Fatal("the copy is still on the disk")
	}
}
