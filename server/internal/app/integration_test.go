package app

import (
	"bytes"
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/http/cookiejar"
	"net/http/httptest"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/pquerna/otp/totp"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/auth"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

const testPassword = "correct horse battery"

type stack struct {
	external string
	t        *testing.T
	pool     *pgxpool.Pool
	url      string
	library  string
	cache    string
	dbURL    string
	handler  http.Handler
}

// newStack creates a database, migrates it and starts the real handler.
func newStack(t *testing.T) *stack {
	t.Helper()
	base := os.Getenv("TEST_DATABASE_URL")
	if base == "" {
		t.Skip("TEST_DATABASE_URL is not set; run through `make test`")
	}
	ctx := context.Background()
	name := "test_" + strings.ReplaceAll(strings.ToLower(rand.Text()), "-", "")
	admin, err := pgx.Connect(ctx, base)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := admin.Exec(ctx, "CREATE DATABASE "+name); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		_, _ = admin.Exec(context.Background(), "DROP DATABASE "+name+" WITH (FORCE)")
		_ = admin.Close(context.Background())
	})

	parsed, err := url.Parse(base)
	if err != nil {
		t.Fatal(err)
	}
	parsed.Path = "/" + name
	dbURL := parsed.String()
	if err := db.Migrate(ctx, dbURL); err != nil {
		t.Fatal(err)
	}
	pool, err := pgxpool.New(ctx, dbURL)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	inserter, err := jobs.NewInserter(pool)
	if err != nil {
		t.Fatal(err)
	}
	library := filepath.Join(t.TempDir(), "library")
	cache := filepath.Join(t.TempDir(), "cache")
	external := t.TempDir()
	handler, err := NewHandler(Deps{Pinger: db.New(pool), Pool: pool, Inserter: inserter, LibraryPath: library, CachePath: cache, ExternalPath: external})
	if err != nil {
		t.Fatal(err)
	}
	server := httptest.NewServer(handler)
	t.Cleanup(server.Close)
	return &stack{t: t, pool: pool, url: server.URL, library: library, cache: cache, external: external, dbURL: dbURL, handler: handler}
}

type client struct {
	s    *stack
	http *http.Client
}

func (s *stack) client() *client {
	jar, err := cookiejar.New(nil)
	if err != nil {
		s.t.Fatal(err)
	}
	return &client{s: s, http: &http.Client{Jar: jar}}
}

func (c *client) do(method, path string, headers map[string]string, body io.Reader) (*http.Response, []byte) {
	c.s.t.Helper()
	req, err := http.NewRequestWithContext(context.Background(), method, c.s.url+path, body)
	if err != nil {
		c.s.t.Fatal(err)
	}
	for key, value := range headers {
		req.Header.Set(key, value)
	}
	resp, err := c.http.Do(req)
	if err != nil {
		c.s.t.Fatal(err)
	}
	defer func() { _ = resp.Body.Close() }()
	data, err := io.ReadAll(resp.Body)
	if err != nil {
		c.s.t.Fatal(err)
	}
	return resp, data
}

func (c *client) post(path string, payload any) (*http.Response, []byte) {
	c.s.t.Helper()
	encoded, err := json.Marshal(payload)
	if err != nil {
		c.s.t.Fatal(err)
	}
	return c.do(http.MethodPost, path, map[string]string{"Content-Type": "application/json"}, bytes.NewReader(encoded))
}

// doHost makes a request as if the server were at another address, which passkeys depend on.
func (c *client) doHost(host, method, path string, headers map[string]string, body string) (*http.Response, []byte) {
	c.s.t.Helper()
	request, err := http.NewRequestWithContext(context.Background(), method, c.s.url+path, strings.NewReader(body))
	if err != nil {
		c.s.t.Fatal(err)
	}
	request.Host = host
	// The cookie jar goes by the address asked for, so it would keep the session back.
	for _, cookie := range c.http.Jar.Cookies(request.URL) {
		request.AddCookie(cookie)
	}
	for key, value := range headers {
		request.Header.Set(key, value)
	}
	response, err := c.http.Do(request)
	if err != nil {
		c.s.t.Fatal(err)
	}
	defer func() { _ = response.Body.Close() }()
	data, err := io.ReadAll(response.Body)
	if err != nil {
		c.s.t.Fatal(err)
	}
	return response, data
}

