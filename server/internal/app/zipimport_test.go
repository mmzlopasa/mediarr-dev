package app

import (
	"archive/zip"
	"bytes"
	"net/http"
	"os"
	"testing"
	"time"

	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

func zipOf(t *testing.T, files map[string][]byte) []byte {
	t.Helper()
	var out bytes.Buffer
	writer := zip.NewWriter(&out)
	for name, body := range files {
		entry, err := writer.Create(name)
		if err != nil {
			t.Fatal(err)
		}
		if _, err := entry.Write(body); err != nil {
			t.Fatal(err)
		}
	}
	if err := writer.Close(); err != nil {
		t.Fatal(err)
	}
	return out.Bytes()
}

func (c *client) newZipImport(t *testing.T, source string) api.UserImport {
	t.Helper()
	resp, body := c.post("/api/imports", map[string]string{"source": source})
	expect(t, resp, body, http.StatusCreated)
	return decode[api.UserImport](t, body)
}

func (c *client) uploadPart(t *testing.T, id, name string, data []byte) *http.Response {
	t.Helper()
	return c.upload(name, data, map[string]string{"importId": id})
}

func (c *client) waitForImport(t *testing.T, id string) api.ImportDetail {
	t.Helper()
	end := time.Now().Add(3 * time.Minute)
	for time.Now().Before(end) {
		resp, body := c.get("/api/imports/" + id)
		expect(t, resp, body, http.StatusOK)
		detail := decode[api.ImportDetail](t, body)
		if detail.Status != api.ImportDetailStatusRunning {
			return detail
		}
		time.Sleep(200 * time.Millisecond)
	}
	t.Fatal("the import never finished")
	return api.ImportDetail{}
}

// A user who is not an administrator brings in a Takeout in two ZIP files, where a photo's sidecar
// is in the other file. The second time, nothing new comes in.
func TestAnyoneImportsTheirTakeoutFromZipFiles(t *testing.T) {
	s := newStack(t)
	s.startWorker(t)
	admin := s.admin()
	ana := s.user(admin, "ana@example.com")
	other := s.user(admin, "other@example.com")

	partOne := zipOf(t, map[string][]byte{
		"Takeout/Google Photos/Summer/sea.jpg":             pictureOf(t, 11),
		"Takeout/Google Photos/Summer/metadata.json":       []byte(`{"title":"Summer","description":"Two weeks by the sea"}`),
		"Takeout/Google Photos/Photos from 2019/plain.jpg": pictureOf(t, 12),
	})
	partTwo := zipOf(t, map[string][]byte{
		// 15 July 2024 at 17:00 UTC, in Split: 19:00 there.
		"Takeout/Google Photos/Summer/sea.jpg.supplemental-metadata.json": []byte(
			`{"description":"Sunset","photoTakenTime":{"timestamp":"1721062800"},"geoData":{"latitude":43.508,"longitude":16.44},"favorited":true}`),
		"Takeout/Google Photos/Summer/gone.jpg":      pictureOf(t, 13),
		"Takeout/Google Photos/Summer/gone.jpg.json": []byte(`{"trashed":true}`),
	})

	entry := ana.newZipImport(t, "takeout")
	id := entry.Id.String()
	if entry.Status != api.UserImportStatusUploading || !entry.FromZip {
		t.Fatalf("%+v", entry)
	}

	// Nothing to start yet, and nobody else can see it or add to it.
	resp, body := ana.post("/api/imports/"+id+"/start", nil)
	expect(t, resp, body, http.StatusConflict)
	resp, body = other.get("/api/imports/" + id)
	expect(t, resp, body, http.StatusNotFound)
	resp, body = other.createUpload(len(partOne), map[string]string{"filename": "takeout-001.zip", "importId": id})
	expect(t, resp, body, http.StatusNotFound)
	resp, body = ana.createUpload(10, map[string]string{"filename": "photo.jpg", "importId": id})
	expect(t, resp, body, http.StatusBadRequest)
	if resp := ana.uploadPart(t, id, "broken.zip", []byte("not a zip at all")); resp.StatusCode != http.StatusUnprocessableEntity {
		t.Fatalf("a file that is not a ZIP was taken: %d", resp.StatusCode)
	}

	for name, data := range map[string][]byte{"takeout-001.zip": partOne, "takeout-002.zip": partTwo} {
		if resp := ana.uploadPart(t, id, name, data); resp.StatusCode != http.StatusNoContent {
			t.Fatalf("%s: %d", name, resp.StatusCode)
		}
	}
	resp, body = ana.get("/api/imports/" + id)
	expect(t, resp, body, http.StatusOK)
	if parts := decode[api.ImportDetail](t, body).Parts; len(parts) != 2 {
		t.Fatalf("parts: %+v", parts)
	}
	resp, body = ana.post("/api/imports/"+id+"/start", nil)
	expect(t, resp, body, http.StatusNoContent)
	done := ana.waitForImport(t, id)
	if done.Status != api.ImportDetailStatusDone || done.Total != 3 || done.Added != 2 || done.Skipped != 1 || done.Failed != 0 {
		t.Fatalf("%+v", done)
	}
	if len(done.Parts) != 0 {
		t.Fatal("the ZIP files were kept after the import")
	}
	if _, err := os.Stat(jobs.ImportPartsDir(s.library, pgUUID(done.Id))); !os.IsNotExist(err) {
		t.Fatal("the ZIP files are still on the disk")
	}
	s.settle(t)
	if got := s.count(t, `SELECT count(*) FROM assets WHERE original_name='sea.jpg' AND caption='Sunset' AND is_favorite
		AND taken_at = to_timestamp(1721062800) AND taken_offset_minutes = 120`); got != 1 {
		t.Fatal("the description, favourite or time zone of sea.jpg was lost")
	}
	if got := s.count(t, `SELECT count(*) FROM albums al JOIN album_assets aa ON aa.album_id = al.id JOIN assets a ON a.id = aa.asset_id
		WHERE al.title='Summer' AND al.description='Two weeks by the sea' AND a.original_name='sea.jpg'`); got != 1 {
		t.Fatal("the album was lost")
	}

	// An administrator sees it, with whose it is.
	resp, body = admin.get("/api/imports/" + id)
	expect(t, resp, body, http.StatusOK)
	if detail := decode[api.ImportDetail](t, body); detail.UserEmail != "ana@example.com" {
		t.Fatalf("%+v", detail)
	}

	again := ana.newZipImport(t, "takeout")
	for name, data := range map[string][]byte{"takeout-001.zip": partOne, "takeout-002.zip": partTwo} {
		if resp := ana.uploadPart(t, again.Id.String(), name, data); resp.StatusCode != http.StatusNoContent {
			t.Fatalf("%s: %d", name, resp.StatusCode)
		}
	}
	resp, body = ana.post("/api/imports/"+again.Id.String()+"/start", nil)
	expect(t, resp, body, http.StatusNoContent)
	if second := ana.waitForImport(t, again.Id.String()); second.Added != 0 || second.Skipped != 3 {
		t.Fatalf("the second import brought in something again: %+v", second)
	}

	// Removing an import leaves what it brought in.
	resp, _ = ana.do(http.MethodDelete, "/api/imports/"+id, nil, nil)
	if resp.StatusCode != http.StatusNoContent {
		t.Fatalf("delete: %d", resp.StatusCode)
	}
	if got := s.count(t, `SELECT count(*) FROM assets WHERE original_name IN ('sea.jpg','plain.jpg') AND deleted_at IS NULL`); got != 2 {
		t.Fatal("removing the import removed photos")
	}
}
