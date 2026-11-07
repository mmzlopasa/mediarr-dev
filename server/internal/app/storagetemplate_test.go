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

	"github.com/mediarr-app/mediarr/server/internal/api"
)

func (s *stack) originalPath(t *testing.T, id string) string {
	t.Helper()
	var path string
	if err := s.pool.QueryRow(context.Background(), "SELECT original_path FROM assets WHERE id = $1", id).Scan(&path); err != nil {
		t.Fatal(err)
	}
	return path
}

func (c *client) waitForStorageReport(t *testing.T, dryRun bool) api.StorageReport {
	t.Helper()
	end := time.Now().Add(60 * time.Second)
	for time.Now().Before(end) {
		resp, body := c.get("/api/admin/storage-template")
		expect(t, resp, body, http.StatusOK)
		got := decode[api.StorageTemplate](t, body)
		if r := got.Report; r != nil && !r.Running && r.FinishedAt != nil && r.DryRun == dryRun {
			return *r
		}
		time.Sleep(200 * time.Millisecond)
	}
	t.Fatal("the storage report did not come")
	return api.StorageReport{}
}

func TestOriginalsGoWhereTheStorageTemplateSays(t *testing.T) {
	if _, err := exec.LookPath("vips"); err != nil {
		t.Skip("media tools are not installed; run through `make test`")
	}
	s := newStack(t)
	admin := s.admin()
	ana := s.user(admin, "ana@example.com")
	s.startWorker(t)
	year := time.Now().UTC().Format("2006")

	// Before any template, the layout is as it always was.
	before := uploadedID(t, ana.upload("before.jpg", pictureOf(t, 10), nil))
	waitForAsset(t, ana, "before.jpg")
	old := s.originalPath(t, before)
	if !strings.Contains(old, string(filepath.Separator)+year+string(filepath.Separator)) {
		t.Fatalf("%s", old)
	}

	// Bad templates are refused, and only administrators choose.
	for _, bad := range []string{"{{y}}", "../{{filename}}", "{{nope}}/{{filename}}"} {
		resp, body := admin.send(http.MethodPut, "/api/admin/storage-template", map[string]string{"template": bad})
		expect(t, resp, body, http.StatusBadRequest)
	}
	resp, body := ana.send(http.MethodPut, "/api/admin/storage-template", map[string]string{"template": "{{filename}}.{{ext}}"})
	expect(t, resp, body, http.StatusForbidden)
	template := "{{y}}/Camera {{camera}}/{{filename}}.{{ext}}"
	resp, body = admin.send(http.MethodPut, "/api/admin/storage-template", map[string]string{"template": template})
	expect(t, resp, body, http.StatusOK)

	// The preview shows real files, and moves nothing.
	resp, body = admin.post("/api/admin/storage-template/preview", map[string]string{"template": template})
	expect(t, resp, body, http.StatusOK)
	previews := decode[[]api.StoragePreview](t, body)
	if len(previews) != 1 || previews[0].Path != year+"/Camera Unknown camera/before.jpg" {
		t.Fatalf("%s", body)
	}
	if s.originalPath(t, before) != old {
		t.Fatal("the preview moved a file")
	}

	// A new original goes where the template says; two of the same name both stay.
	first := uploadedID(t, ana.upload("same.jpg", pictureOf(t, 20), nil))
	waitForAsset(t, ana, "same.jpg")
	second := uploadedID(t, ana.upload("same.jpg", pictureOf(t, 30), nil))
	userRoot := filepath.Join(s.library, s.userID("ana@example.com"))
	wantFirst := filepath.Join(userRoot, year, "Camera Unknown camera", "same.jpg")
	wantSecond := filepath.Join(userRoot, year, "Camera Unknown camera", "same-1.jpg")
	end := time.Now().Add(60 * time.Second)
	for time.Now().Before(end) && (s.originalPath(t, first) != wantFirst || s.originalPath(t, second) != wantSecond) {
		time.Sleep(200 * time.Millisecond)
	}
	for id, want := range map[string]string{first: wantFirst, second: wantSecond} {
		if got := s.originalPath(t, id); got != want {
			t.Fatalf("%s, want %s", got, want)
		}
		if _, err := os.Stat(want); err != nil {
			t.Fatal(err)
		}
	}

	// What was here before moves only when asked, after a dry run that moves nothing.
	if s.originalPath(t, before) != old {
		t.Fatal("an old original moved by itself")
	}
	resp, body = admin.post("/api/admin/storage-template/apply", map[string]bool{"dryRun": true})
	expect(t, resp, body, http.StatusAccepted)
	report := admin.waitForStorageReport(t, true)
	if report.Moved != 1 || report.Failed != 0 || len(report.Samples) != 1 || !strings.HasSuffix(report.Samples[0].To, "Camera Unknown camera/before.jpg") {
		t.Fatalf("%+v", report)
	}
	if s.originalPath(t, before) != old {
		t.Fatal("the dry run moved a file")
	}
	resp, body = admin.post("/api/admin/storage-template/apply", map[string]bool{"dryRun": false})
	expect(t, resp, body, http.StatusAccepted)
	report = admin.waitForStorageReport(t, false)
	moved := filepath.Join(userRoot, year, "Camera Unknown camera", "before.jpg")
	if report.Moved != 1 || s.originalPath(t, before) != moved {
		t.Fatalf("%+v %s", report, s.originalPath(t, before))
	}
	if _, err := os.Stat(old); !os.IsNotExist(err) {
		t.Fatalf("the old file is still there: %v", err)
	}
	// The emptied folders are tidied away, and the photo still opens.
	if _, err := os.Stat(filepath.Dir(old)); !os.IsNotExist(err) {
		t.Errorf("the old folder stayed: %v", err)
	}
	resp, body = ana.get("/api/assets/" + before + "/original")
	expect(t, resp, body, http.StatusOK)

	// Running again finds nothing to move.
	resp, body = admin.post("/api/admin/storage-template/apply", map[string]bool{"dryRun": true})
	expect(t, resp, body, http.StatusAccepted)
	if report = admin.waitForStorageReport(t, true); report.Moved != 0 || report.Checked != 3 {
		t.Fatalf("%+v", report)
	}
}
