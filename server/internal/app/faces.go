package app

import (
	"context"
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

func birthDate(date pgtype.Date) *string {
	if !date.Valid {
		return nil
	}
	text := date.Time.Format(time.DateOnly)
	return &text
}

// parseBirthDate takes a past date. Nothing at all removes the date.
func parseBirthDate(text string, now time.Time) (pgtype.Date, bool) {
	if text == "" {
		return pgtype.Date{}, true
	}
	date, err := time.Parse(time.DateOnly, text)
	if err != nil || date.After(now) {
		return pgtype.Date{}, false
	}
	return pgtype.Date{Time: date, Valid: true}, true
}

func (s *apiServer) previewSize(ctx context.Context, asset pgtype.UUID) (width, height float32, err error) {
	path, err := s.queries.GetAssetFile(ctx, db.GetAssetFileParams{AssetID: asset, Kind: "thumb_large"})
	if err != nil {
		return 0, 0, err
	}
	return jobs.PreviewSize(path)
}

func (s *apiServer) ListAssetFaces(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	ctx := r.Context()
	asset, err := s.queries.GetAsset(ctx, pgUUID(id))
	if db.IsNotFound(err) || (err == nil && asset.UserID != user.ID) {
		writeError(w, http.StatusNotFound, "no such asset")
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	rows, err := s.queries.ListAssetFaces(ctx, db.ListAssetFacesParams{AssetID: asset.ID, UserID: user.ID})
	if err != nil {
		internalError(w, r, err)
		return
	}
	faces := make([]api.AssetFace, len(rows))
	if len(rows) > 0 {
		width, height, err := s.previewSize(ctx, asset.ID)
		if err != nil {
			internalError(w, r, err)
			return
		}
		for i := range rows {
			row := &rows[i]
			box := jobs.RelativeBox(row.X1, row.Y1, row.X2, row.Y2, width, height)
			faces[i] = api.AssetFace{Id: openapi_types.UUID(row.ID.Bytes), X1: box[0], Y1: box[1], X2: box[2], Y2: box[3]}
			if row.PersonID.Valid {
				faces[i].Person = &api.PersonRef{Id: row.PersonID.Bytes, Name: row.PersonName.String}
			}
		}
	}
	writeJSON(w, http.StatusOK, api.AssetFaces{Faces: faces})
}

// face reads a face of the signed-in user, with its box in parts of the picture.
func (s *apiServer) face(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) (*db.GetFaceRow, [4]float32, *db.User, bool) {
	var box [4]float32
	user := requireUser(w, r)
	if user == nil {
		return nil, box, nil, false
	}
	row, err := s.queries.GetFace(r.Context(), db.GetFaceParams{ID: pgUUID(id), UserID: user.ID})
	if db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "no such face")
		return nil, box, nil, false
	}
	if err != nil {
		internalError(w, r, err)
		return nil, box, nil, false
	}
	width, height, err := s.previewSize(r.Context(), row.AssetID)
	if err != nil {
		internalError(w, r, err)
		return nil, box, nil, false
	}
	return &row, jobs.RelativeBox(row.X1, row.Y1, row.X2, row.Y2, width, height), user, true
}

// forgetHints removes what was said about this box before, so that only the newest answer stands.
func forgetHints(ctx context.Context, q *db.Queries, asset pgtype.UUID, box [4]float32) error {
	hints, err := q.ListFaceHints(ctx, asset)
	if err != nil {
		return err
	}
	for i := range hints {
		hint := &hints[i]
		if !jobs.BoxesMatch(box, [4]float32{hint.X1, hint.Y1, hint.X2, hint.Y2}) {
			continue
		}
		if err := q.DeleteFaceHint(ctx, db.DeleteFaceHintParams{AssetID: asset, PersonID: hint.PersonID, X1: hint.X1, Y1: hint.Y1}); err != nil {
			return err
		}
	}
	return nil
}

func (s *apiServer) AssignFace(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	face, box, user, ok := s.face(w, r, id)
	if !ok {
		return
	}
	var body api.FaceAssign
	if !readJSON(w, r, &body) {
		return
	}
	ctx := r.Context()
	name := ""
	if body.Name != nil {
		name = strings.TrimSpace(*body.Name)
	}
	var known pgtype.UUID
	switch {
	case body.PersonId != nil:
		person, err := s.queries.GetPerson(ctx, db.GetPersonParams{ID: pgUUID(*body.PersonId), UserID: user.ID})
		if db.IsNotFound(err) {
			writeError(w, http.StatusNotFound, "no such person")
			return
		}
		if err != nil {
			internalError(w, r, err)
			return
		}
		known = person.ID
	case name == "" || len([]rune(name)) > maxPersonName:
		writeError(w, http.StatusBadRequest, "say who this is: a known person or a name")
		return
	}
	err := pgx.BeginFunc(ctx, s.Pool, func(tx pgx.Tx) error {
		qtx := s.queries.WithTx(tx)
		person := known
		if !person.Valid {
			created, err := qtx.CreatePerson(ctx, user.ID)
			if err != nil {
				return err
			}
			if err := qtx.UpdatePerson(ctx, db.UpdatePersonParams{ID: created, Name: name}); err != nil {
				return err
			}
			person = created
		}
		if err := qtx.SetFacePerson(ctx, db.SetFacePersonParams{ID: face.ID, PersonID: person}); err != nil {
			return err
		}
		if err := forgetHints(ctx, qtx, face.AssetID, box); err != nil {
			return err
		}
		return qtx.AddFaceHint(ctx, db.AddFaceHintParams{
			AssetID: face.AssetID, PersonID: person, X1: box[0], Y1: box[1], X2: box[2], Y2: box[3],
		})
	})
	if err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) RemoveFace(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	face, box, _, ok := s.face(w, r, id)
	if !ok {
		return
	}
	ctx := r.Context()
	err := pgx.BeginFunc(ctx, s.Pool, func(tx pgx.Tx) error {
		qtx := s.queries.WithTx(tx)
		if err := qtx.DeleteFace(ctx, face.ID); err != nil {
			return err
		}
		if err := forgetHints(ctx, qtx, face.AssetID, box); err != nil {
			return err
		}
		return qtx.AddFaceIgnored(ctx, db.AddFaceIgnoredParams{
			AssetID: face.AssetID, X1: box[0], Y1: box[1], X2: box[2], Y2: box[3],
		})
	})
	if err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
