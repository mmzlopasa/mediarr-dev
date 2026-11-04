package app

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"net/netip"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgtype"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/auth"
)

const (
	stateIPAllowlist     = "security_ip_allowlist"
	stateIPEnabled       = "security_ip_enabled"
	stateDeviceApproval  = "security_device_approval"
	securityRefresh      = 10 * time.Second
	deviceCookie         = "mediarr_device"
	deviceHeader         = "X-Device-Id"
	deviceCookieLifetime = 5 * 365 * 24 * time.Hour
	maxDeviceID          = 128
	maxUserAgent         = 300
	securityPage         = 200
	deviceNotApproved    = "this device has to be approved by an administrator first"

	eventLoginOK      = "login_ok"
	eventLoginFailed  = "login_failed"
	eventLoginLocked  = "login_locked"
	eventIPBlocked    = "ip_blocked"
	eventDeviceDenied = "device_blocked"
)

type securityRules struct {
	loaded         time.Time
	ipEnabled      bool
	allowed        []netip.Prefix
	deviceApproval bool
}

// parseAllowlist reads addresses and networks, such as 192.168.1.20 or 192.168.1.0/24.
func parseAllowlist(lines []string) ([]netip.Prefix, error) {
	out := []netip.Prefix{}
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}
		if prefix, err := netip.ParsePrefix(line); err == nil {
			out = append(out, prefix.Masked())
			continue
		}
		address, err := netip.ParseAddr(line)
		if err != nil {
			return nil, errors.New("not an address or a network: " + line)
		}
		address = address.Unmap()
		out = append(out, netip.PrefixFrom(address, address.BitLen()))
	}
	return out, nil
}

func addressAllowed(address string, allowed []netip.Prefix) bool {
	parsed, err := netip.ParseAddr(hostOnly(address))
	if err != nil {
		return false
	}
	parsed = parsed.Unmap()
	for _, prefix := range allowed {
		if prefix.Contains(parsed) {
			return true
		}
	}
	return false
}

func (s *apiServer) loadSecurity(ctx context.Context) (*securityRules, error) {
	enabled, err := s.state(ctx, stateIPEnabled)
	if err != nil {
		return nil, err
	}
	list, err := s.state(ctx, stateIPAllowlist)
	if err != nil {
		return nil, err
	}
	device, err := s.state(ctx, stateDeviceApproval)
	if err != nil {
		return nil, err
	}
	allowed, err := parseAllowlist(strings.Split(list, "\n"))
	if err != nil {
		return nil, err
	}
	rules := &securityRules{
		loaded: time.Now(), ipEnabled: enabled == "1", allowed: allowed, deviceApproval: device == "1",
	}
	s.security.Store(rules)
	return rules, nil
}

func (s *apiServer) securityRules(ctx context.Context) (*securityRules, error) {
	if rules := s.security.Load(); rules != nil && time.Since(rules.loaded) < securityRefresh {
		return rules, nil
	}
	return s.loadSecurity(ctx)
}

// enforceIPAllowlist comes first, so that nothing at all is answered to an address not on the list.
// If the rules cannot be read it refuses too, because this is what keeps strangers out.
func (s *apiServer) enforceIPAllowlist(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/api/health" {
			next.ServeHTTP(w, r)
			return
		}
		rules, err := s.securityRules(r.Context())
		if err != nil {
			internalError(w, r, err)
			return
		}
		ip := hostOnly(clientIP(r))
		if rules.ipEnabled && !addressAllowed(ip, rules.allowed) {
			// One line a minute for each address, as a scan could otherwise fill the log.
			if s.blockedLogged.Allowed(ip) {
				s.blockedLogged.Fail(ip)
				s.recordSecurity(r, eventIPBlocked, "", r.URL.Path)
			}
			writeError(w, http.StatusForbidden, "this address may not use this server")
			return
		}
		next.ServeHTTP(w, r)
	})
}

func (s *apiServer) recordSecurity(r *http.Request, kind, email, detail string) {
	agent := r.UserAgent()
	if len(agent) > maxUserAgent {
		agent = agent[:maxUserAgent]
	}
	if err := s.queries.InsertSecurityEvent(r.Context(), db.InsertSecurityEventParams{
		Kind: kind, Email: email, Ip: hostOnly(clientIP(r)), UserAgent: agent, Detail: detail,
	}); err != nil {
		slog.Warn("a security event was not recorded", "error", err)
	}
}

// deviceToken names this browser or phone. The app sends its own, and a browser gets a cookie.
func deviceToken(w http.ResponseWriter, r *http.Request) string {
	if token := r.Header.Get(deviceHeader); token != "" && len(token) <= maxDeviceID {
		return token
	}
	if cookie, err := r.Cookie(deviceCookie); err == nil && cookie.Value != "" && len(cookie.Value) <= maxDeviceID {
		return cookie.Value
	}
	token, _, err := auth.NewToken()
	if err != nil {
		return ""
	}
	http.SetCookie(w, &http.Cookie{
		Name: deviceCookie, Value: token, Path: "/", Expires: time.Now().Add(deviceCookieLifetime),
		HttpOnly: true, SameSite: http.SameSiteLaxMode, Secure: isHTTPS(r),
	})
	return token
}

