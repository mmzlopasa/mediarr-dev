package app

import (
	"context"
	"net/http"
	"slices"
	"strconv"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/mmzlopasa/mediarr-app/server/db"
	"github.com/mmzlopasa/mediarr-app/server/internal/api"
	"github.com/mmzlopasa/mediarr-app/server/internal/auth"
	"github.com/mmzlopasa/mediarr-app/server/internal/jobs"
)

// features are the additions an administrator turns on. All are off until then.
var features = []string{jobs.FeatureBackup, featureFilters, featureDocuments, featureFamily, "webhooks", featureKiosk, jobs.FeatureDescriptions}

const (
	featureFilters   = "filters"
	featureDocuments = "documents"
	featureKiosk     = "kiosk"
)

func (s *apiServer) featureOn(ctx context.Context, name string) (bool, error) {
	value, err := s.state(ctx, jobs.StateFeaturePrefix+name)
	return value == "1", err
}

func (s *apiServer) GetFeatures(w http.ResponseWriter, r *http.Request) {
	if requireUser(w, r) == nil {
		return
	}
	out := api.Features{}
	for _, name := range features {
		on, err := s.featureOn(r.Context(), name)
		if err != nil {
			internalError(w, r, err)
			return
		}
		out[name] = on
	}
	writeJSON(w, http.StatusOK, out)
}

func (s *apiServer) SetFeature(w http.ResponseWriter, r *http.Request, name string) {
	if requireAdmin(w, r) == nil {
		return
	}
	if !slices.Contains(features, name) {
		writeError(w, http.StatusNotFound, "no such feature")
		return
	}
	var body api.FeatureUpdate
	if !readJSON(w, r, &body) {
		return
	}
	value := "0"
	if body.Enabled {
		value = "1"
	}
	if err := s.queries.SetState(r.Context(), db.SetStateParams{Key: jobs.StateFeaturePrefix + name, Value: value}); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) backupToAPI(ctx context.Context) (api.BackupSettings, error) {
	var out api.BackupSettings
	settings, err := jobs.LoadBackupSettings(ctx, s.queries)
	if err != nil {
		return out, err
	}
	hour, err := s.state(ctx, jobs.StateBackupHour)
	if err != nil {
		return out, err
	}
	parsed := 3
	if value, err := strconv.Atoi(hour); err == nil {
		parsed = value
	}
	return api.BackupSettings{
		Repository: settings.Repository, Hour: parsed, HasPassword: settings.Password != "", HasS3Key: settings.S3Key != "",
		LocalFolder: s.BackupPath,
	}, nil
}

func (s *apiServer) GetBackupSettings(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	out, err := s.backupToAPI(r.Context())
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, out)
}

func (s *apiServer) SetBackupSettings(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	var body api.BackupSettingsUpdate
	if !readJSON(w, r, &body) {
		return
	}
	repository := strings.TrimSpace(body.Repository)
	if repository != "" {
		if err := jobs.ValidRepository(repository, s.BackupPath); err != nil {
			writeError(w, http.StatusBadRequest, err.Error())
			return
		}
	}
	if body.Hour < 0 || body.Hour > 23 {
		writeError(w, http.StatusBadRequest, "the hour must be between 0 and 23")
		return
	}
	values := map[string]string{jobs.StateBackupRepository: repository, jobs.StateBackupHour: strconv.Itoa(body.Hour)}
	if body.Password != nil {
		if len(*body.Password) < auth.MinPasswordLength {
			writeError(w, http.StatusBadRequest, "the backup's password must have at least 12 characters")
			return
		}
		values[jobs.StateBackupPassword] = *body.Password
	}
	if body.S3Key != nil {
		values[jobs.StateBackupS3Key] = *body.S3Key
	}
	if body.S3Secret != nil {
		values[jobs.StateBackupS3Secret] = *body.S3Secret
	}
	// Without a destination the secrets have no use, and should not stay behind.
	if repository == "" {
		values[jobs.StateBackupPassword], values[jobs.StateBackupS3Key], values[jobs.StateBackupS3Secret] = "", "", ""
	}
	ctx := r.Context()
	for key, value := range values {
		if err := s.queries.SetState(ctx, db.SetStateParams{Key: key, Value: value}); err != nil {
			internalError(w, r, err)
			return
		}
	}
	out, err := s.backupToAPI(ctx)
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, out)
}

func (s *apiServer) StartBackupRun(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	var body api.BackupRunRequest
	if !readJSON(w, r, &body) {
		return
	}
	ctx := r.Context()
	settings, err := jobs.LoadBackupSettings(ctx, s.queries)
	if err != nil {
		internalError(w, r, err)
		return
	}
	if settings.Repository == "" || settings.Password == "" {
		writeError(w, http.StatusConflict, "set where the backup goes and its password first")
		return
	}
	var run pgtype.UUID
	err = pgx.BeginFunc(ctx, s.Pool, func(tx pgx.Tx) error {
		var err error
		if run, err = s.queries.WithTx(tx).CreateBackupRun(ctx, string(body.Kind)); err != nil {
			return err
		}
		_, err = s.Inserter.InsertTx(ctx, tx, jobs.BackupArgs{What: string(body.Kind), Run: run.Bytes}, nil)
		return err
	})
	if err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusAccepted)
}

func (s *apiServer) ListBackupRuns(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	rows, err := s.queries.ListBackupRuns(r.Context())
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := make([]api.BackupRun, len(rows))
	for i := range rows {
		row := &rows[i]
		out[i] = api.BackupRun{
			Id: row.ID.Bytes, Kind: api.BackupRunKind(row.Kind), Status: api.BackupRunStatus(row.Status), Message: row.Message,
			Files: row.Files, StartedAt: row.StartedAt.Time, FinishedAt: optional(row.FinishedAt.Time, row.FinishedAt.Valid),
		}
	}
	writeJSON(w, http.StatusOK, out)
}
