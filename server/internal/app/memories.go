package app

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"mime"
	"net/http"
	"slices"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

const (
	maxMemoryItems   = 30
	summaryDays      = 7
	minSummaryPhotos = 3
	maxStoryTitle    = 200
	maxMemoryKey     = 200
	// Time zones reach a day ahead or behind; further than that the date is not somebody's today.
	maxOwnDayDrift = 48 * time.Hour
)

// spread picks up to limit items evenly, so a memory covers the whole day or week.
func spread[T any](items []T, limit int) []T {
	if len(items) <= limit {
		return items
	}
	out := make([]T, 0, limit)
	for i := range limit {
		out = append(out, items[i*len(items)/limit])
	}
	return out
}

// weekKey is what the week's summary is hidden by: hiding it holds for that week.
func weekKey(day time.Time) string {
	year, week := day.ISOWeek()
	return fmt.Sprintf("%d-W%02d", year, week)
}

func validMemoryKinds(kinds *[]api.UserPreferencesMemoryKindsOff) bool {
	if kinds == nil {
		return true
	}
	for _, kind := range *kinds {
		if !kind.Valid() {
			return false
		}
	}
	return true
}

func (s *apiServer) liveMemories(ctx context.Context, user pgtype.UUID, day time.Time) ([]api.Memory, error) {
	memories := []api.Memory{}
	rows, err := s.queries.OnThisDay(ctx, db.OnThisDayParams{
		UserID: user, Month: int32(day.Month()), Day: int32(day.Day()), //nolint:gosec // A month and a day.
		Before: pgtype.Timestamp{Time: time.Date(day.Year(), time.January, 1, 0, 0, 0, 0, time.UTC), Valid: true},
	})
	if err != nil {
		return nil, err
	}
	byYear := map[int32][]pgtype.UUID{}
	years := []int32{}
	for _, row := range rows {
		if len(byYear[row.Year]) == 0 {
			years = append(years, row.Year)
		}
		byYear[row.Year] = append(byYear[row.Year], row.ID)
	}
	for _, year := range years {
		items, err := s.itemsInOrder(ctx, spread(byYear[year], maxMemoryItems))
		if err != nil {
			return nil, err
		}
		value := int(year)
		date := fmt.Sprintf("%d-%02d-%02d", year, day.Month(), day.Day())
		memories = append(memories, api.Memory{Kind: api.MemoryKindOnThisDay, Key: date, Year: &value, Items: items, Title: date})
	}

	from := day.AddDate(0, 0, -summaryDays)
	recent, err := s.queries.RecentForSummary(ctx, db.RecentForSummaryParams{
		UserID: user, FromAt: pgtype.Timestamp{Time: from, Valid: true},
		ToAt: pgtype.Timestamp{Time: day.AddDate(0, 0, 1), Valid: true},
	})
	if err != nil {
		return nil, err
	}
	if len(recent) >= minSummaryPhotos {
		items, err := s.itemsInOrder(ctx, spread(recent, maxMemoryItems))
		if err != nil {
			return nil, err
		}
		memories = append([]api.Memory{{
			Kind: api.MemoryKindWeek, Key: weekKey(day), Items: items, Title: from.Format(dateLayout) + " – " + day.Format(dateLayout),
		}}, memories...)
	}
	return memories, nil
}

// smartMemories reads what the daily job worked out; nothing here looks through the library.
func (s *apiServer) smartMemories(ctx context.Context, user pgtype.UUID, day time.Time) ([]api.Memory, error) {
	rows, err := s.queries.ListDueMemories(ctx, db.ListDueMemoriesParams{UserID: user, Day: pgtype.Date{Time: day, Valid: true}})
	if err != nil || len(rows) == 0 {
		return nil, err
	}
	all := []pgtype.UUID{}
	for i := range rows {
		all = append(all, rows[i].Items...)
	}
	kept, err := s.queries.FilterMemoryItems(ctx, db.FilterMemoryItemsParams{Ids: all, UserID: user})
	if err != nil {
		return nil, err
	}
	visible := make(map[pgtype.UUID]bool, len(kept))
	for _, id := range kept {
		visible[id] = true
	}
	memories := make([]api.Memory, 0, len(rows))
	for i := range rows {
		row := &rows[i]
		ids := slices.DeleteFunc(slices.Clone(row.Items), func(id pgtype.UUID) bool { return !visible[id] })
		if len(ids) == 0 {
			continue
		}
		items, err := s.itemsInOrder(ctx, ids)
		if err != nil {
			return nil, err
		}
		var params api.MemoryTitleParams
		if err := json.Unmarshal(row.TitleParams, &params); err != nil {
			return nil, err
		}
		memories = append(memories, api.Memory{Kind: api.MemoryKind(row.Kind), Key: row.Key, Title: row.Title, TitleParams: &params, Items: items})
	}
	return memories, nil
}

