package app

import (
	"context"
	"errors"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgtype"
	openapi_types "github.com/oapi-codegen/runtime/types"
	"github.com/pquerna/otp"
	"github.com/pquerna/otp/totp"

	"github.com/mmzlopasa/mediarr-app/server/db"
	"github.com/mmzlopasa/mediarr-app/server/internal/api"
	"github.com/mmzlopasa/mediarr-app/server/internal/auth"
)

const (
	totpPeriod     = 30
	totpSkew       = 1
	uniqueViolated = "23505"
)

type userKey struct{}

// loadUser attaches the signed-in user, if any, from a session cookie or an API key.
func (s *apiServer) loadUser(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !strings.HasPrefix(r.URL.Path, "/api/") {
			next.ServeHTTP(w, r)
			return
		}
		ctx := r.Context()
		user, err := s.authenticate(r, &ctx)
		if err != nil {
			if !db.IsNotFound(err) {
				internalError(w, r, err)
				return
			}
			next.ServeHTTP(w, r)
			return
		}
		r = r.WithContext(context.WithValue(ctx, userKey{}, &user))
		if scopes, ok := ctx.Value(scopesKey{}).([]string); ok && !keyMayDo(scopes, r.Method, r.URL.Path) {
			writeError(w, http.StatusForbidden, "this key does not have the right to do that")
			return
		}
		next.ServeHTTP(w, r)
	})
}

func (s *apiServer) authenticate(r *http.Request, ctx *context.Context) (db.User, error) {
	if key := r.Header.Get(apiKeyHeader); key != "" {
		row, err := s.queries.GetUserByAPIKey(r.Context(), auth.HashToken(key))
		if err != nil {
			return db.User{}, err
		}
		*ctx = context.WithValue(*ctx, scopesKey{}, row.Scopes)
		return row.User, nil
	}
	cookie, err := r.Cookie(sessionCookie)
	if err != nil {
		return db.User{}, pgx.ErrNoRows
	}
	return s.queries.GetUserBySessionToken(r.Context(), auth.HashToken(cookie.Value))
}

func currentUser(r *http.Request) *db.User {
	user, _ := r.Context().Value(userKey{}).(*db.User)
	return user
}

func requireUser(w http.ResponseWriter, r *http.Request) *db.User {
	user := currentUser(r)
	if user == nil {
		writeError(w, http.StatusUnauthorized, "sign in first")
	}
	return user
}

func requireAdmin(w http.ResponseWriter, r *http.Request) *db.User {
	user := requireUser(w, r)
	if user == nil {
		return nil
	}
	if !user.IsAdmin {
		writeError(w, http.StatusForbidden, "administrators only")
		return nil
	}
	return user
}

func toAPIUser(user *db.User) api.User {
	return api.User{
		Id:          uuid.UUID(user.ID.Bytes),
		Email:       user.Email,
		Name:        user.Name,
		IsAdmin:     user.IsAdmin,
		TotpEnabled: user.TotpEnabled,
	}
}

// isHTTPS decides the cookie's Secure flag. Mediarr must also work over plain HTTP on an IP address.
func isHTTPS(r *http.Request) bool {
	return r.TLS != nil || r.Header.Get("X-Forwarded-Proto") == "https"
}

const maxEmailLength = 320

func clientIP(r *http.Request) string {
	if ip := r.Header.Get("X-Real-IP"); ip != "" {
		return ip
	}
	return r.RemoteAddr
}

func (s *apiServer) startSession(ctx context.Context, w http.ResponseWriter, r *http.Request, userID pgtype.UUID) error {
	token, hash, err := auth.NewToken()
	if err != nil {
		return err
	}
	expires := time.Now().Add(sessionLifetime)
	if err := s.queries.CreateSession(ctx, db.CreateSessionParams{
		UserID:    userID,
		TokenHash: hash,
		ExpiresAt: pgtype.Timestamptz{Time: expires, Valid: true},
	}); err != nil {
		return err
	}
	http.SetCookie(w, &http.Cookie{
		Name:     sessionCookie,
		Value:    token,
		Path:     "/",
		Expires:  expires,
		HttpOnly: true,
		SameSite: http.SameSiteLaxMode,
		Secure:   isHTTPS(r),
	})
	return nil
}

func clearSessionCookie(w http.ResponseWriter, r *http.Request) {
	http.SetCookie(w, &http.Cookie{
		Name:     sessionCookie,
		Path:     "/",
		MaxAge:   -1,
		HttpOnly: true,
		SameSite: http.SameSiteLaxMode,
		Secure:   isHTTPS(r),
	})
}

func (s *apiServer) GetAuthStatus(w http.ResponseWriter, r *http.Request) {
	count, err := s.queries.CountUsers(r.Context())
	if err != nil {
		internalError(w, r, err)
		return
	}
	status := api.AuthStatus{SetupRequired: count == 0}
	if user := currentUser(r); user != nil {
		apiUser := toAPIUser(user)
		status.User = &apiUser
	}
	writeJSON(w, http.StatusOK, status)
}