func (c *client) get(path string) (*http.Response, []byte) {
	c.s.t.Helper()
	return c.do(http.MethodGet, path, nil, nil)
}

func expect(t *testing.T, resp *http.Response, body []byte, code int) {
	t.Helper()
	if resp.StatusCode != code {
		t.Fatalf("%s %s: status %d, want %d: %s", resp.Request.Method, resp.Request.URL.Path, resp.StatusCode, code, body)
	}
}

func (s *stack) admin() *client {
	s.t.Helper()
	c := s.client()
	resp, body := c.post("/api/auth/setup", api.SetupRequest{Email: "admin@example.com", Name: "Admin", Password: testPassword})
	expect(s.t, resp, body, http.StatusCreated)
	return c
}

func (s *stack) user(admin *client, email string) *client {
	s.t.Helper()
	resp, body := admin.post("/api/admin/users", api.CreateUserRequest{Email: email, Name: "User", Password: testPassword})
	expect(s.t, resp, body, http.StatusCreated)
	c := s.client()
	resp, body = c.post("/api/auth/login", api.LoginRequest{Email: email, Password: testPassword})
	expect(s.t, resp, body, http.StatusOK)
	return c
}

func TestSetupOnlyOnce(t *testing.T) {
	s := newStack(t)
	c := s.client()

	var status api.AuthStatus
	resp, body := c.get("/api/auth/status")
	expect(t, resp, body, http.StatusOK)
	if err := json.Unmarshal(body, &status); err != nil || !status.SetupRequired || status.User != nil {
		t.Fatalf("status: %s, %v", body, err)
	}

	resp, body = c.post("/api/auth/setup", api.SetupRequest{Email: "bad", Name: "A", Password: testPassword})
	expect(t, resp, body, http.StatusBadRequest)
	resp, body = c.post("/api/auth/setup", api.SetupRequest{Email: "a@example.com", Name: "A", Password: "short"})
	expect(t, resp, body, http.StatusBadRequest)

	// Simultaneous requests must create exactly one administrator.
	var wg sync.WaitGroup
	codes := make([]int, 8)
	for i := range codes {
		wg.Go(func() {
			r, _ := s.client().post("/api/auth/setup", api.SetupRequest{Email: fmt.Sprintf("a%d@example.com", i), Name: "A", Password: testPassword})
			codes[i] = r.StatusCode
		})
	}
	wg.Wait()
	created := 0
	for _, code := range codes {
		if code == http.StatusCreated {
			created++
		} else if code != http.StatusConflict {
			t.Errorf("status %d", code)
		}
	}
	if created != 1 {
		t.Errorf("%d administrators created", created)
	}
}

func TestLogin(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	s.user(admin, "ana@example.com")

	c := s.client()
	resp, body := c.get("/api/admin/users")
	expect(t, resp, body, http.StatusUnauthorized)

	resp, body = c.post("/api/auth/login", api.LoginRequest{Email: "ana@example.com", Password: "wrong password here"})
	expect(t, resp, body, http.StatusUnauthorized)
	resp, body = c.post("/api/auth/login", api.LoginRequest{Email: "nobody@example.com", Password: testPassword})
	expect(t, resp, body, http.StatusUnauthorized)

	resp, body = c.post("/api/auth/login", api.LoginRequest{Email: " ANA@example.com ", Password: testPassword})
	expect(t, resp, body, http.StatusOK)
	var sessionCookieFound bool
	for _, cookie := range resp.Cookies() {
		if cookie.Name != sessionCookie {
			continue
		}
		sessionCookieFound = true
		if !cookie.HttpOnly || cookie.SameSite != http.SameSiteLaxMode {
			t.Errorf("cookie flags: %+v", cookie)
		}
		if cookie.Secure {
			t.Error("Secure cookie over plain HTTP would break sign-in by IP address")
		}
	}
	if !sessionCookieFound {
		t.Fatal("no session cookie")
	}

	// A normal user cannot reach administrator endpoints.
	resp, body = c.get("/api/admin/users")
	expect(t, resp, body, http.StatusForbidden)

	resp, body = c.post("/api/auth/logout", nil)
	expect(t, resp, body, http.StatusNoContent)
	resp, body = c.get("/api/assets")
	expect(t, resp, body, http.StatusUnauthorized)
}

