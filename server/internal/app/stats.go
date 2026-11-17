package app

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/jackc/pgx/v5/pgtype"

	"github.com/mediarr-app/mediarr/server/internal/api"
)

// GetServerStats gives a monitoring dashboard the numbers of the whole server. It changes nothing, so
// an administrator's key with only the read scope may ask for it; the admin scope is not needed.
func (s *apiServer) GetServerStats(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	if !user.IsAdmin {
		writeError(w, http.StatusForbidden, "administrators only")
		return
	}
	stats, err := s.serverStats(r.Context())
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, stats)
}

func (s *apiServer) serverStats(ctx context.Context) (*api.ServerStats, error) {
	overview, err := s.adminOverview(ctx)
	if err != nil {
		return nil, err
	}
	stats := &api.ServerStats{
		Photos:         overview.Photos,
		Videos:         overview.Videos,
		UsageBytes:     overview.LibraryBytes,
		Users:          overview.Users,
		Processing:     overview.Processing,
		Failed:         overview.Failed,
		DiskTotalBytes: overview.DiskTotalBytes,
		DiskFreeBytes:  overview.DiskFreeBytes,
		Version:        overview.Version,
	}

	var last pgtype.Timestamptz
	if err := s.Pool.QueryRow(ctx, `SELECT max(created_at) FROM assets WHERE deleted_at IS NULL`).Scan(&last); err != nil {
		return nil, fmt.Errorf("read the newest upload: %w", err)
	}
	if last.Valid {
		at := last.Time.UTC().Truncate(time.Second)
		stats.LastUploadAt = &at
	}

	rows, err := s.Pool.Query(ctx, `
		SELECT queue,
		       count(*) FILTER (WHERE state IN ('available', 'pending', 'retryable', 'scheduled')),
		       count(*) FILTER (WHERE state = 'running'),
		       count(*) FILTER (WHERE state IN ('cancelled', 'discarded'))
		FROM river_job GROUP BY queue ORDER BY queue`)
	if err != nil {
		return nil, fmt.Errorf("count jobs by queue: %w", err)
	}
	defer rows.Close()
	// Always a list, also when no work has been done yet, so a dashboard can add it up.
	stats.Jobs = make([]struct {
		Failed  int64  `json:"failed"`
		Queue   string `json:"queue"`
		Queued  int64  `json:"queued"`
		Running int64  `json:"running"`
	}, 0)
	for rows.Next() {
		var job struct {
			Failed  int64  `json:"failed"`
			Queue   string `json:"queue"`
			Queued  int64  `json:"queued"`
			Running int64  `json:"running"`
		}
		if err := rows.Scan(&job.Queue, &job.Queued, &job.Running, &job.Failed); err != nil {
			return nil, fmt.Errorf("read jobs by queue: %w", err)
		}
		stats.Jobs = append(stats.Jobs, job)
	}
	return stats, rows.Err()
}