func (s *apiServer) memoriesFor(ctx context.Context, user pgtype.UUID, today time.Time, smart bool) ([]api.Memory, error) {
	day := time.Date(today.Year(), today.Month(), today.Day(), 0, 0, 0, 0, time.UTC)
	memories, err := s.liveMemories(ctx, user, day)
	if err != nil {
		return nil, err
	}
	if smart {
		computed, err := s.smartMemories(ctx, user, day)
		if err != nil {
			return nil, err
		}
		// The week's summary stays first, the years of "on this day" last.
		at := 0
		if len(memories) > 0 && memories[0].Kind == api.MemoryKindWeek {
			at = 1
		}
		memories = slices.Insert(memories, at, computed...)
	}
	hidden, err := s.queries.ListHiddenMemoryKeys(ctx, user)
	if err != nil {
		return nil, err
	}
	hiddenKeys := make(map[string]bool, len(hidden))
	for i := range hidden {
		hiddenKeys[hidden[i].Kind+"\x00"+hidden[i].Key] = true
	}
	prefs, err := s.preferences(ctx, user)
	if err != nil {
		return nil, err
	}
	off := map[string]bool{}
	if prefs.MemoryKindsOff != nil {
		for _, kind := range *prefs.MemoryKindsOff {
			off[string(kind)] = true
		}
	}
	return slices.DeleteFunc(memories, func(memory api.Memory) bool {
		return off[string(memory.Kind)] || hiddenKeys[string(memory.Kind)+"\x00"+memory.Key]
	}), nil
}

// A person whose day it is should find them when they look, not after the next daily run. The job
// is queued only for a day close to now, and never twice at once.
func (s *apiServer) askForMemories(ctx context.Context, user pgtype.UUID, day time.Time) {
	if s.Inserter == nil || day.Sub(time.Now().UTC()).Abs() > maxOwnDayDrift {
		return
	}
	run, err := s.queries.GetMemoryRun(ctx, user)
	if err == nil && run.Valid && run.Time.Equal(day) {
		return
	}
	if err != nil && !db.IsNotFound(err) {
		slog.Warn("reading when memories were worked out", "error", err)
		return
	}
	if _, err := s.Inserter.Insert(ctx, jobs.MemoriesArgs{UserID: user.Bytes, Day: day.Format(time.DateOnly)}, nil); err != nil {
		slog.Warn("queueing memories", "error", err)
	}
}

func (s *apiServer) ListMemories(w http.ResponseWriter, r *http.Request, params api.ListMemoriesParams) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	today := time.Now()
	day, err := parseDay(params.Date)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	if day != nil {
		today = *day
	}
	smart := params.Smart != nil && *params.Smart
	memories, err := s.memoriesFor(r.Context(), user.ID, today, smart)
	if err != nil {
		internalError(w, r, err)
		return
	}
	if smart {
		s.askForMemories(r.Context(), user.ID, time.Date(today.Year(), today.Month(), today.Day(), 0, 0, 0, 0, time.UTC))
	}
	writeJSON(w, http.StatusOK, memories)
}

