package app

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"os"
	"strconv"
	"strings"
	"testing"

	"github.com/google/uuid"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/mmzlopasa/mediarr-app/server/internal/api"
)

func (c *client) send(method, path string, payload any) (*http.Response, []byte) {
	c.s.t.Helper()
	encoded, err := json.Marshal(payload)
	if err != nil {
		c.s.t.Fatal(err)
	}
	return c.do(method, path, map[string]string{"Content-Type": "application/json"}, bytes.NewReader(encoded))
}

func uuids(t *testing.T, ids ...string) []openapi_types.UUID {
	t.Helper()
	out := make([]openapi_types.UUID, len(ids))
	for i, id := range ids {
		parsed, err := uuid.Parse(id)
		if err != nil {
			t.Fatal(err)
		}
		out[i] = parsed
	}
	return out
}

func (s *stack) userID(email string) string {
	s.t.Helper()
	var id string
	if err := s.pool.QueryRow(context.Background(), `SELECT id::text FROM users WHERE email = $1`, email).Scan(&id); err != nil {
		s.t.Fatal(err)
	}
	return id
}

func decode[T any](t *testing.T, body []byte) T {
	t.Helper()
	var out T
	if err := json.Unmarshal(body, &out); err != nil {
		t.Fatalf("%v: %s", err, body)
	}
	return out
}

func (c *client) newAlbum(payload map[string]any) string {
	c.s.t.Helper()
	resp, body := c.post("/api/albums", payload)
	expect(c.s.t, resp, body, http.StatusCreated)
	return decode[api.Album](c.s.t, body).Id.String()
}

// newPhoto uploads a file that the worker would have finished.
func (c *client) newPhoto(t *testing.T, name, takenAt string) string {
	t.Helper()
	id := uploadedID(t, c.upload(name, randomBytes(t, 100), nil))
	c.s.markReady(t, id, takenAt, nil)
	return id
}

func changedBy(t *testing.T, resp *http.Response, body []byte) int64 {
	t.Helper()
	expect(t, resp, body, http.StatusOK)
	return decode[api.BulkResponse](t, body).Changed
}

