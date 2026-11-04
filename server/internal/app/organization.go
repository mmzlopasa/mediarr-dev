package app

import (
	"context"
	"net/http"
	"regexp"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgtype"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/auth"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

const (
	vaultCookie         = "mediarr_vault"
	vaultTokenHeader    = "X-Vault-Token" //nolint:gosec // A header name, not a credential.
	vaultSessionTime    = 15 * time.Minute
	vaultPinFailures    = 5
	collectionVault     = "vault"
	maxTagLength        = 100
	collectionCacheRule = "private, no-store"
)

var vaultPin = regexp.MustCompile(`^[0-9]{4,12}$`)

func (s *apiServer) vaultUnlocked(r *http.Request, user *db.User) (bool, error) {
	token := r.Header.Get(vaultTokenHeader)
	if token == "" {
		cookie, err := r.Cookie(vaultCookie)
		if err != nil {
			return false, nil //nolint:nilerr // No cookie simply means locked.
		}
		token = cookie.Value
	}
	return s.queries.VaultSessionValid(r.Context(), db.VaultSessionValidParams{TokenHash: auth.HashToken(token), UserID: user.ID})
}

// collection answers who is asking, and refuses the vault while it is locked.
func (s *apiServer) collection(w http.ResponseWriter, r *http.Request, scope string) (*db.User, bool) {
	user := requireUser(w, r)
	if user == nil {
		return nil, false
	}
	if scope == collectionVault {
		unlocked, err := s.vaultUnlocked(r, user)
		if err != nil {
			internalError(w, r, err)
			return nil, false
		}
		if !unlocked {
			writeError(w, http.StatusUnauthorized, "the vault is locked")
			return nil, false
		}
	}
	return user, true
}

func (s *apiServer) GetCollectionBuckets(w http.ResponseWriter, r *http.Request, scope api.GetCollectionBucketsParamsScope) {
	user, ok := s.collection(w, r, string(scope))
	if !ok {
		return
	}
	rows, err := s.queries.CollectionBuckets(r.Context(), db.CollectionBucketsParams{UserID: user.ID, Scope: string(scope)})
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := make([]db.TimelineBucketsRow, len(rows))
	for i, row := range rows {
		out[i] = db.TimelineBucketsRow(row)
	}
	writeBuckets(w, out, false)
}

func (s *apiServer) GetCollectionBucket(w http.ResponseWriter, r *http.Request, scope api.GetCollectionBucketParamsScope, month string) {
	user, ok := s.collection(w, r, string(scope))
	if !ok {
		return
	}
	from, to, ok := monthRange(w, month)
	if !ok {
		return
	}
	rows, err := s.queries.CollectionBucket(r.Context(), db.CollectionBucketParams{UserID: user.ID, FromAt: from, ToAt: to, Scope: string(scope)})
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

func (s *apiServer) collectionAsset(w http.ResponseWriter, r *http.Request, scope string, id openapi_types.UUID) (*db.Asset, bool) {
	user, ok := s.collection(w, r, scope)
	if !ok {
		return nil, false
	}
	row, err := s.queries.GetCollectionAsset(r.Context(), db.GetCollectionAssetParams{ID: pgUUID(id), UserID: user.ID, Scope: scope})
	if db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "no such asset")
		return nil, false
	}
	if err != nil {
		internalError(w, r, err)
		return nil, false
	}
	return &row, true
}

func (s *apiServer) GetCollectionAsset(w http.ResponseWriter, r *http.Request, scope api.GetCollectionAssetParamsScope, id openapi_types.UUID) {
	row, ok := s.collectionAsset(w, r, string(scope), id)
	if !ok {
		return
	}
	detail, err := s.assetDetail(r.Context(), row)
	if err != nil {
		internalError(w, r, err)
		return
	}
	// Here a photo is only looked at. Moving it out goes through the collection's own actions.
	detail.IsOwner = optional(false, true)
	detail.DownloadAllowed = optional(true, true)
	writeJSON(w, http.StatusOK, detail)
}

