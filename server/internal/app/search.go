package app

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"path/filepath"
	"regexp"
	"slices"
	"strconv"
	"strings"
	"sync"
	"time"
	"unicode"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	openapi_types "github.com/oapi-codegen/runtime/types"
	"golang.org/x/text/runes"
	"golang.org/x/text/transform"
	"golang.org/x/text/unicode/norm"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
	"github.com/mediarr-app/mediarr/server/internal/ml"
)

const (
	maxQueryLength   = 500
	searchResultSize = 100
	searchCandidates = 100
	rrfConstant      = 60.0
	minStem          = 4
	stemTail         = 2
	// Long enough for the model to load again after a quiet period, which takes up to about 12 s.
	textDeadline  = 20 * time.Second
	maxPersonName = 100
	termsFresh    = time.Minute
)

var yearWord = regexp.MustCompile(`^(19|20)[0-9]{2}$`)

// Month stems in both languages. A stem also covers Croatian forms such as "srpnju".
var monthStems = []struct {
	stem  string
	month time.Month
}{
	{"sijec", time.January},
	{"januar", time.January},
	{"january", time.January},
	{"veljac", time.February},
	{"februar", time.February},
	{"february", time.February},
	{"ozuj", time.March},
	{"mart", time.March},
	{"march", time.March},
	{"trav", time.April},
	{"april", time.April},
	{"svib", time.May},
	{"maj", time.May},
	{"may", time.May},
	{"lipan", time.June},
	{"lipnj", time.June},
	{"jun", time.June},
	{"srpan", time.July},
	{"srpnj", time.July},
	{"jul", time.July},
	{"kolovoz", time.August},
	{"avgust", time.August},
	{"august", time.August},
	{"rujan", time.September},
	{"rujn", time.September},
	{"septemb", time.September},
	{"listopad", time.October},
	{"oktob", time.October},
	{"octob", time.October},
	{"studen", time.November},
	{"novemb", time.November},
	{"prosin", time.December},
	{"decemb", time.December},
}

// searchTerm is something the library can name: a person, a place or a camera.
type searchTerm struct {
	kind, value, ref string
}

// parsedQuery is a query split into filters and the words left to look for.
type parsedQuery struct {
	words  string
	year   int
	month  time.Month
	person *searchTerm
	place  string
	camera string
}

func foldWord(value string) string {
	strip := transform.Chain(norm.NFD, runes.Remove(runes.In(unicode.Mn)), norm.NFC)
	folded, _, err := transform.String(strip, strings.ToLower(value))
	if err != nil {
		folded = strings.ToLower(value)
	}
	// These letters have no combining mark to remove.
	return strings.NewReplacer("đ", "d", "ß", "ss").Replace(folded)
}

// wordMatches also accepts endings, because Croatian changes words: Zagreb, Zagrebu, Zagrebom.
func wordMatches(word, name string) bool {
	if word == name {
		return true
	}
	if len(name) < minStem || len(word) < minStem {
		return false
	}
	// The last letter can change too: Marko, Marku.
	stem := name[:len(name)-1]
	return strings.HasPrefix(word, stem) && len(word)-len(stem) <= stemTail+1
}

func monthOf(word string) (time.Month, bool) {
	for _, candidate := range monthStems {
		if len(word) >= 3 && strings.HasPrefix(word, candidate.stem) {
			return candidate.month, true
		}
	}
	return 0, false
}

// matchTerm finds a term at the start of the words, and says how many words it took.
func matchTerm(words []string, terms []searchTerm) (*searchTerm, int) {
	var best *searchTerm
	bestLength := 0
	for i := range terms {
		parts := strings.Fields(foldWord(terms[i].value))
		if len(parts) == 0 || len(parts) > len(words) || len(parts) <= bestLength {
			continue
		}
		matched := true
		for j, part := range parts {
			if !wordMatches(words[j], part) {
				matched = false
				break
			}
		}
		if matched {
			best, bestLength = &terms[i], len(parts)
		}
	}
	return best, bestLength
}

