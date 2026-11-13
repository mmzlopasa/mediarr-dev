package app

import (
	"bytes"
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

func needMediaTools(t *testing.T) {
	t.Helper()
	for _, tool := range []string{"vipsthumbnail", "ffmpeg", "exiftool"} {
		if _, err := exec.LookPath(tool); err != nil {
			t.Skip("media tools are not installed; run through `make test`")
		}
	}
}

func (c *client) cast(ids ...string) api.CastSession {
	c.s.t.Helper()
	resp, body := c.post("/api/cast-sessions", map[string]any{"ids": ids})
	expect(c.s.t, resp, body, http.StatusCreated)
	return decode[api.CastSession](c.s.t, body)
}

func TestATVTokenOpensOnlyWhatWasSentToIt(t *testing.T) {
	needMediaTools(t)
	s := newStack(t)
	s.startWorker(t)
	owner := s.admin()
	stranger := s.user(owner, "stranger@example.com")
	tv := s.client()
	sent := uploadedID(t, owner.upload("sent.jpg", pictureOf(t, 10), nil))
	other := uploadedID(t, owner.upload("other.jpg", pictureOf(t, 200), nil))
	strangers := uploadedID(t, stranger.upload("theirs.jpg", pictureOf(t, 90), nil))
	s.settle(t)

	session := owner.cast(sent)
	if session.Token == nil || len(session.Media) != 1 || time.Until(session.ExpiresAt) > castLifetime+time.Minute {
		t.Fatalf("session: %+v", session)
	}
	image := session.Media[0].Image
	if !strings.HasPrefix(image, "/api/tv/"+*session.Token+"/assets/"+sent) || session.Media[0].File != nil {
		t.Fatalf("media: %+v", session.Media[0])
	}

	// The TV has no cookie and no password, and gets a JPEG without any metadata.
	resp, body := tv.get(image)
	expect(t, resp, body, http.StatusOK)
	if resp.Header.Get("Content-Type") != "image/jpeg" || !bytes.HasPrefix(body, []byte{0xFF, 0xD8}) || bytes.Contains(body, []byte("Exif")) {
		t.Fatalf("not a clean JPEG: %s", resp.Header.Get("Content-Type"))
	}
	if resp.Header.Get("Set-Cookie") != "" {
		t.Fatal("a TV must not be given a cookie")
	}

	// Nothing else is reached with the token: another photo, the original, the details or a list.
	prefix := "/api/tv/" + *session.Token + "/assets/"
	for _, path := range []string{
		prefix + other + "/image", prefix + strangers + "/image", prefix + sent + "/video/master.m3u8",
		"/api/tv/wrong/assets/" + sent + "/image", "/api/assets/" + sent, "/api/timeline/buckets",
	} {
		resp, body := tv.get(path)
		if resp.StatusCode < http.StatusBadRequest {
			t.Errorf("%s reached with the token: %d %s", path, resp.StatusCode, truncateForTest(body))
		}
	}
	resp, body = tv.get(prefix + sent + "/original")
	expect(t, resp, body, http.StatusForbidden)

	// Swiping on adds the next photo, which only the owner of the session can do.
	resp, body = stranger.post("/api/cast-sessions/"+session.Id.String()+"/assets", map[string]any{"ids": []string{strangers}})
	expect(t, resp, body, http.StatusNotFound)
	resp, body = owner.post("/api/cast-sessions/"+session.Id.String()+"/assets", map[string]any{"ids": []string{strangers}})
	expect(t, resp, body, http.StatusNotFound)
	resp, body = owner.post("/api/cast-sessions/"+session.Id.String()+"/assets", map[string]any{"ids": []string{other}})
	expect(t, resp, body, http.StatusOK)
	added := decode[api.CastSession](t, body)
	if added.Token != nil || len(added.Media) != 1 || !strings.HasPrefix(added.Media[0].Image, "/api/tv/{token}/assets/"+other) {
		t.Fatalf("added: %+v", added)
	}
	resp, body = tv.get(prefix + other + "/image")
	expect(t, resp, body, http.StatusOK)

	// Someone else's photo cannot be sent, nor a session started with it.
	resp, body = owner.post("/api/cast-sessions", map[string]any{"ids": []string{strangers}})
	expect(t, resp, body, http.StatusNotFound)

	// A photo that goes to the trash or to the locked folder leaves the TV at once.
	ctx := context.Background()
	if _, err := s.pool.Exec(ctx, "UPDATE assets SET vault_at = now() WHERE id = $1", other); err != nil {
		t.Fatal(err)
	}
	resp, body = tv.get(prefix + other + "/image")
	expect(t, resp, body, http.StatusNotFound)

	// Stopping ends the token, for the TV too; a stranger cannot stop it.
	resp, body = stranger.send(http.MethodDelete, "/api/cast-sessions/"+session.Id.String(), nil)
	expect(t, resp, body, http.StatusNotFound)
	resp, body = tv.get(image)
	expect(t, resp, body, http.StatusOK)
	resp, body = owner.send(http.MethodDelete, "/api/cast-sessions/"+session.Id.String(), nil)
	expect(t, resp, body, http.StatusNoContent)
	resp, body = tv.get(image)
	expect(t, resp, body, http.StatusNotFound)

	// A token ends by itself after its time.
	expired := owner.cast(sent)
	resp, body = tv.get(expired.Media[0].Image)
	expect(t, resp, body, http.StatusOK)
	if _, err := s.pool.Exec(ctx, "UPDATE cast_sessions SET expires_at = now() - interval '1 second' WHERE id = $1", expired.Id); err != nil {
		t.Fatal(err)
	}
	resp, body = tv.get(expired.Media[0].Image)
	expect(t, resp, body, http.StatusNotFound)
	resp, body = owner.post("/api/cast-sessions/"+expired.Id.String()+"/assets", map[string]any{"ids": []string{sent}})
	expect(t, resp, body, http.StatusNotFound)
}

func TestATVPlaysAVideoWithoutItsLocation(t *testing.T) {
	needMediaTools(t)
	s := newStack(t)
	s.startWorker(t)
	owner := s.admin()
	tv := s.client()
	path := filepath.Join(t.TempDir(), "clip.mp4")
	if out, err := exec.Command("ffmpeg", "-nostdin", "-v", "error", "-f", "lavfi", "-i", "testsrc2=duration=2:size=320x180:rate=10",
		"-c:v", "libx264", "-pix_fmt", "yuv420p", path).CombinedOutput(); err != nil {
		t.Fatalf("%v: %s", err, out)
	}
	if out, err := exec.Command("exiftool", "-q", "-overwrite_original", "-Keys:GPSCoordinates=45.8150 15.9819",
		"-UserData:GPSCoordinates=45.8150 15.9819", path).CombinedOutput(); err != nil {
		t.Fatalf("%v: %s", err, out)
	}
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Contains(data, []byte("45.815")) {
		t.Fatal("the test video has no location to remove")
	}
	id := uploadedID(t, owner.upload("clip.mp4", data, nil))
	// Converting a video takes a while when the whole suite runs at once.
	deadline := time.Now().Add(4 * time.Minute)
	for {
		// A TV is offered only what is ready, which can come a moment after the conversion.
		if detail := owner.detail(id); detail.HlsReady != nil && *detail.HlsReady && detail.Status == "ready" {
			break
		}
		if time.Now().After(deadline) {
			t.Fatal("the video was not converted in time")
		}
		time.Sleep(200 * time.Millisecond)
	}

	session := owner.cast(id)
	media := session.Media[0]
	if media.Kind != api.CastMediaKindVideo || media.Hls == nil || media.File == nil || media.MimeType == nil || *media.MimeType != "video/mp4" {
		t.Fatalf("media: %+v", media)
	}
	resp, body := tv.get(*media.Hls)
	expect(t, resp, body, http.StatusOK)
	if !strings.Contains(string(body), "0.m3u8") {
		t.Fatalf("master: %s", body)
	}
	resp, body = tv.get(strings.TrimSuffix(*media.Hls, "master.m3u8") + "0_000.ts")
	expect(t, resp, body, http.StatusOK)
	resp, body = tv.get(strings.TrimSuffix(*media.Hls, "master.m3u8") + "sprite.jpg")
	expect(t, resp, body, http.StatusNotFound)

	resp, body = tv.get(*media.File)
	expect(t, resp, body, http.StatusOK)
	if len(body) < 1000 || bytes.Contains(body, []byte("45.815")) {
		t.Fatalf("the video still says where it was taken (%d bytes)", len(body))
	}
	// A TV jumps around in a video, so parts of it can be asked for.
	resp, body = tv.do(http.MethodGet, *media.File, map[string]string{"Range": "bytes=0-99"}, nil)
	expect(t, resp, body, http.StatusPartialContent)
	resp, body = tv.get(media.Image)
	expect(t, resp, body, http.StatusOK)
}

func TestACastSessionIsChecked(t *testing.T) {
	s := newStack(t)
	owner := s.admin()
	resp, body := owner.post("/api/cast-sessions", map[string]any{"ids": []string{}})
	expect(t, resp, body, http.StatusBadRequest)
	resp, body = owner.post("/api/cast-sessions", map[string]any{"ids": []string{"00000000-0000-4000-8000-000000000000"}})
	expect(t, resp, body, http.StatusNotFound)
	resp, body = s.client().post("/api/cast-sessions", map[string]any{"ids": []string{"00000000-0000-4000-8000-000000000000"}})
	expect(t, resp, body, http.StatusUnauthorized)
}