// A vault's files must not stay in a browser's cache after it locks.
func collectionCache(scope string) string {
	if scope == collectionVault {
		return collectionCacheRule
	}
	return thumbCacheAge
}

func (s *apiServer) GetCollectionThumbnail(w http.ResponseWriter, r *http.Request, scope api.GetCollectionThumbnailParamsScope, id openapi_types.UUID, params api.GetCollectionThumbnailParams) {
	row, ok := s.collectionAsset(w, r, string(scope), id)
	if !ok {
		return
	}
	kind := "thumb_small"
	if params.Size != nil && *params.Size == api.GetCollectionThumbnailParamsSizeLarge {
		kind = "thumb_large"
	}
	if params.Size != nil && *params.Size == api.GetCollectionThumbnailParamsSizeFull {
		s.serveFullPreview(w, r, row)
		return
	}
	path, err := s.queries.GetAssetFile(r.Context(), db.GetAssetFileParams{AssetID: row.ID, Kind: kind})
	if db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "no such thumbnail")
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	w.Header().Set("Content-Type", "image/webp")
	w.Header().Set("Cache-Control", collectionCache(string(scope)))
	w.Header().Set("X-Content-Type-Options", "nosniff")
	serveFile(w, r, path)
}

func (s *apiServer) GetCollectionOriginal(w http.ResponseWriter, r *http.Request, scope api.GetCollectionOriginalParamsScope, id openapi_types.UUID, params api.GetCollectionOriginalParams) {
	row, ok := s.collectionAsset(w, r, string(scope), id)
	if !ok {
		return
	}
	serveOriginal(w, r, row, params.Download != nil && *params.Download)
}

func (s *apiServer) GetCollectionMotion(w http.ResponseWriter, r *http.Request, scope api.GetCollectionMotionParamsScope, id openapi_types.UUID) {
	row, ok := s.collectionAsset(w, r, string(scope), id)
	if !ok {
		return
	}
	path, err := s.queries.GetAssetFile(r.Context(), db.GetAssetFileParams{AssetID: row.ID, Kind: "motion_video"})
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
	w.Header().Set("Cache-Control", collectionCache(string(scope)))
	serveFile(w, r, path)
}

func (s *apiServer) GetCollectionVideoFile(w http.ResponseWriter, r *http.Request, scope api.GetCollectionVideoFileParamsScope, id openapi_types.UUID, file string) {
	row, ok := s.collectionAsset(w, r, string(scope), id)
	if !ok {
		return
	}
	s.serveVideoFile(w, r, file, func(kind string) (string, error) {
		return s.queries.GetAssetFile(r.Context(), db.GetAssetFileParams{AssetID: row.ID, Kind: kind})
	})
}

// vaultOrPurge runs the bulk actions that touch the vault or delete for good.
func (s *apiServer) vaultOrPurge(w http.ResponseWriter, r *http.Request, user *db.User, action api.BulkRequestAction, ids []pgtype.UUID) (int64, bool, error) {
	ctx := r.Context()
	unlocked, err := s.vaultUnlocked(r, user)
	if err != nil {
		return 0, true, err
	}
	switch action {
	case api.BulkRequestActionVault:
		if !user.VaultPinHash.Valid {
			writeError(w, http.StatusBadRequest, "set a vault PIN first")
			return 0, false, nil
		}
		changed, err := s.queries.MoveToVault(ctx, db.MoveToVaultParams{UserID: user.ID, Column2: ids})
		return changed, true, err
	case api.BulkRequestActionUnvault:
		if !unlocked {
			writeError(w, http.StatusUnauthorized, "the vault is locked")
			return 0, false, nil
		}
		changed, err := s.queries.MoveOutOfVault(ctx, db.MoveOutOfVaultParams{UserID: user.ID, Column2: ids})
		return changed, true, err
	default:
		purgeable, err := s.queries.ListPurgeable(ctx, db.ListPurgeableParams{UserID: user.ID, Ids: ids, InVault: unlocked})
		if err != nil {
			return 0, true, err
		}
		if len(purgeable) == 0 {
			return 0, true, nil
		}
		return int64(len(purgeable)), true, jobs.PurgeAssets(ctx, s.queries, s.CachePath, purgeable)
	}
}