func TestLoginCookieIsSecureBehindHTTPSProxy(t *testing.T) {
	s := newStack(t)
	s.admin()
	encoded, err := json.Marshal(api.LoginRequest{Email: "admin@example.com", Password: testPassword})
	if err != nil {
		t.Fatal(err)
	}
	resp, body := s.client().do(http.MethodPost, "/api/auth/login",
		map[string]string{"Content-Type": "application/json", "X-Forwarded-Proto": "https"}, bytes.NewReader(encoded))
	expect(t, resp, body, http.StatusOK)
	for _, cookie := range resp.Cookies() {
		if cookie.Name == sessionCookie && !cookie.Secure {
			t.Error("cookie is not Secure behind an HTTPS proxy")
		}
	}
}

func TestLoginRateLimit(t *testing.T) {
	s := newStack(t)
	s.admin()
	c := s.client()
	for range loginFailuresUser {
		resp, body := c.post("/api/auth/login", api.LoginRequest{Email: "admin@example.com", Password: "wrong password here"})
		expect(t, resp, body, http.StatusUnauthorized)
	}
	resp, body := c.post("/api/auth/login", api.LoginRequest{Email: "admin@example.com", Password: testPassword})
	expect(t, resp, body, http.StatusTooManyRequests)
}

func TestFormPostIsRejected(t *testing.T) {
	s := newStack(t)
	resp, body := s.client().do(http.MethodPost, "/api/auth/login",
		map[string]string{"Content-Type": "application/x-www-form-urlencoded"}, strings.NewReader("email=a&password=b"))
	expect(t, resp, body, http.StatusUnsupportedMediaType)
}

func TestChangePasswordEndsOtherSessions(t *testing.T) {
	s := newStack(t)
	first := s.admin()
	second := s.client()
	resp, body := second.post("/api/auth/login", api.LoginRequest{Email: "admin@example.com", Password: testPassword})
	expect(t, resp, body, http.StatusOK)

	resp, body = first.post("/api/me/password", api.ChangePasswordRequest{CurrentPassword: "wrong password here", NewPassword: "a brand new password"})
	expect(t, resp, body, http.StatusUnauthorized)
	resp, body = first.post("/api/me/password", api.ChangePasswordRequest{CurrentPassword: testPassword, NewPassword: "a brand new password"})
	expect(t, resp, body, http.StatusNoContent)

	resp, body = first.get("/api/admin/users")
	expect(t, resp, body, http.StatusOK)
	resp, body = second.get("/api/admin/users")
	expect(t, resp, body, http.StatusUnauthorized)
}

func TestTotp(t *testing.T) {
	s := newStack(t)
	c := s.admin()

	resp, body := c.post("/api/me/totp/setup", nil)
	expect(t, resp, body, http.StatusOK)
	var setup api.TotpSetup
	if err := json.Unmarshal(body, &setup); err != nil {
		t.Fatal(err)
	}
	resp, body = c.post("/api/me/totp/enable", api.TotpCode{Code: "000000"})
	expect(t, resp, body, http.StatusBadRequest)

	// Enable with the previous step's code, so the current step is still free for sign-in.
	now := time.Now()
	previous, err := totp.GenerateCode(setup.Secret, now.Add(-totpPeriod*time.Second))
	if err != nil {
		t.Fatal(err)
	}
	resp, body = c.post("/api/me/totp/enable", api.TotpCode{Code: previous})
	expect(t, resp, body, http.StatusNoContent)

	fresh := s.client()
	resp, body = fresh.post("/api/auth/login", api.LoginRequest{Email: "admin@example.com", Password: testPassword})
	expect(t, resp, body, http.StatusUnauthorized)
	var loginError api.LoginError
	if err := json.Unmarshal(body, &loginError); err != nil || !loginError.TotpRequired {
		t.Fatalf("login error: %s", body)
	}

	wrong := "000000"
	resp, body = fresh.post("/api/auth/login", api.LoginRequest{Email: "admin@example.com", Password: testPassword, TotpCode: &wrong})
	expect(t, resp, body, http.StatusUnauthorized)

	code, err := totp.GenerateCode(setup.Secret, time.Now())
	if err != nil {
		t.Fatal(err)
	}
	resp, body = fresh.post("/api/auth/login", api.LoginRequest{Email: "admin@example.com", Password: testPassword, TotpCode: &code})
	expect(t, resp, body, http.StatusOK)

	// The same code must not work twice.
	resp, body = s.client().post("/api/auth/login", api.LoginRequest{Email: "admin@example.com", Password: testPassword, TotpCode: &code})
	expect(t, resp, body, http.StatusUnauthorized)

	resp, body = fresh.post("/api/me/totp/disable", api.PasswordConfirm{Password: "wrong password here"})
	expect(t, resp, body, http.StatusUnauthorized)
	resp, body = fresh.post("/api/me/totp/disable", api.PasswordConfirm{Password: testPassword})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = s.client().post("/api/auth/login", api.LoginRequest{Email: "admin@example.com", Password: testPassword})
	expect(t, resp, body, http.StatusOK)
}

