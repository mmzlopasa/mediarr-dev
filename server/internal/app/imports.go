package app

import (
	"context"
	"errors"
	"net/http"
	"net/url"
	"os"
	"path"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

func importToAPI(row *db.ListImportsRow) api.ImportEntry {
	return api.ImportEntry{
		Id: row.ID.Bytes, UserEmail: row.UserEmail, Source: api.ImportEntrySource(row.Source), Status: api.ImportEntryStatus(row.Status),
		FromZip: row.FromZip, Total: int(row.Total),
		Added: int(row.Added), Skipped: int(row.Skipped), Failed: int(row.Failed), LastError: row.LastError,
		CreatedAt: row.CreatedAt.Time, FinishedAt: optional(row.FinishedAt.Time, row.FinishedAt.Valid),
	}
}

func (s *apiServer) ListImports(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	rows, err := s.queries.ListImports(r.Context())
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := make([]api.ImportEntry, len(rows))
	for i := range rows {
		out[i] = importToAPI(&rows[i])
	}
	writeJSON(w, http.StatusOK, out)
}

// CreateImport is for administrators, since the server then reaches the address it is given.
func (s *apiServer) CreateImport(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	var body api.ImportCreate
	if !readJSON(w, r, &body) {
		return
	}
	params := db.CreateImportParams{UserID: pgUUID(body.OwnerId), Source: string(body.Source)}
	switch body.Source {
	case api.ImportCreateSourceImmich:
		address, key := "", ""
		if body.Address != nil {
			address = strings.TrimSpace(*body.Address)
		}
		if body.ApiKey != nil {
			key = strings.TrimSpace(*body.ApiKey)
		}
		parsed, err := url.Parse(address)
		if err != nil || parsed.Host == "" || (parsed.Scheme != "http" && parsed.Scheme != "https") || key == "" {
			writeError(w, http.StatusBadRequest, "enter the address of the Immich server and an API key")
			return
		}
		params.Address, params.Secret = strings.TrimRight(address, "/"), key
	case api.ImportCreateSourceTakeout, api.ImportCreateSourceIcloud:
		if body.Folder == nil || strings.TrimSpace(*body.Folder) == "" {
			writeError(w, http.StatusBadRequest, "enter a folder inside the external library's mount")
			return
		}
		// Clean makes "../" harmless: the result is always inside the mount.
		params.Folder = strings.TrimPrefix(path.Clean("/"+strings.TrimSpace(*body.Folder)), "/")
	default:
		writeError(w, http.StatusBadRequest, "unknown source")
		return
	}
	ctx := r.Context()
	if _, err := s.queries.GetUserByID(ctx, params.UserID); db.IsNotFound(err) {
		writeError(w, http.StatusBadRequest, "no such user")
		return
	} else if err != nil {
		internalError(w, r, err)
		return
	}
	var id pgtype.UUID
	err := pgx.BeginFunc(ctx, s.Pool, func(tx pgx.Tx) error {
		var err error
		if id, err = s.queries.WithTx(tx).CreateImport(ctx, params); err != nil {
			return err
		}
		_, err = s.Inserter.InsertTx(ctx, tx, jobs.ImportArgs{ImportID: id.Bytes}, nil)
		return err
	})
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusCreated, map[string]openapi_types.UUID{"id": id.Bytes})
}

