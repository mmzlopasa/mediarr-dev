package app

import (
	"net/http"
	"path"
	"strings"

	"github.com/jackc/pgx/v5/pgtype"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/mmzlopasa/mediarr-app/server/db"
	"github.com/mmzlopasa/mediarr-app/server/internal/api"
	"github.com/mmzlopasa/mediarr-app/server/internal/jobs"
)

const maxFolderItems = 1000

func (s *apiServer) externalStatus(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	out := api.ExternalLibrary{Available: jobs.IsExternalAvailable(s.ExternalPath)}
	library, err := s.queries.GetExternalLibrary(ctx)
	if err != nil && !db.IsNotFound(err) {
		internalError(w, r, err)
		return
	}
	if err == nil {
		owner := openapi_types.UUID(library.UserID.Bytes)
		out.OwnerId = &owner
		counts, err := s.queries.ExternalLibraryCounts(ctx, library.ID)
		if err != nil {
			internalError(w, r, err)
			return
		}
		out.Assets, out.Missing = counts.Assets, counts.Missing
		out.Scanning = library.ScanStartedAt.Valid && !library.ScanFinishedAt.Valid
		out.ScanFinishedAt = optional(library.ScanFinishedAt.Time, library.ScanFinishedAt.Valid)
		out.ScanError = optional(library.ScanError.String, library.ScanError.Valid)
	}
	writeJSON(w, http.StatusOK, out)
}

func (s *apiServer) GetExternalLibrary(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	s.externalStatus(w, r)
}

func (s *apiServer) queueExternalScan(r *http.Request) error {
	_, err := s.Inserter.Insert(r.Context(), jobs.ExternalScanArgs{}, nil)
	return err
}

// SetExternalLibrary chooses whose photos the folder holds. It cannot change once they are imported,
// because every record, album and face belongs to that user.
func (s *apiServer) SetExternalLibrary(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	var body api.ExternalLibraryOwner
	if !readJSON(w, r, &body) {
		return
	}
	if !jobs.IsExternalAvailable(s.ExternalPath) {
		writeError(w, http.StatusConflict, "set EXTERNAL_LIBRARY_PATH in .env first")
		return
	}
	ctx := r.Context()
	library, err := s.queries.GetExternalLibrary(ctx)
	switch {
	case err == nil:
		counts, err := s.queries.ExternalLibraryCounts(ctx, library.ID)
		if err != nil {
			internalError(w, r, err)
			return
		}
		if counts.Assets > 0 && library.UserID != pgUUID(body.OwnerId) {
			writeError(w, http.StatusConflict, "the photos are already imported for another user")
			return
		}
		if err := s.queries.DeleteExternalLibrary(ctx); err != nil {
			internalError(w, r, err)
			return
		}
	case !db.IsNotFound(err):
		internalError(w, r, err)
		return
	}
	_, err = s.queries.CreateExternalLibrary(ctx, db.CreateExternalLibraryParams{
		UserID: pgUUID(body.OwnerId), Path: pgtype.Text{String: s.ExternalPath, Valid: true},
	})
	if err != nil {
		writeError(w, http.StatusBadRequest, "no such user")
		return
	}
	if err := s.queueExternalScan(r); err != nil {
		internalError(w, r, err)
		return
	}
	s.externalStatus(w, r)
}

func (s *apiServer) ScanExternalLibrary(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	if _, err := s.queries.GetExternalLibrary(r.Context()); db.IsNotFound(err) {
		writeError(w, http.StatusConflict, "choose whose photos these are first")
		return
	} else if err != nil {
		internalError(w, r, err)
		return
	}
	if err := s.queueExternalScan(r); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusAccepted)
}

func (s *apiServer) GetFolder(w http.ResponseWriter, r *http.Request, params api.GetFolderParams) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	ctx := r.Context()
	// Clean makes "../" harmless, and the query matches by prefix only, so it cannot leave the library.
	current := ""
	if params.Path != nil {
		current = strings.TrimPrefix(path.Clean("/"+*params.Path), "/")
	}
	out := api.Folder{Path: current, Folders: []api.FolderEntry{}, Items: []api.TimelineItem{}}
	library, err := s.queries.GetExternalLibrary(ctx)
	if db.IsNotFound(err) || (err == nil && library.UserID != user.ID) {
		writeJSON(w, http.StatusOK, out)
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	out.Available = true
	prefix := strings.TrimSuffix(library.Path.String, "/") + "/"
	if current != "" {
		prefix += current + "/"
	}
	children, err := s.queries.ListFolderChildren(ctx, db.ListFolderChildrenParams{Prefix: prefix, LibraryID: library.ID, UserID: user.ID})
	if err != nil {
		internalError(w, r, err)
		return
	}
	for i := range children {
		out.Folders = append(out.Folders, api.FolderEntry{
			Name: children[i].Name, Count: children[i].Count, CoverId: children[i].CoverID.Bytes,
		})
	}
	rows, err := s.queries.ListFolderItems(ctx, db.ListFolderItemsParams{Prefix: prefix, LibraryID: library.ID, UserID: user.ID, RowLimit: maxFolderItems})
	if err != nil {
		internalError(w, r, err)
		return
	}
	buckets := make([]db.TimelineBucketRow, len(rows))
	for i := range rows {
		buckets[i] = db.TimelineBucketRow(rows[i])
	}
	out.Items = timelineItems(buckets, user.ID)
	writeJSON(w, http.StatusOK, out)
}
