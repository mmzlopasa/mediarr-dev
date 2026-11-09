package app

import (
	"net/http"
	"testing"

	"github.com/mediarr-app/mediarr/server/internal/api"
)

func cleanupCounts(t *testing.T, c *client, query string) map[api.CleanupCategoryId]int64 {
	t.Helper()
	resp, body := c.get("/api/cleanup" + query)
	expect(t, resp, body, http.StatusOK)
	out := map[api.CleanupCategoryId]int64{}
	for _, category := range decode[api.CleanupSummary](t, body).Categories {
		out[category.Id] = category.Count
	}
	return out
}

func TestCleanUpOffersBlurryScreenshotsLargeVideosAndBursts(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	other := s.user(c, "other@example.com")
	blurry := c.newPhoto(t, "blurry.jpg", "2024-07-05T10:00:00Z")
	sharp := c.newPhoto(t, "sharp.jpg", "2024-07-05T10:01:00Z")
	screenshot := c.newPhoto(t, "Screenshot_20240705-101500.png", "2024-07-05T10:15:00Z")
	snimka := c.newPhoto(t, "Snimka zaslona 2024-07-05.png", "2024-07-05T10:16:00Z")
	video := c.newPhoto(t, "long.mp4", "2024-07-05T11:00:00Z")
	small := c.newPhoto(t, "short.mp4", "2024-07-05T11:05:00Z")
	burstMain := c.newPhoto(t, "IMG_0010.jpg", "2024-07-05T12:00:00Z")
	burstOther := c.newPhoto(t, "IMG_0011.jpg", "2024-07-05T12:00:01Z")
	raw := c.newPhoto(t, "IMG_0010.CR2", "2024-07-05T12:00:00Z")
	theirs := other.newPhoto(t, "Screenshot_theirs.png", "2024-07-05T10:00:00Z")
	s.exec(t, `UPDATE assets SET sharpness = 5 WHERE id = $1`, blurry)
	s.exec(t, `UPDATE assets SET sharpness = 900 WHERE id = $1`, sharp)
	s.exec(t, `UPDATE assets SET kind = 'video', size_bytes = 900 * 1024 * 1024, duration_ms = 600000 WHERE id = $1`, video)
	s.exec(t, `UPDATE assets SET kind = 'video', size_bytes = 10 * 1024 * 1024 WHERE id = $1`, small)
	s.exec(t, `UPDATE assets SET stack_parent = $2 WHERE id = ANY($1::uuid[])`, []string{burstOther, raw}, burstMain)
	_ = theirs

	counts := cleanupCounts(t, c, "")
	if counts[api.Blurry] != 1 || counts[api.Screenshots] != 2 || counts[api.LargeVideos] != 1 || counts[api.Bursts] != 1 {
		t.Fatalf("%v", counts)
	}
	// Smaller videos count when the size goes down; a stricter blur finds fewer.
	if counts := cleanupCounts(t, c, "?videoMb=250&blur=1"); counts[api.LargeVideos] != 1 || counts[api.Blurry] != 1 {
		t.Fatalf("%v", counts)
	}

	resp, body := c.get("/api/cleanup/screenshots?limit=1")
	expect(t, resp, body, http.StatusOK)
	page := decode[api.CleanupPage](t, body)
	if len(page.Items) != 1 || page.NextOffset == nil || *page.NextOffset != 1 {
		t.Fatalf("%s", body)
	}
	resp, body = c.get("/api/cleanup/bursts")
	expect(t, resp, body, http.StatusOK)
	if page := decode[api.CleanupPage](t, body); len(page.Items) != 1 || page.Items[0].Id.String() != burstOther {
		t.Fatalf("a RAW is not a burst: %s", body)
	}
	resp, body = c.get("/api/cleanup/largeVideos")
	expect(t, resp, body, http.StatusOK)
	if page := decode[api.CleanupPage](t, body); len(page.Items) != 1 || page.Items[0].DurationMs == nil {
		t.Fatalf("%s", body)
	}
	resp, body = c.get("/api/cleanup/nonsense")
	expect(t, resp, body, http.StatusBadRequest)

	// Kept is not offered again; someone else's photos are not touched.
	resp, body = c.post("/api/cleanup/keep", api.AssetIds{Ids: uuids(t, snimka, theirs)})
	expect(t, resp, body, http.StatusNoContent)
	if counts := cleanupCounts(t, c, ""); counts[api.Screenshots] != 1 {
		t.Fatalf("%v", counts)
	}
	if counts := cleanupCounts(t, other, ""); counts[api.Screenshots] != 1 {
		t.Fatalf("theirs: %v", counts)
	}
	_ = screenshot
}
