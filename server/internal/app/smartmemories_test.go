package app

import (
	"context"
	"fmt"
	"net/http"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgtype"

	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

func (s *stack) placePhoto(t *testing.T, id, city string, lat, lon float64) {
	t.Helper()
	s.exec(t, `INSERT INTO exif (asset_id, city, country, latitude, longitude, raw) VALUES ($1, $2, 'HR', $3, $4, '{}')
		ON CONFLICT (asset_id) DO UPDATE SET city = $2, country = 'HR', latitude = $3, longitude = $4`, id, city, lat, lon)
}

func (s *stack) namedPerson(t *testing.T, owner, name, birth string) string {
	t.Helper()
	var id pgtype.UUID
	if birth == "" {
		if err := s.pool.QueryRow(context.Background(), `INSERT INTO people (user_id, name) VALUES ($1, $2) RETURNING id`, owner, name).Scan(&id); err != nil {
			t.Fatal(err)
		}
	} else if err := s.pool.QueryRow(context.Background(), `INSERT INTO people (user_id, name, birth_date) VALUES ($1, $2, $3) RETURNING id`, owner, name, birth).Scan(&id); err != nil {
		t.Fatal(err)
	}
	return fmt.Sprintf("%x-%x-%x-%x-%x", id.Bytes[0:4], id.Bytes[4:6], id.Bytes[6:8], id.Bytes[8:10], id.Bytes[10:16])
}

func (s *stack) tagFace(t *testing.T, owner, asset, person string) {
	t.Helper()
	s.exec(t, `INSERT INTO faces (asset_id, user_id, person_id, x1, y1, x2, y2, score, embedding)
		VALUES ($1, $2, $3, 0, 0, 1, 1, 1, array_fill(0.5::real, ARRAY[512])::vector)`, asset, owner, person)
}

// compute runs the daily job for a day and returns what the page would get.
func (s *stack) compute(t *testing.T, c *client, user, day string) []api.Memory {
	t.Helper()
	at, err := time.Parse(time.DateOnly, day)
	if err != nil {
		t.Fatal(err)
	}
	var id pgtype.UUID
	if err := id.Scan(user); err != nil {
		t.Fatal(err)
	}
	if err := jobs.ComputeMemories(context.Background(), s.pool, id, at); err != nil {
		t.Fatal(err)
	}
	resp, body := c.get("/api/memories?smart=true&date=" + day)
	expect(t, resp, body, http.StatusOK)
	return decode[[]api.Memory](t, body)
}

func onlyKind(memories []api.Memory, kind api.MemoryKind) []api.Memory {
	out := []api.Memory{}
	for _, memory := range memories {
		if memory.Kind == kind {
			out = append(out, memory)
		}
	}
	return out
}

func TestTripIsDaysFarFromTheHomeWithTheMostPhotos(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	user := s.userID("admin@example.com")
	const lat, lon = 45.81, 15.98
	for i := range 12 {
		id := c.newPhoto(t, fmt.Sprintf("home%d.jpg", i), fmt.Sprintf("2024-03-%02dT10:00:00Z", i+1))
		s.placePhoto(t, id, "Zagreb", lat, lon)
	}
	// Three days in Split: the trip.
	for i := range 6 {
		id := c.newPhoto(t, fmt.Sprintf("split%d.jpg", i), fmt.Sprintf("2024-07-%02dT10:00:00Z", 3+i%3))
		s.placePhoto(t, id, "Split", 43.51, 16.44)
	}
	// A day trip nearby and a single day away are not trips.
	for i := range 6 {
		id := c.newPhoto(t, fmt.Sprintf("near%d.jpg", i), fmt.Sprintf("2024-08-%02dT10:00:00Z", 10+i%2))
		s.placePhoto(t, id, "Samobor", 45.80, 15.71)
	}
	for i := range 6 {
		id := c.newPhoto(t, fmt.Sprintf("once%d.jpg", i), "2024-09-20T10:00:00Z")
		s.placePhoto(t, id, "Rijeka", 45.33, 14.44)
	}

	trips := onlyKind(s.compute(t, c, user, "2024-07-08"), api.MemoryKindTrip)
	if len(trips) != 1 || *trips[0].TitleParams.Place != "Split" || *trips[0].TitleParams.Month != 7 || *trips[0].TitleParams.Year != 2024 || len(trips[0].Items) != 6 {
		t.Fatalf("right after: %+v", trips)
	}
	// Its anniversary.
	if trips := onlyKind(s.compute(t, c, user, "2025-07-05"), api.MemoryKindTrip); len(trips) != 1 {
		t.Fatalf("a year later: %+v", trips)
	}
	if trips := onlyKind(s.compute(t, c, user, "2025-10-01"), api.MemoryKindTrip); len(trips) != 0 {
		t.Fatalf("no reason to show it now: %+v", trips)
	}
}

func TestNothingHiddenEverEntersAMemory(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	user := s.userID("admin@example.com")
	const day = "2024-05-10T10:00:00Z"
	keep := []string{c.newPhoto(t, "a.jpg", day), c.newPhoto(t, "b.jpg", day), c.newPhoto(t, "c.jpg", day)}
	rejected := c.newPhoto(t, "rejected.jpg", day)
	s.exec(t, `UPDATE assets SET pick = -1 WHERE id = $1`, rejected)
	screenshot := c.newPhoto(t, "Screenshot 1.jpg", day)
	archived := c.newPhoto(t, "archived.jpg", day)
	s.exec(t, `UPDATE assets SET archived_at = now() WHERE id = $1`, archived)
	vaulted := c.newPhoto(t, "vault.jpg", day)
	s.exec(t, `UPDATE assets SET vault_at = now() WHERE id = $1`, vaulted)
	trashed := c.newPhoto(t, "trash.jpg", day)
	c.bulk(t, "delete", trashed)
	copyOf := c.newPhoto(t, "copy.jpg", day)
	first, second := keep[0], copyOf
	if first > second {
		first, second = second, first
	}
	s.exec(t, `INSERT INTO similar_pairs (a_id, b_id, user_id) VALUES ($1, $2, $3)`, first, second, user)
	banned := map[string]bool{rejected: true, screenshot: true, archived: true, vaulted: true, trashed: true}
	banned[second] = true

	months := onlyKind(s.compute(t, c, user, "2024-06-10"), api.MemoryKindMonthAgo)
	if len(months) != 1 {
		t.Fatalf("a month ago: %+v", months)
	}
	for _, item := range months[0].Items {
		if banned[item.Id.String()] {
			t.Fatalf("%s should not be here", item.Id)
		}
	}
	// The same for "on this day", which is worked out when asked.
	resp, body := c.get("/api/memories?date=2025-05-10")
	expect(t, resp, body, http.StatusOK)
	for _, item := range decode[[]api.Memory](t, body)[0].Items {
		if banned[item.Id.String()] {
			t.Fatalf("on this day: %s", item.Id)
		}
	}
	// A photo trashed after the job ran leaves at once.
	c.bulk(t, "delete", keep[2])
	resp, body = c.get("/api/memories?smart=true&date=2024-06-10")
	expect(t, resp, body, http.StatusOK)
	for _, item := range onlyKind(decode[[]api.Memory](t, body), api.MemoryKindMonthAgo)[0].Items {
		if item.Id.String() == keep[2] {
			t.Fatal("still shows a photo that is in the trash")
		}
	}
}

func TestFavoritesAndRatingsLeadThePicture(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	user := s.userID("admin@example.com")
	best := []string{}
	for i := range 40 {
		id := c.newPhoto(t, fmt.Sprintf("p%d.jpg", i), "2024-05-10T10:00:00Z")
		if i < 3 {
			s.exec(t, `UPDATE assets SET is_favorite = true WHERE id = $1`, id)
			best = append(best, id)
		}
	}
	months := onlyKind(s.compute(t, c, user, "2024-06-10"), api.MemoryKindMonthAgo)
	if len(months) != 1 || len(months[0].Items) != 30 {
		t.Fatalf("%+v", months)
	}
	seen := map[string]bool{}
	for _, item := range months[0].Items {
		seen[item.Id.String()] = true
	}
	for _, id := range best {
		if !seen[id] {
			t.Fatalf("favorite %s left out", id)
		}
	}
}

func TestAPersonThroughTheYears(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	user := s.userID("admin@example.com")
	person := s.namedPerson(t, user, "Ana", "")
	for year := 2020; year < 2024; year++ {
		for i := range 2 {
			id := c.newPhoto(t, fmt.Sprintf("a%d-%d.jpg", year, i), fmt.Sprintf("%d-04-%02dT10:00:00Z", year, i+1))
			s.tagFace(t, user, id, person)
		}
	}
	got := onlyKind(s.compute(t, c, user, "2024-11-06"), api.MemoryKindPersonYears)
	if len(got) != 1 || *got[0].TitleParams.Person != "Ana" || len(got[0].Items) != 8 {
		t.Fatalf("%+v", got)
	}
	if got[0].TitleParams.PersonId == nil || got[0].TitleParams.PersonId.String() != person {
		t.Fatalf("no person id: %+v", got[0].TitleParams)
	}
}

func TestBirthdayNeedsADateOfBirth(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	user := s.userID("admin@example.com")
	withDate := s.namedPerson(t, user, "Mia", "1990-11-06")
	without := s.namedPerson(t, user, "Ivo", "")
	for i := range 3 {
		id := c.newPhoto(t, fmt.Sprintf("m%d.jpg", i), fmt.Sprintf("2022-06-%02dT10:00:00Z", i+1))
		s.tagFace(t, user, id, withDate)
		other := c.newPhoto(t, fmt.Sprintf("i%d.jpg", i), fmt.Sprintf("2022-07-%02dT10:00:00Z", i+1))
		s.tagFace(t, user, other, without)
	}
	got := onlyKind(s.compute(t, c, user, "2024-11-06"), api.MemoryKindBirthday)
	if len(got) != 1 || *got[0].TitleParams.Person != "Mia" {
		t.Fatalf("%+v", got)
	}
	if got := onlyKind(s.compute(t, c, user, "2024-11-07"), api.MemoryKindBirthday); len(got) != 0 {
		t.Fatalf("the day after: %+v", got)
	}
}

func TestYearInPhotosComesInJanuary(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	user := s.userID("admin@example.com")
	for i := range 12 {
		c.newPhoto(t, fmt.Sprintf("y%d.jpg", i), fmt.Sprintf("2024-%02d-10T10:00:00Z", i+1))
	}
	got := onlyKind(s.compute(t, c, user, "2025-01-15"), api.MemoryKindYearReview)
	if len(got) != 1 || *got[0].TitleParams.Year != 2024 || len(got[0].Items) != 12 {
		t.Fatalf("%+v", got)
	}
	if got := onlyKind(s.compute(t, c, user, "2025-02-15"), api.MemoryKindYearReview); len(got) != 0 {
		t.Fatalf("February: %+v", got)
	}
}

func TestAMonthAgo(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	user := s.userID("admin@example.com")
	for i := range 3 {
		c.newPhoto(t, fmt.Sprintf("m%d.jpg", i), "2024-03-30T10:00:00Z")
	}
	got := onlyKind(s.compute(t, c, user, "2024-04-30"), api.MemoryKindMonthAgo)
	if len(got) != 1 || got[0].Key != "2024-03-30" {
		t.Fatalf("a month before: %+v", got)
	}
	if got := onlyKind(s.compute(t, c, user, "2024-05-30"), api.MemoryKindMonthAgo); len(got) != 0 {
		t.Fatalf("not that day: %+v", got)
	}
	// A short month: from March 31st the month before ends on the 29th of February.
	for i := range 3 {
		c.newPhoto(t, fmt.Sprintf("f%d.jpg", i), "2024-02-29T10:00:00Z")
	}
	got = onlyKind(s.compute(t, c, user, "2024-03-31"), api.MemoryKindMonthAgo)
	if len(got) != 1 || got[0].Key != "2024-02-29" {
		t.Fatalf("clamped: %+v", got)
	}
}

func TestHidingIsRememberedAcrossRuns(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	user := s.userID("admin@example.com")
	other := s.user(c, "other@example.com")
	for i := range 3 {
		c.newPhoto(t, fmt.Sprintf("m%d.jpg", i), "2024-05-10T10:00:00Z")
	}
	got := onlyKind(s.compute(t, c, user, "2024-06-10"), api.MemoryKindMonthAgo)
	if len(got) != 1 {
		t.Fatalf("%+v", got)
	}
	resp, body := c.send(http.MethodPut, "/api/memories/hidden", map[string]any{"kind": "month_ago", "key": got[0].Key, "hidden": true})
	expect(t, resp, body, http.StatusNoContent)
	if got := onlyKind(s.compute(t, c, user, "2024-06-10"), api.MemoryKindMonthAgo); len(got) != 0 {
		t.Fatalf("came back: %+v", got)
	}
	// Someone else's list is untouched by this and their hide does not reach here.
	resp, body = other.send(http.MethodPut, "/api/memories/hidden", map[string]any{"kind": "month_ago", "key": "x", "hidden": true})
	expect(t, resp, body, http.StatusNoContent)
	// Live memories are hidden the same way.
	resp, body = c.get("/api/memories?date=2025-05-10")
	expect(t, resp, body, http.StatusOK)
	live := decode[[]api.Memory](t, body)
	resp, body = c.send(http.MethodPut, "/api/memories/hidden", map[string]any{"kind": "on_this_day", "key": live[0].Key, "hidden": true})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = c.get("/api/memories?date=2025-05-10")
	expect(t, resp, body, http.StatusOK)
	if left := decode[[]api.Memory](t, body); len(left) != 0 {
		t.Fatalf("still there: %s", body)
	}
	resp, body = c.get("/api/memories/hidden")
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.HiddenMemories](t, body); got.Count != 2 {
		t.Fatalf("%s", body)
	}
	resp, body = c.send(http.MethodDelete, "/api/memories/hidden", nil)
	expect(t, resp, body, http.StatusNoContent)
	if got := onlyKind(s.compute(t, c, user, "2024-06-10"), api.MemoryKindMonthAgo); len(got) != 1 {
		t.Fatalf("restored: %+v", got)
	}
}

