package jobs

import (
	"context"
	"fmt"
	"log/slog"
	"math"
	"math/bits"
	"path/filepath"
	"slices"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/riverqueue/river"
	"github.com/riverqueue/river/rivertype"

	"github.com/mediarr-app/mediarr/server/db"
)

const (
	organizeInterval = time.Minute
	organizeBatch    = 500
	organizeTimeout  = 30 * time.Minute

	// Shots at most this far apart, from one camera, belong to the same burst.
	burstGap      = time.Second
	minBurstShots = 3
	// A RAW file and its JPEG are written at the same moment, give or take the camera's clock.
	rawPairGap = 2 * time.Second

	// How much two pictures may differ to be proposed as duplicates. Measured on 30 real photos and
	// copies of them: re-saved, halved, brightened or grey copies were at most 4 bits away, and
	// different photos at least 20. For the embedding, re-saved, halved and brightened copies were
	// at most 0.016 away, and different photos at least 0.09. It catches many crops as well.
	maxHashDistance      = 6
	maxEmbeddingDistance = 0.03

	fingerprintSide = 512
	hashSource      = 32
	hashSide        = 8
)

// OrganizeArgs looks through new photos for stacks and duplicates.
type OrganizeArgs struct{}

// Kind identifies the job in the queue.
func (OrganizeArgs) Kind() string { return "organize" }

// InsertOpts keeps a single run at a time, however long a large library takes.
func (OrganizeArgs) InsertOpts() river.InsertOpts {
	return river.InsertOpts{UniqueOpts: river.UniqueOpts{ByArgs: true, ByState: []rivertype.JobState{
		rivertype.JobStateAvailable, rivertype.JobStatePending, rivertype.JobStateRetryable,
		rivertype.JobStateRunning, rivertype.JobStateScheduled,
	}}}
}

type organizeWorker struct {
	river.WorkerDefaults[OrganizeArgs]
	*deps
}

func (w *organizeWorker) Timeout(*river.Job[OrganizeArgs]) time.Duration { return organizeTimeout }

func (w *organizeWorker) Work(ctx context.Context, _ *river.Job[OrganizeArgs]) error {
	return Organize(ctx, w.pool, w.queries)
}

// Organize works through everything that is waiting.
func Organize(ctx context.Context, pool beginner, q *db.Queries) error {
	for {
		count, err := organizeNew(ctx, pool, q)
		if err != nil {
			return err
		}
		if count < organizeBatch {
			break
		}
	}
	for {
		count, err := compareEmbeddings(ctx, pool, q)
		if err != nil {
			return err
		}
		if count < organizeBatch {
			return nil
		}
	}
}

func organizeNew(ctx context.Context, pool beginner, q *db.Queries) (int, error) {
	rows, err := q.ListUnorganized(ctx, organizeBatch)
	if err != nil || len(rows) == 0 {
		return 0, err
	}
	type dayKey struct {
		user pgtype.UUID
		day  time.Time
	}
	days := map[dayKey]bool{}
	byUser := map[pgtype.UUID]map[pgtype.UUID]uint64{}
	ids := make([]pgtype.UUID, 0, len(rows))
	for i := range rows {
		row := &rows[i]
		ids = append(ids, row.ID)
		days[dayKey{row.UserID, row.LocalAt.Time.Truncate(24 * time.Hour)}] = true
		hash, known := uint64(row.Phash.Int64), row.Phash.Valid //nolint:gosec // Stored bit for bit.
		if !known {
			hash, known = storeFingerprint(ctx, q, row.ID)
		}
		if known {
			if byUser[row.UserID] == nil {
				byUser[row.UserID] = map[pgtype.UUID]uint64{}
			}
			byUser[row.UserID][row.ID] = hash
		}
	}
	for key := range days {
		if err := stackDay(ctx, pool, q, key.user, key.day); err != nil {
			return 0, err
		}
	}
	for user, fresh := range byUser {
		if err := compareHashes(ctx, q, user, fresh); err != nil {
			return 0, err
		}
	}
	return len(rows), q.MarkOrganized(ctx, ids)
}