func validateNewUser(email, name, password string) (string, string, string) {
	normalized, err := auth.NormalizeEmail(email)
	if err != nil {
		return "", "", err.Error()
	}
	name = strings.TrimSpace(name)
	if name == "" || len(name) > 200 {
		return "", "", "enter a name"
	}
	if err := auth.ValidatePassword(password); err != nil {
		return "", "", err.Error()
	}
	return normalized, name, ""
}

// Setup creates the first administrator. The lock makes two simultaneous requests safe.
func (s *apiServer) Setup(w http.ResponseWriter, r *http.Request) {
	var body api.SetupRequest
	if !readJSON(w, r, &body) {
		return
	}
	email, name, problem := validateNewUser(body.Email, body.Name, body.Password)
	if problem != "" {
		writeError(w, http.StatusBadRequest, problem)
		return
	}
	hash, err := auth.HashPassword(body.Password)
	if err != nil {
		internalError(w, r, err)
		return
	}

	var user db.User
	closed := false
	err = pgx.BeginFunc(r.Context(), s.Pool, func(tx pgx.Tx) error {
		q := s.queries.WithTx(tx)
		if err := q.LockSetup(r.Context()); err != nil {
			return err
		}
		count, err := q.CountUsers(r.Context())
		if err != nil {
			return err
		}
		if count > 0 {
			closed = true
			return nil
		}
		user, err = q.CreateUser(r.Context(), db.CreateUserParams{Email: email, Name: name, PasswordHash: hash, IsAdmin: true})
		return err
	})
	if err != nil {
		internalError(w, r, err)
		return
	}
	if closed {
		writeError(w, http.StatusConflict, "setup is already complete")
		return
	}
	if err := s.startSession(r.Context(), w, r, user.ID); err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusCreated, toAPIUser(&user))
}

func (s *apiServer) Login(w http.ResponseWriter, r *http.Request) {
	var body api.LoginRequest
	if !readJSON(w, r, &body) {
		return
	}
	if len(body.Email) > maxEmailLength {
		writeError(w, http.StatusBadRequest, "that email address is too long")
		return
	}
	email := strings.ToLower(strings.TrimSpace(body.Email))
	noteAuditEmail(r, email)
	ip := clientIP(r)
	userKey := email + "|" + ip
	if !s.userLimiter.Allowed(userKey) || !s.ipLimiter.Allowed(ip) {
		writeError(w, http.StatusTooManyRequests, "too many attempts; try again later")
		return
	}

	failed := func(totpRequired bool) {
		s.userLimiter.Fail(userKey)
		s.ipLimiter.Fail(ip)
		writeJSON(w, http.StatusUnauthorized, api.LoginError{Message: "wrong email, password or code", TotpRequired: totpRequired})
	}

	user, err := s.queries.GetUserByEmail(r.Context(), email)
	if err != nil {
		if !db.IsNotFound(err) {
			internalError(w, r, err)
			return
		}
		auth.BurnPasswordTime(body.Password)
		failed(false)
		return
	}
	if !auth.VerifyPassword(user.PasswordHash, body.Password) {
		failed(false)
		return
	}
	if user.TotpEnabled {
		code := ""
		if body.TotpCode != nil {
			code = *body.TotpCode
		}
		if code == "" {
			// The password was right, but the first step of two is not a failed attempt.
			writeJSON(w, http.StatusUnauthorized, api.LoginError{Message: "enter your code", TotpRequired: true})
			return
		}
		ok, err := s.claimTotp(r.Context(), &user, code)
		if err != nil {
			internalError(w, r, err)
			return
		}
		if !ok {
			failed(true)
			return
		}
	}

	s.userLimiter.Reset(userKey)
	if err := s.startSession(r.Context(), w, r, user.ID); err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, toAPIUser(&user))
}

// totpStep finds which time step a code belongs to, within the allowed clock skew.
func totpStep(secret, code string, now time.Time) (int64, bool) {
	code = strings.ReplaceAll(code, " ", "")
	for offset := -totpSkew; offset <= totpSkew; offset++ {
		at := now.Add(time.Duration(offset*totpPeriod) * time.Second)
		ok, err := totp.ValidateCustom(code, secret, at, totp.ValidateOpts{Period: totpPeriod, Skew: 0, Digits: otp.DigitsSix, Algorithm: otp.AlgorithmSHA1})
		if err == nil && ok {
			return at.Unix() / totpPeriod, true
		}
	}
	return 0, false
}

// claimTotp accepts a code once, so an observed code cannot be replayed.
func (s *apiServer) claimTotp(ctx context.Context, user *db.User, code string) (bool, error) {
	step, ok := totpStep(user.TotpSecret.String, code, time.Now())
	if !ok {
		return false, nil
	}
	rows, err := s.queries.ClaimTotpStep(ctx, db.ClaimTotpStepParams{ID: user.ID, TotpLastStep: step})
	if err != nil {
		return false, err
	}
	return rows == 1, nil
}