func TestAHiddenPersonLeavesEveryMemory(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	user := s.userID("admin@example.com")
	stranger := s.user(c, "stranger@example.com")
	person := s.namedPerson(t, user, "Ana", "")
	withPerson := ""
	for year := 2020; year < 2024; year++ {
		for i := range 2 {
			id := c.newPhoto(t, fmt.Sprintf("a%d-%d.jpg", year, i), fmt.Sprintf("%d-05-10T10:00:00Z", year))
			s.tagFace(t, user, id, person)
			withPerson = id
		}
	}
	c.newPhoto(t, "plain.jpg", "2023-05-10T11:00:00Z")
	c.newPhoto(t, "plain2.jpg", "2023-05-10T12:00:00Z")
	c.newPhoto(t, "plain3.jpg", "2023-05-10T13:00:00Z")

	if got := onlyKind(s.compute(t, c, user, "2024-11-06"), api.MemoryKindPersonYears); len(got) != 1 {
		t.Fatalf("%+v", got)
	}
	resp, body := stranger.send(http.MethodPut, "/api/memories/hidden-people", map[string]any{"personId": person, "hidden": true})
	expect(t, resp, body, http.StatusNotFound)

	resp, body = c.send(http.MethodPut, "/api/memories/hidden-people", map[string]any{"personId": person, "hidden": true})
	expect(t, resp, body, http.StatusNoContent)
	if got := onlyKind(s.compute(t, c, user, "2024-11-06"), api.MemoryKindPersonYears); len(got) != 0 {
		t.Fatalf("still shown: %+v", got)
	}
	resp, body = c.get("/api/memories?smart=true&date=2024-06-10")
	expect(t, resp, body, http.StatusOK)
	for _, memory := range decode[[]api.Memory](t, body) {
		for _, item := range memory.Items {
			if item.Id.String() == withPerson {
				t.Fatalf("%s in %s", withPerson, memory.Kind)
			}
		}
	}
	// On this day too: the photos with her are gone, the plain ones stay.
	resp, body = c.get("/api/memories?date=2024-05-10")
	expect(t, resp, body, http.StatusOK)
	got := decode[[]api.Memory](t, body)
	if len(got) != 1 || *got[0].Year != 2023 || len(got[0].Items) != 3 {
		t.Fatalf("on this day: %s", body)
	}
	resp, body = c.get("/api/memories/hidden")
	expect(t, resp, body, http.StatusOK)
	if listed := decode[api.HiddenMemories](t, body); len(listed.People) != 1 || listed.People[0].Name != "Ana" {
		t.Fatalf("%s", body)
	}
	resp, body = c.send(http.MethodPut, "/api/memories/hidden-people", map[string]any{"personId": person, "hidden": false})
	expect(t, resp, body, http.StatusNoContent)
	if got := onlyKind(s.compute(t, c, user, "2024-11-06"), api.MemoryKindPersonYears); len(got) != 1 {
		t.Fatalf("back: %+v", got)
	}
}

