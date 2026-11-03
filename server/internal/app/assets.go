package app

import (
	"archive/zip"
	"context"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"mime"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"slices"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/mmzlopasa/mediarr-app/server/db"
	"github.com/mmzlopasa/mediarr-app/server/internal/api"
	"github.com/mmzlopasa/mediarr-app/server/internal/jobs"
)

const (
	localTimeLayout = "2006-01-02T15:04:05"
	maxBulkIDs      = 1000
	maxZipIDs       = 100
	thumbCacheAge   = "private, max-age=31536000, immutable"
)

var bucketMonth = regexp.MustCompile(`^\d{4}-(0[1-9]|1[0-2])$`)

// inlineTypes are the only types shown in the browser. Anything else, such as SVG or HTML that
// exiftool recognised, is sent as a download, so an upload can never run as a page of this site.
var inlineTypes = map[string]bool{
	"image/jpeg": true, "image/png": true, "image/webp": true, "image/avif": true, "image/gif": true,
	"video/mp4": true, "video/webm": true, "video/quicktime": true,
}

func pgUUID(id openapi_types.UUID) pgtype.UUID { return pgtype.UUID{Bytes: id, Valid: true} }

func ratioOf(aspect pgtype.Float4, width, height pgtype.Int4) float32 {
	if aspect.Valid && aspect.Float32 > 0 {
		return aspect.Float32
	}
	if width.Valid && height.Valid && height.Int32 > 0 {
		return float32(width.Int32) / float32(height.Int32)
	}
	return 1
}

