package app

import (
	"crypto/sha256"
	"encoding/base64"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/google/uuid"

	"github.com/mediarr-app/mediarr/server/internal/api"
)

const builtPage = `<!doctype html><html><head>
<script>
	(function (d) { d.dataset.theme = 'dark'; })(document.documentElement);
</script>
<link rel="modulepreload" href="/_app/immutable/entry/start.js">
<script type="module" src="/_app/immutable/entry/app.js"></script>
</head><body><div style="display: contents">
<script>
	{ __sveltekit_x = { base: "" }; import("/_app/immutable/entry/start.js"); }
</script>
</div></body></html>`

func hashOf(script string) string {
	sum := sha256.Sum256([]byte(script))
	return "'sha256-" + base64.StdEncoding.EncodeToString(sum[:]) + "'"
}

// Both inline scripts of the built page run, and nothing else written into a page does.
func TestThePagePolicyAllowsOnlyTheAppsOwnScripts(t *testing.T) {
	theme := "\n\t(function (d) { d.dataset.theme = 'dark'; })(document.documentElement);\n"
	start := "\n\t{ __sveltekit_x = { base: \"\" }; import(\"/_app/immutable/entry/start.js\"); }\n"
	hashes := inlineScriptHashes(builtPage)
	if len(hashes) != 2 || hashes[0] != hashOf(theme) || hashes[1] != hashOf(start) {
		t.Fatalf("hashes %v", hashes)
	}
	policy := pagePolicy(builtPage)
	for _, want := range []string{
		"script-src 'self' " + hashOf(theme) + " " + hashOf(start) + " https://www.gstatic.com;",
		"worker-src 'self' blob:", "media-src 'self' blob:", "object-src 'none'", "frame-ancestors 'self'",
	} {
		if !strings.Contains(policy, want) {
			t.Errorf("the policy has no %q: %s", want, policy)
		}
	}
	if strings.Contains(policy, "unsafe-eval") || strings.Contains(policy, "script-src 'self' 'unsafe-inline'") {
		t.Fatalf("scripts are not limited: %s", policy)
	}
}

// A page whose handler sets a policy of its own still gets the whole one.
func TestThePagePolicyReplacesAShorterOne(t *testing.T) {
	page := securityHeaders(builtPage)(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Security-Policy", "frame-ancestors 'self'")
		_, _ = w.Write([]byte("<!doctype html>"))
	}))
	recorder := httptest.NewRecorder()
	page.ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, "/albums", nil))
	if got := recorder.Header().Get("Content-Security-Policy"); got != pagePolicy(builtPage) {
		t.Fatalf("policy %q", got)
	}
}

func TestEveryAnswerHasSecurityHeaders(t *testing.T) {
	handler := newTestHandler(t, fakePinger{})
	for _, path := range []string{"/api/health", "/api/nothing-here", "/albums"} {
		recorder := httptest.NewRecorder()
		handler.ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, path, nil))
		header := recorder.Header()
		for name, want := range map[string]string{
			"X-Content-Type-Options": "nosniff", "Referrer-Policy": "strict-origin-when-cross-origin",
			"X-Frame-Options": "SAMEORIGIN", "Cross-Origin-Opener-Policy": "same-origin",
		} {
			if got := header.Get(name); got != want {
				t.Errorf("%s: %s is %q, want %q", path, name, got, want)
			}
		}
		if !strings.Contains(header.Get("Permissions-Policy"), "camera=()") {
			t.Errorf("%s: Permissions-Policy %q", path, header.Get("Permissions-Policy"))
		}
		// Plain http on an address must keep working, so nothing makes the browser insist on HTTPS.
		if header.Get("Strict-Transport-Security") != "" {
			t.Errorf("%s sets Strict-Transport-Security", path)
		}
		policy := header.Get("Content-Security-Policy")
		if strings.HasPrefix(path, "/api/") && policy != apiPolicy {
			t.Errorf("%s: policy %q", path, policy)
		}
		if !strings.HasPrefix(path, "/api/") && !strings.Contains(policy, "script-src 'self'") {
			t.Errorf("%s: policy %q", path, policy)
		}
	}
}

func checksums(count int) []string {
	out := make([]string, count)
	for i := range out {
		out[i] = fmt.Sprintf("%064x", i+1)
	}
	return out
}

