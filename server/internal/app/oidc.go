package app

import (
	"context"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/base64"
	"errors"
	"log/slog"
	"net/http"
	"net/url"
	"strings"
	"sync"
	"time"
	"unicode"

	"github.com/coreos/go-oidc/v3/oidc"
	"github.com/jackc/pgx/v5/pgtype"
	"golang.org/x/oauth2"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/auth"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

const (
	stateOIDCIssuer     = "oidc_issuer"
	stateOIDCClientID   = "oidc_client_id"
	stateOIDCSecret     = "oidc_client_secret" //nolint:gosec // The name of a setting, not its value.
	stateOIDCLabel      = "oidc_label"
	stateOIDCAutoCreate = "oidc_auto_create"
	stateOIDCLinkAdmins = "oidc_link_admins"

	oidcCookie       = "mediarr_oidc"
	oidcCookieAge    = 10 * time.Minute
	oidcAppCodeAge   = time.Minute
	oidcCallbackPath = "/api/auth/oidc/callback"
	oidcAppScheme    = "mediarr://oidc"
	maxShortLived    = 10000
)

// shortLived holds what a sign-in needs between two of its steps, and only for a moment.
type shortLived[T any] struct {
	mu    sync.Mutex
	items map[string]shortLivedItem[T]
}

type shortLivedItem[T any] struct {
	value   T
	expires time.Time
}

func newShortLived[T any]() *shortLived[T] {
	return &shortLived[T]{items: map[string]shortLivedItem[T]{}}
}

func (s *shortLived[T]) put(key string, value T, age time.Duration) {
	s.mu.Lock()
	defer s.mu.Unlock()
	now := time.Now()
	for other, item := range s.items {
		if now.After(item.expires) {
			delete(s.items, other)
		}
	}
	// Anyone can start a sign-in, so this cannot grow without end.
	if len(s.items) >= maxShortLived {
		for other := range s.items {
			delete(s.items, other)
			break
		}
	}
	s.items[key] = shortLivedItem[T]{value, now.Add(age)}
}

// take works once, so that nothing can be replayed.
func (s *shortLived[T]) take(key string) (value T, ok bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	item, found := s.items[key]
	delete(s.items, key)
	if !found || time.Now().After(item.expires) {
		return value, false
	}
	return item.value, true
}

type oidcFlow struct {
	state, nonce, verifier string
	next                   string
	// appChallenge is set when the app started this. It proves later that the same app is asking.
	appChallenge string
}

type oidcAppCode struct {
	user      pgtype.UUID
	challenge string
}

type oidcSettings struct {
	issuer, clientID, secret, label string
	autoCreate, linkAdmins          bool
}

func (s *apiServer) state(ctx context.Context, key string) (string, error) {
	value, err := s.queries.GetState(ctx, key)
	if db.IsNotFound(err) {
		return "", nil
	}
	return value, err
}

func (s *apiServer) loadOIDC(ctx context.Context) (oidcSettings, error) {
	var out oidcSettings
	var auto string
	for key, target := range map[string]*string{
		stateOIDCIssuer: &out.issuer, stateOIDCClientID: &out.clientID, stateOIDCSecret: &out.secret,
		stateOIDCLabel: &out.label, stateOIDCAutoCreate: &auto,
	} {
		value, err := s.state(ctx, key)
		if err != nil {
			return out, err
		}
		*target = value
	}
	out.autoCreate = auto == "1"
	admins, err := s.state(ctx, stateOIDCLinkAdmins)
	if err != nil {
		return out, err
	}
	out.linkAdmins = admins == "1"
	return out, nil
}

func (o *oidcSettings) enabled() bool { return o.issuer != "" && o.clientID != "" }

// publicOrigin is what the visitor sees, so that nothing is tied to one domain or address.
func publicOrigin(r *http.Request) string {
	scheme := "http"
	if isHTTPS(r) {
		scheme = "https"
	}
	return scheme + "://" + r.Host
}

func (s *apiServer) oauthConfig(ctx context.Context, r *http.Request, settings *oidcSettings) (*oauth2.Config, *oidc.Provider, error) {
	provider, err := oidc.NewProvider(ctx, settings.issuer)
	if err != nil {
		return nil, nil, err
	}
	return &oauth2.Config{
		ClientID: settings.clientID, ClientSecret: settings.secret,
		Endpoint:    provider.Endpoint(),
		RedirectURL: publicOrigin(r) + oidcCallbackPath,
		Scopes:      []string{oidc.ScopeOpenID, "email", "profile"},
	}, provider, nil
}

func randomText() (string, error) {
	token, _, err := auth.NewToken()
	return token, err
}

func localPath(next string) string {
	// Browsers drop tabs and line breaks from addresses, so "/<tab>/evil" would become "//evil".
	if strings.ContainsFunc(next, unicode.IsControl) {
		return "/"
	}
	if strings.HasPrefix(next, "/") && !strings.HasPrefix(next, "//") && !strings.HasPrefix(next, "/\\") {
		return next
	}
	return "/"
}

func (s *apiServer) StartOIDC(w http.ResponseWriter, r *http.Request, params api.StartOIDCParams) {
	ctx := r.Context()
	settings, err := s.loadOIDC(ctx)
	if err != nil {
		internalError(w, r, err)
		return
	}
	if !settings.enabled() {
		writeError(w, http.StatusNotFound, "single sign-on is not turned on")
		return
	}
	config, _, err := s.oauthConfig(ctx, r, &settings)
	if err != nil {
		slog.Warn("the identity provider cannot be reached", "error", err)
		writeError(w, http.StatusBadGateway, "the identity provider cannot be reached")
		return
	}
	flow := oidcFlow{next: "/"}
	if params.Next != nil {
		flow.next = localPath(*params.Next)
	}
	if params.AppChallenge != nil {
		flow.appChallenge = *params.AppChallenge
	}
	for _, target := range []*string{&flow.state, &flow.nonce} {
		if *target, err = randomText(); err != nil {
			internalError(w, r, err)
			return
		}
	}
	flow.verifier = oauth2.GenerateVerifier()
	cookie, err := randomText()
	if err != nil {
		internalError(w, r, err)
		return
	}
	s.oidcFlows.put(cookie, flow, oidcCookieAge)
	// Lax, because the provider sends the browser back with a plain link.
	http.SetCookie(w, &http.Cookie{
		Name: oidcCookie, Value: cookie, Path: oidcCallbackPath, MaxAge: int(oidcCookieAge.Seconds()),
		HttpOnly: true, SameSite: http.SameSiteLaxMode, Secure: isHTTPS(r),
	})
	http.Redirect(w, r, config.AuthCodeURL(flow.state, oidc.Nonce(flow.nonce), oauth2.S256ChallengeOption(flow.verifier)), http.StatusFound) //nolint:gosec // To the provider the administrator set.
}

// oidcClaims are what the provider says about the person.
type oidcClaims struct {
	Email         string `json:"email"`
	EmailVerified *bool  `json:"email_verified"`
	Name          string `json:"name"`
}

func (s *apiServer) oidcUser(ctx context.Context, r *http.Request, flow *oidcFlow, code string, settings *oidcSettings) (*db.User, error) {
	config, provider, err := s.oauthConfig(ctx, r, settings)
	if err != nil {
		return nil, err
	}
	token, err := config.Exchange(ctx, code, oauth2.VerifierOption(flow.verifier))
	if err != nil {
		return nil, err
	}
	raw, ok := token.Extra("id_token").(string)
	if !ok {
		return nil, errors.New("the provider gave no ID token")
	}
	idToken, err := provider.Verifier(&oidc.Config{ClientID: settings.clientID}).Verify(ctx, raw)
	if err != nil {
		return nil, err
	}
	if subtle.ConstantTimeCompare([]byte(idToken.Nonce), []byte(flow.nonce)) != 1 {
		return nil, errors.New("the nonce does not match")
	}
	var claims oidcClaims
	if err := idToken.Claims(&claims); err != nil {
		return nil, err
	}
	// Someone who came this way before is known by who they are at the provider, not by an email.
	known, err := s.queries.GetOIDCIdentity(ctx, db.GetOIDCIdentityParams{Issuer: settings.issuer, Subject: idToken.Subject})
	if err == nil {
		return &known, nil
	}
	if !db.IsNotFound(err) {
		return nil, err
	}
	// Otherwise the email decides, so it must be one the provider has verified. A provider that does
	// not say, or lets people change it, could otherwise open someone else's account.
	if claims.EmailVerified == nil || !*claims.EmailVerified {
		return nil, errors.New("the provider has not verified this email address")
	}
	email, err := auth.NormalizeEmail(claims.Email)
	if err != nil {
		return nil, errors.New("the provider gave no usable email address")
	}
	user, err := s.queries.GetUserByEmail(ctx, email)
	switch {
	case err == nil:
		// An administrator's account is too much to hand over by email alone.
		if user.IsAdmin && !settings.linkAdmins {
			return nil, errors.New("an administrator's account is not linked by email")
		}
	case !db.IsNotFound(err):
		return nil, err
	case !settings.autoCreate:
		return nil, errors.New("this person has no account here")
	default:
		created, err := s.createOIDCUser(ctx, email, claims.Name)
		if err != nil {
			return nil, err
		}
		user = *created
	}
	if err := s.queries.AddOIDCIdentity(ctx, db.AddOIDCIdentityParams{Issuer: settings.issuer, Subject: idToken.Subject, UserID: user.ID}); err != nil {
		return nil, err
	}
	return &user, nil
}

func (s *apiServer) createOIDCUser(ctx context.Context, email, name string) (*db.User, error) {
	if name = strings.TrimSpace(name); name == "" {
		name = email
	}
	// Nobody knows this password: the person signs in through the provider.
	password, err := randomText()
	if err != nil {
		return nil, err
	}
	hash, err := auth.HashPassword(password)
	if err != nil {
		return nil, err
	}
	created, err := s.queries.CreateUser(ctx, db.CreateUserParams{Email: email, Name: name, PasswordHash: hash})
	if err != nil {
		return nil, err
	}
	if err := s.queries.CreateUploadLibrary(ctx, created.ID); err != nil {
		return nil, err
	}
	return &created, nil
}

func oidcFailureURL(flow *oidcFlow) string {
	if flow != nil && flow.appChallenge != "" {
		return oidcAppScheme + "?error=failed"
	}
	return "/login?sso=failed"
}

func (s *apiServer) FinishOIDC(w http.ResponseWriter, r *http.Request, params api.FinishOIDCParams) {
	ctx := r.Context()
	cookie, err := r.Cookie(oidcCookie)
	if err != nil {
		http.Redirect(w, r, oidcFailureURL(nil), http.StatusFound)
		return
	}
	flow, ok := s.oidcFlows.take(cookie.Value)
	http.SetCookie(w, &http.Cookie{Name: oidcCookie, Path: oidcCallbackPath, MaxAge: -1})
	if !ok || params.State == nil || subtle.ConstantTimeCompare([]byte(*params.State), []byte(flow.state)) != 1 || params.Code == nil {
		slog.Warn("a single sign-on came back without what was sent")
		http.Redirect(w, r, oidcFailureURL(&flow), http.StatusFound)
		return
	}
	settings, err := s.loadOIDC(ctx)
	if err != nil {
		internalError(w, r, err)
		return
	}
	user, err := s.oidcUser(ctx, r, &flow, *params.Code, &settings)
	if err != nil {
		slog.Warn("a single sign-on was refused", "error", err)
		s.recordAudit(r, nil, &auditNote{}, http.StatusUnauthorized)
		http.Redirect(w, r, oidcFailureURL(&flow), http.StatusFound)
		return
	}
	s.recordAudit(r, user, &auditNote{}, http.StatusOK)
	if flow.appChallenge != "" {
		code, err := randomText()
		if err != nil {
			internalError(w, r, err)
			return
		}
		s.oidcCodes.put(code, oidcAppCode{user.ID, flow.appChallenge}, oidcAppCodeAge)
		http.Redirect(w, r, oidcAppScheme+"?code="+url.QueryEscape(code), http.StatusFound)
		return
	}
	if !s.deviceMaySignIn(w, r, user.Email) {
		http.Redirect(w, r, "/login?sso=failed", http.StatusFound)
		return
	}
	if err := s.startSession(ctx, w, r, user.ID); err != nil {
		internalError(w, r, err)
		return
	}
	s.recordSecurity(r, eventLoginOK, user.Email, "single sign-on")
	http.Redirect(w, r, flow.next, http.StatusFound)
}

// ExchangeOIDC gives the app its session. Another app that caught the redirect has only the code,
// not the secret whose hash this app sent at the start.
func (s *apiServer) ExchangeOIDC(w http.ResponseWriter, r *http.Request) {
	var body api.OIDCExchange
	if !readJSON(w, r, &body) {
		return
	}
	code, ok := s.oidcCodes.take(body.Code)
	sum := sha256.Sum256([]byte(body.Verifier))
	challenge := base64.RawURLEncoding.EncodeToString(sum[:])
	if !ok || subtle.ConstantTimeCompare([]byte(challenge), []byte(code.challenge)) != 1 {
		writeError(w, http.StatusUnauthorized, "this sign-in has expired")
		return
	}
	ctx := r.Context()
	user, err := s.queries.GetUserByID(ctx, code.user)
	if err != nil {
		internalError(w, r, err)
		return
	}
	if !s.deviceMaySignIn(w, r, user.Email) {
		writeError(w, http.StatusForbidden, deviceNotApproved)
		return
	}
	if err := s.startSession(ctx, w, r, user.ID); err != nil {
		internalError(w, r, err)
		return
	}
	s.recordSecurity(r, eventLoginOK, user.Email, "single sign-on")
	writeJSON(w, http.StatusOK, toAPIUser(&user))
}

func (s *apiServer) GetAuthMethods(w http.ResponseWriter, r *http.Request) {
	settings, err := s.loadOIDC(r.Context())
	if err != nil {
		internalError(w, r, err)
		return
	}
	server, err := jobs.LoadServerSettings(r.Context(), s.queries)
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := api.AuthMethods{
		Passkeys: passkeysAvailable(r), PasswordLogin: server.PasswordLogin, LoginMessage: server.LoginMessage,
	}
	if settings.enabled() {
		label := settings.label
		if label == "" {
			label = "Single sign-on"
		}
		out.SsoLabel = &label
	}
	writeJSON(w, http.StatusOK, out)
}

func oidcToAPI(settings *oidcSettings) api.OIDCSettings {
	return api.OIDCSettings{
		Issuer: settings.issuer, ClientId: settings.clientID, Label: settings.label,
		AutoCreate: settings.autoCreate, HasSecret: settings.secret != "", LinkAdmins: settings.linkAdmins,
	}
}

func (s *apiServer) GetOIDCSettings(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	settings, err := s.loadOIDC(r.Context())
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, oidcToAPI(&settings))
}

