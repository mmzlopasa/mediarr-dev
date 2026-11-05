package app

import (
	"context"
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
	"strconv"
	"strings"
	"sync/atomic"
	"syscall"
	"time"

	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

const (
	releasesURL     = "https://api.github.com/repos/mediarr-app/mediarr/tags?per_page=30"
	updateEvery     = 6 * time.Hour
	updateWait      = 15 * time.Second
	maxUpdateAnswer = 1 << 20
	versionParts    = 3
)

// latestVersion is what the public repository last said. Empty until it has answered.
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

func (s *apiServer) watchUpdates() {
	for {
		latest, err := fetchLatestVersion(context.Background())
		if err != nil {
			slog.Info("could not check for a new version", "error", err)
		} else if latest != "" {
			latestVersion.Store(&latest)
		}
		time.Sleep(updateEvery)
	}
}

func fetchLatestVersion(ctx context.Context) (string, error) {
	ctx, cancel := context.WithTimeout(ctx, updateWait)
	defer cancel()
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, releasesURL, http.NoBody)
	if err != nil {
		return "", err
	}
	response, err := http.DefaultClient.Do(request)
	if err != nil {
		return "", err
	}
	defer func() { _ = response.Body.Close() }()
	var tags []struct {
		Name string `json:"name"`
	}
	if err := json.NewDecoder(io.LimitReader(response.Body, maxUpdateAnswer)).Decode(&tags); err != nil {
		return "", err
	}
	names := make([]string, len(tags))
	for i := range tags {
		names[i] = tags[i].Name
	}
	return newestVersion(names), nil
}

func newestVersion(names []string) string {
	newest := ""
	for _, name := range names {
		if _, ok := parseVersion(name); ok && (newest == "" || isNewerVersion(name, newest)) {
			newest = name
		}
	}
	return newest
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
