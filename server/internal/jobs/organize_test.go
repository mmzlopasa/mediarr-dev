package jobs

import (
	"math/rand/v2"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgtype"
)

func shotID(n byte) pgtype.UUID { return pgtype.UUID{Bytes: [16]byte{n}, Valid: true} }

func at(seconds int) time.Time {
	return time.Date(2024, 7, 1, 12, 0, seconds, 0, time.UTC)
}

func TestBurstsNeedThreeFramesFromOneCamera(t *testing.T) {
	plans := PlanStacks([]Shot{
		{ID: shotID(1), Name: "a.jpg", TakenAt: at(0), Camera: "X", Sharpness: 1},
		{ID: shotID(2), Name: "b.jpg", TakenAt: at(1), Camera: "X", Sharpness: 9},
		{ID: shotID(3), Name: "c.jpg", TakenAt: at(2), Camera: "X", Sharpness: 3},
		// Too late to belong to it.
		{ID: shotID(4), Name: "d.jpg", TakenAt: at(5), Camera: "X"},
		// Same moment, someone else's camera.
		{ID: shotID(5), Name: "e.jpg", TakenAt: at(1), Camera: "Y"},
		{ID: shotID(6), Name: "f.jpg", TakenAt: at(1), Camera: "Y"},
		// No camera known: never a burst.
		{ID: shotID(7), Name: "g.jpg", TakenAt: at(1)},
		{ID: shotID(8), Name: "h.jpg", TakenAt: at(1)},
		{ID: shotID(9), Name: "i.jpg", TakenAt: at(1)},
	})
	if len(plans) != 1 || len(plans[0].Shots) != 3 {
		t.Fatalf("%+v", plans)
	}
	if plans[0].Main != shotID(2) {
		t.Fatalf("the sharpest shot should lead: %+v", plans[0])
	}
}

func TestRawGoesWithItsJPEG(t *testing.T) {
	plans := PlanStacks([]Shot{
		{ID: shotID(1), Name: "IMG_1.CR2", TakenAt: at(0), Sharpness: 99},
		{ID: shotID(2), Name: "img_1.jpg", TakenAt: at(0), Sharpness: 1},
		// A counter that started over, much later.
		{ID: shotID(3), Name: "IMG_2.CR2", TakenAt: at(0)},
		{ID: shotID(4), Name: "IMG_2.jpg", TakenAt: at(30)},
		// Two JPEGs are not a pair.
		{ID: shotID(5), Name: "IMG_3.jpg", TakenAt: at(0)},
		{ID: shotID(6), Name: "IMG_3.jpeg", TakenAt: at(0)},
	})
	if len(plans) != 1 || plans[0].Main != shotID(2) || len(plans[0].Shots) != 2 {
		t.Fatalf("%+v", plans)
	}
}

func TestRawPairsCountAsOneFrameOfABurst(t *testing.T) {
	plans := PlanStacks([]Shot{
		{ID: shotID(1), Name: "1.cr2", TakenAt: at(0), Camera: "X"},
		{ID: shotID(2), Name: "1.jpg", TakenAt: at(0), Camera: "X"},
		{ID: shotID(3), Name: "2.cr2", TakenAt: at(1), Camera: "X"},
		{ID: shotID(4), Name: "2.jpg", TakenAt: at(1), Camera: "X"},
	})
	if len(plans) != 2 {
		t.Fatalf("two frames are not a burst: %+v", plans)
	}
}

func TestTheUsersChoiceStays(t *testing.T) {
	shots := []Shot{
		{ID: shotID(1), Name: "a.jpg", TakenAt: at(0), Camera: "X", Sharpness: 1, Chosen: true},
		{ID: shotID(2), Name: "b.jpg", TakenAt: at(1), Camera: "X", Sharpness: 9, Parent: shotID(1)},
		{ID: shotID(3), Name: "c.jpg", TakenAt: at(2), Camera: "X", Sharpness: 3, Parent: shotID(1)},
	}
	if plans := PlanStacks(shots); len(plans) != 0 {
		t.Fatalf("a settled stack needs no change: %+v", plans)
	}
	shots = append(shots, Shot{ID: shotID(4), Name: "d.jpg", TakenAt: at(3), Camera: "X", Sharpness: 50})
	plans := PlanStacks(shots)
	if len(plans) != 1 || plans[0].Main != shotID(1) || len(plans[0].Shots) != 4 {
		t.Fatalf("%+v", plans)
	}
}

func TestGroupPairsFollowsChains(t *testing.T) {
	groups := GroupPairs([][2]int{{1, 2}, {3, 4}, {2, 5}})
	if len(groups) != 2 || len(groups[0]) != 3 || len(groups[1]) != 2 {
		t.Fatalf("%v", groups)
	}
}

func noise(seed uint64, side int) []byte {
	random := rand.New(rand.NewPCG(seed, seed))
	out := make([]byte, side*side)
	// Blocks, so the picture has a shape at the scale the hash looks at.
	const block = 64
	for y := range side {
		for x := range side {
			cell := uint64(y/block*side + x/block)
			out[y*side+x] = byte((cell*2654435761 + random.Uint64N(8)) >> 3)
		}
	}
	shape := rand.New(rand.NewPCG(seed, 1))
	cells := make([]byte, side)
	for i := range cells {
		cells[i] = byte(shape.UintN(256))
	}
	for y := range side {
		for x := range side {
			out[y*side+x] = cells[(y/block*(side/block)+x/block)%side] ^ byte(random.UintN(4))
		}
	}
	return out
}

func distance(a, b uint64) int {
	count := 0
	for x := a ^ b; x != 0; x &= x - 1 {
		count++
	}
	return count
}

func TestHashSeesTheSamePictureAndTellsOthersApart(t *testing.T) {
	const side = 512
	one, other := noise(1, side), noise(2, side)
	brighter := make([]byte, len(one))
	for i, value := range one {
		brighter[i] = byte(min(int(value)+20, 255))
	}
	if d := distance(PerceptualHash(one, side), PerceptualHash(brighter, side)); d > maxHashDistance {
		t.Errorf("a brighter copy is %d bits away", d)
	}
	if d := distance(PerceptualHash(one, side), PerceptualHash(other, side)); d <= maxHashDistance {
		t.Errorf("different pictures are only %d bits apart", d)
	}
}

func TestSharpnessDropsWithBlur(t *testing.T) {
	const side = 256
	crisp := noise(3, side)
	blurred := make([]byte, len(crisp))
	copy(blurred, crisp)
	for y := 1; y < side-1; y++ {
		for x := 1; x < side-1; x++ {
			at := y*side + x
			blurred[at] = byte((int(crisp[at-1]) + int(crisp[at+1]) + int(crisp[at-side]) + int(crisp[at+side])) / 4)
		}
	}
	if Sharpness(crisp, side) <= Sharpness(blurred, side) {
		t.Errorf("crisp %f, blurred %f", Sharpness(crisp, side), Sharpness(blurred, side))
	}
}
