package jobs

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"slices"
	"sync/atomic"
	"testing"
	"time"

	"github.com/google/uuid"
)

func TestWithProtocolWhitelist(t *testing.T) {
	tests := []struct {
		command string
		args    []string
		want    []string
	}{
		{"ffmpeg", []string{"-i", "a.mp4"}, []string{"-protocol_whitelist", ffmpegProtocols, "-i", "a.mp4"}},
		{"ffprobe", []string{"a.mp4"}, []string{"-protocol_whitelist", ffmpegProtocols, "a.mp4"}},
		{"nice", []string{"-n", "15", "ffmpeg", "-i", "a.mp4"}, []string{"-n", "15", "ffmpeg", "-protocol_whitelist", ffmpegProtocols, "-i", "a.mp4"}},
		{"nice", []string{"-n", "15", "ffmpeg", "-protocol_whitelist", "file", "-i", "a"}, []string{"-n", "15", "ffmpeg", "-protocol_whitelist", "file", "-i", "a"}},
		{"exiftool", []string{"a.jpg"}, []string{"a.jpg"}},
	}
	for _, tt := range tests {
		if got := withProtocolWhitelist(tt.command, tt.args); !slices.Equal(got, tt.want) {
			t.Errorf("%s %v = %v, want %v", tt.command, tt.args, got, tt.want)
		}
	}
}

// A playlist given to the tools as a video must not make the worker fetch anything, in any of the ways
// it reads a video.
func TestPlaylistDisguisedAsVideoFetchesNothing(t *testing.T) {
	requireTools(t)
	var hits atomic.Int32
	target := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		hits.Add(1)
		http.NotFound(w, nil)
	}))
	defer target.Close()

	dir := t.TempDir()
	playlist := filepath.Join(dir, "holiday.m3u8")
	body := fmt.Sprintf("#EXTM3U\n#EXT-X-TARGETDURATION:4\n#EXTINF:4,\n%s/segment.ts\n#EXT-X-ENDLIST\n", target.URL)
	if err := os.WriteFile(playlist, []byte(body), 0o600); err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), time.Minute)
	defer cancel()

	_, _ = ProbeVideo(ctx, playlist)
	_, _ = MakeSprite(ctx, playlist, filepath.Join(dir, "sprite.jpg"), 4*time.Second)
	_ = extractFrame(ctx, playlist, filepath.Join(dir, "frame.jpg"))
	_ = Transcode(ctx, playlist, filepath.Join(dir, "hls"), "", &VideoInfo{Codec: "h264", Width: 640, Height: 360})
	if n := hits.Load(); n != 0 {
		t.Errorf("the playlist made the worker fetch %d times", n)
	}
}

func TestCleanupStepsAllRunAfterAFailure(t *testing.T) {
	ran := []string{}
	broken := errors.New("broken")
	step := func(name string, err error) cleanupStep {
		return cleanupStep{name, func() error { ran = append(ran, name); return err }}
	}
	err := runSteps(context.Background(), []cleanupStep{step("a", nil), step("b", broken), step("c", nil)})
	if !slices.Equal(ran, []string{"a", "b", "c"}) {
		t.Errorf("ran %v, want every step", ran)
	}
	if !errors.Is(err, broken) {
		t.Errorf("err = %v, want the failure of b", err)
	}

	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	ran = nil
	if err := runSteps(ctx, []cleanupStep{step("a", nil)}); !errors.Is(err, context.Canceled) || len(ran) != 0 {
		t.Errorf("a stopped worker still ran %v (err %v)", ran, err)
	}
}

func TestOpenListLeavesOutHugeLists(t *testing.T) {
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "Photo Details.csv"), []byte("imgName\nIMG_1.jpg\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, "Photo Details-1.csv"), make([]byte, 4096), 0o600); err != nil {
		t.Fatal(err)
	}
	tree, err := newFolderTree(dir)
	if err != nil {
		t.Fatal(err)
	}
	small, ok := openList(tree, "Photo Details.csv", 1024)
	if !ok {
		t.Fatal("a small list was left out")
	}
	_ = small.Close()
	if _, ok := openList(tree, "Photo Details-1.csv", 1024); ok {
		t.Error("a list larger than the limit was opened")
	}
}

func TestSoftDeleteKeepStaysInTheGuestFolder(t *testing.T) {
	library := t.TempDir()
	guest := uuid.New()
	outside := filepath.Join(library, "secret.txt")
	if err := os.WriteFile(outside, []byte("x"), 0o600); err != nil {
		t.Fatal(err)
	}
	for _, rel := range []string{"../../../secret.txt", "/etc/passwd", ""} {
		if err := SoftDeleteKeep(library, guest, rel, time.Now()); err == nil {
			t.Errorf("%q was accepted", rel)
		}
	}
	if _, err := os.Stat(outside); err != nil {
		t.Error("a file outside the guest's folder was moved")
	}
}
