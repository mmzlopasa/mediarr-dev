package app

import (
	"net/http"
	"net/url"
	"strings"
	"testing"

	"github.com/mediarr-app/mediarr/server/internal/api"
)

func TestQRCodesAreReadableAndTyped(t *testing.T) {
	code, err := newQRCode()
	if err != nil || len(code) != qrCodeLength || strings.ContainsAny(code, "01IO") {
		t.Fatalf("%q %v", code, err)
	}
	if got := normalQRCode(" k7qm-2xpa "); got != "K7QM2XPA" {
		t.Fatalf("%q", got)
	}
	link, err := url.Parse(qrLink("http://192.168.1.20:9851", "K7QM2XPA"))
	if err != nil || link.Scheme != "mediarr" || link.Host != "sign-in" ||
		link.Query().Get("server") != "http://192.168.1.20:9851" || link.Query().Get("code") != "K7QM2XPA" {
		t.Fatalf("%v %v", link, err)
	}
}

func TestAPhoneSignsInWithAQRCodeOnceTheSignedInScreenAllowsIt(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	ana := s.user(admin, "ana@example.com")

	// Signed out, nobody can make a code.
	resp, body := s.client().post("/api/auth/qr", nil)
	expect(t, resp, body, http.StatusUnauthorized)

	resp, body = ana.post("/api/auth/qr", nil)
	expect(t, resp, body, http.StatusOK)
	shown := decode[api.QRSignIn](t, body)
	if len(shown.Code) != qrCodeLength+1 || !strings.HasPrefix(shown.Link, "mediarr://sign-in?") {
		t.Fatalf("%+v", shown)
	}

	// Someone else's screen cannot see or answer it.
	resp, body = admin.get("/api/auth/qr/" + shown.Id)
	expect(t, resp, body, http.StatusNotFound)

	// A wrong code tells nothing.
	phone := s.client()
	resp, body = phone.post("/api/auth/qr/redeem", api.QRRedeem{Code: "AAAA-AAAA", Device: "Pixel 9"})
	expect(t, resp, body, http.StatusUnauthorized)

	// The code is typed by hand, in lower case.
	resp, body = phone.post("/api/auth/qr/redeem", api.QRRedeem{Code: strings.ToLower(shown.Code), Device: "Pixel 9"})
	expect(t, resp, body, http.StatusOK)
	ticket := decode[api.QRTicket](t, body)

	// Whoever photographed the screen comes second, and gets nothing.
	resp, body = s.client().post("/api/auth/qr/redeem", api.QRRedeem{Code: shown.Code, Device: "iPhone"})
	expect(t, resp, body, http.StatusUnauthorized)

	resp, body = ana.get("/api/auth/qr/" + shown.Id)
	expect(t, resp, body, http.StatusOK)
	if state := decode[api.QRSignInState](t, body); state.Status != api.Requested || state.Device == nil || *state.Device != "Pixel 9" {
		t.Fatalf("%+v", state)
	}

	// The phone waits; the screen allows it; the phone is signed in as Ana.
	done := make(chan api.User, 1)
	go func() {
		resp, body := phone.post("/api/auth/qr/wait", ticket)
		if resp.StatusCode != http.StatusOK {
			t.Errorf("wait: %d %s", resp.StatusCode, body)
		}
		done <- decode[api.User](t, body)
	}()
	resp, body = ana.post("/api/auth/qr/"+shown.Id+"/answer", api.QRAnswer{Allow: true})
	expect(t, resp, body, http.StatusNoContent)
	if user := <-done; user.Email != "ana@example.com" {
		t.Fatalf("%+v", user)
	}
	resp, body = phone.get("/api/auth/status")
	expect(t, resp, body, http.StatusOK)
	if status := decode[api.AuthStatus](t, body); status.User == nil || status.User.Email != "ana@example.com" {
		t.Fatalf("%+v", status)
	}

	// The ticket worked once, and the code is used.
	resp, body = s.client().post("/api/auth/qr/wait", ticket)
	expect(t, resp, body, http.StatusUnauthorized)
	resp, body = ana.get("/api/auth/qr/" + shown.Id)
	expect(t, resp, body, http.StatusOK)
	if state := decode[api.QRSignInState](t, body); state.Status != api.Used {
		t.Fatalf("%+v", state)
	}
	resp, body = ana.post("/api/auth/qr/"+shown.Id+"/answer", api.QRAnswer{Allow: true})
	expect(t, resp, body, http.StatusConflict)
}

