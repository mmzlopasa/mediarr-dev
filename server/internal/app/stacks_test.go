package app

import (
	"context"
	"net/http"
	"testing"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

func (s *stack) organize(t *testing.T) {
	t.Helper()
	if err := jobs.Organize(context.Background(), s.pool, db.New(s.pool)); err != nil {
		t.Fatal(err)
	}
}

// burst uploads three frames of one camera, the second the sharpest.
func (s *stack) burst(t *testing.T, c *client) (a, b, third string) {
	t.Helper()
	ctx := context.Background()
	ids := make([]string, 3)
	for i, second := range []string{"00", "01", "02"} {
		ids[i] = c.newPhoto(t, "frame"+second+".jpg", "2024-07-01T10:00:"+second+"Z")
		if _, err := s.pool.Exec(ctx, `INSERT INTO exif (asset_id, make, model, raw) VALUES ($1, 'Canon', 'R5', '{}')`, ids[i]); err != nil {
			t.Fatal(err)
		}
		sharpness := []int{1, 9, 3}[i]
		// Far apart, so the frames do not count as duplicates of each other here.
		if _, err := s.pool.Exec(ctx, `UPDATE assets SET sharpness=$2, phash=$3 WHERE id=$1`, ids[i], sharpness, []int64{0, 0x0F0F0F0F, -1}[i]); err != nil {
			t.Fatal(err)
		}
	}
	s.organize(t)
	return ids[0], ids[1], ids[2]
}

func timelineIDs(t *testing.T, c *client) map[string]api.TimelineItem {
	t.Helper()
	resp, body := c.get("/api/timeline/buckets/2024-07")
	expect(t, resp, body, http.StatusOK)
	out := map[string]api.TimelineItem{}
	for _, item := range decode[api.TimelineBucket](t, body).Items {
		out[item.Id.String()] = item
	}
	return out
}

func stackIDs(t *testing.T, c *client, id string) []string {
	t.Helper()
	resp, body := c.get("/api/assets/" + id)
	expect(t, resp, body, http.StatusOK)
	detail := decode[api.AssetDetail](t, body)
	if detail.Stack == nil {
		return nil
	}
	out := []string{}
	for _, shot := range *detail.Stack {
		out = append(out, shot.String())
	}
	return out
}

func TestBurstBecomesAStack(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	a, sharpest, third := s.burst(t, c)

	items := timelineIDs(t, c)
	if len(items) != 1 {
		t.Fatalf("the timeline shows only the main shot: %v", items)
	}
	main, ok := items[sharpest]
	if !ok || main.StackSize == nil || *main.StackSize != 3 {
		t.Fatalf("main: %+v", items)
	}
	// The hidden shots can still be opened, and the stack lists all of them.
	got := stackIDs(t, c, a)
	if len(got) != 3 || got[0] != sharpest {
		t.Fatalf("stack: %v", got)
	}
	// A hidden shot is not on the months' counts either.
	resp, body := c.get("/api/timeline/buckets")
	expect(t, resp, body, http.StatusOK)
	if buckets := decode[api.TimelineBuckets](t, body).Buckets; len(buckets) != 1 || buckets[0].Count != 1 {
		t.Fatalf("buckets: %s", body)
	}

	// Choosing another shot sticks, also after the next look through the photos.
	resp, body = c.do(http.MethodPut, "/api/assets/"+third+"/stack/main", nil, nil)
	expect(t, resp, body, http.StatusNoContent)
	s.organize(t)
	if _, ok := timelineIDs(t, c)[third]; !ok {
		t.Fatal("the chosen shot should lead")
	}
	late := c.newPhoto(t, "late.jpg", "2024-07-01T10:00:03Z")
	if _, err := s.pool.Exec(context.Background(), `INSERT INTO exif (asset_id, make, model, raw) VALUES ($1, 'Canon', 'R5', '{}')`, late); err != nil {
		t.Fatal(err)
	}
	s.organize(t)
	items = timelineIDs(t, c)
	if _, ok := items[third]; !ok || len(items) != 1 || *items[third].StackSize != 4 {
		t.Fatalf("a late frame joins the stack: %+v", items)
	}

	// Splitting brings all back, and they stay apart.
	resp, body = c.do(http.MethodDelete, "/api/assets/"+a+"/stack", nil, nil)
	expect(t, resp, body, http.StatusNoContent)
	if _, err := s.pool.Exec(context.Background(), `UPDATE assets SET organized_at=NULL`); err != nil {
		t.Fatal(err)
	}
	s.organize(t)
	if items := timelineIDs(t, c); len(items) != 4 {
		t.Fatalf("after splitting: %+v", items)
	}
	resp, body = c.do(http.MethodDelete, "/api/assets/"+a+"/stack", nil, nil)
	expect(t, resp, body, http.StatusNotFound)
}

func TestNothingStaysHiddenBehindARemovedShot(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	a, sharpest, third := s.burst(t, c)

	// The main shot goes to the trash: the next sharpest takes over, the third stays behind it.
	c.bulk(t, "delete", sharpest)
	items := timelineIDs(t, c)
	if main, ok := items[third]; !ok || len(items) != 1 || *main.StackSize != 2 {
		t.Fatalf("after deleting the main shot: %+v", items)
	}
	// Coming back, it stands on its own.
	c.bulk(t, "restore", sharpest)
	if items := timelineIDs(t, c); len(items) != 2 {
		t.Fatalf("after restoring: %+v", items)
	}
	// A stack of one is no stack.
	c.bulk(t, "archive", a)
	items = timelineIDs(t, c)
	if len(items) != 2 || items[third].StackSize != nil {
		t.Fatalf("after archiving: %+v", items)
	}
}

func TestDeletingAWholeStackAtOnce(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	a, b, third := s.burst(t, c)
	c.bulk(t, "delete", a, b, third)
	if items := timelineIDs(t, c); len(items) != 0 {
		t.Fatalf("%+v", items)
	}
	c.bulk(t, "restore", a, b, third)
	if items := timelineIDs(t, c); len(items) != 3 {
		t.Fatalf("every shot comes back: %+v", items)
	}
}

func TestStacksBelongToTheirOwner(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	other := s.user(c, "other@example.com")
	_, sharpest, _ := s.burst(t, c)
	resp, body := other.do(http.MethodPut, "/api/assets/"+sharpest+"/stack/main", nil, nil)
	expect(t, resp, body, http.StatusNotFound)
	resp, body = other.do(http.MethodDelete, "/api/assets/"+sharpest+"/stack", nil, nil)
	expect(t, resp, body, http.StatusNotFound)
}

func TestDuplicatesAreOnlyProposed(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	other := s.user(c, "other@example.com")
	ctx := context.Background()
	small := c.newPhoto(t, "small.jpg", "2020-01-01T10:00:00Z")
	big := c.newPhoto(t, "big.jpg", "2021-01-01T10:00:00Z")
	different := c.newPhoto(t, "different.jpg", "2022-01-01T10:00:00Z")
	foreign := other.newPhoto(t, "foreign.jpg", "2022-01-01T10:00:00Z")
	for id, row := range map[string]struct {
		hash   int64
		pixels int
	}{small: {0b1111, 100}, big: {0b11111, 2000}, different: {-1, 500}, foreign: {0b1111, 500}} {
		if _, err := s.pool.Exec(ctx, `UPDATE assets SET phash=$2, width=$3, height=$3 WHERE id=$1`, id, row.hash, row.pixels); err != nil {
			t.Fatal(err)
		}
	}
	s.organize(t)

	resp, body := c.get("/api/duplicates")
	expect(t, resp, body, http.StatusOK)
	found := decode[api.Duplicates](t, body)
	if found.Total != 1 || len(found.Groups) != 1 || len(found.Groups[0].Items) != 2 || found.Pending != 0 {
		t.Fatalf("%s", body)
	}
	if found.Groups[0].KeepId.String() != big {
		t.Fatalf("keep the larger one: %s", body)
	}
	// Nothing was removed by proposing it.
	if items := len(timelineOf(t, c)); items != 3 {
		t.Fatalf("timeline: %d", items)
	}

	// Another user's library is not compared with this one.
	resp, body = other.get("/api/duplicates")
	expect(t, resp, body, http.StatusOK)
	if decode[api.Duplicates](t, body).Total != 0 {
		t.Fatalf("%s", body)
	}

	// Removing one ends the proposal, and restoring it brings it back.
	c.bulk(t, "delete", small)
	resp, body = c.get("/api/duplicates")
	expect(t, resp, body, http.StatusOK)
	if decode[api.Duplicates](t, body).Total != 0 {
		t.Fatalf("%s", body)
	}
	c.bulk(t, "restore", small)

	// "Not duplicates" is final.
	resp, body = c.post("/api/duplicates/dismiss", api.AssetIds{Ids: uuids(t, small, big)})
	expect(t, resp, body, http.StatusNoContent)
	if _, err := s.pool.Exec(ctx, `UPDATE assets SET organized_at=NULL`); err != nil {
		t.Fatal(err)
	}
	s.organize(t)
	resp, body = c.get("/api/duplicates")
	expect(t, resp, body, http.StatusOK)
	if decode[api.Duplicates](t, body).Total != 0 {
		t.Fatalf("%s", body)
	}
}

func timelineOf(t *testing.T, c *client) []string {
	t.Helper()
	out := []string{}
	resp, body := c.get("/api/timeline/buckets")
	expect(t, resp, body, http.StatusOK)
	for _, bucket := range decode[api.TimelineBuckets](t, body).Buckets {
		resp, body := c.get("/api/timeline/buckets/" + bucket.Month)
		expect(t, resp, body, http.StatusOK)
		for _, item := range decode[api.TimelineBucket](t, body).Items {
			out = append(out, item.Id.String())
		}
	}
	return out
}
