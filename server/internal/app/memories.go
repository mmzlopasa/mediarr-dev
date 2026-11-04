package app

import (
	"context"
	"fmt"
	"mime"
	"net/http"
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

func (s *apiServer) memoriesFor(ctx context.Context, user pgtype.UUID, today time.Time) ([]api.Memory, error) {
	day := time.Date(today.Year(), today.Month(), today.Day(), 0, 0, 0, 0, time.UTC)
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
		memories = append(memories, api.Memory{
			Kind: api.OnThisDay, Year: &value, Items: items,
			Title: fmt.Sprintf("%d-%02d-%02d", year, day.Month(), day.Day()),
		})
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
			Kind: api.Week, Items: items, Title: from.Format(dateLayout) + " – " + day.Format(dateLayout),
		}}, memories...)
	}
	return memories, nil
}

func (s *apiServer) ListMemories(w http.ResponseWriter, r *http.Request, params api.ListMemoriesParams) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	today := time.Now()
	if params.Date != nil {
		today = params.Date.Time
	}
	memories, err := s.memoriesFor(r.Context(), user.ID, today)
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, memories)
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
