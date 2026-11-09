package jobs

import (
	"cmp"
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"math"
	"slices"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/riverqueue/river"
	"github.com/riverqueue/river/rivertype"

	"github.com/mediarr-app/mediarr/server/db"
)

const (
	memoriesEvery  = 24 * time.Hour
	memoryMaxItems = 30
	// What is too far from home to be a day out: the neighbouring town does not make a trip.
	tripFarKm       = 50
	tripMinDays     = 2
	tripMinPhotos   = 5
	tripMaxGapDays  = 1
	tripRecentDays  = 14
	tripOldShowDays = 7
	personMinYears  = 3
	personMinPhotos = 6
	birthdayMin     = 3
	yearMinPhotos   = 12
	monthAgoMin     = 3
	yearReviewMonth = time.January
	earthRadiusKm   = 6371.0
)

// The kinds worked out here. Their order is the order on the page.
const (
	memoryBirthday = "birthday"
	memoryTrip     = "trip"
	memoryMonthAgo = "month_ago"
	memoryPerson   = "person_years"
	memoryYear     = "year_review"
)

// MemoriesArgs works out memories: of one account for one day when that person opened them on a day
// not worked out yet, otherwise of everyone for today.
type MemoriesArgs struct {
	UserID uuid.UUID `json:"user_id,omitzero"`
	Day    string    `json:"day,omitempty"`
}

// Kind identifies the job in the queue.
func (MemoriesArgs) Kind() string { return "memories" }

// InsertOpts keeps one such job at a time per account and day: every open of the page may ask.
func (MemoriesArgs) InsertOpts() river.InsertOpts {
	return river.InsertOpts{UniqueOpts: river.UniqueOpts{ByArgs: true, ByState: []rivertype.JobState{
		rivertype.JobStateAvailable, rivertype.JobStatePending, rivertype.JobStateRetryable,
		rivertype.JobStateRunning, rivertype.JobStateScheduled,
	}}}
}

type memoriesWorker struct {
	river.WorkerDefaults[MemoriesArgs]
	*deps
}

func (w *memoriesWorker) Timeout(*river.Job[MemoriesArgs]) time.Duration { return time.Hour }

func (w *memoriesWorker) Work(ctx context.Context, job *river.Job[MemoriesArgs]) error {
	if job.Args.UserID != uuid.Nil {
		day, err := time.Parse(time.DateOnly, job.Args.Day)
		if err != nil {
			return river.JobCancel(err)
		}
		return ComputeMemories(ctx, w.pool, toPG(job.Args.UserID), day)
	}
	users, err := w.queries.ListUsers(ctx)
	if err != nil {
		return err
	}
	today := time.Now().UTC()
	for i := range users {
		if err := ComputeMemories(ctx, w.pool, users[i].ID, today); err != nil {
			// One account that cannot be worked out must not cost the others theirs.
			slog.Warn("memories could not be worked out", "user", uuidString(users[i].ID), "error", err)
		}
	}
	return nil
}

// TitleParams are the facts a client words a title from. The server never words one itself.
type TitleParams struct {
	Place    string `json:"place,omitempty"`
	Person   string `json:"person,omitempty"`
	PersonID string `json:"personId,omitempty"`
	Year     int    `json:"year,omitempty"`
	Month    int    `json:"month,omitempty"`
}

type memoryAsset struct {
	id       pgtype.UUID
	at       time.Time
	favorite bool
	rating   int16
	sharp    float32
	hasGPS   bool
	lat, lon float64
	city     string
	country  string
}

func (a *memoryAsset) place() string {
	if a.city != "" {
		return a.city
	}
	return a.country
}

func startOfDay(t time.Time) time.Time {
	return time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, time.UTC)
}

