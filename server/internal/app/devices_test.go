package app

import (
	"context"
	"net/http"
	"strings"
	"testing"

	"github.com/google/uuid"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

func (s *stack) checksumOf(t *testing.T, id string) string {
	t.Helper()
	var sum string
	if err := s.pool.QueryRow(context.Background(), "SELECT encode(checksum, 'hex') FROM assets WHERE id = $1", id).Scan(&sum); err != nil {
		t.Fatal(err)
	}
	return sum
}

func report(name string, checksums []string, replace bool) map[string]any {
	return map[string]any{
		"name": name, "platform": "android", "appVersion": "0.8.0",
		"pending": 2, "working": 0, "verified": len(checksums), "failed": 1,
		"failures":  []map[string]string{{"name": "IMG_9.HEIC", "reason": "The file could not be read."}},
		"checksums": checksums, "replace": replace,
	}
}

func TestADeviceReportIsCountedByTheServer(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	ana := s.user(admin, "ana@example.com")
	ivo := s.user(admin, "ivo@example.com")

	kept := ana.newPhoto(t, "kept.jpg", "2024-07-01T10:00:00Z")
	trashed := ana.newPhoto(t, "trashed.jpg", "2024-07-02T10:00:00Z")
	never := strings.Repeat("ab", 32)
	device := uuid.NewString()
	path := "/api/me/backup-devices/" + device

	resp, body := ana.send(http.MethodPut, path, report("Pixel 8", []string{s.checksumOf(t, kept), s.checksumOf(t, trashed), never}, true))
	expect(t, resp, body, http.StatusOK)
	got := decode[api.BackupDevice](t, body)
	if got.Files != 3 || got.Confirmed != 2 || got.Gone != 1 || got.Name != "Pixel 8" || got.Pending != 2 || got.Quiet {
		t.Fatalf("%+v", got)
	}

	// Trashing on the server takes it out of what is safe; the phone's word does not count.
	ana.bulk(t, "delete", trashed)
	resp, body = ana.get("/api/me/backup-devices")
	expect(t, resp, body, http.StatusOK)
	list := decode[api.BackupDeviceList](t, body)
	if len(list.Devices) != 1 || list.QuietDays != 3 {
		t.Fatalf("%+v", list)
	}
	if d := list.Devices[0]; d.Confirmed != 1 || d.Trashed != 1 || d.Gone != 1 {
		t.Fatalf("%+v", d)
	}
	resp, body = ana.get(path + "/missing")
	expect(t, resp, body, http.StatusOK)
	missing := decode[api.BackupDeviceMissing](t, body)
	if len(missing.Failures) != 1 || missing.Failures[0].Name != "IMG_9.HEIC" || len(missing.Gone) != 2 {
		t.Fatalf("%+v", missing)
	}
	names := map[string]bool{}
	for _, gone := range missing.Gone {
		names[gone.Name] = gone.InTrash
	}
	if !names["trashed.jpg"] {
		t.Fatalf("%+v", missing.Gone)
	}

	// A report without checksums keeps them; replace starts the list anew.
	resp, body = ana.send(http.MethodPut, path, map[string]any{"name": "Pixel 8", "platform": "android", "appVersion": "0.8.0", "pending": 0, "working": 0, "verified": 1, "failed": 0})
	expect(t, resp, body, http.StatusOK)
	if d := decode[api.BackupDevice](t, body); d.Files != 3 {
		t.Fatalf("%+v", d)
	}
	resp, body = ana.get(path + "/missing")
	expect(t, resp, body, http.StatusOK)
	if m := decode[api.BackupDeviceMissing](t, body); len(m.Failures) != 1 {
		t.Fatalf("failures left out should stay: %+v", m)
	}
	resp, body = ana.send(http.MethodPut, path, report("Pixel 8", []string{s.checksumOf(t, kept)}, true))
	expect(t, resp, body, http.StatusOK)
	if d := decode[api.BackupDevice](t, body); d.Files != 1 || d.Confirmed != 1 || d.Gone != 0 {
		t.Fatalf("%+v", d)
	}

	// Bad input is refused.
	resp, body = ana.send(http.MethodPut, path, report("Pixel 8", []string{"not-hex"}, false))
	expect(t, resp, body, http.StatusBadRequest)

	// Someone else cannot see, take over or remove the device.
	resp, body = ivo.send(http.MethodPut, path, report("Mine now", nil, true))
	expect(t, resp, body, http.StatusNotFound)
	resp, body = ivo.get(path + "/missing")
	expect(t, resp, body, http.StatusNotFound)
	resp, body = ivo.send(http.MethodDelete, path, nil)
	expect(t, resp, body, http.StatusNotFound)
	resp, body = ivo.get("/api/me/backup-devices")
	expect(t, resp, body, http.StatusOK)
	if l := decode[api.BackupDeviceList](t, body); len(l.Devices) != 0 {
		t.Fatalf("%+v", l)
	}

	// The administrator sees every device, with whose it is; others may not.
	resp, body = admin.get("/api/admin/backup-devices")
	expect(t, resp, body, http.StatusOK)
	all := decode[api.BackupDeviceList](t, body)
	if len(all.Devices) != 1 || all.Devices[0].OwnerEmail != "ana@example.com" {
		t.Fatalf("%+v", all)
	}
	resp, body = ana.get("/api/admin/backup-devices")
	expect(t, resp, body, http.StatusForbidden)

	// Removing it keeps the photos.
	resp, body = ana.send(http.MethodDelete, path, nil)
	expect(t, resp, body, http.StatusNoContent)
	if n := s.count(t, "SELECT count(*) FROM assets WHERE id = $1", kept); n != 1 {
		t.Fatal("the photo went with the device")
	}
	if n := s.count(t, "SELECT count(*) FROM backup_device_files"); n != 0 {
		t.Fatalf("%d files left", n)
	}
}

func TestAQuietDeviceIsToldOncePerSilence(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	ana := s.user(admin, "ana@example.com")
	device := uuid.NewString()
	path := "/api/me/backup-devices/" + device
	resp, body := ana.send(http.MethodPut, path, report("iPhone", nil, true))
	expect(t, resp, body, http.StatusOK)

	ctx := context.Background()
	q := db.New(s.pool)
	quietFor := func(days int) {
		t.Helper()
		if _, err := s.pool.Exec(ctx, "UPDATE backup_devices SET reported_at = now() - make_interval(days => $1)", days); err != nil {
			t.Fatal(err)
		}
	}
	told := func() int {
		t.Helper()
		if err := jobs.TellQuietDevices(ctx, q); err != nil {
			t.Fatal(err)
		}
		return s.count(t, "SELECT count(*) FROM notifications WHERE kind = 'device_quiet'")
	}

	quietFor(2)
	if n := told(); n != 0 {
		t.Fatalf("told after 2 days: %d", n)
	}
	quietFor(4)
	if n := told(); n != 1 {
		t.Fatalf("told %d times", n)
	}
	resp, body = ana.get("/api/me/backup-devices")
	expect(t, resp, body, http.StatusOK)
	if d := decode[api.BackupDeviceList](t, body).Devices[0]; !d.Quiet {
		t.Fatalf("%+v", d)
	}
	if n := told(); n != 1 {
		t.Fatalf("told again in the same silence: %d", n)
	}

	// Reporting again ends the silence; the next one is told anew.
	resp, body = ana.send(http.MethodPut, path, report("iPhone", nil, false))
	expect(t, resp, body, http.StatusOK)
	if d := decode[api.BackupDevice](t, body); d.Quiet {
		t.Fatalf("%+v", d)
	}
	quietFor(5)
	if n := told(); n != 2 {
		t.Fatalf("told %d times", n)
	}

	// A threshold of 0 never warns, and the threshold is checked.
	resp, body = ana.send(http.MethodPut, "/api/me/backup-devices/quiet-days", map[string]int{"days": 61})
	expect(t, resp, body, http.StatusBadRequest)
	resp, body = ana.send(http.MethodPut, "/api/me/backup-devices/quiet-days", map[string]int{"days": 0})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = ana.send(http.MethodPut, path, report("iPhone", nil, false))
	expect(t, resp, body, http.StatusOK)
	quietFor(30)
	if n := told(); n != 2 {
		t.Fatalf("told with warnings off: %d", n)
	}
}

func TestTheBackupKeyMayReportItsDeviceAndNothingMore(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	ana := s.user(admin, "ana@example.com")
	key := ana.newKey(t, "upload")
	headers := map[string]string{"X-Api-Key": key}
	keyed := s.client()
	path := "/api/me/backup-devices/" + uuid.NewString()

	resp, body := keyed.sendWith(http.MethodPut, path, headers, report("Pixel 8", nil, true))
	expect(t, resp, body, http.StatusOK)
	for _, other := range []struct{ method, path string }{
		{http.MethodGet, "/api/me/backup-devices"},
		{http.MethodPut, "/api/me/backup-devices/quiet-days"},
		{http.MethodDelete, path},
		{http.MethodGet, path + "/missing"},
	} {
		resp, body = keyed.sendWith(other.method, other.path, headers, map[string]int{"days": 0})
		if resp.StatusCode != http.StatusForbidden {
			t.Errorf("%s %s with the backup key: %d %s", other.method, other.path, resp.StatusCode, body)
		}
	}
}
