package app

import (
	"encoding/json"
	"net/http"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

func (s *apiServer) GetIntegrity(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	raw, err := s.queries.GetState(r.Context(), jobs.StateIntegrity)
	if db.IsNotFound(err) {
		writeJSON(w, http.StatusOK, api.IntegrityReport{Problems: []api.IntegrityProblem{}})
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	var report api.IntegrityReport
	if err := json.Unmarshal([]byte(raw), &report); err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, report)
}

func (s *apiServer) RunIntegrity(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	var body api.IntegrityRun
	if !readJSON(w, r, &body) {
		return
	}
	if _, err := s.Inserter.Insert(r.Context(), jobs.IntegrityArgs{Thorough: body.Thorough}, nil); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusAccepted)
}
