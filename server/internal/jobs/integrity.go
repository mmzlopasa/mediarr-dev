package jobs

import (
	"context"
	"crypto/sha256"
	"encoding/json"
	"errors"
	"io"
	"io/fs"
	"log/slog"
	"os"
	"time"

	"github.com/jackc/pgx/v5/pgtype"
	"github.com/riverqueue/river"
	"github.com/riverqueue/river/rivertype"

	"github.com/mediarr-app/mediarr/server/db"
)

const (
	// StateIntegrity holds the last report.
	StateIntegrity   = "integrity_report"
	integrityBatch   = 500
	integrityShown   = 200
	integrityEvery   = 7 * 24 * time.Hour
	integrityTimeout = 48 * time.Hour
)

// IntegrityProblem is one file that is not as it should be.
type IntegrityProblem struct {
	Name    string `json:"name"`
	Path    string `json:"path"`
	Problem string `json:"problem"`
}

// IntegrityReport says how the originals looked when they were last checked.
type IntegrityReport struct {
	FinishedAt time.Time          `json:"finishedAt"`
	Checked    int64              `json:"checked"`
	Thorough   bool               `json:"thorough"`
	Total      int64              `json:"total"`
	Problems   []IntegrityProblem `json:"problems"`
}

// IntegrityArgs checks that originals are there. Thorough also reads each one and compares its
// checksum, which takes as long as reading the whole library.
type IntegrityArgs struct {
	Thorough bool `json:"thorough"`
}

// Kind identifies the job in the queue.
func (IntegrityArgs) Kind() string { return "integrity" }

// InsertOpts shares the queue of long jobs, one at a time.
func (IntegrityArgs) InsertOpts() river.InsertOpts {
	return river.InsertOpts{
		Queue: importQueue,
		UniqueOpts: river.UniqueOpts{ByArgs: true, ByState: []rivertype.JobState{
			rivertype.JobStateAvailable, rivertype.JobStatePending, rivertype.JobStateRetryable,
			rivertype.JobStateRunning, rivertype.JobStateScheduled,
		}},
	}
}

type integrityWorker struct {
	river.WorkerDefaults[IntegrityArgs]
	*deps
}

func (w *integrityWorker) Timeout(*river.Job[IntegrityArgs]) time.Duration {
	return integrityTimeout
}

func (w *integrityWorker) Work(ctx context.Context, job *river.Job[IntegrityArgs]) error {
	report, err := CheckIntegrity(ctx, w.queries, job.Args.Thorough)
	if err != nil {
		return err
	}
	slog.Info("originals checked", "checked", report.Checked, "problems", report.Total)
	return nil
}

func fileSHA256(path string) ([]byte, error) {
	file, err := os.Open(path) //nolint:gosec // From the database.
	if err != nil {
		return nil, err
	}
	defer func() { _ = file.Close() }()
	hash := sha256.New()
	if _, err := io.Copy(hash, file); err != nil {
		return nil, err
	}
	return hash.Sum(nil), nil
}

// CheckIntegrity looks at every original and saves what it found. It changes no file.
func CheckIntegrity(ctx context.Context, q *db.Queries, thorough bool) (*IntegrityReport, error) {
	report := &IntegrityReport{Thorough: thorough, Problems: []IntegrityProblem{}}
	found := func(row *db.ListOriginalsRow, problem string) {
		report.Total++
		if len(report.Problems) < integrityShown {
			report.Problems = append(report.Problems, IntegrityProblem{Name: row.OriginalName, Path: row.OriginalPath, Problem: problem})
		}
	}
	after := pgtype.UUID{Valid: true}
	for {
		rows, err := q.ListOriginals(ctx, db.ListOriginalsParams{ID: after, Limit: integrityBatch})
		if err != nil {
			return nil, err
		}
		if len(rows) == 0 {
			break
		}
		for i := range rows {
			row := &rows[i]
			after = row.ID
			report.Checked++
			if _, err := os.Stat(row.OriginalPath); err != nil {
				if errors.Is(err, fs.ErrNotExist) {
					found(row, "missing")
				} else {
					found(row, "unreadable")
				}
				continue
			}
			if !thorough || len(row.Checksum) == 0 {
				continue
			}
			sum, err := fileSHA256(row.OriginalPath)
			switch {
			case err != nil:
				found(row, "unreadable")
			case string(sum) != string(row.Checksum):
				found(row, "changed")
			}
		}
	}
	report.FinishedAt = time.Now()
	data, err := json.Marshal(report)
	if err != nil {
		return nil, err
	}
	return report, q.SetState(ctx, db.SetStateParams{Key: StateIntegrity, Value: string(data)})
}