func TestAPIKey(t *testing.T) {
	s := newStack(t)
	s.admin()
	ctx := context.Background()
	q := db.New(s.pool)
	user, err := q.GetUserByEmail(ctx, "admin@example.com")
	if err != nil {
		t.Fatal(err)
	}
	token, hash, err := auth.NewToken()
	if err != nil {
		t.Fatal(err)
	}
	if _, err := q.CreateAPIKey(ctx, db.CreateAPIKeyParams{UserID: user.ID, Name: "test", KeyHash: hash, Scopes: []string{"admin"}}); err != nil {
		t.Fatal(err)
	}
	c := s.client()
	resp, body := c.do(http.MethodGet, "/api/admin/users", map[string]string{apiKeyHeader: token}, nil)
	expect(t, resp, body, http.StatusOK)
	resp, body = c.do(http.MethodGet, "/api/admin/users", map[string]string{apiKeyHeader: "wrong"}, nil)
	expect(t, resp, body, http.StatusUnauthorized)
}

func tusMeta(pairs map[string]string) string {
	parts := make([]string, 0, len(pairs))
	for key, value := range pairs {
		parts = append(parts, key+" "+base64.StdEncoding.EncodeToString([]byte(value)))
	}
	return strings.Join(parts, ",")
}

func (c *client) createUpload(size int, meta map[string]string) (*http.Response, []byte) {
	c.s.t.Helper()
	return c.do(http.MethodPost, "/api/uploads", map[string]string{
		"Tus-Resumable":   "1.0.0",
		"Upload-Length":   strconv.Itoa(size),
		"Upload-Metadata": tusMeta(meta),
	}, nil)
}

func (c *client) patch(path string, offset int, data []byte) (*http.Response, []byte) {
	c.s.t.Helper()
	return c.do(http.MethodPatch, path, map[string]string{
		"Tus-Resumable": "1.0.0",
		"Upload-Offset": strconv.Itoa(offset),
		"Content-Type":  "application/offset+octet-stream",
	}, bytes.NewReader(data))
}

func uploadPath(t *testing.T, resp *http.Response) string {
	t.Helper()
	location, err := resp.Location()
	if err != nil {
		t.Fatal(err)
	}
	return location.Path
}

func (c *client) upload(name string, data []byte, meta map[string]string) *http.Response {
	c.s.t.Helper()
	all := map[string]string{"filename": name}
	for key, value := range meta {
		all[key] = value
	}
	resp, body := c.createUpload(len(data), all)
	expect(c.s.t, resp, body, http.StatusCreated)
	resp, _ = c.patch(uploadPath(c.s.t, resp), 0, data)
	return resp
}

func randomBytes(t *testing.T, size int) []byte {
	t.Helper()
	data := make([]byte, size)
	if _, err := rand.Read(data); err != nil {
		t.Fatal(err)
	}
	return data
}

func (s *stack) assetFile(id string) (path string, mode os.FileMode) {
	s.t.Helper()
	var uuidValue [16]byte
	raw, err := hex.DecodeString(strings.ReplaceAll(id, "-", ""))
	if err != nil {
		s.t.Fatal(err)
	}
	copy(uuidValue[:], raw)
	var stored string
	if err := s.pool.QueryRow(context.Background(), "SELECT original_path FROM assets WHERE id = $1", uuidValue).Scan(&stored); err != nil {
		s.t.Fatal(err)
	}
	info, err := os.Stat(stored)
	if err != nil {
		s.t.Fatal(err)
	}
	return stored, info.Mode()
}

