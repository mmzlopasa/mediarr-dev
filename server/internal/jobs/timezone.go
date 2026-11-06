package jobs

import (
	"log/slog"
	"time"
	_ "time/tzdata" // Zones by name, whether or not the system has them.

	"github.com/ringsaturn/tzf"
)

// placeInTime works out the time zone of a photo from where it was taken, when its source gave the
// moment but not the zone, as Google does. Without it, a photo taken at seven in the evening by the
// sea would show the hour in UTC.
func (i *importRun) placeInTime(item *importItem) {
	if item.offset != nil || item.takenAt == nil || item.latitude == nil || item.longitude == nil {
		return
	}
	if i.zones == nil {
		if i.zonesFailed {
			return
		}
		// Loaded only for an import that needs it, and dropped with it, to keep the worker small.
		finder, err := tzf.NewDefaultFinder()
		if err != nil {
			i.zonesFailed = true
			slog.Warn("time zones by place are not available", "error", err)
			return
		}
		i.zones = finder
	}
	if offset, ok := OffsetAt(i.zones, *item.latitude, *item.longitude, *item.takenAt); ok {
		item.offset = &offset
	}
}

// OffsetAt is the offset from UTC, in minutes, at a place and moment, summer time included.
func OffsetAt(finder tzf.F, latitude, longitude float64, when time.Time) (int32, bool) {
	name := finder.GetTimezoneName(longitude, latitude)
	if name == "" {
		return 0, false
	}
	zone, err := time.LoadLocation(name)
	if err != nil {
		return 0, false
	}
	_, seconds := when.In(zone).Zone()
	return int32(seconds / 60), true //nolint:gosec // An offset in minutes fits.
}
