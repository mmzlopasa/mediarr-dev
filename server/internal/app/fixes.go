package app

import (
	"context"
	"encoding/xml"
	"errors"
	"fmt"
	"math"
	"net/http"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/ringsaturn/tzf"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

const (
	fixShown         = 20
	maxFixIDs        = 1000
	maxShiftMinutes  = 100 * 366 * 24 * 60
	defaultNearMins  = 30
	maxNearMins      = 24 * 60
	trackReach       = 5 * time.Minute
	fromFileWords    = "from the file"
	locationFormat   = "%.5f, %.5f"
	errNothingToSend = "send between 1 and 1000 photos"
	// A GPX track of a long day, with its points every second.
	maxTrackBody = 25 << 20
)

// A change one photo is to get. Either a date, a location, nothing (clear), or back to its file.
type fix struct {
	id       pgtype.UUID
	name     string
	before   string
	after    string
	at       time.Time
	offset   int32
	lat, lon float64
	clear    bool
	useFile  bool
}

func localText(at time.Time, offset *int32) string {
	if offset == nil {
		return at.UTC().Format("2006-01-02T15:04:05")
	}
	return at.In(time.FixedZone("", int(*offset)*60)).Format(time.RFC3339)
}

func dateBefore(row *db.DateFactsRow) (time.Time, *int32) {
	at := row.CreatedAt.Time
	if row.TakenAt.Valid {
		at = row.TakenAt.Time
	}
	if row.TakenOffsetMinutes.Valid {
		offset := row.TakenOffsetMinutes.Int32
		return at, &offset
	}
	return at, nil
}

func locationText(row *db.DateFactsRow) string {
	if !row.Latitude.Valid || !row.Longitude.Valid {
		return ""
	}
	return fmt.Sprintf(locationFormat, row.Latitude.Float64, row.Longitude.Float64)
}

func fixIDs(ids []uuid.UUID) ([]pgtype.UUID, bool) {
	if len(ids) == 0 || len(ids) > maxFixIDs {
		return nil, false
	}
	out := make([]pgtype.UUID, len(ids))
	for i, id := range ids {
		out[i] = pgUUID(id)
	}
	return out, true
}

func fixResult(fixes []fix, skipped int) api.FixResult {
	out := api.FixResult{Changed: len(fixes), Skipped: skipped, Changes: []api.FixChange{}}
	for _, f := range fixes[:min(len(fixes), fixShown)] {
		out.Changes = append(out.Changes, api.FixChange{Id: f.id.Bytes, Name: f.name, Before: f.before, After: f.after})
	}
	return out
}

var errFixInput = errors.New("fix input")

// planDates works out what each photo's date becomes, without changing anything.
func planDates(rows []db.DateFactsRow, body *api.DateFix, now time.Time) ([]fix, int, error) {
	var out []fix
	skipped := 0
	switch body.Action {
	case api.DateFixActionShift:
		if body.Minutes == nil || *body.Minutes == 0 || abs(*body.Minutes) > maxShiftMinutes {
			return nil, 0, fmt.Errorf("%w: say how many minutes to shift, up to a hundred years", errFixInput)
		}
		for i := range rows {
			at, offset := dateBefore(&rows[i])
			after := at.Add(time.Duration(*body.Minutes) * time.Minute)
			if after.After(now) {
				skipped++
				continue
			}
			out = append(out, dated(&rows[i], at, offset, after, offset))
		}
	case api.DateFixActionSet:
		if body.TakenAt == nil {
			return nil, 0, fmt.Errorf("%w: say the date", errFixInput)
		}
		when, zone, ok := parseTakenAt(*body.TakenAt, now)
		if !ok {
			return nil, 0, fmt.Errorf("%w: the date must be a real moment, with its offset, and not in the future", errFixInput)
		}
		// A minute apart, so they keep their order.
		for i := range rows {
			at, offset := dateBefore(&rows[i])
			out = append(out, dated(&rows[i], at, offset, when.Add(time.Duration(i)*time.Minute), &zone))
		}
	case api.DateFixActionZoneFromPlace:
		loaded := jobs.WithZones(func(finder tzf.F) {
			for i := range rows {
				row := &rows[i]
				if !row.TakenAt.Valid || !row.Latitude.Valid || !row.Longitude.Valid {
					skipped++
					continue
				}
				at, offset := dateBefore(row)
				after, zone, ok := jobs.ZoneFromPlace(finder, at, offset, row.Kind == "video", row.Latitude.Float64, row.Longitude.Float64)
				if !ok {
					skipped++
					continue
				}
				if offset != nil && *offset == zone && after.Equal(at) {
					continue
				}
				out = append(out, dated(row, at, offset, after, &zone))
			}
		})
		if !loaded {
			return nil, 0, errors.New("time zones by place are not available on this server")
		}
	case api.DateFixActionTravel:
		if body.CameraZone == nil || body.PlaceZone == nil {
			return nil, 0, fmt.Errorf("%w: say the zone of the camera's clock and of the place", errFixInput)
		}
		camera, err := time.LoadLocation(*body.CameraZone)
		if err != nil {
			return nil, 0, fmt.Errorf("%w: %q is not a time zone", errFixInput, *body.CameraZone)
		}
		place, err := time.LoadLocation(*body.PlaceZone)
		if err != nil {
			return nil, 0, fmt.Errorf("%w: %q is not a time zone", errFixInput, *body.PlaceZone)
		}
		for i := range rows {
			at, offset := dateBefore(&rows[i])
			wall := at
			if offset != nil {
				wall = at.Add(time.Duration(*offset) * time.Minute)
			}
			// The camera's clock showed this hour at home, so this is the moment it was.
			instant := time.Date(wall.Year(), wall.Month(), wall.Day(), wall.Hour(), wall.Minute(), wall.Second(), wall.Nanosecond(), camera)
			_, seconds := instant.In(place).Zone()
			zone := int32(seconds / 60) //nolint:gosec // An offset in minutes fits.
			out = append(out, dated(&rows[i], at, offset, instant.UTC(), &zone))
		}
	case api.DateFixActionUseFile:
		for i := range rows {
			at, offset := dateBefore(&rows[i])
			out = append(out, fix{id: rows[i].ID, name: rows[i].OriginalName, before: localText(at, offset), after: fromFileWords, useFile: true})
		}
	default:
		return nil, 0, fmt.Errorf("%w: unknown action", errFixInput)
	}
	return out, skipped, nil
}

func dated(row *db.DateFactsRow, at time.Time, offset *int32, after time.Time, zone *int32) fix {
	f := fix{id: row.ID, name: row.OriginalName, before: localText(at, offset), after: localText(after, zone), at: after}
	if zone != nil {
		f.offset = *zone
	}
	return f
}

func abs(n int) int {
	if n < 0 {
		return -n
	}
	return n
}

// FixDates shifts, sets or zones the dates of many photos, after showing what would change.
func (s *apiServer) FixDates(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	var body api.DateFix
	if !readJSON(w, r, &body) {
		return
	}
	ids, ok := fixIDs(body.Ids)
	if !ok {
		writeError(w, http.StatusBadRequest, errNothingToSend)
		return
	}
	ctx := r.Context()
	rows, err := s.queries.DateFacts(ctx, db.DateFactsParams{UserID: user.ID, Ids: ids})
	if err != nil {
		internalError(w, r, err)
		return
	}
	fixes, skipped, err := planDates(rows, &body, time.Now())
	if errors.Is(err, errFixInput) {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err.Error())
		return
	}
	if body.DryRun == nil || !*body.DryRun {
		if err := s.applyFixes(ctx, fixes, true); err != nil {
			internalError(w, r, err)
			return
		}
	}
	writeJSON(w, http.StatusOK, fixResult(fixes, skipped))
}