func TestAlbumRolesAreEnforced(t *testing.T) {
	s := newStack(t)
	owner := s.admin()
	viewer := s.user(owner, "viewer@example.com")
	contributor := s.user(owner, "contributor@example.com")
	editor := s.user(owner, "editor@example.com")
	stranger := s.user(owner, "stranger@example.com")

	album := owner.newAlbum(map[string]any{"title": "Summer"})
	path := "/api/albums/" + album
	photo := owner.newPhoto(t, "a.jpg", "2024-07-01T10:00:00Z")
	resp, body := owner.post(path+"/assets", api.AssetIds{Ids: uuids(t, photo)})
	if changedBy(t, resp, body) != 1 {
		t.Fatal("the owner's photo was not added")
	}
	resp, body = owner.post("/api/assets/bulk", map[string]any{"ids": []string{photo}, "action": "favorite"})
	expect(t, resp, body, http.StatusOK)

	for email, role := range map[string]string{"viewer@example.com": "viewer", "contributor@example.com": "contributor", "editor@example.com": "editor"} {
		resp, body = owner.send(http.MethodPut, path+"/members/"+s.userID(email), map[string]string{"role": role})
		expect(t, resp, body, http.StatusNoContent)
	}

	// A stranger cannot even tell the album or the photo exist.
	for _, url := range []string{path, path + "/buckets", "/api/assets/" + photo, "/api/assets/" + photo + "/thumbnail", "/api/assets/" + photo + "/original"} {
		resp, body = stranger.get(url)
		expect(t, resp, body, http.StatusNotFound)
	}

	// A viewer sees, comments and reacts, and changes nothing.
	resp, body = viewer.get("/api/assets/" + photo + "/thumbnail")
	expect(t, resp, body, http.StatusOK)
	resp, body = viewer.get("/api/assets/" + photo + "/original?download=true")
	expect(t, resp, body, http.StatusOK)
	resp, body = viewer.get("/api/assets/" + photo)
	expect(t, resp, body, http.StatusOK)
	detail := decode[api.AssetDetail](t, body)
	if detail.IsFavorite || detail.IsOwner == nil || *detail.IsOwner {
		t.Fatalf("a viewer sees the owner's private state: %s", body)
	}
	resp, body = viewer.get(path + "/buckets/2024-07")
	expect(t, resp, body, http.StatusOK)
	items := decode[api.TimelineBucket](t, body).Items
	if len(items) != 1 || items[0].IsFavorite || items[0].IsShared == nil || !*items[0].IsShared {
		t.Fatalf("bucket for a viewer: %s", body)
	}
	own := viewer.newPhoto(t, "own.jpg", "2024-07-02T10:00:00Z")
	resp, body = viewer.post(path+"/assets", api.AssetIds{Ids: uuids(t, own)})
	expect(t, resp, body, http.StatusForbidden)
	resp, body = viewer.post(path+"/assets/remove", api.AssetIds{Ids: uuids(t, photo)})
	expect(t, resp, body, http.StatusForbidden)
	resp, body = viewer.send(http.MethodPatch, path, map[string]string{"title": "Mine"})
	expect(t, resp, body, http.StatusForbidden)
	resp, body = viewer.get(path + "/links")
	expect(t, resp, body, http.StatusForbidden)
	resp, body = viewer.post(path+"/comments", map[string]string{"body": "Nice", "assetId": photo})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = viewer.send(http.MethodPut, path+"/assets/"+photo+"/heart", nil)
	expect(t, resp, body, http.StatusNoContent)
	resp, body = viewer.get(path + "/comments?assetId=" + photo)
	expect(t, resp, body, http.StatusOK)
	activity := decode[api.Activity](t, body)
	if len(activity.Comments) != 1 || activity.Hearts != 1 || !activity.Hearted || !activity.Comments[0].CanDelete {
		t.Fatalf("activity: %s", body)
	}
	comment := activity.Comments[0].Id.String()
	resp, body = contributor.do(http.MethodDelete, path+"/comments/"+comment, nil, nil)
	expect(t, resp, body, http.StatusForbidden)
	resp, body = editor.do(http.MethodDelete, path+"/comments/"+comment, nil, nil)
	expect(t, resp, body, http.StatusNoContent)

	// A contributor adds and removes only their own, and cannot pass on what is merely shared.
	added := contributor.newPhoto(t, "b.jpg", "2024-07-03T10:00:00Z")
	resp, body = contributor.post(path+"/assets", api.AssetIds{Ids: uuids(t, added, photo)})
	if changedBy(t, resp, body) != 1 {
		t.Fatalf("contributor added: %s", body)
	}
	resp, body = contributor.post(path+"/assets/remove", api.AssetIds{Ids: uuids(t, photo)})
	if changedBy(t, resp, body) != 0 {
		t.Fatal("a contributor removed someone else's photo")
	}
	resp, body = contributor.send(http.MethodPatch, path, map[string]string{"title": "Mine"})
	expect(t, resp, body, http.StatusForbidden)
	resp, body = contributor.post(path+"/assets/remove", api.AssetIds{Ids: uuids(t, added)})
	if changedBy(t, resp, body) != 1 {
		t.Fatal("a contributor could not remove their own photo")
	}
	resp, body = contributor.post(path+"/assets", api.AssetIds{Ids: uuids(t, added)})
	if changedBy(t, resp, body) != 1 {
		t.Fatal("re-adding failed")
	}

	// An editor manages content, not access. Removing from an album deletes nothing.
	resp, body = editor.post(path+"/assets/remove", api.AssetIds{Ids: uuids(t, added)})
	if changedBy(t, resp, body) != 1 {
		t.Fatal("an editor could not remove a photo")
	}
	resp, body = contributor.get("/api/assets/" + added)
	expect(t, resp, body, http.StatusOK)
	resp, body = editor.send(http.MethodPatch, path, map[string]any{"title": "Holiday", "order": "oldest", "coverAssetId": photo})
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.Album](t, body); got.Title != "Holiday" || got.CoverAssetId.String() != photo {
		t.Fatalf("update: %s", body)
	}
	resp, body = editor.send(http.MethodPatch, path, map[string]any{"coverAssetId": own})
	expect(t, resp, body, http.StatusBadRequest)
	resp, body = editor.do(http.MethodDelete, path, nil, nil)
	expect(t, resp, body, http.StatusForbidden)
	resp, body = editor.send(http.MethodPut, path+"/members/"+s.userID("stranger@example.com"), map[string]string{"role": "viewer"})
	expect(t, resp, body, http.StatusForbidden)
	resp, body = editor.post(path+"/links", map[string]any{})
	expect(t, resp, body, http.StatusForbidden)

	// Photos in the trash leave the album for everyone and come back with it.
	resp, body = owner.post("/api/assets/bulk", map[string]any{"ids": []string{photo}, "action": "delete"})
	expect(t, resp, body, http.StatusOK)
	resp, body = viewer.get("/api/assets/" + photo + "/thumbnail")
	expect(t, resp, body, http.StatusNotFound)
	if _, err := s.pool.Exec(context.Background(), `UPDATE assets SET deleted_at = NULL WHERE id = $1`, photo); err != nil {
		t.Fatal(err)
	}

	// Ending access works at once, also for a file link kept from before.
	resp, body = owner.do(http.MethodDelete, path+"/members/"+s.userID("viewer@example.com"), nil, nil)
	expect(t, resp, body, http.StatusNoContent)
	resp, body = viewer.get("/api/assets/" + photo + "/thumbnail")
	expect(t, resp, body, http.StatusNotFound)
	resp, body = viewer.get(path)
	expect(t, resp, body, http.StatusNotFound)

	// A member can leave, and deleting the album leaves the photos alone.
	resp, body = editor.do(http.MethodDelete, path+"/members/"+s.userID("contributor@example.com"), nil, nil)
	expect(t, resp, body, http.StatusForbidden)
	resp, body = editor.do(http.MethodDelete, path+"/members/"+s.userID("editor@example.com"), nil, nil)
	expect(t, resp, body, http.StatusNoContent)
	resp, body = owner.do(http.MethodDelete, path, nil, nil)
	expect(t, resp, body, http.StatusNoContent)
	resp, body = owner.get("/api/assets/" + photo)
	expect(t, resp, body, http.StatusOK)
}

