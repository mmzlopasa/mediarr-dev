package auth

import (
	"sync"
	"time"
)

// Lockout allows a few failures per key, then locks the key out for a while, each time twice as
// long as the time before, up to a ceiling. A short secret such as a PIN then cannot be found by
// patiently trying a few each window. A success, or a full day with no failure, starts over.
type Lockout struct {
	mu      sync.Mutex
	max     int
	base    time.Duration
	ceiling time.Duration
	now     func() time.Time
	keys    map[string]*lockoutState
}

type lockoutState struct {
	failures int // since the last lockout ended
	lockouts int
	until    time.Time
	last     time.Time
}

// lockoutMemory is how long a key's past lockouts are remembered after its last failure.
const lockoutMemory = 24 * time.Hour

// NewLockout allows limit failures, then locks out for base, 2*base, 4*base, ... at most ceiling.
func NewLockout(limit int, base, ceiling time.Duration) *Lockout {
	return &Lockout{max: limit, base: base, ceiling: ceiling, now: time.Now, keys: map[string]*lockoutState{}}
}

func (l *Lockout) state(key string, now time.Time) *lockoutState {
	state := l.keys[key]
	if state != nil && now.After(state.until) && now.Sub(state.last) > lockoutMemory {
		delete(l.keys, key)
		return nil
	}
	return state
}

// Allowed reports whether another attempt may be made now.
func (l *Lockout) Allowed(key string) bool {
	l.mu.Lock()
	defer l.mu.Unlock()
	now := l.now()
	state := l.state(key, now)
	return state == nil || !now.Before(state.until)
}

// Fail records a failed attempt, and locks the key out once there were too many.
func (l *Lockout) Fail(key string) {
	l.mu.Lock()
	defer l.mu.Unlock()
	now := l.now()
	state := l.state(key, now)
	if state == nil {
		state = &lockoutState{}
		l.keys[key] = state
	}
	state.last = now
	state.failures++
	if state.failures < l.max {
		return
	}
	state.failures = 0
	wait := l.base << min(state.lockouts, 30)
	if wait <= 0 || wait > l.ceiling {
		wait = l.ceiling
	}
	state.lockouts++
	state.until = now.Add(wait)
	if len(l.keys) > maxTrackedKeys {
		for other := range l.keys {
			l.state(other, now)
		}
	}
}

// Reset forgets a key after a successful attempt.
func (l *Lockout) Reset(key string) {
	l.mu.Lock()
	defer l.mu.Unlock()
	delete(l.keys, key)
}