// storeFingerprint is best effort: a picture that cannot be read simply is not compared.
func storeFingerprint(ctx context.Context, q *db.Queries, id pgtype.UUID) (uint64, bool) {
	path, err := q.GetAssetFile(ctx, db.GetAssetFileParams{AssetID: id, Kind: "thumb_large"})
	if err != nil {
		return 0, false
	}
	hash, sharpness, err := fingerprintFile(ctx, path)
	if err != nil {
		slog.Warn("a picture could not be compared", "asset", uuidString(id), "error", err)
		return 0, false
	}
	if err := q.SetFingerprint(ctx, db.SetFingerprintParams{
		ID:        id,
		Phash:     pgtype.Int8{Int64: int64(hash), Valid: true}, //nolint:gosec // Stored bit for bit.
		Sharpness: pgtype.Float4{Float32: float32(sharpness), Valid: true},
	}); err != nil {
		slog.Warn("a fingerprint could not be stored", "asset", uuidString(id), "error", err)
		return 0, false
	}
	return hash, true
}

func fingerprintFile(ctx context.Context, path string) (hash uint64, sharpness float64, err error) {
	side := fmt.Sprintf("scale=%d:%d,format=gray", fingerprintSide, fingerprintSide)
	out, err := runTool(ctx, "ffmpeg", "-nostdin", "-v", "error", "-i", path, "-vf", side, "-frames:v", "1", "-f", "rawvideo", "-")
	if err != nil {
		return 0, 0, err
	}
	if len(out) != fingerprintSide*fingerprintSide {
		return 0, 0, fmt.Errorf("expected %d bytes, got %d", fingerprintSide*fingerprintSide, len(out))
	}
	return PerceptualHash(out, fingerprintSide), Sharpness(out, fingerprintSide), nil
}

// PerceptualHash reads the coarse shape of a square grey picture from the lowest frequencies of its
// cosine transform, so a resized or re-saved copy keeps nearly the same bits.
func PerceptualHash(gray []byte, side int) uint64 {
	small := make([]float64, hashSource*hashSource)
	cell := side / hashSource
	for y := range hashSource {
		for x := range hashSource {
			sum := 0
			for dy := range cell {
				for dx := range cell {
					sum += int(gray[(y*cell+dy)*side+x*cell+dx])
				}
			}
			small[y*hashSource+x] = float64(sum) / float64(cell*cell)
		}
	}
	coefficients := make([]float64, 0, hashSide*hashSide)
	for v := range hashSide {
		for u := range hashSide {
			sum := 0.0
			for y := range hashSource {
				for x := range hashSource {
					sum += small[y*hashSource+x] *
						math.Cos(float64(2*x+1)*float64(u)*math.Pi/(2*hashSource)) *
						math.Cos(float64(2*y+1)*float64(v)*math.Pi/(2*hashSource))
				}
			}
			coefficients = append(coefficients, sum)
		}
	}
	// The first one is only the overall brightness.
	sorted := slices.Clone(coefficients[1:])
	slices.Sort(sorted)
	median := sorted[len(sorted)/2]
	var hash uint64
	for i, value := range coefficients {
		if i > 0 && value > median {
			hash |= 1 << i
		}
	}
	return hash
}

// Sharpness is the variance of the Laplacian: edges that are crisp make it large.
func Sharpness(gray []byte, side int) float64 {
	var sum, squares float64
	for y := 1; y < side-1; y++ {
		for x := 1; x < side-1; x++ {
			at := y*side + x
			value := float64(gray[at-side]) + float64(gray[at+side]) + float64(gray[at-1]) + float64(gray[at+1]) - 4*float64(gray[at])
			sum += value
			squares += value * value
		}
	}
	count := float64((side - 2) * (side - 2))
	mean := sum / count
	return squares/count - mean*mean
}

// Shot is what deciding a stack needs to know about a photo.
type Shot struct {
	ID        pgtype.UUID
	Name      string
	TakenAt   time.Time
	Camera    string
	Sharpness float32
	Parent    pgtype.UUID
	Chosen    bool
}

// StackPlan is one stack: its main shot and all of its shots, the main one included.
type StackPlan struct {
	Main  pgtype.UUID
	Shots []pgtype.UUID
}

