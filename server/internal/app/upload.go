package app

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	stdslog "log/slog"
	"net/http"
	"os"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/tus/tusd/v2/pkg/filelocker"
	"github.com/tus/tusd/v2/pkg/filestore"
	tusd "github.com/tus/tusd/v2/pkg/handler"
	"golang.org/x/exp/slog"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
	"github.com/mediarr-app/mediarr/server/internal/storage"
)

const (
	uploadBasePath  = "/api/uploads/"
	metaUserID      = "user_id"
	metaFilename    = "filename"
	metaChecksum    = "checksum"
	metaModified    = "lastModified"
	metaAlbum       = "albumId"
	metaGuest       = "guest"
	maxAssetListLen = 200
	defaultListLen  = 50
)

var (
	uploadID    = regexp.MustCompile(`^[0-9a-f]{32}$`)
	checksumHex = regexp.MustCompile(`^[0-9a-f]{64}$`)
)

func (s *apiServer) newUploadHandler() (*tusd.UnroutedHandler, error) {
	tmp := storage.TmpDir(s.LibraryPath)
	if err := os.MkdirAll(tmp, 0o750); err != nil {
		return nil, fmt.Errorf("create upload directory: %w", err)
	}
	composer := tusd.NewStoreComposer()
	filestore.New(tmp).UseIn(composer)
	filelocker.New(tmp).UseIn(composer)

	return tusd.NewUnroutedHandler(tusd.Config{
		BasePath:        uploadBasePath,
		StoreComposer:   composer,
		DisableDownload: true,
		// It reads other uploads by a path from the client, which could reach any readable file.
		DisableConcatenation:      true,
		RespectForwardedHeaders:   true,
		Cors:                      &tusd.CorsConfig{Disable: true},
		Logger:                    slog.New(slog.NewTextHandler(io.Discard, nil)),
		PreUploadCreateCallback:   s.beforeUpload,
		PreFinishResponseCallback: s.finishUpload,
	})
}

// beforeUpload ties the upload to the signed-in user and rejects bad metadata early.
func (s *apiServer) beforeUpload(hook tusd.HookEvent) (tusd.HTTPResponse, tusd.FileInfoChanges, error) {
	user, ok := hook.Context.Value(userKey{}).(*db.User)
	if !ok || user == nil {
		return tusd.HTTPResponse{}, tusd.FileInfoChanges{}, tusd.NewError("ERR_UNAUTHORIZED", "sign in first", http.StatusUnauthorized)
	}
	// A size given only later would get past the checks below, which run once, here.
	if hook.Upload.SizeIsDeferred {
		return tusd.HTTPResponse{}, tusd.FileInfoChanges{}, tusd.NewError("ERR_SIZE_NEEDED", "say the size of the file at the start", http.StatusBadRequest)
	}
	if hook.Upload.IsFinal || hook.Upload.IsPartial {
		return tusd.HTTPResponse{}, tusd.FileInfoChanges{}, tusd.NewError("ERR_NO_CONCAT", "uploads cannot be put together", http.StatusBadRequest)
	}
	if err := s.checkDiskRoom(hook.Upload.Size); err != nil {
		return tusd.HTTPResponse{}, tusd.FileInfoChanges{}, err
	}
	if user.QuotaBytes.Valid {
		stored, err := s.queries.UserStoredBytes(hook.Context, user.ID)
		if err != nil {
			return tusd.HTTPResponse{}, tusd.FileInfoChanges{}, err
		}
		if stored+hook.Upload.Size > user.QuotaBytes.Int64 {
			return tusd.HTTPResponse{}, tusd.FileInfoChanges{}, tusd.NewError("ERR_QUOTA", "this account has reached its storage limit", http.StatusRequestEntityTooLarge)
		}
	}
	meta := hook.Upload.MetaData
	if sum := meta[metaChecksum]; sum != "" && !checksumHex.MatchString(sum) {
		return tusd.HTTPResponse{}, tusd.FileInfoChanges{}, tusd.NewError("ERR_BAD_CHECKSUM", "checksum must be lowercase hex SHA-256", http.StatusBadRequest)
	}
	// Only known keys are kept, and the owner always comes from the session, never from the client.
	changes := tusd.MetaData{
		metaUserID:   uuid.UUID(user.ID.Bytes).String(),
		metaFilename: storage.SafeName(meta[metaFilename]),
		metaChecksum: meta[metaChecksum],
		metaModified: meta[metaModified],
	}
	// A guest's album comes from the link they opened, never from what they send.
	if album, ok := hook.Context.Value(guestAlbumKey{}).(pgtype.UUID); ok {
		changes[metaAlbum] = uuid.UUID(album.Bytes).String()
		changes[metaGuest] = "true"
	} else if wanted := meta[metaAlbum]; wanted != "" {
		id, err := uuid.Parse(wanted)
		if err != nil || !s.canUploadToAlbum(hook.Context, id, user.ID) {
			return tusd.HTTPResponse{}, tusd.FileInfoChanges{}, tusd.NewError("ERR_ALBUM_FORBIDDEN", "you cannot add photos to this album", http.StatusForbidden)
		}
		changes[metaAlbum] = id.String()
	}
	return tusd.HTTPResponse{}, tusd.FileInfoChanges{MetaData: changes}, nil
}

