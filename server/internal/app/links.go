package app

import (
	"context"
	"encoding/hex"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/mmzlopasa/mediarr-app/server/db"
	"github.com/mmzlopasa/mediarr-app/server/internal/api"
	"github.com/mmzlopasa/mediarr-app/server/internal/auth"
	"github.com/mmzlopasa/mediarr-app/server/internal/jobs"
)

const (
	publicPathPrefix     = "/api/public/"
	linkCookie           = "mediarr_link"
	linkSessionLifetime  = 24 * time.Hour
	linkPasswordFailures = 10
	maxGuestFileBytes    = 20 << 30
	guestBytesPerDay     = 200 << 30
	linkUploadsPerHour   = 500
	maxWatermark         = 100
	publicCacheAge       = "private, max-age=3600"
)

type guestAlbumKey struct{}

func toAPILink(row *db.ShareLink) api.ShareLink {
	out := api.ShareLink{
		Id: row.ID.Bytes, Label: row.Label, HasPassword: row.PasswordHash.Valid,
		DownloadCount: int(row.DownloadCount), AllowDownload: row.AllowDownload, AllowUpload: row.AllowUpload,
		UploadOnly: row.UploadOnly, ShowLocation: row.ShowLocation, CreatedAt: row.CreatedAt.Time,
		ExpiresAt:     optional(row.ExpiresAt.Time, row.ExpiresAt.Valid),
		DownloadLimit: optional(int(row.DownloadLimit.Int32), row.DownloadLimit.Valid),
		Watermark:     optional(row.Watermark.String, row.Watermark.Valid),
	}
	return out
}