func TestAlbumOrderAndList(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	empty := c.newAlbum(map[string]any{"title": "b empty"})
	album := c.newAlbum(map[string]any{"title": "A full"})
	older := c.newPhoto(t, "old.jpg", "2020-03-01T10:00:00Z")
	newer := c.newPhoto(t, "new.jpg", "2024-03-01T10:00:00Z")
	sameMonth := c.newPhoto(t, "same.jpg", "2024-03-02T10:00:00Z")
	resp, body := c.post("/api/albums/"+album+"/assets", api.AssetIds{Ids: uuids(t, older, newer, sameMonth)})
	if changedBy(t, resp, body) != 3 {
		t.Fatal("add failed")
	}

	resp, body = c.get("/api/albums?sort=title")
	expect(t, resp, body, http.StatusOK)
	list := decode[[]api.Album](t, body)
	if len(list) != 2 || list[0].Id.String() != album || list[1].Id.String() != empty {
		t.Fatalf("sorted by title: %s", body)
	}
	if list[0].AssetCount != 3 || list[0].CoverAssetId.String() != sameMonth || list[1].CoverAssetId != nil {
		t.Fatalf("count and cover: %s", body)
	}
	resp, body = c.get("/api/albums?sort=date")
	expect(t, resp, body, http.StatusOK)
	if list = decode[[]api.Album](t, body); list[0].Id.String() != album {
		t.Fatalf("sorted by date: %s", body)
	}

	resp, body = c.send(http.MethodPatch, "/api/albums/"+album, map[string]string{"order": "oldest"})
	expect(t, resp, body, http.StatusOK)
	resp, body = c.get("/api/albums/" + album + "/buckets")
	expect(t, resp, body, http.StatusOK)
	buckets := decode[api.TimelineBuckets](t, body).Buckets
	if len(buckets) != 2 || buckets[0].Month != "2020-03" {
		t.Fatalf("oldest first: %s", body)
	}
	resp, body = c.get("/api/albums/" + album + "/buckets/2024-03")
	expect(t, resp, body, http.StatusOK)
	if items := decode[api.TimelineBucket](t, body).Items; items[0].Id.String() != newer {
		t.Fatalf("oldest first inside a month: %s", body)
	}

	for _, title := range []string{"", "   ", strings.Repeat("x", maxAlbumTitle+1)} {
		resp, body = c.post("/api/albums", map[string]string{"title": title})
		expect(t, resp, body, http.StatusBadRequest)
	}
}

func TestUploadStraightIntoAnAlbum(t *testing.T) {
	s := newStack(t)
	owner := s.admin()
	contributor := s.user(owner, "contributor@example.com")
	viewer := s.user(owner, "viewer@example.com")
	album := owner.newAlbum(map[string]any{"title": "Event"})
	for email, role := range map[string]string{"contributor@example.com": "contributor", "viewer@example.com": "viewer"} {
		resp, body := owner.send(http.MethodPut, "/api/albums/"+album+"/members/"+s.userID(email), map[string]string{"role": role})
		expect(t, resp, body, http.StatusNoContent)
	}
	id := uploadedID(t, contributor.upload("c.jpg", randomBytes(t, 100), map[string]string{"albumId": album}))
	s.markReady(t, id, "2024-05-01T10:00:00Z", nil)
	resp, body := owner.get("/api/albums/" + album)
	expect(t, resp, body, http.StatusOK)
	if decode[api.Album](t, body).AssetCount != 1 {
		t.Fatalf("not in the album: %s", body)
	}
	resp, body = viewer.createUpload(10, map[string]string{"filename": "v.jpg", "albumId": album})
	expect(t, resp, body, http.StatusForbidden)
	resp, body = viewer.createUpload(10, map[string]string{"filename": "v.jpg", "albumId": "00000000-0000-0000-0000-000000000000"})
	expect(t, resp, body, http.StatusForbidden)
}