// PlanStacks puts RAW files with their JPEGs and bursts together. Stacks that exist stay together.
func PlanStacks(shots []Shot) []StackPlan {
	groups := newUnion[pgtype.UUID]()
	known := make(map[pgtype.UUID]*Shot, len(shots))
	for i := range shots {
		known[shots[i].ID] = &shots[i]
	}
	for i := range shots {
		if _, ok := known[shots[i].Parent]; shots[i].Parent.Valid && ok {
			groups.join(shots[i].ID, shots[i].Parent)
		}
	}
	joinRawPairs(shots, groups)
	frames := newUnion[pgtype.UUID]()
	joinRawPairs(shots, frames)
	joinBursts(shots, frames, groups)

	members := map[pgtype.UUID][]*Shot{}
	for i := range shots {
		root := groups.find(shots[i].ID)
		members[root] = append(members[root], &shots[i])
	}
	plans := []StackPlan{}
	for _, group := range members {
		if len(group) < 2 {
			continue
		}
		main := bestShot(group)
		plan := StackPlan{Main: main.ID}
		settled := true
		for _, shot := range group {
			plan.Shots = append(plan.Shots, shot.ID)
			if shot != main && shot.Parent != main.ID {
				settled = false
			}
		}
		if !settled || main.Parent.Valid {
			plans = append(plans, plan)
		}
	}
	slices.SortFunc(plans, func(a, b StackPlan) int { return slices.Compare(a.Main.Bytes[:], b.Main.Bytes[:]) })
	return plans
}

func joinRawPairs(shots []Shot, groups *union[pgtype.UUID]) {
	byStem := map[string][]*Shot{}
	for i := range shots {
		name := strings.ToLower(shots[i].Name)
		stem := strings.TrimSuffix(name, filepath.Ext(name))
		byStem[stem] = append(byStem[stem], &shots[i])
	}
	for _, same := range byStem {
		for _, raw := range same {
			if !isRaw(raw.Name) {
				continue
			}
			var closest *Shot
			for _, other := range same {
				if isRaw(other.Name) || absDuration(other.TakenAt.Sub(raw.TakenAt)) > rawPairGap {
					continue
				}
				if closest == nil || absDuration(other.TakenAt.Sub(raw.TakenAt)) < absDuration(closest.TakenAt.Sub(raw.TakenAt)) {
					closest = other
				}
			}
			if closest != nil {
				groups.join(raw.ID, closest.ID)
			}
		}
	}
}

func joinBursts(shots []Shot, frames, groups *union[pgtype.UUID]) {
	byCamera := map[string][]*Shot{}
	for i := range shots {
		// Without a known camera, two people's photos could pass for one burst.
		if shots[i].Camera != "" {
			byCamera[shots[i].Camera] = append(byCamera[shots[i].Camera], &shots[i])
		}
	}
	for _, same := range byCamera {
		slices.SortFunc(same, func(a, b *Shot) int { return a.TakenAt.Compare(b.TakenAt) })
		start := 0
		for i := 1; i <= len(same); i++ {
			if i < len(same) && same[i].TakenAt.Sub(same[i-1].TakenAt) <= burstGap {
				continue
			}
			joinBurst(same[start:i], frames, groups)
			start = i
		}
	}
}

// joinBurst counts a RAW file and its JPEG as one frame.
func joinBurst(run []*Shot, frames, groups *union[pgtype.UUID]) {
	seen := map[pgtype.UUID]bool{}
	for _, shot := range run {
		seen[frames.find(shot.ID)] = true
	}
	if len(seen) < minBurstShots {
		return
	}
	for _, shot := range run[1:] {
		groups.join(run[0].ID, shot.ID)
	}
}

// bestShot honours the user's choice. Otherwise the sharpest wins, and a RAW file only if there is
// nothing else, because a JPEG is what the camera finished.
func bestShot(group []*Shot) *Shot {
	best := group[0]
	better := func(a, b *Shot) bool {
		if a.Chosen != b.Chosen {
			return a.Chosen
		}
		if isRaw(a.Name) != isRaw(b.Name) {
			return !isRaw(a.Name)
		}
		if a.Sharpness != b.Sharpness {
			return a.Sharpness > b.Sharpness
		}
		return slices.Compare(a.ID.Bytes[:], b.ID.Bytes[:]) < 0
	}
	for _, shot := range group[1:] {
		if better(shot, best) {
			best = shot
		}
	}
	return best
}

func absDuration(d time.Duration) time.Duration { return max(d, -d) }