func (s *apiServer) SetOIDCSettings(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	var body api.OIDCSettingsUpdate
	if !readJSON(w, r, &body) {
		return
	}
	issuer := strings.TrimRight(strings.TrimSpace(body.Issuer), "/")
	if issuer != "" {
		parsed, err := url.Parse(issuer)
		if err != nil || parsed.Host == "" || (parsed.Scheme != "http" && parsed.Scheme != "https") {
			writeError(w, http.StatusBadRequest, "the issuer must be an http or https address")
			return
		}
	}
	auto := "0"
	if body.AutoCreate {
		auto = "1"
	}
	linkAdmins := "0"
	if body.LinkAdmins != nil && *body.LinkAdmins {
		linkAdmins = "1"
	}
	values := map[string]string{
		stateOIDCLinkAdmins: linkAdmins,
		stateOIDCIssuer:     issuer, stateOIDCClientID: strings.TrimSpace(body.ClientId),
		stateOIDCLabel: strings.TrimSpace(body.Label), stateOIDCAutoCreate: auto,
	}
	// Left out means keep it: the secret is never sent back to fill the form.
	if body.Secret != nil {
		values[stateOIDCSecret] = *body.Secret
	}
	ctx := r.Context()
	for key, value := range values {
		if err := s.queries.SetState(ctx, db.SetStateParams{Key: key, Value: value}); err != nil {
			internalError(w, r, err)
			return
		}
	}
	settings, err := s.loadOIDC(ctx)
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, oidcToAPI(&settings))
}
