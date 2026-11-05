package app

import (
	"context"
	"net/http"
	"os/exec"
	"strings"
	"testing"

	"github.com/mediarr-app/mediarr/server/internal/api"
)

func TestARatingIsGivenAndChecked(t *testing.T) {
	service := fakeML(t)
	s := newStack(t)
	s.useML(t, service)
	c := s.admin()
	stranger := s.user(c, "stranger@example.com")
	id := c.newPhoto(t, "1.jpg", "2024-01-01T10:00:00Z")
	path := "/api/assets/" + id + "/facts"

	for _, bad := range []int{-1, 6} {
		rating := bad
		resp, body := c.send(http.MethodPatch, path, api.AssetFacts{Rating: &rating})
		expect(t, resp, body, http.StatusBadRequest)
	}
	four := 4
	resp, body := c.send(http.MethodPatch, path, api.AssetFacts{Rating: &four})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = c.get("/api/assets/" + id)
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.AssetDetail](t, body).Rating; got == nil || *got != 4 {
		t.Fatalf("rating: %v", got)
	}
	// A file read again does not take the owner's rating away.
	if _, err := s.pool.Exec(context.Background(),
		`UPDATE assets SET rating = CASE WHEN rating_by_owner THEN rating ELSE 1 END WHERE id = $1`, id); err != nil {
		t.Fatal(err)
	}
	resp, body = c.get("/api/assets/" + id)
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.AssetDetail](t, body).Rating; got == nil || *got != 4 {
		t.Fatalf("after reading the file: %v", got)
	}
	none := 0
	resp, body = c.send(http.MethodPatch, path, api.AssetFacts{Rating: &none})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = c.get("/api/assets/" + id)
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.AssetDetail](t, body).Rating; got != nil {
		t.Fatalf("no stars, but %d", *got)
	}

	resp, body = stranger.get("/api/assets/" + id + "/sidecar")
	expect(t, resp, body, http.StatusNotFound)
}

func TestTheSidecarIsAnXMPFileNamedAfterTheOriginal(t *testing.T) {
	if _, err := exec.LookPath("exiftool"); err != nil {
		t.Skip("exiftool is not installed")
	}
	s := newStack(t)
	c := s.admin()
	id := c.newPhoto(t, "beach.jpg", "2024-01-01T10:00:00Z")
	resp, body := c.get("/api/assets/" + id + "/sidecar")
	expect(t, resp, body, http.StatusOK)
	if !strings.Contains(resp.Header.Get("Content-Disposition"), "beach.jpg.xmp") || !strings.Contains(string(body), "x:xmpmeta") {
		t.Fatalf("%s %.200s", resp.Header.Get("Content-Disposition"), body)
	}
}