func (s *apiServer) GetTimelineBuckets(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	ctx := r.Context()
	partners, err := s.queries.CountTimelinePartners(ctx, user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	var rows []db.TimelineBucketsRow
	if partners == 0 {
		rows, err = s.queries.TimelineBuckets(ctx, user.ID)
	} else {
		var mixed []db.TimelineBucketsWithPartnersRow
		mixed, err = s.queries.TimelineBucketsWithPartners(ctx, user.ID)
		for _, row := range mixed {
			rows = append(rows, db.TimelineBucketsRow(row))
		}
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeBuckets(w, rows, false)
}

func writeBuckets(w http.ResponseWriter, rows []db.TimelineBucketsRow, oldestFirst bool) {
	if oldestFirst {
		slices.Reverse(rows)
	}
	out := api.TimelineBuckets{Buckets: make([]struct {
		Count int64  `json:"count"`
		Month string `json:"month"`
	}, len(rows))}
	for i, row := range rows {
		out.Buckets[i].Month = row.Month
		out.Buckets[i].Count = row.Count
	}
	writeJSON(w, http.StatusOK, out)
}

func monthRange(w http.ResponseWriter, month string) (from, to pgtype.Timestamp, ok bool) {
	if !bucketMonth.MatchString(month) {
		writeError(w, http.StatusBadRequest, "month must look like 2024-07")
		return from, to, false
	}
	start, err := time.Parse("2006-01", month)
	if err != nil {
		writeError(w, http.StatusBadRequest, "month must look like 2024-07")
		return from, to, false
	}
	return pgtype.Timestamp{Time: start, Valid: true}, pgtype.Timestamp{Time: start.AddDate(0, 1, 0), Valid: true}, true
}

func (s *apiServer) GetTimelineBucket(w http.ResponseWriter, r *http.Request, month string) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	from, to, ok := monthRange(w, month)
	if !ok {
		return
	}
	ctx := r.Context()
	partners, err := s.queries.CountTimelinePartners(ctx, user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	var rows []db.TimelineBucketRow
	if partners == 0 {
		rows, err = s.queries.TimelineBucket(ctx, db.TimelineBucketParams{UserID: user.ID, FromAt: from, ToAt: to})
	} else {
		var mixed []db.TimelineBucketWithPartnersRow
		mixed, err = s.queries.TimelineBucketWithPartners(ctx, db.TimelineBucketWithPartnersParams{UserID: user.ID, FromAt: from, ToAt: to})
		for i := range mixed {
			rows = append(rows, db.TimelineBucketRow(mixed[i]))
		}
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeBucket(w, month, rows, user.ID, false)
}

// writeBucket hides what belongs to the owner alone, such as favorites, from everyone else.
func writeBucket(w http.ResponseWriter, month string, rows []db.TimelineBucketRow, viewer pgtype.UUID, oldestFirst bool) {
	if oldestFirst {
		slices.Reverse(rows)
	}
	items := make([]api.TimelineItem, len(rows))
	for i := range rows {
		row := &rows[i]
		mine := row.UserID == viewer
		items[i] = api.TimelineItem{
			Id:         uuid.UUID(row.ID.Bytes),
			Kind:       api.TimelineItemKind(row.Kind),
			Ratio:      ratioOf(row.AspectRatio, row.Width, row.Height),
			IsFavorite: row.IsFavorite && mine,
			IsLive:     optional(row.IsLive, row.IsLive),
			StackSize:  optional(int(row.StackMembers)+1, mine && row.StackMembers > 0),
			IsShared:   optional(true, !mine),
			DurationMs: optional(row.DurationMs.Int64, row.DurationMs.Valid),
			LocalAt:    row.LocalAt.Time.Format(localTimeLayout),
		}
		if row.Blurhash.Valid {
			items[i].Blurhash = &row.Blurhash.String
		}
	}
	writeJSON(w, http.StatusOK, api.TimelineBucket{Month: month, Items: items})
}

func optional[T any](value T, valid bool) *T {
	if !valid {
		return nil
	}
	return &value
}

func (s *apiServer) GetAsset(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	ctx := r.Context()
	row, err := s.queries.GetVisibleAsset(ctx, db.GetVisibleAssetParams{ID: pgUUID(id), UserID: user.ID})
	if db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "no such asset")
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	detail, err := s.assetDetail(ctx, &row)
	if err != nil {
		internalError(w, r, err)
		return
	}
	owner := row.UserID == user.ID
	detail.IsOwner = &owner
	detail.DownloadAllowed = optional(true, true)
	if owner {
		tags, err := s.queries.ListAssetTags(ctx, row.ID)
		if err != nil {
			internalError(w, r, err)
			return
		}
		detail.Tags = &tags
		stack, err := s.stackOf(ctx, &row)
		if err != nil {
			internalError(w, r, err)
			return
		}
		detail.Stack = stack
		people, err := s.queries.ListAssetPeople(ctx, row.ID)
		if err != nil {
			internalError(w, r, err)
			return
		}
		refs := make([]api.PersonRef, len(people))
		for i := range people {
			refs[i] = api.PersonRef{Id: people[i].ID.Bytes, Name: people[i].Name}
		}
		detail.People = &refs
	}
	if !owner {
		// Someone else's favorites and archive are their own business. Their neighbours too:
		// the client moves through the album it is showing.
		detail.IsFavorite, detail.IsArchived = false, false
		writeJSON(w, http.StatusOK, detail)
		return
	}
	if newer, err := s.queries.NewerAsset(ctx, db.NewerAssetParams{UserID: user.ID, LocalAt: row.LocalAt, ID: row.ID}); err == nil {
		value := openapi_types.UUID(newer.Bytes)
		detail.NewerId = &value
	} else if !db.IsNotFound(err) {
		internalError(w, r, err)
		return
	}
	if older, err := s.queries.OlderAsset(ctx, db.OlderAssetParams{UserID: user.ID, LocalAt: row.LocalAt, ID: row.ID}); err == nil {
		value := openapi_types.UUID(older.Bytes)
		detail.OlderId = &value
	} else if !db.IsNotFound(err) {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, detail)
}

func (s *apiServer) assetDetail(ctx context.Context, row *db.Asset) (api.AssetDetail, error) {
	detail := api.AssetDetail{
		Id:             row.ID.Bytes,
		OriginalName:   row.OriginalName,
		Kind:           api.AssetDetailKind(row.Kind),
		Status:         api.AssetDetailStatus(row.Status),
		MimeType:       optional(row.MimeType.String, row.MimeType.Valid),
		SizeBytes:      row.SizeBytes,
		Width:          optional(int(row.Width.Int32), row.Width.Valid),
		Height:         optional(int(row.Height.Int32), row.Height.Valid),
		IsFavorite:     row.IsFavorite,
		IsArchived:     row.ArchivedAt.Valid,
		LocalAt:        row.LocalAt.Time.Format(localTimeLayout),
		OffsetMinutes:  optional(int(row.TakenOffsetMinutes.Int32), row.TakenOffsetMinutes.Valid),
		HasCaptureTime: optional(row.TakenAt.Valid, true),
		CreatedAt:      row.CreatedAt.Time,
	}
	if err := s.addMediaDetails(ctx, row, &detail); err != nil {
		return detail, err
	}
	exif, err := s.queries.GetExif(ctx, row.ID)
	if db.IsNotFound(err) {
		return detail, nil
	}
	if err != nil {
		return detail, err
	}
	camera := strings.TrimSpace(exif.Make.String + " " + exif.Model.String)
	detail.Camera = optional(camera, camera != "")
	detail.Lens = optional(exif.Lens.String, exif.Lens.Valid)
	detail.Iso = optional(int(exif.Iso.Int32), exif.Iso.Valid)
	detail.FNumber = optional(exif.FNumber.Float64, exif.FNumber.Valid)
	detail.ExposureTime = optional(exif.ExposureTime.String, exif.ExposureTime.Valid)
	detail.FocalLength = optional(exif.FocalLength.Float64, exif.FocalLength.Valid)
	detail.Latitude = optional(exif.Latitude.Float64, exif.Latitude.Valid)
	detail.Longitude = optional(exif.Longitude.Float64, exif.Longitude.Valid)
	detail.City = optional(exif.City.String, exif.City.Valid)
	detail.State = optional(exif.State.String, exif.State.Valid)
	detail.Country = optional(exif.Country.String, exif.Country.Valid)
	return detail, nil
}

func (s *apiServer) addMediaDetails(ctx context.Context, row *db.Asset, detail *api.AssetDetail) error {
	detail.DurationMs = optional(row.DurationMs.Int64, row.DurationMs.Valid)
	detail.VideoCodec = optional(row.VideoCodec.String, row.VideoCodec.Valid)

	hasFile := func(kind string) (bool, error) {
		_, err := s.queries.GetAssetFile(ctx, db.GetAssetFileParams{AssetID: row.ID, Kind: kind})
		if db.IsNotFound(err) {
			return false, nil
		}
		return err == nil, err
	}
	hls, err := hasFile("hls")
	if err != nil {
		return err
	}
	motion, err := hasFile("motion_video")
	if err != nil {
		return err
	}
	detail.HlsReady = optional(hls, hls)
	detail.HasMotion = optional(motion, motion)

	live, err := s.queries.GetLiveVideo(ctx, row.ID)
	if err == nil {
		value := openapi_types.UUID(live.Bytes)
		detail.LiveVideoId = &value
	} else if !db.IsNotFound(err) {
		return err
	}
	if row.SpriteColumns.Valid {
		detail.Sprite = &api.Sprite{
			Columns:    int(row.SpriteColumns.Int32),
			Rows:       int(row.SpriteRows.Int32),
			Count:      int(row.SpriteCount.Int32),
			IntervalMs: int(row.SpriteIntervalMs.Int32),
		}
	}
	return nil
}

func (s *apiServer) GetAssetThumbnail(w http.ResponseWriter, r *http.Request, id openapi_types.UUID, params api.GetAssetThumbnailParams) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	kind := "thumb_small"
	if params.Size != nil && *params.Size == api.GetAssetThumbnailParamsSizeLarge {
		kind = "thumb_large"
	}
	if params.Size != nil && *params.Size == api.GetAssetThumbnailParamsSizeFull {
		row, err := s.queries.GetVisibleAsset(r.Context(), db.GetVisibleAssetParams{ID: pgUUID(id), UserID: user.ID})
		if db.IsNotFound(err) {
			writeError(w, http.StatusNotFound, "no such asset")
			return
		}
		if err != nil {
			internalError(w, r, err)
			return
		}
		s.serveFullPreview(w, r, &row)
		return
	}
	path, err := s.queries.GetVisibleAssetFile(r.Context(), db.GetVisibleAssetFileParams{AssetID: pgUUID(id), Kind: kind, UserID: user.ID})
	if db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "no such thumbnail")
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	w.Header().Set("Content-Type", "image/webp")
	w.Header().Set("Cache-Control", thumbCacheAge)
	w.Header().Set("X-Content-Type-Options", "nosniff")
	serveFile(w, r, path)
}

