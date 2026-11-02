package app

import (
	"context"
	"fmt"
	"net/http"
	"syscall"

	"github.com/mmzlopasa/mediarr-app/server/internal/api"
)

// Version is set at build time. Development builds report "dev".
var Version = "dev"

func (s *apiServer) GetAdminOverview(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	overview, err := s.adminOverview(r.Context())
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, overview)
}

func (s *apiServer) adminOverview(ctx context.Context) (*api.AdminOverview, error) {
	counts, err := s.queries.AdminCounts(ctx)
	if err != nil {
		return nil, fmt.Errorf("count assets: %w", err)
	}
	overview := &api.AdminOverview{
		Users:        counts.Users,
		Photos:       counts.Photos,
		Videos:       counts.Videos,
		Processing:   counts.Processing,
		Failed:       counts.Failed,
		LibraryBytes: counts.LibraryBytes,
		Version:      Version,
	}

	err = s.Pool.QueryRow(ctx, `
		SELECT count(*) FILTER (WHERE state IN ('available', 'pending', 'retryable', 'scheduled')),
		       count(*) FILTER (WHERE state = 'running'),
		       count(*) FILTER (WHERE state = 'completed'),
		       count(*) FILTER (WHERE state IN ('cancelled', 'discarded'))
		FROM river_job`).Scan(&overview.Jobs.Queued, &overview.Jobs.Running, &overview.Jobs.Completed, &overview.Jobs.Failed)
	if err != nil {
		return nil, fmt.Errorf("count jobs: %w", err)
	}
	if err := s.Pool.QueryRow(ctx, "SHOW server_version").Scan(&overview.DatabaseVersion); err != nil {
		return nil, fmt.Errorf("read database version: %w", err)
	}

	var disk syscall.Statfs_t
	if err := syscall.Statfs(s.LibraryPath, &disk); err != nil {
		return nil, fmt.Errorf("read library disk: %w", err)
	}
	blockSize := int64(disk.Bsize)                           //nolint:unconvert // Bsize differs in type between platforms.
	overview.DiskTotalBytes = int64(disk.Blocks) * blockSize //nolint:gosec // Disks are far below the limit.
	overview.DiskFreeBytes = int64(disk.Bavail) * blockSize  //nolint:gosec // Disks are far below the limit.
	return overview, nil
}
