package app

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"os/exec"
	"strings"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgtype"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
	"github.com/mediarr-app/mediarr/server/internal/ml"
)

// Vectors that point in clearly different directions, for a service that always answers the same.
func axis(size, index int) []float32 {
	out := make([]float32, size)
	out[index] = 1
	return out
}

const (
	clipSize = 768
	faceSize = 512
)

// fakeML stands in for the service: a picture's bytes decide what it "shows".
func fakeML(t *testing.T) *httptest.Server {
	t.Helper()
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		data, err := io.ReadAll(r.Body)
		if err != nil {
			t.Error(err)
		}
		content := string(data)
		var out any
		switch r.URL.Path {
		case "/clip/image":
			index := 0
			if strings.Contains(content, "beach") {
				index = 1
			}
			out = map[string]any{"embedding": axis(clipSize, index)}
		case "/clip/text":
			index := 0
			if strings.Contains(strings.ToLower(content), "pla") || strings.Contains(content, "beach") {
				index = 1
			}
			out = map[string]any{"embedding": axis(clipSize, index)}
		case "/faces":
			faces := []map[string]any{}
			if strings.Contains(content, "ana") {
				faces = append(faces, map[string]any{"box": []float32{10, 10, 110, 110}, "score": 0.9, "embedding": axis(faceSize, 1)})
			}
			if strings.Contains(content, "marko") {
				faces = append(faces, map[string]any{"box": []float32{200, 10, 300, 110}, "score": 0.9, "embedding": axis(faceSize, 2)})
			}
			// "left" and "right" are too far apart for one person, and "bridge" is close to both.
			if strings.Contains(content, "left") {
				faces = append(faces, map[string]any{"box": []float32{10, 10, 110, 110}, "score": 0.9, "embedding": facePair(1, 0)})
			}
			if strings.Contains(content, "right") {
				faces = append(faces, map[string]any{"box": []float32{200, 10, 300, 110}, "score": 0.9, "embedding": facePair(0.1, 0.995)})
			}
			if strings.Contains(content, "bridge") {
				faces = append(faces, map[string]any{"box": []float32{400, 10, 500, 110}, "score": 0.9, "embedding": facePair(1.1, 0.995)})
			}
			if strings.Contains(content, "tiny") {
				faces = append(faces, map[string]any{"box": []float32{1, 1, 11, 11}, "score": 0.9, "embedding": axis(faceSize, 3)})
			}
			out = map[string]any{"faces": faces}
		case "/ocr":
			text := ""
			if strings.Contains(content, "receipt") {
				text = "Konzum račun 42"
			}
			out = map[string]any{"text": text}
		default:
			http.NotFound(w, r)
			return
		}
		if err := json.NewEncoder(w).Encode(out); err != nil {
			t.Error(err)
		}
	}))
	t.Cleanup(server.Close)
	return server
}

// analyzed uploads a picture whose content tells the fake service what to find.
func (s *stack) analyzed(t *testing.T, c *client, service *httptest.Server, name, taken, content string) string {
	t.Helper()
	id := c.newPhoto(t, name, taken)
	var path string
	if err := s.pool.QueryRow(context.Background(), `SELECT path FROM asset_files WHERE asset_id = $1 AND kind = 'thumb_large'`, id).Scan(&path); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte(content), 0o600); err != nil {
		t.Fatal(err)
	}
	var asset pgtype.UUID
	if err := asset.Scan(id); err != nil {
		t.Fatal(err)
	}
	if err := jobs.AnalyzeAsset(context.Background(), s.pool, db.New(s.pool), ml.New(service.URL, ""), asset); err != nil {
		t.Fatal(err)
	}
	return id
}

// useML turns the service on from here on, as setting ML_URL does in an installation.
func (s *stack) useML(t *testing.T, service *httptest.Server) {
	t.Helper()
	s.useMLAt(t, service.URL, "")
}

