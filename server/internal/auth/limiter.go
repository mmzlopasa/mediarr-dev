package auth

import (
	"sync"
	"time"
)

// Limiter counts failures per key within a sliding window.
type Limiter struct {
	mu     sync.Mutex
	max    int
	window time.Duration
	now    func() time.Time
	hits   map[string][]time.Time
}

// NewLimiter allows up to limit failures per key within window.
func NewLimiter(limit int, window time.Duration) *Limiter {
	return &Limiter{max: limit, window: window, now: time.Now, hits: map[string][]time.Time{}}
}

func (l *Limiter) recent(key string, now time.Time) []time.Time {
	kept := l.hits[key][:0]
	for _, hit := range l.hits[key] {
		if now.Sub(hit) < l.window {
			kept = append(kept, hit)
		}
	}
	if len(kept) == 0 {
		delete(l.hits, key)
		return nil
	}
	l.hits[key] = kept
	return kept
}

// Allowed reports whether another attempt may be made.
func (l *Limiter) Allowed(key string) bool {
	l.mu.Lock()
	defer l.mu.Unlock()
	return len(l.recent(key, l.now())) < l.max
}

// A visitor can make up any number of keys, so old ones are cleared once there are many.
const maxTrackedKeys = 10000

// Fail records a failed attempt.
func (l *Limiter) Fail(key string) {
	l.mu.Lock()
	defer l.mu.Unlock()
	now := l.now()
	l.hits[key] = append(l.recent(key, now), now)
	if len(l.hits) > maxTrackedKeys {
		for other := range l.hits {
			l.recent(other, now)
		}
	}
}

// Reset forgets a key after a successful attempt.
func (l *Limiter) Reset(key string) {
	l.mu.Lock()
	defer l.mu.Unlock()
	delete(l.hits, key)
}
