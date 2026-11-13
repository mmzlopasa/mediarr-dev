package app

import (
	"context"
	"os"
	"path/filepath"
	"sync"
	"sync/atomic"
	"testing"
	"time"
)

func TestRequestsAtOnceShareOneTVCopy(t *testing.T) {
	s := &apiServer{}
	dest := filepath.Join(t.TempDir(), "copy.mp4")
	var made atomic.Int32
	release := make(chan struct{})
	build := func(context.Context) error {
		made.Add(1)
		<-release
		return os.WriteFile(dest, []byte("video"), 0o600)
	}
	var wg sync.WaitGroup
	for range 8 {
		wg.Go(func() {
			if err := s.makeTVCopy(context.Background(), dest, build); err != nil {
				t.Error(err)
			}
		})
	}
	time.Sleep(50 * time.Millisecond)
	close(release)
	wg.Wait()
	if n := made.Load(); n != 1 {
		t.Errorf("the copy was made %d times", n)
	}
	// Once it exists, nothing is made again.
	if err := s.makeTVCopy(context.Background(), dest, build); err != nil || made.Load() != 1 {
		t.Errorf("made again: %v, %d", err, made.Load())
	}
}

func TestARequestThatGoesAwayDoesNotStopTheCopy(t *testing.T) {
	s := &apiServer{}
	dest := filepath.Join(t.TempDir(), "copy.mp4")
	started, finished := make(chan struct{}), make(chan error, 1)
	build := func(ctx context.Context) error {
		close(started)
		time.Sleep(50 * time.Millisecond)
		err := ctx.Err()
		finished <- err
		return err
	}
	ctx, cancel := context.WithCancel(context.Background())
	go func() {
		<-started
		cancel()
	}()
	if err := s.makeTVCopy(ctx, dest, build); err == nil {
		t.Error("the request that went away still waited")
	}
	if err := <-finished; err != nil {
		t.Errorf("the copy was stopped: %v", err)
	}
}