// serveFullPreview makes the full resolution preview on first request and keeps it. Only a few run
// at once, because a RAW decode takes a lot of CPU and memory.
func (s *apiServer) serveFullPreview(w http.ResponseWriter, r *http.Request, row *db.Asset) {
	ctx := r.Context()
	if row.Kind != "photo" || row.Status != "ready" {
		writeError(w, http.StatusNotFound, "this asset has no full preview")
		return
	}

	path, err := s.queries.GetAssetFile(ctx, db.GetAssetFileParams{AssetID: row.ID, Kind: "thumb_full"})
	if db.IsNotFound(err) {
		path, err = s.makeFullPreview(ctx, row)
	}
	if err != nil {
		var unreadable interface{ Unreadable() bool }
		if errors.As(err, &unreadable) && unreadable.Unreadable() {
			writeError(w, http.StatusNotFound, "this file cannot be shown in full")
			return
		}
		internalError(w, r, err)
		return
	}
	w.Header().Set("Content-Type", "image/webp")
	w.Header().Set("Cache-Control", thumbCacheAge)
	w.Header().Set("X-Content-Type-Options", "nosniff")
	serveFile(w, r, path)
}

func (s *apiServer) makeFullPreview(ctx context.Context, row *db.Asset) (string, error) {
	select {
	case s.fullPreviews <- struct{}{}:
		defer func() { <-s.fullPreviews }()
	case <-ctx.Done():
		return "", ctx.Err()
	}
	// Someone may have finished the same one while this request waited its turn.
	if path, err := s.queries.GetAssetFile(ctx, db.GetAssetFileParams{AssetID: row.ID, Kind: "thumb_full"}); err == nil {
		return path, nil
	}
	id := uuid.UUID(row.ID.Bytes).String()
	dest := filepath.Join(s.CachePath, "thumbs", uuid.UUID(row.UserID.Bytes).String(), id[:2], id+"-full.webp")
	if err := jobs.MakeFullPreview(ctx, row.OriginalPath, dest); err != nil {
		return "", err
	}
	info, err := os.Stat(dest) //nolint:gosec // Built from the cache folder and IDs from the database.
	if err != nil {
		return "", err
	}
	err = s.queries.UpsertAssetFile(ctx, db.UpsertAssetFileParams{AssetID: row.ID, Kind: "thumb_full", Path: dest, SizeBytes: info.Size()})
	return dest, err
}

