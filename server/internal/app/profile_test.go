package app

import (
	"bytes"
	"context"
	"io"
	"net/http"
	"os/exec"
	"testing"

	"github.com/mediarr-app/mediarr/server/internal/api"
)

func (c *client) putImage(path string, data []byte) (*http.Response, []byte) {
	c.s.t.Helper()
	request, err := http.NewRequestWithContext(context.Background(), http.MethodPut, c.s.url+path, bytes.NewReader(data))
	if err != nil {
		c.s.t.Fatal(err)
	}
	request.Header.Set("Content-Type", "image/jpeg")
	response, err := c.http.Do(request)
	if err != nil {
		c.s.t.Fatal(err)
	}
	defer func() { _ = response.Body.Close() }()
	body, err := io.ReadAll(response.Body)
	if err != nil {
		c.s.t.Fatal(err)
	}
	return response, body
}

func TestPeopleChangeTheirNameEmailAndPicture(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	ana := s.user(admin, "ana@example.com")

	resp, body := ana.send(http.MethodPatch, "/api/me", map[string]string{"name": "  Ana Horvat "})
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.User](t, body); got.Name != "Ana Horvat" || got.Email != "ana@example.com" {
		t.Fatalf("%+v", got)
	}
	resp, body = ana.send(http.MethodPatch, "/api/me", map[string]string{"name": ""})
	expect(t, resp, body, http.StatusBadRequest)

	// A new email address takes the password, and must not be someone else's.
	resp, body = ana.send(http.MethodPatch, "/api/me", map[string]string{"email": "ana.h@example.com"})
	expect(t, resp, body, http.StatusUnauthorized)
	resp, body = ana.send(http.MethodPatch, "/api/me", map[string]string{"email": "admin@example.com", "currentPassword": testPassword})
	expect(t, resp, body, http.StatusConflict)
	resp, body = ana.send(http.MethodPatch, "/api/me", map[string]string{"email": "Ana.H@Example.com", "currentPassword": testPassword})
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.User](t, body); got.Email != "ana.h@example.com" {
		t.Fatalf("%+v", got)
	}

	if _, err := exec.LookPath("vipsthumbnail"); err != nil {
		t.Skip("libvips is not installed; run through `make test`")
	}
	resp, body = ana.putImage("/api/me/avatar", []byte("not a picture"))
	expect(t, resp, body, http.StatusBadRequest)
	resp, body = ana.putImage("/api/me/avatar", pictureOf(t, 40))
	expect(t, resp, body, http.StatusOK)
	me := decode[api.User](t, body)
	if me.AvatarVersion == nil || *me.AvatarVersion != 1 {
		t.Fatalf("%+v", me)
	}
	// Anyone signed in sees it, as a WebP; nobody signed out does.
	resp, body = admin.get("/api/users/" + me.Id.String() + "/avatar")
	expect(t, resp, body, http.StatusOK)
	if resp.Header.Get("Content-Type") != "image/webp" || !bytes.HasPrefix(body, []byte("RIFF")) {
		t.Fatalf("%s %q", resp.Header.Get("Content-Type"), body[:min(len(body), 12)])
	}
	resp, body = s.client().get("/api/users/" + me.Id.String() + "/avatar")
	expect(t, resp, body, http.StatusUnauthorized)

	resp, body = ana.send(http.MethodDelete, "/api/me/avatar", nil)
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.User](t, body); got.AvatarVersion != nil {
		t.Fatalf("%+v", got)
	}
	resp, body = admin.get("/api/users/" + me.Id.String() + "/avatar")
	expect(t, resp, body, http.StatusNotFound)
}
