package jobs

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/riverqueue/river"

	"github.com/mediarr-app/mediarr/server/db"
)

const (
	// MaxStoryPictures keeps a story short, and the work for the server bounded.
	MaxStoryPictures = 60
	storySeconds     = 3.0
	storyFadeSeconds = 0.5
	storyWidth       = 1280
	storyHeight      = 720
	storyFrameRate   = 30
	storyKeepDays    = 7
	storyTimeout     = time.Hour
)

// StoryArgs makes a video of chosen photos.
type StoryArgs struct {
	ExportID uuid.UUID   `json:"export_id"`
	UserID   uuid.UUID   `json:"user_id"`
	AssetIDs []uuid.UUID `json:"asset_ids"`
}

// Kind identifies the job in the queue.
func (StoryArgs) Kind() string { return "story" }

// InsertOpts shares the video queue, so only one heavy encode runs at a time.
func (StoryArgs) InsertOpts() river.InsertOpts { return river.InsertOpts{Queue: videoQueue} }

type storyWorker struct {
	river.WorkerDefaults[StoryArgs]
	*deps
}

// Timeout allows for the longest story on a slow machine.
func (w *storyWorker) Timeout(*river.Job[StoryArgs]) time.Duration { return storyTimeout }

func (w *storyWorker) Work(ctx context.Context, job *river.Job[StoryArgs]) error {
	export := pgtype.UUID{Bytes: job.Args.ExportID, Valid: true}
	finish := func(status, path string) error {
		return w.queries.FinishStoryExport(ctx, db.FinishStoryExportParams{
			ID: export, Status: status, Path: pgtype.Text{String: path, Valid: path != ""},
		})
	}
	ids := make([]pgtype.UUID, len(job.Args.AssetIDs))
	for i, id := range job.Args.AssetIDs {
		ids[i] = pgtype.UUID{Bytes: id, Valid: true}
	}
	rows, err := w.queries.ListStoryPictures(ctx, db.ListStoryPicturesParams{Ids: ids, UserID: pgtype.UUID{Bytes: job.Args.UserID, Valid: true}})
	if err != nil {
		return err
	}
	byID := make(map[pgtype.UUID]string, len(rows))
	for i := range rows {
		byID[rows[i].ID] = rows[i].Path
	}
	pictures := make([]string, 0, len(ids))
	for _, id := range ids {
		if path, ok := byID[id]; ok {
			pictures = append(pictures, path)
		}
	}
	if len(pictures) == 0 {
		return finish("failed", "")
	}
	dest := filepath.Join(w.opts.CachePath, "stories", job.Args.ExportID.String()+".mp4")
	if err := MakeStory(ctx, pictures, dest); err != nil {
		slog.Error("a story could not be made", "export", job.Args.ExportID, "error", err)
		if job.Attempt >= maxAttempts {
			return finish("failed", "")
		}
		return err
	}
	return finish("ready", dest)
}

// StoryFilter joins pictures into one video with a short fade between them.
func StoryFilter(count int) string {
	var out strings.Builder
	for i := range count {
		fmt.Fprintf(&out, "[%d:v]scale=%d:%d:force_original_aspect_ratio=decrease,pad=%d:%d:(ow-iw)/2:(oh-ih)/2:color=black,setsar=1,fps=%d,format=yuv420p[p%d];",
			i, storyWidth, storyHeight, storyWidth, storyHeight, storyFrameRate, i)
	}
	if count == 1 {
		out.WriteString("[p0]null[out]")
		return out.String()
	}
	last := "p0"
	for i := 1; i < count; i++ {
		next := "x" + strconv.Itoa(i)
		if i == count-1 {
			next = "out"
		}
		offset := float64(i) * (storySeconds - storyFadeSeconds)
		fmt.Fprintf(&out, "[%s][p%d]xfade=transition=fade:duration=%g:offset=%g[%s]", last, i, storyFadeSeconds, offset, next)
		if i < count-1 {
			out.WriteByte(';')
		}
		last = next
	}
	return out.String()
}

// MakeStory writes the video. It appears under its final name only when complete.
func MakeStory(ctx context.Context, pictures []string, dest string) error {
	if err := os.MkdirAll(filepath.Dir(dest), 0o750); err != nil {
		return err
	}
	tmp := dest + ".tmp.mp4"
	defer func() { _ = os.Remove(tmp) }()
	args := []string{"-y", "-v", "error"}
	for _, picture := range pictures {
		args = append(args, "-loop", "1", "-t", strconv.FormatFloat(storySeconds, 'f', -1, 64), "-i", picture)
	}
	args = append(args, "-filter_complex", StoryFilter(len(pictures)), "-map", "[out]",
		"-c:v", "libx264", "-preset", "veryfast", "-crf", "23", "-movflags", "+faststart", "-threads", "2", tmp)
	if _, err := runToolNoLimit(ctx, "ffmpeg", args...); err != nil {
		return err
	}
	return os.Rename(tmp, dest)
}

// removeOldStories frees the disk: a story can always be made again.
func removeOldStories(ctx context.Context, q *db.Queries, now time.Time) error {
	rows, err := q.ListOldStoryExports(ctx, pgtype.Timestamptz{Time: now.AddDate(0, 0, -storyKeepDays), Valid: true})
	if err != nil {
		return err
	}
	for i := range rows {
		if rows[i].Path.Valid {
			if err := os.Remove(rows[i].Path.String); err != nil && !os.IsNotExist(err) {
				slog.Warn("remove an old story", "error", err)
			}
		}
		if err := q.DeleteStoryExport(ctx, rows[i].ID); err != nil {
			return err
		}
	}
	return nil
}
