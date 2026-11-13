package app

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/auth"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

// A TV fetches what it shows by itself, without the cookie of the phone or browser that sent it. It
// gets addresses under /api/tv/{token}/, where the token opens only the assets sent to it, for a few
// hours, and nothing else: no lists, no details, no originals of photos.
const (
	castLifetime     = 4 * time.Hour
	castPathPrefix   = "/api/tv/"
	maxCastAssets    = 5000
	maxCastPerCall   = 500
	castImageSize    = "3840x2160"
	castCacheControl = "private, max-age=3600"
)

func castMediaPath(token string, id uuid.UUID) string {
	return castPathPrefix + token + "/assets/" + id.String()
}

func (s *apiServer) castIDs(w http.ResponseWriter, r *http.Request, user *db.User) ([]db.CastableAssetsRow, bool) {
	var body api.CastAssets
	if !readJSON(w, r, &body) {
		return nil, false
	}
	if len(body.Ids) == 0 || len(body.Ids) > maxCastPerCall {
		writeError(w, http.StatusBadRequest, fmt.Sprintf("send between 1 and %d assets", maxCastPerCall))
		return nil, false
	}
	ids := make([]pgtype.UUID, len(body.Ids))
	for i, id := range body.Ids {
		ids[i] = pgUUID(id)
	}
	rows, err := s.queries.CastableAssets(r.Context(), db.CastableAssetsParams{Ids: ids, UserID: user.ID})
	if err != nil {
		internalError(w, r, err)
		return nil, false
	}
	if len(rows) == 0 {
		// The same answer for what does not exist and for what is someone else's.
		writeError(w, http.StatusNotFound, "none of these can be shown on a TV")
		return nil, false
	}
	return rows, true
}

// castMedia says where a TV finds each asset. The token is only known while the session is started,
// so later answers give paths without it for the client to fill in.
func (s *apiServer) castMedia(ctx context.Context, token string, rows []db.CastableAssetsRow) ([]api.CastMedia, error) {
	out := make([]api.CastMedia, 0, len(rows))
	for _, row := range rows {
		id := uuid.UUID(row.ID.Bytes)
		base := castMediaPath(token, id)
		media := api.CastMedia{Id: id, Kind: api.CastMediaKind(row.Kind), Image: base + "/image"}
		if row.Kind == "video" {
			asset, err := s.queries.GetAsset(ctx, row.ID)
			if err != nil {
				return nil, err
			}
			media.File = new(base + "/original")
			media.MimeType = optional(asset.MimeType.String, asset.MimeType.Valid)
			media.DurationMs = optional(asset.DurationMs.Int64, asset.DurationMs.Valid)
			if _, err := s.queries.GetAssetFile(ctx, db.GetAssetFileParams{AssetID: row.ID, Kind: "hls"}); err == nil {
				media.Hls = new(base + "/video/master.m3u8")
			} else if !db.IsNotFound(err) {
				return nil, err
			}
		}
		out = append(out, media)
	}
	return out, nil
}

func castIDList(rows []db.CastableAssetsRow) []pgtype.UUID {
	ids := make([]pgtype.UUID, len(rows))
	for i, row := range rows {
		ids[i] = row.ID
	}
	return ids
}

func (s *apiServer) CreateCastSession(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	rows, ok := s.castIDs(w, r, user)
	if !ok {
		return
	}
	ctx := r.Context()
	if err := s.queries.DeleteExpiredCastSessions(ctx); err != nil {
		internalError(w, r, err)
		return
	}
	token, hash, err := auth.NewToken()
	if err != nil {
		internalError(w, r, err)
		return
	}
	session, err := s.queries.CreateCastSession(ctx, db.CreateCastSessionParams{
		UserID: user.ID, TokenHash: hash, ExpiresAt: pgtype.Timestamptz{Time: time.Now().Add(castLifetime), Valid: true},
	})
	if err != nil {
		internalError(w, r, err)
		return
	}
	if err := s.queries.AddCastAssets(ctx, db.AddCastAssetsParams{SessionID: session.ID, Ids: castIDList(rows)}); err != nil {
		internalError(w, r, err)
		return
	}
	media, err := s.castMedia(ctx, token, rows)
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusCreated, api.CastSession{
		Id: session.ID.Bytes, Token: &token, ExpiresAt: session.ExpiresAt.Time, Media: media,
	})
}

