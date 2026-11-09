package jobs

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/mediarr-app/mediarr/server/internal/ml"
)

func TestAnalysisWaitsForTheServiceAndContinues(t *testing.T) {
	tries := 0
	err := retryUntilAvailable(context.Background(), func() error {
		tries++
		if tries < 3 {
			return ml.ErrWrongToken
		}
		return nil
	}, time.Millisecond, time.Minute)
	if err != nil || tries != 3 {
		t.Fatalf("%v after %d tries", err, tries)
	}
}

func TestAnalysisGivesBackTheJobAfterHoldingItLongEnough(t *testing.T) {
	tries := 0
	err := retryUntilAvailable(context.Background(), func() error {
		tries++
		return ml.ErrWrongToken
	}, time.Millisecond, 0)
	if !ml.Unavailable(err) || tries != 1 {
		t.Fatalf("%v after %d tries", err, tries)
	}
}

func TestAProblemWithThePictureIsNotRetried(t *testing.T) {
	tries := 0
	cause := errors.New("broken")
	err := retryUntilAvailable(context.Background(), func() error {
		tries++
		return cause
	}, time.Millisecond, time.Minute)
	if !errors.Is(err, cause) || tries != 1 {
		t.Fatalf("%v after %d tries", err, tries)
	}
}