func (s *apiServer) GetAssetMotion(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	path, err := s.queries.GetVisibleAssetFile(r.Context(), db.GetVisibleAssetFileParams{AssetID: pgUUID(id), Kind: "motion_video", UserID: user.ID})
	if db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "no such video")
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	w.Header().Set("Content-Type", "video/mp4")
	w.Header().Set("X-Content-Type-Options", "nosniff")
	w.Header().Set("Cache-Control", thumbCacheAge)
	serveFile(w, r, path)
}

var hlsFileName = regexp.MustCompile(`^(master|[0-9]+)\.m3u8$|^[0-9]+_[0-9]+\.ts$`)

// GetAssetVideoFile serves HLS files. The name must match exactly, so it can never leave the folder.
func (s *apiServer) GetAssetVideoFile(w http.ResponseWriter, r *http.Request, id openapi_types.UUID, file string) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	s.serveVideoFile(w, r, file, func(kind string) (string, error) {
		return s.queries.GetVisibleAssetFile(r.Context(), db.GetVisibleAssetFileParams{AssetID: pgUUID(id), Kind: kind, UserID: user.ID})
	})
}

func (s *apiServer) serveVideoFile(w http.ResponseWriter, r *http.Request, file string, lookup func(kind string) (string, error)) {
	kind, name, contentType := "hls", file, "video/mp2t"
	switch {
	case file == "sprite.jpg":
		kind, contentType = "sprite", "image/jpeg"
	case !hlsFileName.MatchString(file):
		writeError(w, http.StatusNotFound, "no such file")
		return
	case strings.HasSuffix(file, ".m3u8"):
		contentType = "application/vnd.apple.mpegurl"
	}
	path, err := lookup(kind)
	if db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "no such file")
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	if kind == "hls" {
		path = filepath.Join(path, name)
	}
	w.Header().Set("Content-Type", contentType)
	w.Header().Set("X-Content-Type-Options", "nosniff")
	w.Header().Set("Cache-Control", thumbCacheAge)
	serveFile(w, r, path)
}

