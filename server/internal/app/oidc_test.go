package app

import (
	"context"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"sync"
	"testing"
	"time"

	jose "github.com/go-jose/go-jose/v4"
	"github.com/go-jose/go-jose/v4/jwt"

	"github.com/mediarr-app/mediarr/server/internal/api"
)

// fakeProvider is an identity provider that signs what the test tells it to say.
type fakeProvider struct {
	t      *testing.T
	server *httptest.Server
	key    *rsa.PrivateKey
	mu     sync.Mutex
	claims map[string]any
	nonce  string
}

func newFakeProvider(t *testing.T) *fakeProvider {
	t.Helper()
	key, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatal(err)
	}
	p := &fakeProvider{t: t, key: key}
	mux := http.NewServeMux()
	mux.HandleFunc("/.well-known/openid-configuration", func(w http.ResponseWriter, _ *http.Request) {
		_ = json.NewEncoder(w).Encode(map[string]any{
			"issuer": p.server.URL, "authorization_endpoint": p.server.URL + "/authorize",
			"token_endpoint": p.server.URL + "/token", "jwks_uri": p.server.URL + "/keys",
			"id_token_signing_alg_values_supported": []string{"RS256"},
		})
	})
	mux.HandleFunc("/keys", func(w http.ResponseWriter, _ *http.Request) {
		_ = json.NewEncoder(w).Encode(jose.JSONWebKeySet{Keys: []jose.JSONWebKey{
			{Key: key.Public(), KeyID: "k", Algorithm: "RS256", Use: "sig"},
		}})
	})
	mux.HandleFunc("/token", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]any{"access_token": "a", "token_type": "Bearer", "id_token": p.idToken()})
	})
	p.server = httptest.NewServer(mux)
	t.Cleanup(p.server.Close)
	return p
}

func (p *fakeProvider) idToken() string {
	p.mu.Lock()
	defer p.mu.Unlock()
	signer, err := jose.NewSigner(jose.SigningKey{Algorithm: jose.RS256, Key: p.key},
		(&jose.SignerOptions{}).WithType("JWT").WithHeader("kid", "k"))
	if err != nil {
		p.t.Error(err)
		return ""
	}
	now := time.Now()
	claims := map[string]any{
		"iss": p.server.URL, "sub": "person", "aud": "mediarr", "nonce": p.nonce,
		"iat": now.Unix(), "exp": now.Add(time.Hour).Unix(),
	}
	for key, value := range p.claims {
		claims[key] = value
	}
	token, err := jwt.Signed(signer).Claims(claims).Serialize()
	if err != nil {
		p.t.Error(err)
	}
	return token
}

func (p *fakeProvider) says(claims map[string]any) {
	p.mu.Lock()
	defer p.mu.Unlock()
	p.claims = claims
}

// signInWith walks the browser's way through the provider, without following anything by itself.
func (p *fakeProvider) signInWith(c *client, start string) (*http.Response, string) {
	p.t.Helper()
	c.http.CheckRedirect = func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }
	resp, body := c.get(start)
	if resp.StatusCode != http.StatusFound {
		p.t.Fatalf("start: %d %s", resp.StatusCode, body)
	}
	to, err := url.Parse(resp.Header.Get("Location"))
	if err != nil {
		p.t.Fatal(err)
	}
	if !strings.HasPrefix(to.String(), p.server.URL+"/authorize") {
		p.t.Fatalf("went to %s", to)
	}
	query := to.Query()
	p.mu.Lock()
	p.nonce = query.Get("nonce")
	p.mu.Unlock()
	if query.Get("code_challenge") == "" || !strings.Contains(query.Get("redirect_uri"), oidcCallbackPath) {
		p.t.Fatalf("authorize: %s", to)
	}
	state := query.Get("state")
	resp, _ = c.get(oidcCallbackPath + "?code=x&state=" + url.QueryEscape(state))
	return resp, state
}

func (s *stack) turnOnOIDC(t *testing.T, admin *client, p *fakeProvider, autoCreate bool) {
	t.Helper()
	resp, body := admin.send(http.MethodPut, "/api/admin/oidc", map[string]any{
		"issuer": p.server.URL, "clientId": "mediarr", "secret": "shh", "label": "Family login", "autoCreate": autoCreate,
	})
	expect(t, resp, body, http.StatusOK)
	if strings.Contains(string(body), "shh") {
		t.Fatalf("the secret came back: %s", body)
	}
}

