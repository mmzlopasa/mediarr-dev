package app

import (
	"context"
	"net/http"
	"testing"

	"github.com/mediarr-app/mediarr/server/internal/api"
)

func TestAFamilySharesOnlyByItsRules(t *testing.T) {
	s := newStack(t)
	mum := s.admin()
	dad := s.user(mum, "dad@example.com")
	stranger := s.user(mum, "stranger@example.com")
	ctx := context.Background()
	summer := mum.newPhoto(t, "summer.jpg", "2024-07-10T10:00:00Z")
	private := mum.newPhoto(t, "private.jpg", "2023-02-10T10:00:00Z")
	locked := mum.newPhoto(t, "locked.jpg", "2024-07-11T10:00:00Z")

	// Off, nobody is in anything.
	resp, body := mum.get("/api/family")
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.Family](t, body); got.Enabled || got.Member {
		t.Fatalf("%s", body)
	}
	resp, body = mum.post("/api/family/rules", map[string]any{"title": "Summer", "rules": map[string]string{"from": "2024-06-01"}})
	expect(t, resp, body, http.StatusForbidden)

	resp, body = mum.send(http.MethodPut, "/api/admin/features/family", map[string]bool{"enabled": true})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = dad.send(http.MethodPut, "/api/admin/family/"+s.userID("dad@example.com"), map[string]any{})
	expect(t, resp, body, http.StatusForbidden)
	for _, email := range []string{"admin@example.com", "dad@example.com"} {
		resp, body = mum.send(http.MethodPut, "/api/admin/family/"+s.userID(email), map[string]any{})
		expect(t, resp, body, http.StatusNoContent)
	}

	// A rule with nothing in it would share everything, so it is refused.
	resp, body = mum.post("/api/family/rules", map[string]any{"title": "All", "rules": map[string]any{}})
	expect(t, resp, body, http.StatusBadRequest)
	resp, body = mum.post("/api/family/rules", map[string]any{"title": "Summer", "rules": map[string]string{"from": "2024-06-01"}})
	expect(t, resp, body, http.StatusCreated)
	rule := decode[map[string]string](t, body)["id"]
	if _, err := s.pool.Exec(ctx, "UPDATE assets SET vault_at=now() WHERE id=$1", locked); err != nil {
		t.Fatal(err)
	}

	items := func(c *client) []string {
		t.Helper()
		resp, body := c.get("/api/family/buckets")
		if resp.StatusCode == http.StatusForbidden {
			return nil
		}
		expect(t, resp, body, http.StatusOK)
		out := []string{}
		for _, bucket := range decode[api.TimelineBuckets](t, body).Buckets {
			resp, body := c.get("/api/family/buckets/" + bucket.Month)
			expect(t, resp, body, http.StatusOK)
			for _, item := range decode[api.TimelineBucket](t, body).Items {
				out = append(out, item.Id.String())
			}
		}
		return out
	}
	// Dad sees what the rule covers, and neither what it does not nor what is in the vault.
	if got := items(dad); len(got) != 1 || got[0] != summer {
		t.Fatalf("dad: %v", got)
	}
	resp, body = dad.get("/api/assets/" + summer)
	expect(t, resp, body, http.StatusOK)
	resp, body = dad.get("/api/assets/" + private)
	expect(t, resp, body, http.StatusNotFound)
	// He cannot change or delete it, and someone outside the family sees nothing.
	resp, body = dad.send(http.MethodPost, "/api/assets/bulk", map[string]any{"ids": []string{summer}, "action": "delete"})
	if got := changedBy(t, resp, body); got != 0 {
		t.Fatalf("dad deleted %d", got)
	}
	if got := items(stranger); got != nil {
		t.Fatalf("stranger: %v", got)
	}
	resp, body = stranger.get("/api/assets/" + summer)
	expect(t, resp, body, http.StatusNotFound)
	// The rule belongs to whoever made it, and does not clutter anyone's albums.
	resp, body = dad.do(http.MethodDelete, "/api/family/rules/"+rule, nil, nil)
	expect(t, resp, body, http.StatusNotFound)
	resp, body = dad.get("/api/albums")
	expect(t, resp, body, http.StatusOK)
	if got := decode[[]api.Album](t, body); len(got) != 0 {
		t.Fatalf("albums: %s", body)
	}

	// Someone joining later sees what is already shared. Someone leaving stops sharing, and seeing.
	sis := s.user(mum, "sis@example.com")
	resp, body = mum.send(http.MethodPut, "/api/admin/family/"+s.userID("sis@example.com"), map[string]any{})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = sis.get("/api/assets/" + summer)
	expect(t, resp, body, http.StatusOK)
	resp, body = mum.do(http.MethodDelete, "/api/admin/family/"+s.userID("admin@example.com"), nil, nil)
	expect(t, resp, body, http.StatusNoContent)
	resp, body = dad.get("/api/assets/" + summer)
	expect(t, resp, body, http.StatusNotFound)
	if got := items(dad); len(got) != 0 {
		t.Fatalf("after leaving: %v", got)
	}
	// Her photos are all still hers.
	resp, body = mum.get("/api/assets/" + summer)
	expect(t, resp, body, http.StatusOK)
}

func TestTurningTheFamilyOffStopsItsTimeline(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	resp, body := c.send(http.MethodPut, "/api/admin/features/family", map[string]bool{"enabled": true})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = c.send(http.MethodPut, "/api/admin/family/"+s.userID("admin@example.com"), map[string]any{})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = c.get("/api/family/buckets")
	expect(t, resp, body, http.StatusOK)
	resp, body = c.send(http.MethodPut, "/api/admin/features/family", map[string]bool{"enabled": false})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = c.get("/api/family/buckets")
	expect(t, resp, body, http.StatusForbidden)
}