func (s *apiServer) EmptyTrash(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	ctx := r.Context()
	var total int64
	for {
		ids, err := s.queries.ListTrash(ctx, user.ID)
		if err != nil {
			internalError(w, r, err)
			return
		}
		if len(ids) == 0 {
			break
		}
		if err := jobs.PurgeAssets(ctx, s.queries, s.CachePath, ids); err != nil {
			internalError(w, r, err)
			return
		}
		total += int64(len(ids))
	}
	writeJSON(w, http.StatusOK, api.BulkResponse{Changed: total})
}

func (s *apiServer) GetVaultStatus(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	unlocked, err := s.vaultUnlocked(r, user)
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, api.VaultStatus{HasPin: user.VaultPinHash.Valid, Unlocked: unlocked})
}

// checkPin counts failures per user, so a stolen session cannot try every PIN.
func (s *apiServer) checkPin(w http.ResponseWriter, user *db.User, pin string) bool {
	key := user.Email
	if !s.vaultPins.Allowed(key) {
		writeError(w, http.StatusTooManyRequests, "too many attempts; try again later")
		return false
	}
	if !auth.VerifyPassword(user.VaultPinHash.String, pin) {
		s.vaultPins.Fail(key)
		writeError(w, http.StatusUnauthorized, "wrong PIN")
		return false
	}
	s.vaultPins.Reset(key)
	return true
}

func (s *apiServer) SetVaultPin(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	var body api.VaultPinChange
	if !readJSON(w, r, &body) {
		return
	}
	if !vaultPin.MatchString(body.Pin) {
		writeError(w, http.StatusBadRequest, "the PIN must have between 4 and 12 digits")
		return
	}
	if user.VaultPinHash.Valid {
		current := ""
		if body.CurrentPin != nil {
			current = *body.CurrentPin
		}
		if !s.checkPin(w, user, current) {
			return
		}
	}
	hash, err := auth.HashPassword(body.Pin)
	if err != nil {
		internalError(w, r, err)
		return
	}
	ctx := r.Context()
	if err := s.queries.SetVaultPin(ctx, db.SetVaultPinParams{ID: user.ID, VaultPinHash: pgtype.Text{String: hash, Valid: true}}); err != nil {
		internalError(w, r, err)
		return
	}
	if err := s.queries.DeleteVaultSessions(ctx, user.ID); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) UnlockVault(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	var body api.VaultUnlock
	if !readJSON(w, r, &body) {
		return
	}
	if !user.VaultPinHash.Valid {
		writeError(w, http.StatusBadRequest, "set a vault PIN first")
		return
	}
	if !s.checkPin(w, user, body.Pin) {
		return
	}
	token, hash, err := auth.NewToken()
	if err != nil {
		internalError(w, r, err)
		return
	}
	expires := time.Now().Add(vaultSessionTime)
	if err := s.queries.CreateVaultSession(r.Context(), db.CreateVaultSessionParams{
		TokenHash: hash, UserID: user.ID, ExpiresAt: pgtype.Timestamptz{Time: expires, Valid: true},
	}); err != nil {
		internalError(w, r, err)
		return
	}
	http.SetCookie(w, &http.Cookie{
		Name: vaultCookie, Value: token, Path: "/api", Expires: expires,
		HttpOnly: true, SameSite: http.SameSiteLaxMode, Secure: isHTTPS(r),
	})
	writeJSON(w, http.StatusOK, api.VaultSession{Token: token})
}