func stackDay(ctx context.Context, pool beginner, q *db.Queries, user pgtype.UUID, day time.Time) error {
	rows, err := q.ListStackShots(ctx, db.ListStackShotsParams{
		UserID: user,
		FromAt: pgtype.Timestamp{Time: day, Valid: true},
		ToAt:   pgtype.Timestamp{Time: day.Add(24 * time.Hour), Valid: true},
	})
	if err != nil {
		return err
	}
	shots := make([]Shot, len(rows))
	for i := range rows {
		row := &rows[i]
		shots[i] = Shot{
			ID: row.ID, Name: row.OriginalName, TakenAt: row.TakenAt.Time,
			Camera:    strings.TrimSpace(row.Make + " " + row.Model),
			Sharpness: row.Sharpness.Float32, Parent: row.StackParent, Chosen: row.StackChosen,
		}
	}
	plans := PlanStacks(shots)
	if len(plans) == 0 {
		return nil
	}
	return pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		qtx := q.WithTx(tx)
		for i := range plans {
			if err := qtx.ApplyStack(ctx, db.ApplyStackParams{MainID: plans[i].Main, Ids: plans[i].Shots}); err != nil {
				return err
			}
		}
		return nil
	})
}

func compareHashes(ctx context.Context, q *db.Queries, user pgtype.UUID, fresh map[pgtype.UUID]uint64) error {
	rows, err := q.ListHashes(ctx, user)
	if err != nil {
		return err
	}
	for id, hash := range fresh {
		for i := range rows {
			other := &rows[i]
			if other.ID == id || bits.OnesCount64(hash^uint64(other.Phash.Int64)) > maxHashDistance { //nolint:gosec // Stored bit for bit.
				continue
			}
			if err := q.AddSimilarPair(ctx, db.AddSimilarPairParams{X: id, Y: other.ID, UserID: user}); err != nil {
				return err
			}
		}
	}
	return nil
}

// compareEmbeddings finds what the hash cannot: the same picture cropped or edited.
func compareEmbeddings(ctx context.Context, pool beginner, q *db.Queries) (int, error) {
	rows, err := q.ListUncheckedEmbeddings(ctx, organizeBatch)
	if err != nil {
		return 0, err
	}
	for i := range rows {
		row := &rows[i]
		err := pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
			if _, err := tx.Exec(ctx, "SET LOCAL hnsw.iterative_scan = relaxed_order"); err != nil {
				return err
			}
			qtx := q.WithTx(tx)
			near, err := qtx.NearestEmbeddings(ctx, db.NearestEmbeddingsParams{
				Embedding: row.Embedding, UserID: row.UserID, AssetID: row.AssetID,
			})
			if err != nil {
				return err
			}
			for j := range near {
				if near[j].Distance > maxEmbeddingDistance {
					continue
				}
				if err := qtx.AddSimilarPair(ctx, db.AddSimilarPairParams{X: row.AssetID, Y: near[j].AssetID, UserID: row.UserID}); err != nil {
					return err
				}
			}
			return qtx.MarkEmbeddingChecked(ctx, row.AssetID)
		})
		if err != nil {
			return 0, err
		}
	}
	return len(rows), nil
}

type union[T comparable] struct{ parent map[T]T }

func newUnion[T comparable]() *union[T] { return &union[T]{parent: map[T]T{}} }

func (u *union[T]) find(value T) T {
	parent, ok := u.parent[value]
	if !ok || parent == value {
		return value
	}
	root := u.find(parent)
	u.parent[value] = root
	return root
}

func (u *union[T]) join(a, b T) {
	if rootA, rootB := u.find(a), u.find(b); rootA != rootB {
		u.parent[rootA] = rootB
	}
}

// GroupPairs turns "these two look alike" into groups that all look alike.
func GroupPairs[T comparable](pairs [][2]T) [][]T {
	groups := newUnion[T]()
	seen := map[T]bool{}
	order := []T{}
	for _, pair := range pairs {
		for _, value := range pair {
			if !seen[value] {
				seen[value] = true
				order = append(order, value)
			}
		}
		groups.join(pair[0], pair[1])
	}
	byRoot := map[T][]T{}
	for _, value := range order {
		root := groups.find(value)
		byRoot[root] = append(byRoot[root], value)
	}
	out := make([][]T, 0, len(byRoot))
	for _, value := range order {
		if group, ok := byRoot[groups.find(value)]; ok {
			out = append(out, group)
			delete(byRoot, groups.find(value))
		}
	}
	return out
}