func TestAKindCanBeTurnedOff(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	user := s.userID("admin@example.com")
	for i := range 3 {
		c.newPhoto(t, fmt.Sprintf("m%d.jpg", i), "2024-05-10T10:00:00Z")
	}
	if got := onlyKind(s.compute(t, c, user, "2024-06-10"), api.MemoryKindMonthAgo); len(got) != 1 {
		t.Fatalf("%+v", got)
	}
	resp, body := c.get("/api/me/preferences")
	expect(t, resp, body, http.StatusOK)
	prefs := decode[api.UserPreferences](t, body)
	off := []api.UserPreferencesMemoryKindsOff{api.UserPreferencesMemoryKindsOffMonthAgo}
	prefs.MemoryKindsOff = &off
	resp, body = c.send(http.MethodPut, "/api/me/preferences", prefs)
	expect(t, resp, body, http.StatusOK)
	resp, body = c.get("/api/memories?smart=true&date=2024-06-10")
	expect(t, resp, body, http.StatusOK)
	if len(onlyKind(decode[[]api.Memory](t, body), api.MemoryKindMonthAgo)) != 0 {
		t.Fatalf("off is off: %s", body)
	}
	bad := []api.UserPreferencesMemoryKindsOff{"nonsense"}
	prefs.MemoryKindsOff = &bad
	resp, body = c.send(http.MethodPut, "/api/me/preferences", prefs)
	expect(t, resp, body, http.StatusBadRequest)
}

func TestAnOldClientGetsOnlyTheKindsItKnows(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	user := s.userID("admin@example.com")
	for i := range 3 {
		c.newPhoto(t, fmt.Sprintf("m%d.jpg", i), "2024-05-10T10:00:00Z")
	}
	s.compute(t, c, user, "2024-06-10")
	resp, body := c.get("/api/memories?date=2024-06-10")
	expect(t, resp, body, http.StatusOK)
	if len(onlyKind(decode[[]api.Memory](t, body), api.MemoryKindMonthAgo)) != 0 {
		t.Fatalf("%s", body)
	}
}
