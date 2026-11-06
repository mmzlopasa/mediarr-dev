package app

import (
	"fmt"
	"math"
	"net/http"
	"net/url"
	"slices"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgtype"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
)

const (
	defaultMapStyleLight = "https://cdn.mediarr.app/maps/style-light.json"
	defaultMapStyleDark  = "https://cdn.mediarr.app/maps/style-dark.json"
	stateMapStyleLight   = "map_style_light"
	stateMapStyleDark    = "map_style_dark"
	dateLayout           = "2006-01-02"

	tripAwayKm     = 100.0
	tripMaxGap     = 3 * 24 * time.Hour
	tripMinPhotos  = 2
	maxTripPlaces  = 3
	homeCellDegree = 0.5
	earthRadiusKm  = 6371.0
)

// parseDay reads a day given as YYYY-MM-DD. Nothing given is no day; anything else is an error.
func parseDay(value *string) (*time.Time, error) {
	if value == nil || *value == "" {
		return nil, nil
	}
	day, err := time.Parse(time.DateOnly, *value)
	if err != nil {
		return nil, fmt.Errorf("a day must be written as YYYY-MM-DD, not %q", *value)
	}
	return &day, nil
}

// dateParam turns a day into the start of that day, or of the next one for an end that includes it.
func dateParam(day *time.Time, next bool) pgtype.Timestamp {
	if day == nil {
		return pgtype.Timestamp{}
	}
	start := time.Date(day.Year(), day.Month(), day.Day(), 0, 0, 0, 0, time.UTC)
	if next {
		start = start.AddDate(0, 0, 1)
	}
	return pgtype.Timestamp{Time: start, Valid: true}
}

func (s *apiServer) GetMapPoints(w http.ResponseWriter, r *http.Request, params api.GetMapPointsParams) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	from, err := parseDay(params.From)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	to, err := parseDay(params.To)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	rows, err := s.queries.MapPoints(r.Context(), db.MapPointsParams{
		FromAt: dateParam(from, false), ToAt: dateParam(to, true), UserID: user.ID,
	})
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := api.MapPoints{
		Ids:   make([]openapi_types.UUID, len(rows)),
		Kinds: make([]string, len(rows)),
		Lats:  make([]float64, len(rows)),
		Lons:  make([]float64, len(rows)),
	}
	for i := range rows {
		out.Ids[i] = rows[i].ID.Bytes
		out.Kinds[i] = rows[i].Kind
		out.Lats[i] = rows[i].Latitude
		out.Lons[i] = rows[i].Longitude
	}
	writeJSON(w, http.StatusOK, out)
}

// tripPoint is one located photo, oldest first.
type tripPoint struct {
	id       openapi_types.UUID
	at       time.Time
	lat, lon float64
	place    string
}

func distanceKm(lat1, lon1, lat2, lon2 float64) float64 {
	const toRadians = math.Pi / 180
	dLat := (lat2 - lat1) * toRadians
	dLon := (lon2 - lon1) * toRadians
	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1*toRadians)*math.Cos(lat2*toRadians)*math.Sin(dLon/2)*math.Sin(dLon/2)
	return 2 * earthRadiusKm * math.Asin(math.Min(1, math.Sqrt(a)))
}

// homeOf is the area with the most photos, which is taken as where the person lives.
func homeOf(points []tripPoint) (lat, lon float64) {
	type cell struct{ lat, lon int }
	counts := map[cell]int{}
	best, bestCount := cell{}, 0
	for i := range points {
		key := cell{int(math.Floor(points[i].lat / homeCellDegree)), int(math.Floor(points[i].lon / homeCellDegree))}
		counts[key]++
		if counts[key] > bestCount {
			best, bestCount = key, counts[key]
		}
	}
	return (float64(best.lat) + 0.5) * homeCellDegree, (float64(best.lon) + 0.5) * homeCellDegree
}