// pickBest keeps the best photos, at most limit, spread over the buckets so that one busy month or
// year does not fill a memory, and returns them in the order they were taken.
func pickBest(assets []*memoryAsset, limit int, bucket func(*memoryAsset) string) []pgtype.UUID {
	maxSharp := float32(0)
	for _, a := range assets {
		maxSharp = max(maxSharp, a.sharp)
	}
	score := func(a *memoryAsset) float64 {
		value := float64(a.rating) * 10
		if a.favorite {
			value += 100
		}
		if maxSharp > 0 {
			value += float64(a.sharp/maxSharp) * 9
		}
		return value
	}
	ordered := slices.Clone(assets)
	slices.SortStableFunc(ordered, func(a, b *memoryAsset) int { return cmp.Compare(score(b), score(a)) })

	taken := make([]*memoryAsset, 0, limit)
	counted := map[string]int{}
	buckets := map[string]bool{}
	for _, a := range ordered {
		buckets[bucket(a)] = true
	}
	perBucket := max(limit/max(len(buckets), 1), 1)
	rest := []*memoryAsset{}
	for _, a := range ordered {
		key := bucket(a)
		if len(taken) < limit && counted[key] < perBucket {
			counted[key]++
			taken = append(taken, a)
			continue
		}
		rest = append(rest, a)
	}
	for _, a := range rest {
		if len(taken) == limit {
			break
		}
		taken = append(taken, a)
	}
	slices.SortStableFunc(taken, func(a, b *memoryAsset) int { return a.at.Compare(b.at) })
	out := make([]pgtype.UUID, len(taken))
	for i, a := range taken {
		out[i] = a.id
	}
	return out
}

func haversineKm(lat1, lon1, lat2, lon2 float64) float64 {
	toRad := func(deg float64) float64 { return deg * math.Pi / 180 }
	dLat, dLon := toRad(lat2-lat1), toRad(lon2-lon1)
	h := math.Pow(math.Sin(dLat/2), 2) + math.Cos(toRad(lat1))*math.Cos(toRad(lat2))*math.Pow(math.Sin(dLon/2), 2)
	return 2 * earthRadiusKm * math.Asin(math.Min(1, math.Sqrt(h)))
}

type homePlace struct {
	name     string
	lat, lon float64
	located  bool
}

// findHome is the place with the most photos, and where its photos were taken on average.
func findHome(assets []*memoryAsset) homePlace {
	counts := map[string]int{}
	for _, a := range assets {
		if place := a.place(); place != "" {
			counts[place]++
		}
	}
	home := homePlace{}
	best := 0
	for place, count := range counts {
		if count > best || (count == best && place < home.name) {
			home.name, best = place, count
		}
	}
	located := 0
	for _, a := range assets {
		if a.place() == home.name && a.hasGPS {
			home.lat += a.lat
			home.lon += a.lon
			located++
		}
	}
	if located > 0 {
		home.lat /= float64(located)
		home.lon /= float64(located)
		home.located = true
	}
	return home
}

type trip struct {
	place    string
	from, to time.Time
	assets   []*memoryAsset
}

// mostCommonPlace names a set of photos; empty when none of them has a place.
func mostCommonPlace(assets []*memoryAsset) string {
	counts := map[string]int{}
	name, best := "", 0
	for _, a := range assets {
		place := a.place()
		if place == "" {
			continue
		}
		counts[place]++
		if counts[place] > best || (counts[place] == best && place < name) {
			name, best = place, counts[place]
		}
	}
	return name
}

// farFromHome tells whether a day's photos were taken away from home. A day without a known place
// says nothing, so it does not break a trip and does not start one.
func farFromHome(day []*memoryAsset, home homePlace) (away, known bool) {
	place := mostCommonPlace(day)
	if place == "" {
		return false, false
	}
	if place == home.name {
		return false, true
	}
	if !home.located {
		return true, true
	}
	lat, lon, located := 0.0, 0.0, 0
	for _, a := range day {
		if a.place() == place && a.hasGPS {
			lat += a.lat
			lon += a.lon
			located++
		}
	}
	if located == 0 {
		return true, true
	}
	return haversineKm(home.lat, home.lon, lat/float64(located), lon/float64(located)) > tripFarKm, true
}

