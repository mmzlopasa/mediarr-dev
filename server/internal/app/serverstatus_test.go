package app

import (
	"context"
	"net/http"
	"net/http/httptest"
	"net/url"
	"slices"
	"sync/atomic"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/mediarr-app/mediarr/server/db"
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

type fakeUpdateStore struct {
	state map[string]string
	users int64
}

func (f *fakeUpdateStore) GetState(_ context.Context, key string) (string, error) {
	value, ok := f.state[key]
	if !ok {
		return "", pgx.ErrNoRows
	}
	return value, nil
}

func (f *fakeUpdateStore) SetState(_ context.Context, arg db.SetStateParams) error {
	f.state[arg.Key] = arg.Value
	return nil
}

func (f *fakeUpdateStore) CountUsers(context.Context) (int64, error) { return f.users, nil }

// withUpdateSite points the check at a test server for one test.
func withUpdateSite(t *testing.T, handler http.HandlerFunc) *atomic.Int32 {
	t.Helper()
	var hits atomic.Int32
	site := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		hits.Add(1)
		handler(w, r)
	}))
	t.Cleanup(site.Close)
	oldURL, oldVersion := updateURL, Version
	updateURL, Version = site.URL+"/install/cli/latest.json", "v0.1.0"
	t.Cleanup(func() { updateURL, Version = oldURL, oldVersion })
	return &hits
}

func TestUpdateCheckSendsOnlyThreeNumbers(t *testing.T) {
	var queries []url.Values
	withUpdateSite(t, func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/install/cli/latest.json" || r.Method != http.MethodGet {
			t.Errorf("%s %s", r.Method, r.URL.Path)
		}
		var names []string
		for name := range r.Header {
			names = append(names, name)
		}
		if !slices.Equal(names, []string{"User-Agent"}) || r.UserAgent() != "Mediarr/v0.1.0" {
			t.Errorf("headers: %v", r.Header)
		}
		queries = append(queries, r.URL.Query())
		_, _ = w.Write([]byte(`{"version":"v0.2.0"}`))
	})
	store := &fakeUpdateStore{state: map[string]string{}, users: 3}
	for range 2 {
		latest, err := checkForUpdate(context.Background(), store)
		if err != nil || latest != "v0.2.0" {
			t.Fatalf("%q %v", latest, err)
		}
	}
	if len(queries) != 2 {
		t.Fatalf("%d requests", len(queries))
	}
	first := queries[0]
	if len(first) != 3 || first.Get("v") != "v0.1.0" || first.Get("u") != "3" {
		t.Fatalf("query: %v", first)
	}
	id, err := uuid.Parse(first.Get("i"))
	if err != nil || id.Version() != 4 {
		t.Fatalf("install number %q: %v", first.Get("i"), err)
	}
	if queries[1].Get("i") != first.Get("i") || store.state[stateInstallID] != first.Get("i") {
		t.Fatal("the install number changed between checks")
	}
}

func TestUpdateCheckOffSendsNothing(t *testing.T) {
	hits := withUpdateSite(t, func(w http.ResponseWriter, _ *http.Request) {
		_, _ = w.Write([]byte(`{"version":"v0.2.0"}`))
	})
	store := &fakeUpdateStore{state: map[string]string{}}
	watchUpdates(store, false)
	if hits.Load() != 0 || len(store.state) != 0 {
		t.Fatalf("%d requests, state %v", hits.Load(), store.state)
	}
}

func TestUpdateCheckRejectsBadAnswers(t *testing.T) {
	for _, answer := range []string{`not json`, `{}`, `{"version":"v1.0"}`, `{"version":"v1.0.0-rc1"}`, `[]`} {
		withUpdateSite(t, func(w http.ResponseWriter, _ *http.Request) { _, _ = w.Write([]byte(answer)) })
		latest, err := checkForUpdate(context.Background(), &fakeUpdateStore{state: map[string]string{}})
		if err == nil || latest != "" {
			t.Errorf("%s: %q %v", answer, latest, err)
		}
	}
	withUpdateSite(t, func(w http.ResponseWriter, _ *http.Request) { http.Error(w, "gone", http.StatusNotFound) })
	if _, err := checkForUpdate(context.Background(), &fakeUpdateStore{state: map[string]string{}}); err == nil {
		t.Error("a missing file was taken as an answer")
	}
}

func TestUpdateCheckStaysOnItsHost(t *testing.T) {
	elsewhere := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		t.Error("followed a redirect to another host")
		_, _ = w.Write([]byte(`{"version":"v9.0.0"}`))
	}))
	t.Cleanup(elsewhere.Close)
	target := elsewhere.URL + "/x"
	withUpdateSite(t, func(w http.ResponseWriter, r *http.Request) { http.Redirect(w, r, target, http.StatusFound) })
	if _, err := checkForUpdate(context.Background(), &fakeUpdateStore{state: map[string]string{}}); err == nil {
		t.Error("a redirect was taken as an answer")
	}
}