// A point of a GPX track.
type trackPoint struct {
	at       time.Time
	lat, lon float64
}

// readTrack takes the points of a GPX file that have a time, in order.
func readTrack(text string) ([]trackPoint, error) {
	var doc struct {
		Points []struct {
			Lat  float64 `xml:"lat,attr"`
			Lon  float64 `xml:"lon,attr"`
			Time string  `xml:"time"`
		} `xml:"trk>trkseg>trkpt"`
	}
	if err := xml.NewDecoder(strings.NewReader(text)).Decode(&doc); err != nil {
		return nil, fmt.Errorf("%w: the track is not a GPX file", errFixInput)
	}
	out := make([]trackPoint, 0, len(doc.Points))
	for _, p := range doc.Points {
		at, err := time.Parse(time.RFC3339, strings.TrimSpace(p.Time))
		if err != nil || !validLocation(p.Lat, p.Lon) {
			continue
		}
		out = append(out, trackPoint{at: at, lat: p.Lat, lon: p.Lon})
	}
	if len(out) == 0 {
		return nil, fmt.Errorf("%w: the track has no points with a time", errFixInput)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].at.Before(out[j].at) })
	return out, nil
}

// onTrack is where the track was at a moment: between the two points around it, if both are near,
// else the nearest one if it is near.
func onTrack(points []trackPoint, at time.Time) (float64, float64, bool) {
	next := sort.Search(len(points), func(i int) bool { return !points[i].at.Before(at) })
	var before, after *trackPoint
	if next < len(points) {
		after = &points[next]
	}
	if next > 0 {
		before = &points[next-1]
	}
	near := func(p *trackPoint) bool { return p != nil && math.Abs(float64(p.at.Sub(at))) <= float64(trackReach) }
	switch {
	case near(before) && near(after) && after.at.After(before.at):
		share := float64(at.Sub(before.at)) / float64(after.at.Sub(before.at))
		return before.lat + (after.lat-before.lat)*share, before.lon + (after.lon-before.lon)*share, true
	case near(after):
		return after.lat, after.lon, true
	case near(before):
		return before.lat, before.lon, true
	}
	return 0, 0, false
}