func (s *stack) useMLAt(t *testing.T, url, token string) {
	t.Helper()
	inserter, err := jobs.NewInserter(s.pool)
	if err != nil {
		t.Fatal(err)
	}
	handler, err := NewHandler(Deps{
		Pinger: db.New(s.pool), Pool: s.pool, Inserter: inserter,
		LibraryPath: s.library, CachePath: s.cache, MLURL: url, MLToken: token,
	})
	if err != nil {
		t.Fatal(err)
	}
	server := httptest.NewServer(handler)
	t.Cleanup(server.Close)
	s.url = server.URL
}

func TestParseQuery(t *testing.T) {
	terms := []searchTerm{
		{kind: "person", value: "Ana Horvat", ref: "1"},
		{kind: "person", value: "Marko", ref: "2"},
		{kind: "place", value: "Zagreb"},
		{kind: "place", value: "Hvar"},
		{kind: "camera", value: "iPhone 15"},
	}
	cases := []struct {
		query, words, place, camera, person string
		year                                int
		month                               time.Month
	}{
		{query: "pas na plaži", words: "pas na plaži"},
		{query: "pas na plaži 2024", words: "pas na plaži", year: 2024},
		{query: "more u srpnju 2023", words: "more u", year: 2023, month: time.July},
		{query: "beach in July", words: "beach in", month: time.July},
		{query: "fotke iz Zagreba", words: "fotke iz", place: "Zagreb"},
		{query: "Ana Horvat na Hvaru", words: "na", person: "Ana Horvat", place: "Hvar"},
		{query: "Marko iphone 15 2020", person: "Marko", camera: "iPhone 15", year: 2020},
		{query: "Marku rođendan", words: "rođendan", person: "Marko"},
		// An ordinary short word is not a name that merely starts the same way.
		{query: "mar", words: "mar"},
		{query: "račun 42", words: "račun 42"},
	}
	for _, tc := range cases {
		got := parseQuery(tc.query, terms)
		person := ""
		if got.person != nil {
			person = got.person.value
		}
		if got.words != tc.words || got.place != tc.place || got.camera != tc.camera || person != tc.person || got.year != tc.year || got.month != tc.month {
			t.Errorf("%q: %+v, person %q", tc.query, got, person)
		}
	}
}

func TestMonthAloneIsTheLastOneWithThatName(t *testing.T) {
	now := time.Date(2026, time.March, 5, 0, 0, 0, 0, time.UTC)
	later := parsedQuery{month: time.July}
	from, to := later.dateRange(now)
	if from.Time.Year() != 2025 || to.Time.Month() != time.August {
		t.Fatalf("%v %v", from.Time, to.Time)
	}
	earlier := parsedQuery{month: time.February}
	from, _ = earlier.dateRange(now)
	if from.Time.Year() != 2026 {
		t.Fatalf("%v", from.Time)
	}
	none := parsedQuery{}
	if from, _ = none.dateRange(now); from.Valid {
		t.Fatal("a date from nothing")
	}
}

func TestLikePatternTakesWordsLiterally(t *testing.T) {
	if got := likePattern(`50%_a\b`); got != `%50\%\_a\\b%` {
		t.Fatalf("%s", got)
	}
}

func TestMergeRanksFavoursAgreement(t *testing.T) {
	id := func(b byte) pgtype.UUID { return pgtype.UUID{Bytes: [16]byte{b}, Valid: true} }
	got := mergeRanks(3, []pgtype.UUID{id(1), id(2), id(3)}, []pgtype.UUID{id(3), id(4), id(2)})
	if len(got) != 3 || got[0] != id(3) {
		t.Fatalf("%v", got)
	}
}

// facePair is a face vector with two values, which decide how close it is to another.
func facePair(first, second float32) []float32 {
	out := make([]float32, faceSize)
	out[10], out[11] = first, second
	return out
}

func peopleNamed(t *testing.T, c *client) []api.Person {
	t.Helper()
	resp, body := c.get("/api/people")
	expect(t, resp, body, http.StatusOK)
	return decode[api.PeopleList](t, body).People
}