func serveFile(w http.ResponseWriter, r *http.Request, path string) {
	f, err := os.Open(path) //nolint:gosec // From the database, and video file names must match hlsFileName first.
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			slog.Error("file in the database is missing on disk", "path", path)
			w.Header().Del("Cache-Control")
			writeError(w, http.StatusNotFound, "the file is missing")
			return
		}
		internalError(w, r, err)
		return
	}
	defer func() { _ = f.Close() }()
	info, err := f.Stat()
	if err != nil {
		internalError(w, r, err)
		return
	}
	http.ServeContent(w, r, "", info.ModTime(), f)
}

func (s *apiServer) GetAssetOriginal(w http.ResponseWriter, r *http.Request, id openapi_types.UUID, params api.GetAssetOriginalParams) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	row, err := s.queries.GetVisibleAsset(r.Context(), db.GetVisibleAssetParams{ID: pgUUID(id), UserID: user.ID})
	if db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "no such asset")
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	serveOriginal(w, r, &row, params.Download != nil && *params.Download)
}

func serveOriginal(w http.ResponseWriter, r *http.Request, row *db.Asset, download bool) {
	inline := inlineTypes[row.MimeType.String] && !download
	contentType, disposition := "application/octet-stream", "attachment"
	if inline {
		contentType, disposition = row.MimeType.String, "inline"
	}
	w.Header().Set("Content-Type", contentType)
	w.Header().Set("Content-Disposition", mime.FormatMediaType(disposition, map[string]string{"filename": row.OriginalName}))
	w.Header().Set("X-Content-Type-Options", "nosniff")
	w.Header().Set("Content-Security-Policy", "default-src 'none'; sandbox")
	w.Header().Set("Cache-Control", "private, no-cache")
	serveFile(w, r, row.OriginalPath)
}