func (s *apiServer) ListAlbumLinks(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	album, _, ok := s.album(w, r, id, roleOwner)
	if !ok {
		return
	}
	rows, err := s.queries.ListLinks(r.Context(), album.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := make([]api.ShareLink, len(rows))
	for i := range rows {
		out[i] = toAPILink(&rows[i])
	}
	writeJSON(w, http.StatusOK, out)
}

func flag(value *bool, fallback bool) bool {
	if value == nil {
		return fallback
	}
	return *value
}

func (s *apiServer) CreateAlbumLink(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	album, _, ok := s.album(w, r, id, roleOwner)
	if !ok {
		return
	}
	var body api.ShareLinkCreate
	if !readJSON(w, r, &body) {
		return
	}
	uploadOnly := flag(body.UploadOnly, false)
	allowUpload := flag(body.AllowUpload, false) || uploadOnly
	if allowUpload && album.Rules != nil {
		writeError(w, http.StatusBadRequest, "a smart album fills itself from its rules, so it cannot receive uploads")
		return
	}
	params := db.CreateLinkParams{
		AlbumID: album.ID, AllowDownload: flag(body.AllowDownload, true) && !uploadOnly,
		AllowUpload: allowUpload, UploadOnly: uploadOnly, ShowLocation: flag(body.ShowLocation, false) && !uploadOnly,
	}
	if body.Label != nil {
		params.Label = strings.TrimSpace(*body.Label)
	}
	if body.ExpiresAt != nil {
		if !body.ExpiresAt.After(time.Now()) {
			writeError(w, http.StatusBadRequest, "the expiry must be in the future")
			return
		}
		params.ExpiresAt = pgtype.Timestamptz{Time: *body.ExpiresAt, Valid: true}
	}
	if body.DownloadLimit != nil {
		if *body.DownloadLimit < 1 || *body.DownloadLimit > 1_000_000 {
			writeError(w, http.StatusBadRequest, "the download limit must be at least 1")
			return
		}
		params.DownloadLimit = pgtype.Int4{Int32: int32(*body.DownloadLimit), Valid: true} //nolint:gosec // Bounded above.
	}
	if body.Watermark != nil {
		text := strings.TrimSpace(*body.Watermark)
		if len([]rune(text)) > maxWatermark {
			writeError(w, http.StatusBadRequest, "the watermark is too long")
			return
		}
		if text != "" {
			params.Watermark = pgtype.Text{String: text, Valid: true}
			// The original has no watermark, so downloading it would get around one.
			params.AllowDownload = false
		}
	}
	if body.Password != nil && *body.Password != "" {
		hash, err := auth.HashPassword(*body.Password)
		if err != nil {
			internalError(w, r, err)
			return
		}
		params.PasswordHash = pgtype.Text{String: hash, Valid: true}
	}
	token, hash, err := auth.NewToken()
	if err != nil {
		internalError(w, r, err)
		return
	}
	params.TokenHash = hash
	row, err := s.queries.CreateLink(r.Context(), params)
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := toAPILink(&row)
	out.Token = &token
	writeJSON(w, http.StatusCreated, out)
}

func (s *apiServer) DeleteAlbumLink(w http.ResponseWriter, r *http.Request, id, linkID openapi_types.UUID) {
	album, _, ok := s.album(w, r, id, roleOwner)
	if !ok {
		return
	}
	removed, err := s.queries.DeleteLink(r.Context(), db.DeleteLinkParams{ID: pgUUID(linkID), AlbumID: album.ID})
	if err != nil {
		internalError(w, r, err)
		return
	}
	if removed == 0 {
		writeError(w, http.StatusNotFound, "no such link")
		return
	}
	s.removeLinkCache(pgUUID(linkID))
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) linkCacheDir(id pgtype.UUID) string {
	return filepath.Join(s.CachePath, "links", uuid.UUID(id.Bytes).String())
}

func (s *apiServer) removeLinkCache(id pgtype.UUID) {
	_ = os.RemoveAll(s.linkCacheDir(id))
}

// Public side: everything below works without an account and gives only what the link allows.

func (s *apiServer) publicLink(w http.ResponseWriter, r *http.Request, token string) (*db.GetLinkByTokenRow, bool) {
	row, err := s.queries.GetLinkByToken(r.Context(), auth.HashToken(token))
	if db.IsNotFound(err) {
		// Wrong, expired and revoked look the same.
		writeError(w, http.StatusNotFound, "this link is not available")
		return nil, false
	}
	if err != nil {
		internalError(w, r, err)
		return nil, false
	}
	return &row, true
}

func (s *apiServer) linkUnlocked(r *http.Request, link *db.GetLinkByTokenRow) (bool, error) {
	if !link.PasswordHash.Valid {
		return true, nil
	}
	cookie, err := r.Cookie(linkCookie)
	if err != nil {
		return false, nil //nolint:nilerr // No cookie simply means locked.
	}
	return s.queries.LinkSessionValid(r.Context(), db.LinkSessionValidParams{TokenHash: auth.HashToken(cookie.Value), LinkID: link.ID})
}

func (s *apiServer) openLink(w http.ResponseWriter, r *http.Request, token string) (*db.GetLinkByTokenRow, bool) {
	link, ok := s.publicLink(w, r, token)
	if !ok {
		return nil, false
	}
	unlocked, err := s.linkUnlocked(r, link)
	if err != nil {
		internalError(w, r, err)
		return nil, false
	}
	if !unlocked {
		writeError(w, http.StatusUnauthorized, "this link needs a password")
		return nil, false
	}
	return link, true
}

// viewLink opens a link for looking at the album, which an upload-only link never allows.
func (s *apiServer) viewLink(w http.ResponseWriter, r *http.Request, token string) (*db.GetLinkByTokenRow, bool) {
	link, ok := s.openLink(w, r, token)
	if !ok {
		return nil, false
	}
	if link.UploadOnly {
		writeError(w, http.StatusForbidden, "this link only receives files")
		return nil, false
	}
	return link, true
}

func (s *apiServer) viewLinkAsset(w http.ResponseWriter, r *http.Request, token string, id openapi_types.UUID) (*db.GetLinkByTokenRow, bool) {
	link, ok := s.viewLink(w, r, token)
	if !ok || !s.assetInAlbum(w, r, link.AlbumID, pgUUID(id)) {
		return nil, false
	}
	return link, true
}

func (s *apiServer) GetPublicLink(w http.ResponseWriter, r *http.Request, token string) {
	link, ok := s.publicLink(w, r, token)
	if !ok {
		return
	}
	unlocked, err := s.linkUnlocked(r, link)
	if err != nil {
		internalError(w, r, err)
		return
	}
	if !unlocked {
		writeJSON(w, http.StatusOK, api.PublicLink{Locked: true})
		return
	}
	kiosk, err := s.featureOn(r.Context(), featureKiosk)
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := api.PublicLink{
		Kiosk:         kiosk,
		AllowDownload: link.AllowDownload, AllowUpload: link.AllowUpload,
		UploadOnly: link.UploadOnly, Watermarked: link.Watermark.Valid,
	}
	out.Title = &link.Title
	if link.Description != "" {
		out.Description = &link.Description
	}
	writeJSON(w, http.StatusOK, out)
}

func (s *apiServer) UnlockPublicLink(w http.ResponseWriter, r *http.Request, token string) {
	link, ok := s.publicLink(w, r, token)
	if !ok {
		return
	}
	var body api.LinkPassword
	if !readJSON(w, r, &body) {
		return
	}
	if !link.PasswordHash.Valid {
		w.WriteHeader(http.StatusNoContent)
		return
	}
	key := hex.EncodeToString(link.TokenHash) + "|" + clientIP(r)
	if !s.linkPasswords.Allowed(key) {
		writeError(w, http.StatusTooManyRequests, "too many attempts; try again later")
		return
	}
	if !auth.VerifyPassword(link.PasswordHash.String, body.Password) {
		s.linkPasswords.Fail(key)
		writeError(w, http.StatusUnauthorized, "wrong password")
		return
	}
	s.linkPasswords.Reset(key)
	session, hash, err := auth.NewToken()
	if err != nil {
		internalError(w, r, err)
		return
	}
	ctx := r.Context()
	expires := time.Now().Add(linkSessionLifetime)
	if err := s.queries.DeleteExpiredLinkSessions(ctx); err != nil {
		internalError(w, r, err)
		return
	}
	if err := s.queries.CreateLinkSession(ctx, db.CreateLinkSessionParams{
		TokenHash: hash, LinkID: link.ID, ExpiresAt: pgtype.Timestamptz{Time: expires, Valid: true},
	}); err != nil {
		internalError(w, r, err)
		return
	}
	http.SetCookie(w, &http.Cookie{
		Name: linkCookie, Value: session, Path: publicPathPrefix + token, Expires: expires,
		HttpOnly: true, SameSite: http.SameSiteLaxMode, Secure: isHTTPS(r),
	})
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) GetPublicBuckets(w http.ResponseWriter, r *http.Request, token string) {
	link, ok := s.viewLink(w, r, token)
	if !ok {
		return
	}
	s.writeAlbumBuckets(w, r, link.AlbumID, link.AssetOrder)
}

func (s *apiServer) GetPublicBucket(w http.ResponseWriter, r *http.Request, token, month string) {
	link, ok := s.viewLink(w, r, token)
	if !ok {
		return
	}
	s.writeAlbumBucket(w, r, link.AlbumID, link.AssetOrder, month, pgtype.UUID{})
}

func downloadsLeft(link *db.GetLinkByTokenRow) bool {
	return link.AllowDownload && (!link.DownloadLimit.Valid || link.DownloadCount < link.DownloadLimit.Int32)
}

func (s *apiServer) GetPublicAsset(w http.ResponseWriter, r *http.Request, token string, id openapi_types.UUID) {
	link, ok := s.viewLinkAsset(w, r, token, id)
	if !ok {
		return
	}
	ctx := r.Context()
	row, err := s.queries.GetAsset(ctx, pgUUID(id))
	if err != nil {
		internalError(w, r, err)
		return
	}
	detail, err := s.assetDetail(ctx, &row)
	if err != nil {
		internalError(w, r, err)
		return
	}
	detail.IsOwner = optional(false, true)
	detail.IsFavorite, detail.IsArchived = false, false
	detail.DownloadAllowed = optional(downloadsLeft(link), true)
	if !link.ShowLocation {
		// A place name says where the photo was as well as coordinates do.
		detail.Latitude, detail.Longitude = nil, nil
		detail.City, detail.State, detail.Country = nil, nil, nil
	}
	if link.Watermark.Valid {
		// Only the marked previews exist on such a link, so nothing plays or opens unmarked.
		detail.HlsReady, detail.HasMotion, detail.LiveVideoId, detail.Sprite = nil, nil, nil, nil
	}
	writeJSON(w, http.StatusOK, detail)
}

func (s *apiServer) GetPublicThumbnail(w http.ResponseWriter, r *http.Request, token string, id openapi_types.UUID, params api.GetPublicThumbnailParams) {
	link, ok := s.viewLinkAsset(w, r, token, id)
	if !ok {
		return
	}
	ctx := r.Context()
	kind := "thumb_small"
	if params.Size != nil && *params.Size != api.GetPublicThumbnailParamsSizeSmall {
		kind = "thumb_large"
	}
	// Without downloads, a full size preview would be the download.
	if !link.Watermark.Valid && link.AllowDownload && params.Size != nil && *params.Size == api.GetPublicThumbnailParamsSizeFull {
		row, err := s.queries.GetAsset(ctx, pgUUID(id))
		if err != nil {
			internalError(w, r, err)
			return
		}
		s.serveFullPreview(w, r, &row)
		return
	}
	path, err := s.queries.GetAssetFile(ctx, db.GetAssetFileParams{AssetID: pgUUID(id), Kind: kind})
	if db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "no such thumbnail")
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	if link.Watermark.Valid {
		if path, err = s.watermarked(ctx, link, id, kind, path); err != nil {
			internalError(w, r, err)
			return
		}
	}
	w.Header().Set("Content-Type", "image/webp")
	w.Header().Set("Cache-Control", publicCacheAge)
	w.Header().Set("X-Content-Type-Options", "nosniff")
	serveFile(w, r, path)
}