func located(row *db.DateFactsRow, lat, lon float64) fix {
	return fix{
		id: row.ID, name: row.OriginalName, before: locationText(row),
		after: fmt.Sprintf(locationFormat, lat, lon), lat: lat, lon: lon,
	}
}

// FixLocations sets, takes away or finds the locations of many photos, after showing what changes.
func (s *apiServer) FixLocations(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	var body api.LocationFix
	if !readJSONUpTo(w, r, &body, maxTrackBody) {
		return
	}
	ids, ok := fixIDs(body.Ids)
	if !ok {
		writeError(w, http.StatusBadRequest, errNothingToSend)
		return
	}
	ctx := r.Context()
	rows, err := s.queries.DateFacts(ctx, db.DateFactsParams{UserID: user.ID, Ids: ids})
	if err != nil {
		internalError(w, r, err)
		return
	}
	var fixes []fix
	skipped := 0
	switch body.Action {
	case api.LocationFixActionSet:
		if body.Latitude == nil || body.Longitude == nil || !validLocation(*body.Latitude, *body.Longitude) {
			writeError(w, http.StatusBadRequest, "a location needs a latitude from -90 to 90 and a longitude from -180 to 180")
			return
		}
		for i := range rows {
			fixes = append(fixes, located(&rows[i], *body.Latitude, *body.Longitude))
		}
	case api.LocationFixActionClear:
		for i := range rows {
			if locationText(&rows[i]) == "" {
				continue
			}
			fixes = append(fixes, fix{id: rows[i].ID, name: rows[i].OriginalName, before: locationText(&rows[i]), clear: true})
		}
	case api.LocationFixActionFromNeighbours:
		minutes := defaultNearMins
		if body.Minutes != nil {
			minutes = *body.Minutes
		}
		if minutes < 1 || minutes > maxNearMins {
			writeError(w, http.StatusBadRequest, "nearby means from 1 minute to a day")
			return
		}
		for i := range rows {
			row := &rows[i]
			if locationText(row) != "" {
				continue
			}
			if !row.TakenAt.Valid {
				skipped++
				continue
			}
			near, err := s.queries.NearestLocated(ctx, db.NearestLocatedParams{
				UserID: user.ID, At: row.TakenAt, Minutes: int32(minutes), //nolint:gosec // Checked above.
			})
			if db.IsNotFound(err) {
				skipped++
				continue
			}
			if err != nil {
				internalError(w, r, err)
				return
			}
			fixes = append(fixes, located(row, near.Latitude, near.Longitude))
		}
	case api.LocationFixActionFromTrack:
		if body.Track == nil {
			writeError(w, http.StatusBadRequest, "send the GPX track")
			return
		}
		points, err := readTrack(*body.Track)
		if err != nil {
			writeError(w, http.StatusBadRequest, err.Error())
			return
		}
		for i := range rows {
			row := &rows[i]
			if locationText(row) != "" {
				continue
			}
			if !row.TakenAt.Valid {
				skipped++
				continue
			}
			lat, lon, ok := onTrack(points, row.TakenAt.Time)
			if !ok {
				skipped++
				continue
			}
			fixes = append(fixes, located(row, lat, lon))
		}
	case api.LocationFixActionUseFile:
		for i := range rows {
			fixes = append(fixes, fix{id: rows[i].ID, name: rows[i].OriginalName, before: locationText(&rows[i]), after: fromFileWords, useFile: true})
		}
	default:
		writeError(w, http.StatusBadRequest, "unknown action")
		return
	}
	if body.DryRun == nil || !*body.DryRun {
		if err := s.applyFixes(ctx, fixes, false); err != nil {
			internalError(w, r, err)
			return
		}
	}
	writeJSON(w, http.StatusOK, fixResult(fixes, skipped))
}