func (s *apiServer) AddCastAssets(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	ctx := r.Context()
	session, err := s.queries.GetCastSession(ctx, db.GetCastSessionParams{ID: pgUUID(id), UserID: user.ID})
	if db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "this TV session has ended")
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	rows, ok := s.castIDs(w, r, user)
	if !ok {
		return
	}
	count, err := s.queries.CountCastAssets(ctx, session.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	if count+int64(len(rows)) > maxCastAssets {
		writeError(w, http.StatusBadRequest, "this TV session has shown enough; start casting again")
		return
	}
	if err := s.queries.AddCastAssets(ctx, db.AddCastAssetsParams{SessionID: session.ID, Ids: castIDList(rows)}); err != nil {
		internalError(w, r, err)
		return
	}
	// The token is not kept, so the paths carry a placeholder the client replaces with its own.
	media, err := s.castMedia(ctx, "{token}", rows)
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, api.CastSession{Id: session.ID.Bytes, ExpiresAt: session.ExpiresAt.Time, Media: media})
}

func (s *apiServer) DeleteCastSession(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	removed, err := s.queries.DeleteCastSession(r.Context(), db.DeleteCastSessionParams{ID: pgUUID(id), UserID: user.ID})
	if err != nil {
		internalError(w, r, err)
		return
	}
	if removed == 0 {
		writeError(w, http.StatusNotFound, "no such TV session")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// castAsset finds an asset by a TV's token. Wrong, expired, stopped and not sent all look the same.
func (s *apiServer) castAsset(w http.ResponseWriter, r *http.Request, token string, id openapi_types.UUID) (*db.Asset, pgtype.UUID, bool) {
	row, err := s.queries.GetCastAsset(r.Context(), db.GetCastAssetParams{TokenHash: auth.HashToken(token), AssetID: pgUUID(id)})
	if db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "not available")
		return nil, pgtype.UUID{}, false
	}
	if err != nil {
		internalError(w, r, err)
		return nil, pgtype.UUID{}, false
	}
	return &row.Asset, row.CastUserID, true
}

func (s *apiServer) GetCastImage(w http.ResponseWriter, r *http.Request, token string, id openapi_types.UUID) {
	row, _, ok := s.castAsset(w, r, token, id)
	if !ok {
		return
	}
	s.serveTVImage(w, r, row)
}

// serveTVImage gives a JPEG, which every TV shows, of the picture as it looks after its edits, at
// most 4K and without any metadata: no location, no camera, no date.
func (s *apiServer) serveTVImage(w http.ResponseWriter, r *http.Request, row *db.Asset) {
	ctx := r.Context()
	id := uuid.UUID(row.ID.Bytes).String()
	dest := filepath.Join(s.CachePath, "tv", id[:2], fmt.Sprintf("%s-r%d.jpg", id, row.EditRevision))
	if _, err := os.Stat(dest); err != nil { //nolint:gosec // Made of the cache folder and an id from the database.
		var source string
		var err error
		if row.Kind == "photo" {
			source, err = s.fullPreviewFile(ctx, row)
		} else {
			source, err = s.queries.GetAssetFile(ctx, db.GetAssetFileParams{AssetID: row.ID, Kind: "thumb_large"})
		}
		if db.IsNotFound(err) {
			writeError(w, http.StatusNotFound, "no picture yet")
			return
		}
		if err != nil {
			internalError(w, r, err)
			return
		}
		if err := s.makeTVCopy(ctx, dest, func(ctx context.Context) error { return tvJPEG(ctx, source, dest) }); err != nil {
			internalError(w, r, err)
			return
		}
	}
	w.Header().Set("Content-Type", "image/jpeg")
	w.Header().Set("Cache-Control", castCacheControl)
	w.Header().Set("X-Content-Type-Options", "nosniff")
	// A Chromecast's receiver is a web page on another origin.
	w.Header().Set("Access-Control-Allow-Origin", "*")
	serveFile(w, r, dest)
}