func (s *apiServer) BulkAssets(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	var body api.BulkRequest
	if !readJSON(w, r, &body) {
		return
	}
	if len(body.Ids) == 0 || len(body.Ids) > maxBulkIDs {
		writeError(w, http.StatusBadRequest, fmt.Sprintf("send between 1 and %d assets", maxBulkIDs))
		return
	}
	ids := make([]pgtype.UUID, len(body.Ids))
	for i, id := range body.Ids {
		ids[i] = pgUUID(id)
	}

	var changed int64
	var err error
	ctx := r.Context()
	switch body.Action {
	case api.BulkRequestActionFavorite:
		changed, err = s.queries.SetFavorite(ctx, db.SetFavoriteParams{UserID: user.ID, Column2: ids, IsFavorite: true})
	case api.BulkRequestActionUnfavorite:
		changed, err = s.queries.SetFavorite(ctx, db.SetFavoriteParams{UserID: user.ID, Column2: ids, IsFavorite: false})
	case api.BulkRequestActionArchive:
		changed, err = s.queries.ArchiveAssets(ctx, db.ArchiveAssetsParams{UserID: user.ID, Column2: ids})
	case api.BulkRequestActionUnarchive:
		changed, err = s.queries.UnarchiveAssets(ctx, db.UnarchiveAssetsParams{UserID: user.ID, Column2: ids})
	case api.BulkRequestActionDelete:
		changed, err = s.queries.SoftDeleteAssets(ctx, db.SoftDeleteAssetsParams{UserID: user.ID, Column2: ids})
	case api.BulkRequestActionRestore:
		changed, err = s.queries.RestoreAssets(ctx, db.RestoreAssetsParams{UserID: user.ID, Column2: ids})
	case api.BulkRequestActionVault, api.BulkRequestActionUnvault, api.BulkRequestActionPurge:
		var ok bool
		changed, ok, err = s.vaultOrPurge(w, r, user, body.Action, ids)
		if !ok {
			return
		}
	default:
		writeError(w, http.StatusBadRequest, "unknown action")
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, api.BulkResponse{Changed: changed})
}

// DownloadAssets streams a ZIP without compression: photos and videos are already compressed.
func (s *apiServer) DownloadAssets(w http.ResponseWriter, r *http.Request, params api.DownloadAssetsParams) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	parts := strings.Split(params.Ids, ",")
	if len(parts) > maxZipIDs {
		writeError(w, http.StatusBadRequest, fmt.Sprintf("download at most %d files at once", maxZipIDs))
		return
	}
	ids := make([]pgtype.UUID, 0, len(parts))
	for _, part := range parts {
		id, err := uuid.Parse(strings.TrimSpace(part))
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid asset id")
			return
		}
		ids = append(ids, pgtype.UUID{Bytes: id, Valid: true})
	}
	rows, err := s.queries.ListVisibleAssets(r.Context(), db.ListVisibleAssetsParams{Ids: ids, UserID: user.ID})
	if err != nil {
		internalError(w, r, err)
		return
	}
	if len(rows) == 0 {
		writeError(w, http.StatusNotFound, "no such assets")
		return
	}

	w.Header().Set("Content-Type", "application/zip")
	w.Header().Set("Content-Disposition", mime.FormatMediaType("attachment", map[string]string{"filename": "mediarr-" + strconv.Itoa(len(rows)) + "-files.zip"}))
	archive := zip.NewWriter(w)
	used := map[string]int{}
	for i := range rows {
		if err := addToZip(archive, &rows[i], used); err != nil {
			// The status is already sent, so the only signal left is a broken ZIP.
			slog.Error("download failed", "asset", uuid.UUID(rows[i].ID.Bytes).String(), "error", err)
			panic(http.ErrAbortHandler)
		}
	}
	if err := archive.Close(); err != nil {
		slog.Error("finish download", "error", err)
	}
}

func addToZip(archive *zip.Writer, row *db.Asset, used map[string]int) error {
	f, err := os.Open(row.OriginalPath)
	if err != nil {
		return err
	}
	defer func() { _ = f.Close() }()

	name := filepath.Base(row.OriginalName)
	used[name]++
	if count := used[name]; count > 1 {
		ext := filepath.Ext(name)
		name = fmt.Sprintf("%s (%d)%s", strings.TrimSuffix(name, ext), count, ext)
	}
	entry, err := archive.CreateHeader(&zip.FileHeader{Name: name, Method: zip.Store, Modified: row.CreatedAt.Time})
	if err != nil {
		return err
	}
	_, err = io.Copy(entry, f)
	return err
}
