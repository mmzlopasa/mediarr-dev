package app

import (
	"context"
	"net/http"
	"testing"

	"github.com/mediarr-app/mediarr/server/internal/api"
)

func TestSessionsCanBeSeenAndEnded(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	second := s.client()
	resp, body := second.post("/api/auth/login", api.LoginRequest{Email: "admin@example.com", Password: testPassword})
	expect(t, resp, body, http.StatusOK)
	stranger := s.user(admin, "stranger@example.com")

	resp, body = admin.get("/api/me/sessions")
	expect(t, resp, body, http.StatusOK)
	sessions := decode[[]api.UserSession](t, body)
	if len(sessions) != 2 {
		t.Fatalf("%+v", sessions)
	}
	other := ""
	currents := 0
	for _, session := range sessions {
		if session.Current {
			currents++
		} else {
			other = session.Id.String()
		}
	}
	if currents != 1 || other == "" {
		t.Fatalf("%+v", sessions)
	}
	// Someone else's session cannot be ended.
	resp, body = stranger.send(http.MethodDelete, "/api/me/sessions/"+other, nil)
	expect(t, resp, body, http.StatusNotFound)
	resp, body = second.get("/api/timeline/buckets")
	expect(t, resp, body, http.StatusOK)

	resp, body = admin.send(http.MethodDelete, "/api/me/sessions/"+other, nil)
	expect(t, resp, body, http.StatusNoContent)
	resp, body = second.get("/api/timeline/buckets")
	expect(t, resp, body, http.StatusUnauthorized)

	third := s.client()
	resp, body = third.post("/api/auth/login", api.LoginRequest{Email: "admin@example.com", Password: testPassword})
	expect(t, resp, body, http.StatusOK)
	resp, body = admin.send(http.MethodDelete, "/api/me/sessions", nil)
	expect(t, resp, body, http.StatusNoContent)
	resp, body = third.get("/api/timeline/buckets")
	expect(t, resp, body, http.StatusUnauthorized)
	resp, body = admin.get("/api/timeline/buckets")
	expect(t, resp, body, http.StatusOK)
}

func TestStatsCountWhatTheAccountHolds(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	c.newPhoto(t, "a.jpg", "2024-01-01T10:00:00Z")
	photo := c.newPhoto(t, "b.jpg", "2024-01-02T10:00:00Z")
	if _, err := s.pool.Exec(context.Background(), `UPDATE assets SET is_favorite = true WHERE id = $1`, photo); err != nil {
		t.Fatal(err)
	}
	resp, body := c.get("/api/me/stats")
	expect(t, resp, body, http.StatusOK)
	stats := decode[api.AccountStats](t, body)
	if stats.Photos != 2 || stats.Favorites != 1 || stats.Videos != 0 {
		t.Fatalf("%+v", stats)
	}
}

func TestAnUnreadableLivePhotoVideoIsNotReported(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	ctx := context.Background()
	c.newPhoto(t, "IMG_1.HEIC", "2024-01-01T10:00:00Z")
	video := c.newPhoto(t, "IMG_1.mov", "2024-01-01T10:00:00Z")
	lone := c.newPhoto(t, "IMG_2.mov", "2024-01-01T10:00:00Z")
	if _, err := s.pool.Exec(ctx, `UPDATE assets SET status = 'failed', error = 'x' WHERE id = ANY($1::uuid[])`, []string{video, lone}); err != nil {
		t.Fatal(err)
	}
	resp, body := c.get("/api/assets?status=failed&limit=200")
	expect(t, resp, body, http.StatusOK)
	list := decode[api.AssetList](t, body)
	if len(list.Items) != 1 || list.Items[0].OriginalName != "IMG_2.mov" {
		t.Fatalf("%s", body)
	}
}