func TestUploadResumesAndStaysIntact(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	data := randomBytes(t, 1<<20)
	sum := sha256.Sum256(data)

	resp, body := c.createUpload(len(data), map[string]string{"filename": "../../evil name.jpg", "user_id": "someone-else"})
	expect(t, resp, body, http.StatusCreated)
	path := uploadPath(t, resp)

	half := len(data) / 2
	resp, body = c.patch(path, 0, data[:half])
	expect(t, resp, body, http.StatusNoContent)

	// As after a dropped connection: ask how far the upload got, then continue from there.
	resp, body = c.do(http.MethodHead, path, map[string]string{"Tus-Resumable": "1.0.0"}, nil)
	expect(t, resp, body, http.StatusOK)
	offset, err := strconv.Atoi(resp.Header.Get("Upload-Offset"))
	if err != nil || offset != half {
		t.Fatalf("offset %q", resp.Header.Get("Upload-Offset"))
	}
	resp, body = c.patch(path, offset, data[offset:])
	expect(t, resp, body, http.StatusNoContent)
	id := resp.Header.Get("X-Asset-Id")
	if id == "" || resp.Header.Get("X-Asset-Duplicate") != "false" {
		t.Fatalf("headers: %v", resp.Header)
	}

	stored, mode := s.assetFile(id)
	got, err := os.ReadFile(stored)
	if err != nil {
		t.Fatal(err)
	}
	if sha256.Sum256(got) != sum {
		t.Error("the stored file differs from the upload")
	}
	if mode.Perm()&0o222 != 0 {
		t.Errorf("original is writable: %v", mode)
	}
	rel, err := filepath.Rel(s.library, stored)
	if err != nil || strings.HasPrefix(rel, "..") || !strings.HasSuffix(stored, hex.EncodeToString(sum[:])[:16]+"-evil name.jpg") {
		t.Errorf("stored at %s", stored)
	}

	var owner string
	if err := s.pool.QueryRow(context.Background(), "SELECT u.email FROM assets a JOIN users u ON u.id = a.user_id").Scan(&owner); err != nil {
		t.Fatal(err)
	}
	if owner != "admin@example.com" {
		t.Errorf("owner %s: the client must not choose the owner", owner)
	}
	entries, err := os.ReadDir(filepath.Join(s.library, ".tmp"))
	if err != nil {
		t.Fatal(err)
	}
	for _, entry := range entries {
		if !strings.HasSuffix(entry.Name(), ".lock") {
			t.Errorf("left in the upload directory: %s", entry.Name())
		}
	}
}

func TestDedup(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	other := s.user(admin, "ana@example.com")
	data := randomBytes(t, 4096)
	sum := sha256.Sum256(data)
	sumHex := hex.EncodeToString(sum[:])

	resp, body := admin.post("/api/assets/check", api.ChecksumCheckRequest{Checksums: []string{sumHex}})
	expect(t, resp, body, http.StatusOK)
	if strings.Contains(string(body), sumHex) {
		t.Error("reported a checksum that does not exist")
	}

	first := admin.upload("a.jpg", data, nil)
	if first.Header.Get("X-Asset-Duplicate") != "false" {
		t.Fatalf("first upload: %v", first.Header)
	}
	stored, _ := s.assetFile(first.Header.Get("X-Asset-Id"))

	second := admin.upload("renamed.jpg", data, nil)
	if second.Header.Get("X-Asset-Duplicate") != "true" || second.Header.Get("X-Asset-Id") != first.Header.Get("X-Asset-Id") {
		t.Errorf("second upload: %v", second.Header)
	}
	if _, err := os.Stat(stored); err != nil {
		t.Errorf("dedup removed the original: %v", err)
	}

	resp, body = admin.post("/api/assets/check", api.ChecksumCheckRequest{Checksums: []string{sumHex}})
	expect(t, resp, body, http.StatusOK)
	if !strings.Contains(string(body), sumHex) {
		t.Errorf("did not report the existing checksum: %s", body)
	}
	var answer api.ChecksumCheckResponse
	if err := json.Unmarshal(body, &answer); err != nil || len(answer.Ids) != len(answer.Existing) {
		t.Errorf("checksums without their asset: %s, %v", body, err)
	}

	// Libraries are private, so another user's copy is a separate asset.
	resp, body = other.post("/api/assets/check", api.ChecksumCheckRequest{Checksums: []string{sumHex}})
	expect(t, resp, body, http.StatusOK)
	if strings.Contains(string(body), sumHex) {
		t.Error("revealed another user's file")
	}
	third := other.upload("a.jpg", data, nil)
	if third.Header.Get("X-Asset-Duplicate") != "false" {
		t.Errorf("other user: %v", third.Header)
	}

	var rows int
	if err := s.pool.QueryRow(context.Background(), "SELECT count(*) FROM assets").Scan(&rows); err != nil {
		t.Fatal(err)
	}
	if rows != 2 {
		t.Errorf("%d assets, want 2", rows)
	}
}

