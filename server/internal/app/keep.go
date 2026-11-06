package app

import (
	"crypto/subtle"
	"errors"
	"net/http"
	"os"
	"path"
	"regexp"
	"strings"
	"sync"
	"syscall"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	openapi_types "github.com/oapi-codegen/runtime/types"
	"github.com/restic/rest-server/repo"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

// --- This server keeps the encrypted backup of other Mediarr servers ---

const (
	keepPrefix        = "/api/keep/"
	keepPairFailures  = 10
	keepAuthFailures  = 20
	keepSeenEvery     = time.Minute
	maxKeepGuestName  = 100
	minKeepQuotaBytes = 1 << 30
)

var (
	// keepRepoPath is a guest's repository and what restic asks of it.
	keepRepoPath = regexp.MustCompile(`^/api/keep/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})(/.*)?$`)
	// keepKept are the files restic deletes that a host keeps for 90 days: everything but locks.
	keepKept = regexp.MustCompile(`^/(data|index|keys|snapshots)/([0-9a-f]{64})$`)
)

// keepState is what the host remembers between requests: how much each guest takes, worked out
// once and then counted, and when it was last written down that a guest was seen.
type keepState struct {
	mu    sync.Mutex
	used  map[uuid.UUID]int64
	seen  map[uuid.UUID]time.Time
	fsync sync.Once
}

func newKeepState() *keepState {
	return &keepState{used: map[uuid.UUID]int64{}, seen: map[uuid.UUID]time.Time{}}
}

func (k *keepState) usage(library string, guest uuid.UUID) int64 {
	k.mu.Lock()
	defer k.mu.Unlock()
	if used, ok := k.used[guest]; ok {
		return used
	}
	used, _ := jobs.KeepUsage(library, guest)
	k.used[guest] = used
	return used
}

func (k *keepState) add(guest uuid.UUID, size int64) {
	k.mu.Lock()
	defer k.mu.Unlock()
	if _, ok := k.used[guest]; ok {
		k.used[guest] += size
	}
}

func (k *keepState) forget(guest uuid.UUID) {
	k.mu.Lock()
	defer k.mu.Unlock()
	delete(k.used, guest)
}

func (k *keepState) shouldMarkSeen(guest uuid.UUID, now time.Time) bool {
	k.mu.Lock()
	defer k.mu.Unlock()
	if now.Sub(k.seen[guest]) < keepSeenEvery {
		return false
	}
	k.seen[guest] = now
	return true
}

func isKeepRepo(path string) bool {
	return strings.HasPrefix(path, keepPrefix) && path != keepPrefix+"pair"
}

// statusRecorder remembers the status a handler answered with.
type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (r *statusRecorder) WriteHeader(status int) {
	r.status = status
	r.ResponseWriter.WriteHeader(status)
}

// serveKeep answers restic for a guest. It is apart from the JSON API: restic sends files, signs in
// with HTTP Basic, and must reach nothing but its own repository.
func (s *apiServer) serveKeep(w http.ResponseWriter, r *http.Request) {
	match := keepRepoPath.FindStringSubmatch(r.URL.Path)
	if match == nil {
		http.NotFound(w, r)
		return
	}
	ip := clientIP(r)
	if !s.keepFailures.Allowed(ip) {
		http.Error(w, "too many failed attempts; wait a while", http.StatusTooManyRequests)
		return
	}
	guestID := uuid.MustParse(match[1])
	user, secret, ok := r.BasicAuth()
	guest, err := s.queries.GetKeepGuest(r.Context(), pgtype.UUID{Bytes: guestID, Valid: true})
	if !ok || user != guestID.String() || err != nil || guest.SecretHash == nil ||
		subtle.ConstantTimeCompare(guest.SecretHash, jobs.KeepHash(secret)) != 1 {
		s.keepFailures.Fail(ip)
		http.Error(w, http.StatusText(http.StatusUnauthorized), http.StatusUnauthorized)
		return
	}
	if guest.Status != "active" {
		http.Error(w, "this server has stopped keeping this backup", http.StatusForbidden)
		return
	}
	now := time.Now()
	if s.keep.shouldMarkSeen(guestID, now) {
		_ = s.queries.SeenKeepGuest(r.Context(), guest.ID)
	}
	rest := match[2]
	if rest == "" {
		rest = "/"
	}
	// What restic deletes is set aside for 90 days, so neither the guest nor someone who took it over
	// can remove its backup at once.
	if r.Method == http.MethodDelete && (rest == "/config" || keepKept.MatchString(rest)) {
		if err := jobs.SoftDeleteKeep(s.LibraryPath, guestID, keepFile(rest), now); err != nil {
			http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusOK)
		return
	}
	var size int64
	if r.Method == http.MethodPost && rest != "/" {
		size = r.ContentLength
		if size < 0 {
			http.Error(w, "say the size of the file", http.StatusLengthRequired)
			return
		}
		if s.keep.usage(s.LibraryPath, guestID)+size > guest.QuotaBytes {
			http.Error(w, "this backup is larger than this server keeps for it", http.StatusInsufficientStorage)
			return
		}
		if err := s.checkKeepRoom(size); err != nil {
			http.Error(w, err.Error(), http.StatusInsufficientStorage)
			return
		}
	}
	handler, err := repo.New(jobs.KeepRepoDir(s.LibraryPath, guestID), repo.Options{FsyncWarning: &s.keep.fsync})
	if err != nil {
		http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
		return
	}
	inner := r.Clone(r.Context())
	inner.URL.Path = rest
	inner.URL.RawPath = ""
	recorder := &statusRecorder{ResponseWriter: w, status: http.StatusOK}
	handler.ServeHTTP(recorder, inner)
	if r.Method == http.MethodPost && recorder.status < http.StatusBadRequest {
		s.keep.add(guestID, size)
		// A new snapshot is a finished backup.
		if strings.HasPrefix(rest, "/snapshots/") {
			_ = s.queries.KeepGuestBackedUp(r.Context(), guest.ID)
		}
	}
}

// keepFile is where restic keeps an object in its repository: data is spread over folders by the
// first two characters of its name.
func keepFile(rest string) string {
	if rest == "/config" {
		return "config"
	}
	match := keepKept.FindStringSubmatch(rest)
	if match[1] == "data" {
		return path.Join("data", match[2][:2], match[2])
	}
	return path.Join(match[1], match[2])
}

// checkKeepRoom refuses a guest's file that would fill the disk.
func (s *apiServer) checkKeepRoom(size int64) error {
	var disk syscall.Statfs_t
	if err := syscall.Statfs(s.LibraryPath, &disk); err != nil {
		return nil //nolint:nilerr // The write then fails on its own if the disk really is the problem.
	}
	if int64(disk.Bavail)*disk.Bsize-size < minFreeDiskBytes { //nolint:gosec // Disk sizes fit.
		return errors.New("the disk of this server is full")
	}
	return nil
}

func (s *apiServer) keepGuestToAPI(row *db.KeepGuest) api.KeepGuest {
	id := uuid.UUID(row.ID.Bytes)
	used, deleted := jobs.KeepUsage(s.LibraryPath, id)
	return api.KeepGuest{
		Id: row.ID.Bytes, Name: row.Name, Status: api.KeepGuestStatus(row.Status), QuotaBytes: row.QuotaBytes,
		UsedBytes: used, DeletedBytes: deleted, Address: row.Address, CreatedAt: row.CreatedAt.Time,
		InviteExpiresAt: optional(row.InviteExpiresAt.Time, row.InviteExpiresAt.Valid),
		LastBackupAt:    optional(row.LastBackupAt.Time, row.LastBackupAt.Valid),
		LastSeenAt:      optional(row.LastSeenAt.Time, row.LastSeenAt.Valid),
	}
}

func (s *apiServer) ListKeepGuests(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	rows, err := s.queries.ListKeepGuests(r.Context())
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := make([]api.KeepGuest, len(rows))
	for i := range rows {
		out[i] = s.keepGuestToAPI(&rows[i])
	}
	writeJSON(w, http.StatusOK, out)
}

// newKeepInvite makes a code, of which only the hash is kept.
func newKeepInvite(address, name string) (code string, hash []byte, expires time.Time, err error) {
	token, hash, err := jobs.NewKeepSecret()
	if err != nil {
		return "", nil, time.Time{}, err
	}
	expires = time.Now().Add(jobs.KeepInviteFor)
	return jobs.KeepCode{Address: address, Token: token, Name: name}.Encode(), hash, expires, nil
}

func (s *apiServer) InviteKeepGuest(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	var body api.KeepGuestCreate
	if !readJSON(w, r, &body) {
		return
	}
	name := strings.TrimSpace(body.Name)
	if name == "" || len(name) > maxKeepGuestName {
		writeError(w, http.StatusBadRequest, "give the other server a name of up to 100 characters")
		return
	}
	if body.QuotaBytes < minKeepQuotaBytes {
		writeError(w, http.StatusBadRequest, "keep at least 1 GB for it")
		return
	}
	address, err := jobs.CleanKeepAddress(body.Address)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	code, hash, expires, err := newKeepInvite(address, name)
	if err != nil {
		internalError(w, r, err)
		return
	}
	row, err := s.queries.CreateKeepGuest(r.Context(), db.CreateKeepGuestParams{
		Name: name, QuotaBytes: body.QuotaBytes, Address: address, InviteHash: hash,
		InviteExpiresAt: pgtype.Timestamptz{Time: expires, Valid: true},
	})
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusCreated, api.KeepInvite{Guest: s.keepGuestToAPI(&row), Code: code, ExpiresAt: expires})
}

