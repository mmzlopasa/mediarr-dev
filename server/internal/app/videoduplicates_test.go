package app

import (
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"testing"

	"github.com/mediarr-app/mediarr/server/internal/api"
)

func TestTheSameVideoTwiceIsProposedAsADuplicate(t *testing.T) {
	if _, err := exec.LookPath("ffmpeg"); err != nil {
		t.Skip("media tools are not installed; run through `make test`")
	}
	s := newStack(t)
	c := s.admin()
	s.startWorker(t)
	dir := t.TempDir()
	original := filepath.Join(dir, "clip.mp4")
	copied := filepath.Join(dir, "clip-small.mp4")
	other := filepath.Join(dir, "other.mp4")
	for _, args := range [][]string{
		{"-f", "lavfi", "-i", "testsrc=duration=4:size=640x360:rate=25", "-pix_fmt", "yuv420p", original},
		// The same video, smaller and saved again, as a messaging app would.
		{"-i", original, "-vf", "scale=320:180", "-crf", "35", copied},
		{"-f", "lavfi", "-i", "mandelbrot=size=640x360:rate=25", "-t", "4", "-pix_fmt", "yuv420p", other},
	} {
		cmd := exec.Command("ffmpeg", append([]string{"-nostdin", "-v", "error", "-y"}, args...)...)
		if out, err := cmd.CombinedOutput(); err != nil {
			t.Fatalf("%v: %s", err, out)
		}
	}
	for _, path := range []string{original, copied, other} {
		data, err := os.ReadFile(path)
		if err != nil {
			t.Fatal(err)
		}
		c.upload(filepath.Base(path), data, nil)
		waitForAsset(t, c, filepath.Base(path))
	}
	s.organize(t)
	resp, body := c.get("/api/duplicates")
	expect(t, resp, body, http.StatusOK)
	found := decode[api.Duplicates](t, body)
	if found.Total != 1 || len(found.Groups[0].Items) != 2 {
		t.Fatalf("%s", body)
	}
	// The larger original is kept.
	for _, item := range found.Groups[0].Items {
		if item.Id == found.Groups[0].KeepId && item.OriginalName != "clip.mp4" {
			t.Fatalf("kept %s", item.OriginalName)
		}
	}
}
