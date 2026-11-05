package app

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/auth"
	"github.com/mediarr-app/mediarr/server/internal/mail"
)

const (
	stateEmail        = "email_settings"
	passwordResetLife = time.Hour
	backgroundMail    = time.Minute
)

type emailSettings struct {
	Enabled   bool   `json:"enabled"`
	Host      string `json:"host"`
	Port      int    `json:"port"`
	Username  string `json:"username"`
	Password  string `json:"password"`
	From      string `json:"from"`
	Security  string `json:"security"`
	PublicURL string `json:"publicUrl"`
}

func (e *emailSettings) transport() *mail.Settings {
	return &mail.Settings{
		Host: e.Host, Port: e.Port, Username: e.Username, Password: e.Password, From: e.From, Security: e.Security,
	}
}

func (s *apiServer) loadEmail(ctx context.Context) (emailSettings, error) {
	out := emailSettings{Port: 587, Security: mail.SecurityStartTLS}
	raw, err := s.state(ctx, stateEmail)
	if err != nil || raw == "" {
		return out, err
	}
	if err := json.Unmarshal([]byte(raw), &out); err != nil {
		return emailSettings{Port: 587, Security: mail.SecurityStartTLS}, nil //nolint:nilerr // Unreadable is unset.
	}
	return out, nil
}

func emailToAPI(e *emailSettings) api.EmailSettings {
	return api.EmailSettings{
		Enabled: e.Enabled, Host: e.Host, Port: e.Port, Username: e.Username, From: e.From,
		Security: api.EmailSettingsSecurity(e.Security), PublicUrl: e.PublicURL, HasPassword: e.Password != "",
	}
}

func (s *apiServer) GetEmailSettings(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	settings, err := s.loadEmail(r.Context())
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, emailToAPI(&settings))
}

func (s *apiServer) SetEmailSettings(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	var body api.EmailSettingsUpdate
	if !readJSON(w, r, &body) {
		return
	}
	ctx := r.Context()
	current, err := s.loadEmail(ctx)
	if err != nil {
		internalError(w, r, err)
		return
	}
	next := emailSettings{
		Enabled: body.Enabled, Host: strings.TrimSpace(body.Host), Port: body.Port,
		Username: strings.TrimSpace(body.Username), Password: current.Password, From: strings.TrimSpace(body.From),
		Security:  string(body.Security),
		PublicURL: strings.TrimRight(strings.TrimSpace(body.PublicUrl), "/"),
	}
	if body.Password != nil {
		next.Password = *body.Password
	}
	if next.PublicURL != "" {
		parsed, err := url.Parse(next.PublicURL)
		if err != nil || parsed.Host == "" || (parsed.Scheme != "http" && parsed.Scheme != "https") {
			writeError(w, http.StatusBadRequest, "the address of this server must start with http:// or https://")
			return
		}
	}
	if next.Enabled && (next.Host == "" || next.From == "" || next.Port < 1 || next.Port > 65535) {
		writeError(w, http.StatusBadRequest, "enter the mail server, its port and the sender's address")
		return
	}
	if strings.ContainsAny(next.From, "\r\n") {
		writeError(w, http.StatusBadRequest, "the sender's address is not valid")
		return
	}
	data, err := json.Marshal(next) //nolint:gosec // Kept in the database like the other secrets, and never sent back.
	if err != nil {
		internalError(w, r, err)
		return
	}
	if err := s.queries.SetState(ctx, db.SetStateParams{Key: stateEmail, Value: string(data)}); err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, emailToAPI(&next))
}