// findTrips groups photos far from home that follow each other within a few days. Newest first.
func findTrips(points []tripPoint) []api.Trip {
	trips := []api.Trip{}
	if len(points) == 0 {
		return trips
	}
	homeLat, homeLon := homeOf(points)
	var current []tripPoint
	flush := func() {
		if len(current) >= tripMinPhotos {
			trips = append(trips, toTrip(current))
		}
		current = nil
	}
	for i := range points {
		point := points[i]
		if distanceKm(homeLat, homeLon, point.lat, point.lon) < tripAwayKm {
			flush()
			continue
		}
		if len(current) > 0 && point.at.Sub(current[len(current)-1].at) > tripMaxGap {
			flush()
		}
		current = append(current, point)
	}
	flush()
	slices.Reverse(trips)
	return trips
}

func toTrip(points []tripPoint) api.Trip {
	counts := map[string]int{}
	order := []string{}
	var sumLat, sumLon float64
	for i := range points {
		sumLat += points[i].lat
		sumLon += points[i].lon
		place := points[i].place
		if place == "" {
			continue
		}
		if counts[place] == 0 {
			order = append(order, place)
		}
		counts[place]++
	}
	slices.SortStableFunc(order, func(a, b string) int { return counts[b] - counts[a] })
	if len(order) > maxTripPlaces {
		order = order[:maxTripPlaces]
	}
	count := float64(len(points))
	return api.Trip{
		From: points[0].at.Format(dateLayout), To: points[len(points)-1].at.Format(dateLayout),
		Count: len(points), CoverId: points[len(points)/2].id,
		Lat: sumLat / count, Lon: sumLon / count, Places: order,
	}
}

func (s *apiServer) GetMapTrips(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	rows, err := s.queries.MapPoints(r.Context(), db.MapPointsParams{UserID: user.ID})
	if err != nil {
		internalError(w, r, err)
		return
	}
	points := make([]tripPoint, len(rows))
	for i := range rows {
		row := &rows[i]
		place := row.City
		if place == "" {
			place = row.Country
		}
		points[i] = tripPoint{id: row.ID.Bytes, at: row.LocalAt.Time, lat: row.Latitude, lon: row.Longitude, place: place}
	}
	writeJSON(w, http.StatusOK, findTrips(points))
}

func (s *apiServer) mapStyle(r *http.Request) (api.MapStyle, error) {
	out := api.MapStyle{Light: defaultMapStyleLight, Dark: defaultMapStyleDark}
	for key, target := range map[string]*string{stateMapStyleLight: &out.Light, stateMapStyleDark: &out.Dark} {
		value, err := s.queries.GetState(r.Context(), key)
		if db.IsNotFound(err) {
			continue
		}
		if err != nil {
			return out, err
		}
		if value != "" {
			*target = value
		}
	}
	return out, nil
}

func (s *apiServer) GetMapStyle(w http.ResponseWriter, r *http.Request) {
	if requireUser(w, r) == nil {
		return
	}
	out, err := s.mapStyle(r)
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, out)
}

func validStyleAddress(value string) bool {
	if value == "" {
		return true
	}
	parsed, err := url.Parse(value)
	return err == nil && parsed.Host != "" && (parsed.Scheme == "http" || parsed.Scheme == "https")
}

func (s *apiServer) SetMapStyle(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	var body api.MapStyle
	if !readJSON(w, r, &body) {
		return
	}
	body.Light, body.Dark = strings.TrimSpace(body.Light), strings.TrimSpace(body.Dark)
	if !validStyleAddress(body.Light) || !validStyleAddress(body.Dark) {
		writeError(w, http.StatusBadRequest, "a style must be an http or https address")
		return
	}
	ctx := r.Context()
	if err := s.queries.SetState(ctx, db.SetStateParams{Key: stateMapStyleLight, Value: body.Light}); err != nil {
		internalError(w, r, err)
		return
	}
	if err := s.queries.SetState(ctx, db.SetStateParams{Key: stateMapStyleDark, Value: body.Dark}); err != nil {
		internalError(w, r, err)
		return
	}
	out, err := s.mapStyle(r)
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, out)
}