func TestADeniedQRSignInGivesNoSession(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	resp, body := admin.post("/api/auth/qr", nil)
	expect(t, resp, body, http.StatusOK)
	shown := decode[api.QRSignIn](t, body)
	stranger := s.client()
	resp, body = stranger.post("/api/auth/qr/redeem", api.QRRedeem{Code: shown.Code, Device: "Unknown"})
	expect(t, resp, body, http.StatusOK)
	ticket := decode[api.QRTicket](t, body)
	resp, body = admin.post("/api/auth/qr/"+shown.Id+"/answer", api.QRAnswer{Allow: false})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = stranger.post("/api/auth/qr/wait", ticket)
	expect(t, resp, body, http.StatusForbidden)
	resp, body = stranger.get("/api/auth/status")
	expect(t, resp, body, http.StatusOK)
	if status := decode[api.AuthStatus](t, body); status.User != nil {
		t.Fatal("a denied device was signed in")
	}
	// Without a name for the device, there is nothing to show; guessing is limited.
	resp, body = stranger.post("/api/auth/qr/redeem", api.QRRedeem{Code: shown.Code, Device: " "})
	expect(t, resp, body, http.StatusBadRequest)
	for range qrFailuresPerMin {
		stranger.post("/api/auth/qr/redeem", api.QRRedeem{Code: "BBBB-BBBB", Device: "x"})
	}
	resp, body = stranger.post("/api/auth/qr/redeem", api.QRRedeem{Code: "BBBB-BBBB", Device: "x"})
	expect(t, resp, body, http.StatusTooManyRequests)
}

func TestTheServerSaysHelloUnlessItIsHidden(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	resp, body := s.client().get(serverHelloPath)
	expect(t, resp, body, http.StatusOK)
	if hello := decode[api.ServerHello](t, body); hello.App != api.ServerHelloAppMediarr || hello.Version == "" {
		t.Fatalf("%+v", hello)
	}
	resp, body = admin.get("/api/admin/server-settings")
	expect(t, resp, body, http.StatusOK)
	settings := decode[api.ServerSettings](t, body)
	if settings.VisibleOnNetwork == nil || !*settings.VisibleOnNetwork {
		t.Fatalf("%+v", settings.VisibleOnNetwork)
	}
	if hello := decode[api.ServerHello](t, mustGet(t, s.client(), serverHelloPath)); hello.Name == nil || *hello.Name != "Mediarr" {
		t.Fatalf("%+v", hello)
	}

	// A name shows where people sign in and where apps find the server.
	settings.ServerName = new("  Kuća  ")
	resp, body = admin.send(http.MethodPut, "/api/admin/server-settings", settings)
	expect(t, resp, body, http.StatusOK)
	if hello := decode[api.ServerHello](t, mustGet(t, s.client(), serverHelloPath)); *hello.Name != "Kuća" {
		t.Fatalf("%+v", hello)
	}
	if methods := decode[api.AuthMethods](t, mustGet(t, s.client(), "/api/auth/methods")); methods.ServerName != "Kuća" {
		t.Fatalf("%+v", methods)
	}
	settings.ServerName = new("x" + strings.Repeat("y", 60))
	resp, body = admin.send(http.MethodPut, "/api/admin/server-settings", settings)
	expect(t, resp, body, http.StatusBadRequest)
	// Left out, the name stays.
	settings.ServerName = nil
	settings.VisibleOnNetwork = new(false)
	resp, body = admin.send(http.MethodPut, "/api/admin/server-settings", settings)
	expect(t, resp, body, http.StatusOK)
	if methods := decode[api.AuthMethods](t, mustGet(t, s.client(), "/api/auth/methods")); methods.ServerName != "Kuća" {
		t.Fatalf("%+v", methods)
	}
	resp, body = s.client().get(serverHelloPath)
	expect(t, resp, body, http.StatusNotFound)
}

func mustGet(t *testing.T, c *client, path string) []byte {
	t.Helper()
	resp, body := c.get(path)
	expect(t, resp, body, http.StatusOK)
	return body
}
