package app

import (
	"context"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/mmzlopasa/mediarr-app/server/db"
	"github.com/mmzlopasa/mediarr-app/server/internal/jobs"
)

func TestMetricsNeedTheirToken(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	photo := c.newPhoto(t, "secret-name.jpg", "2024-01-01T10:00:00Z")

	// Without a token set, there is nothing there.
	resp, err := http.Get(s.url + "/metrics") //nolint:noctx // A test.
	if err != nil {
		t.Fatal(err)
	}
	_ = resp.Body.Close()
	if resp.StatusCode != http.StatusNotFound {
		t.Fatalf("no token set: %d", resp.StatusCode)
	}

	inserter, err := jobs.NewInserter(s.pool)
	if err != nil {
		t.Fatal(err)
	}
	handler, err := NewHandler(Deps{
		Pinger: db.New(s.pool), Pool: s.pool, Inserter: inserter,
		LibraryPath: s.library, CachePath: s.cache, MetricsToken: "scrape-me",
	})
	if err != nil {
		t.Fatal(err)
	}
	server := httptest.NewServer(handler)
	t.Cleanup(server.Close)
	scrape := func(token string) (int, string) {
		t.Helper()
		request, err := http.NewRequestWithContext(context.Background(), http.MethodGet, server.URL+"/metrics", http.NoBody)
		if err != nil {
			t.Fatal(err)
		}
		if token != "" {
			request.Header.Set("Authorization", "Bearer "+token)
		}
		resp, err := http.DefaultClient.Do(request)
		if err != nil {
			t.Fatal(err)
		}
		defer func() { _ = resp.Body.Close() }()
		body, err := io.ReadAll(resp.Body)
		if err != nil {
			t.Fatal(err)
		}
		return resp.StatusCode, string(body)
	}
	if status, _ := scrape(""); status != http.StatusUnauthorized {
		t.Fatalf("no token: %d", status)
	}
	if status, _ := scrape("wrong"); status != http.StatusUnauthorized {
		t.Fatalf("wrong token: %d", status)
	}

	// A request shows up by its route, never by what it was about.
	resp, err = http.Get(server.URL + "/api/assets/" + photo) //nolint:noctx // A test.
	if err != nil {
		t.Fatal(err)
	}
	_ = resp.Body.Close()
	status, body := scrape("scrape-me")
	if status != http.StatusOK {
		t.Fatalf("right token: %d", status)
	}
	for _, want := range []string{"mediarr_users 1", `mediarr_assets{kind="photo"} 1`, `route="/api/assets/{id}"`, "mediarr_disk_bytes"} {
		if !strings.Contains(body, want) {
			t.Errorf("no %q in:\n%s", want, body)
		}
	}
	for _, never := range []string{photo, "secret-name", "admin@example.com"} {
		if strings.Contains(body, never) {
			t.Errorf("%q is in the metrics", never)
		}
	}
}