// parseQuery takes out what is a filter. What remains is matched against the pictures. A photo of
// "Hvar" with no such place in the library simply stays a word to look for.
func parseQuery(query string, terms []searchTerm) parsedQuery {
	var out parsedQuery
	original := strings.Fields(query)
	folded := make([]string, len(original))
	for i, word := range original {
		folded[i] = strings.Trim(foldWord(word), ".,;:!?\"'()")
	}
	var rest []string
	for i := 0; i < len(folded); {
		word := folded[i]
		if yearWord.MatchString(word) && out.year == 0 {
			out.year, _ = strconv.Atoi(word)
			i++
			continue
		}
		if month, ok := monthOf(word); ok && out.month == 0 {
			out.month = month
			i++
			continue
		}
		if term, length := matchTerm(folded[i:], terms); term != nil {
			switch {
			case term.kind == "person" && out.person == nil:
				out.person = term
			case term.kind == "place" && out.place == "":
				out.place = term.value
			case term.kind == "camera" && out.camera == "":
				out.camera = term.value
			default:
				rest = append(rest, original[i:i+length]...)
			}
			i += length
			continue
		}
		rest = append(rest, original[i])
		i++
	}
	out.words = strings.Join(rest, " ")
	return out
}

// dateRange is the span the query names, or nothing.
func (p *parsedQuery) dateRange(now time.Time) (from, to pgtype.Timestamp) {
	switch {
	case p.year != 0 && p.month != 0:
		start := time.Date(p.year, p.month, 1, 0, 0, 0, 0, time.UTC)
		return pgtype.Timestamp{Time: start, Valid: true}, pgtype.Timestamp{Time: start.AddDate(0, 1, 0), Valid: true}
	case p.year != 0:
		start := time.Date(p.year, time.January, 1, 0, 0, 0, 0, time.UTC)
		return pgtype.Timestamp{Time: start, Valid: true}, pgtype.Timestamp{Time: start.AddDate(1, 0, 0), Valid: true}
	case p.month != 0:
		// A month alone is the most recent one with that name.
		year := now.Year()
		if p.month > now.Month() {
			year--
		}
		start := time.Date(year, p.month, 1, 0, 0, 0, 0, time.UTC)
		return pgtype.Timestamp{Time: start, Valid: true}, pgtype.Timestamp{Time: start.AddDate(0, 1, 0), Valid: true}
	}
	return from, to
}

// mergeRanks is reciprocal rank fusion: what ranks well in several lists comes first.
func mergeRanks(limit int, lists ...[]pgtype.UUID) []pgtype.UUID {
	scores := map[pgtype.UUID]float64{}
	order := []pgtype.UUID{}
	for _, list := range lists {
		for rank, id := range list {
			if _, seen := scores[id]; !seen {
				order = append(order, id)
			}
			scores[id] += 1 / (rrfConstant + float64(rank+1))
		}
	}
	slices.SortStableFunc(order, func(a, b pgtype.UUID) int {
		switch {
		case scores[a] > scores[b]:
			return -1
		case scores[a] < scores[b]:
			return 1
		}
		return 0
	})
	if len(order) > limit {
		order = order[:limit]
	}
	return order
}

