package app

import (
	"archive/zip"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"mime"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/mmzlopasa/mediarr-app/server/db"
	"github.com/mmzlopasa/mediarr-app/server/internal/api"
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
	rows, err := s.queries.TimelineBuckets(r.Context(), user.ID)
	if err != nil {
		internalError(w, r, err)
		return
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

func (s *apiServer) GetTimelineBucket(w http.ResponseWriter, r *http.Request, month string) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	if !bucketMonth.MatchString(month) {
		writeError(w, http.StatusBadRequest, "month must look like 2024-07")
		return
	}
	from, err := time.Parse("2006-01", month)
	if err != nil {
		writeError(w, http.StatusBadRequest, "month must look like 2024-07")
		return
	}
	rows, err := s.queries.TimelineBucket(r.Context(), db.TimelineBucketParams{
		UserID: user.ID,
		FromAt: pgtype.Timestamp{Time: from, Valid: true},
		ToAt:   pgtype.Timestamp{Time: from.AddDate(0, 1, 0), Valid: true},
	})
	if err != nil {
		internalError(w, r, err)
		return
	}
	items := make([]api.TimelineItem, len(rows))
	for i := range rows {
		row := &rows[i]
		items[i] = api.TimelineItem{
			Id:         uuid.UUID(row.ID.Bytes),
			Kind:       api.TimelineItemKind(row.Kind),
			Ratio:      ratioOf(row.AspectRatio, row.Width, row.Height),
			IsFavorite: row.IsFavorite,
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
	row, err := s.queries.GetOwnedAsset(ctx, db.GetOwnedAssetParams{ID: pgUUID(id), UserID: user.ID})
	if db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "no such asset")
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	detail := api.AssetDetail{
		Id:             id,
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

	exif, err := s.queries.GetExif(ctx, row.ID)
	if err != nil && !db.IsNotFound(err) {
		internalError(w, r, err)
		return
	}
	if err == nil {
		camera := strings.TrimSpace(exif.Make.String + " " + exif.Model.String)
		detail.Camera = optional(camera, camera != "")
		detail.Lens = optional(exif.Lens.String, exif.Lens.Valid)
		detail.Iso = optional(int(exif.Iso.Int32), exif.Iso.Valid)
		detail.FNumber = optional(exif.FNumber.Float64, exif.FNumber.Valid)
		detail.ExposureTime = optional(exif.ExposureTime.String, exif.ExposureTime.Valid)
		detail.FocalLength = optional(exif.FocalLength.Float64, exif.FocalLength.Valid)
		detail.Latitude = optional(exif.Latitude.Float64, exif.Latitude.Valid)
		detail.Longitude = optional(exif.Longitude.Float64, exif.Longitude.Valid)
	}
	writeJSON(w, http.StatusOK, detail)
}

func (s *apiServer) GetAssetThumbnail(w http.ResponseWriter, r *http.Request, id openapi_types.UUID, params api.GetAssetThumbnailParams) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	kind := "thumb_small"
	if params.Size != nil && *params.Size == api.Large {
		kind = "thumb_large"
	}
	path, err := s.queries.GetOwnedAssetFile(r.Context(), db.GetOwnedAssetFileParams{AssetID: pgUUID(id), Kind: kind, UserID: user.ID})
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

func serveFile(w http.ResponseWriter, r *http.Request, path string) {
	f, err := os.Open(path)
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
	row, err := s.queries.GetOwnedAsset(r.Context(), db.GetOwnedAssetParams{ID: pgUUID(id), UserID: user.ID})
	if db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "no such asset")
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}

	inline := inlineTypes[row.MimeType.String] && (params.Download == nil || !*params.Download)
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
	case api.Favorite:
		changed, err = s.queries.SetFavorite(ctx, db.SetFavoriteParams{UserID: user.ID, Column2: ids, IsFavorite: true})
	case api.Unfavorite:
		changed, err = s.queries.SetFavorite(ctx, db.SetFavoriteParams{UserID: user.ID, Column2: ids, IsFavorite: false})
	case api.Archive:
		changed, err = s.queries.ArchiveAssets(ctx, db.ArchiveAssetsParams{UserID: user.ID, Column2: ids})
	case api.Delete:
		changed, err = s.queries.SoftDeleteAssets(ctx, db.SoftDeleteAssetsParams{UserID: user.ID, Column2: ids})
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
	rows, err := s.queries.ListOwnedAssets(r.Context(), db.ListOwnedAssetsParams{UserID: user.ID, Ids: ids})
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
