package app

import (
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

type receivedHook struct {
	event, signature string
	body             []byte
}

func (s *stack) hookReceiver(t *testing.T) (*httptest.Server, func() []receivedHook) {
	t.Helper()
	var mu sync.Mutex
	got := []receivedHook{}
	server := httptest.NewServer(http.HandlerFunc(func(_ http.ResponseWriter, r *http.Request) {
		body, _ := io.ReadAll(r.Body)
		mu.Lock()
		defer mu.Unlock()
		got = append(got, receivedHook{r.Header.Get("X-Mediarr-Event"), r.Header.Get("X-Mediarr-Signature"), body})
	}))
	t.Cleanup(server.Close)
	return server, func() []receivedHook {
		mu.Lock()
		defer mu.Unlock()
		return append([]receivedHook{}, got...)
	}
}

func TestWebhooksTellWhatHappenedAndAreSigned(t *testing.T) {
	s := newStack(t)
	s.startLocalHookWorker(t)
	c := s.admin()
	server, received := s.hookReceiver(t)
	resp, body := c.post("/api/admin/webhooks", map[string]any{"url": server.URL, "events": []string{"asset.ready"}})
	expect(t, resp, body, http.StatusCreated)
	created := decode[api.WebhookCreated](t, body)

	// Off, nothing is sent.
	first := uploadedID(t, c.upload("a.jpg", landscapeJPEG(t), nil))
	s.settle(t)
	time.Sleep(time.Second)
	if got := received(); len(got) != 0 {
		t.Fatalf("while off: %+v", got)
	}

	resp, body = c.send(http.MethodPut, "/api/admin/features/webhooks", map[string]bool{"enabled": true})
	expect(t, resp, body, http.StatusNoContent)
	second := uploadedID(t, c.upload("b.jpg", pictureOf(t, 120), nil))
	s.settle(t)
	end := time.Now().Add(30 * time.Second)
	for len(received()) == 0 && time.Now().Before(end) {
		time.Sleep(100 * time.Millisecond)
	}
	got := received()
	if len(got) != 1 || got[0].event != "asset.ready" || !strings.Contains(string(got[0].body), second) || strings.Contains(string(got[0].body), first) {
		t.Fatalf("%+v", got)
	}
	if got[0].signature != jobs.SignWebhook(created.Secret, got[0].body) {
		t.Fatal("the signature does not match")
	}
	// It says which asset by id, and nothing about what is in it.
	if strings.Contains(string(got[0].body), "b.jpg") {
		t.Fatalf("%s", got[0].body)
	}

	// The secret is shown once, and the result of the delivery shows in the list. The worker saves
	// the result just after the receiver has it, so the list may need a moment.
	end = time.Now().Add(10 * time.Second)
	for {
		resp, body = c.get("/api/admin/webhooks")
		expect(t, resp, body, http.StatusOK)
		if strings.Contains(string(body), created.Secret) {
			t.Fatalf("%s", body)
		}
		list := decode[[]api.Webhook](t, body)
		if len(list) == 1 && list[0].LastStatus == http.StatusOK {
			break
		}
		if len(list) != 1 || time.Now().After(end) {
			t.Fatalf("%s", body)
		}
		time.Sleep(100 * time.Millisecond)
	}

	// The test button sends one whatever the event.
	resp, body = c.post("/api/admin/webhooks/"+created.Id.String()+"/test", map[string]any{})
	expect(t, resp, body, http.StatusAccepted)
	end = time.Now().Add(30 * time.Second)
	for len(received()) < 2 && time.Now().Before(end) {
		time.Sleep(100 * time.Millisecond)
	}
	if got := received(); len(got) != 2 || got[1].event != "test" {
		t.Fatalf("%+v", got)
	}
}

func TestAWebhookCannotReachThisMachine(t *testing.T) {
	for address, blocked := range map[string]bool{
		"127.0.0.1": true, "::1": true, "169.254.169.254": true, "0.0.0.0": true,
		"192.168.1.20": false, "10.0.0.5": false, "8.8.8.8": false,
	} {
		if got := jobs.IsBlockedAddress(net.ParseIP(address)); got != blocked {
			t.Errorf("%s: %v", address, got)
		}
	}
	s := newStack(t)
	s.startWorker(t)
	c := s.admin()
	server, received := s.hookReceiver(t)
	resp, body := c.post("/api/admin/webhooks", map[string]any{"url": server.URL, "events": []string{"backup.finished"}})
	expect(t, resp, body, http.StatusCreated)
	created := decode[api.WebhookCreated](t, body)
	resp, body = c.post("/api/admin/webhooks/"+created.Id.String()+"/test", map[string]any{})
	expect(t, resp, body, http.StatusAccepted)
	end := time.Now().Add(30 * time.Second)
	for s.count(t, "SELECT count(*) FROM webhooks WHERE last_error <> ''") == 0 && time.Now().Before(end) {
		time.Sleep(100 * time.Millisecond)
	}
	if s.count(t, "SELECT count(*) FROM webhooks WHERE last_error LIKE '%cannot reach%'") != 1 {
		t.Fatal("the refusal is not recorded")
	}
	if len(received()) != 0 {
		t.Fatal("it got through")
	}
}

func TestWebhooksAreChecked(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	user := s.user(admin, "user@example.com")
	resp, body := user.post("/api/admin/webhooks", map[string]any{"url": "http://x", "events": []string{"asset.ready"}})
	expect(t, resp, body, http.StatusForbidden)
	for _, bad := range []map[string]any{
		{"url": "file:///etc/passwd", "events": []string{"asset.ready"}},
		{"url": "http://x", "events": []string{}},
		{"url": "http://x", "events": []string{"nonsense"}},
	} {
		resp, body = admin.post("/api/admin/webhooks", bad)
		expect(t, resp, body, http.StatusBadRequest)
	}
}

func TestKioskWaitsForItsSwitch(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	album := c.newAlbum(map[string]any{"title": "Frame"})
	link := c.newLink(album, map[string]any{})
	resp, body := s.client().get("/api/public/" + *link.Token)
	expect(t, resp, body, http.StatusOK)
	if decode[api.PublicLink](t, body).Kiosk {
		t.Fatalf("while off: %s", body)
	}
	resp, body = c.send(http.MethodPut, "/api/admin/features/kiosk", map[string]bool{"enabled": true})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = s.client().get("/api/public/" + *link.Token)
	expect(t, resp, body, http.StatusOK)
	if !decode[api.PublicLink](t, body).Kiosk {
		t.Fatalf("while on: %s", body)
	}
}
