package app

import (
	"archive/zip"
	"bytes"
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
	"github.com/jackc/pgx/v5/pgtype"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

// markReady stands in for the worker, with a thumbnail file on disk.
func (s *stack) markReady(t *testing.T, id, takenAt string, offset *int) string {
	t.Helper()
	ctx := context.Background()
	thumb := filepath.Join(t.TempDir(), id+".webp")
	if err := os.WriteFile(thumb, []byte("thumbnail "+id), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := s.pool.Exec(ctx, `UPDATE assets SET status='ready', kind='photo', mime_type='image/jpeg', taken_at=$2::timestamptz,
		taken_offset_minutes=$3, aspect_ratio=1.5, blurhash='LEHV6nWB2yk8' WHERE id=$1`, id, takenAt, offset); err != nil {
		t.Fatal(err)
	}
	if _, err := s.pool.Exec(ctx, `INSERT INTO asset_files (asset_id, kind, path, size_bytes) VALUES ($1, 'thumb_small', $2, 10), ($1, 'thumb_large', $2, 10)`, id, thumb); err != nil {
		t.Fatal(err)
	}
	return thumb
}

func textValue(value string) pgtype.Text { return pgtype.Text{String: value, Valid: true} }

func uploadedID(t *testing.T, resp *http.Response) string {
	t.Helper()
	if resp.StatusCode != http.StatusNoContent {
		t.Fatalf("upload: %d", resp.StatusCode)
	}
	return resp.Header.Get("X-Asset-Id")
}

func (c *client) readBucket(month string) api.TimelineBucket {
	c.s.t.Helper()
	resp, body := c.get("/api/timeline/buckets/" + month)
	expect(c.s.t, resp, body, http.StatusOK)
	var bucket api.TimelineBucket
	if err := json.Unmarshal(body, &bucket); err != nil {
		c.s.t.Fatal(err)
	}
	return bucket
}

func TestTimelineGroupsByLocalTime(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	plus2 := 120
	// 23:30 UTC on 31 July is already 1 August where the photo was taken.
	august := uploadedID(t, c.upload("a.jpg", randomBytes(t, 100), nil))
	s.markReady(t, august, "2024-07-31T23:30:00Z", &plus2)
	july := uploadedID(t, c.upload("b.jpg", randomBytes(t, 100), nil))
	s.markReady(t, july, "2024-07-15T12:00:00Z", nil)
	processing := uploadedID(t, c.upload("c.jpg", randomBytes(t, 100), nil))

	resp, body := c.get("/api/timeline/buckets")
	expect(t, resp, body, http.StatusOK)
	var buckets api.TimelineBuckets
	if err := json.Unmarshal(body, &buckets); err != nil {
		t.Fatal(err)
	}
	if len(buckets.Buckets) != 2 || buckets.Buckets[0].Month != "2024-08" || buckets.Buckets[1].Month != "2024-07" {
		t.Fatalf("buckets: %s", body)
	}

	items := c.readBucket("2024-08").Items
	if len(items) != 1 || items[0].Id.String() != august || items[0].LocalAt != "2024-08-01T01:30:00" || items[0].Ratio != 1.5 {
		t.Errorf("august: %+v", items)
	}
	if strings.Contains(string(body), processing) {
		t.Error("an unprocessed asset is on the timeline")
	}
	resp, body = c.get("/api/timeline/buckets/2024-13")
	expect(t, resp, body, http.StatusBadRequest)
	resp, body = c.get("/api/timeline/buckets/..%2f..")
	if resp.StatusCode == http.StatusOK {
		t.Errorf("bad month accepted: %s", body)
	}
}

func TestAssetNeighbours(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	var ids []string
	for i, when := range []string{"2024-01-03T00:00:00Z", "2024-01-02T00:00:00Z", "2024-01-01T00:00:00Z"} {
		id := uploadedID(t, c.upload(string(rune('a'+i))+".jpg", randomBytes(t, 100), nil))
		s.markReady(t, id, when, nil)
		ids = append(ids, id)
	}
	resp, body := c.get("/api/assets/" + ids[1])
	expect(t, resp, body, http.StatusOK)
	var detail api.AssetDetail
	if err := json.Unmarshal(body, &detail); err != nil {
		t.Fatal(err)
	}
	if detail.NewerId == nil || detail.NewerId.String() != ids[0] || detail.OlderId == nil || detail.OlderId.String() != ids[2] {
		t.Errorf("neighbours: %s", body)
	}
	resp, body = c.get("/api/assets/" + ids[0])
	expect(t, resp, body, http.StatusOK)
	var newest api.AssetDetail
	if err := json.Unmarshal(body, &newest); err != nil {
		t.Fatal(err)
	}
	if newest.NewerId != nil {
		t.Error("the newest asset has a newer neighbour")
	}
}

// Another user's asset must look exactly like one that does not exist.
func TestAssetsAreInvisibleToOtherUsers(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	other := s.user(admin, "ana@example.com")
	id := uploadedID(t, admin.upload("private.jpg", randomBytes(t, 100), nil))
	s.markReady(t, id, "2024-01-01T00:00:00Z", nil)

	for _, path := range []string{"/api/assets/" + id, "/api/assets/" + id + "/thumbnail", "/api/assets/" + id + "/original", "/api/assets/download?ids=" + id} {
		resp, body := other.get(path)
		expect(t, resp, body, http.StatusNotFound)
		resp, body = s.client().get(path)
		expect(t, resp, body, http.StatusUnauthorized)
		resp, body = admin.get(path)
		expect(t, resp, body, http.StatusOK)
	}

	resp, body := other.get("/api/timeline/buckets")
	expect(t, resp, body, http.StatusOK)
	if strings.Contains(string(body), "2024-01") {
		t.Errorf("saw another user's month: %s", body)
	}
	if items := other.readBucket("2024-01").Items; len(items) != 0 {
		t.Errorf("saw another user's items: %+v", items)
	}
	resp, body = s.client().get("/api/timeline/buckets")
	expect(t, resp, body, http.StatusUnauthorized)

	// Bulk actions ignore assets of other users.
	parsed := uuid.MustParse(id)
	for _, action := range []api.BulkRequestAction{api.BulkRequestActionFavorite, api.BulkRequestActionArchive, api.BulkRequestActionDelete} {
		resp, body = other.post("/api/assets/bulk", api.BulkRequest{Ids: []openapi_types.UUID{parsed}, Action: action})
		expect(t, resp, body, http.StatusOK)
		var result api.BulkResponse
		if err := json.Unmarshal(body, &result); err != nil {
			t.Fatal(err)
		}
		if result.Changed != 0 {
			t.Errorf("%s changed another user's asset", action)
		}
	}
	if items := admin.readBucket("2024-01").Items; len(items) != 1 || items[0].IsFavorite {
		t.Errorf("owner's asset changed: %+v", items)
	}
}

func TestOriginalHeadersAndRange(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	data := randomBytes(t, 1000)
	id := uploadedID(t, c.upload("photo.jpg", data, nil))
	s.markReady(t, id, "2024-01-01T00:00:00Z", nil)

	resp, body := c.get("/api/assets/" + id + "/original")
	expect(t, resp, body, http.StatusOK)
	if !bytes.Equal(body, data) {
		t.Error("the original differs")
	}
	if resp.Header.Get("X-Content-Type-Options") != "nosniff" || !strings.Contains(resp.Header.Get("Content-Security-Policy"), "sandbox") {
		t.Errorf("headers: %v", resp.Header)
	}
	if !strings.HasPrefix(resp.Header.Get("Content-Disposition"), "inline") {
		t.Errorf("disposition: %s", resp.Header.Get("Content-Disposition"))
	}

	resp, body = c.do(http.MethodGet, "/api/assets/"+id+"/original", map[string]string{"Range": "bytes=10-19"}, nil)
	expect(t, resp, body, http.StatusPartialContent)
	if !bytes.Equal(body, data[10:20]) {
		t.Error("wrong range")
	}

	resp, body = c.get("/api/assets/" + id + "/original?download=true")
	expect(t, resp, body, http.StatusOK)
	if !strings.Contains(resp.Header.Get("Content-Disposition"), "attachment") || !strings.Contains(resp.Header.Get("Content-Disposition"), "photo.jpg") {
		t.Errorf("download disposition: %s", resp.Header.Get("Content-Disposition"))
	}
}

// An uploaded SVG or HTML file must never run as a page of this site.
func TestActiveContentIsNeverShownInline(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	payload := []byte(`<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>`)
	id := uploadedID(t, c.upload("evil.svg", payload, nil))
	s.markReady(t, id, "2024-01-01T00:00:00Z", nil)
	if _, err := s.pool.Exec(context.Background(), "UPDATE assets SET mime_type='image/svg+xml' WHERE id=$1", id); err != nil {
		t.Fatal(err)
	}
	resp, body := c.get("/api/assets/" + id + "/original")
	expect(t, resp, body, http.StatusOK)
	if resp.Header.Get("Content-Type") != "application/octet-stream" || !strings.HasPrefix(resp.Header.Get("Content-Disposition"), "attachment") {
		t.Errorf("served as %s, %s", resp.Header.Get("Content-Type"), resp.Header.Get("Content-Disposition"))
	}
}

func TestThumbnail(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	id := uploadedID(t, c.upload("a.jpg", randomBytes(t, 100), nil))
	s.markReady(t, id, "2024-01-01T00:00:00Z", nil)

	resp, body := c.get("/api/assets/" + id + "/thumbnail?size=large")
	expect(t, resp, body, http.StatusOK)
	if resp.Header.Get("Content-Type") != "image/webp" || !strings.Contains(resp.Header.Get("Cache-Control"), "private") {
		t.Errorf("headers: %v", resp.Header)
	}
	if string(body) != "thumbnail "+id {
		t.Errorf("body: %s", body)
	}
	// Without a version it is checked each time, so an edit made elsewhere shows at once; with one
	// it is kept, because an edit gives a new version.
	if got := resp.Header.Get("Cache-Control"); got != "private, no-cache" {
		t.Errorf("without a version: %q", got)
	}
	resp, body = c.get("/api/assets/" + id + "/thumbnail?v=abc")
	expect(t, resp, body, http.StatusOK)
	if got := resp.Header.Get("Cache-Control"); !strings.Contains(got, "immutable") {
		t.Errorf("with a version: %q", got)
	}
	resp, body = c.get("/api/assets/" + uuid.NewString() + "/thumbnail")
	expect(t, resp, body, http.StatusNotFound)
	resp, _ = c.get("/api/assets/not-a-uuid/thumbnail")
	if resp.StatusCode != http.StatusBadRequest {
		t.Errorf("bad id: %d", resp.StatusCode)
	}
}

func TestBulkActionsAndDeleteKeepTheOriginal(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	data := randomBytes(t, 100)
	id := uploadedID(t, c.upload("a.jpg", data, nil))
	s.markReady(t, id, "2024-02-01T00:00:00Z", nil)
	stored, _ := s.assetFile(id)
	parsed := uuid.MustParse(id)
	act := func(action api.BulkRequestAction) int64 {
		t.Helper()
		resp, body := c.post("/api/assets/bulk", api.BulkRequest{Ids: []openapi_types.UUID{parsed}, Action: action})
		expect(t, resp, body, http.StatusOK)
		var result api.BulkResponse
		if err := json.Unmarshal(body, &result); err != nil {
			t.Fatal(err)
		}
		return result.Changed
	}

	if act(api.BulkRequestActionFavorite) != 1 || !c.readBucket("2024-02").Items[0].IsFavorite {
		t.Error("favorite did not apply")
	}
	if act(api.BulkRequestActionUnfavorite) != 1 || c.readBucket("2024-02").Items[0].IsFavorite {
		t.Error("unfavorite did not apply")
	}

	if act(api.BulkRequestActionDelete) != 1 {
		t.Error("delete did not apply")
	}
	if items := c.readBucket("2024-02").Items; len(items) != 0 {
		t.Error("a deleted asset is on the timeline")
	}
	resp, body := c.get("/api/assets/" + id)
	expect(t, resp, body, http.StatusNotFound)
	if _, err := os.Stat(stored); err != nil {
		t.Errorf("delete removed the original: %v", err)
	}

	// Uploading the same file again brings it back.
	again := c.upload("a.jpg", data, nil)
	if again.Header.Get("X-Asset-Id") != id || again.Header.Get("X-Asset-Duplicate") != "true" {
		t.Errorf("headers: %v", again.Header)
	}
	if items := c.readBucket("2024-02").Items; len(items) != 1 {
		t.Error("re-upload did not restore the asset")
	}

	if act(api.BulkRequestActionArchive) != 1 {
		t.Error("archive did not apply")
	}
	if items := c.readBucket("2024-02").Items; len(items) != 0 {
		t.Error("an archived asset is on the timeline")
	}

	resp, body = c.post("/api/assets/bulk", api.BulkRequest{Ids: nil, Action: api.BulkRequestActionDelete})
	expect(t, resp, body, http.StatusBadRequest)
	resp, body = c.post("/api/assets/bulk", map[string]any{"ids": []string{id}, "action": "explode"})
	expect(t, resp, body, http.StatusBadRequest)
}

func TestDownloadZip(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	first, second := randomBytes(t, 300), randomBytes(t, 400)
	a := uploadedID(t, c.upload("same.jpg", first, nil))
	b := uploadedID(t, c.upload("same.jpg", second, nil))
	s.markReady(t, a, "2024-01-01T00:00:00Z", nil)
	s.markReady(t, b, "2024-01-02T00:00:00Z", nil)

	resp, body := c.get("/api/assets/download?ids=" + a + "," + b)
	expect(t, resp, body, http.StatusOK)
	archive, err := zip.NewReader(bytes.NewReader(body), int64(len(body)))
	if err != nil {
		t.Fatal(err)
	}
	if len(archive.File) != 2 || archive.File[0].Name == archive.File[1].Name {
		t.Fatalf("files: %+v", archive.File)
	}

	resp, body = c.get("/api/assets/download?ids=../../etc/passwd")
	expect(t, resp, body, http.StatusBadRequest)
	resp, body = c.get("/api/assets/download?ids=" + strings.TrimSuffix(strings.Repeat(a+",", maxZipIDs+1), ","))
	expect(t, resp, body, http.StatusBadRequest)
}

func TestRealThumbnailHasARatio(t *testing.T) {
	if _, err := exec.LookPath("vips"); err != nil {
		t.Skip("media tools are not installed; run through `make test`")
	}
	s := newStack(t)
	c := s.admin()
	ctx, cancel := context.WithCancel(context.Background())
	worker, err := jobs.NewWorker(s.pool, jobs.Options{Concurrency: 1, LibraryPath: s.library, CachePath: s.cache})
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

	image := filepath.Join(t.TempDir(), "wide.jpg")
	if out, err := exec.Command("vips", "gaussnoise", image, "800", "400").CombinedOutput(); err != nil {
		t.Fatalf("%v: %s", err, out)
	}
	data, err := os.ReadFile(image)
	if err != nil {
		t.Fatal(err)
	}
	id := uploadedID(t, c.upload("wide.jpg", data, nil))
	waitForAsset(t, c, "wide.jpg")

	month := time.Now().UTC().Format("2006-01")
	items := c.readBucket(month).Items
	if len(items) != 1 || items[0].Id.String() != id || items[0].Ratio < 1.99 || items[0].Ratio > 2.01 {
		t.Errorf("items: %+v", items)
	}
}
