package app

import (
	"context"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/mmzlopasa/mediarr-app/server/internal/api"
	"github.com/mmzlopasa/mediarr-app/server/internal/jobs"
)

func TestUploadsCannotBePutTogether(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	for _, concat := range []string{"final;/api/uploads/../../../etc/passwd", "partial"} {
		resp, body := c.do(http.MethodPost, "/api/uploads", map[string]string{
			"Tus-Resumable": "1.0.0", "Upload-Concat": concat, "Upload-Length": "1",
		}, nil)
		if resp.StatusCode < http.StatusBadRequest {
			t.Errorf("%q was accepted: %d %s", concat, resp.StatusCode, body)
		}
	}
}

func TestOnlyTheOwnerChangesWhatASmartAlbumShows(t *testing.T) {
	s := newStack(t)
	owner := s.admin()
	editor := s.user(owner, "editor@example.com")
	album := owner.newAlbum(map[string]any{"title": "Summer", "rules": map[string]string{"from": "2024-01-01", "to": "2024-12-31"}})
	resp, body := owner.send(http.MethodPut, "/api/albums/"+album+"/members/"+s.userID("editor@example.com"), map[string]any{"role": "editor"})
	if resp.StatusCode >= http.StatusBadRequest {
		t.Fatalf("%s", body)
	}
	resp, body = editor.send(http.MethodPatch, "/api/albums/"+album, map[string]any{"rules": map[string]string{"from": "1900-01-01"}})
	expect(t, resp, body, http.StatusForbidden)
	resp, body = editor.send(http.MethodPatch, "/api/albums/"+album, map[string]any{"title": "Still allowed"})
	expect(t, resp, body, http.StatusOK)
	resp, body = owner.send(http.MethodPatch, "/api/albums/"+album, map[string]any{"rules": map[string]string{"from": "2023-01-01"}})
	expect(t, resp, body, http.StatusOK)
}

func TestALockedVaultStaysLocked(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	photo := c.newPhoto(t, "a.jpg", "2024-01-01T10:00:00Z")
	if _, err := s.pool.Exec(context.Background(), "UPDATE assets SET vault_at=now() WHERE id=$1", photo); err != nil {
		t.Fatal(err)
	}
	resp, body := c.get("/api/assets/" + photo + "/thumbnail?size=source")
	expect(t, resp, body, http.StatusNotFound)
	resp, body = c.send(http.MethodPut, "/api/assets/"+photo+"/edits", map[string]any{"rotate": 90})
	expect(t, resp, body, http.StatusNotFound)
}

func TestChangingThePasswordEndsAllOtherAccess(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	thief := s.client()
	resp, body := thief.post("/api/auth/login", api.LoginRequest{Email: "admin@example.com", Password: testPassword})
	expect(t, resp, body, http.StatusOK)
	resp, body = thief.post("/api/me/device-keys", api.CreateDeviceKeyRequest{Name: "stolen"})
	expect(t, resp, body, http.StatusCreated)
	key := decode[api.DeviceKey](t, body).Key

	const next = "a-completely-new-password"
	resp, body = c.post("/api/me/password", map[string]string{"currentPassword": testPassword, "newPassword": next})
	if resp.StatusCode >= http.StatusBadRequest {
		t.Fatalf("%s", body)
	}
	resp, body = thief.get("/api/timeline/buckets")
	expect(t, resp, body, http.StatusUnauthorized)
	resp, body = s.client().do(http.MethodGet, "/api/timeline/buckets", map[string]string{apiKeyHeader: key}, nil)
	expect(t, resp, body, http.StatusUnauthorized)
	resp, body = c.get("/api/timeline/buckets")
	expect(t, resp, body, http.StatusOK)
}

func TestAKeyCannotChangeThePassword(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	resp, body := c.post("/api/me/device-keys", api.CreateDeviceKeyRequest{Name: "phone"})
	expect(t, resp, body, http.StatusCreated)
	key := decode[api.DeviceKey](t, body).Key
	byKey := s.client()
	resp, body = byKey.do(http.MethodPost, "/api/me/password", map[string]string{
		apiKeyHeader: key, "Content-Type": "application/json",
	}, strings.NewReader(`{"currentPassword":"`+testPassword+`","newPassword":"a-completely-new-password"}`))
	expect(t, resp, body, http.StatusForbidden)
	resp, body = c.get("/api/timeline/buckets")
	expect(t, resp, body, http.StatusOK)
}

func TestAnotherSiteCannotUseTheCookie(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	resp, body := c.do(http.MethodPost, "/api/trash/empty", map[string]string{"Origin": "http://evil.example"}, nil)
	expect(t, resp, body, http.StatusForbidden)
	host := strings.TrimPrefix(s.url, "http://")
	resp, body = c.do(http.MethodPost, "/api/trash/empty", map[string]string{"Origin": "http://" + host}, nil)
	if resp.StatusCode == http.StatusForbidden {
		t.Fatalf("its own site was refused: %s", body)
	}
	// An app sends no Origin.
	resp, body = c.do(http.MethodPost, "/api/trash/empty", nil, nil)
	if resp.StatusCode == http.StatusForbidden {
		t.Fatalf("an app was refused: %s", body)
	}
}

