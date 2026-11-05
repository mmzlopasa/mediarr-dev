package app

import (
	"context"
	"net/http"
	"testing"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

func notifications(t *testing.T, c *client) api.NotificationList {
	t.Helper()
	resp, body := c.get("/api/notifications")
	expect(t, resp, body, http.StatusOK)
	return decode[api.NotificationList](t, body)
}

func TestSharingAnAlbumNotifiesOnceAndOnlyThatPerson(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	person := s.user(admin, "person@example.com")
	stranger := s.user(admin, "stranger@example.com")
	var personID string
	if err := s.pool.QueryRow(context.Background(), `SELECT id::text FROM users WHERE email = 'person@example.com'`).Scan(&personID); err != nil {
		t.Fatal(err)
	}
	resp, body := admin.post("/api/albums", api.AlbumCreate{Title: "Summer"})
	expect(t, resp, body, http.StatusCreated)
	album := decode[api.Album](t, body)
	path := "/api/albums/" + album.Id.String() + "/members/" + personID

	resp, body = admin.send(http.MethodPut, path, api.MemberRole{Role: api.MemberRoleRoleViewer})
	expect(t, resp, body, http.StatusNoContent)
	got := notifications(t, person)
	if got.Unread != 1 || len(got.Items) != 1 || got.Items[0].Kind != api.AlbumShared ||
		got.Items[0].Subject != "Summer" || got.Items[0].Ref != album.Id.String() {
		t.Fatalf("after sharing: %+v", got)
	}
	// A new role is not a new album.
	resp, body = admin.send(http.MethodPut, path, api.MemberRole{Role: api.MemberRoleRoleEditor})
	expect(t, resp, body, http.StatusNoContent)
	if got := notifications(t, person); len(got.Items) != 1 {
		t.Fatalf("after a new role: %+v", got)
	}
	if got := notifications(t, stranger); len(got.Items) != 0 || got.Unread != 0 {
		t.Fatalf("someone else: %+v", got)
	}

	// Somebody else's cannot be removed.
	id := got.Items[0].Id.String()
	resp, body = stranger.send(http.MethodDelete, "/api/notifications/"+id, nil)
	expect(t, resp, body, http.StatusNotFound)

	resp, body = person.post("/api/notifications/read", nil)
	expect(t, resp, body, http.StatusNoContent)
	got = notifications(t, person)
	if got.Unread != 0 || !got.Items[0].Read {
		t.Fatalf("after reading: %+v", got)
	}
	resp, body = person.send(http.MethodDelete, "/api/notifications/"+id, nil)
	expect(t, resp, body, http.StatusNoContent)
	if got := notifications(t, person); len(got.Items) != 0 {
		t.Fatalf("after removing: %+v", got)
	}
}

func TestAFailedBackupNotifiesAdministrators(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	person := s.user(admin, "person@example.com")
	if err := jobs.NotifyBackupFailed(context.Background(), db.New(s.pool), "the disk is full"); err != nil {
		t.Fatal(err)
	}
	got := notifications(t, admin)
	if got.Unread != 1 || got.Items[0].Kind != api.BackupFailed || got.Items[0].Subject != "the disk is full" {
		t.Fatalf("administrator: %+v", got)
	}
	if got := notifications(t, person); len(got.Items) != 0 {
		t.Fatalf("not an administrator: %+v", got)
	}
}
