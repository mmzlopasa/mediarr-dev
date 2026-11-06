package app

import (
	"context"
	"mime"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/storage"
)

const (
	shareSmallSize = "2048x2048"
	shareWait      = 2 * time.Minute
)

// GetAssetShare gives a file to send to another app or keep on a phone. The original goes as it is,
// unless it has edits, which are sent as they look, or a smaller file is asked for. Either of those
// is a JPEG, which every app takes, and leaves out where the photo was taken.
func (s *apiServer) GetAssetShare(w http.ResponseWriter, r *http.Request, id openapi_types.UUID, params api.GetAssetShareParams) {
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
	if s.refuseCropped(w, r, row.ID, user.ID) {
		return
	}
	small := params.Small != nil && *params.Small
	edited := len(row.Edits) > 0
	if row.Kind != "photo" || (!small && !edited && row.UserID == user.ID) {
		serveOriginal(w, r, &row, true)
		return
	}
	source, err := s.shareSource(ctx, &row, small)
	if err != nil {
		writeError(w, http.StatusNotFound, "this photo cannot be sent yet")
		return
	}
	tmpDir := storage.TmpDir(s.LibraryPath)
	if err := os.MkdirAll(tmpDir, 0o750); err != nil {
		internalError(w, r, err)
		return
	}
	out, err := os.CreateTemp(tmpDir, "share-*.jpg")
	if err != nil {
		internalError(w, r, err)
		return
	}
	_ = out.Close()
	defer func() { _ = os.Remove(out.Name()) }()
	if err := toJPEG(ctx, source, out.Name(), small); err != nil {
		internalError(w, r, err)
		return
	}
	name := strings.TrimSuffix(row.OriginalName, filepath.Ext(row.OriginalName)) + ".jpg"
	w.Header().Set("Content-Type", "image/jpeg")
	w.Header().Set("Content-Disposition", mime.FormatMediaType("attachment", map[string]string{"filename": name}))
	w.Header().Set("X-Content-Type-Options", "nosniff")
	w.Header().Set("Cache-Control", "private, no-store")
	serveFile(w, r, out.Name())
}

// shareSource is the picture as it looks: the large preview for a small file, the full one otherwise.
// Both carry the edits.
func (s *apiServer) shareSource(ctx context.Context, row *db.Asset, small bool) (string, error) {
	if small {
		return s.queries.GetAssetFile(ctx, db.GetAssetFileParams{AssetID: row.ID, Kind: "thumb_large"})
	}
	path, err := s.queries.GetAssetFile(ctx, db.GetAssetFileParams{AssetID: row.ID, Kind: "thumb_full"})
	if db.IsNotFound(err) {
		return s.makeFullPreview(ctx, row)
	}
	return path, err
}

// toJPEG writes a JPEG with libvips, without metadata, so no location goes with it.
func toJPEG(ctx context.Context, source, dest string, small bool) error {
	ctx, cancel := context.WithTimeout(ctx, shareWait)
	defer cancel()
	if small {
		//nolint:gosec // Both paths are made here, not taken from the request.
		return exec.CommandContext(ctx, "vipsthumbnail", source, "--size", shareSmallSize, "-o", dest+"[Q=85,strip]").Run()
	}
	//nolint:gosec // As above.
	return exec.CommandContext(ctx, "vips", "copy", source, dest+"[Q=90,strip]").Run()
}