func TestSmartAlbum(t *testing.T) {
	s := newStack(t)
	owner := s.admin()
	member := s.user(owner, "member@example.com")
	ctx := context.Background()
	match := owner.newPhoto(t, "match.jpg", "2024-06-15T10:00:00Z")
	wrongCamera := owner.newPhoto(t, "camera.jpg", "2024-06-15T11:00:00Z")
	tooOld := owner.newPhoto(t, "old.jpg", "2019-06-15T11:00:00Z")
	notMine := member.newPhoto(t, "mine.jpg", "2024-06-16T11:00:00Z")
	for id, model := range map[string]string{match: "iPhone 15", wrongCamera: "Pixel 8", tooOld: "iPhone 15", notMine: "iPhone 15"} {
		if _, err := s.pool.Exec(ctx, `INSERT INTO exif (asset_id, make, model, raw) VALUES ($1, 'Acme', $2, '{}')`, id, model); err != nil {
			t.Fatal(err)
		}
	}

	resp, body := owner.post("/api/albums", map[string]any{"title": "Nothing", "rules": map[string]any{}})
	expect(t, resp, body, http.StatusBadRequest)
	resp, body = owner.post("/api/albums", map[string]any{"title": "Backwards", "rules": map[string]any{"from": "2024-02-01", "to": "2024-01-01"}})
	expect(t, resp, body, http.StatusBadRequest)

	album := owner.newAlbum(map[string]any{"title": "Phone", "rules": map[string]any{"from": "2024-01-01", "to": "2024-12-31", "camera": "acme iphone 15", "kind": "photo"}})
	path := "/api/albums/" + album
	resp, body = owner.get(path + "/buckets/2024-06")
	expect(t, resp, body, http.StatusOK)
	items := decode[api.TimelineBucket](t, body).Items
	if len(items) != 1 || items[0].Id.String() != match {
		t.Fatalf("matched: %s", body)
	}
	resp, body = owner.post(path+"/assets", api.AssetIds{Ids: uuids(t, wrongCamera)})
	expect(t, resp, body, http.StatusConflict)

	// Sharing it shows what matches, and only that.
	resp, body = owner.send(http.MethodPut, path+"/members/"+s.userID("member@example.com"), map[string]string{"role": "viewer"})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = member.get("/api/assets/" + match + "/thumbnail")
	expect(t, resp, body, http.StatusOK)
	resp, body = member.get("/api/assets/" + wrongCamera + "/thumbnail")
	expect(t, resp, body, http.StatusNotFound)

	// A new photo appears by itself, and the two definitions of an album's content agree.
	later := owner.newPhoto(t, "later.jpg", "2024-08-01T10:00:00Z")
	if _, err := s.pool.Exec(ctx, `INSERT INTO exif (asset_id, make, model, raw) VALUES ($1, 'Acme', 'iPhone 15', '{}')`, later); err != nil {
		t.Fatal(err)
	}
	resp, body = member.get("/api/assets/" + later + "/thumbnail")
	expect(t, resp, body, http.StatusOK)
	var disagree int
	if err := s.pool.QueryRow(ctx, `SELECT count(*) FROM assets a CROSS JOIN albums al
		WHERE a.live_photo_of IS NULL AND album_has_asset(al.id, a.id) <> (a.id IN (SELECT album_item_ids(al.id)))`).Scan(&disagree); err != nil {
		t.Fatal(err)
	}
	if disagree != 0 {
		t.Fatalf("album_has_asset and album_item_ids disagree on %d assets", disagree)
	}
}