// findTrips finds runs of days away from home. A day at home ends a run; so does more than one day
// without any photo.
func findTrips(assets []*memoryAsset, home homePlace) []trip {
	if home.name == "" {
		return nil
	}
	byDay := map[time.Time][]*memoryAsset{}
	days := []time.Time{}
	for _, a := range assets {
		day := startOfDay(a.at)
		if len(byDay[day]) == 0 {
			days = append(days, day)
		}
		byDay[day] = append(byDay[day], a)
	}
	slices.SortFunc(days, time.Time.Compare)

	trips := []trip{}
	var runDays []time.Time
	finish := func() {
		if len(runDays) >= tripMinDays {
			run := trip{from: runDays[0], to: runDays[len(runDays)-1]}
			for _, day := range runDays {
				run.assets = append(run.assets, byDay[day]...)
			}
			run.place = mostCommonPlace(run.assets)
			if run.place != "" && len(run.assets) >= tripMinPhotos {
				trips = append(trips, run)
			}
		}
		runDays = nil
	}
	for _, day := range days {
		away, known := farFromHome(byDay[day], home)
		if !known {
			// Only a day inside a run belongs to it.
			if len(runDays) > 0 && day.Sub(runDays[len(runDays)-1]) <= (tripMaxGapDays+1)*24*time.Hour {
				runDays = append(runDays, day)
			}
			continue
		}
		if !away {
			finish()
			continue
		}
		if len(runDays) > 0 && day.Sub(runDays[len(runDays)-1]) > (tripMaxGapDays+1)*24*time.Hour {
			finish()
		}
		runDays = append(runDays, day)
	}
	finish()
	return trips
}

type computedMemory struct {
	kind     string
	key      string
	title    string
	params   TitleParams
	items    []pgtype.UUID
	rank     int32
	from, to time.Time
}

func dateSpan(from, to time.Time) string {
	if from.Equal(to) {
		return from.Format(time.DateOnly)
	}
	return from.Format(time.DateOnly) + " – " + to.Format(time.DateOnly)
}

func shownOn(day, from, to time.Time) bool { return !day.Before(from) && !day.After(to) }

// tripWindow says when a trip is shown around this day: in the two weeks after it, and in the week
// from each anniversary of its start.
func tripWindow(t *trip, day time.Time) (from, to time.Time, ok bool) {
	from, to = t.to.AddDate(0, 0, 1), t.to.AddDate(0, 0, tripRecentDays)
	if shownOn(day, from, to) {
		return from, to, true
	}
	for _, year := range []int{day.Year() - 1, day.Year()} {
		if year <= t.from.Year() {
			continue
		}
		from = time.Date(year, t.from.Month(), t.from.Day(), 0, 0, 0, 0, time.UTC)
		to = from.AddDate(0, 0, tripOldShowDays-1)
		if shownOn(day, from, to) {
			return from, to, true
		}
	}
	return from, to, false
}

func noBucket(*memoryAsset) string { return "" }

func dayBucket(a *memoryAsset) string { return a.at.Format(time.DateOnly) }

func monthBucket(a *memoryAsset) string { return a.at.Format("2006-01") }

func yearBucket(a *memoryAsset) string { return a.at.Format("2006") }

// monthBefore is the same day a month earlier, the last of that month when it is shorter.
func monthBefore(day time.Time) time.Time {
	first := time.Date(day.Year(), day.Month()-1, 1, 0, 0, 0, 0, time.UTC)
	last := first.AddDate(0, 1, -1).Day()
	return first.AddDate(0, 0, min(day.Day(), last)-1)
}

func birthdayToday(birth, day time.Time) bool {
	if birth.Month() == time.February && birth.Day() == 29 && !isLeap(day.Year()) {
		return day.Month() == time.February && day.Day() == 28
	}
	return birth.Month() == day.Month() && birth.Day() == day.Day()
}

func isLeap(year int) bool { return year%4 == 0 && (year%100 != 0 || year%400 == 0) }

// mondayOf is the Monday that starts the week of a day.
func mondayOf(day time.Time) time.Time {
	return day.AddDate(0, 0, -((int(day.Weekday()) + 6) % 7))
}

type memoryPersonRow struct {
	id    pgtype.UUID
	name  string
	birth pgtype.Date
}

