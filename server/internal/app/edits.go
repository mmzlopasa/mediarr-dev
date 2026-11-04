package app

import (
	"encoding/json"
	"errors"
	"net/http"
	"os"
	"path/filepath"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/mmzlopasa/mediarr-app/server/db"
	"github.com/mmzlopasa/mediarr-app/server/internal/api"
	"github.com/mmzlopasa/mediarr-app/server/internal/jobs"
)

func editsFromAPI(body *api.AssetEdits) *jobs.Edits {
	out := &jobs.Edits{}
	if body.Rotate != nil {
		out.Rotate = *body.Rotate
	}
	if body.Brightness != nil {
		out.Brightness = *body.Brightness
	}
	if body.Contrast != nil {
		out.Contrast = *body.Contrast
	}
	if body.Saturation != nil {
		out.Saturation = *body.Saturation
	}
	if crop := body.Crop; crop != nil {
		out.Crop = &jobs.CropBox{X: crop.X, Y: crop.Y, Width: crop.Width, Height: crop.Height}
	}
	return out
}

func editsToAPI(edits *jobs.Edits) *api.AssetEdits {
	if edits == nil {
		return nil
	}
	out := &api.AssetEdits{
		Rotate:     optional(edits.Rotate, edits.Rotate != 0),
		Brightness: optional(edits.Brightness, edits.Brightness != 0),
		Contrast:   optional(edits.Contrast, edits.Contrast != 0),
		Saturation: optional(edits.Saturation, edits.Saturation != 0),
	}
	if crop := edits.Crop; crop != nil {
		out.Crop = &api.CropBox{X: crop.X, Y: crop.Y, Width: crop.Width, Height: crop.Height}
	}
	return out
}

// storeEdits saves the list and queues new previews, whose absence never hides the photo: the old
// ones are served until the new ones are ready.
func (s *apiServer) storeEdits(w http.ResponseWriter, r *http.Request, id openapi_types.UUID, edits *jobs.Edits) {
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
	if row.Kind != "photo" || row.Status != "ready" || row.LivePhotoOf.Valid {
		writeError(w, http.StatusConflict, "only a finished photo can be edited")
		return
	}
	var raw []byte
	if !edits.IsEmpty() {
		if raw, err = json.Marshal(edits); err != nil {
			internalError(w, r, err)
			return
		}
	}
	err = pgx.BeginFunc(ctx, s.Pool, func(tx pgx.Tx) error {
		q := s.queries.WithTx(tx)
		if err := q.SetAssetEdits(ctx, db.SetAssetEditsParams{ID: row.ID, Edits: raw}); err != nil {
			return err
		}
		if err := q.DeleteAssetFile(ctx, db.DeleteAssetFileParams{AssetID: row.ID, Kind: "thumb_full"}); err != nil {
			return err
		}
		_, err := s.Inserter.InsertTx(ctx, tx, jobs.ThumbnailArgs{AssetID: row.ID.Bytes}, nil)
		return err
	})
	if err != nil {
		internalError(w, r, err)
		return
	}
	// Links keep marked previews of their own, which would still show the picture as it was.
	if stale, err := filepath.Glob(filepath.Join(s.CachePath, "links", "*", uuid.UUID(row.ID.Bytes).String()+"-*")); err == nil {
		for _, path := range stale {
			_ = os.Remove(path)
		}
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) SetAssetEdits(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	var body api.AssetEdits
	if !readJSON(w, r, &body) {
		return
	}
	edits := editsFromAPI(&body)
	if err := edits.Validate(); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	s.storeEdits(w, r, id, edits)
}

func (s *apiServer) ClearAssetEdits(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	s.storeEdits(w, r, id, nil)
}

// serveSourcePreview shows the unedited picture, which is what the editor works on. Only the owner
// gets it: what was cropped out is not for those the photo is shared with.
func (s *apiServer) serveSourcePreview(w http.ResponseWriter, r *http.Request, id openapi_types.UUID, user pgtype.UUID) {
	ctx := r.Context()
	row, err := s.queries.GetOwnedAsset(ctx, db.GetOwnedAssetParams{ID: pgUUID(id), UserID: user})
	if db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "no such asset")
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	path, err := s.queries.GetAssetFile(ctx, db.GetAssetFileParams{AssetID: row.ID, Kind: "thumb_source"})
	if db.IsNotFound(err) {
		path, err = s.makeSourcePreview(ctx, &row)
	}
	if err != nil {
		var unreadable interface{ Unreadable() bool }
		if errors.As(err, &unreadable) && unreadable.Unreadable() {
			writeError(w, http.StatusNotFound, "this file cannot be shown")
			return
		}
		internalError(w, r, err)
		return
	}
	w.Header().Set("Content-Type", "image/webp")
	w.Header().Set("Cache-Control", "private, no-cache")
	w.Header().Set("X-Content-Type-Options", "nosniff")
	serveFile(w, r, path)
}
