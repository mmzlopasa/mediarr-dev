package app

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"path/filepath"
	"strings"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
	"github.com/mediarr-app/mediarr/server/internal/storage"
)

const (
	// The layout originals have always had, shown when no template is chosen.
	defaultStorageLayout = "{{y}}/{{MM}}/{{hash}}-{{filename}}.{{ext}}"
	storagePreviews      = 6
)

func (s *apiServer) storageTemplate(ctx context.Context) (api.StorageTemplate, error) {
	template, err := jobs.LoadStorageTemplate(ctx, s.queries)
	if err != nil {
		return api.StorageTemplate{}, err
	}
	out := api.StorageTemplate{Template: template, DefaultLayout: defaultStorageLayout, Tokens: []api.StorageToken{}}
	for _, token := range storage.TemplateTokens {
		out.Tokens = append(out.Tokens, api.StorageToken{Token: token.Token, Means: token.Means})
	}
	raw, err := s.state(ctx, jobs.StateStorageReport)
	if err != nil {
		return out, err
	}
	if raw != "" {
		var report api.StorageReport
		if json.Unmarshal([]byte(raw), &report) == nil {
			out.Report = &report
		}
	}
	return out, nil
}

func (s *apiServer) GetStorageTemplate(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	out, err := s.storageTemplate(r.Context())
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, out)
}

// SetStorageTemplate keeps the template for new originals. The ones already here stay where they
// are until an administrator asks, after a dry run.
func (s *apiServer) SetStorageTemplate(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	var body api.StorageTemplateChange
	if !readJSON(w, r, &body) {
		return
	}
	template := strings.TrimSpace(body.Template)
	if err := storage.ValidateTemplate(template); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	ctx := r.Context()
	if err := s.queries.SetState(ctx, db.SetStateParams{Key: jobs.StateStorageTemplate, Value: template}); err != nil {
		internalError(w, r, err)
		return
	}
	out, err := s.storageTemplate(ctx)
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, out)
}

// PreviewStorageTemplate shows where a template would put a few real originals.
func (s *apiServer) PreviewStorageTemplate(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	var body api.StorageTemplateChange
	if !readJSON(w, r, &body) {
		return
	}
	template := strings.TrimSpace(body.Template)
	if template == "" {
		template = defaultStorageLayout
	}
	if err := storage.ValidateTemplate(template); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	ctx := r.Context()
	ids, err := s.queries.RecentUploadAssets(ctx, storagePreviews)
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := []api.StoragePreview{}
	for _, id := range ids {
		from, to, _, err := jobs.StorageTarget(ctx, s.queries, s.LibraryPath, template, id)
		if err != nil || to == "" {
			continue
		}
		// Shown inside the owner's folder, which is always the first part.
		rel, err := filepath.Rel(s.LibraryPath, to)
		if err != nil {
			continue
		}
		parts := strings.SplitN(filepath.ToSlash(rel), "/", 2)
		if len(parts) != 2 {
			continue
		}
		out = append(out, api.StoragePreview{Name: filepath.Base(from), Path: parts[1]})
	}
	writeJSON(w, http.StatusOK, out)
}

var errNoTemplate = errors.New("choose a template first")

// ApplyStorageTemplate starts putting the originals already here where the template says, or with
// dryRun only says what would move. The report is in GET /api/admin/storage-template.
func (s *apiServer) ApplyStorageTemplate(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	var body api.StorageApply
	if !readJSON(w, r, &body) {
		return
	}
	ctx := r.Context()
	template, err := jobs.LoadStorageTemplate(ctx, s.queries)
	if err != nil {
		internalError(w, r, err)
		return
	}
	if template == "" {
		writeError(w, http.StatusBadRequest, errNoTemplate.Error())
		return
	}
	if _, err := s.Inserter.Insert(ctx, jobs.StorageApplyArgs{DryRun: body.DryRun}, nil); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusAccepted)
}