// makeTVCopy runs build once for dest, however many requests want it at the same time: a TV and a
// phone asking for one video then share a single copy of the whole file. The copy does not stop when
// one request goes away, since the others still wait for it and the next one finds it made; a
// request that goes away only stops waiting.
func (s *apiServer) makeTVCopy(ctx context.Context, dest string, build func(context.Context) error) error {
	done := s.tvCopies.DoChan(dest, func() (any, error) {
		if _, err := os.Stat(dest); err == nil { //nolint:gosec // Made by the caller from the cache folder and an id.
			return nil, nil
		}
		return nil, build(context.WithoutCancel(ctx))
	})
	select {
	case result := <-done:
		return result.Err
	case <-ctx.Done():
		return ctx.Err()
	}
}

func tvJPEG(ctx context.Context, source, dest string) error {
	if err := os.MkdirAll(filepath.Dir(dest), 0o750); err != nil { //nolint:gosec // As above.
		return err
	}
	ctx, cancel := context.WithTimeout(ctx, shareWait)
	defer cancel()
	tmp := strings.TrimSuffix(dest, ".jpg") + fmt.Sprintf(".tmp%d.jpg", time.Now().UnixNano())
	//nolint:gosec // Both paths are made here, not taken from the request.
	if err := exec.CommandContext(ctx, "vipsthumbnail", source, "--size", castImageSize+">", "-o", tmp+"[Q=88,strip]").Run(); err != nil {
		_ = os.Remove(tmp)
		return err
	}
	return os.Rename(tmp, dest) //nolint:gosec // As above.
}

var plainExtension = regexp.MustCompile(`^\.[a-z0-9]{1,5}$`)

func (s *apiServer) GetCastOriginal(w http.ResponseWriter, r *http.Request, token string, id openapi_types.UUID) {
	row, viewer, ok := s.castAsset(w, r, token, id)
	if !ok {
		return
	}
	s.serveTVVideo(w, r, row, viewer)
}

// serveTVVideo gives the original of a video, without its location. A photo's original never goes:
// the picture is enough for a TV, and the original carries everything the camera wrote.
func (s *apiServer) serveTVVideo(w http.ResponseWriter, r *http.Request, row *db.Asset, viewer pgtype.UUID) {
	if row.Kind != "video" {
		writeError(w, http.StatusForbidden, "only a video's file goes to a TV")
		return
	}
	cropped, err := s.croppedForViewer(r.Context(), row, viewer)
	if err != nil {
		internalError(w, r, err)
		return
	}
	if cropped {
		writeError(w, http.StatusNotFound, "the owner has edited this, so its video is not shared")
		return
	}
	id := uuid.UUID(row.ID.Bytes).String()
	// The name comes from the camera or whoever uploaded it, so only a plain extension is kept.
	ext := strings.ToLower(filepath.Ext(row.OriginalName))
	if !plainExtension.MatchString(ext) {
		ext = ".mp4"
	}
	dest := filepath.Join(s.CachePath, "tv", id[:2], id+"-nolocation"+ext)
	if _, err := os.Stat(dest); err != nil { //nolint:gosec // The cache folder, an id from the database and a checked extension.
		if err := s.makeTVCopy(r.Context(), dest, func(ctx context.Context) error {
			return jobs.StripLocation(ctx, row.OriginalPath, dest)
		}); err != nil {
			// Never the original instead, which is the very thing this avoids.
			writeError(w, http.StatusForbidden, "this video cannot be shown without its location")
			return
		}
	}
	copied := *row
	copied.OriginalPath = dest
	w.Header().Set("Access-Control-Allow-Origin", "*")
	serveOriginal(w, r, &copied, false)
}

func (s *apiServer) GetCastVideoFile(w http.ResponseWriter, r *http.Request, token string, id openapi_types.UUID, file string) {
	row, viewer, ok := s.castAsset(w, r, token, id)
	if !ok {
		return
	}
	if file == "sprite.jpg" {
		writeError(w, http.StatusNotFound, "no such file")
		return
	}
	cropped, err := s.croppedForViewer(r.Context(), row, viewer)
	if err != nil {
		internalError(w, r, err)
		return
	}
	if cropped {
		writeError(w, http.StatusNotFound, "the owner has edited this, so its video is not shared")
		return
	}
	w.Header().Set("Access-Control-Allow-Origin", "*")
	s.serveVideoFile(w, r, file, func(kind string) (string, error) {
		return s.queries.GetAssetFile(r.Context(), db.GetAssetFileParams{AssetID: row.ID, Kind: kind})
	})
}