func TestOnlyProxiesWeTrustNameTheVisitor(t *testing.T) {
	for _, row := range []struct {
		header string
		hops   int
		want   string
	}{
		{"1.1.1.1, 2.2.2.2", 1, "1.1.1.1"},
		// What the visitor sent is further left, and is ignored.
		{"6.6.6.6, 1.1.1.1, 2.2.2.2", 1, "1.1.1.1"},
		{"1.1.1.1, 2.2.2.2, 3.3.3.3", 2, "1.1.1.1"},
		{"1.1.1.1", 1, ""},
		{"1.1.1.1, 2.2.2.2", 0, ""},
		{"", 1, ""},
	} {
		if got := forwardedClient(row.header, row.hops); got != row.want {
			t.Errorf("%q with %d: %q", row.header, row.hops, got)
		}
	}
}

func TestALinkDayHasABudget(t *testing.T) {
	budget := newByteBudget()
	now := time.Date(2026, 1, 1, 12, 0, 0, 0, time.UTC)
	if !budget.spend("a", guestBytesPerDay, now) {
		t.Fatal("the budget itself was refused")
	}
	if budget.spend("a", 1, now) {
		t.Fatal("over the budget")
	}
	if !budget.spend("b", 1, now) {
		t.Fatal("another link was affected")
	}
	if !budget.spend("a", 1, now.Add(24*time.Hour)) {
		t.Fatal("the next day should start again")
	}
}

func TestStrippedCopyHasNoLocation(t *testing.T) {
	if _, err := exec.LookPath("exiftool"); err != nil {
		t.Skip("media tools are not installed; run through `make test`")
	}
	dir := t.TempDir()
	original := filepath.Join(dir, "a.jpg")
	if err := os.WriteFile(original, landscapeJPEG(t), 0o600); err != nil {
		t.Fatal(err)
	}
	if out, err := exec.Command("exiftool", "-q", "-overwrite_original", "-GPSLatitude=45.8", "-GPSLongitude=15.9", "-Make=Canon", original).CombinedOutput(); err != nil {
		t.Fatalf("%v: %s", err, out)
	}
	before, err := os.ReadFile(original)
	if err != nil {
		t.Fatal(err)
	}
	dest := filepath.Join(dir, "links", "b.jpg")
	if err := jobs.StripLocation(context.Background(), original, dest); err != nil {
		t.Fatal(err)
	}
	out, err := exec.Command("exiftool", "-s", "-GPSLatitude", "-Make", dest).CombinedOutput()
	if err != nil {
		t.Fatalf("%v: %s", err, out)
	}
	if strings.Contains(string(out), "GPS") || !strings.Contains(string(out), "Canon") {
		t.Fatalf("after stripping: %s", out)
	}
	after, err := os.ReadFile(original)
	if err != nil {
		t.Fatal(err)
	}
	if string(before) != string(after) {
		t.Fatal("the original changed")
	}
}

func TestAGuestsDownloadHasNoLocationUnlessShared(t *testing.T) {
	if _, err := exec.LookPath("exiftool"); err != nil {
		t.Skip("media tools are not installed; run through `make test`")
	}
	s := newStack(t)
	c := s.admin()
	path := filepath.Join(t.TempDir(), "a.jpg")
	if err := os.WriteFile(path, landscapeJPEG(t), 0o600); err != nil {
		t.Fatal(err)
	}
	if out, err := exec.Command("exiftool", "-q", "-overwrite_original", "-GPSLatitude=45.8", "-GPSLongitude=15.9", path).CombinedOutput(); err != nil {
		t.Fatalf("%v: %s", err, out)
	}
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	id := uploadedID(t, c.upload("a.jpg", data, nil))
	s.markReady(t, id, "2024-01-01T10:00:00Z", nil)
	album := c.newAlbum(map[string]any{"title": "Trip"})
	resp, body := c.post("/api/albums/"+album+"/assets", api.AssetIds{Ids: uuids(t, id)})
	expect(t, resp, body, http.StatusOK)

	hasGPS := func(token string) bool {
		t.Helper()
		resp, body := s.client().get("/api/public/" + token + "/assets/" + id + "/original?download=true")
		expect(t, resp, body, http.StatusOK)
		file := filepath.Join(t.TempDir(), "got.jpg")
		if err := os.WriteFile(file, body, 0o600); err != nil {
			t.Fatal(err)
		}
		out, err := exec.Command("exiftool", "-s", "-GPSLatitude", file).CombinedOutput()
		if err != nil {
			t.Fatalf("%v: %s", err, out)
		}
		return strings.Contains(string(out), "GPS")
	}
	if hasGPS(*c.newLink(album, map[string]any{}).Token) {
		t.Error("a link that hides the location gave it away")
	}
	if !hasGPS(*c.newLink(album, map[string]any{"showLocation": true}).Token) {
		t.Error("a link that shares the location lost it")
	}
}
