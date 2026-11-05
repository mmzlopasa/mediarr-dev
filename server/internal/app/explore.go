package app

import (
	"net/http"

	"github.com/mediarr-app/mediarr/server/internal/api"
)

// ListExplorePlaces gives the places in the user's own photos, those with the most first.
func (s *apiServer) ListExplorePlaces(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	rows, err := s.queries.ListPlacesOfUser(r.Context(), user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	places := make([]api.ExplorePlace, len(rows))
	for i := range rows {
		row := &rows[i]
		places[i] = api.ExplorePlace{Name: row.Name, Country: row.Country, AssetCount: row.AssetCount, CoverId: row.CoverID.Bytes}
	}
	writeJSON(w, http.StatusOK, api.ExplorePlaces{Places: places})
}
