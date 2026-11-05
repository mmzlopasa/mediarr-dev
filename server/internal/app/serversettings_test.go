package app

import (
	"context"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

func TestServerSettingsAreCheckedAndApplied(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	resp, body := admin.get("/api/admin/server-settings")
	expect(t, resp, body, http.StatusOK)
	settings := decode[api.ServerSettings](t, body)
	if settings.TrashDays != 30 || !settings.PasswordLogin {
		t.Fatalf("%+v", settings)
	}
	bad := settings
	bad.ImageQuality = 5
	resp, body = admin.send(http.MethodPut, "/api/admin/server-settings", bad)
	expect(t, resp, body, http.StatusBadRequest)
	// Nobody could sign in without passwords and without single sign-on.
	bad = settings
	bad.PasswordLogin = false
	resp, body = admin.send(http.MethodPut, "/api/admin/server-settings", bad)
	expect(t, resp, body, http.StatusBadRequest)

	settings.LoginMessage = "Welcome to the family server"
	settings.TrashDays = 7
	resp, body = admin.send(http.MethodPut, "/api/admin/server-settings", settings)
	expect(t, resp, body, http.StatusOK)
	resp, body = s.client().get("/api/auth/methods")
	expect(t, resp, body, http.StatusOK)
	methods := decode[api.AuthMethods](t, body)
	if methods.LoginMessage != "Welcome to the family server" || !methods.PasswordLogin {
		t.Fatalf("%+v", methods)
	}
	resp, body = admin.get("/api/server/status")
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.ServerStatus](t, body).TrashDays; got != 7 {
		t.Fatalf("trash days: %d", got)
	}
}

func TestPasswordsCanBeTurnedOffAndBack(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	ctx := context.Background()
	queries := db.New(s.pool)
	if err := queries.SetState(ctx, db.SetStateParams{Key: jobs.StateServerSettings, Value: `{"passwordLogin":false}`}); err != nil {
		t.Fatal(err)
	}
	resp, body := s.client().post("/api/auth/login", api.LoginRequest{Email: "admin@example.com", Password: testPassword})
	expect(t, resp, body, http.StatusForbidden)
	if !strings.Contains(string(body), "turned off") {
		t.Fatalf("%s", body)
	}
	resp, body = admin.get("/api/timeline/buckets")
	expect(t, resp, body, http.StatusOK)
	// The way back in for someone whose provider broke.
	if err := ResetSecurity(ctx, queries); err != nil {
		t.Fatal(err)
	}
	resp, body = s.client().post("/api/auth/login", api.LoginRequest{Email: "admin@example.com", Password: testPassword})
	expect(t, resp, body, http.StatusOK)
}

func TestTheTrashKeepsWhatItIsSetTo(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	ctx := context.Background()
	photo := c.newPhoto(t, "a.jpg", "2024-01-01T10:00:00Z")
	queries := db.New(s.pool)
	if _, err := s.pool.Exec(ctx, `UPDATE assets SET deleted_at = now() - interval '10 days' WHERE id = $1`, photo); err != nil {
		t.Fatal(err)
	}
	now := time.Now()
	if err := jobs.PurgeExpiredTrash(ctx, queries, s.cache, now); err != nil {
		t.Fatal(err)
	}
	if got := s.count(t, "SELECT count(*) FROM assets"); got != 1 {
		t.Fatalf("removed too early: %d", got)
	}
	if err := queries.SetState(ctx, db.SetStateParams{Key: jobs.StateServerSettings, Value: `{"trashDays":7}`}); err != nil {
		t.Fatal(err)
	}
	if err := jobs.PurgeExpiredTrash(ctx, queries, s.cache, now); err != nil {
		t.Fatal(err)
	}
	if got := s.count(t, "SELECT count(*) FROM assets"); got != 0 {
		t.Fatalf("still there: %d", got)
	}
}