func TestAFaceBetweenTwoPeopleMakesThemOne(t *testing.T) {
	service := fakeML(t)
	s := newStack(t)
	c := s.admin()
	s.analyzed(t, c, service, "1.jpg", "2024-01-01T10:00:00Z", "left")
	s.analyzed(t, c, service, "2.jpg", "2024-01-02T10:00:00Z", "left again")
	s.analyzed(t, c, service, "3.jpg", "2024-01-03T10:00:00Z", "right")
	s.analyzed(t, c, service, "4.jpg", "2024-01-04T10:00:00Z", "right again")
	if got := peopleNamed(t, c); len(got) != 2 {
		t.Fatalf("before the bridge: %+v", got)
	}
	// A smart album that follows one of them must not lose its photos.
	follower := got0(t, peopleNamed(t, c))
	album := c.newAlbum(map[string]any{"title": "Follows", "rules": map[string]string{"person": follower}})

	s.analyzed(t, c, service, "5.jpg", "2024-01-05T10:00:00Z", "bridge")
	got := peopleNamed(t, c)
	if len(got) != 1 || got[0].AssetCount != 5 {
		t.Fatalf("after the bridge: %+v", got)
	}
	resp, body := c.get("/api/albums/" + album)
	expect(t, resp, body, http.StatusOK)
	if decode[api.Album](t, body).AssetCount != 5 {
		t.Fatalf("the album lost the person: %s", body)
	}
}

func got0(t *testing.T, people []api.Person) string {
	t.Helper()
	if len(people) == 0 {
		t.Fatal("nobody found")
	}
	return people[0].Id.String()
}

func TestOnlyTheUserMergesWhomTheyNamed(t *testing.T) {
	service := fakeML(t)
	s := newStack(t)
	c := s.admin()
	s.analyzed(t, c, service, "1.jpg", "2024-01-01T10:00:00Z", "left")
	s.analyzed(t, c, service, "2.jpg", "2024-01-02T10:00:00Z", "left again")
	s.analyzed(t, c, service, "3.jpg", "2024-01-03T10:00:00Z", "right")
	s.analyzed(t, c, service, "4.jpg", "2024-01-04T10:00:00Z", "right again")
	for i, person := range peopleNamed(t, c) {
		resp, body := c.send(http.MethodPatch, "/api/people/"+person.Id.String(), map[string]string{"name": []string{"Ana", "Eva"}[i]})
		expect(t, resp, body, http.StatusNoContent)
	}
	s.analyzed(t, c, service, "5.jpg", "2024-01-05T10:00:00Z", "bridge")
	if got := peopleNamed(t, c); len(got) != 2 {
		t.Fatalf("%+v", got)
	}
}

func TestPeopleInOnePhotoAreNotMerged(t *testing.T) {
	service := fakeML(t)
	s := newStack(t)
	c := s.admin()
	s.analyzed(t, c, service, "1.jpg", "2024-01-01T10:00:00Z", "left right")
	s.analyzed(t, c, service, "2.jpg", "2024-01-02T10:00:00Z", "left again")
	s.analyzed(t, c, service, "3.jpg", "2024-01-03T10:00:00Z", "right again")
	s.analyzed(t, c, service, "4.jpg", "2024-01-05T10:00:00Z", "bridge")
	if got := peopleNamed(t, c); len(got) != 2 {
		t.Fatalf("%+v", got)
	}
}