// applyFixes keeps each change beside the file's own facts, which stay as they were, and lets the
// copy kept for other programs follow.
func (s *apiServer) applyFixes(ctx context.Context, fixes []fix, dates bool) error {
	return pgx.BeginFunc(ctx, s.Pool, func(tx pgx.Tx) error {
		q := s.queries.WithTx(tx)
		for i := range fixes {
			f := &fixes[i]
			var err error
			switch {
			case f.useFile && dates:
				err = q.ClearManualDate(ctx, f.id)
			case f.useFile:
				err = q.ClearManualLocation(ctx, f.id)
			case dates:
				err = q.SetManualDate(ctx, db.SetManualDateParams{
					ID: f.id, ManualTakenAt: pgtype.Timestamptz{Time: f.at, Valid: true},
					ManualOffsetMinutes: pgtype.Int4{Int32: f.offset, Valid: true},
				})
			case f.clear:
				if err = q.SetManualNoLocation(ctx, f.id); err == nil {
					err = q.ClearExifLocation(ctx, f.id)
				}
			default:
				lat, lon := pgtype.Float8{Float64: f.lat, Valid: true}, pgtype.Float8{Float64: f.lon, Valid: true}
				if err = q.SetManualLocation(ctx, db.SetManualLocationParams{ID: f.id, ManualLatitude: lat, ManualLongitude: lon}); err == nil {
					if err = q.SetExifLocation(ctx, db.SetExifLocationParams{AssetID: f.id, Latitude: lat, Longitude: lon}); err == nil {
						err = q.GeocodeAsset(ctx, f.id)
					}
				}
			}
			if err != nil {
				return err
			}
			// What the file says is read again; what was set by hand still wins over it.
			if f.useFile {
				if _, err := s.Inserter.InsertTx(ctx, tx, jobs.MetadataArgs{AssetID: uuid.UUID(f.id.Bytes)}, nil); err != nil {
					return err
				}
				continue
			}
			if _, err := s.Inserter.InsertTx(ctx, tx, jobs.SidecarArgs{AssetID: uuid.UUID(f.id.Bytes)}, nil); err != nil {
				return err
			}
		}
		return nil
	})
}
