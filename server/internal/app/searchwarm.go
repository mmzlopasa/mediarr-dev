package app

import (
	"context"
	"log/slog"
	"net/http"
	"sync/atomic"
	"time"
)

const (
	// warmEvery keeps many open search pages from asking more than once in a while.
	warmEvery = time.Minute
	warmLimit = 30 * time.Second
	// warmWords is any short text: reading it loads the model, and the answer is thrown away.
	warmWords = "photo"
)

// lastWarm is when the model was last asked to load, in Unix seconds.
var lastWarm atomic.Int64

// WarmSearch starts loading the model that reads words when someone opens search, so that after the
// ML service let it go while idle, the first query does not wait several seconds for it.
func (s *apiServer) WarmSearch(w http.ResponseWriter, r *http.Request) {
	if requireUser(w, r) == nil {
		return
	}
	w.WriteHeader(http.StatusNoContent)
	now := time.Now().Unix()
	last := lastWarm.Load()
	if !s.embeddings.Enabled() || now-last < int64(warmEvery.Seconds()) || !lastWarm.CompareAndSwap(last, now) {
		return
	}
	go func() {
		ctx, cancel := context.WithTimeout(context.Background(), warmLimit)
		defer cancel()
		if _, err := s.embeddings.Client().EmbedText(ctx, warmWords); err != nil {
			slog.Debug("the model for search did not load ahead", "error", err)
		}
	}()
}
