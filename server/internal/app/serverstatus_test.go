package app

import (
	"net/http"
	"testing"

	"github.com/mediarr-app/mediarr/server/internal/api"
)

func TestVersionsCompare(t *testing.T) {
	for _, tc := range []struct {
		candidate, current string
		want               bool
	}{
		{"v0.1.2", "v0.1.1", true},
		{"v0.2.0", "v0.1.9", true},
		{"v0.10.0", "v0.9.0", true},
		{"v0.1.1", "v0.1.1", false},
		{"v0.1.0", "v0.1.1", false},
		{"v0.2.0", "dev", false},
		{"v1.0", "v0.1.0", false},
		{"app-v1.0.0", "v0.1.0", false},
	} {
		if got := isNewerVersion(tc.candidate, tc.current); got != tc.want {
			t.Errorf("%s over %s: %v", tc.candidate, tc.current, got)
		}
	}
	if got := newestVersion([]string{"v0.1.2", "v0.10.0", "v0.9.0", "nightly"}); got != "v0.10.0" {
		t.Errorf("newest: %s", got)
	}
}

func TestServerStatusIsForSignedInPeople(t *testing.T) {
	s := newStack(t)
	resp, body := s.client().get("/api/server/status")
	expect(t, resp, body, http.StatusUnauthorized)
	resp, body = s.admin().get("/api/server/status")
	expect(t, resp, body, http.StatusOK)
	status := decode[api.ServerStatus](t, body)
	if status.DiskTotalBytes <= 0 || status.DiskUsedBytes <= 0 || status.Version == "" {
		t.Fatalf("%+v", status)
	}
	if status.UpdateAvailable {
		t.Fatal("a development build has no update")
	}
}