func (s *apiServer) SendTestEmail(w http.ResponseWriter, r *http.Request) {
	user := requireAdmin(w, r)
	if user == nil {
		return
	}
	ctx := r.Context()
	settings, err := s.loadEmail(ctx)
	if err != nil {
		internalError(w, r, err)
		return
	}
	if !settings.Enabled {
		writeError(w, http.StatusConflict, "turn email on and save it first")
		return
	}
	if err := mail.Send(ctx, settings.transport(), user.Email, "Mediarr test message", "Email from your Mediarr server works."); err != nil {
		slog.Warn("a test email failed", "error", err)
		writeError(w, http.StatusBadGateway, "the mail server refused it: "+err.Error())
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// sendLater does not keep a request waiting, and does not show from how long it takes whether an
// address has an account.
func (s *apiServer) sendLater(to, subject, body string) {
	go func() {
		ctx, cancel := context.WithTimeout(context.Background(), backgroundMail)
		defer cancel()
		settings, err := s.loadEmail(ctx)
		if err != nil || !settings.Enabled {
			return
		}
		if err := mail.Send(ctx, settings.transport(), to, subject, body); err != nil {
			slog.Warn("an email was not sent", "error", err)
		}
	}()
}

// ForgotPassword always answers the same, so it does not tell who has an account. The link needs the
// address the administrator gave: one built from this request could be pointed anywhere by an attacker.
func (s *apiServer) ForgotPassword(w http.ResponseWriter, r *http.Request) {
	var body api.PasswordForgot
	if !readJSON(w, r, &body) {
		return
	}
	email, err := auth.NormalizeEmail(body.Email)
	ip := hostOnly(clientIP(r))
	if err != nil || !s.resetLimiter.Allowed(ip) || !s.resetLimiter.Allowed(email) {
		w.WriteHeader(http.StatusNoContent)
		return
	}
	s.resetLimiter.Fail(ip)
	s.resetLimiter.Fail(email)
	ctx := r.Context()
	settings, err := s.loadEmail(ctx)
	if err != nil {
		internalError(w, r, err)
		return
	}
	user, err := s.queries.GetUserByEmail(ctx, email)
	if settings.Enabled && settings.PublicURL != "" && err == nil {
		token, hash, tokenErr := auth.NewToken()
		if tokenErr != nil {
			internalError(w, r, tokenErr)
			return
		}
		if err := s.queries.CreatePasswordReset(ctx, db.CreatePasswordResetParams{
			TokenHash: hash, UserID: user.ID, ExpiresAt: pgtype.Timestamptz{Time: time.Now().Add(passwordResetLife), Valid: true},
		}); err != nil {
			internalError(w, r, err)
			return
		}
		link := settings.PublicURL + "/login/reset?token=" + url.QueryEscape(token)
		s.sendLater(user.Email, "Set a new Mediarr password",
			"Someone asked to set a new password for this account.\n\n"+link+
				"\n\nThe link works once, for one hour. If this was not you, you can ignore this message.")
		s.recordSecurity(r, eventPasswordReset, email, "asked for a link")
	}
	w.WriteHeader(http.StatusNoContent)
}

// ResetPassword ends every session and key, as on a change of password, and leaves two-factor sign-in on.
func (s *apiServer) ResetPassword(w http.ResponseWriter, r *http.Request) {
	var body api.PasswordReset
	if !readJSON(w, r, &body) {
		return
	}
	if err := auth.ValidatePassword(body.NewPassword); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	hash, err := auth.HashPassword(body.NewPassword)
	if err != nil {
		internalError(w, r, err)
		return
	}
	ctx := r.Context()
	expired := false
	err = pgx.BeginFunc(ctx, s.Pool, func(tx pgx.Tx) error {
		q := s.queries.WithTx(tx)
		userID, err := q.TakePasswordReset(ctx, auth.HashToken(body.Token))
		if db.IsNotFound(err) {
			expired = true
			return nil
		}
		if err != nil {
			return err
		}
		if err := q.SetPassword(ctx, db.SetPasswordParams{ID: userID, PasswordHash: hash}); err != nil {
			return err
		}
		if err := q.DeleteUserAPIKeys(ctx, userID); err != nil {
			return err
		}
		if err := q.DeleteUserPasskeys(ctx, userID); err != nil {
			return err
		}
		if err := q.DeleteUserPasswordResets(ctx, userID); err != nil {
			return err
		}
		return q.DeleteUserSessions(ctx, userID)
	})
	if err != nil {
		internalError(w, r, err)
		return
	}
	if expired {
		writeError(w, http.StatusBadRequest, "this link has expired or was already used")
		return
	}
	s.recordSecurity(r, eventPasswordReset, "", "a new password was set")
	w.WriteHeader(http.StatusNoContent)
}