func distinctYears(rows []*memoryAsset) int {
	years := map[int]bool{}
	for _, a := range rows {
		years[a.at.Year()] = true
	}
	return len(years)
}

func personMemories(people []memoryPersonRow, byPerson map[pgtype.UUID][]*memoryAsset, day time.Time) []computedMemory {
	out := []computedMemory{}
	eligible := []memoryPersonRow{}
	for i := range people {
		person := &people[i]
		photos := byPerson[person.id]
		if len(photos) >= personMinPhotos && distinctYears(photos) >= personMinYears {
			eligible = append(eligible, *person)
		}
		if person.birth.Valid && len(photos) >= birthdayMin && birthdayToday(person.birth.Time, day) {
			out = append(out, computedMemory{
				kind: memoryBirthday, key: fmt.Sprintf("%s|%d", uuidString(person.id), day.Year()),
				title:  day.Format(time.DateOnly),
				params: TitleParams{Person: person.name, PersonID: uuidString(person.id), Year: day.Year()},
				items:  pickBest(photos, memoryMaxItems, yearBucket), rank: 10, from: day, to: day,
			})
		}
	}
	if len(eligible) > 0 {
		// One person a week, in turn, the same for a whole week.
		slices.SortFunc(eligible, func(a, b memoryPersonRow) int {
			if diff := cmp.Compare(len(byPerson[b.id]), len(byPerson[a.id])); diff != 0 {
				return diff
			}
			return cmp.Compare(uuidString(a.id), uuidString(b.id))
		})
		monday := mondayOf(day)
		week := int(monday.Unix() / (7 * 24 * 3600))
		person := eligible[week%len(eligible)]
		photos := byPerson[person.id]
		slices.SortFunc(photos, func(a, b *memoryAsset) int { return a.at.Compare(b.at) })
		out = append(out, computedMemory{
			kind: memoryPerson, key: uuidString(person.id),
			title:  dateSpan(startOfDay(photos[0].at), startOfDay(photos[len(photos)-1].at)),
			params: TitleParams{Person: person.name, PersonID: uuidString(person.id)},
			items:  pickBest(photos, memoryMaxItems, yearBucket), rank: 40,
			from: monday, to: monday.AddDate(0, 0, 6),
		})
	}
	return out
}

func tripMemories(assets []*memoryAsset, day time.Time) []computedMemory {
	out := []computedMemory{}
	seen := map[string]bool{}
	for _, t := range findTrips(assets, findHome(assets)) {
		from, to, ok := tripWindow(&t, day)
		if !ok {
			continue
		}
		key := t.place + "|" + t.from.Format(time.DateOnly)
		if seen[key] {
			continue
		}
		seen[key] = true
		out = append(out, computedMemory{
			kind: memoryTrip, key: key, title: dateSpan(t.from, t.to),
			params: TitleParams{Place: t.place, Year: t.from.Year(), Month: int(t.from.Month())},
			items:  pickBest(t.assets, memoryMaxItems, dayBucket), rank: 20, from: from, to: to,
		})
	}
	return out
}

func monthAgoMemory(assets []*memoryAsset, day time.Time) []computedMemory {
	target := monthBefore(day)
	photos := []*memoryAsset{}
	for _, a := range assets {
		if startOfDay(a.at).Equal(target) {
			photos = append(photos, a)
		}
	}
	if len(photos) < monthAgoMin {
		return nil
	}
	return []computedMemory{{
		kind: memoryMonthAgo, key: target.Format(time.DateOnly), title: target.Format(time.DateOnly),
		params: TitleParams{Year: target.Year(), Month: int(target.Month())},
		items:  pickBest(photos, memoryMaxItems, noBucket), rank: 30, from: day, to: day,
	}}
}

