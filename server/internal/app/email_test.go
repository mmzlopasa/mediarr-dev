package app

import (
	"bufio"
	"fmt"
	"net"
	"net/http"
	"regexp"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/mediarr-app/mediarr/server/internal/api"
)

// A small mail server that keeps what it is given.
type fakeSMTP struct {
	mu       sync.Mutex
	messages []string
	port     int
}

func (f *fakeSMTP) serve(conn net.Conn) {
	defer func() { _ = conn.Close() }()
	reader := bufio.NewReader(conn)
	say := func(line string) { _, _ = fmt.Fprintf(conn, "%s\r\n", line) }
	say("220 fake")
	for {
		line, err := reader.ReadString('\n')
		if err != nil {
			return
		}
		switch command := strings.ToUpper(strings.TrimSpace(line)); {
		case strings.HasPrefix(command, "EHLO"), strings.HasPrefix(command, "HELO"):
			say("250 fake")
		case strings.HasPrefix(command, "DATA"):
			say("354 go on")
			var message strings.Builder
			for {
				part, err := reader.ReadString('\n')
				if err != nil || part == ".\r\n" {
					break
				}
				message.WriteString(part)
			}
			f.mu.Lock()
			f.messages = append(f.messages, message.String())
			f.mu.Unlock()
			say("250 kept")
		case strings.HasPrefix(command, "QUIT"):
			say("221 bye")
			return
		default:
			say("250 ok")
		}
	}
}