// watermarked keeps each marked preview per link. Revoking the link removes them.
func (s *apiServer) watermarked(ctx context.Context, link *db.GetLinkByTokenRow, id uuid.UUID, kind, source string) (string, error) {
	dest := filepath.Join(s.linkCacheDir(link.ID), id.String()+"-"+kind+".webp")
	if _, err := os.Stat(dest); err == nil {
		return dest, nil
	}
	select {
	case s.fullPreviews <- struct{}{}:
		defer func() { <-s.fullPreviews }()
	case <-ctx.Done():
		return "", ctx.Err()
	}
	if err := jobs.Watermark(ctx, source, link.Watermark.String, dest); err != nil {
		return "", err
	}
	return dest, nil
}

func (s *apiServer) GetPublicOriginal(w http.ResponseWriter, r *http.Request, token string, id openapi_types.UUID, params api.GetPublicOriginalParams) {
	link, ok := s.viewLinkAsset(w, r, token, id)
	if !ok {
		return
	}
	ctx := r.Context()
	row, err := s.queries.GetAsset(ctx, pgUUID(id))
	if err != nil {
		internalError(w, r, err)
		return
	}
	download := params.Download != nil && *params.Download
	if !download {
		// Playback only: a video the server has not converted yet can be played only from the
		// original, which is why this needs the same permission as a download. Photos always have
		// previews, and a watermark must not be bypassed.
		ready, err := s.queries.GetAssetFile(ctx, db.GetAssetFileParams{AssetID: row.ID, Kind: "hls"})
		if err != nil && !db.IsNotFound(err) {
			internalError(w, r, err)
			return
		}
		if row.Kind != "video" || ready != "" || link.Watermark.Valid || !downloadsLeft(link) {
			writeError(w, http.StatusForbidden, "this link does not allow this file")
			return
		}
		s.serveLinkOriginal(w, r, link.ID, link.ShowLocation, &row, false)
		return
	}
	// Every request is one whole download. Honouring Range would let a client take a file piece by
	// piece and never reach the limit.
	r.Header.Del("Range")
	counted, err := s.queries.CountLinkDownload(ctx, link.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	if counted == 0 {
		writeError(w, http.StatusForbidden, "this link has no downloads left")
		return
	}
	s.serveLinkOriginal(w, r, link.ID, link.ShowLocation, &row, true)
}

// serveLinkOriginal gives a guest the file, without what the link does not share: the location, and
// what the owner cropped out.
func (s *apiServer) serveLinkOriginal(w http.ResponseWriter, r *http.Request, link pgtype.UUID, showLocation bool, row *db.Asset, download bool) {
	if len(row.Edits) > 0 {
		s.serveFullPreview(w, r, row)
		return
	}
	if showLocation {
		serveOriginal(w, r, row, download)
		return
	}
	id := uuid.UUID(row.ID.Bytes).String()
	dest := filepath.Join(s.linkCacheDir(link), id+"-nolocation"+strings.ToLower(filepath.Ext(row.OriginalName)))
	if _, err := os.Stat(dest); err != nil {
		if err := jobs.StripLocation(r.Context(), row.OriginalPath, dest); err != nil {
			// Never fall back to the original, which is the very thing this avoids.
			slog.Warn("a location could not be removed for a link", "asset", id, "error", err)
			writeError(w, http.StatusForbidden, "this file cannot be shared without its location")
			return
		}
	}
	copied := *row
	copied.OriginalPath = dest
	serveOriginal(w, r, &copied, download)
}

func (s *apiServer) GetPublicMotion(w http.ResponseWriter, r *http.Request, token string, id openapi_types.UUID) {
	link, ok := s.viewLinkAsset(w, r, token, id)
	if !ok {
		return
	}
	if link.Watermark.Valid {
		writeError(w, http.StatusForbidden, "this link shows only marked previews")
		return
	}
	path, err := s.queries.GetAssetFile(r.Context(), db.GetAssetFileParams{AssetID: pgUUID(id), Kind: "motion_video"})
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
	w.Header().Set("Cache-Control", publicCacheAge)
	serveFile(w, r, path)
}

func (s *apiServer) GetPublicVideoFile(w http.ResponseWriter, r *http.Request, token string, id openapi_types.UUID, file string) {
	link, ok := s.viewLinkAsset(w, r, token, id)
	if !ok {
		return
	}
	if link.Watermark.Valid {
		writeError(w, http.StatusForbidden, "this link shows only marked previews")
		return
	}
	s.serveVideoFile(w, r, file, func(kind string) (string, error) {
		return s.queries.GetAssetFile(r.Context(), db.GetAssetFileParams{AssetID: pgUUID(id), Kind: kind})
	})
}

// CreatePublicUpload takes one whole file in one request. A guest has no way to continue an upload
// later, so an upload that breaks is simply sent again.
func (s *apiServer) CreatePublicUpload(w http.ResponseWriter, r *http.Request, token string) {
	link, ok := s.openLink(w, r, token)
	if !ok {
		return
	}
	if !link.AllowUpload {
		writeError(w, http.StatusForbidden, "this link does not receive files")
		return
	}
	size, err := strconv.ParseInt(r.Header.Get("Upload-Length"), 10, 64)
	if err != nil || size <= 0 || r.ContentLength != size {
		writeError(w, http.StatusBadRequest, "send the whole file in one request")
		return
	}
	if size > maxGuestFileBytes {
		writeError(w, http.StatusRequestEntityTooLarge, "this file is too large for a shared link")
		return
	}
	if !s.guestBytes.spend(hex.EncodeToString(link.TokenHash), size, time.Now()) {
		writeError(w, http.StatusTooManyRequests, "this link has received a lot today; try again later")
		return
	}
	key := hex.EncodeToString(link.TokenHash) + "|" + clientIP(r)
	if !s.linkUploads.Allowed(key) {
		writeError(w, http.StatusTooManyRequests, "too many uploads; try again later")
		return
	}
	s.linkUploads.Fail(key)
	owner, err := s.queries.GetUserByID(r.Context(), link.OwnerID)
	if err != nil {
		if !errors.Is(err, context.Canceled) {
			internalError(w, r, err)
		}
		return
	}
	ctx := context.WithValue(r.Context(), userKey{}, &owner)
	ctx = context.WithValue(ctx, guestAlbumKey{}, link.AlbumID)
	s.uploads.Middleware(http.HandlerFunc(s.uploads.PostFile)).ServeHTTP(w, r.WithContext(ctx))
}

// byteBudget limits how much one link can receive in a day, so that a leaked link cannot fill the disk.
type byteBudget struct {
	mu    sync.Mutex
	spent map[string]budgetDay
}

type budgetDay struct {
	day   string
	bytes int64
}

func newByteBudget() *byteBudget { return &byteBudget{spent: map[string]budgetDay{}} }

func (b *byteBudget) spend(key string, size int64, now time.Time) bool {
	b.mu.Lock()
	defer b.mu.Unlock()
	today := now.UTC().Format(time.DateOnly)
	current := b.spent[key]
	if current.day != today {
		current = budgetDay{day: today}
	}
	if current.bytes+size > guestBytesPerDay {
		return false
	}
	current.bytes += size
	b.spent[key] = current
	return true
}