func (s *apiServer) CancelImport(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	if requireAdmin(w, r) == nil {
		return
	}
	if _, err := s.queries.StopImport(r.Context(), pgUUID(id)); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// --- Anyone's own imports, from the ZIP files of a Google Takeout or iCloud export ---

func (s *apiServer) userImport(ctx context.Context, row *db.Import) (api.UserImport, error) {
	parts, err := s.queries.ListImportParts(ctx, row.ID)
	if err != nil {
		return api.UserImport{}, err
	}
	out := api.UserImport{
		Id: row.ID.Bytes, Source: api.UserImportSource(row.Source), Status: api.UserImportStatus(row.Status), FromZip: row.FromZip,
		Parts: make([]api.ImportPart, len(parts)), Total: int(row.Total),
		Added: int(row.Added), Skipped: int(row.Skipped), Failed: int(row.Failed), LastError: row.LastError,
		CreatedAt: row.CreatedAt.Time, FinishedAt: optional(row.FinishedAt.Time, row.FinishedAt.Valid),
	}
	for n := range parts {
		out.Parts[n] = api.ImportPart{Id: parts[n].ID.Bytes, Name: parts[n].Name, Size: parts[n].SizeBytes}
	}
	return out, nil
}

// ownImport finds an import its owner, or an administrator, may see. Anyone else gets a 404, as if
// it did not exist.
func (s *apiServer) ownImport(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) (*db.Import, *db.User) {
	user := requireUser(w, r)
	if user == nil {
		return nil, nil
	}
	row, err := s.queries.GetImport(r.Context(), pgUUID(id))
	if db.IsNotFound(err) || (err == nil && row.UserID != user.ID && !actsAsAdmin(r, user)) {
		writeError(w, http.StatusNotFound, "no such import")
		return nil, nil
	}
	if err != nil {
		internalError(w, r, err)
		return nil, nil
	}
	return &row, user
}

func (s *apiServer) ListMyImports(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	rows, err := s.queries.ListUserImports(r.Context(), user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := make([]api.UserImport, 0, len(rows))
	for n := range rows {
		entry, err := s.userImport(r.Context(), &rows[n])
		if err != nil {
			internalError(w, r, err)
			return
		}
		out = append(out, entry)
	}
	writeJSON(w, http.StatusOK, out)
}

func (s *apiServer) CreateMyImport(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	var body api.UserImportCreate
	if !readJSON(w, r, &body) {
		return
	}
	if !body.Source.Valid() {
		writeError(w, http.StatusBadRequest, "choose Google Takeout or iCloud")
		return
	}
	id, err := s.queries.CreateZipImport(r.Context(), db.CreateZipImportParams{UserID: user.ID, Source: string(body.Source)})
	if err != nil {
		internalError(w, r, err)
		return
	}
	row, err := s.queries.GetImport(r.Context(), id)
	if err != nil {
		internalError(w, r, err)
		return
	}
	out, err := s.userImport(r.Context(), &row)
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusCreated, out)
}

func (s *apiServer) GetImport(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	row, _ := s.ownImport(w, r, id)
	if row == nil {
		return
	}
	ctx := r.Context()
	entry, err := s.userImport(ctx, row)
	if err != nil {
		internalError(w, r, err)
		return
	}
	owner, err := s.queries.GetUserByID(ctx, row.UserID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	problems, err := s.queries.ListImportProblems(ctx, row.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := api.ImportDetail{
		Id: entry.Id, Source: api.ImportDetailSource(entry.Source), Status: api.ImportDetailStatus(entry.Status), FromZip: entry.FromZip,
		Parts: entry.Parts, Total: entry.Total, Added: entry.Added, Skipped: entry.Skipped, Failed: entry.Failed,
		LastError: entry.LastError, CreatedAt: entry.CreatedAt, FinishedAt: entry.FinishedAt,
		UserEmail: owner.Email, Problems: make([]api.ImportProblem, len(problems)),
	}
	for n := range problems {
		out.Problems[n] = api.ImportProblem{Name: problems[n].Name, Reason: problems[n].Reason}
	}
	writeJSON(w, http.StatusOK, out)
}

func (s *apiServer) StartImport(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	row, _ := s.ownImport(w, r, id)
	if row == nil {
		return
	}
	ctx := r.Context()
	if row.FromZip {
		parts, err := s.queries.ListImportParts(ctx, row.ID)
		if err != nil {
			internalError(w, r, err)
			return
		}
		if len(parts) == 0 {
			writeError(w, http.StatusConflict, "upload the ZIP files first")
			return
		}
	}
	err := pgx.BeginFunc(ctx, s.Pool, func(tx pgx.Tx) error {
		started, err := s.queries.WithTx(tx).StartImport(ctx, row.ID)
		if err != nil {
			return err
		}
		if started == 0 {
			return errImportNotStartable
		}
		_, err = s.Inserter.InsertTx(ctx, tx, jobs.ImportArgs{ImportID: row.ID.Bytes}, nil)
		return err
	})
	if errors.Is(err, errImportNotStartable) {
		writeError(w, http.StatusConflict, "this import is running or finished")
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

var errImportNotStartable = errors.New("not startable")

func (s *apiServer) StopImport(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	row, _ := s.ownImport(w, r, id)
	if row == nil {
		return
	}
	if _, err := s.queries.StopImport(r.Context(), row.ID); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) DeleteImport(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	row, _ := s.ownImport(w, r, id)
	if row == nil {
		return
	}
	if row.Status == "running" {
		writeError(w, http.StatusConflict, "stop the import first")
		return
	}
	if err := os.RemoveAll(jobs.ImportPartsDir(s.LibraryPath, row.ID)); err != nil {
		internalError(w, r, err)
		return
	}
	if err := s.queries.DeleteImport(r.Context(), row.ID); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