func (s *apiServer) SetMemoryHidden(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	var body api.MemoryHideRequest
	if !readJSON(w, r, &body) {
		return
	}
	if !body.Kind.Valid() || body.Key == "" || len(body.Key) > maxMemoryKey {
		writeError(w, http.StatusBadRequest, "no such memory")
		return
	}
	ctx := r.Context()
	var err error
	if body.Hidden {
		err = s.queries.HideMemory(ctx, db.HideMemoryParams{UserID: user.ID, Kind: string(body.Kind), Key: body.Key})
	} else {
		err = s.queries.ShowMemory(ctx, db.ShowMemoryParams{UserID: user.ID, Kind: string(body.Kind), Key: body.Key})
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) RestoreHiddenMemories(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	if err := s.queries.ShowAllMemories(r.Context(), user.ID); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) ListHiddenMemories(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	ctx := r.Context()
	keys, err := s.queries.ListHiddenMemoryKeys(ctx, user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	rows, err := s.queries.ListMemoryHiddenPeople(ctx, user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := api.HiddenMemories{Count: len(keys)}
	out.People = make([]api.PersonRef, len(rows))
	for i := range rows {
		out.People[i] = api.PersonRef{Id: rows[i].ID.Bytes, Name: rows[i].Name}
	}
	writeJSON(w, http.StatusOK, out)
}

func (s *apiServer) SetMemoryPersonHidden(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	var body api.MemoryPersonHideRequest
	if !readJSON(w, r, &body) {
		return
	}
	ctx := r.Context()
	person := pgUUID(body.PersonId)
	if _, err := s.queries.GetPerson(ctx, db.GetPersonParams{ID: person, UserID: user.ID}); db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "no such person")
		return
	} else if err != nil {
		internalError(w, r, err)
		return
	}
	var err error
	if body.Hidden {
		err = s.queries.HideMemoryPerson(ctx, db.HideMemoryPersonParams{UserID: user.ID, PersonID: person})
	} else {
		err = s.queries.ShowMemoryPerson(ctx, db.ShowMemoryPersonParams{UserID: user.ID, PersonID: person})
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	// The next daily run drops this person from what it builds; today's rows are filtered when read.
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) CreateStoryExport(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	var body api.StoryRequest
	if !readJSON(w, r, &body) {
		return
	}
	title := strings.TrimSpace(body.Title)
	if title == "" || len([]rune(title)) > maxStoryTitle {
		writeError(w, http.StatusBadRequest, "a story needs a title")
		return
	}
	if len(body.Ids) == 0 || len(body.Ids) > jobs.MaxStoryPictures {
		writeError(w, http.StatusBadRequest, fmt.Sprintf("a story has between 1 and %d photos", jobs.MaxStoryPictures))
		return
	}
	ctx := r.Context()
	var id pgtype.UUID
	err := pgx.BeginFunc(ctx, s.Pool, func(tx pgx.Tx) error {
		var err error
		id, err = s.queries.WithTx(tx).CreateStoryExport(ctx, db.CreateStoryExportParams{UserID: user.ID, Title: title})
		if err != nil {
			return err
		}
		_, err = s.Inserter.InsertTx(ctx, tx, jobs.StoryArgs{ExportID: id.Bytes, UserID: user.ID.Bytes, AssetIDs: body.Ids}, nil)
		return err
	})
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusAccepted, api.StoryExport{Id: id.Bytes, Status: api.StoryExportStatusWorking})
}

func (s *apiServer) storyExport(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) (*db.StoryExport, bool) {
	user := requireUser(w, r)
	if user == nil {
		return nil, false
	}
	row, err := s.queries.GetStoryExport(r.Context(), db.GetStoryExportParams{ID: pgUUID(id), UserID: user.ID})
	if db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "no such video")
		return nil, false
	}
	if err != nil {
		internalError(w, r, err)
		return nil, false
	}
	return &row, true
}

func (s *apiServer) GetStoryExport(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	row, ok := s.storyExport(w, r, id)
	if !ok {
		return
	}
	writeJSON(w, http.StatusOK, api.StoryExport{Id: id, Status: api.StoryExportStatus(row.Status)})
}

func (s *apiServer) GetStoryVideo(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	row, ok := s.storyExport(w, r, id)
	if !ok {
		return
	}
	if row.Status != string(api.StoryExportStatusReady) || !row.Path.Valid {
		writeError(w, http.StatusNotFound, "this video is not ready")
		return
	}
	w.Header().Set("Content-Type", "video/mp4")
	w.Header().Set("X-Content-Type-Options", "nosniff")
	w.Header().Set("Content-Disposition", mime.FormatMediaType("attachment", map[string]string{"filename": row.Title + ".mp4"}))
	serveFile(w, r, row.Path.String)
}