func TestSingleSignOn(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	p := newFakeProvider(t)

	// Off, there is nothing to start.
	resp, body := s.client().get("/api/auth/oidc/start")
	expect(t, resp, body, http.StatusNotFound)
	s.turnOnOIDC(t, admin, p, false)

	resp, body = s.client().get("/api/auth/methods")
	expect(t, resp, body, http.StatusOK)
	if methods := decode[api.AuthMethods](t, body); methods.SsoLabel == nil || *methods.SsoLabel != "Family login" {
		t.Fatalf("%s", body)
	}

	// Someone who has an account gets in, to that account.
	person := s.client()
	resp, body = admin.send(http.MethodPut, "/api/admin/oidc", map[string]any{
		"issuer": p.server.URL, "clientId": "mediarr", "label": "Family login", "autoCreate": false, "linkAdmins": true,
	})
	expect(t, resp, body, http.StatusOK)
	p.says(map[string]any{"sub": "person-admin", "email": "ADMIN@example.com", "email_verified": true})
	resp, _ = p.signInWith(person, "/api/auth/oidc/start?next=/albums")
	if resp.StatusCode != http.StatusFound || resp.Header.Get("Location") != "/albums" {
		t.Fatalf("after signing in: %d %s", resp.StatusCode, resp.Header.Get("Location"))
	}
	resp, body = person.get("/api/admin/users")
	expect(t, resp, body, http.StatusOK)

	// Without an account, and with creating them off, not.
	stranger := s.client()
	p.says(map[string]any{"sub": "person-new", "email": "new@example.com", "email_verified": true})
	resp, _ = p.signInWith(stranger, "/api/auth/oidc/start")
	if !strings.Contains(resp.Header.Get("Location"), "sso=failed") {
		t.Fatalf("a stranger: %s", resp.Header.Get("Location"))
	}
	if got := s.count(t, "SELECT count(*) FROM users WHERE email='new@example.com'"); got != 0 {
		t.Fatal("an account was made")
	}

	// With it on, they get a plain account of their own, which can upload.
	s.turnOnOIDC(t, admin, p, true)
	p.says(map[string]any{"sub": "person-new", "email": "new@example.com", "email_verified": true, "name": "New Person"})
	stranger = s.client()
	resp, _ = p.signInWith(stranger, "/api/auth/oidc/start")
	if resp.Header.Get("Location") != "/" {
		t.Fatalf("created: %s", resp.Header.Get("Location"))
	}
	resp, body = stranger.get("/api/admin/users")
	expect(t, resp, body, http.StatusForbidden)
	if got := stranger.upload("a.jpg", randomBytes(t, 50), nil); got.StatusCode != http.StatusNoContent {
		t.Fatalf("upload: %d", got.StatusCode)
	}

	// An address the provider has not verified opens nothing, or it would open the admin's account.
	// Saying nothing about it counts as not verified.
	for _, claims := range []map[string]any{
		{"sub": "liar-1", "email": "admin@example.com", "email_verified": false},
		{"sub": "liar-2", "email": "admin@example.com"},
	} {
		p.says(claims)
		liar := s.client()
		resp, _ = p.signInWith(liar, "/api/auth/oidc/start")
		if !strings.Contains(resp.Header.Get("Location"), "sso=failed") {
			t.Fatalf("unverified: %s", resp.Header.Get("Location"))
		}
		resp, body = liar.get("/api/timeline/buckets")
		expect(t, resp, body, http.StatusUnauthorized)
	}

	// Someone known stays themselves, whatever email the provider reports later.
	p.says(map[string]any{"sub": "person-new", "email": "admin@example.com", "email_verified": true})
	stranger = s.client()
	resp, _ = p.signInWith(stranger, "/api/auth/oidc/start")
	if resp.Header.Get("Location") != "/" {
		t.Fatalf("known: %s", resp.Header.Get("Location"))
	}
	resp, body = stranger.get("/api/admin/users")
	expect(t, resp, body, http.StatusForbidden)

	// By default, an administrator is not linked by email at all.
	s.turnOnOIDC(t, admin, p, true)
	p.says(map[string]any{"sub": "other-admin", "email": "admin@example.com", "email_verified": true})
	claimed := s.client()
	resp, _ = p.signInWith(claimed, "/api/auth/oidc/start")
	if !strings.Contains(resp.Header.Get("Location"), "sso=failed") {
		t.Fatalf("admin by email: %s", resp.Header.Get("Location"))
	}
}

