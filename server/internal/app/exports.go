package app

import (
	"context"
	"errors"
	"fmt"
	"mime"
	"net/http"
	"os"
	"syscall"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgtype"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

// exportHeadroom is left free on the cache disk besides the export itself.
const exportHeadroom = 1 << 30

// canDownloadExport says who may take the files of an export: its owner, and the administrator who
// started it for them. Other administrators follow and stop it, and do not get the photos.
func canDownloadExport(row *db.GetExportRow, user *db.User, admin bool) bool {
	return row.UserID == user.ID || (admin && row.CreatedBy == user.ID)
}

func (s *apiServer) exportToAPI(ctx context.Context, row *db.GetExportRow, user *db.User, admin bool) (api.LibraryExport, error) {
	parts, err := s.queries.ListExportParts(ctx, row.ID)
	if err != nil {
		return api.LibraryExport{}, err
	}
	out := api.LibraryExport{
		Id: row.ID.Bytes, UserId: row.UserID.Bytes, UserEmail: row.UserEmail, Status: api.LibraryExportStatus(row.Status),
		StartedByAdmin: row.CreatedBy.Valid && row.CreatedBy != row.UserID, StartedBy: row.StartedByName,
		TotalFiles: int(row.TotalFiles), TotalBytes: row.TotalBytes, DoneFiles: int(row.DoneFiles), DoneBytes: row.DoneBytes,
		Missing: int(row.Missing), LastError: row.LastError, CreatedAt: row.CreatedAt.Time,
		FinishedAt: optional(row.FinishedAt.Time, row.FinishedAt.Valid), ExpiresAt: optional(row.ExpiresAt.Time, row.ExpiresAt.Valid),
		Parts: make([]api.LibraryExportPart, 0, len(parts)), CanDownload: canDownloadExport(row, user, admin),
	}
	// Parts are offered once all of them are there.
	if row.Status == string(api.LibraryExportStatusDone) {
		for i := range parts {
			out.Parts = append(out.Parts, api.LibraryExportPart{Number: parts[i].Number, Size: parts[i].SizeBytes, Files: int(parts[i].Files)})
		}
	}
	return out, nil
}

func (s *apiServer) exportsByID(w http.ResponseWriter, r *http.Request, user *db.User, ids []pgtype.UUID) {
	out := make([]api.LibraryExport, 0, len(ids))
	for _, id := range ids {
		row, err := s.queries.GetExport(r.Context(), id)
		if err != nil {
			internalError(w, r, err)
			return
		}
		entry, err := s.exportToAPI(r.Context(), &row, user, actsAsAdmin(r, user))
		if err != nil {
			internalError(w, r, err)
			return
		}
		out = append(out, entry)
	}
	writeJSON(w, http.StatusOK, out)
}

func (s *apiServer) ListMyExports(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	ids, err := s.queries.ListUserExports(r.Context(), user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	s.exportsByID(w, r, user, ids)
}

func (s *apiServer) ListAllExports(w http.ResponseWriter, r *http.Request) {
	user := requireAdmin(w, r)
	if user == nil {
		return
	}
	ids, err := s.queries.ListAllExports(r.Context())
	if err != nil {
		internalError(w, r, err)
		return
	}
	s.exportsByID(w, r, user, ids)
}

func (s *apiServer) CreateExport(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	var body api.LibraryExportCreate
	if !readJSON(w, r, &body) {
		return
	}
	ctx := r.Context()
	owner := user.ID
	if body.UserId != nil && pgUUID(*body.UserId) != user.ID {
		if !actsAsAdmin(r, user) {
			writeError(w, http.StatusForbidden, "only an administrator exports someone else's library")
			return
		}
		owner = pgUUID(*body.UserId)
		if _, err := s.queries.GetUserByID(ctx, owner); db.IsNotFound(err) {
			writeError(w, http.StatusBadRequest, "no such user")
			return
		} else if err != nil {
			internalError(w, r, err)
			return
		}
	}
	estimate, err := s.queries.ExportEstimate(ctx, owner)
	if err != nil {
		internalError(w, r, err)
		return
	}
	if err := os.MkdirAll(s.CachePath, 0o750); err != nil {
		internalError(w, r, err)
		return
	}
	var disk syscall.Statfs_t
	if err := syscall.Statfs(s.CachePath, &disk); err != nil {
		internalError(w, r, err)
		return
	}
	free := int64(disk.Bavail) * disk.Bsize //nolint:gosec // Sizes of a real disk.
	if need := estimate.Bytes + exportHeadroom; free < need {
		writeError(w, http.StatusInsufficientStorage, fmt.Sprintf(
			"not enough free space for the export: it needs about %s in the cache folder, and %s is free",
			humanBytes(need), humanBytes(free)))
		return
	}
	var id pgtype.UUID
	err = pgx.BeginFunc(ctx, s.Pool, func(tx pgx.Tx) error {
		var err error
		if id, err = s.queries.WithTx(tx).CreateExport(ctx, db.CreateExportParams{UserID: owner, CreatedBy: user.ID}); err != nil {
			return err
		}
		_, err = s.Inserter.InsertTx(ctx, tx, jobs.ExportArgs{ExportID: id.Bytes}, nil)
		return err
	})
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) && pgErr.Code == "23505" {
		writeError(w, http.StatusConflict, "an export of this library is already running")
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	row, err := s.queries.GetExport(ctx, id)
	if err != nil {
		internalError(w, r, err)
		return
	}
	out, err := s.exportToAPI(ctx, &row, user, actsAsAdmin(r, user))
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusCreated, out)
}

// humanBytes says a size the way a person reads it.
func humanBytes(n int64) string {
	const unit = 1024
	if n < unit {
		return fmt.Sprintf("%d B", n)
	}
	value, suffix := float64(n), []string{"KB", "MB", "GB", "TB", "PB"}
	i := -1
	for value >= unit && i < len(suffix)-1 {
		value /= unit
		i++
	}
	return fmt.Sprintf("%.1f %s", value, suffix[i])
}

// ownExport finds an export its owner, or an administrator, may see. Anyone else gets a 404, as if
// it did not exist.
func (s *apiServer) ownExport(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) (*db.GetExportRow, *db.User) {
	user := requireUser(w, r)
	if user == nil {
		return nil, nil
	}
	row, err := s.queries.GetExport(r.Context(), pgUUID(id))
	if db.IsNotFound(err) || (err == nil && row.UserID != user.ID && !actsAsAdmin(r, user)) {
		writeError(w, http.StatusNotFound, "no such export")
		return nil, nil
	}
	if err != nil {
		internalError(w, r, err)
		return nil, nil
	}
	return &row, user
}

func (s *apiServer) GetExport(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	row, user := s.ownExport(w, r, id)
	if row == nil {
		return
	}
	out, err := s.exportToAPI(r.Context(), row, user, actsAsAdmin(r, user))
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, out)
}

