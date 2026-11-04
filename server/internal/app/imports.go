package app

import (
	"net/http"
	"net/url"
	"path"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/mmzlopasa/mediarr-app/server/db"
	"github.com/mmzlopasa/mediarr-app/server/internal/api"
	"github.com/mmzlopasa/mediarr-app/server/internal/jobs"
)

func importToAPI(row *db.ListImportsRow) api.ImportEntry {
	return api.ImportEntry{
		Id: row.ID.Bytes, UserEmail: row.UserEmail, Source: api.ImportEntrySource(row.Source), Status: api.ImportEntryStatus(row.Status),
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
	if err := s.queries.FinishImport(r.Context(), db.FinishImportParams{ID: pgUUID(id), Status: "cancelled", Column3: ""}); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