func (s *apiServer) Logout(w http.ResponseWriter, r *http.Request) {
	if cookie, err := r.Cookie(sessionCookie); err == nil {
		if err := s.queries.DeleteSession(r.Context(), auth.HashToken(cookie.Value)); err != nil {
			internalError(w, r, err)
			return
		}
	}
	clearSessionCookie(w, r)
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) ChangePassword(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	var body api.ChangePasswordRequest
	if !readJSON(w, r, &body) {
		return
	}
	if !auth.VerifyPassword(user.PasswordHash, body.CurrentPassword) {
		writeError(w, http.StatusUnauthorized, "the current password is wrong")
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
	var keep []byte
	if cookie, err := r.Cookie(sessionCookie); err == nil {
		keep = auth.HashToken(cookie.Value)
	}
	err = pgx.BeginFunc(r.Context(), s.Pool, func(tx pgx.Tx) error {
		q := s.queries.WithTx(tx)
		if err := q.SetPassword(r.Context(), db.SetPasswordParams{ID: user.ID, PasswordHash: hash}); err != nil {
			return err
		}
		// Someone who got in before the change must not stay in. A phone signs in again for its backup.
		if err := q.DeleteUserAPIKeys(r.Context(), user.ID); err != nil {
			return err
		}
		return q.DeleteOtherSessions(r.Context(), db.DeleteOtherSessionsParams{UserID: user.ID, Keep: keep})
	})
	if err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) SetupTotp(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	if user.TotpEnabled {
		writeError(w, http.StatusConflict, "two-factor sign-in is already on")
		return
	}
	key, err := totp.Generate(totp.GenerateOpts{Issuer: "Mediarr", AccountName: user.Email, Period: totpPeriod, Digits: otp.DigitsSix, Algorithm: otp.AlgorithmSHA1})
	if err != nil {
		internalError(w, r, err)
		return
	}
	if err := s.queries.SetTotpSecret(r.Context(), db.SetTotpSecretParams{ID: user.ID, TotpSecret: pgtype.Text{String: key.Secret(), Valid: true}}); err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, api.TotpSetup{Secret: key.Secret(), Uri: key.URL()})
}

func (s *apiServer) EnableTotp(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	var body api.TotpCode
	if !readJSON(w, r, &body) {
		return
	}
	if !user.TotpSecret.Valid {
		writeError(w, http.StatusBadRequest, "start two-factor setup first")
		return
	}
	step, ok := totpStep(user.TotpSecret.String, body.Code, time.Now())
	if !ok {
		writeError(w, http.StatusBadRequest, "the code is wrong")
		return
	}
	if err := s.queries.EnableTotp(r.Context(), db.EnableTotpParams{ID: user.ID, TotpLastStep: step}); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) DisableTotp(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	var body api.PasswordConfirm
	if !readJSON(w, r, &body) {
		return
	}
	if !auth.VerifyPassword(user.PasswordHash, body.Password) {
		writeError(w, http.StatusUnauthorized, "the password is wrong")
		return
	}
	if err := s.queries.DisableTotp(r.Context(), user.ID); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) CreateDeviceKey(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	var body api.CreateDeviceKeyRequest
	if !readJSON(w, r, &body) {
		return
	}
	name := strings.TrimSpace(body.Name)
	if name == "" || len(name) > 100 {
		writeError(w, http.StatusBadRequest, "enter a device name")
		return
	}
	key, hash, err := auth.NewToken()
	if err != nil {
		internalError(w, r, err)
		return
	}
	// A phone's backup only ever sends files, so a stolen phone key cannot read the library.
	id, err := s.queries.CreateAPIKey(r.Context(), db.CreateAPIKeyParams{
		UserID: user.ID, Name: name, KeyHash: hash, Scopes: []string{scopeUpload},
	})
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusCreated, api.DeviceKey{Id: uuid.UUID(id.Bytes), Key: key})
}

func (s *apiServer) RevokeDeviceKey(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	if err := s.queries.DeleteAPIKey(r.Context(), db.DeleteAPIKeyParams{ID: pgUUID(id), UserID: user.ID}); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) ListUsers(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	users, err := s.queries.ListUsers(r.Context())
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := make([]api.User, len(users))
	for i := range users {
		out[i] = toAPIUser(&users[i])
	}
	writeJSON(w, http.StatusOK, out)
}

func (s *apiServer) CreateUser(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	var body api.CreateUserRequest
	if !readJSON(w, r, &body) {
		return
	}
	email, name, problem := validateNewUser(body.Email, body.Name, body.Password)
	if problem != "" {
		writeError(w, http.StatusBadRequest, problem)
		return
	}
	hash, err := auth.HashPassword(body.Password)
	if err != nil {
		internalError(w, r, err)
		return
	}
	user, err := s.queries.CreateUser(r.Context(), db.CreateUserParams{Email: email, Name: name, PasswordHash: hash, IsAdmin: body.IsAdmin})
	if err != nil {
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) && pgErr.Code == uniqueViolated {
			writeError(w, http.StatusConflict, "a user with this email already exists")
			return
		}
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusCreated, toAPIUser(&user))
}
