package auth

import (
	"testing"
	"time"
)

func TestEachLockoutLastsTwiceAsLongUpToTheCeiling(t *testing.T) {
	now := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)
	l := NewLockout(3, 15*time.Minute, time.Hour)
	l.now = func() time.Time { return now }
	failAll := func() {
		t.Helper()
		for i := range 3 {
			if !l.Allowed("a") {
				t.Fatalf("attempt %d refused", i+1)
			}
			l.Fail("a")
		}
		if l.Allowed("a") {
			t.Fatal("still allowed after the limit")
		}
	}
	for _, wait := range []time.Duration{15 * time.Minute, 30 * time.Minute, time.Hour, time.Hour} {
		failAll()
		now = now.Add(wait - time.Second)
		if l.Allowed("a") {
			t.Fatalf("allowed before %s passed", wait)
		}
		now = now.Add(time.Second)
		if !l.Allowed("a") {
			t.Fatalf("still locked after %s", wait)
		}
	}
	if !l.Allowed("b") {
		t.Error("another key was locked too")
	}
}

func TestASuccessOrAQuietDayStartsOver(t *testing.T) {
	now := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)
	l := NewLockout(1, time.Minute, time.Hour)
	l.now = func() time.Time { return now }
	l.Fail("a")
	now = now.Add(time.Minute)
	l.Fail("a") // The second lockout: two minutes.
	now = now.Add(2 * time.Minute)
	l.Reset("a")
	l.Fail("a")
	now = now.Add(time.Minute)
	if !l.Allowed("a") {
		t.Error("a success did not start over")
	}
	l.Fail("a") // Two minutes again.
	now = now.Add(2*time.Minute + lockoutMemory + time.Second)
	l.Fail("a")
	now = now.Add(time.Minute)
	if !l.Allowed("a") {
		t.Error("a quiet day did not start over")
	}
}