func hashFile(path string) ([]byte, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer func() { _ = f.Close() }()
	h := sha256.New()
	if _, err := io.Copy(h, f); err != nil {
		return nil, err
	}
	return h.Sum(nil), nil
}

func uploadTime(modified string) time.Time {
	if ms, err := strconv.ParseInt(modified, 10, 64); err == nil && ms > 0 {
		when := time.UnixMilli(ms)
		if when.Before(time.Now().Add(24*time.Hour)) && when.Year() >= 1970 {
			return when
		}
	}
	return time.Now()
}

// finishUpload verifies a finished upload and publishes it. It runs before the last response, so
// the client learns the result, and a failure leaves the upload in place to retry.
func (s *apiServer) finishUpload(hook tusd.HookEvent) (tusd.HTTPResponse, error) {
	ctx := hook.Context
	tmp := hook.Upload.Storage["Path"]
	infoFile := hook.Upload.Storage["InfoPath"]
	if tmp == "" {
		return tusd.HTTPResponse{}, errors.New("upload has no stored file")
	}

	sum, err := hashFile(tmp)
	if err != nil {
		return tusd.HTTPResponse{}, fmt.Errorf("hash upload: %w", err)
	}
	sumHex := hex.EncodeToString(sum)
	meta := hook.Upload.MetaData
	if claimed := meta[metaChecksum]; claimed != "" && claimed != sumHex {
		removeUpload(tmp, infoFile)
		return tusd.HTTPResponse{}, tusd.NewError("ERR_CHECKSUM_MISMATCH", "the uploaded data does not match its checksum", 460)
	}

	owner, err := uuid.Parse(meta[metaUserID])
	if err != nil {
		return tusd.HTTPResponse{}, fmt.Errorf("upload has no owner: %w", err)
	}
	userID := pgtype.UUID{Bytes: owner, Valid: true}
	name := meta[metaFilename]
	dest := storage.OriginalPath(s.LibraryPath, owner.String(), uploadTime(meta[metaModified]), sumHex, name)

	guest := meta[metaGuest] == "true"
	assetID, duplicate, err := s.storeAsset(ctx, userID, sum, name, dest, tmp, hook.Upload.Size, !guest)
	if err != nil {
		return tusd.HTTPResponse{}, err
	}
	if duplicate {
		removeUpload(tmp)
	}
	removeUpload(infoFile)
	if err := s.addUploadToAlbum(ctx, meta[metaAlbum], guest, userID, assetID); err != nil {
		return tusd.HTTPResponse{}, err
	}
	if guest {
		// A guest learns nothing about the owner's library, not even whether a file was already in it.
		return tusd.HTTPResponse{}, nil
	}

	return tusd.HTTPResponse{Header: tusd.HTTPHeader{
		"X-Asset-Id":        uuid.UUID(assetID.Bytes).String(),
		"X-Asset-Duplicate": strconv.FormatBool(duplicate),
	}}, nil
}