// deviceMaySignIn remembers every device that got the password right, for the administrator to see.
func (s *apiServer) deviceMaySignIn(w http.ResponseWriter, r *http.Request, email string) bool {
	ctx := r.Context()
	rules, err := s.securityRules(ctx)
	if err != nil {
		slog.Error("the security rules could not be read", "error", err)
		return false
	}
	token := deviceToken(w, r)
	agent := r.UserAgent()
	if len(agent) > maxUserAgent {
		agent = agent[:maxUserAgent]
	}
	device, err := s.queries.SeeDevice(ctx, db.SeeDeviceParams{
		TokenHash: auth.HashToken(token), Email: email, Ip: hostOnly(clientIP(r)), UserAgent: agent,
	})
	if err != nil {
		slog.Error("a device could not be recorded", "error", err)
		return !rules.deviceApproval
	}
	if rules.deviceApproval && !device.ApprovedAt.Valid {
		s.recordSecurity(r, eventDeviceDenied, email, "")
		return false
	}
	return true
}

func (s *apiServer) securitySettings(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	rules, err := s.loadSecurity(ctx)
	if err != nil {
		internalError(w, r, err)
		return
	}
	rows, err := s.queries.ListDevices(ctx)
	if err != nil {
		internalError(w, r, err)
		return
	}
	list := make([]string, len(rules.allowed))
	for i, prefix := range rules.allowed {
		list[i] = prefix.String()
	}
	devices := make([]api.SecurityDevice, len(rows))
	for i := range rows {
		row := &rows[i]
		devices[i] = api.SecurityDevice{
			Id: openapi_types.UUID(row.ID.Bytes), Email: row.Email, Ip: row.Ip, UserAgent: row.UserAgent,
			FirstSeen: row.FirstSeen.Time, LastSeen: row.LastSeen.Time, Approved: row.ApprovedAt.Valid,
		}
	}
	writeJSON(w, http.StatusOK, api.SecuritySettings{
		IpAllowlistEnabled: rules.ipEnabled, IpAllowlist: list, DeviceApprovalEnabled: rules.deviceApproval,
		YourAddress: hostOnly(clientIP(r)), Devices: devices,
	})
}

func (s *apiServer) GetSecurity(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	s.securitySettings(w, r)
}

func (s *apiServer) SetSecurity(w http.ResponseWriter, r *http.Request) {
	user := requireAdmin(w, r)
	if user == nil {
		return
	}
	var body api.SecurityUpdate
	if !readJSON(w, r, &body) {
		return
	}
	allowed, err := parseAllowlist(body.IpAllowlist)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	if body.IpAllowlistEnabled && !addressAllowed(clientIP(r), allowed) {
		writeError(w, http.StatusBadRequest, "your own address, "+hostOnly(clientIP(r))+", is not on the list, so this would lock you out")
		return
	}
	ctx := r.Context()
	if body.DeviceApprovalEnabled {
		// The person turning this on must not lose this device.
		hash := auth.HashToken(deviceToken(w, r))
		if _, err := s.queries.SeeDevice(ctx, db.SeeDeviceParams{TokenHash: hash, Email: user.Email, Ip: hostOnly(clientIP(r)), UserAgent: r.UserAgent()}); err != nil {
			internalError(w, r, err)
			return
		}
		if err := s.queries.ApproveDeviceByToken(ctx, hash); err != nil {
			internalError(w, r, err)
			return
		}
	}
	lines := make([]string, len(allowed))
	for i, prefix := range allowed {
		lines[i] = prefix.String()
	}
	flag := func(on bool) string {
		if on {
			return "1"
		}
		return "0"
	}
	for key, value := range map[string]string{
		stateIPAllowlist: strings.Join(lines, "\n"), stateIPEnabled: flag(body.IpAllowlistEnabled),
		stateDeviceApproval: flag(body.DeviceApprovalEnabled),
	} {
		if err := s.queries.SetState(ctx, db.SetStateParams{Key: key, Value: value}); err != nil {
			internalError(w, r, err)
			return
		}
	}
	s.securitySettings(w, r)
}

func (s *apiServer) ListSecurityEvents(w http.ResponseWriter, r *http.Request, params api.ListSecurityEventsParams) {
	if requireAdmin(w, r) == nil {
		return
	}
	before := pgtype.Int8{}
	if params.Before != nil {
		before = pgtype.Int8{Int64: *params.Before, Valid: true}
	}
	rows, err := s.queries.ListSecurityEvents(r.Context(), db.ListSecurityEventsParams{Before: before, RowLimit: securityPage})
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := make([]api.SecurityEvent, len(rows))
	for i := range rows {
		row := &rows[i]
		out[i] = api.SecurityEvent{
			Id: row.ID, At: row.At.Time, Kind: api.SecurityEventKind(row.Kind), Email: row.Email,
			Ip: row.Ip, UserAgent: row.UserAgent, Detail: row.Detail,
		}
	}
	writeJSON(w, http.StatusOK, out)
}

func (s *apiServer) ApproveDevice(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	if requireAdmin(w, r) == nil {
		return
	}
	changed, err := s.queries.ApproveDevice(r.Context(), pgUUID(id))
	if err != nil {
		internalError(w, r, err)
		return
	}
	if changed == 0 {
		writeError(w, http.StatusNotFound, "not found")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) DeleteDevice(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	if requireAdmin(w, r) == nil {
		return
	}
	changed, err := s.queries.DeleteDevice(r.Context(), pgUUID(id))
	if err != nil {
		internalError(w, r, err)
		return
	}
	if changed == 0 {
		writeError(w, http.StatusNotFound, "not found")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ResetSecurity turns off both rules. It runs on the server itself, for someone locked out.
func ResetSecurity(ctx context.Context, q *db.Queries) error {
	for _, key := range []string{stateIPEnabled, stateDeviceApproval} {
		if err := q.SetState(ctx, db.SetStateParams{Key: key, Value: "0"}); err != nil {
			return err
		}
	}
	return nil
}
