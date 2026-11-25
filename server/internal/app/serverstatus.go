package app

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"sync/atomic"
	"syscall"
	"time"

	"github.com/google/uuid"
	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

const (
	updateEvery        = 6 * time.Hour
	updateWait         = 15 * time.Second
	maxUpdateAnswer    = 1 << 16
	maxUpdateRedirects = 3
	versionParts       = 3
	stateInstallID     = "install_id"
)

// updateURL is where the newest version is read. Only tests change it.
var updateURL = "https://cdn.mediarr.app/install/cli/latest.json"

// latestVersion is what Mediarr's site last said. Empty until it has answered.
var latestVersion atomic.Pointer[string]

func (s *apiServer) GetServerStatus(w http.ResponseWriter, r *http.Request) {
	if requireUser(w, r) == nil {
		return
	}
	var disk syscall.Statfs_t
	if err := syscall.Statfs(s.LibraryPath, &disk); err != nil {
		internalError(w, r, err)
		return
	}
	size := int64(disk.Bsize)          //nolint:unconvert // Bsize differs by platform.
	total := int64(disk.Blocks) * size //nolint:gosec // Disks are far below the limit.
	free := int64(disk.Bfree) * size   //nolint:gosec // Disks are far below the limit.
	settings, err := jobs.LoadServerSettings(r.Context(), s.queries)
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := api.ServerStatus{
		Version: Version, DiskTotalBytes: total, DiskUsedBytes: total - free, TrashDays: settings.TrashDays,
	}
	if latest := latestVersion.Load(); latest != nil {
		out.LatestVersion = latest
		out.UpdateAvailable = isNewerVersion(*latest, Version)
	}
	writeJSON(w, http.StatusOK, out)
}

// watchUpdates checks every few hours until the server stops. Turned off, it sends nothing.
func watchUpdates(store updateStore, on bool) {
	if !on {
		return
	}
	for {
		latest, err := checkForUpdate(context.Background(), store)
		if err != nil {
			slog.Info("could not check for a new version", "error", err)
		} else if latest != "" {
			latestVersion.Store(&latest)
		}
		time.Sleep(updateEvery)
	}
}

// updateStore is the part of the database the check needs.
type updateStore interface {
	GetState(ctx context.Context, key string) (string, error)
	SetState(ctx context.Context, arg db.SetStateParams) error
	CountUsers(ctx context.Context) (int64, error)
}

// checkForUpdate asks Mediarr's site for the newest version. It sends only the install number, the
// version running here and how many accounts there are, so installs can be counted without
// knowing anything about them.
func checkForUpdate(ctx context.Context, store updateStore) (string, error) {
	install, err := installID(ctx, store)
	if err != nil {
		return "", err
	}
	users, err := store.CountUsers(ctx)
	if err != nil {
		return "", err
	}
	address, err := url.Parse(updateURL)
	if err != nil {
		return "", err
	}
	address.RawQuery = url.Values{
		"i": {install}, "v": {Version}, "u": {strconv.FormatInt(users, 10)},
	}.Encode()

	ctx, cancel := context.WithTimeout(ctx, updateWait)
	defer cancel()
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, address.String(), http.NoBody)
	if err != nil {
		return "", err
	}
	request.Header.Set("User-Agent", "Mediarr/"+Version)
	response, err := updateClient.Do(request)
	if err != nil {
		return "", err
	}
	defer func() { _ = response.Body.Close() }()
	if response.StatusCode != http.StatusOK {
		return "", fmt.Errorf("the site answered %s", response.Status)
	}
	var answer struct {
		Version string `json:"version"`
	}
	if err := json.NewDecoder(io.LimitReader(response.Body, maxUpdateAnswer)).Decode(&answer); err != nil {
		return "", err
	}
	if _, ok := parseVersion(answer.Version); !ok {
		return "", fmt.Errorf("the site named no version: %q", answer.Version)
	}
	return answer.Version, nil
}

// installID is a random number made the first time this installation checks. It says nothing about
// the server; it only lets the same install be counted once.
func installID(ctx context.Context, store updateStore) (string, error) {
	value, err := store.GetState(ctx, stateInstallID)
	if err == nil {
		if _, bad := uuid.Parse(value); bad == nil {
			return value, nil
		}
	} else if !db.IsNotFound(err) {
		return "", err
	}
	value = uuid.NewString()
	if err := store.SetState(ctx, db.SetStateParams{Key: stateInstallID, Value: value}); err != nil {
		return "", err
	}
	return value, nil
}

// updateClient sends no cookies, asks for no compression and follows a redirect only on the same host.
var updateClient = &http.Client{
	Transport: &http.Transport{Proxy: http.ProxyFromEnvironment, DisableCompression: true},
	CheckRedirect: func(next *http.Request, via []*http.Request) error {
		if len(via) >= maxUpdateRedirects || next.URL.Host != via[0].URL.Host {
			return http.ErrUseLastResponse
		}
		return nil
	},
}

func parseVersion(text string) ([versionParts]int, bool) {
	var out [versionParts]int
	parts := strings.Split(strings.TrimPrefix(text, "v"), ".")
	if len(parts) != versionParts {
		return out, false
	}
	for i, part := range parts {
		number, err := strconv.Atoi(part)
		if err != nil || number < 0 {
			return out, false
		}
		out[i] = number
	}
	return out, true
}

// isNewerVersion is false for anything that is not a plain version, such as a development build.
func isNewerVersion(candidate, current string) bool {
	first, ok := parseVersion(candidate)
	second, also := parseVersion(current)
	if !ok || !also {
		return false
	}
	for i := range first {
		if first[i] != second[i] {
			return first[i] > second[i]
		}
	}
	return false
}
