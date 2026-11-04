package app

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"net"
	"net/http"
	"strings"
	"time"

	"github.com/go-webauthn/webauthn/protocol"
	"github.com/go-webauthn/webauthn/webauthn"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/mmzlopasa/mediarr-app/server/db"
	"github.com/mmzlopasa/mediarr-app/server/internal/api"
	"github.com/mmzlopasa/mediarr-app/server/internal/auth"
)

const (
	passkeyChallengeAge = 5 * time.Minute
	maxPasskeyBody      = 64 * 1024
	maxPasskeyName      = 100
)

// passkeysAvailable is false on a plain http address, where browsers do not offer them at all, and
// on an IP address, which cannot be what a passkey belongs to. Everything else works without them.
func passkeysAvailable(r *http.Request) bool {
	host := hostOnly(r.Host)
	if host == "localhost" {
		return true
	}
	return isHTTPS(r) && net.ParseIP(host) == nil && strings.Contains(host, ".")
}

func relyingParty(r *http.Request) (*webauthn.WebAuthn, error) {
	return webauthn.New(&webauthn.Config{
		RPDisplayName: "Mediarr",
		RPID:          hostOnly(r.Host),
		RPOrigins:     []string{publicOrigin(r)},
	})
}

// passkeyUser is a user as the library needs it.
type passkeyUser struct {
	user        *db.User
	credentials []webauthn.Credential
}

func (u *passkeyUser) WebAuthnID() []byte                         { return u.user.ID.Bytes[:] }
func (u *passkeyUser) WebAuthnName() string                       { return u.user.Email }
func (u *passkeyUser) WebAuthnDisplayName() string                { return u.user.Name }
func (u *passkeyUser) WebAuthnCredentials() []webauthn.Credential { return u.credentials }

func (s *apiServer) loadPasskeyUser(ctx context.Context, user *db.User) (*passkeyUser, error) {
	rows, err := s.queries.ListPasskeys(ctx, user.ID)
	if err != nil {
		return nil, err
	}
	out := &passkeyUser{user: user}
	for i := range rows {
		var credential webauthn.Credential
		if err := json.Unmarshal(rows[i].Credential, &credential); err != nil {
			return nil, err
		}
		out.credentials = append(out.credentials, credential)
	}
	return out, nil
}

type passkeyChallenge struct {
	session webauthn.SessionData
	user    pgtype.UUID
}

func (s *apiServer) rememberChallenge(session *webauthn.SessionData, user pgtype.UUID) (string, error) {
	id, err := randomText()
	if err != nil {
		return "", err
	}
	s.passkeyChallenges.put(id, passkeyChallenge{*session, user}, passkeyChallengeAge)
	return id, nil
}

func passkeysOff(w http.ResponseWriter, r *http.Request) bool {
	if passkeysAvailable(r) {
		return false
	}
	writeError(w, http.StatusConflict, "passkeys need HTTPS and a domain name")
	return true
}

func (s *apiServer) ListPasskeys(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	rows, err := s.queries.ListPasskeys(r.Context(), user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := make([]api.Passkey, len(rows))
	for i := range rows {
		out[i] = api.Passkey{
			Id: uuid.UUID(rows[i].ID.Bytes), Name: rows[i].Name, CreatedAt: rows[i].CreatedAt.Time,
			LastUsedAt: optional(rows[i].LastUsedAt.Time, rows[i].LastUsedAt.Valid),
		}
	}
	writeJSON(w, http.StatusOK, out)
}

func (s *apiServer) DeletePasskey(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	if err := s.queries.DeletePasskey(r.Context(), db.DeletePasskeyParams{ID: pgUUID(id), UserID: user.ID}); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) BeginPasskeyRegistration(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil || passkeysOff(w, r) {
		return
	}
	// A way back in must not be something a stolen session can add by itself.
	var confirm api.PasswordConfirm
	if !readJSON(w, r, &confirm) {
		return
	}
	if !auth.VerifyPassword(user.PasswordHash, confirm.Password) {
		writeError(w, http.StatusUnauthorized, "the password is wrong")
		return
	}
	ctx := r.Context()
	party, err := relyingParty(r)
	if err != nil {
		internalError(w, r, err)
		return
	}
	owner, err := s.loadPasskeyUser(ctx, user)
	if err != nil {
		internalError(w, r, err)
		return
	}
	options, session, err := party.BeginRegistration(owner,
		webauthn.WithResidentKeyRequirement(protocol.ResidentKeyRequirementRequired),
		webauthn.WithExclusions(webauthn.Credentials(owner.credentials).CredentialDescriptors()))
	if err != nil {
		internalError(w, r, err)
		return
	}
	id, err := s.rememberChallenge(session, user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"challengeId": id, "options": options})
}

// passkeyAnswer is what the browser's authenticator produced, as it produced it.
type passkeyAnswer struct {
	ChallengeID string          `json:"challengeId"`
	Name        string          `json:"name"`
	Credential  json.RawMessage `json:"credential"`
}