func TestSearchAndPeople(t *testing.T) {
	service := fakeML(t)
	s := newStack(t)
	c := s.admin()
	other := s.user(c, "other@example.com")
	beach := s.analyzed(t, c, service, "IMG_1.jpg", "2024-07-10T10:00:00Z", "beach ana")
	office := s.analyzed(t, c, service, "IMG_2.jpg", "2023-02-10T10:00:00Z", "office ana marko")
	receipt := s.analyzed(t, c, service, "racun.jpg", "2022-02-10T10:00:00Z", "receipt tiny")
	foreign := s.analyzed(t, other, service, "foreign.jpg", "2024-07-11T10:00:00Z", "beach ana")

	// Faces are per user, and a stray small face or one seen once is not listed.
	resp, body := c.get("/api/people")
	expect(t, resp, body, http.StatusOK)
	people := decode[api.PeopleList](t, body)
	if len(people.People) != 1 || people.People[0].AssetCount != 2 || people.People[0].Name != "" {
		t.Fatalf("people: %s", body)
	}
	person := people.People[0].Id.String()
	resp, body = other.get("/api/people/" + person + "/buckets")
	expect(t, resp, body, http.StatusNotFound)
	resp, body = other.send(http.MethodPatch, "/api/people/"+person, map[string]string{"name": "Mine"})
	expect(t, resp, body, http.StatusNotFound)

	resp, body = c.send(http.MethodPatch, "/api/people/"+person, map[string]string{"name": "Ana"})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = c.get("/api/people/" + person + "/buckets/2024-07")
	expect(t, resp, body, http.StatusOK)
	if items := decode[api.TimelineBucket](t, body).Items; len(items) != 1 || items[0].Id.String() != beach {
		t.Fatalf("person's photos: %s", body)
	}
	resp, body = c.get("/api/assets/" + office)
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.AssetDetail](t, body).People; got == nil || len(*got) != 1 || (*got)[0].Name != "Ana" {
		t.Fatalf("detail: %s", body)
	}

	// Names stay private, even for someone the photo is shared with.
	album := c.newAlbum(map[string]any{"title": "Shared"})
	resp, body = c.post("/api/albums/"+album+"/assets", api.AssetIds{Ids: uuids(t, office)})
	expect(t, resp, body, http.StatusOK)
	resp, body = c.send(http.MethodPut, "/api/albums/"+album+"/members/"+s.userID("other@example.com"), map[string]string{"role": "viewer"})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = other.get("/api/assets/" + office)
	expect(t, resp, body, http.StatusOK)
	if decode[api.AssetDetail](t, body).People != nil {
		t.Fatalf("names shown to a member: %s", body)
	}

	search := func(c *client, query string) api.SearchResult {
		t.Helper()
		resp, body := c.get("/api/search?q=" + strings.ReplaceAll(query, " ", "%20"))
		expect(t, resp, body, http.StatusOK)
		return decode[api.SearchResult](t, body)
	}
	first := func(result api.SearchResult) string {
		t.Helper()
		if len(result.Items) == 0 {
			t.Fatal("nothing found")
		}
		return result.Items[0].Id.String()
	}
	// The handler in this stack has no service: words on pictures and file names still work.
	got := search(c, "Konzum")
	if got.Smart || len(got.Items) != 1 || first(got) != receipt {
		t.Fatalf("words on a picture: %+v", got)
	}
	if first(search(c, "racun.jpg")) != receipt {
		t.Fatal("file name")
	}
	// Filters alone need no service at all.
	got = search(c, "Ana 2024")
	if len(got.Items) != 1 || first(got) != beach || got.Filters.Person == nil || *got.Filters.Person != "Ana" {
		t.Fatalf("person and year: %+v", got)
	}

	// With the service, a meaning is found, and only in one's own library.
	s.useML(t, service)
	got = search(c, "beach")
	if !got.Smart || first(got) != beach {
		t.Fatalf("meaning: %+v", got)
	}
	for _, item := range got.Items {
		if item.Id.String() == foreign {
			t.Fatal("someone else's photo in the results")
		}
	}
	got = search(c, "beach 2023")
	if len(got.Items) != 1 || first(got) != office {
		t.Fatalf("a filter limits what is found: %+v", got)
	}

	// Trash and vault are not searched.
	c.bulk(t, "delete", beach)
	for _, item := range search(c, "beach").Items {
		if item.Id.String() == beach {
			t.Fatal("found in the trash")
		}
	}
	resp, body = c.get("/api/search?q=%20")
	expect(t, resp, body, http.StatusBadRequest)

	// A smart album can follow a person.
	smart := c.newAlbum(map[string]any{"title": "Ana", "rules": map[string]any{"person": person}})
	resp, body = c.get("/api/albums/" + smart)
	expect(t, resp, body, http.StatusOK)
	if decode[api.Album](t, body).AssetCount != 1 {
		t.Fatalf("smart album by person: %s", body)
	}

	// Merging and hiding.
	stray := s.analyzed(t, c, service, "IMG_3.jpg", "2021-01-01T10:00:00Z", "marko")
	resp, body = c.get("/api/people")
	expect(t, resp, body, http.StatusOK)
	people = decode[api.PeopleList](t, body)
	if len(people.People) != 2 || stray == "" {
		t.Fatalf("after a second photo of someone: %s", body)
	}
	var marko string
	for _, candidate := range people.People {
		if candidate.Id.String() != person {
			marko = candidate.Id.String()
		}
	}
	resp, body = c.post("/api/people/"+person+"/merge", api.AssetIds{Ids: uuids(t, person)})
	expect(t, resp, body, http.StatusBadRequest)
	resp, body = c.post("/api/people/"+person+"/merge", api.AssetIds{Ids: uuids(t, marko)})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = c.get("/api/people")
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.PeopleList](t, body).People; len(got) != 1 || got[0].Id.String() != person {
		t.Fatalf("after merging: %s", body)
	}
	resp, body = c.send(http.MethodPatch, "/api/people/"+person, map[string]bool{"hidden": true})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = c.get("/api/assets/" + office)
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.AssetDetail](t, body).People; got != nil && len(*got) != 0 {
		t.Fatalf("a hidden person is shown: %s", body)
	}

	// Progress is for administrators.
	resp, body = other.get("/api/admin/analysis")
	expect(t, resp, body, http.StatusForbidden)
	resp, body = c.get("/api/admin/analysis")
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.AnalysisProgress](t, body); got.Analyzed == 0 {
		t.Fatalf("progress: %s", body)
	}
}