// The app asks about a thousand files at once and reports five thousand, which are larger than the
// usual limit on a request.
func TestTheAppsLargestRequestsFit(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	ana := s.user(admin, "ana@example.com")

	resp, body := ana.post("/api/assets/check", map[string]any{"checksums": checksums(1000)})
	expect(t, resp, body, http.StatusOK)
	resp, body = ana.post("/api/assets/check", map[string]any{"checksums": checksums(1001)})
	expect(t, resp, body, http.StatusBadRequest)

	path := "/api/me/backup-devices/" + uuid.NewString()
	resp, body = ana.send(http.MethodPut, path, report("Pixel 8", checksums(5000), true))
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.BackupDevice](t, body); got.Files != 5000 {
		t.Fatalf("%+v", got)
	}
}

// A stolen session cannot be used to guess the password through the pages that ask for it again.
func TestPasswordConfirmationsAreCounted(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	ana := s.user(admin, "ana@example.com")
	for range confirmFailures {
		resp, body := ana.send(http.MethodPost, "/api/me/password", api.ChangePasswordRequest{CurrentPassword: "not the password", NewPassword: "a brand new password"})
		expect(t, resp, body, http.StatusUnauthorized)
	}
	resp, body := ana.send(http.MethodPost, "/api/me/password", api.ChangePasswordRequest{CurrentPassword: testPassword, NewPassword: "a brand new password"})
	expect(t, resp, body, http.StatusTooManyRequests)
	resp, body = ana.send(http.MethodPatch, "/api/me", map[string]any{"email": "other@example.com", "currentPassword": testPassword})
	expect(t, resp, body, http.StatusTooManyRequests)
	// Another account is not held up by it.
	resp, body = admin.send(http.MethodPost, "/api/me/password", api.ChangePasswordRequest{CurrentPassword: testPassword, NewPassword: "a brand new password"})
	expect(t, resp, body, http.StatusNoContent)
}

func TestSearchAndAlbumInputsAreLimited(t *testing.T) {
	s := newStack(t)
	admin := s.admin()

	resp, body := admin.get("/api/search?tag=" + strings.Repeat("a&tag=", maxSearchChoices) + "a")
	expect(t, resp, body, http.StatusBadRequest)
	resp, body = admin.get("/api/search?place=" + strings.Repeat("x", maxQueryLength+1))
	expect(t, resp, body, http.StatusBadRequest)
	resp, body = admin.get("/api/search?tag=a&tag=b")
	expect(t, resp, body, http.StatusOK)

	long := strings.Repeat("d", maxDescription+1)
	resp, body = admin.post("/api/albums", map[string]any{"title": "Trip", "description": long})
	expect(t, resp, body, http.StatusBadRequest)
	album := admin.newAlbum(map[string]any{"title": "Trip"})
	resp, body = admin.send(http.MethodPatch, "/api/albums/"+album, map[string]any{"description": long})
	expect(t, resp, body, http.StatusBadRequest)
	// A failed parent leaves no album behind.
	resp, body = admin.post("/api/albums", map[string]any{"title": "Lost", "parentId": uuid.NewString()})
	expect(t, resp, body, http.StatusNotFound)
	if count := s.count(t, "SELECT count(*) FROM albums"); count != 1 {
		t.Fatalf("%d albums", count)
	}
}

// The list of albums shows the chosen cover, and the newest photo once the cover has left.
func TestAlbumListShowsTheChosenCover(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	older := admin.newPhoto(t, "older.jpg", "2024-01-01T10:00:00Z")
	newer := admin.newPhoto(t, "newer.jpg", "2024-02-01T10:00:00Z")
	album := admin.newAlbum(map[string]any{"title": "Trip"})
	resp, body := admin.post("/api/albums/"+album+"/assets", map[string]any{"ids": []string{older, newer}})
	expect(t, resp, body, http.StatusOK)
	resp, body = admin.send(http.MethodPatch, "/api/albums/"+album, map[string]any{"coverAssetId": older})
	expect(t, resp, body, http.StatusOK)
	if got := admin.albums(t)["Trip"]; got.CoverAssetId == nil || got.CoverAssetId.String() != older {
		t.Fatalf("%+v", got)
	}
	resp, body = admin.post("/api/albums/"+album+"/assets/remove", map[string]any{"ids": []string{older}})
	expect(t, resp, body, http.StatusOK)
	if got := admin.albums(t)["Trip"]; got.CoverAssetId == nil || got.CoverAssetId.String() != newer {
		t.Fatalf("%+v", got)
	}
}

func TestAnAppsChallengeIsLimited(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	s.turnOnOIDC(t, admin, newFakeProvider(t), false)
	resp, body := s.client().get("/api/auth/oidc/start?appChallenge=" + strings.Repeat("a", maxAppChallenge+1))
	expect(t, resp, body, http.StatusBadRequest)
}