func readPasskeyAnswer(w http.ResponseWriter, r *http.Request) (*passkeyAnswer, bool) {
	r.Body = http.MaxBytesReader(w, r.Body, maxPasskeyBody)
	var answer passkeyAnswer
	if err := json.NewDecoder(r.Body).Decode(&answer); err != nil {
		writeError(w, http.StatusBadRequest, "this answer cannot be read")
		return nil, false
	}
	return &answer, true
}

func (s *apiServer) FinishPasskeyRegistration(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil || passkeysOff(w, r) {
		return
	}
	answer, ok := readPasskeyAnswer(w, r)
	if !ok {
		return
	}
	name := strings.TrimSpace(answer.Name)
	if name == "" || len(name) > maxPasskeyName {
		writeError(w, http.StatusBadRequest, "enter a name for this passkey")
		return
	}
	challenge, ok := s.passkeyChallenges.take(answer.ChallengeID)
	if !ok || challenge.user != user.ID {
		writeError(w, http.StatusBadRequest, "this attempt has expired, try again")
		return
	}
	ctx := r.Context()
	party, err := relyingParty(r)
	if err != nil {
		internalError(w, r, err)
		return
	}
	owner, err := s.loadPasskeyUser(ctx, user)
	if err != nil {
		internalError(w, r, err)
		return
	}
	parsed, err := protocol.ParseCredentialCreationResponseBytes(answer.Credential)
	if err != nil {
		writeError(w, http.StatusBadRequest, "this passkey cannot be read")
		return
	}
	credential, err := party.CreateCredential(owner, challenge.session, parsed)
	if err != nil {
		slog.Warn("a passkey was refused", "error", err)
		writeError(w, http.StatusBadRequest, "this passkey was refused")
		return
	}
	raw, err := json.Marshal(credential)
	if err != nil {
		internalError(w, r, err)
		return
	}
	if _, err := s.queries.CreatePasskey(ctx, db.CreatePasskeyParams{
		UserID: user.ID, CredentialID: credential.ID, Name: name, Credential: raw,
	}); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) BeginPasskeyLogin(w http.ResponseWriter, r *http.Request) {
	if passkeysOff(w, r) {
		return
	}
	party, err := relyingParty(r)
	if err != nil {
		internalError(w, r, err)
		return
	}
	options, session, err := party.BeginDiscoverableLogin()
	if err != nil {
		internalError(w, r, err)
		return
	}
	id, err := s.rememberChallenge(session, pgtype.UUID{})
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"challengeId": id, "options": options})
}

func (s *apiServer) FinishPasskeyLogin(w http.ResponseWriter, r *http.Request) {
	if passkeysOff(w, r) {
		return
	}
	answer, ok := readPasskeyAnswer(w, r)
	if !ok {
		return
	}
	challenge, ok := s.passkeyChallenges.take(answer.ChallengeID)
	if !ok {
		writeError(w, http.StatusBadRequest, "this attempt has expired, try again")
		return
	}
	ctx := r.Context()
	party, err := relyingParty(r)
	if err != nil {
		internalError(w, r, err)
		return
	}
	parsed, err := protocol.ParseCredentialRequestResponseBytes(answer.Credential)
	if err != nil {
		writeError(w, http.StatusBadRequest, "this passkey cannot be read")
		return
	}
	var owner *passkeyUser
	credential, err := party.ValidateDiscoverableLogin(func(_, handle []byte) (webauthn.User, error) {
		parsedID, err := uuid.FromBytes(handle)
		if err != nil {
			return nil, err
		}
		user, err := s.queries.GetUserByID(ctx, pgUUID(parsedID))
		if err != nil {
			return nil, errors.New("no such user")
		}
		owner, err = s.loadPasskeyUser(ctx, &user)
		return owner, err
	}, challenge.session, parsed)
	if err != nil || owner == nil {
		slog.Warn("a passkey sign-in was refused", "error", err)
		writeError(w, http.StatusUnauthorized, "this passkey was refused")
		return
	}
	noteAuditEmail(r, owner.user.Email)
	if credential.Authenticator.CloneWarning {
		slog.Warn("a passkey looks copied, and was refused", "user", owner.user.Email)
		writeError(w, http.StatusUnauthorized, "this passkey was refused")
		return
	}
	raw, err := json.Marshal(credential)
	if err != nil {
		internalError(w, r, err)
		return
	}
	// The counter in it is how a cloned passkey gets noticed.
	if err := s.queries.UpdatePasskeyCredential(ctx, db.UpdatePasskeyCredentialParams{CredentialID: credential.ID, Credential: raw}); err != nil {
		internalError(w, r, err)
		return
	}
	if err := s.startSession(ctx, w, r, owner.user.ID); err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, toAPIUser(owner.user))
}