func (s *apiServer) LockVault(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	if err := s.queries.DeleteVaultSessions(r.Context(), user.ID); err != nil {
		internalError(w, r, err)
		return
	}
	http.SetCookie(w, &http.Cookie{
		Name: vaultCookie, Path: "/api", MaxAge: -1,
		HttpOnly: true, SameSite: http.SameSiteLaxMode, Secure: isHTTPS(r),
	})
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) ListTags(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	rows, err := s.queries.ListTags(r.Context(), user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := make([]api.Tag, len(rows))
	for i, row := range rows {
		out[i] = api.Tag{Id: row.ID.Bytes, Name: row.Name, AssetCount: row.AssetCount}
	}
	writeJSON(w, http.StatusOK, out)
}

func (s *apiServer) DeleteTag(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	removed, err := s.queries.DeleteTag(r.Context(), db.DeleteTagParams{ID: pgUUID(id), UserID: user.ID})
	if err != nil {
		internalError(w, r, err)
		return
	}
	if removed == 0 {
		writeError(w, http.StatusNotFound, "no such tag")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) ownTag(ctx context.Context, w http.ResponseWriter, r *http.Request, id openapi_types.UUID) (*db.User, bool) {
	user := requireUser(w, r)
	if user == nil {
		return nil, false
	}
	_, err := s.queries.GetTag(ctx, db.GetTagParams{ID: pgUUID(id), UserID: user.ID})
	if db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "no such tag")
		return nil, false
	}
	if err != nil {
		internalError(w, r, err)
		return nil, false
	}
	return user, true
}

func (s *apiServer) GetTagBuckets(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	ctx := r.Context()
	if _, ok := s.ownTag(ctx, w, r, id); !ok {
		return
	}
	rows, err := s.queries.TagBuckets(ctx, pgUUID(id))
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := make([]db.TimelineBucketsRow, len(rows))
	for i, row := range rows {
		out[i] = db.TimelineBucketsRow(row)
	}
	writeBuckets(w, out, false)
}

func (s *apiServer) GetTagBucket(w http.ResponseWriter, r *http.Request, id openapi_types.UUID, month string) {
	ctx := r.Context()
	user, ok := s.ownTag(ctx, w, r, id)
	if !ok {
		return
	}
	from, to, ok := monthRange(w, month)
	if !ok {
		return
	}
	rows, err := s.queries.TagBucket(ctx, db.TagBucketParams{TagID: pgUUID(id), FromAt: from, ToAt: to})
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

func (s *apiServer) ChangeAssetTags(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	var body api.AssetTagChange
	if !readJSON(w, r, &body) {
		return
	}
	name := strings.TrimSpace(body.Name)
	if name == "" || len([]rune(name)) > maxTagLength {
		writeError(w, http.StatusBadRequest, "a tag must have between 1 and 100 characters")
		return
	}
	if len(body.Ids) == 0 || len(body.Ids) > maxBulkIDs {
		writeError(w, http.StatusBadRequest, "send between 1 and 1000 assets")
		return
	}
	ids := make([]pgtype.UUID, len(body.Ids))
	for i, id := range body.Ids {
		ids[i] = pgUUID(id)
	}
	ctx := r.Context()
	if body.Remove != nil && *body.Remove {
		changed, err := s.queries.UntagAssets(ctx, db.UntagAssetsParams{UserID: user.ID, Ids: ids, Name: name})
		if err != nil {
			internalError(w, r, err)
			return
		}
		writeJSON(w, http.StatusOK, api.BulkResponse{Changed: changed})
		return
	}
	tag, err := s.queries.EnsureTag(ctx, db.EnsureTagParams{UserID: user.ID, Name: name})
	if err != nil {
		internalError(w, r, err)
		return
	}
	changed, err := s.queries.TagAssets(ctx, db.TagAssetsParams{TagID: tag, UserID: user.ID, Ids: ids})
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, api.BulkResponse{Changed: changed})
}