func TestFirstUploadsOfANewUserCanRunTogether(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	user := s.user(admin, "ana@example.com")

	const uploads = 8
	var wg sync.WaitGroup
	codes := make([]int, uploads)
	for i := range uploads {
		data := randomBytes(t, 2048)
		wg.Go(func() {
			codes[i] = user.upload(fmt.Sprintf("%d.jpg", i), data, nil).StatusCode
		})
	}
	wg.Wait()
	for i, code := range codes {
		if code != http.StatusNoContent {
			t.Errorf("upload %d: status %d", i, code)
		}
	}
	var libraries int
	if err := s.pool.QueryRow(context.Background(), "SELECT count(*) FROM libraries").Scan(&libraries); err != nil {
		t.Fatal(err)
	}
	if libraries != 1 {
		t.Errorf("%d libraries, want 1", libraries)
	}
}

// A background transfer on iOS can only send one file in one request.
func TestWholeFileInOneRequestWithAKey(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	resp, body := admin.post("/api/me/device-keys", api.CreateDeviceKeyRequest{Name: "iPhone"})
	expect(t, resp, body, http.StatusCreated)
	var key api.DeviceKey
	if err := json.Unmarshal(body, &key); err != nil {
		t.Fatal(err)
	}

	send := func(data []byte, sum string) *http.Response {
		t.Helper()
		resp, _ := s.client().do(http.MethodPost, "/api/uploads", map[string]string{
			apiKeyHeader:      key.Key,
			"Tus-Resumable":   "1.0.0",
			"Upload-Length":   strconv.Itoa(len(data)),
			"Upload-Metadata": tusMeta(map[string]string{"filename": "IMG_1.HEIC", "checksum": sum}),
			"Content-Type":    "application/offset+octet-stream",
		}, bytes.NewReader(data))
		return resp
	}
	data := randomBytes(t, 2048)
	digest := sha256.Sum256(data)
	sum := hex.EncodeToString(digest[:])

	first := send(data, sum)
	if first.StatusCode != http.StatusCreated || first.Header.Get("X-Asset-Id") == "" || first.Header.Get("X-Asset-Duplicate") != "false" {
		t.Fatalf("first: %d %v", first.StatusCode, first.Header)
	}
	stored, _ := s.assetFile(first.Header.Get("X-Asset-Id"))
	got, err := os.ReadFile(stored)
	if err != nil || !bytes.Equal(got, data) {
		t.Errorf("stored file differs: %v", err)
	}

	second := send(data, sum)
	if second.StatusCode != http.StatusCreated || second.Header.Get("X-Asset-Id") != first.Header.Get("X-Asset-Id") || second.Header.Get("X-Asset-Duplicate") != "true" {
		t.Errorf("second: %d %v", second.StatusCode, second.Header)
	}

	// A file damaged on the way is refused.
	if bad := send(randomBytes(t, 2048), sum); bad.StatusCode != 460 {
		t.Errorf("wrong checksum: %d", bad.StatusCode)
	}

	resp, body = admin.do(http.MethodDelete, "/api/me/device-keys/"+key.Id.String(), nil, nil)
	expect(t, resp, body, http.StatusNoContent)
	if revoked := send(randomBytes(t, 100), ""); revoked.StatusCode != http.StatusUnauthorized {
		t.Errorf("revoked key: %d", revoked.StatusCode)
	}
}