func (s *apiServer) ReinviteKeepGuest(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	if requireAdmin(w, r) == nil {
		return
	}
	guest, err := s.queries.GetKeepGuest(r.Context(), pgUUID(id))
	if db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "no such guest")
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	code, hash, expires, err := newKeepInvite(guest.Address, guest.Name)
	if err != nil {
		internalError(w, r, err)
		return
	}
	row, err := s.queries.SetKeepGuestInvite(r.Context(), db.SetKeepGuestInviteParams{
		ID: guest.ID, InviteHash: hash, InviteExpiresAt: pgtype.Timestamptz{Time: expires, Valid: true},
	})
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, api.KeepInvite{Guest: s.keepGuestToAPI(&row), Code: code, ExpiresAt: expires})
}

func (s *apiServer) UpdateKeepGuest(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	if requireAdmin(w, r) == nil {
		return
	}
	var body api.KeepGuestUpdate
	if !readJSON(w, r, &body) {
		return
	}
	if body.QuotaBytes < minKeepQuotaBytes || !body.Status.Valid() {
		writeError(w, http.StatusBadRequest, "keep at least 1 GB, and say whether it is active or stopped")
		return
	}
	guest, err := s.queries.GetKeepGuest(r.Context(), pgUUID(id))
	if db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "no such guest")
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	status := string(body.Status)
	if guest.Status == "invited" {
		// Not paired yet: it becomes active by pairing, not by this.
		status = "invited"
	}
	row, err := s.queries.UpdateKeepGuest(r.Context(), db.UpdateKeepGuestParams{ID: guest.ID, QuotaBytes: body.QuotaBytes, Status: status})
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, s.keepGuestToAPI(&row))
}

