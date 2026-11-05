package app

import (
	"mime"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

const (
	maxCaption     = 2000
	minPlaceSearch = 2
	earliestPhoto  = 1800
)

// parseTakenAt reads a moment together with its offset, which says what day it was where it was taken.
func parseTakenAt(text string, now time.Time) (time.Time, int32, bool) {
	when, err := time.Parse(time.RFC3339, text)
	if err != nil || when.Year() < earliestPhoto || when.After(now.Add(24*time.Hour)) {
		return time.Time{}, 0, false
	}
	_, offset := when.Zone()
	return when, int32(offset / 60), true //nolint:gosec // A time zone's offset is small.
}

func validLocation(latitude, longitude float64) bool {
	return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180
}

// SetAssetFacts changes what is known about a photo, never its file.
func (s *apiServer) SetAssetFacts(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	ctx := r.Context()
	asset, err := s.queries.GetAsset(ctx, pgUUID(id))
	if db.IsNotFound(err) || (err == nil && asset.UserID != user.ID) {
		writeError(w, http.StatusNotFound, "no such asset")
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	var body api.AssetFacts
	if !readJSON(w, r, &body) {
		return
	}
	var (
		when   time.Time
		offset int32
	)
	if body.TakenAt != nil {
		var valid bool
		if when, offset, valid = parseTakenAt(*body.TakenAt, time.Now()); !valid {
			writeError(w, http.StatusBadRequest, "the date must be a real moment, with its offset, and not in the future")
			return
		}
	}
	if (body.Latitude == nil) != (body.Longitude == nil) ||
		(body.Latitude != nil && !validLocation(*body.Latitude, *body.Longitude)) {
		writeError(w, http.StatusBadRequest, "a location needs a latitude from -90 to 90 and a longitude from -180 to 180")
		return
	}
	if body.Rating != nil && (*body.Rating < 0 || *body.Rating > 5) {
		writeError(w, http.StatusBadRequest, "a rating is from 0 to 5 stars")
		return
	}
	if body.Caption != nil && len([]rune(*body.Caption)) > maxCaption {
		writeError(w, http.StatusBadRequest, "the description is too long")
		return
	}
	err = pgx.BeginFunc(ctx, s.Pool, func(tx pgx.Tx) error {
		q := s.queries.WithTx(tx)
		// The copy of what Mediarr knows, for other programs, follows each change.
		if _, err := s.Inserter.InsertTx(ctx, tx, jobs.SidecarArgs{AssetID: uuid.UUID(asset.ID.Bytes)}, nil); err != nil {
			return err
		}
		if body.Rating != nil {
			if err := q.SetOwnerRating(ctx, db.SetOwnerRatingParams{ID: asset.ID, Rating: int16(*body.Rating)}); err != nil { //nolint:gosec // Checked above.
				return err
			}
		}
		if body.Caption != nil {
			if err := q.SetAssetCaption(ctx, db.SetAssetCaptionParams{ID: asset.ID, Caption: strings.TrimSpace(*body.Caption)}); err != nil {
				return err
			}
		}
		if body.UseFile != nil && *body.UseFile {
			if err := q.ClearManualFacts(ctx, asset.ID); err != nil {
				return err
			}
			_, err := s.Inserter.InsertTx(ctx, tx, jobs.MetadataArgs{AssetID: uuid.UUID(asset.ID.Bytes)}, nil)
			return err
		}
		if body.TakenAt != nil {
			if err := q.SetManualDate(ctx, db.SetManualDateParams{
				ID: asset.ID, ManualTakenAt: pgtype.Timestamptz{Time: when, Valid: true}, ManualOffsetMinutes: pgtype.Int4{Int32: offset, Valid: true},
			}); err != nil {
				return err
			}
		}
		if body.Latitude != nil {
			latitude := pgtype.Float8{Float64: *body.Latitude, Valid: true}
			longitude := pgtype.Float8{Float64: *body.Longitude, Valid: true}
			if err := q.SetManualLocation(ctx, db.SetManualLocationParams{ID: asset.ID, ManualLatitude: latitude, ManualLongitude: longitude}); err != nil {
				return err
			}
			if err := q.SetExifLocation(ctx, db.SetExifLocationParams{AssetID: asset.ID, Latitude: latitude, Longitude: longitude}); err != nil {
				return err
			}
			return q.GeocodeAsset(ctx, asset.ID)
		}
		return nil
	})
	if err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// GetAssetSidecar gives an XMP file with what the file says and what Mediarr knows, for programs
// such as Lightroom or darktable. It is made fresh, so it holds the newest names and tags.
func (s *apiServer) GetAssetSidecar(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	ctx := r.Context()
	asset, err := s.queries.GetAsset(ctx, pgUUID(id))
	if db.IsNotFound(err) || (err == nil && asset.UserID != user.ID) {
		writeError(w, http.StatusNotFound, "no such asset")
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	facts, err := jobs.LoadSidecarFacts(ctx, s.queries, &asset)
	if err != nil {
		internalError(w, r, err)
		return
	}
	dir, err := os.MkdirTemp("", "mediarr-xmp-")
	if err != nil {
		internalError(w, r, err)
		return
	}
	defer func() { _ = os.RemoveAll(dir) }()
	path := filepath.Join(dir, "sidecar.xmp")
	if _, err := jobs.WriteSidecarWithFacts(ctx, asset.OriginalPath, path, facts); err != nil {
		internalError(w, r, err)
		return
	}
	w.Header().Set("Content-Type", "application/rdf+xml")
	w.Header().Set("Content-Disposition", mime.FormatMediaType("attachment", map[string]string{"filename": asset.OriginalName + ".xmp"}))
	w.Header().Set("X-Content-Type-Options", "nosniff")
	serveFile(w, r, path)
}

// SearchPlaces finds a place by the start of its name, to set a location without knowing coordinates.
func (s *apiServer) SearchPlaces(w http.ResponseWriter, r *http.Request, params api.SearchPlacesParams) {
	if requireUser(w, r) == nil {
		return
	}
	places := []api.Place{}
	text := strings.NewReplacer(`\`, `\\`, "%", `\%`, "_", `\_`).Replace(strings.TrimSpace(params.Q))
	if len([]rune(text)) >= minPlaceSearch {
		rows, err := s.queries.SearchPlaces(r.Context(), text)
		if err != nil {
			internalError(w, r, err)
			return
		}
		for i := range rows {
			row := &rows[i]
			places = append(places, api.Place{Name: row.Name, State: row.State, Country: row.Country, Latitude: row.Lat, Longitude: row.Lon})
		}
	}
	writeJSON(w, http.StatusOK, api.PlaceList{Places: places})
}
