package app

import (
	"crypto/rand"
	"errors"
	"net/http"
	"net/url"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/auth"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

const (
	qrLifetime = 5 * time.Minute
	// qrAnswerTime is how long a device that has scanned the code waits for an answer at least.
	qrAnswerTime = 2 * time.Minute
	qrWaitTime   = 25 * time.Second
	qrCodeLength = 8
	// Without 0, 1, I and O, which look alike when typed by hand.
	qrAlphabet       = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
	maxQRSignIns     = 10000
	qrCreatesPerMin  = 10
	qrFailuresPerMin = 10
	maxDeviceName    = 80
	serverHelloPath  = "/api/server/hello"
)

const (
	qrWaiting   = "waiting"
	qrRequested = "requested"
	qrAllowed   = "allowed"
	qrDenied    = "denied"
	qrUsed      = "used"
	qrExpired   = "expired"
)

// qrSignIn is one code shown on a signed-in screen, for one other device.
type qrSignIn struct {
	id         string
	user       pgtype.UUID
	codeHash   string
	ticketHash string
	status     string
	device     string
	from       string
	expires    time.Time
	// changed is closed and replaced whenever the status changes, so that waiting requests wake.
	changed chan struct{}
}

// qrSignIns lives in memory: a code lasts minutes, and a restart only means scanning again.
type qrSignIns struct {
	mu       sync.Mutex
	byID     map[string]*qrSignIn
	byCode   map[string]*qrSignIn
	byTicket map[string]*qrSignIn
	creates  *auth.Limiter
	failures *auth.Limiter
}

func newQRSignIns() *qrSignIns {
	return &qrSignIns{
		byID: map[string]*qrSignIn{}, byCode: map[string]*qrSignIn{}, byTicket: map[string]*qrSignIn{},
		creates:  auth.NewLimiter(qrCreatesPerMin, time.Minute),
		failures: auth.NewLimiter(qrFailuresPerMin, time.Minute),
	}
}

func (q *qrSignIns) forget(item *qrSignIn) {
	delete(q.byID, item.id)
	delete(q.byCode, item.codeHash)
	if item.ticketHash != "" {
		delete(q.byTicket, item.ticketHash)
	}
}

// sweep is called with the lock held.
func (q *qrSignIns) sweep(now time.Time) {
	for _, item := range q.byID {
		if now.After(item.expires) {
			q.forget(item)
		}
	}
	for len(q.byID) >= maxQRSignIns {
		for _, item := range q.byID {
			q.forget(item)
			break
		}
	}
}

func (q *qrSignIns) setStatus(item *qrSignIn, status string) {
	item.status = status
	close(item.changed)
	item.changed = make(chan struct{})
}

func newQRCode() (string, error) {
	random := make([]byte, qrCodeLength)
	if _, err := rand.Read(random); err != nil {
		return "", err
	}
	code := make([]byte, qrCodeLength)
	for i, b := range random {
		// 256 is a multiple of 32, so every character is as likely.
		code[i] = qrAlphabet[int(b)%len(qrAlphabet)]
	}
	return string(code), nil
}

// normalQRCode accepts what a person types: lower case, spaces and the dash between the halves.
func normalQRCode(code string) string {
	code = strings.ToUpper(code)
	return strings.Map(func(r rune) rune {
		if r == '-' || r == ' ' {
			return -1
		}
		return r
	}, code)
}

func qrLink(server, code string) string {
	values := url.Values{}
	values.Set("server", server)
	values.Set("code", code)
	return "mediarr://sign-in?" + values.Encode()
}

func shownQRCode(code string) string {
	return code[:qrCodeLength/2] + "-" + code[qrCodeLength/2:]
}

func (s *apiServer) CreateQRSignIn(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	key := uuid.UUID(user.ID.Bytes).String()
	q := s.qrSignIns
	q.mu.Lock()
	defer q.mu.Unlock()
	if !q.creates.Allowed(key) {
		writeError(w, http.StatusTooManyRequests, "too many codes; wait a minute")
		return
	}
	q.creates.Fail(key)
	now := time.Now()
	q.sweep(now)
	code, err := newQRCode()
	if err != nil {
		internalError(w, r, err)
		return
	}
	id, err := randomText()
	if err != nil {
		internalError(w, r, err)
		return
	}
	item := &qrSignIn{
		id: id, user: user.ID, codeHash: string(auth.HashToken(code)), status: qrWaiting,
		from: limitedAgent(r), expires: now.Add(qrLifetime), changed: make(chan struct{}),
	}
	q.byID[id] = item
	q.byCode[item.codeHash] = item
	server := publicOrigin(r)
	writeJSON(w, http.StatusOK, api.QRSignIn{
		Id: id, Code: shownQRCode(code), Link: qrLink(server, code), Server: &server, ExpiresAt: item.expires,
	})
}

// mine finds a code of the signed-in user; anyone else's is not found.
func (s *apiServer) myQRSignIn(w http.ResponseWriter, r *http.Request, id string) *qrSignIn {
	user := requireUser(w, r)
	if user == nil {
		return nil
	}
	item := s.qrSignIns.byID[id]
	if item == nil || item.user != user.ID {
		writeError(w, http.StatusNotFound, "this code has expired")
		return nil
	}
	return item
}

func qrState(item *qrSignIn, now time.Time) api.QRSignInState {
	state := api.QRSignInState{Status: api.QRSignInStateStatus(item.status), ExpiresAt: item.expires}
	if now.After(item.expires) && item.status != qrUsed {
		state.Status = qrExpired
	}
	if item.device != "" {
		state.Device = &item.device
	}
	return state
}

func (s *apiServer) GetQRSignIn(w http.ResponseWriter, r *http.Request, id string) {
	q := s.qrSignIns
	q.mu.Lock()
	defer q.mu.Unlock()
	item := s.myQRSignIn(w, r, id)
	if item == nil {
		return
	}
	writeJSON(w, http.StatusOK, qrState(item, time.Now()))
}

func (s *apiServer) AnswerQRSignIn(w http.ResponseWriter, r *http.Request, id string) {
	var body api.QRAnswer
	if !readJSON(w, r, &body) {
		return
	}
	q := s.qrSignIns
	q.mu.Lock()
	defer q.mu.Unlock()
	item := s.myQRSignIn(w, r, id)
	if item == nil {
		return
	}
	if item.status != qrRequested || time.Now().After(item.expires) {
		writeError(w, http.StatusConflict, "no device is waiting for an answer")
		return
	}
	if body.Allow {
		q.setStatus(item, qrAllowed)
	} else {
		q.setStatus(item, qrDenied)
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) RedeemQRSignIn(w http.ResponseWriter, r *http.Request) {
	var body api.QRRedeem
	if !readJSON(w, r, &body) {
		return
	}
	device := strings.TrimSpace(body.Device)
	if device == "" || len(device) > maxDeviceName {
		writeError(w, http.StatusBadRequest, "say what this device is called, in up to 80 characters")
		return
	}
	ip := hostOnly(clientIP(r))
	q := s.qrSignIns
	q.mu.Lock()
	defer q.mu.Unlock()
	if !q.failures.Allowed(ip) {
		writeError(w, http.StatusTooManyRequests, "too many attempts; try again later")
		return
	}
	now := time.Now()
	item := q.byCode[string(auth.HashToken(normalQRCode(body.Code)))]
	// A code is handed in once: whoever was first is shown to the person who must answer.
	if item == nil || item.status != qrWaiting || now.After(item.expires) {
		q.failures.Fail(ip)
		s.recordSecurity(r, eventLoginFailed, "", "QR code")
		writeError(w, http.StatusUnauthorized, "this code has expired or was already used; make a new one")
		return
	}
	ticket, hash, err := auth.NewToken()
	if err != nil {
		internalError(w, r, err)
		return
	}
	item.ticketHash = string(hash)
	item.device = device
	q.byTicket[item.ticketHash] = item
	if answerBy := now.Add(qrAnswerTime); item.expires.Before(answerBy) {
		item.expires = answerBy
	}
	q.setStatus(item, qrRequested)
	writeJSON(w, http.StatusOK, api.QRTicket{Ticket: ticket})
}

var errQRGone = errors.New("this sign-in has expired")

// waitForAnswer returns the sign-in once it is answered, or nil when the time to wait is over.
func (q *qrSignIns) waitForAnswer(r *http.Request, ticket string) (*qrSignIn, error) {
	hash := auth.HashToken(ticket)
	deadline := time.NewTimer(qrWaitTime)
	defer deadline.Stop()
	for {
		q.mu.Lock()
		item := q.byTicket[string(hash)]
		if item == nil || time.Now().After(item.expires) {
			q.mu.Unlock()
			return nil, errQRGone
		}
		if item.status != qrRequested {
			q.mu.Unlock()
			return item, nil
		}
		changed := item.changed
		q.mu.Unlock()
		select {
		case <-changed:
		case <-deadline.C:
			return nil, nil
		case <-r.Context().Done():
			return nil, nil
		}
	}
}

func (s *apiServer) WaitQRSignIn(w http.ResponseWriter, r *http.Request) {
	var body api.QRTicket
	if !readJSON(w, r, &body) {
		return
	}
	q := s.qrSignIns
	item, err := q.waitForAnswer(r, body.Ticket)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err.Error())
		return
	}
	if item == nil {
		w.WriteHeader(http.StatusAccepted)
		return
	}
	q.mu.Lock()
	status := item.status
	if status == qrAllowed {
		// The ticket works once, so the session is made only once.
		q.setStatus(item, qrUsed)
		delete(q.byTicket, item.ticketHash)
	}
	q.mu.Unlock()
	if status != qrAllowed {
		writeError(w, http.StatusForbidden, "the sign-in was not allowed")
		return
	}
	ctx := r.Context()
	user, err := s.queries.GetUserByID(ctx, item.user)
	if err != nil {
		internalError(w, r, err)
		return
	}
	if s.closedForMaintenance(w, r, user.IsAdmin) {
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
	s.recordSecurity(r, eventLoginOK, user.Email, "QR code from "+item.from)
	writeJSON(w, http.StatusOK, toAPIUser(&user))
}

func (s *apiServer) GetServerHello(w http.ResponseWriter, r *http.Request) {
	settings, err := jobs.LoadServerSettings(r.Context(), s.queries)
	if err != nil {
		internalError(w, r, err)
		return
	}
	if settings.HiddenOnNetwork {
		writeError(w, http.StatusNotFound, "not found")
		return
	}
	writeJSON(w, http.StatusOK, api.ServerHello{App: api.ServerHelloAppMediarr, Version: Version, Name: new(settings.Name())})
}
