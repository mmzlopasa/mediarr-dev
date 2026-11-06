package jobs

import (
	"bytes"
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"log/slog"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/mediarr-app/mediarr/server/db"
)

const (
	// KeepDeletedFor is how long a host keeps what a guest deleted, against an attacker who takes over
	// the guest and deletes its backup.
	KeepDeletedFor = 90 * 24 * time.Hour
	// KeepInviteFor is how long a code to pair with works.
	KeepInviteFor  = 7 * 24 * time.Hour
	keepCodePrefix = "mediarr-keep:"
	keepDateLayout = "2006-01-02"
	pairWait       = 30 * time.Second
	maxPairAnswer  = 64 << 10
	notifyLate     = "backup_late"
)

// KeepRepoDir is where the encrypted backup of a guest is kept, on the disk of the library.
func KeepRepoDir(library string, guest uuid.UUID) string {
	return filepath.Join(library, ".keep", guest.String(), "repo")
}

// KeepDeletedDir is where what a guest deleted waits, by the day it was deleted.
func KeepDeletedDir(library string, guest uuid.UUID) string {
	return filepath.Join(library, ".keep", guest.String(), "deleted")
}

// KeepGuestDir holds both.
func KeepGuestDir(library string, guest uuid.UUID) string {
	return filepath.Join(library, ".keep", guest.String())
}

// NewKeepSecret is a random secret and the hash that is all a host keeps of it.
func NewKeepSecret() (secret string, hash []byte, err error) {
	raw := make([]byte, 32)
	if _, err := rand.Read(raw); err != nil {
		return "", nil, err
	}
	secret = base64.RawURLEncoding.EncodeToString(raw)
	return secret, KeepHash(secret), nil
}

// KeepHash is how a secret or the token of an invitation is kept and compared.
func KeepHash(secret string) []byte {
	sum := sha256.Sum256([]byte(secret))
	return sum[:]
}

// KeepCode is what a host's administrator gives to the guest's: where to reach the host, and the
// token of the invitation.
type KeepCode struct {
	Address string `json:"a"`
	Token   string `json:"t"`
	Name    string `json:"n"`
}

// Encode writes the code as text that can be copied, typed or shown as a QR code.
func (c KeepCode) Encode() string {
	raw, _ := json.Marshal(c) //nolint:errchkjson // Plain strings always encode.
	return keepCodePrefix + base64.RawURLEncoding.EncodeToString(raw)
}

// ParseKeepCode reads a code, forgiving spaces and line breaks from copying it.
func ParseKeepCode(text string) (KeepCode, error) {
	var code KeepCode
	text = strings.Join(strings.Fields(text), "")
	body, ok := strings.CutPrefix(text, keepCodePrefix)
	if !ok {
		return code, errors.New("this is not a code from another Mediarr")
	}
	raw, err := base64.RawURLEncoding.DecodeString(body)
	if err != nil || json.Unmarshal(raw, &code) != nil || code.Token == "" {
		return code, errors.New("this code is damaged; copy it again")
	}
	address, err := CleanKeepAddress(code.Address)
	if err != nil {
		return code, err
	}
	code.Address = address
	return code, nil
}

// CleanKeepAddress accepts the address of a Mediarr server as http(s)://host[:port], with no path.
func CleanKeepAddress(address string) (string, error) {
	parsed, err := url.Parse(strings.TrimSpace(address))
	if err != nil || parsed.Host == "" || (parsed.Scheme != "http" && parsed.Scheme != "https") || parsed.User != nil {
		return "", errors.New("the address must look like https://photos.example.com or http://192.168.1.10:9851")
	}
	return parsed.Scheme + "://" + parsed.Host + strings.TrimRight(parsed.Path, "/"), nil
}

// KeepPairing is what a host answers to a code: the credentials of the guest, once.
type KeepPairing struct {
	GuestID    uuid.UUID `json:"guestId"`
	Secret     string    `json:"secret"`
	Name       string    `json:"name"`
	QuotaBytes int64     `json:"quotaBytes"`
}

// PairWithHost turns a code into credentials, by asking the host it names. It follows no
// redirects, which could carry the token somewhere else.
func PairWithHost(ctx context.Context, code KeepCode) (*KeepPairing, error) {
	body, _ := json.Marshal(map[string]string{"token": code.Token}) //nolint:errchkjson // A plain string.
	request, err := http.NewRequestWithContext(ctx, http.MethodPost, code.Address+"/api/keep/pair", bytes.NewReader(body))
	if err != nil {
		return nil, err
	}
	request.Header.Set("Content-Type", "application/json")
	client := &http.Client{Timeout: pairWait, CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }}
	response, err := client.Do(request)
	if err != nil {
		return nil, fmt.Errorf("the other Mediarr cannot be reached at %s", code.Address)
	}
	defer func() { _ = response.Body.Close() }()
	raw, err := io.ReadAll(io.LimitReader(response.Body, maxPairAnswer))
	if err != nil {
		return nil, err
	}
	if response.StatusCode != http.StatusOK {
		var problem struct {
			Message string `json:"message"`
		}
		if json.Unmarshal(raw, &problem) == nil && problem.Message != "" {
			return nil, errors.New(problem.Message)
		}
		return nil, fmt.Errorf("the other Mediarr answered %d", response.StatusCode)
	}
	var pairing KeepPairing
	if err := json.Unmarshal(raw, &pairing); err != nil || pairing.Secret == "" || pairing.GuestID == uuid.Nil {
		return nil, errors.New("the other Mediarr gave an answer that cannot be used")
	}
	return &pairing, nil
}