func TestSingleSignOnRefusesWhatItDidNotStart(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	p := newFakeProvider(t)
	s.turnOnOIDC(t, admin, p, true)
	p.says(map[string]any{"sub": "a", "email": "admin@example.com", "email_verified": true})

	// Coming back with no flow of its own: someone trying to sign a victim in to their account.
	victim := s.client()
	victim.http.CheckRedirect = func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }
	resp, _ := victim.get(oidcCallbackPath + "?code=x&state=y")
	if !strings.Contains(resp.Header.Get("Location"), "sso=failed") {
		t.Fatalf("no flow: %s", resp.Header.Get("Location"))
	}
	resp, body := victim.get("/api/timeline/buckets")
	expect(t, resp, body, http.StatusUnauthorized)

	// A wrong state on a flow that exists.
	c := s.client()
	c.http.CheckRedirect = victim.http.CheckRedirect
	resp, body = c.get("/api/auth/oidc/start")
	if resp.StatusCode != http.StatusFound {
		t.Fatalf("%s", body)
	}
	resp, _ = c.get(oidcCallbackPath + "?code=x&state=wrong")
	if !strings.Contains(resp.Header.Get("Location"), "sso=failed") {
		t.Fatalf("wrong state: %s", resp.Header.Get("Location"))
	}

	// After a sign-in, a link back to another site is ignored.
	if got := localPath("https://evil.example"); got != "/" {
		t.Errorf("next: %s", got)
	}
	if got := localPath("//evil.example"); got != "/" {
		t.Errorf("next: %s", got)
	}
	if got := localPath("/\t/evil.example"); got != "/" {
		t.Errorf("next with a tab: %q", got)
	}
}

func TestTheAppGetsItsSessionOnlyWithItsSecret(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	p := newFakeProvider(t)
	resp, body := admin.send(http.MethodPut, "/api/admin/oidc", map[string]any{
		"issuer": p.server.URL, "clientId": "mediarr", "label": "x", "autoCreate": false, "linkAdmins": true,
	})
	expect(t, resp, body, http.StatusOK)
	p.says(map[string]any{"sub": "a", "email": "admin@example.com", "email_verified": true})

	const verifier = "the-secret-only-the-app-knows"
	sum := sha256.Sum256([]byte(verifier))
	challenge := base64.RawURLEncoding.EncodeToString(sum[:])
	browser := s.client()
	resp, _ = p.signInWith(browser, "/api/auth/oidc/start?appChallenge="+challenge)
	location := resp.Header.Get("Location")
	if !strings.HasPrefix(location, oidcAppScheme+"?code=") {
		t.Fatalf("redirect: %s", location)
	}
	parsed, err := url.Parse(location)
	if err != nil {
		t.Fatal(err)
	}
	code := parsed.Query().Get("code")
	// The browser itself has no session: only the app gets one.
	resp, body = browser.get("/api/timeline/buckets")
	expect(t, resp, body, http.StatusUnauthorized)

	// Another app that caught the redirect has only the code.
	resp, body = s.client().post("/api/auth/oidc/exchange", api.OIDCExchange{Code: code, Verifier: "guess"})
	expect(t, resp, body, http.StatusUnauthorized)

	// The code works once, and that attempt used it up.
	app := s.client()
	resp, body = app.post("/api/auth/oidc/exchange", api.OIDCExchange{Code: code, Verifier: verifier})
	expect(t, resp, body, http.StatusUnauthorized)

	p.mu.Lock()
	p.nonce = ""
	p.mu.Unlock()
	// The app now waits on its own address, which leaves mediarr:// to sign-in links.
	resp, _ = p.signInWith(s.client(), "/api/auth/oidc/start?appReturn=mediarr-sso&appChallenge="+challenge)
	if location := resp.Header.Get("Location"); !strings.HasPrefix(location, oidcAppReturn+"?code=") {
		t.Fatalf("redirect: %s", location)
	}
	parsed, err = url.Parse(resp.Header.Get("Location"))
	if err != nil {
		t.Fatal(err)
	}
	resp, body = app.post("/api/auth/oidc/exchange", api.OIDCExchange{Code: parsed.Query().Get("code"), Verifier: verifier})
	expect(t, resp, body, http.StatusOK)
	resp, body = app.get("/api/timeline/buckets")
	expect(t, resp, body, http.StatusOK)
}

func TestPasskeysAreOfferedOnlyWhereTheyCanWork(t *testing.T) {
	check := func(host string, proto string, want bool) {
		t.Helper()
		r := httptest.NewRequestWithContext(context.Background(), http.MethodGet, "http://"+host+"/", http.NoBody)
		r.Host = host
		if proto != "" {
			r.Header.Set("X-Forwarded-Proto", proto)
		}
		if got := passkeysAvailable(r); got != want {
			t.Errorf("%s %s: %v", proto, host, got)
		}
	}
	check("192.168.1.10:9851", "", false)
	check("192.168.1.10:9851", "https", false)
	check("photos.example.com", "", false)
	check("photos.example.com", "https", true)
	check("localhost:9852", "", true)
}
