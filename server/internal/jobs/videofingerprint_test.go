package jobs

import "testing"

func TestTheSameVideoHasTheSameLengthAndFrames(t *testing.T) {
	a := []int64{0b1111, 0b1010, 0b0101, 0b1100}
	near := []int64{0b1110, 0b1010, 0b0101, 0b1100}
	if !SameVideo(a, near, 10_000, 10_400) {
		t.Fatal("a re-encoded copy is the same video")
	}
	if SameVideo(a, near, 10_000, 12_000) {
		t.Fatal("two seconds longer is another video")
	}
	other := []int64{0b1111, 0b1010, 0b0101, -1}
	if SameVideo(a, other, 10_000, 10_000) {
		t.Fatal("one different frame is another video")
	}
	if SameVideo(a, []int64{}, 10_000, 10_000) {
		t.Fatal("a video that could not be read is like nothing")
	}
}
