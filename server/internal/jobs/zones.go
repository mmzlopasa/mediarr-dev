package jobs

import (
	"log/slog"
	"sync"
	"time"

	"github.com/ringsaturn/tzf"
)

// The map of time zones is large, so it is loaded when it is needed and let go when it has not been
// for a while, to keep the server and worker small when nothing asks.
var zones struct {
	sync.Mutex
	finder tzf.F
	failed bool
	timer  *time.Timer
}

const zonesIdle = 5 * time.Minute

// WithZones runs fn with the map of time zones, or answers false when it cannot be loaded.
func WithZones(fn func(tzf.F)) bool {
	zones.Lock()
	defer zones.Unlock()
	if zones.finder == nil {
		if zones.failed {
			return false
		}
		finder, err := tzf.NewDefaultFinder()
		if err != nil {
			zones.failed = true
			slog.Warn("time zones by place are not available", "error", err)
			return false
		}
		zones.finder = finder
	}
	fn(zones.finder)
	if zones.timer != nil {
		zones.timer.Stop()
	}
	zones.timer = time.AfterFunc(zonesIdle, func() {
		zones.Lock()
		zones.finder = nil
		zones.timer = nil
		zones.Unlock()
	})
	return true
}

// ZoneFromPlace gives a time its zone from where it was taken. A time without a zone is the clock
// of the place read as UTC, so it moves by the offset; a video's time without a zone is UTC by its
// format, so only the zone is added.
func ZoneFromPlace(finder tzf.F, at time.Time, offset *int32, video bool, latitude, longitude float64) (time.Time, int32, bool) {
	wall := at
	if offset != nil {
		wall = at.Add(time.Duration(*offset) * time.Minute)
	} else if video {
		zone, ok := OffsetAt(finder, latitude, longitude, at)
		return at, zone, ok
	}
	// The offset of the place is found at about the right moment, then once more at the exact one,
	// which differs only around the change to and from summer time.
	guess, ok := OffsetAt(finder, latitude, longitude, wall)
	if !ok {
		return at, 0, false
	}
	instant := wall.Add(-time.Duration(guess) * time.Minute)
	zone, ok := OffsetAt(finder, latitude, longitude, instant)
	if !ok {
		return at, 0, false
	}
	return wall.Add(-time.Duration(zone) * time.Minute), zone, true
}