func (s *apiServer) RemoveKeepGuest(w http.ResponseWriter, r *http.Request, id openapi_types.UUID, params api.RemoveKeepGuestParams) {
	if requireAdmin(w, r) == nil {
		return
	}
	guest, err := s.queries.GetKeepGuest(r.Context(), pgUUID(id))
	if db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "no such guest")
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	if params.Name == nil || strings.TrimSpace(*params.Name) != guest.Name {
		writeError(w, http.StatusBadRequest, "type the name of the guest to delete its backup")
		return
	}
	if err := s.queries.DeleteKeepGuest(r.Context(), guest.ID); err != nil {
		internalError(w, r, err)
		return
	}
	if err := os.RemoveAll(jobs.KeepGuestDir(s.LibraryPath, id)); err != nil {
		internalError(w, r, err)
		return
	}
	s.keep.forget(id)
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) RestoreKeepGuestDeleted(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	if requireAdmin(w, r) == nil {
		return
	}
	if _, err := s.queries.GetKeepGuest(r.Context(), pgUUID(id)); db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "no such guest")
		return
	} else if err != nil {
		internalError(w, r, err)
		return
	}
	restored, err := jobs.RestoreKeepDeleted(s.LibraryPath, id)
	if err != nil {
		internalError(w, r, err)
		return
	}
	s.keep.forget(id)
	writeJSON(w, http.StatusOK, api.KeepRestored{Restored: restored})
}

