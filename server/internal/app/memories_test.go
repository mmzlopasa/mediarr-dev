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
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

func TestSpreadCoversTheWholeList(t *testing.T) {
	values := []int{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
	got := spread(values, 5)
	if len(got) != 5 || got[0] != 0 || got[4] != 8 {
		t.Fatalf("%v", got)
	}
	if len(spread(values, 20)) != 10 {
		t.Fatal("short lists stay whole")
	}
}

func TestMemories(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	other := s.user(c, "other@example.com")
	y2020 := c.newPhoto(t, "a.jpg", "2020-06-15T10:00:00Z")
	y2022 := c.newPhoto(t, "b.jpg", "2022-06-15T10:00:00Z")
	c.newPhoto(t, "thisyear.jpg", "2024-06-15T08:00:00Z")
	c.newPhoto(t, "other-day.jpg", "2022-06-16T10:00:00Z")
	trashed := c.newPhoto(t, "trash.jpg", "2021-06-15T10:00:00Z")
	c.bulk(t, "delete", trashed)
	other.newPhoto(t, "foreign.jpg", "2019-06-15T10:00:00Z")

	resp, body := c.get("/api/memories?date=2024-06-15")
	expect(t, resp, body, http.StatusOK)
	memories := decode[[]api.Memory](t, body)
	if len(memories) != 2 || *memories[0].Year != 2022 || *memories[1].Year != 2020 {
		t.Fatalf("memories: %s", body)
	}
	if memories[0].Items[0].Id.String() != y2022 || memories[1].Items[0].Id.String() != y2020 {
		t.Fatalf("items: %s", body)
	}

	// Enough recent photos make a summary of the week, which comes first.
	c.newPhoto(t, "w1.jpg", "2024-06-12T10:00:00Z")
	c.newPhoto(t, "w2.jpg", "2024-06-13T10:00:00Z")
	resp, body = c.get("/api/memories?date=2024-06-15")
	expect(t, resp, body, http.StatusOK)
	memories = decode[[]api.Memory](t, body)
	if memories[0].Kind != api.MemoryKindWeek || len(memories[0].Items) != 3 {
		t.Fatalf("week: %s", body)
	}
	resp, body = c.get("/api/memories?date=1999-01-01")
	expect(t, resp, body, http.StatusOK)
	if len(decode[[]api.Memory](t, body)) != 0 {
		t.Fatalf("nothing on that day: %s", body)
	}
	// A day is plain YYYY-MM-DD; a time with a zone would move it to another day, so it is refused.
	resp, body = c.get("/api/memories?date=2024-06-14T22:00:00Z")
	expect(t, resp, body, http.StatusBadRequest)
	resp, body = c.get("/api/map/points?from=2024-06&to=2024-06-30")
	expect(t, resp, body, http.StatusBadRequest)
	resp, body = c.get("/api/map/points?from=2024-06-01&to=2024-06-30")
	expect(t, resp, body, http.StatusOK)
}

func TestStoryRequests(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	other := s.user(c, "other@example.com")
	photo := c.newPhoto(t, "a.jpg", "2024-06-15T10:00:00Z")
	resp, body := c.post("/api/stories", map[string]any{"title": "", "ids": []string{photo}})
	expect(t, resp, body, http.StatusBadRequest)
	resp, body = c.post("/api/stories", map[string]any{"title": "Summer", "ids": []string{}})
	expect(t, resp, body, http.StatusBadRequest)
	resp, body = c.post("/api/stories", map[string]any{"title": "Summer", "ids": []string{photo}})
	expect(t, resp, body, http.StatusAccepted)
	id := decode[api.StoryExport](t, body).Id.String()

	resp, body = other.get("/api/stories/" + id)
	expect(t, resp, body, http.StatusNotFound)
	resp, body = c.get("/api/stories/" + id)
	expect(t, resp, body, http.StatusOK)
	resp, body = c.get("/api/stories/" + id + "/video")
	expect(t, resp, body, http.StatusNotFound)

	path := filepath.Join(s.cache, "story.mp4")
	if err := os.MkdirAll(s.cache, 0o750); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte("video"), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := s.pool.Exec(context.Background(), `UPDATE story_exports SET status = 'ready', path = $2 WHERE id = $1`, id, path); err != nil {
		t.Fatal(err)
	}
	resp, body = other.get("/api/stories/" + id + "/video")
	expect(t, resp, body, http.StatusNotFound)
	resp, body = c.get("/api/stories/" + id + "/video")
	expect(t, resp, body, http.StatusOK)
	if !strings.Contains(resp.Header.Get("Content-Disposition"), "Summer.mp4") {
		t.Fatalf("name: %q", resp.Header.Get("Content-Disposition"))
	}
}

func TestStoryFilterChainsEveryPicture(t *testing.T) {
	if got := jobs.StoryFilter(1); !strings.HasSuffix(got, "[p0]null[out]") {
		t.Fatalf("one: %s", got)
	}
	got := jobs.StoryFilter(3)
	if strings.Count(got, "xfade") != 2 || !strings.HasSuffix(got, "[out]") || !strings.Contains(got, "[2:v]") {
		t.Fatalf("three: %s", got)
	}
}

func TestMakeStoryWritesAPlayableVideo(t *testing.T) {
	if _, err := exec.LookPath("ffmpeg"); err != nil {
		t.Skip("media tools are not installed; run through `make test`")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()
	dir := t.TempDir()
	pictures := []string{filepath.Join(dir, "a.webp"), filepath.Join(dir, "b.webp")}
	for i, size := range []string{"640 480", "300 900"} {
		parts := strings.Fields(size)
		cmd := exec.CommandContext(ctx, "vips", "black", pictures[i], parts[0], parts[1])
		if out, err := cmd.CombinedOutput(); err != nil {
			t.Fatalf("%v: %s", err, out)
		}
	}
	dest := filepath.Join(dir, "stories", "story.mp4")
	if err := jobs.MakeStory(ctx, pictures, dest); err != nil {
		t.Fatal(err)
	}
	out, err := exec.CommandContext(ctx, "ffprobe", "-v", "error", "-show_entries", "stream=width,height:format=duration", "-of", "csv=p=0", dest).CombinedOutput()
	if err != nil {
		t.Fatalf("%v: %s", err, out)
	}
	if !strings.Contains(string(out), "1280,720") {
		t.Fatalf("%s", out)
	}
}
