package jobs

import (
	"testing"
	"time"
)

func TestScanIsDueFollowsTheInterval(t *testing.T) {
	now := time.Date(2026, 1, 2, 12, 0, 0, 0, time.UTC)
	if scanIsDue(now.Add(-5*time.Hour), 6, now) {
		t.Fatal("scanned too soon")
	}
	if !scanIsDue(now.Add(-6*time.Hour), 6, now) {
		t.Fatal("the interval passed and no scan")
	}
}