func TestPartnerSharing(t *testing.T) {
	s := newStack(t)
	owner := s.admin()
	partner := s.user(owner, "partner@example.com")
	recent := owner.newPhoto(t, "recent.jpg", "2024-06-15T10:00:00Z")
	old := owner.newPhoto(t, "old.jpg", "2019-06-15T10:00:00Z")
	archived := owner.newPhoto(t, "archived.jpg", "2024-06-16T10:00:00Z")
	resp, body := owner.post("/api/assets/bulk", map[string]any{"ids": []string{archived}, "action": "archive"})
	expect(t, resp, body, http.StatusOK)
	ownerID := s.userID("admin@example.com")
	partnerID := s.userID("partner@example.com")

	resp, body = partner.get("/api/assets/" + recent)
	expect(t, resp, body, http.StatusNotFound)
	resp, body = partner.get("/api/partners/" + ownerID + "/buckets")
	expect(t, resp, body, http.StatusNotFound)
	resp, body = owner.send(http.MethodPut, "/api/partners/"+ownerID, map[string]any{})
	expect(t, resp, body, http.StatusBadRequest)

	resp, body = owner.send(http.MethodPut, "/api/partners/"+partnerID, map[string]string{"since": "2024-01-01"})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = partner.get("/api/partners")
	expect(t, resp, body, http.StatusOK)
	partners := decode[api.Partners](t, body)
	if len(partners.Received) != 1 || partners.Received[0].InTimeline || partners.Received[0].Since.Format("2006-01-02") != "2024-01-01" {
		t.Fatalf("partners: %s", body)
	}

	resp, body = partner.get("/api/assets/" + recent + "/thumbnail")
	expect(t, resp, body, http.StatusOK)
	for _, hidden := range []string{old, archived} {
		resp, body = partner.get("/api/assets/" + hidden + "/thumbnail")
		expect(t, resp, body, http.StatusNotFound)
	}
	resp, body = partner.get("/api/partners/" + ownerID + "/buckets")
	expect(t, resp, body, http.StatusOK)
	if buckets := decode[api.TimelineBuckets](t, body).Buckets; len(buckets) != 1 || buckets[0].Count != 1 {
		t.Fatalf("buckets: %s", body)
	}
	resp, body = partner.get("/api/partners/" + ownerID + "/buckets/2019-06")
	expect(t, resp, body, http.StatusOK)
	if items := decode[api.TimelineBucket](t, body).Items; len(items) != 0 {
		t.Fatalf("before the date: %s", body)
	}

	// One way only: the partner's own library stays private.
	mine := partner.newPhoto(t, "mine.jpg", "2024-06-20T10:00:00Z")
	resp, body = owner.get("/api/assets/" + mine)
	expect(t, resp, body, http.StatusNotFound)
	resp, body = owner.get("/api/partners/" + partnerID + "/buckets")
	expect(t, resp, body, http.StatusNotFound)

	// In the timeline only when the partner chooses, and still read-only.
	if got := partner.readBucket("2024-06").Items; len(got) != 1 {
		t.Fatalf("before opting in: %v", got)
	}
	resp, body = partner.send(http.MethodPut, "/api/partners/"+ownerID+"/timeline", map[string]bool{"show": true})
	expect(t, resp, body, http.StatusNoContent)
	got := partner.readBucket("2024-06").Items
	if len(got) != 2 {
		t.Fatalf("after opting in: %v", got)
	}
	for _, item := range got {
		if (item.Id.String() == recent) != (item.IsShared != nil && *item.IsShared) {
			t.Fatalf("shared flag: %+v", item)
		}
	}
	resp, body = partner.post("/api/assets/bulk", map[string]any{"ids": []string{recent}, "action": "delete"})
	if changedBy(t, resp, body) != 0 {
		t.Fatal("a partner deleted the owner's photo")
	}

	resp, body = owner.do(http.MethodDelete, "/api/partners/"+partnerID, nil, nil)
	expect(t, resp, body, http.StatusNoContent)
	resp, body = partner.get("/api/assets/" + recent + "/thumbnail")
	expect(t, resp, body, http.StatusNotFound)
	if got := partner.readBucket("2024-06").Items; len(got) != 1 {
		t.Fatalf("after stopping: %v", got)
	}
}

// guestUpload sends a whole file the way a guest's browser does.
func (s *stack) guestUpload(c *client, token, name string, data []byte) (*http.Response, []byte) {
	s.t.Helper()
	return c.do(http.MethodPost, publicPathPrefix+token+"/uploads", map[string]string{
		"Tus-Resumable":   "1.0.0",
		"Upload-Length":   strconv.Itoa(len(data)),
		"Upload-Metadata": tusMeta(map[string]string{"filename": name}),
		"Content-Type":    "application/offset+octet-stream",
	}, bytes.NewReader(data))
}

func (c *client) newLink(album string, payload map[string]any) api.ShareLink {
	c.s.t.Helper()
	resp, body := c.post("/api/albums/"+album+"/links", payload)
	expect(c.s.t, resp, body, http.StatusCreated)
	return decode[api.ShareLink](c.s.t, body)
}

