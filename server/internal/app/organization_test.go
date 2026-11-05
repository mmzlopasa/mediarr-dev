package app

import (
	"context"
	"net/http"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

func (c *client) bulk(t *testing.T, action string, ids ...string) int64 {
	t.Helper()
	resp, body := c.post("/api/assets/bulk", map[string]any{"ids": ids, "action": action})
	return changedBy(t, resp, body)
}

func TestTrashRestoreAndPurge(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	otherUser := s.user(c, "other@example.com")
	ctx := context.Background()
	photo := c.newPhoto(t, "a.jpg", "2024-06-15T10:00:00Z")
	kept := c.newPhoto(t, "b.jpg", "2024-06-16T10:00:00Z")
	original, _ := s.assetFile(photo)

	if c.bulk(t, "delete", photo) != 1 {
		t.Fatal("not deleted")
	}
	resp, body := c.get("/api/assets/" + photo + "/thumbnail")
	expect(t, resp, body, http.StatusNotFound)
	resp, body = c.get("/api/collections/trash/buckets/2024-06")
	expect(t, resp, body, http.StatusOK)
	if items := decode[api.TimelineBucket](t, body).Items; len(items) != 1 || items[0].Id.String() != photo {
		t.Fatalf("trash: %s", body)
	}
	resp, body = c.get("/api/collections/trash/assets/" + photo + "/thumbnail")
	expect(t, resp, body, http.StatusOK)
	resp, body = otherUser.get("/api/collections/trash/assets/" + photo + "/thumbnail")
	expect(t, resp, body, http.StatusNotFound)
	if otherUser.bulk(t, "restore", photo) != 0 || otherUser.bulk(t, "purge", photo) != 0 {
		t.Fatal("someone else changed the trash")
	}

	if c.bulk(t, "restore", photo) != 1 {
		t.Fatal("not restored")
	}
	resp, body = c.get("/api/assets/" + photo + "/thumbnail")
	expect(t, resp, body, http.StatusOK)

	// Only what is in the trash can be deleted for good.
	if c.bulk(t, "purge", photo) != 0 {
		t.Fatal("a photo outside the trash was purged")
	}
	if _, err := os.Stat(original); err != nil {
		t.Fatal(err)
	}
	c.bulk(t, "delete", photo)
	if c.bulk(t, "purge", photo) != 1 {
		t.Fatal("not purged")
	}
	if _, err := os.Stat(original); !os.IsNotExist(err) {
		t.Fatalf("the original is still there: %v", err)
	}
	if other, _ := s.assetFile(kept); other == "" {
		t.Fatal("another photo was touched")
	} else if _, err := os.Stat(other); err != nil {
		t.Fatalf("another photo's file was touched: %v", err)
	}

	// After 30 days it goes by itself, and a Live Photo's video goes with it.
	c.bulk(t, "delete", kept)
	video := uploadedID(t, c.upload("v.mov", randomBytes(t, 100), nil))
	if _, err := s.pool.Exec(ctx, `UPDATE assets SET live_photo_of = $1 WHERE id = $2`, kept, video); err != nil {
		t.Fatal(err)
	}
	queries := db.New(s.pool)
	if err := jobs.PurgeExpiredTrash(ctx, queries, s.cache, time.Now()); err != nil {
		t.Fatal(err)
	}
	var left int
	if err := s.pool.QueryRow(ctx, `SELECT count(*) FROM assets WHERE id = $1`, kept).Scan(&left); err != nil || left != 1 {
		t.Fatalf("purged too early: %d, %v", left, err)
	}
	if err := jobs.PurgeExpiredTrash(ctx, queries, s.cache, time.Now().Add(jobs.TrashLifetime+time.Hour)); err != nil {
		t.Fatal(err)
	}
	if err := s.pool.QueryRow(ctx, `SELECT count(*) FROM assets WHERE id = ANY($1::uuid[])`, []string{kept, video}).Scan(&left); err != nil || left != 0 {
		t.Fatalf("%d left after 30 days, %v", left, err)
	}

	// The same file can come back as new.
	again := c.newPhoto(t, "c.jpg", "2024-06-17T10:00:00Z")
	c.bulk(t, "delete", again)
	resp, body = c.post("/api/trash/empty", map[string]any{})
	if changedBy(t, resp, body) != 1 {
		t.Fatalf("empty: %s", body)
	}
}

func TestArchive(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	photo := c.newPhoto(t, "a.jpg", "2024-06-15T10:00:00Z")
	c.bulk(t, "archive", photo)
	if len(c.readBucket("2024-06").Items) != 0 {
		t.Fatal("still on the timeline")
	}
	resp, body := c.get("/api/collections/archive/buckets/2024-06")
	expect(t, resp, body, http.StatusOK)
	if len(decode[api.TimelineBucket](t, body).Items) != 1 {
		t.Fatalf("archive: %s", body)
	}
	c.bulk(t, "unarchive", photo)
	if len(c.readBucket("2024-06").Items) != 1 {
		t.Fatal("not back on the timeline")
	}
}

func TestVaultHidesEverywhere(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	partner := s.user(c, "partner@example.com")
	member := s.user(c, "member@example.com")
	guest := s.client()
	photo := c.newPhoto(t, "secret.jpg", "2024-06-15T10:00:00Z")

	album := c.newAlbum(map[string]any{"title": "Trip"})
	resp, body := c.post("/api/albums/"+album+"/assets", api.AssetIds{Ids: uuids(t, photo)})
	expect(t, resp, body, http.StatusOK)
	resp, body = c.send(http.MethodPut, "/api/albums/"+album+"/members/"+s.userID("member@example.com"), map[string]string{"role": "viewer"})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = c.send(http.MethodPut, "/api/partners/"+s.userID("partner@example.com"), map[string]any{})
	expect(t, resp, body, http.StatusNoContent)
	link := c.newLink(album, map[string]any{})
	smart := c.newAlbum(map[string]any{"title": "All photos", "rules": map[string]any{"kind": "photo"}})

	// No PIN yet: nothing can go in, because nothing could ever get it out.
	resp, body = c.post("/api/assets/bulk", map[string]any{"ids": []string{photo}, "action": "vault"})
	expect(t, resp, body, http.StatusBadRequest)

	resp, body = c.post("/api/vault/pin", map[string]string{"pin": "12"})
	expect(t, resp, body, http.StatusBadRequest)
	resp, body = c.post("/api/vault/pin", map[string]string{"pin": "1234"})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = c.post("/api/vault/pin", map[string]string{"pin": "9999"})
	expect(t, resp, body, http.StatusUnauthorized)

	if c.bulk(t, "vault", photo) != 1 {
		t.Fatal("not moved")
	}

	// Gone from every normal way of looking, also for the owner.
	for _, who := range []*client{c, partner, member} {
		resp, body = who.get("/api/assets/" + photo + "/thumbnail")
		expect(t, resp, body, http.StatusNotFound)
		resp, body = who.get("/api/assets/" + photo + "/original")
		expect(t, resp, body, http.StatusNotFound)
	}
	if len(c.readBucket("2024-06").Items) != 0 {
		t.Fatal("on the timeline")
	}
	resp, body = guest.get(publicPathPrefix + *link.Token + "/assets/" + photo + "/thumbnail")
	expect(t, resp, body, http.StatusNotFound)
	for _, id := range []string{album, smart} {
		resp, body = c.get("/api/albums/" + id)
		expect(t, resp, body, http.StatusOK)
		if decode[api.Album](t, body).AssetCount != 0 {
			t.Fatalf("still counted in an album: %s", body)
		}
	}
	resp, body = partner.get("/api/partners/" + s.userID("admin@example.com") + "/buckets")
	expect(t, resp, body, http.StatusOK)
	if len(decode[api.TimelineBuckets](t, body).Buckets) != 0 {
		t.Fatalf("visible to a partner: %s", body)
	}
	if c.bulk(t, "delete", photo) != 0 || c.bulk(t, "favorite", photo) != 0 {
		t.Fatal("changed through the normal actions")
	}

	// Locked: the vault gives nothing, and nothing comes out.
	for _, path := range []string{"/buckets", "/buckets/2024-06", "/assets/" + photo, "/assets/" + photo + "/thumbnail", "/assets/" + photo + "/original"} {
		resp, body = c.get("/api/collections/vault" + path)
		expect(t, resp, body, http.StatusUnauthorized)
	}
	resp, body = c.post("/api/assets/bulk", map[string]any{"ids": []string{photo}, "action": "unvault"})
	expect(t, resp, body, http.StatusUnauthorized)
	if c.bulk(t, "purge", photo) != 0 {
		t.Fatal("purged while locked")
	}
	resp, body = c.post("/api/vault/unlock", map[string]string{"pin": "0000"})
	expect(t, resp, body, http.StatusUnauthorized)

	resp, body = c.post("/api/vault/unlock", map[string]string{"pin": "1234"})
	expect(t, resp, body, http.StatusOK)
	token := decode[api.VaultSession](t, body).Token
	resp, body = c.get("/api/collections/vault/assets/" + photo + "/thumbnail")
	expect(t, resp, body, http.StatusOK)
	if !strings.Contains(resp.Header.Get("Cache-Control"), "no-store") {
		t.Fatalf("a vault photo may be cached: %q", resp.Header.Get("Cache-Control"))
	}

	// The app sends the token instead of a cookie. Someone else's vault stays closed with it.
	resp, body = partner.do(http.MethodGet, "/api/collections/vault/assets/"+photo+"/thumbnail", map[string]string{vaultTokenHeader: token}, nil)
	expect(t, resp, body, http.StatusUnauthorized)

	resp, body = c.post("/api/vault/lock", map[string]any{})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = c.get("/api/collections/vault/buckets")
	expect(t, resp, body, http.StatusUnauthorized)

	// Coming out restores it where it was.
	resp, body = c.post("/api/vault/unlock", map[string]string{"pin": "1234"})
	expect(t, resp, body, http.StatusOK)
	if c.bulk(t, "unvault", photo) != 1 {
		t.Fatal("not moved out")
	}
	resp, body = member.get("/api/assets/" + photo + "/thumbnail")
	expect(t, resp, body, http.StatusOK)

	// Changing the PIN needs the old one, and locks what was open.
	resp, body = c.post("/api/vault/pin", map[string]string{"pin": "5678", "currentPin": "1234"})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = c.get("/api/collections/vault/buckets")
	expect(t, resp, body, http.StatusUnauthorized)

	// Guessing stops.
	for range vaultPinFailures {
		resp, body = c.post("/api/vault/unlock", map[string]string{"pin": "0000"})
		expect(t, resp, body, http.StatusUnauthorized)
	}
	resp, body = c.post("/api/vault/unlock", map[string]string{"pin": "5678"})
	expect(t, resp, body, http.StatusTooManyRequests)
}

func TestTags(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	other := s.user(c, "other@example.com")
	photo := c.newPhoto(t, "a.jpg", "2024-06-15T10:00:00Z")
	foreign := other.newPhoto(t, "b.jpg", "2024-06-15T10:00:00Z")

	for _, name := range []string{"", "   ", strings.Repeat("x", maxTagLength+1)} {
		resp, body := c.post("/api/assets/tags", map[string]any{"ids": []string{photo}, "name": name})
		expect(t, resp, body, http.StatusBadRequest)
	}
	resp, body := c.post("/api/assets/tags", map[string]any{"ids": []string{photo, foreign}, "name": " Beach "})
	if changedBy(t, resp, body) != 1 {
		t.Fatalf("tagged: %s", body)
	}
	// The same tag in other letters is the same tag.
	resp, body = c.post("/api/assets/tags", map[string]any{"ids": []string{photo}, "name": "beach"})
	if changedBy(t, resp, body) != 0 {
		t.Fatalf("tagged twice: %s", body)
	}
	resp, body = c.get("/api/tags")
	expect(t, resp, body, http.StatusOK)
	tags := decode[[]api.Tag](t, body)
	if len(tags) != 1 || tags[0].Name != "Beach" || tags[0].AssetCount != 1 {
		t.Fatalf("tags: %s", body)
	}
	id := tags[0].Id.String()
	resp, body = c.get("/api/assets/" + photo)
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.AssetDetail](t, body).Tags; got == nil || len(*got) != 1 {
		t.Fatalf("detail: %s", body)
	}
	resp, body = c.get("/api/tags/" + id + "/buckets/2024-06")
	expect(t, resp, body, http.StatusOK)
	if len(decode[api.TimelineBucket](t, body).Items) != 1 {
		t.Fatalf("bucket: %s", body)
	}

	// Tags are private.
	for _, path := range []string{"/api/tags/" + id + "/buckets", "/api/tags/" + id + "/buckets/2024-06"} {
		resp, body = other.get(path)
		expect(t, resp, body, http.StatusNotFound)
	}
	resp, body = other.do(http.MethodDelete, "/api/tags/"+id, nil, nil)
	expect(t, resp, body, http.StatusNotFound)

	resp, body = c.post("/api/assets/tags", map[string]any{"ids": []string{photo}, "name": "BEACH", "remove": true})
	if changedBy(t, resp, body) != 1 {
		t.Fatalf("untagged: %s", body)
	}
	resp, body = c.do(http.MethodDelete, "/api/tags/"+id, nil, nil)
	expect(t, resp, body, http.StatusNoContent)
	resp, body = c.get("/api/assets/" + photo)
	expect(t, resp, body, http.StatusOK)
}

func TestALivePhotosClipFollowsItsPhoto(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	ctx := context.Background()
	link := func() (string, string) {
		t.Helper()
		photo := c.newPhoto(t, "live.heic", "2024-01-01T10:00:00Z")
		video := uploadedID(t, c.upload("live.mov", randomBytes(t, 100), nil))
		if _, err := s.pool.Exec(ctx, `UPDATE assets SET live_photo_of = $1 WHERE id = $2`, photo, video); err != nil {
			t.Fatal(err)
		}
		return photo, video
	}
	state := func(id string) (deleted, archived bool) {
		t.Helper()
		if err := s.pool.QueryRow(ctx, `SELECT deleted_at IS NOT NULL, archived_at IS NOT NULL FROM assets WHERE id = $1`, id).
			Scan(&deleted, &archived); err != nil {
			t.Fatal(err)
		}
		return deleted, archived
	}
	photo, video := link()
	c.bulk(t, "archive", photo)
	if _, archived := state(video); !archived {
		t.Fatal("the clip stayed out of the archive")
	}
	other, clip := link()
	c.bulk(t, "delete", other)
	if deleted, _ := state(clip); !deleted {
		t.Fatal("the clip stayed out of the trash, where a partner could still play it")
	}
}
