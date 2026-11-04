package app

import (
	"context"
	"errors"
	"net/http"
	"slices"
	"time"

	"github.com/jackc/pgx/v5/pgtype"
	openapi_types "github.com/oapi-codegen/runtime/types"
	"github.com/riverqueue/river/rivertype"

	"github.com/mmzlopasa/mediarr-app/server/db"
	"github.com/mmzlopasa/mediarr-app/server/internal/api"
)

const (
	failedJobsShown = 50
	// The worker finishes a periodic job every minute, so this long a silence means it has stopped.
	workerSilence = 5 * time.Minute
	mlHealthWait  = 3 * time.Second
)

var jobQueues = []string{"default", "video", "ml", "import"}

func (s *apiServer) GetAdminJobs(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	ctx := r.Context()
	out := api.AdminJobs{Queues: []api.JobQueue{}, Failed: []api.FailedJob{}}
	rows, err := s.Pool.Query(ctx, `
		SELECT q.name, q.paused,
		       count(*) FILTER (WHERE j.state IN ('available', 'pending', 'retryable', 'scheduled')),
		       count(*) FILTER (WHERE j.state = 'running')
		FROM (SELECT n AS name, EXISTS (SELECT 1 FROM river_queue r WHERE r.name = n AND r.paused_at IS NOT NULL) AS paused
		      FROM unnest($1::text[]) n) q
		LEFT JOIN river_job j ON j.queue = q.name AND j.state IN ('available', 'pending', 'retryable', 'scheduled', 'running')
		GROUP BY q.name, q.paused ORDER BY q.name`, jobQueues)
	if err != nil {
		internalError(w, r, err)
		return
	}
	defer rows.Close()
	for rows.Next() {
		var queue api.JobQueue
		if err := rows.Scan(&queue.Name, &queue.Paused, &queue.Queued, &queue.Running); err != nil {
			internalError(w, r, err)
			return
		}
		out.Queues = append(out.Queues, queue)
	}
	rows.Close()
	failed, err := s.Pool.Query(ctx, `
		SELECT id, kind, queue, coalesce(errors[array_length(errors, 1)]->>'error', ''), coalesce(finalized_at, created_at)
		FROM river_job WHERE state IN ('discarded', 'cancelled')
		ORDER BY id DESC LIMIT $1`, failedJobsShown)
	if err != nil {
		internalError(w, r, err)
		return
	}
	defer failed.Close()
	for failed.Next() {
		var job api.FailedJob
		if err := failed.Scan(&job.Id, &job.Kind, &job.Queue, &job.Error, &job.At); err != nil {
			internalError(w, r, err)
			return
		}
		out.Failed = append(out.Failed, job)
	}
	writeJSON(w, http.StatusOK, out)
}

func (s *apiServer) changeQueue(w http.ResponseWriter, r *http.Request, queue string, change func(context.Context, string) error) {
	if requireAdmin(w, r) == nil {
		return
	}
	if !slices.Contains(jobQueues, queue) {
		writeError(w, http.StatusNotFound, "no such queue")
		return
	}
	if err := change(r.Context(), queue); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) PauseJobQueue(w http.ResponseWriter, r *http.Request, queue string) {
	s.changeQueue(w, r, queue, func(ctx context.Context, name string) error {
		return s.Inserter.QueuePause(ctx, name, nil)
	})
}

func (s *apiServer) ResumeJobQueue(w http.ResponseWriter, r *http.Request, queue string) {
	s.changeQueue(w, r, queue, func(ctx context.Context, name string) error {
		return s.Inserter.QueueResume(ctx, name, nil)
	})
}

func (s *apiServer) RetryJob(w http.ResponseWriter, r *http.Request, id int64) {
	if requireAdmin(w, r) == nil {
		return
	}
	if _, err := s.Inserter.JobRetry(r.Context(), id); err != nil {
		if errors.Is(err, rivertype.ErrNotFound) {
			writeError(w, http.StatusNotFound, "no such job")
			return
		}
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) GetAdminHealth(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	ctx := r.Context()
	out := api.AdminHealth{MlEnabled: s.MLURL != ""}
	var last pgtype.Timestamptz
	if err := s.Pool.QueryRow(ctx, `SELECT max(finalized_at) FROM river_job WHERE state = 'completed'`).Scan(&last); err != nil {
		internalError(w, r, err)
		return
	}
	out.WorkerRunning = last.Valid && time.Since(last.Time) < workerSilence
	out.WorkerLastSeen = optional(last.Time, last.Valid)
	if err := s.Pool.QueryRow(ctx, `SELECT pg_database_size(current_database())`).Scan(&out.DatabaseBytes); err != nil {
		internalError(w, r, err)
		return
	}
	if s.MLURL != "" {
		out.MlRunning = optional(s.mlAnswers(ctx), true)
	}
	writeJSON(w, http.StatusOK, out)
}

func (s *apiServer) mlAnswers(ctx context.Context) bool {
	ctx, cancel := context.WithTimeout(ctx, mlHealthWait)
	defer cancel()
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, s.MLURL+"/health", http.NoBody)
	if err != nil {
		return false
	}
	response, err := http.DefaultClient.Do(request) //nolint:gosec // From the installation's own settings.
	if err != nil {
		return false
	}
	defer func() { _ = response.Body.Close() }()
	return response.StatusCode == http.StatusOK
}

func (s *apiServer) GetAdminStorage(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	rows, err := s.queries.ListUserStorage(r.Context())
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := make([]api.UserStorage, len(rows))
	for i := range rows {
		row := &rows[i]
		out[i] = api.UserStorage{
			Id: row.ID.Bytes, Name: row.Name, Email: row.Email, StoredBytes: row.StoredBytes, Assets: row.Assets,
			QuotaBytes: optional(row.QuotaBytes.Int64, row.QuotaBytes.Valid),
		}
	}
	writeJSON(w, http.StatusOK, out)
}

func (s *apiServer) SetUserQuota(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	if requireAdmin(w, r) == nil {
		return
	}
	var body api.QuotaUpdate
	if !readJSON(w, r, &body) {
		return
	}
	quota := pgtype.Int8{}
	if body.QuotaBytes != nil {
		if *body.QuotaBytes < 0 {
			writeError(w, http.StatusBadRequest, "a quota cannot be negative")
			return
		}
		quota = pgtype.Int8{Int64: *body.QuotaBytes, Valid: true}
	}
	changed, err := s.queries.SetUserQuota(r.Context(), db.SetUserQuotaParams{ID: pgUUID(id), QuotaBytes: quota})
	if err != nil {
		internalError(w, r, err)
		return
	}
	if changed == 0 {
		writeError(w, http.StatusNotFound, "no such user")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) GetTrashSummary(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	row, err := s.queries.TrashSummary(r.Context(), user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, api.TrashSummary{Assets: row.Assets, Bytes: row.Bytes})
}