func TestPublicLinkShowsOnlyItsAlbum(t *testing.T) {
	s := newStack(t)
	owner := s.admin()
	guest := s.client()
	ctx := context.Background()
	album := owner.newAlbum(map[string]any{"title": "Trip", "description": "Lovely"})
	shared := owner.newPhoto(t, "shared.jpg", "2024-06-15T10:00:00Z")
	private := owner.newPhoto(t, "private.jpg", "2024-06-16T10:00:00Z")
	if _, err := s.pool.Exec(ctx, `INSERT INTO exif (asset_id, latitude, longitude, raw) VALUES ($1, 45.8, 16.0, '{}')`, shared); err != nil {
		t.Fatal(err)
	}
	resp, body := owner.post("/api/albums/"+album+"/assets", api.AssetIds{Ids: uuids(t, shared)})
	expect(t, resp, body, http.StatusOK)

	link := owner.newLink(album, map[string]any{"label": "Family", "downloadLimit": 1})
	if link.Token == nil || *link.Token == "" {
		t.Fatal("no token on creation")
	}
	token := *link.Token
	base := publicPathPrefix + token

	// The token is shown once and is not kept in readable form.
	resp, body = owner.get("/api/albums/" + album + "/links")
	expect(t, resp, body, http.StatusOK)
	if strings.Contains(string(body), token) || decode[[]api.ShareLink](t, body)[0].Token != nil {
		t.Fatalf("the token is shown again: %s", body)
	}

	resp, body = guest.get(publicPathPrefix + "wrong-token")
	expect(t, resp, body, http.StatusNotFound)
	resp, body = guest.get(base)
	expect(t, resp, body, http.StatusOK)
	info := decode[api.PublicLink](t, body)
	if info.Locked || *info.Title != "Trip" || !info.AllowDownload || info.AllowUpload {
		t.Fatalf("info: %s", body)
	}
	if strings.Contains(string(body), "admin") || strings.Contains(string(body), "Admin") {
		t.Fatalf("account details are shown: %s", body)
	}

	resp, body = guest.get(base + "/buckets/2024-06")
	expect(t, resp, body, http.StatusOK)
	if items := decode[api.TimelineBucket](t, body).Items; len(items) != 1 || items[0].Id.String() != shared {
		t.Fatalf("items: %s", body)
	}
	resp, body = guest.get(base + "/assets/" + shared)
	expect(t, resp, body, http.StatusOK)
	detail := decode[api.AssetDetail](t, body)
	if detail.Latitude != nil || detail.Longitude != nil || detail.IsOwner == nil || *detail.IsOwner {
		t.Fatalf("detail: %s", body)
	}
	resp, body = guest.get(base + "/assets/" + shared + "/thumbnail")
	expect(t, resp, body, http.StatusOK)

	// Nothing outside the album, whichever way it is asked for.
	for _, path := range []string{"/assets/" + private, "/assets/" + private + "/thumbnail", "/assets/" + private + "/original?download=true", "/assets/" + private + "/motion", "/assets/" + private + "/video/master.m3u8"} {
		resp, body = guest.get(base + path)
		expect(t, resp, body, http.StatusNotFound)
	}
	// The link gives no access to the normal API.
	resp, body = guest.get("/api/assets/" + shared + "/thumbnail")
	expect(t, resp, body, http.StatusUnauthorized)
	resp, body = guest.get("/api/albums/" + album)
	expect(t, resp, body, http.StatusUnauthorized)
	// This link does not receive files, and a photo cannot be viewed as if it were a playable video.
	resp, body = s.guestUpload(guest, token, "x.jpg", randomBytes(t, 50))
	expect(t, resp, body, http.StatusForbidden)
	resp, body = guest.get(base + "/assets/" + shared + "/original")
	expect(t, resp, body, http.StatusForbidden)

	// A real picture, because the location is taken out of what a guest downloads.
	var stored string
	if err := s.pool.QueryRow(context.Background(), "SELECT original_path FROM assets WHERE id=$1", shared).Scan(&stored); err != nil {
		t.Fatal(err)
	}
	// Originals are read-only, so it takes the place of the file.
	if err := os.Remove(stored); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(stored, landscapeJPEG(t), 0o600); err != nil {
		t.Fatal(err)
	}
	// The limit holds: one download, then none.
	resp, body = guest.get(base + "/assets/" + shared + "/original?download=true")
	expect(t, resp, body, http.StatusOK)
	resp, body = guest.get(base + "/assets/" + shared + "/original?download=true")
	expect(t, resp, body, http.StatusForbidden)
	// Asking for a part of the file does not get around it.
	resp, body = guest.do(http.MethodGet, base+"/assets/"+shared+"/original?download=true", map[string]string{"Range": "bytes=1-"}, nil)
	expect(t, resp, body, http.StatusForbidden)
	resp, body = guest.get(base + "/assets/" + shared)
	expect(t, resp, body, http.StatusOK)
	if allowed := decode[api.AssetDetail](t, body).DownloadAllowed; allowed == nil || *allowed {
		t.Fatalf("downloads left: %s", body)
	}

	// An expired link and a revoked link are simply gone.
	if _, err := s.pool.Exec(ctx, `UPDATE share_links SET expires_at = now() - interval '1 minute' WHERE id = $1`, link.Id); err != nil {
		t.Fatal(err)
	}
	resp, body = guest.get(base + "/assets/" + shared + "/thumbnail")
	expect(t, resp, body, http.StatusNotFound)
	if _, err := s.pool.Exec(ctx, `UPDATE share_links SET expires_at = NULL WHERE id = $1`, link.Id); err != nil {
		t.Fatal(err)
	}
	resp, body = owner.do(http.MethodDelete, "/api/albums/"+album+"/links/"+link.Id.String(), nil, nil)
	expect(t, resp, body, http.StatusNoContent)
	resp, body = guest.get(base)
	expect(t, resp, body, http.StatusNotFound)

	resp, body = owner.post("/api/albums/"+album+"/links", map[string]any{"expiresAt": "2001-01-01T00:00:00Z"})
	expect(t, resp, body, http.StatusBadRequest)
	withLocation := owner.newLink(album, map[string]any{"showLocation": true})
	resp, body = guest.get(publicPathPrefix + *withLocation.Token + "/assets/" + shared)
	expect(t, resp, body, http.StatusOK)
	if decode[api.AssetDetail](t, body).Latitude == nil {
		t.Fatalf("location was asked for: %s", body)
	}
}

