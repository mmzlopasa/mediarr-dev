package app

import (
	"context"
	"net/http"
	"strings"
	"testing"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
)

func TestAllowlistParsing(t *testing.T) {
	allowed, err := parseAllowlist([]string{"192.168.1.0/24", " 10.0.0.5 ", "", "2001:db8::/32"})
	if err != nil {
		t.Fatal(err)
	}
	for address, want := range map[string]bool{
		"192.168.1.77": true, "10.0.0.5": true, "10.0.0.6": false, "2001:db8::1": true,
		"::ffff:192.168.1.1": true, "8.8.8.8": false, "nonsense": false, "192.168.1.77:5000": true,
	} {
		if got := addressAllowed(address, allowed); got != want {
			t.Errorf("%s: %v", address, got)
		}
	}
	if _, err := parseAllowlist([]string{"not an address"}); err == nil {
		t.Fatal("a wrong line was accepted")
	}
}

func TestIPAllowlistKeepsStrangersOut(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	update := func(list ...string) (*http.Response, []byte) {
		return admin.send(http.MethodPut, "/api/admin/security", api.SecurityUpdate{
			IpAllowlistEnabled: true, IpAllowlist: list,
		})
	}
	// A list without the person asking is refused, as it would lock them out.
	resp, body := update("10.0.0.0/8")
	expect(t, resp, body, http.StatusBadRequest)
	if !strings.Contains(string(body), "lock you out") {
		t.Fatalf("%s", body)
	}
	resp, body = update("127.0.0.1", "not an address")
	expect(t, resp, body, http.StatusBadRequest)

	resp, body = update("127.0.0.1")
	expect(t, resp, body, http.StatusOK)
	resp, body = admin.get("/api/timeline/buckets")
	expect(t, resp, body, http.StatusOK)

	stranger := s.client()
	headers := map[string]string{"X-Real-IP": "203.0.113.9"}
	resp, body = stranger.do(http.MethodGet, "/api/auth/status", headers, nil)
	expect(t, resp, body, http.StatusForbidden)
	resp, body = stranger.do(http.MethodGet, "/", headers, nil)
	expect(t, resp, body, http.StatusForbidden)
	// The container's own health check keeps working.
	resp, body = stranger.do(http.MethodGet, "/api/health", headers, nil)
	if resp.StatusCode == http.StatusForbidden {
		t.Fatalf("%s", body)
	}
	if got := s.count(t, "SELECT count(*) FROM security_events WHERE kind='ip_blocked' AND ip='203.0.113.9'"); got != 1 {
		t.Fatalf("blocked events: %d, a scan must not fill the log", got)
	}

	if err := ResetSecurity(context.Background(), db.New(s.pool)); err != nil {
		t.Fatal(err)
	}
}

func TestANewDeviceWaitsForApproval(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	s.user(admin, "person@example.com")
	login := func(device string) (*http.Response, []byte) {
		headers := map[string]string{"Content-Type": "application/json", deviceHeader: device}
		return s.client().do(http.MethodPost, "/api/auth/login", headers,
			strings.NewReader(`{"email":"person@example.com","password":"`+testPassword+`"}`))
	}
	resp, body := admin.send(http.MethodPut, "/api/admin/security", api.SecurityUpdate{
		DeviceApprovalEnabled: true, IpAllowlist: []string{},
	})
	expect(t, resp, body, http.StatusOK)
	settings := decode[api.SecuritySettings](t, body)
	own := false
	for _, device := range settings.Devices {
		own = own || (device.Email == "admin@example.com" && device.Approved)
	}
	if !own {
		t.Fatalf("the admin's own device must stay approved: %+v", settings.Devices)
	}

	resp, body = login("phone-1")
	expect(t, resp, body, http.StatusForbidden)
	// A wrong password says nothing about the device.
	resp, body = s.client().do(http.MethodPost, "/api/auth/login",
		map[string]string{"Content-Type": "application/json", deviceHeader: "phone-2"},
		strings.NewReader(`{"email":"person@example.com","password":"wrong-password-here"}`))
	expect(t, resp, body, http.StatusUnauthorized)

	resp, body = admin.get("/api/admin/security")
	expect(t, resp, body, http.StatusOK)
	waiting := []string{}
	for _, device := range decode[api.SecuritySettings](t, body).Devices {
		if device.Email == "person@example.com" && !device.Approved {
			waiting = append(waiting, device.Id.String())
		}
	}
	if len(waiting) == 0 {
		t.Fatalf("the waiting device is not listed: %s", body)
	}
	for _, id := range waiting {
		resp, body = admin.post("/api/admin/security/devices/"+id+"/approve", map[string]any{})
		expect(t, resp, body, http.StatusNoContent)
	}
	resp, body = login("phone-1")
	expect(t, resp, body, http.StatusOK)

	for _, id := range waiting {
		resp, body = admin.send(http.MethodDelete, "/api/admin/security/devices/"+id, nil)
		expect(t, resp, body, http.StatusNoContent)
	}
	resp, body = login("phone-1")
	expect(t, resp, body, http.StatusForbidden)

	resp, body = admin.get("/api/admin/security/events")
	expect(t, resp, body, http.StatusOK)
	kinds := string(body)
	for _, kind := range []string{"device_blocked", "login_failed", "login_ok"} {
		if !strings.Contains(kinds, kind) {
			t.Errorf("%s was not recorded: %s", kind, kinds)
		}
	}
	if strings.Contains(kinds, testPassword) || strings.Contains(kinds, "wrong-password-here") {
		t.Fatal("a password reached the log")
	}
}