func (s *apiServer) CancelExport(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	row, _ := s.ownExport(w, r, id)
	if row == nil {
		return
	}
	if _, err := s.queries.CancelExport(r.Context(), row.ID); db.IsNotFound(err) {
		writeError(w, http.StatusConflict, "this export is not running")
		return
	} else if err != nil {
		internalError(w, r, err)
		return
	}
	// The worker stops within seconds and removes what it wrote; this removes the finished parts now.
	_ = os.RemoveAll(jobs.ExportDir(s.CachePath, row.ID))
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) DeleteExport(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	row, _ := s.ownExport(w, r, id)
	if row == nil {
		return
	}
	if row.Status == string(api.LibraryExportStatusRunning) {
		writeError(w, http.StatusConflict, "cancel the export first")
		return
	}
	if err := os.RemoveAll(jobs.ExportDir(s.CachePath, row.ID)); err != nil {
		internalError(w, r, err)
		return
	}
	if err := s.queries.DeleteExport(r.Context(), row.ID); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) DownloadExportPart(w http.ResponseWriter, r *http.Request, id openapi_types.UUID, number int32) {
	row, user := s.ownExport(w, r, id)
	if row == nil {
		return
	}
	if !canDownloadExport(row, user, actsAsAdmin(r, user)) {
		writeError(w, http.StatusForbidden, "only the owner of the library, or the administrator who started the export, downloads it")
		return
	}
	if row.Status != string(api.LibraryExportStatusDone) {
		writeError(w, http.StatusNotFound, "this export has no parts to download")
		return
	}
	if _, err := s.queries.GetExportPart(r.Context(), db.GetExportPartParams{ExportID: row.ID, Number: number}); db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "no such part")
		return
	} else if err != nil {
		internalError(w, r, err)
		return
	}
	name := fmt.Sprintf("mediarr-export-%s-part-%03d.zip", row.CreatedAt.Time.Format("2006-01-02"), number)
	w.Header().Set("Content-Type", "application/zip")
	w.Header().Set("Content-Disposition", mime.FormatMediaType("attachment", map[string]string{"filename": name}))
	w.Header().Set("X-Content-Type-Options", "nosniff")
	w.Header().Set("Cache-Control", "private, no-cache")
	serveFile(w, r, jobs.ExportPartPath(s.CachePath, row.ID, number))
}