func TestPublicLinkPassword(t *testing.T) {
	s := newStack(t)
	owner := s.admin()
	guest := s.client()
	album := owner.newAlbum(map[string]any{"title": "Secret title"})
	photo := owner.newPhoto(t, "a.jpg", "2024-06-15T10:00:00Z")
	resp, body := owner.post("/api/albums/"+album+"/assets", api.AssetIds{Ids: uuids(t, photo)})
	expect(t, resp, body, http.StatusOK)
	link := owner.newLink(album, map[string]any{"password": "open sesame", "allowUpload": true})
	base := publicPathPrefix + *link.Token

	resp, body = guest.get(base)
	expect(t, resp, body, http.StatusOK)
	if !decode[api.PublicLink](t, body).Locked || strings.Contains(string(body), "Secret") {
		t.Fatalf("a locked link tells too much: %s", body)
	}
	for _, path := range []string{"/buckets", "/buckets/2024-06", "/assets/" + photo, "/assets/" + photo + "/thumbnail", "/assets/" + photo + "/original?download=true"} {
		resp, body = guest.get(base + path)
		expect(t, resp, body, http.StatusUnauthorized)
	}
	resp, body = s.guestUpload(guest, *link.Token, "x.jpg", randomBytes(t, 50))
	expect(t, resp, body, http.StatusUnauthorized)

	resp, body = guest.post(base+"/unlock", api.LinkPassword{Password: "wrong"})
	expect(t, resp, body, http.StatusUnauthorized)
	resp, body = guest.post(base+"/unlock", api.LinkPassword{Password: "open sesame"})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = guest.get(base + "/assets/" + photo + "/thumbnail")
	expect(t, resp, body, http.StatusOK)

	// The cookie opens this link only.
	other := owner.newLink(album, map[string]any{"password": "something else"})
	resp, body = guest.get(publicPathPrefix + *other.Token + "/buckets")
	expect(t, resp, body, http.StatusUnauthorized)

	attacker := s.client()
	for range linkPasswordFailures {
		resp, body = attacker.post(publicPathPrefix+*other.Token+"/unlock", api.LinkPassword{Password: "guess"})
		expect(t, resp, body, http.StatusUnauthorized)
	}
	resp, body = attacker.post(publicPathPrefix+*other.Token+"/unlock", api.LinkPassword{Password: "something else"})
	expect(t, resp, body, http.StatusTooManyRequests)
}