func TestDeviceKeyCannotBeRevokedByAnotherUser(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	other := s.user(admin, "ana@example.com")
	resp, body := admin.post("/api/me/device-keys", api.CreateDeviceKeyRequest{Name: "iPhone"})
	expect(t, resp, body, http.StatusCreated)
	var key api.DeviceKey
	if err := json.Unmarshal(body, &key); err != nil {
		t.Fatal(err)
	}
	resp, body = other.do(http.MethodDelete, "/api/me/device-keys/"+key.Id.String(), nil, nil)
	expect(t, resp, body, http.StatusNoContent)
	resp, body = s.client().sendWith(http.MethodPost, "/api/assets/check", map[string]string{apiKeyHeader: key.Key}, map[string]any{"checksums": []string{}})
	expect(t, resp, body, http.StatusOK)

	resp, body = s.client().post("/api/me/device-keys", api.CreateDeviceKeyRequest{Name: "x"})
	expect(t, resp, body, http.StatusUnauthorized)
	resp, body = admin.post("/api/me/device-keys", api.CreateDeviceKeyRequest{Name: "  "})
	expect(t, resp, body, http.StatusBadRequest)
}

func TestChecksumMismatchIsRejected(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	resp := c.upload("a.jpg", randomBytes(t, 1024), map[string]string{"checksum": strings.Repeat("ab", 32)})
	if resp.StatusCode != 460 {
		t.Fatalf("status %d", resp.StatusCode)
	}
	var rows int
	if err := s.pool.QueryRow(context.Background(), "SELECT count(*) FROM assets").Scan(&rows); err != nil {
		t.Fatal(err)
	}
	if rows != 0 {
		t.Error("stored a file with a wrong checksum")
	}
}

func TestUploadsAreReservedForTheirOwner(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	other := s.user(admin, "ana@example.com")

	resp, body := s.client().createUpload(10, map[string]string{"filename": "a.jpg"})
	expect(t, resp, body, http.StatusUnauthorized)

	resp, body = admin.createUpload(10, map[string]string{"filename": "a.jpg"})
	expect(t, resp, body, http.StatusCreated)
	path := uploadPath(t, resp)

	resp, body = other.do(http.MethodHead, path, map[string]string{"Tus-Resumable": "1.0.0"}, nil)
	expect(t, resp, body, http.StatusNotFound)
	resp, body = other.patch(path, 0, []byte("0123456789"))
	expect(t, resp, body, http.StatusNotFound)
	resp, body = other.do(http.MethodDelete, path, map[string]string{"Tus-Resumable": "1.0.0"}, nil)
	expect(t, resp, body, http.StatusNotFound)
	resp, body = s.client().patch(path, 0, []byte("0123456789"))
	expect(t, resp, body, http.StatusUnauthorized)

	// IDs that are not ours never reach the file system.
	resp, body = admin.do(http.MethodHead, "/api/uploads/..%2f..%2fetc", map[string]string{"Tus-Resumable": "1.0.0"}, nil)
	if resp.StatusCode != http.StatusNotFound {
		t.Errorf("traversal id: %d %s", resp.StatusCode, body)
	}

	resp, body = admin.do(http.MethodDelete, path, map[string]string{"Tus-Resumable": "1.0.0"}, nil)
	expect(t, resp, body, http.StatusNoContent)
}

func TestAssetsAreListedOnlyForTheirOwner(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	other := s.user(admin, "ana@example.com")
	admin.upload("mine.jpg", randomBytes(t, 100), nil)

	resp, body := other.get("/api/assets")
	expect(t, resp, body, http.StatusOK)
	var list api.AssetList
	if err := json.Unmarshal(body, &list); err != nil {
		t.Fatal(err)
	}
	if list.Total != 0 || len(list.Items) != 0 {
		t.Errorf("saw another user's assets: %s", body)
	}
}

func TestMigrationsGoDownAndUp(t *testing.T) {
	s := newStack(t)
	ctx := context.Background()
	// Every schema migration after the first must be able to go down.
	for range 33 {
		if err := db.MigrateDown(ctx, s.dbURL); err != nil {
			t.Fatal(err)
		}
	}
	var exists bool
	if err := s.pool.QueryRow(ctx, "SELECT to_regclass('assets') IS NOT NULL").Scan(&exists); err != nil {
		t.Fatal(err)
	}
	if exists {
		t.Error("down did not remove the tables")
	}
	if err := db.Migrate(ctx, s.dbURL); err != nil {
		t.Fatal(err)
	}
}