func startFakeSMTP(t *testing.T) *fakeSMTP {
	t.Helper()
	listener, err := (&net.ListenConfig{}).Listen(t.Context(), "tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = listener.Close() })
	fake := &fakeSMTP{port: listener.Addr().(*net.TCPAddr).Port}
	go func() {
		for {
			conn, err := listener.Accept()
			if err != nil {
				return
			}
			go fake.serve(conn)
		}
	}()
	return fake
}

func (f *fakeSMTP) waitFor(t *testing.T, count int) []string {
	t.Helper()
	end := time.Now().Add(10 * time.Second)
	for time.Now().Before(end) {
		f.mu.Lock()
		got := append([]string(nil), f.messages...)
		f.mu.Unlock()
		if len(got) >= count {
			return got
		}
		time.Sleep(50 * time.Millisecond)
	}
	t.Fatalf("fewer than %d messages arrived", count)
	return nil
}

func turnOnEmail(t *testing.T, admin *client, fake *fakeSMTP) {
	t.Helper()
	resp, body := admin.send(http.MethodPut, "/api/admin/email", api.EmailSettingsUpdate{
		Enabled: true, Host: "127.0.0.1", Port: fake.port, From: "server@example.com",
		Security: api.EmailSettingsUpdateSecurityNone, PublicUrl: "https://photos.example.com/",
	})
	expect(t, resp, body, http.StatusOK)
}

func TestAnEmailReachesTheAdmin(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	fake := startFakeSMTP(t)
	resp, body := admin.post("/api/admin/email/test", map[string]any{})
	expect(t, resp, body, http.StatusConflict)
	turnOnEmail(t, admin, fake)
	resp, body = admin.get("/api/admin/email")
	expect(t, resp, body, http.StatusOK)
	if strings.Contains(string(body), `"password"`) {
		t.Fatalf("the password came back: %s", body)
	}
	resp, body = admin.post("/api/admin/email/test", map[string]any{})
	expect(t, resp, body, http.StatusNoContent)
	if got := fake.waitFor(t, 1)[0]; !strings.Contains(got, "To: admin@example.com") {
		t.Fatalf("%s", got)
	}
}

func TestAForgottenPasswordIsReset(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	person := s.user(admin, "person@example.com")
	fake := startFakeSMTP(t)
	turnOnEmail(t, admin, fake)

	// A stranger's address gets the same answer, and no message.
	resp, body := s.client().post("/api/auth/password/forgot", map[string]string{"email": "nobody@example.com"})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = s.client().post("/api/auth/password/forgot", map[string]string{"email": "person@example.com"})
	expect(t, resp, body, http.StatusNoContent)
	got := fake.waitFor(t, 1)
	if len(got) != 1 {
		t.Fatalf("%d messages", len(got))
	}
	// The address the administrator gave, whatever this request says it is for.
	match := regexp.MustCompile(`https://photos\.example\.com/login/reset\?token=(\S+)`).FindStringSubmatch(strings.ReplaceAll(got[0], "=\r\n", ""))
	if match == nil {
		t.Fatalf("no link: %s", got[0])
	}
	token := match[1]

	resp, body = s.client().post("/api/auth/password/reset", map[string]string{"token": "wrong", "newPassword": "a-completely-new-password"})
	expect(t, resp, body, http.StatusBadRequest)
	resp, body = s.client().post("/api/auth/password/reset", map[string]string{"token": token, "newPassword": "short"})
	expect(t, resp, body, http.StatusBadRequest)
	resp, body = s.client().post("/api/auth/password/reset", map[string]string{"token": token, "newPassword": "a-completely-new-password"})
	expect(t, resp, body, http.StatusNoContent)
	// Whoever was signed in is out, the old password is dead, and the link works once.
	resp, body = person.get("/api/timeline/buckets")
	expect(t, resp, body, http.StatusUnauthorized)
	resp, body = s.client().post("/api/auth/login", api.LoginRequest{Email: "person@example.com", Password: testPassword})
	expect(t, resp, body, http.StatusUnauthorized)
	resp, body = s.client().post("/api/auth/login", api.LoginRequest{Email: "person@example.com", Password: "a-completely-new-password"})
	expect(t, resp, body, http.StatusOK)
	resp, body = s.client().post("/api/auth/password/reset", map[string]string{"token": token, "newPassword": "another-new-password-1"})
	expect(t, resp, body, http.StatusBadRequest)
}

func TestNoResetWithoutTheServersOwnAddress(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	fake := startFakeSMTP(t)
	resp, body := admin.send(http.MethodPut, "/api/admin/email", api.EmailSettingsUpdate{
		Enabled: true, Host: "127.0.0.1", Port: fake.port, From: "server@example.com",
		Security: api.EmailSettingsUpdateSecurityNone,
	})
	expect(t, resp, body, http.StatusOK)
	resp, body = s.client().post("/api/auth/password/forgot", map[string]string{"email": "admin@example.com"})
	expect(t, resp, body, http.StatusNoContent)
	time.Sleep(300 * time.Millisecond)
	fake.mu.Lock()
	defer fake.mu.Unlock()
	if len(fake.messages) != 0 {
		t.Fatal("a link was built from nothing")
	}
}

func TestSharingAnAlbumTellsThePerson(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	person := s.user(admin, "person@example.com")
	fake := startFakeSMTP(t)
	turnOnEmail(t, admin, fake)
	// The person reads Croatian, and the message is in it.
	resp, body := person.send(http.MethodPatch, "/api/me", map[string]string{"language": "hr"})
	expect(t, resp, body, http.StatusOK)
	if user := decode[api.User](t, body); user.Language == nil || *user.Language != api.Hr {
		t.Fatalf("%s", body)
	}
	resp, body = person.send(http.MethodPatch, "/api/me", map[string]string{"language": "xx"})
	expect(t, resp, body, http.StatusBadRequest)
	resp, body = admin.post("/api/albums", api.AlbumCreate{Title: "Holiday"})
	expect(t, resp, body, http.StatusCreated)
	album := decode[api.Album](t, body).Id.String()
	resp, body = admin.send(http.MethodPut, "/api/albums/"+album+"/members/"+s.userID("person@example.com"), map[string]string{"role": "viewer"})
	if resp.StatusCode >= http.StatusBadRequest {
		t.Fatalf("%s", body)
	}
	got := fake.waitFor(t, 1)[0]
	if !strings.Contains(got, "To: person@example.com") || !strings.Contains(got, "Holiday") || !strings.Contains(got, "podijelio") {
		t.Fatalf("%s", got)
	}
}