// PairKeepGuest gives a guest its credentials for the token of its invitation, once. Nobody is signed
// in: the token is the proof.
func (s *apiServer) PairKeepGuest(w http.ResponseWriter, r *http.Request) {
	ip := clientIP(r)
	if !s.keepPairs.Allowed(ip) {
		writeError(w, http.StatusTooManyRequests, "too many failed attempts; wait a while")
		return
	}
	var body api.KeepPairRequest
	if !readJSON(w, r, &body) {
		return
	}
	secret, hash, err := jobs.NewKeepSecret()
	if err != nil {
		internalError(w, r, err)
		return
	}
	guest, err := s.queries.PairKeepGuest(r.Context(), db.PairKeepGuestParams{InviteHash: jobs.KeepHash(body.Token), SecretHash: hash})
	if db.IsNotFound(err) {
		s.keepPairs.Fail(ip)
		writeError(w, http.StatusNotFound, "this code was used already, has expired, or is wrong; ask for a new one")
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, api.KeepPairing{GuestId: guest.ID.Bytes, Secret: secret, Name: guest.Name, QuotaBytes: guest.QuotaBytes})
}

// --- This server sends a copy of its backup to other Mediarr servers ---

func destinationToAPI(row *db.BackupDestination) api.BackupDestination {
	return api.BackupDestination{
		Id: row.ID.Bytes, Name: row.Name, Address: row.Address, QuotaBytes: row.QuotaBytes, LastError: row.LastError,
		CreatedAt: row.CreatedAt.Time, LastSuccessAt: optional(row.LastSuccessAt.Time, row.LastSuccessAt.Valid),
	}
}

func (s *apiServer) ListBackupDestinations(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	rows, err := s.queries.ListBackupDestinations(r.Context())
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := make([]api.BackupDestination, len(rows))
	for i := range rows {
		out[i] = destinationToAPI(&rows[i])
	}
	writeJSON(w, http.StatusOK, out)
}

// AddBackupDestination pairs with another Mediarr by its code. The server reaches the address in the
// code, which is why only an administrator can do this.
func (s *apiServer) AddBackupDestination(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	var body api.BackupDestinationCreate
	if !readJSON(w, r, &body) {
		return
	}
	code, err := jobs.ParseKeepCode(body.Code)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	pairing, err := jobs.PairWithHost(r.Context(), code)
	if err != nil {
		writeError(w, http.StatusBadGateway, err.Error())
		return
	}
	row, err := s.queries.CreateBackupDestination(r.Context(), db.CreateBackupDestinationParams{
		Name: pairing.Name, Address: code.Address, GuestID: pgtype.UUID{Bytes: pairing.GuestID, Valid: true},
		Secret: pairing.Secret, QuotaBytes: pairing.QuotaBytes,
	})
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusCreated, destinationToAPI(&row))
}

func (s *apiServer) RemoveBackupDestination(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	if requireAdmin(w, r) == nil {
		return
	}
	if _, err := s.queries.GetBackupDestination(r.Context(), pgUUID(id)); db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "no such destination")
		return
	} else if err != nil {
		internalError(w, r, err)
		return
	}
	if err := s.queries.DeleteBackupDestination(r.Context(), pgUUID(id)); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