// waitForAsset polls until the worker finishes with the asset.
func waitForAsset(t *testing.T, c *client, name string) api.Asset {
	t.Helper()
	deadline := time.Now().Add(60 * time.Second)
	for time.Now().Before(deadline) {
		resp, body := c.get("/api/assets")
		expect(t, resp, body, http.StatusOK)
		var list api.AssetList
		if err := json.Unmarshal(body, &list); err != nil {
			t.Fatal(err)
		}
		for _, asset := range list.Items {
			if asset.OriginalName == name && asset.Status != api.AssetStatusProcessing {
				return asset
			}
		}
		time.Sleep(100 * time.Millisecond)
	}
	t.Fatalf("%s was not processed in time", name)
	return api.Asset{}
}

func TestWorkerProcessesUploads(t *testing.T) {
	if _, err := exec.LookPath("vips"); err != nil {
		t.Skip("media tools are not installed; run through `make test`")
	}
	s := newStack(t)
	c := s.admin()

	ctx, cancel := context.WithCancel(context.Background())
	worker, err := jobs.NewWorker(s.pool, jobs.Options{Concurrency: 2, LibraryPath: s.library, CachePath: s.cache})
	if err != nil {
		t.Fatal(err)
	}
	done := make(chan error, 1)
	go func() { done <- jobs.Run(ctx, worker) }()
	t.Cleanup(func() {
		cancel()
		if err := <-done; err != nil {
			t.Errorf("worker: %v", err)
		}
	})

	image := filepath.Join(t.TempDir(), "photo.jpg")
	if out, err := exec.Command("vips", "gaussnoise", image, "1600", "1200").CombinedOutput(); err != nil {
		t.Fatalf("%v: %s", err, out)
	}
	if out, err := exec.Command("exiftool", "-q", "-overwrite_original", "-Make=Test", "-DateTimeOriginal=2024:05:06 07:08:09", "-OffsetTimeOriginal=+02:00", image).CombinedOutput(); err != nil {
		t.Fatalf("%v: %s", err, out)
	}
	data, err := os.ReadFile(image)
	if err != nil {
		t.Fatal(err)
	}

	resp := c.upload("photo.jpg", data, nil)
	if resp.StatusCode != http.StatusNoContent {
		t.Fatalf("upload: %d", resp.StatusCode)
	}
	asset := waitForAsset(t, c, "photo.jpg")
	if asset.Status != api.AssetStatusReady || asset.Kind != api.AssetKindPhoto || asset.Blurhash == nil || asset.Width == nil || *asset.Width != 1600 {
		t.Fatalf("asset: %+v, error %v", asset, asset.Error)
	}
	if asset.TakenAt == nil || !asset.TakenAt.Equal(time.Date(2024, 5, 6, 5, 8, 9, 0, time.UTC)) {
		t.Errorf("taken at %v", asset.TakenAt)
	}

	var files int
	if err := s.pool.QueryRow(ctx, "SELECT count(*) FROM asset_files WHERE kind LIKE 'thumb%'").Scan(&files); err != nil {
		t.Fatal(err)
	}
	if files != 2 {
		t.Errorf("%d thumbnails", files)
	}
	var cameraMake string
	if err := s.pool.QueryRow(ctx, "SELECT make FROM exif").Scan(&cameraMake); err != nil {
		t.Fatal(err)
	}
	if cameraMake != "Test" {
		t.Errorf("make %q", cameraMake)
	}

	// A broken file shows an error instead of retrying or stopping the queue.
	if resp := c.upload("broken.jpg", []byte("this is not an image"), nil); resp.StatusCode != http.StatusNoContent {
		t.Fatalf("upload: %d", resp.StatusCode)
	}
	broken := waitForAsset(t, c, "broken.jpg")
	if broken.Status != api.AssetStatusFailed || broken.Error == nil {
		t.Errorf("broken: %+v", broken)
	}

	stored, _ := s.assetFile(asset.Id.String())
	after, err := os.ReadFile(stored)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(after, data) {
		t.Error("processing changed the original")
	}
}