// storeAsset publishes the file inside the transaction: if the commit fails, the next attempt
// overwrites the same path with the same content, so nothing is lost or duplicated.
func (s *apiServer) storeAsset(ctx context.Context, userID pgtype.UUID, sum []byte, name, dest, tmp string, size int64, restore bool) (pgtype.UUID, bool, error) {
	var assetID pgtype.UUID
	duplicate := false
	err := pgx.BeginFunc(ctx, s.Pool, func(tx pgx.Tx) error {
		q := s.queries.WithTx(tx)
		// Two statements on purpose: an insert that lost a race to a simultaneous upload waits for it,
		// and only a new statement can see the row that upload committed.
		if err := q.CreateUploadLibrary(ctx, userID); err != nil {
			return fmt.Errorf("create library: %w", err)
		}
		library, err := q.GetUploadLibrary(ctx, userID)
		if err != nil {
			return fmt.Errorf("find library: %w", err)
		}
		assetID, err = q.InsertAsset(ctx, db.InsertAssetParams{
			UserID: userID, LibraryID: library, Checksum: sum, OriginalName: name, OriginalPath: dest, SizeBytes: size,
		})
		if db.IsNotFound(err) {
			duplicate = true
			assetID, err = q.GetAssetIDByChecksum(ctx, db.GetAssetIDByChecksumParams{UserID: userID, Checksum: sum})
			if err != nil {
				return err
			}
			// Uploading a deleted file again brings it back, instead of leaving it hidden. Only the
			// owner's own upload does: a guest cannot undo what the owner deleted.
			if !restore {
				return nil
			}
			return q.RestoreDeletedAsset(ctx, assetID)
		}
		if err != nil {
			return fmt.Errorf("insert asset: %w", err)
		}
		if _, err := s.Inserter.InsertTx(ctx, tx, jobs.MetadataArgs{AssetID: assetID.Bytes}, nil); err != nil {
			return fmt.Errorf("queue metadata job: %w", err)
		}
		return storage.Publish(tmp, dest)
	})
	return assetID, duplicate, err
}

func removeUpload(paths ...string) {
	for _, path := range paths {
		if path == "" {
			continue
		}
		if err := os.Remove(path); err != nil && !errors.Is(err, os.ErrNotExist) {
			stdslog.Warn("remove finished upload", "path", path, "error", err)
		}
	}
}

// ownsUpload stops one user from reading or changing another user's upload.
func (s *apiServer) ownsUpload(w http.ResponseWriter, r *http.Request, id string) bool {
	user := requireUser(w, r)
	if user == nil {
		return false
	}
	if !uploadID.MatchString(id) {
		writeError(w, http.StatusNotFound, "no such upload")
		return false
	}
	store := filestore.New(storage.TmpDir(s.LibraryPath))
	upload, err := store.GetUpload(r.Context(), id)
	if err != nil {
		writeError(w, http.StatusNotFound, "no such upload")
		return false
	}
	info, err := upload.GetInfo(r.Context())
	if err != nil || info.MetaData[metaUserID] != uuid.UUID(user.ID.Bytes).String() {
		writeError(w, http.StatusNotFound, "no such upload")
		return false
	}
	return true
}

func (s *apiServer) CreateUpload(w http.ResponseWriter, r *http.Request) {
	if requireUser(w, r) == nil {
		return
	}
	s.uploads.Middleware(http.HandlerFunc(s.uploads.PostFile)).ServeHTTP(w, r)
}

func (s *apiServer) GetUploadOffset(w http.ResponseWriter, r *http.Request, id string) {
	if s.ownsUpload(w, r, id) {
		http.StripPrefix(uploadBasePath, s.uploads.Middleware(http.HandlerFunc(s.uploads.HeadFile))).ServeHTTP(w, r)
	}
}