func TestPublicLinkUploadOnly(t *testing.T) {
	s := newStack(t)
	owner := s.admin()
	guest := s.client()
	ctx := context.Background()
	album := owner.newAlbum(map[string]any{"title": "Wedding"})
	existing := owner.newPhoto(t, "before.jpg", "2024-06-15T10:00:00Z")
	resp, body := owner.post("/api/albums/"+album+"/assets", api.AssetIds{Ids: uuids(t, existing)})
	expect(t, resp, body, http.StatusOK)
	link := owner.newLink(album, map[string]any{"uploadOnly": true})
	token := *link.Token
	base := publicPathPrefix + token
	if !link.AllowUpload || link.AllowDownload {
		t.Fatalf("upload-only link: %+v", link)
	}

	// The guest sees nothing of the album.
	resp, body = guest.get(base)
	expect(t, resp, body, http.StatusOK)
	if info := decode[api.PublicLink](t, body); !info.UploadOnly {
		t.Fatalf("info: %s", body)
	}
	for _, path := range []string{"/buckets", "/buckets/2024-06", "/assets/" + existing, "/assets/" + existing + "/thumbnail", "/assets/" + existing + "/original?download=true"} {
		resp, body = guest.get(base + path)
		expect(t, resp, body, http.StatusForbidden)
	}

	data := randomBytes(t, 200)
	resp, body = s.guestUpload(guest, token, "guest.jpg", data)
	expect(t, resp, body, http.StatusCreated)
	if resp.Header.Get("X-Asset-Id") != "" || resp.Header.Get("X-Asset-Duplicate") != "" {
		t.Fatal("a guest learned about the owner's library")
	}
	var id, ownerID string
	if err := s.pool.QueryRow(ctx, `SELECT a.id::text, a.user_id::text FROM assets a WHERE a.original_name = 'guest.jpg'`).Scan(&id, &ownerID); err != nil {
		t.Fatal(err)
	}
	if ownerID != s.userID("admin@example.com") {
		t.Fatal("the upload does not belong to the album's owner")
	}
	s.markReady(t, id, "2024-06-20T10:00:00Z", nil)
	resp, body = owner.get("/api/albums/" + album)
	expect(t, resp, body, http.StatusOK)
	if decode[api.Album](t, body).AssetCount != 2 {
		t.Fatalf("not in the album: %s", body)
	}

	// The same file again is not stored twice, and answers the same.
	resp, body = s.guestUpload(guest, token, "guest-again.jpg", data)
	expect(t, resp, body, http.StatusCreated)
	if resp.Header.Get("X-Asset-Duplicate") != "" {
		t.Fatal("a guest learned about a duplicate")
	}
	var count int
	if err := s.pool.QueryRow(ctx, `SELECT count(*) FROM assets WHERE original_name LIKE 'guest%'`).Scan(&count); err != nil {
		t.Fatal(err)
	}
	if count != 1 {
		t.Fatalf("%d copies", count)
	}

	// A guest cannot bring back what the owner deleted.
	resp, body = owner.post("/api/assets/bulk", map[string]any{"ids": []string{id}, "action": "delete"})
	expect(t, resp, body, http.StatusOK)
	resp, body = s.guestUpload(guest, token, "guest.jpg", data)
	expect(t, resp, body, http.StatusCreated)
	resp, body = owner.get("/api/assets/" + id)
	expect(t, resp, body, http.StatusNotFound)

	// Part of a file is refused, and a smart album cannot receive anything.
	resp, body = guest.do(http.MethodPost, base+"/uploads", map[string]string{
		"Tus-Resumable": "1.0.0", "Upload-Length": "1000", "Content-Type": "application/offset+octet-stream",
	}, bytes.NewReader(data))
	expect(t, resp, body, http.StatusBadRequest)
	smart := owner.newAlbum(map[string]any{"title": "Smart", "rules": map[string]any{"kind": "photo"}})
	resp, body = owner.post("/api/albums/"+smart+"/links", map[string]any{"allowUpload": true})
	expect(t, resp, body, http.StatusBadRequest)
}

func TestWatermarkedLinkGivesNoOriginals(t *testing.T) {
	s := newStack(t)
	owner := s.admin()
	guest := s.client()
	album := owner.newAlbum(map[string]any{"title": "Proofs"})
	photo := owner.newPhoto(t, "a.jpg", "2024-06-15T10:00:00Z")
	resp, body := owner.post("/api/albums/"+album+"/assets", api.AssetIds{Ids: uuids(t, photo)})
	expect(t, resp, body, http.StatusOK)
	link := owner.newLink(album, map[string]any{"watermark": "© Studio", "allowDownload": true})
	if link.AllowDownload {
		t.Fatal("a watermark must turn downloads off")
	}
	base := publicPathPrefix + *link.Token
	resp, body = guest.get(base)
	expect(t, resp, body, http.StatusOK)
	if info := decode[api.PublicLink](t, body); !info.Watermarked || info.AllowDownload {
		t.Fatalf("info: %s", body)
	}
	for _, path := range []string{"/original?download=true", "/original", "/motion", "/video/master.m3u8"} {
		resp, body = guest.get(base + "/assets/" + photo + path)
		expect(t, resp, body, http.StatusForbidden)
	}
	resp, body = guest.get(base + "/assets/" + photo)
	expect(t, resp, body, http.StatusOK)
	if detail := decode[api.AssetDetail](t, body); detail.DownloadAllowed == nil || *detail.DownloadAllowed {
		t.Fatalf("detail: %s", body)
	}
}
