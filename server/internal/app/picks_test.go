package app

import (
	"context"
	"fmt"
	"net/http"
	"testing"

	"github.com/google/uuid"

	"github.com/mediarr-app/mediarr/server/internal/api"
)

func pickBody(t *testing.T, pick int, ids ...string) api.PickRequest {
	t.Helper()
	body := api.PickRequest{Pick: pick}
	for _, id := range ids {
		body.Ids = append(body.Ids, uuid.MustParse(id))
	}
	return body
}

func TestPickFilterReadsTheMark(t *testing.T) {
	if got, ok := pickFilter(nil); !ok || got.Valid {
		t.Fatalf("no mark: %v %v", got, ok)
	}
	for _, bad := range []int{-2, 2} {
		if _, ok := pickFilter(&bad); ok {
			t.Errorf("%d was accepted", bad)
		}
	}
	zero := 0
	if got, ok := pickFilter(&zero); !ok || !got.Valid || got.Int16 != 0 {
		t.Fatalf("unmarked: %v %v", got, ok)
	}
}

func TestOnlyTheOwnerMarksAPhoto(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	stranger := s.user(c, "stranger@example.com")
	id := c.newPhoto(t, "1.jpg", "2024-01-01T10:00:00Z")

	resp, body := c.send(http.MethodPost, "/api/assets/pick", pickBody(t, 2, id))
	expect(t, resp, body, http.StatusBadRequest)
	resp, body = c.send(http.MethodPost, "/api/assets/pick", api.PickRequest{Pick: 1})
	expect(t, resp, body, http.StatusBadRequest)

	resp, body = stranger.send(http.MethodPost, "/api/assets/pick", pickBody(t, -1, id))
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.BulkResponse](t, body).Changed; got != 0 {
		t.Fatalf("a stranger changed %d", got)
	}
	resp, body = stranger.send(http.MethodPost, "/api/assets/pick/read", api.AssetIds{Ids: []uuid.UUID{uuid.MustParse(id)}})
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.PickStates](t, body).Items; len(got) != 0 {
		t.Fatalf("a stranger read %v", got)
	}

	var before int
	ctx := context.Background()
	const sidecarJobs = `SELECT count(*) FROM river_job WHERE kind = 'sidecar' AND args->>'asset_id' = $1`
	if err := s.pool.QueryRow(ctx, sidecarJobs, id).Scan(&before); err != nil {
		t.Fatal(err)
	}
	resp, body = c.send(http.MethodPost, "/api/assets/pick", pickBody(t, 1, id))
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.BulkResponse](t, body).Changed; got != 1 {
		t.Fatalf("changed %d", got)
	}
	var after int
	if err := s.pool.QueryRow(ctx, sidecarJobs, id).Scan(&after); err != nil {
		t.Fatal(err)
	}
	if after != before+1 {
		t.Fatalf("sidecar jobs: %d, then %d", before, after)
	}
	resp, body = c.send(http.MethodPost, "/api/assets/pick/read", api.AssetIds{Ids: []uuid.UUID{uuid.MustParse(id)}})
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.PickStates](t, body).Items; len(got) != 1 || got[0].Pick != 1 {
		t.Fatalf("read %v", got)
	}
}

func TestSearchAndAlbumsFilterByMark(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	picked := c.newPhoto(t, "picked.jpg", "2024-01-01T10:00:00Z")
	rejected := c.newPhoto(t, "rejected.jpg", "2024-01-01T11:00:00Z")
	plain := c.newPhoto(t, "plain.jpg", "2024-01-01T12:00:00Z")
	for mark, id := range map[int]string{1: picked, -1: rejected} {
		resp, body := c.send(http.MethodPost, "/api/assets/pick", pickBody(t, mark, id))
		expect(t, resp, body, http.StatusOK)
	}
	cases := map[int]string{1: picked, -1: rejected, 0: plain}
	for mark, want := range cases {
		resp, body := c.get(fmt.Sprintf("/api/search?pick=%d", mark))
		expect(t, resp, body, http.StatusOK)
		items := decode[api.SearchResult](t, body).Items
		if len(items) != 1 || items[0].Id.String() != want {
			t.Errorf("search for %d: %s", mark, body)
		}
	}
	resp, body := c.get("/api/search?pick=5")
	expect(t, resp, body, http.StatusBadRequest)

	album := c.newAlbum(map[string]any{"title": "Shoot"})
	resp, body = c.post("/api/albums/"+album+"/assets", api.AssetIds{Ids: uuids(t, picked, rejected, plain)})
	expect(t, resp, body, http.StatusOK)

	resp, body = c.get("/api/albums/" + album + "/buckets?pick=1")
	expect(t, resp, body, http.StatusOK)
	buckets := decode[api.TimelineBuckets](t, body).Buckets
	if len(buckets) != 1 || buckets[0].Count != 1 {
		t.Fatalf("buckets: %s", body)
	}
	resp, body = c.get("/api/albums/" + album + "/buckets/2024-01?pick=-1")
	expect(t, resp, body, http.StatusOK)
	items := decode[api.TimelineBucket](t, body).Items
	if len(items) != 1 || items[0].Id.String() != rejected {
		t.Fatalf("bucket: %s", body)
	}
	resp, body = c.get("/api/albums/" + album + "/buckets?pick=9")
	expect(t, resp, body, http.StatusBadRequest)

	// A member of a shared album does not learn what the owner rejected.
	member := s.user(c, "member@example.com")
	resp, body = c.send(http.MethodPut, "/api/albums/"+album+"/members/"+s.userID("member@example.com"), map[string]string{"role": "viewer"})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = member.get("/api/albums/" + album + "/buckets?pick=-1")
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.TimelineBuckets](t, body).Buckets; len(got) != 0 {
		t.Fatalf("a member saw the owner's marks: %s", body)
	}
}