// yearMemory is last year in photos, shown through January.
func yearMemory(assets []*memoryAsset, day time.Time) []computedMemory {
	if day.Month() != yearReviewMonth {
		return nil
	}
	year := day.Year() - 1
	photos := []*memoryAsset{}
	for _, a := range assets {
		if a.at.Year() == year {
			photos = append(photos, a)
		}
	}
	if len(photos) < yearMinPhotos {
		return nil
	}
	first := time.Date(day.Year(), time.January, 1, 0, 0, 0, 0, time.UTC)
	return []computedMemory{{
		kind: memoryYear, key: fmt.Sprintf("%d", year), title: fmt.Sprintf("%d", year),
		params: TitleParams{Year: year},
		items:  pickBest(photos, memoryMaxItems, monthBucket), rank: 50,
		from: first, to: first.AddDate(0, 1, -1),
	}}
}

// ComputeMemories replaces the memories of an account for a day. The owner's hidden ones stay hidden.
func ComputeMemories(ctx context.Context, pool *pgxpool.Pool, user pgtype.UUID, today time.Time) error {
	q := db.New(pool)
	day := startOfDay(today)
	rows, err := q.ListMemoryCandidates(ctx, user)
	if err != nil {
		return err
	}
	assets := make([]*memoryAsset, 0, len(rows))
	byID := make(map[pgtype.UUID]*memoryAsset, len(rows))
	for i := range rows {
		row := &rows[i]
		a := &memoryAsset{
			id: row.ID, at: row.LocalAt.Time, favorite: row.IsFavorite, rating: row.Rating,
			sharp: row.Sharpness.Float32, city: row.City, country: row.Country,
		}
		if row.Latitude.Valid && row.Longitude.Valid {
			a.hasGPS, a.lat, a.lon = true, row.Latitude.Float64, row.Longitude.Float64
		}
		assets = append(assets, a)
		byID[a.id] = a
	}

	hidden, err := q.ListMemoryHiddenPeopleIDs(ctx, user)
	if err != nil {
		return err
	}
	blockedPeople := make(map[pgtype.UUID]bool, len(hidden))
	for _, id := range hidden {
		blockedPeople[id] = true
	}
	faces, err := q.ListMemoryFaces(ctx, user)
	if err != nil {
		return err
	}
	blocked := map[pgtype.UUID]bool{}
	for i := range faces {
		if blockedPeople[faces[i].PersonID] {
			blocked[faces[i].AssetID] = true
		}
	}
	allowed := assets[:0:0]
	for _, a := range assets {
		if !blocked[a.id] {
			allowed = append(allowed, a)
		}
	}
	byPerson := map[pgtype.UUID][]*memoryAsset{}
	for i := range faces {
		if a := byID[faces[i].AssetID]; a != nil && !blocked[a.id] {
			byPerson[faces[i].PersonID] = append(byPerson[faces[i].PersonID], a)
		}
	}

	found, err := q.ListMemoryPeople(ctx, user)
	if err != nil {
		return err
	}
	people := make([]memoryPersonRow, 0, len(found))
	for _, person := range found {
		if blockedPeople[person.ID] {
			continue
		}
		people = append(people, memoryPersonRow{id: person.ID, name: person.Name, birth: person.BirthDate})
	}

	memories := personMemories(people, byPerson, day)
	memories = append(memories, tripMemories(allowed, day)...)
	memories = append(memories, monthAgoMemory(allowed, day)...)
	memories = append(memories, yearMemory(allowed, day)...)

	return pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		qtx := q.WithTx(tx)
		if err := qtx.ClearComputedMemories(ctx, user); err != nil {
			return err
		}
		for i := range memories {
			memory := &memories[i]
			params, err := json.Marshal(memory.params)
			if err != nil {
				return err
			}
			if err := qtx.UpsertMemory(ctx, db.UpsertMemoryParams{
				UserID: user, Kind: memory.kind, Key: memory.key, Title: memory.title, TitleParams: params,
				Items: memory.items, Rank: memory.rank,
				ShownFrom:  pgtype.Date{Time: memory.from, Valid: true},
				ShownUntil: pgtype.Date{Time: memory.to, Valid: true},
			}); err != nil {
				return err
			}
		}
		return qtx.SetMemoryRun(ctx, db.SetMemoryRunParams{UserID: user, ComputedFor: pgtype.Date{Time: day, Valid: true}})
	})
}