// DestinationSettings are the settings restic needs to send a backup to another Mediarr. The
// password is this server's own backup password, which the host never sees.
func DestinationSettings(destination *db.BackupDestination, password string) *BackupSettings {
	return &BackupSettings{
		Repository:   "rest:" + destination.Address + "/api/keep/" + uuidString(destination.GuestID) + "/",
		Password:     password,
		RestUser:     uuidString(destination.GuestID),
		RestPassword: destination.Secret,
	}
}

// KeepUsage is how much a guest takes on the disk, and how much of it is what it deleted.
func KeepUsage(library string, guest uuid.UUID) (used, deleted int64) {
	sum := func(root string) int64 {
		var total int64
		_ = filepath.WalkDir(root, func(_ string, entry fs.DirEntry, err error) error {
			if err == nil && entry.Type().IsRegular() {
				if info, err := entry.Info(); err == nil {
					total += info.Size()
				}
			}
			return nil
		})
		return total
	}
	deleted = sum(KeepDeletedDir(library, guest))
	return sum(KeepRepoDir(library, guest)) + deleted, deleted
}

// SoftDeleteKeep moves a file a guest deleted aside, by the day, instead of deleting it.
func SoftDeleteKeep(library string, guest uuid.UUID, rel string, now time.Time) error {
	from := filepath.Join(KeepRepoDir(library, guest), rel)
	to := filepath.Join(KeepDeletedDir(library, guest), now.UTC().Format(keepDateLayout), rel)
	if err := os.MkdirAll(filepath.Dir(to), 0o750); err != nil {
		return err
	}
	err := os.Rename(from, to)
	if errors.Is(err, os.ErrNotExist) {
		// Deleting twice is fine: restic tries again when an answer is lost.
		return nil
	}
	return err
}

// RestoreKeepDeleted puts back everything a guest deleted that is still kept. A file that is there
// again, sent anew, stays as it is.
func RestoreKeepDeleted(library string, guest uuid.UUID) (int, error) {
	root := KeepDeletedDir(library, guest)
	days, err := os.ReadDir(root)
	if errors.Is(err, os.ErrNotExist) {
		return 0, nil
	}
	if err != nil {
		return 0, err
	}
	restored := 0
	for _, day := range days {
		base := filepath.Join(root, day.Name())
		err := filepath.WalkDir(base, func(path string, entry fs.DirEntry, err error) error {
			if err != nil || !entry.Type().IsRegular() {
				return err
			}
			rel, err := filepath.Rel(base, path)
			if err != nil {
				return err
			}
			to := filepath.Join(KeepRepoDir(library, guest), rel)
			if _, err := os.Stat(to); err == nil {
				return os.Remove(path) //nolint:gosec // Only this server writes here, and never a link.
			}
			if err := os.MkdirAll(filepath.Dir(to), 0o750); err != nil {
				return err
			}
			if err := os.Rename(path, to); err != nil { //nolint:gosec // As above.
				return err
			}
			restored++
			return nil
		})
		if err != nil {
			return restored, err
		}
		if err := os.RemoveAll(base); err != nil {
			return restored, err
		}
	}
	return restored, nil
}

// PurgeKeepDeleted removes what guests deleted more than 90 days ago.
func PurgeKeepDeleted(library string, now time.Time) error {
	guests, err := os.ReadDir(filepath.Join(library, ".keep"))
	if errors.Is(err, os.ErrNotExist) {
		return nil
	}
	if err != nil {
		return err
	}
	cutoff := now.Add(-KeepDeletedFor)
	for _, guest := range guests {
		id, err := uuid.Parse(guest.Name())
		if err != nil {
			continue
		}
		days, err := os.ReadDir(KeepDeletedDir(library, id))
		if err != nil {
			continue
		}
		for _, day := range days {
			when, err := time.Parse(keepDateLayout, day.Name())
			if err != nil || !when.Before(cutoff) {
				continue
			}
			if err := os.RemoveAll(filepath.Join(KeepDeletedDir(library, id), day.Name())); err != nil {
				return err
			}
		}
	}
	return nil
}

// WarnLateBackups tells. The subject is "from:<guest>" or "to:<destination>", worded by the interface.
// WarnLateBackups tells the administrators when a copy has not gone out, or a guest's has not come
// in, for three days.
func WarnLateBackups(ctx context.Context, q *db.Queries) error {
	guests, err := q.ListLateKeepGuests(ctx)
	if err != nil {
		return err
	}
	for i := range guests {
		if err := q.NotifyAdmins(ctx, db.NotifyAdminsParams{Kind: notifyLate, Subject: "from:" + guests[i].Name}); err != nil {
			return err
		}
		if err := q.WarnedKeepGuest(ctx, guests[i].ID); err != nil {
			return err
		}
	}
	destinations, err := q.ListLateBackupDestinations(ctx)
	if err != nil {
		return err
	}
	for i := range destinations {
		if err := q.NotifyAdmins(ctx, db.NotifyAdminsParams{Kind: notifyLate, Subject: "to:" + destinations[i].Name}); err != nil {
			return err
		}
		if err := q.WarnedBackupDestination(ctx, destinations[i].ID); err != nil {
			return err
		}
	}
	return nil
}

// keepHousekeeping runs with the nightly cleanup. A failure is logged, as it must not stop the rest.
func keepHousekeeping(ctx context.Context, q *db.Queries, library string) {
	if err := PurgeKeepDeleted(library, time.Now()); err != nil {
		slog.Warn("what guests deleted could not be cleared", "error", err)
	}
	if err := WarnLateBackups(ctx, q); err != nil {
		slog.Warn("late backups could not be told", "error", err)
	}
}