func (s *apiServer) AppendUpload(w http.ResponseWriter, r *http.Request, id string) {
	if s.ownsUpload(w, r, id) {
		http.StripPrefix(uploadBasePath, s.uploads.Middleware(http.HandlerFunc(s.uploads.PatchFile))).ServeHTTP(w, r)
	}
}

func (s *apiServer) CancelUpload(w http.ResponseWriter, r *http.Request, id string) {
	if s.ownsUpload(w, r, id) {
		http.StripPrefix(uploadBasePath, s.uploads.Middleware(http.HandlerFunc(s.uploads.DelFile))).ServeHTTP(w, r)
	}
}

func (s *apiServer) ListAssets(w http.ResponseWriter, r *http.Request, params api.ListAssetsParams) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	limit := defaultListLen
	if params.Limit != nil {
		limit = min(max(*params.Limit, 1), maxAssetListLen)
	}
	filter := pgtype.Text{}
	if params.Status != nil {
		filter = pgtype.Text{String: string(*params.Status), Valid: true}
	}
	rows, err := s.queries.ListAssets(r.Context(), db.ListAssetsParams{UserID: user.ID, Status: filter, RowLimit: int32(limit)}) //nolint:gosec // Bounded above.
	if err != nil {
		internalError(w, r, err)
		return
	}
	counts, err := s.queries.CountAssetStatus(r.Context(), user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	items := make([]api.Asset, len(rows))
	for i := range rows {
		items[i] = toAPIAsset(&rows[i])
	}
	writeJSON(w, http.StatusOK, api.AssetList{Items: items, Total: counts.Total, Processing: counts.Processing, Failed: counts.Failed})
}

func toAPIAsset(row *db.Asset) api.Asset {
	asset := api.Asset{
		Id:           uuid.UUID(row.ID.Bytes),
		OriginalName: row.OriginalName,
		Kind:         api.AssetKind(row.Kind),
		Status:       api.AssetStatus(row.Status),
		SizeBytes:    row.SizeBytes,
		Checksum:     hex.EncodeToString(row.Checksum),
		CreatedAt:    row.CreatedAt.Time,
	}
	if row.Error.Valid {
		asset.Error = &row.Error.String
	}
	if row.Blurhash.Valid {
		asset.Blurhash = &row.Blurhash.String
	}
	if row.Width.Valid {
		width := int(row.Width.Int32)
		asset.Width = &width
	}
	if row.Height.Valid {
		height := int(row.Height.Int32)
		asset.Height = &height
	}
	if row.TakenAt.Valid {
		asset.TakenAt = &row.TakenAt.Time
	}
	return asset
}

func (s *apiServer) CheckAssets(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	var body api.ChecksumCheckRequest
	if !readJSON(w, r, &body) {
		return
	}
	if len(body.Checksums) > 1000 {
		writeError(w, http.StatusBadRequest, "too many checksums")
		return
	}
	sums := make([][]byte, 0, len(body.Checksums))
	for _, value := range body.Checksums {
		value = strings.ToLower(value)
		if !checksumHex.MatchString(value) {
			writeError(w, http.StatusBadRequest, "checksums must be hex SHA-256")
			return
		}
		sum, err := hex.DecodeString(value)
		if err != nil {
			writeError(w, http.StatusBadRequest, "checksums must be hex SHA-256")
			return
		}
		sums = append(sums, sum)
	}
	found, err := s.queries.FindExistingChecksums(r.Context(), db.FindExistingChecksumsParams{UserID: user.ID, Column2: sums})
	if err != nil {
		internalError(w, r, err)
		return
	}
	existing := make([]string, len(found))
	for i, sum := range found {
		existing[i] = hex.EncodeToString(sum)
	}
	writeJSON(w, http.StatusOK, api.ChecksumCheckResponse{Existing: existing})
}