// likePattern finds words anywhere in a name. What the person typed is taken literally.
func likePattern(words string) string {
	return "%" + strings.NewReplacer(`\`, `\\`, "%", `\%`, "_", `\_`).Replace(words) + "%"
}

func textArg(value string) pgtype.Text { return pgtype.Text{String: value, Valid: value != ""} }

// termsCache remembers what each library can name for a moment: the list comes from reading every
// picture's details, which is far too slow to do for each search.
type termsCache struct {
	mu     sync.Mutex
	byUser map[pgtype.UUID]cachedTerms
}

type cachedTerms struct {
	terms []searchTerm
	read  time.Time
}

func (s *apiServer) searchTerms(ctx context.Context, user pgtype.UUID) ([]searchTerm, error) {
	s.terms.mu.Lock()
	cached, known := s.terms.byUser[user]
	s.terms.mu.Unlock()
	if known && time.Since(cached.read) < termsFresh {
		return cached.terms, nil
	}
	rows, err := s.queries.ListSearchTerms(ctx, user)
	if err != nil {
		return nil, err
	}
	terms := make([]searchTerm, len(rows))
	for i, row := range rows {
		terms[i] = searchTerm{kind: row.Kind, value: row.Value, ref: row.Ref}
	}
	s.terms.mu.Lock()
	if s.terms.byUser == nil {
		s.terms.byUser = map[pgtype.UUID]cachedTerms{}
	}
	s.terms.byUser[user] = cachedTerms{terms: terms, read: time.Now()}
	s.terms.mu.Unlock()
	return terms, nil
}

// forgetSearchTerms makes the next search read the names again, after a person was named.
func (s *apiServer) forgetSearchTerms(user pgtype.UUID) {
	s.terms.mu.Lock()
	delete(s.terms.byUser, user)
	s.terms.mu.Unlock()
}

func (s *apiServer) vectorSearch(ctx context.Context, params *db.SearchVectorParams) ([]pgtype.UUID, error) {
	var ids []pgtype.UUID
	err := pgx.BeginFunc(ctx, s.Pool, func(tx pgx.Tx) error {
		// Keeps looking through the index when filters remove the nearest results.
		if _, err := tx.Exec(ctx, "SET LOCAL hnsw.iterative_scan = relaxed_order"); err != nil {
			return err
		}
		if _, err := tx.Exec(ctx, "SET LOCAL hnsw.ef_search = 100"); err != nil {
			return err
		}
		var err error
		ids, err = s.queries.WithTx(tx).SearchVector(ctx, *params)
		return err
	})
	return ids, err
}

// searchScope is everything a search is narrowed by: what was chosen in the filters, and what was
// found in the words.
type searchScope struct {
	from, to    pgtype.Timestamp
	people      []pgtype.UUID
	peopleAll   bool
	place       string
	camera      string
	lens        string
	kind        string
	minRating   int16
	pick        pgtype.Int2
	favorite    bool
	tags        []string
	album       pgtype.UUID
	albumShared bool
	notInAlbum  bool
}

func (c *searchScope) filtered(user pgtype.UUID, limit int32) db.SearchFilteredParams {
	return db.SearchFilteredParams{
		UserID: user, AlbumShared: c.albumShared, FromAt: c.from, ToAt: c.to, People: c.people, PeopleAll: c.peopleAll,
		Place: textArg(c.place), Camera: textArg(c.camera), Lens: textArg(c.lens), Kind: textArg(c.kind),
		MinRating: c.minRating, Pick: c.pick, FavoriteOnly: c.favorite, Tags: c.tags, Album: c.album, NotInAlbum: c.notInAlbum, RowLimit: limit,
	}
}

func (c *searchScope) text(user pgtype.UUID, words string, limit int32) db.SearchTextParams {
	f := c.filtered(user, limit)
	return db.SearchTextParams{
		UserID: user, Words: words, NamePattern: likePattern(words), AlbumShared: f.AlbumShared, FromAt: f.FromAt, ToAt: f.ToAt,
		People: f.People, PeopleAll: f.PeopleAll, Place: f.Place, Camera: f.Camera, Lens: f.Lens, Kind: f.Kind,
		MinRating: f.MinRating, Pick: f.Pick, FavoriteOnly: f.FavoriteOnly, Tags: f.Tags, Album: f.Album, NotInAlbum: f.NotInAlbum, RowLimit: limit,
	}
}

func (c *searchScope) vector(user pgtype.UUID, embedding string, limit int32) db.SearchVectorParams {
	f := c.filtered(user, limit)
	return db.SearchVectorParams{
		UserID: user, Embedding: embedding, AlbumShared: f.AlbumShared, FromAt: f.FromAt, ToAt: f.ToAt,
		People: f.People, PeopleAll: f.PeopleAll, Place: f.Place, Camera: f.Camera, Lens: f.Lens, Kind: f.Kind,
		MinRating: f.MinRating, Pick: f.Pick, FavoriteOnly: f.FavoriteOnly, Tags: f.Tags, Album: f.Album, NotInAlbum: f.NotInAlbum, RowLimit: limit,
	}
}

func cleanStrings(values *[]string) []string {
	out := []string{}
	if values == nil {
		return out
	}
	for _, value := range *values {
		if value = strings.ToLower(strings.TrimSpace(value)); value != "" && !slices.Contains(out, value) {
			out = append(out, value)
		}
	}
	return out
}

func trimmed(value *string) string {
	if value == nil {
		return ""
	}
	return strings.TrimSpace(*value)
}

func (s *apiServer) SearchAssets(w http.ResponseWriter, r *http.Request, params api.SearchAssetsParams) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	query := trimmed(params.Q)
	if len(query) > maxQueryLength {
		writeError(w, http.StatusBadRequest, "the search may have at most 500 characters")
		return
	}
	ctx := r.Context()
	scope := searchScope{
		peopleAll: params.People == nil || *params.People != api.SearchAssetsParamsPeopleAny,
		place:     trimmed(params.Place), camera: trimmed(params.Camera), lens: trimmed(params.Lens),
		tags:       cleanStrings(params.Tag),
		favorite:   params.Favorite != nil && *params.Favorite,
		notInAlbum: params.NotInAlbum != nil && *params.NotInAlbum,
	}
	filters := api.SearchFilters{}
	if params.Type != nil {
		scope.kind = string(*params.Type)
		kind := api.SearchFiltersType(*params.Type)
		filters.Type = &kind
	}
	if params.MinRating != nil {
		scope.minRating = int16(min(max(*params.MinRating, 0), 5)) //nolint:gosec // Bounded.
		filters.MinRating = params.MinRating
	}
	var validPick bool
	if scope.pick, validPick = pickFilter(params.Pick); !validPick {
		writeError(w, http.StatusBadRequest, errBadPick)
		return
	}
	filters.Pick = params.Pick
	if params.Album != nil {
		album, err := s.queries.GetAlbumForUser(ctx, db.GetAlbumForUserParams{ID: pgUUID(*params.Album), UserID: user.ID})
		if db.IsNotFound(err) {
			writeError(w, http.StatusNotFound, "no such album")
			return
		}
		if err != nil {
			internalError(w, r, err)
			return
		}
		scope.album, scope.albumShared = album.ID, album.OwnerID != user.ID
		filters.Album = &api.AlbumRef{Id: album.ID.Bytes, Title: album.Title}
	}
	if params.Person != nil {
		names, err := s.queries.ListPeople(ctx, db.ListPeopleParams{UserID: user.ID, MinFaces: 0})
		if err != nil {
			internalError(w, r, err)
			return
		}
		refs := []api.PersonRef{}
		for _, id := range *params.Person {
			for i := range names {
				if names[i].ID.Bytes == id {
					scope.people = append(scope.people, names[i].ID)
					refs = append(refs, api.PersonRef{Id: id, Name: names[i].Name})
				}
			}
		}
		// A person who is not this user's matches nothing, rather than being left out.
		if len(scope.people) < len(*params.Person) {
			writeJSON(w, http.StatusOK, api.SearchResult{Items: []api.TimelineItem{}, Smart: false, Filters: filters})
			return
		}
		filters.People = &refs
	}
	fromDay, err := parseDay(params.From)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	toDay, err := parseDay(params.To)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	scope.from, scope.to = dateParam(fromDay, false), dateParam(toDay, true)

	chosen := scope.from.Valid || scope.to.Valid || len(scope.people) > 0 || scope.place != "" || scope.camera != "" ||
		scope.lens != "" || scope.kind != "" || scope.minRating > 0 || scope.pick.Valid || scope.favorite || len(scope.tags) > 0 ||
		scope.album.Valid || scope.notInAlbum
	if query == "" && !chosen {
		writeError(w, http.StatusBadRequest, "type something to look for, or choose a filter")
		return
	}
	words := query
	if query != "" && (params.Plain == nil || !*params.Plain) {
		terms, err := s.searchTerms(ctx, user.ID)
		if err != nil {
			internalError(w, r, err)
			return
		}
		parsed := parseQuery(query, terms)
		words = parsed.words
		// What the words say narrows the search too, unless the filters already say it.
		if from, to := parsed.dateRange(time.Now()); from.Valid && !scope.from.Valid && !scope.to.Valid {
			scope.from, scope.to = from, to
		}
		if parsed.person != nil {
			if id, err := uuid.Parse(parsed.person.ref); err == nil {
				person := pgtype.UUID{Bytes: id, Valid: true}
				if !slices.Contains(scope.people, person) {
					scope.people = append(scope.people, person)
					refs := []api.PersonRef{}
					if filters.People != nil {
						refs = *filters.People
					}
					refs = append(refs, api.PersonRef{Id: id, Name: parsed.person.value})
					filters.People = &refs
				}
				filters.Person = &parsed.person.value
			}
		}
		if scope.place == "" {
			scope.place = parsed.place
		}
		if scope.camera == "" {
			scope.camera = parsed.camera
		}
	}
	filters.Place = optional(scope.place, scope.place != "")
	filters.Camera = optional(scope.camera, scope.camera != "")
	filters.Lens = optional(scope.lens, scope.lens != "")
	filters.Words = optional(words, words != "")
	if len(scope.tags) > 0 {
		filters.Tags = &scope.tags
	}
	if scope.favorite {
		filters.Favorite = &scope.favorite
	}
	if scope.notInAlbum {
		filters.NotInAlbum = &scope.notInAlbum
	}
	if len(scope.people) > 1 {
		match := api.SearchFiltersPeopleMatchAll
		if !scope.peopleAll {
			match = api.SearchFiltersPeopleMatchAny
		}
		filters.PeopleMatch = &match
	}
	if scope.from.Valid {
		filters.From = &openapi_types.Date{Time: scope.from.Time}
	}
	if scope.to.Valid {
		filters.To = &openapi_types.Date{Time: scope.to.Time.AddDate(0, 0, -1)}
	}

	smart := s.embeddings.Enabled()
	var ids []pgtype.UUID
	if words == "" {
		ids, err = s.queries.SearchFiltered(ctx, scope.filtered(user.ID, searchResultSize))
		if err != nil {
			internalError(w, r, err)
			return
		}
	} else {
		// Side by side, because each takes a moment and the person is waiting.
		type textResult struct {
			ids []pgtype.UUID
			err error
		}
		textDone := make(chan textResult, 1)
		go func() {
			found, err := s.queries.SearchText(ctx, scope.text(user.ID, words, searchCandidates))
			textDone <- textResult{found, err}
		}()
		var vectorIDs []pgtype.UUID
		var vectorErr error
		if smart {
			// Search still answers from words on pictures and file names if this fails.
			textCtx, cancel := context.WithTimeout(ctx, textDeadline)
			vector, err := s.embeddings.Text(textCtx, words)
			cancel()
			if err != nil {
				if !errors.Is(err, ml.ErrDisabled) && !errors.Is(err, ml.ErrCoolingOff) {
					slog.Warn("search without picture analysis", "error", err)
				}
				smart = false
			} else {
				params := scope.vector(user.ID, vector, searchCandidates)
				vectorIDs, vectorErr = s.vectorSearch(ctx, &params)
			}
		}
		text := <-textDone
		if vectorErr != nil {
			internalError(w, r, vectorErr)
			return
		}
		if text.err != nil {
			internalError(w, r, text.err)
			return
		}
		ids = mergeRanks(searchResultSize, text.ids, vectorIDs)
	}

	items, err := s.itemsInOrder(ctx, ids)
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, api.SearchResult{Items: items, Smart: smart, Filters: filters})
}

// GetSearchOptions lists what the filters can offer: only what this library has.
func (s *apiServer) GetSearchOptions(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	rows, err := s.queries.SearchOptions(r.Context(), user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := api.SearchOptions{Cameras: []string{}, Lenses: []string{}, Places: []string{}, Tags: []string{}}
	for _, row := range rows {
		value := row.Value.String
		switch row.Kind {
		case "camera":
			out.Cameras = append(out.Cameras, value)
		case "lens":
			out.Lenses = append(out.Lenses, value)
		case "place":
			if !slices.Contains(out.Places, value) {
				out.Places = append(out.Places, value)
			}
		case "tag":
			out.Tags = append(out.Tags, value)
		}
	}
	writeJSON(w, http.StatusOK, out)
}

// itemsInOrder reads what the given photos need on screen, in the order asked for.
func (s *apiServer) itemsInOrder(ctx context.Context, ids []pgtype.UUID) ([]api.TimelineItem, error) {
	rows, err := s.queries.ItemsByID(ctx, ids)
	if err != nil {
		return nil, err
	}
	found := make(map[pgtype.UUID]*db.ItemsByIDRow, len(rows))
	for i := range rows {
		found[rows[i].ID] = &rows[i]
	}
	items := make([]api.TimelineItem, 0, len(ids))
	for _, id := range ids {
		row := found[id]
		if row == nil {
			continue
		}
		items = append(items, api.TimelineItem{
			Id: row.ID.Bytes, Kind: api.TimelineItemKind(row.Kind),
			Ratio:      ratioOf(row.AspectRatio, row.Width, row.Height),
			IsFavorite: row.IsFavorite, IsLive: optional(row.IsLive, row.IsLive),
			DurationMs: optional(row.DurationMs.Int64, row.DurationMs.Valid),
			LocalAt:    row.LocalAt.Time.Format(localTimeLayout),
			Blurhash:   optional(row.Blurhash.String, row.Blurhash.Valid),
		})
	}
	return items, nil
}

func (s *apiServer) ListPeople(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	prefs, err := s.preferences(r.Context(), user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	rows, err := s.queries.ListPeople(r.Context(), db.ListPeopleParams{UserID: user.ID, MinFaces: int64(prefs.MinFaces)})
	if err != nil {
		internalError(w, r, err)
		return
	}
	people := make([]api.Person, len(rows))
	for i := range rows {
		people[i] = api.Person{BirthDate: birthDate(rows[i].BirthDate), Id: rows[i].ID.Bytes, Name: rows[i].Name, Hidden: rows[i].Hidden, AssetCount: rows[i].AssetCount}
	}
	writeJSON(w, http.StatusOK, api.PeopleList{Enabled: s.embeddings.Enabled(), People: people})
}

// person reads a person of the signed-in user. Faces are nobody else's business.
func (s *apiServer) person(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) (*db.GetPersonRow, *db.User, bool) {
	user := requireUser(w, r)
	if user == nil {
		return nil, nil, false
	}
	row, err := s.queries.GetPerson(r.Context(), db.GetPersonParams{ID: pgUUID(id), UserID: user.ID})
	if db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "no such person")
		return nil, nil, false
	}
	if err != nil {
		internalError(w, r, err)
		return nil, nil, false
	}
	return &row, user, true
}

func (s *apiServer) UpdatePerson(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	row, user, ok := s.person(w, r, id)
	if !ok {
		return
	}
	var body api.PersonUpdate
	if !readJSON(w, r, &body) {
		return
	}
	params := db.UpdatePersonParams{ID: row.ID, Name: row.Name, Hidden: row.Hidden}
	if body.Name != nil {
		params.Name = strings.TrimSpace(*body.Name)
		if len([]rune(params.Name)) > maxPersonName {
			writeError(w, http.StatusBadRequest, "the name is too long")
			return
		}
	}
	if body.Hidden != nil {
		params.Hidden = *body.Hidden
	}
	var date pgtype.Date
	if body.BirthDate != nil {
		var valid bool
		if date, valid = parseBirthDate(*body.BirthDate, time.Now()); !valid {
			writeError(w, http.StatusBadRequest, "the date of birth must be a past date, as YYYY-MM-DD")
			return
		}
	}
	if err := s.queries.UpdatePerson(r.Context(), params); err != nil {
		internalError(w, r, err)
		return
	}
	defer s.forgetSearchTerms(user.ID)
	if body.BirthDate != nil {
		if err := s.queries.SetPersonBirthDate(r.Context(), db.SetPersonBirthDateParams{ID: row.ID, BirthDate: date}); err != nil {
			internalError(w, r, err)
			return
		}
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) MergePeople(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	row, user, ok := s.person(w, r, id)
	if !ok {
		return
	}
	var body api.AssetIds
	if !readJSON(w, r, &body) {
		return
	}
	sources := make([]pgtype.UUID, 0, len(body.Ids))
	for _, source := range body.Ids {
		if pgUUID(source) != row.ID {
			sources = append(sources, pgUUID(source))
		}
	}
	if len(sources) == 0 {
		writeError(w, http.StatusBadRequest, "choose someone else to merge")
		return
	}
	err := pgx.BeginFunc(r.Context(), s.Pool, func(tx pgx.Tx) error {
		return jobs.MergePeople(r.Context(), s.queries.WithTx(tx), row.ID, sources, user.ID)
	})
	if err != nil {
		internalError(w, r, err)
		return
	}
	s.forgetSearchTerms(user.ID)
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) GetPersonThumbnail(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	row, _, ok := s.person(w, r, id)
	if !ok {
		return
	}
	ctx := r.Context()
	face, err := s.queries.PersonCoverFace(ctx, row.ID)
	if db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "no picture of this person")
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	dest := filepath.Join(s.CachePath, "faces", uuid.UUID(face.ID.Bytes).String()+".webp")
	if err := jobs.CropFace(ctx, face.Path, dest, face.X1, face.Y1, face.X2, face.Y2); err != nil {
		internalError(w, r, err)
		return
	}
	w.Header().Set("Content-Type", "image/webp")
	w.Header().Set("Cache-Control", "private, no-cache")
	w.Header().Set("X-Content-Type-Options", "nosniff")
	serveFile(w, r, dest)
}

func (s *apiServer) GetPersonBuckets(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	row, _, ok := s.person(w, r, id)
	if !ok {
		return
	}
	rows, err := s.queries.PersonBuckets(r.Context(), row.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := make([]db.TimelineBucketsRow, len(rows))
	for i, bucket := range rows {
		out[i] = db.TimelineBucketsRow(bucket)
	}
	writeBuckets(w, out, false)
}

func (s *apiServer) GetPersonBucket(w http.ResponseWriter, r *http.Request, id openapi_types.UUID, month string) {
	row, user, ok := s.person(w, r, id)
	if !ok {
		return
	}
	from, to, ok := monthRange(w, month)
	if !ok {
		return
	}
	rows, err := s.queries.PersonBucket(r.Context(), db.PersonBucketParams{PersonID: row.ID, FromAt: from, ToAt: to})
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := make([]db.TimelineBucketRow, len(rows))
	for i := range rows {
		out[i] = db.TimelineBucketRow(rows[i])
	}
	writeBucket(w, month, out, user.ID, false)
}

func (s *apiServer) GetAnalysisProgress(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	counts, err := s.queries.GetAnalysisCounts(r.Context())
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, api.AnalysisProgress{Enabled: s.embeddings.Enabled(), Total: counts.Total, Analyzed: counts.Analyzed})
}
