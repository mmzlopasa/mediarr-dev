package app

import (
	"errors"
	"net/http"
	"os"

	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/upgrade"
)

// ListUpgradeSnapshots shows what an upgrade can be undone to. Going back is a command, run while
// the server is stopped, so it is not here.
func (s *apiServer) ListUpgradeSnapshots(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	all, err := upgrade.List(s.LibraryPath)
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := make([]api.UpgradeSnapshot, 0, len(all))
	for _, snap := range all {
		out = append(out, api.UpgradeSnapshot{
			Name: snap.Name, FromVersion: snap.FromVersion, ToVersion: snap.ToVersion,
			FromSchema: snap.FromSchema, ToSchema: snap.ToSchema, CreatedAt: snap.CreatedAt, SizeBytes: snap.SizeBytes,
		})
	}
	writeJSON(w, http.StatusOK, out)
}

func (s *apiServer) DeleteUpgradeSnapshot(w http.ResponseWriter, r *http.Request, name string) {
	if requireAdmin(w, r) == nil {
		return
	}
	err := upgrade.Delete(s.LibraryPath, name)
	if errors.Is(err, os.ErrNotExist) {
		writeError(w, http.StatusNotFound, "snapshot not found")
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
