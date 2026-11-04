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

	"github.com/mmzlopasa/mediarr-app/server/db"
	"github.com/mmzlopasa/mediarr-app/server/internal/api"
	"github.com/mmzlopasa/mediarr-app/server/internal/jobs"
)

func (s *stack) startWorker(t *testing.T) {
	t.Helper()
	ctx, cancel := context.WithCancel(context.Background())
	worker, err := jobs.NewWorker(s.pool, jobs.Options{Concurrency: 2, LibraryPath: s.library, CachePath: s.cache, ExternalPath: s.external})
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

func (s *stack) startLocalHookWorker(t *testing.T) {
	t.Helper()
	ctx, cancel := context.WithCancel(context.Background())
	worker, err := jobs.NewWorker(s.pool, jobs.Options{Concurrency: 2, LibraryPath: s.library, CachePath: s.cache, AllowLocalWebhooks: true})
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

func (c *client) detail(id string) api.AssetDetail {
	c.s.t.Helper()
	resp, body := c.get("/api/assets/" + id)
	expect(c.s.t, resp, body, http.StatusOK)
	var detail api.AssetDetail
	if err := json.Unmarshal(body, &detail); err != nil {
		c.s.t.Fatal(err)
	}
	return detail
}

func TestVideoGetsHLSAndAScrubStrip(t *testing.T) {
	if _, err := exec.LookPath("ffmpeg"); err != nil {
		t.Skip("media tools are not installed; run through `make test`")
	}
	s := newStack(t)
	c := s.admin()
	other := s.user(c, "ana@example.com")
	s.startWorker(t)

	path := filepath.Join(t.TempDir(), "clip.mp4")
	if out, err := exec.Command("ffmpeg", "-nostdin", "-v", "error", "-f", "lavfi", "-i", "testsrc2=duration=2:size=640x360:rate=10",
		"-c:v", "libx264", "-pix_fmt", "yuv420p", path).CombinedOutput(); err != nil {
		t.Fatalf("%v: %s", err, out)
	}
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	id := uploadedID(t, c.upload("clip.mp4", data, nil))

	var detail api.AssetDetail
	deadline := time.Now().Add(90 * time.Second)
	for time.Now().Before(deadline) {
		detail = c.detail(id)
		if detail.HlsReady != nil && *detail.HlsReady {
			break
		}
		time.Sleep(200 * time.Millisecond)
	}
	if detail.HlsReady == nil || !*detail.HlsReady {
		t.Fatalf("no HLS: %+v", detail)
	}
	if detail.DurationMs == nil || *detail.DurationMs < 1000 || detail.VideoCodec == nil || *detail.VideoCodec != "h264" {
		t.Errorf("video info: %+v", detail)
	}
	if detail.Sprite == nil || detail.Sprite.Count < 2 {
		t.Errorf("sprite: %+v", detail.Sprite)
	}

	base := "/api/assets/" + id + "/video/"
	resp, body := c.get(base + "master.m3u8")
	expect(t, resp, body, http.StatusOK)
	if resp.Header.Get("Content-Type") != "application/vnd.apple.mpegurl" || !strings.Contains(string(body), "0.m3u8") {
		t.Errorf("master: %v %s", resp.Header, body)
	}
	resp, body = c.get(base + "0.m3u8")
	expect(t, resp, body, http.StatusOK)
	if !strings.Contains(string(body), "0_000.ts") {
		t.Errorf("playlist must use relative names, with no folder of the server: %s", body)
	}
	if strings.Contains(string(body), "/data") || strings.Contains(string(body), s.cache) {
		t.Errorf("the playlist shows a server path: %s", body)
	}
	resp, body = c.get(base + "0_000.ts")
	expect(t, resp, body, http.StatusOK)
	if resp.Header.Get("Content-Type") != "video/mp2t" || len(body) == 0 {
		t.Errorf("segment: %v", resp.Header)
	}
	resp, body = c.get(base + "sprite.jpg")
	expect(t, resp, body, http.StatusOK)
	if resp.Header.Get("Content-Type") != "image/jpeg" {
		t.Errorf("sprite: %v", resp.Header)
	}

	// Only the owner, and only files that match exactly.
	for _, file := range []string{"master.m3u8", "0_000.ts", "sprite.jpg"} {
		resp, body = other.get(base + file)
		expect(t, resp, body, http.StatusNotFound)
		resp, body = s.client().get(base + file)
		expect(t, resp, body, http.StatusUnauthorized)
	}
	for _, file := range []string{"..%2f..%2fetc%2fpasswd", "..", "master.m3u8.bak", "0.ts", ".hidden", "a.m3u8"} {
		resp, _ = c.get(base + file)
		if resp.StatusCode == http.StatusOK {
			t.Errorf("served %q", file)
		}
	}
}

func TestFullPreviewIsMadeOnceAndOnlyForTheOwner(t *testing.T) {
	if _, err := exec.LookPath("vips"); err != nil {
		t.Skip("media tools are not installed; run through `make test`")
	}
	s := newStack(t)
	c := s.admin()
	other := s.user(c, "ana@example.com")
	s.startWorker(t)

	path := filepath.Join(t.TempDir(), "big.jpg")
	if out, err := exec.Command("vips", "gaussnoise", path, "2000", "1500").CombinedOutput(); err != nil {
		t.Fatalf("%v: %s", err, out)
	}
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	id := uploadedID(t, c.upload("big.jpg", data, nil))
	waitForAsset(t, c, "big.jpg")

	url := "/api/assets/" + id + "/thumbnail?size=full"
	resp, body := other.get(url)
	expect(t, resp, body, http.StatusNotFound)
	resp, first := c.get(url)
	expect(t, resp, first, http.StatusOK)
	if resp.Header.Get("Content-Type") != "image/webp" || len(first) == 0 {
		t.Errorf("full: %v", resp.Header)
	}
	resp, second := c.get(url)
	expect(t, resp, second, http.StatusOK)
	if string(first) != string(second) {
		t.Error("the second request made a different file")
	}
	var rows int
	if err := s.pool.QueryRow(context.Background(), "SELECT count(*) FROM asset_files WHERE kind='thumb_full'").Scan(&rows); err != nil {
		t.Fatal(err)
	}
	if rows != 1 {
		t.Errorf("%d rows", rows)
	}
}

// Generated HEIC files cannot carry Apple's identifier, so this sets it the way metadata would.
func TestLivePhotoPairsInEitherOrder(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	ctx := context.Background()
	q := db.New(s.pool)
	user, err := q.GetUserByEmail(ctx, "admin@example.com")
	if err != nil {
		t.Fatal(err)
	}

	photo := uploadedID(t, c.upload("IMG.HEIC", randomBytes(t, 100), nil))
	s.markReady(t, photo, "2024-03-01T10:00:00Z", nil)
	video := uploadedID(t, c.upload("IMG.MOV", randomBytes(t, 100), nil))
	s.markReady(t, video, "2024-03-01T10:00:00Z", nil)
	before := uploadedID(t, c.upload("other.jpg", randomBytes(t, 100), nil))
	s.markReady(t, before, "2024-03-01T09:00:00Z", nil)

	setID := func(id, kind string) {
		t.Helper()
		if _, err := s.pool.Exec(ctx, "UPDATE assets SET kind=$2, content_id='LIVE-1' WHERE id=$1", id, kind); err != nil {
			t.Fatal(err)
		}
		if err := q.LinkLivePhoto(ctx, db.LinkLivePhotoParams{UserID: user.ID, ContentID: textValue("LIVE-1")}); err != nil {
			t.Fatal(err)
		}
	}
	// The video arrives first, with nothing to pair with yet.
	setID(video, "video")
	if items := c.readBucket("2024-03").Items; len(items) != 3 {
		t.Fatalf("before the photo: %d items", len(items))
	}
	setID(photo, "photo")

	items := c.readBucket("2024-03").Items
	if len(items) != 2 {
		t.Fatalf("after pairing: %d items, the video must be hidden", len(items))
	}
	for _, item := range items {
		if item.Id.String() == video {
			t.Error("the paired video is still on the timeline")
		}
		if item.Id.String() == photo && (item.IsLive == nil || !*item.IsLive) {
			t.Errorf("the photo is not marked live: %+v", item)
		}
	}
	detail := c.detail(photo)
	if detail.LiveVideoId == nil || detail.LiveVideoId.String() != video {
		t.Errorf("live video: %+v", detail.LiveVideoId)
	}
	if older := c.detail(before); older.NewerId == nil || older.NewerId.String() != photo {
		t.Errorf("the viewer would step onto the hidden video: %+v", older.NewerId)
	}
	resp, body := c.get("/api/assets/" + video + "/original")
	expect(t, resp, body, http.StatusOK)

	// Another user's file with the same identifier never pairs.
	other := s.user(c, "ana@example.com")
	foreign := uploadedID(t, other.upload("x.MOV", randomBytes(t, 100), nil))
	s.markReady(t, foreign, "2024-03-01T10:00:00Z", nil)
	if _, err := s.pool.Exec(ctx, "UPDATE assets SET kind='video', content_id='LIVE-1' WHERE id=$1", foreign); err != nil {
		t.Fatal(err)
	}
	if err := q.LinkLivePhoto(ctx, db.LinkLivePhotoParams{UserID: user.ID, ContentID: textValue("LIVE-1")}); err != nil {
		t.Fatal(err)
	}
	var linked *string
	if err := s.pool.QueryRow(ctx, "SELECT live_photo_of::text FROM assets WHERE id=$1", foreign).Scan(&linked); err != nil {
		t.Fatal(err)
	}
	if linked != nil {
		t.Error("paired with another user's photo")
	}
}

func TestMotionFileIsOnlyForTheOwner(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	other := s.user(c, "ana@example.com")
	id := uploadedID(t, c.upload("MVIMG.jpg", randomBytes(t, 100), nil))
	s.markReady(t, id, "2024-01-01T00:00:00Z", nil)
	resp, body := c.get("/api/assets/" + id + "/motion")
	expect(t, resp, body, http.StatusNotFound)

	video := filepath.Join(t.TempDir(), "m.mp4")
	if err := os.WriteFile(video, []byte("video"), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := s.pool.Exec(context.Background(), "INSERT INTO asset_files (asset_id, kind, path, size_bytes) VALUES ($1, 'motion_video', $2, 5)", id, video); err != nil {
		t.Fatal(err)
	}
	if detail := c.detail(id); detail.HasMotion == nil || !*detail.HasMotion {
		t.Errorf("detail: %+v", detail)
	}
	resp, body = c.get("/api/assets/" + id + "/motion")
	expect(t, resp, body, http.StatusOK)
	if resp.Header.Get("Content-Type") != "video/mp4" {
		t.Errorf("type %s", resp.Header.Get("Content-Type"))
	}
	resp, body = other.get("/api/assets/" + id + "/motion")
	expect(t, resp, body, http.StatusNotFound)
}