func TestPersonThumbnailIsAReadableCrop(t *testing.T) {
	if _, err := exec.LookPath("vips"); err != nil {
		t.Skip("media tools are not installed; run through `make test`")
	}
	ctx := context.Background()
	dir := t.TempDir()
	source := dir + "/source.webp"
	cmd := exec.CommandContext(ctx, "vips", "black", source, "800", "600")
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("%v: %s", err, out)
	}
	dest := dir + "/faces/crop.webp"
	// A face against the edge must not push the crop outside the picture.
	if err := jobs.CropFace(ctx, source, dest, 700, 500, 790, 590); err != nil {
		t.Fatal(err)
	}
	info, err := os.Stat(dest)
	if err != nil || info.Size() == 0 {
		t.Fatalf("%v, %v", info, err)
	}
}

func TestMergingPeopleKeepsWhatAnImportRemembers(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	ctx := context.Background()
	asset := c.newPhoto(t, "a.jpg", "2024-01-01T10:00:00Z")
	var user, keep, merged string
	if err := s.pool.QueryRow(ctx, `SELECT id FROM users LIMIT 1`).Scan(&user); err != nil {
		t.Fatal(err)
	}
	for _, target := range []*string{&keep, &merged} {
		if err := s.pool.QueryRow(ctx, `INSERT INTO people (user_id, name) VALUES ($1, '') RETURNING id`, user).Scan(target); err != nil {
			t.Fatal(err)
		}
	}
	if _, err := s.pool.Exec(ctx, `INSERT INTO import_map (user_id, origin, kind, remote_id, local_id) VALUES ($1, 'x', 'person', 'r', $2)`, user, merged); err != nil {
		t.Fatal(err)
	}
	if _, err := s.pool.Exec(ctx, `INSERT INTO face_hints (asset_id, person_id, x1, y1, x2, y2) VALUES ($1, $2, 0, 0, 1, 1)`, asset, merged); err != nil {
		t.Fatal(err)
	}
	resp, body := c.post("/api/people/"+keep+"/merge", map[string][]string{"ids": {merged}})
	if resp.StatusCode >= http.StatusBadRequest {
		t.Fatalf("%d %s", resp.StatusCode, body)
	}
	var mapped, hinted string
	if err := s.pool.QueryRow(ctx, `SELECT local_id FROM import_map WHERE remote_id = 'r'`).Scan(&mapped); err != nil || mapped != keep {
		t.Fatalf("map: %s, %v", mapped, err)
	}
	if err := s.pool.QueryRow(ctx, `SELECT person_id FROM face_hints WHERE asset_id = $1`, asset).Scan(&hinted); err != nil || hinted != keep {
		t.Fatalf("hint: %s, %v", hinted, err)
	}
}
