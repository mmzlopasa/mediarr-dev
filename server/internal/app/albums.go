package app

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"slices"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

const (
	roleViewer      = "viewer"
	roleContributor = "contributor"
	roleEditor      = "editor"
	roleOwner       = "owner"

	maxAlbumTitle  = 200
	maxCommentBody = 2000
)

var roleRank = map[string]int{roleViewer: 1, roleContributor: 2, roleEditor: 3, roleOwner: 4}

func roleAtLeast(role, wanted string) bool { return roleRank[role] >= roleRank[wanted] }

// album reads an album for the signed-in user. Someone without access gets the same answer as for
// an album that does not exist, so albums cannot be discovered by guessing.
func (s *apiServer) album(w http.ResponseWriter, r *http.Request, id openapi_types.UUID, wanted string) (*db.GetAlbumForUserRow, *db.User, bool) {
	user := requireUser(w, r)
	if user == nil {
		return nil, nil, false
	}
	row, err := s.queries.GetAlbumForUser(r.Context(), db.GetAlbumForUserParams{ID: pgUUID(id), UserID: user.ID})
	if db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "no such album")
		return nil, nil, false
	}
	if err != nil {
		internalError(w, r, err)
		return nil, nil, false
	}
	if !roleAtLeast(row.Role, wanted) {
		writeError(w, http.StatusForbidden, "your role in this album does not allow this")
		return nil, nil, false
	}
	return &row, user, true
}

func (s *apiServer) toAPIAlbum(ctx context.Context, row *db.GetAlbumForUserRow) (api.Album, error) {
	out := api.Album{
		Id:          row.ID.Bytes,
		Title:       row.Title,
		Description: row.Description,
		Role:        api.AlbumRole(row.Role),
		OwnerId:     row.OwnerID.Bytes,
		OwnerName:   row.OwnerName,
		AssetCount:  row.AssetCount,
		Order:       api.AlbumOrder(row.AssetOrder),
		IsSmart:     row.Rules != nil,
		CreatedAt:   row.CreatedAt.Time,
		UpdatedAt:   row.UpdatedAt.Time,
		ChildCount:  optional(row.ChildCount, row.ChildCount > 0),
	}
	if row.ParentID.Valid {
		parent := openapi_types.UUID(row.ParentID.Bytes)
		out.ParentId = &parent
	}
	if row.Rules != nil {
		var rules api.AlbumRules
		if err := json.Unmarshal(row.Rules, &rules); err != nil {
			return out, fmt.Errorf("read album rules: %w", err)
		}
		out.Rules = &rules
	}
	cover := row.NewestAssetID
	if row.CoverAssetID.Valid {
		chosen, err := s.queries.AlbumHasAsset(ctx, db.AlbumHasAssetParams{PAlbum: row.ID, PAsset: row.CoverAssetID})
		if err != nil {
			return out, err
		}
		if chosen {
			cover = row.CoverAssetID
		}
	}
	if cover.Valid {
		value := openapi_types.UUID(cover.Bytes)
		out.CoverAssetId = &value
	}
	return out, nil
}

func cleanTitle(title string) (string, error) {
	title = strings.TrimSpace(title)
	if title == "" || len([]rune(title)) > maxAlbumTitle {
		return "", fmt.Errorf("the title must have between 1 and %d characters", maxAlbumTitle)
	}
	return title, nil
}

// encodeRules checks a smart album's conditions. An album without any would match the whole library.
func encodeRules(rules *api.AlbumRules) ([]byte, error) {
	if rules.Camera != nil {
		camera := strings.TrimSpace(*rules.Camera)
		rules.Camera = optional(camera, camera != "")
	}
	if rules.Place != nil {
		place := strings.TrimSpace(*rules.Place)
		rules.Place = optional(place, place != "")
	}
	if rules.From == nil && rules.To == nil && rules.Kind == nil && rules.Camera == nil &&
		rules.Person == nil && rules.Tag == nil && rules.Place == nil {
		return nil, errors.New("a smart album needs at least one rule")
	}
	if rules.From != nil && rules.To != nil && rules.To.Before(rules.From.Time) {
		return nil, errors.New("the end date is before the start date")
	}
	if rules.Kind != nil && !rules.Kind.Valid() {
		return nil, errors.New("unknown kind")
	}
	return json.Marshal(rules)
}

func (s *apiServer) ListDirectory(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	rows, err := s.queries.ListDirectory(r.Context(), user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := make([]api.UserRef, len(rows))
	for i, row := range rows {
		out[i] = api.UserRef{Id: row.ID.Bytes, Name: row.Name}
	}
	writeJSON(w, http.StatusOK, out)
}

func (s *apiServer) ListAlbums(w http.ResponseWriter, r *http.Request, params api.ListAlbumsParams) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	ctx := r.Context()
	rows, err := s.queries.ListAlbums(ctx, user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	if params.Sort != nil {
		switch *params.Sort {
		case api.Title:
			slices.SortStableFunc(rows, func(a, b db.ListAlbumsRow) int {
				return strings.Compare(strings.ToLower(a.Title), strings.ToLower(b.Title))
			})
		case api.Date:
			slices.SortStableFunc(rows, func(a, b db.ListAlbumsRow) int {
				return b.NewestAt.Time.Compare(a.NewestAt.Time)
			})
		case api.Updated:
		}
	}
	out := make([]api.Album, len(rows))
	for i := range rows {
		row := db.GetAlbumForUserRow(rows[i])
		if out[i], err = s.toAPIAlbum(ctx, &row); err != nil {
			internalError(w, r, err)
			return
		}
	}
	writeJSON(w, http.StatusOK, out)
}

func (s *apiServer) CreateAlbum(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	var body api.AlbumCreate
	if !readJSON(w, r, &body) {
		return
	}
	title, err := cleanTitle(body.Title)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	var rules []byte
	if body.Rules != nil {
		if rules, err = encodeRules(body.Rules); err != nil {
			writeError(w, http.StatusBadRequest, err.Error())
			return
		}
	}
	description := ""
	if body.Description != nil {
		description = strings.TrimSpace(*body.Description)
	}
	ctx := r.Context()
	id, err := s.queries.CreateAlbum(ctx, db.CreateAlbumParams{OwnerID: user.ID, Title: title, Description: description, Rules: rules})
	if err != nil {
		internalError(w, r, err)
		return
	}
	prefs, err := s.preferences(ctx, user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	if err := s.queries.SetAlbumOrder(ctx, db.SetAlbumOrderParams{ID: id, AssetOrder: string(prefs.AlbumOrder)}); err != nil {
		internalError(w, r, err)
		return
	}
	if body.ParentId != nil {
		if code, message := s.checkParent(ctx, user.ID, id, *body.ParentId); code != 0 {
			// The album is made only where it was asked for.
			_ = s.queries.DeleteAlbum(ctx, id)
			writeError(w, code, message)
			return
		}
		if err := s.queries.SetAlbumParent(ctx, db.SetAlbumParentParams{ID: id, ParentID: pgUUID(*body.ParentId)}); err != nil {
			internalError(w, r, err)
			return
		}
	}
	s.writeAlbum(w, r, http.StatusCreated, id, user.ID, false)
}

// checkParent says whether an album may go inside another: both one's own, and never inside itself
// at any depth. It answers a status and a message, or 0 when it may.
func (s *apiServer) checkParent(ctx context.Context, userID, id pgtype.UUID, parentID openapi_types.UUID) (int, string) {
	parent, err := s.queries.GetAlbumForUser(ctx, db.GetAlbumForUserParams{ID: pgUUID(parentID), UserID: userID})
	if db.IsNotFound(err) {
		return http.StatusNotFound, "no such album to put it in"
	}
	if err != nil {
		return http.StatusInternalServerError, "the album to put it in could not be read"
	}
	if parent.OwnerID != userID {
		return http.StatusForbidden, "an album can only go inside one of your own"
	}
	within, err := s.queries.AlbumIsWithin(ctx, db.AlbumIsWithinParams{Album: pgUUID(parentID), Outer: id})
	if err != nil {
		return http.StatusInternalServerError, "the albums could not be read"
	}
	if within {
		return http.StatusBadRequest, "an album cannot go inside itself or one of the albums in it"
	}
	return 0, ""
}

// MoveAlbum puts an album inside another of one's own, or back at the top.
func (s *apiServer) MoveAlbum(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	row, user, ok := s.album(w, r, id, roleOwner)
	if !ok {
		return
	}
	var body api.AlbumParent
	if !readJSON(w, r, &body) {
		return
	}
	ctx := r.Context()
	parent := pgtype.UUID{}
	if body.ParentId != nil {
		if code, message := s.checkParent(ctx, user.ID, row.ID, *body.ParentId); code != 0 {
			writeError(w, code, message)
			return
		}
		parent = pgUUID(*body.ParentId)
	}
	if err := s.queries.SetAlbumParent(ctx, db.SetAlbumParentParams{ID: row.ID, ParentID: parent}); err != nil {
		internalError(w, r, err)
		return
	}
	s.writeAlbum(w, r, http.StatusOK, row.ID, user.ID, false)
}

func (s *apiServer) writeAlbum(w http.ResponseWriter, r *http.Request, code int, id, userID pgtype.UUID, members bool) {
	ctx := r.Context()
	row, err := s.queries.GetAlbumForUser(ctx, db.GetAlbumForUserParams{ID: id, UserID: userID})
	if err != nil {
		internalError(w, r, err)
		return
	}
	out, err := s.toAPIAlbum(ctx, &row)
	if err != nil {
		internalError(w, r, err)
		return
	}
	if members {
		rows, err := s.queries.ListAlbumMembers(ctx, id)
		if err != nil {
			internalError(w, r, err)
			return
		}
		list := make([]api.AlbumMember, len(rows))
		for i, member := range rows {
			list[i] = api.AlbumMember{UserId: member.UserID.Bytes, Name: member.Name, Role: api.AlbumMemberRole(member.Role)}
		}
		out.Members = &list
	}
	writeJSON(w, code, out)
}

func (s *apiServer) GetAlbum(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	album, user, ok := s.album(w, r, id, roleViewer)
	if !ok {
		return
	}
	s.writeAlbum(w, r, http.StatusOK, album.ID, user.ID, true)
}

func (s *apiServer) UpdateAlbum(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	album, user, ok := s.album(w, r, id, roleEditor)
	if !ok {
		return
	}
	var body api.AlbumUpdate
	if !readJSON(w, r, &body) {
		return
	}
	ctx := r.Context()
	params := db.UpdateAlbumParams{
		ID: album.ID, Title: album.Title, Description: album.Description,
		CoverAssetID: album.CoverAssetID, AssetOrder: album.AssetOrder, Rules: album.Rules,
	}
	var err error
	if body.Title != nil {
		if params.Title, err = cleanTitle(*body.Title); err != nil {
			writeError(w, http.StatusBadRequest, err.Error())
			return
		}
	}
	if body.Description != nil {
		params.Description = strings.TrimSpace(*body.Description)
	}
	if body.Order != nil {
		if !body.Order.Valid() {
			writeError(w, http.StatusBadRequest, "unknown order")
			return
		}
		params.AssetOrder = string(*body.Order)
	}
	if body.Rules != nil {
		// A rule can match the owner's whole library, so it is the owner's decision alone.
		if album.OwnerID != user.ID {
			writeError(w, http.StatusForbidden, "only the owner can change what a smart album shows")
			return
		}
		if album.Rules == nil {
			writeError(w, http.StatusBadRequest, "this album is not a smart album")
			return
		}
		if params.Rules, err = encodeRules(body.Rules); err != nil {
			writeError(w, http.StatusBadRequest, err.Error())
			return
		}
	}
	if body.CoverAssetId != nil {
		inAlbum, err := s.queries.AlbumHasAsset(ctx, db.AlbumHasAssetParams{PAlbum: album.ID, PAsset: pgUUID(*body.CoverAssetId)})
		if err != nil {
			internalError(w, r, err)
			return
		}
		if !inAlbum {
			writeError(w, http.StatusBadRequest, "the cover must be a photo in this album")
			return
		}
		params.CoverAssetID = pgUUID(*body.CoverAssetId)
	}
	if err := s.queries.UpdateAlbum(ctx, params); err != nil {
		internalError(w, r, err)
		return
	}
	s.writeAlbum(w, r, http.StatusOK, album.ID, user.ID, true)
}

func (s *apiServer) DeleteAlbum(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	album, _, ok := s.album(w, r, id, roleOwner)
	if !ok {
		return
	}
	links, err := s.queries.ListLinks(r.Context(), album.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	if err := s.queries.DeleteAlbum(r.Context(), album.ID); err != nil {
		internalError(w, r, err)
		return
	}
	for i := range links {
		s.removeLinkCache(links[i].ID)
	}
	w.WriteHeader(http.StatusNoContent)
}

func readAssetIDs(w http.ResponseWriter, r *http.Request) ([]pgtype.UUID, bool) {
	var body api.AssetIds
	if !readJSON(w, r, &body) {
		return nil, false
	}
	if len(body.Ids) == 0 || len(body.Ids) > maxBulkIDs {
		writeError(w, http.StatusBadRequest, fmt.Sprintf("send between 1 and %d assets", maxBulkIDs))
		return nil, false
	}
	ids := make([]pgtype.UUID, len(body.Ids))
	for i, id := range body.Ids {
		ids[i] = pgUUID(id)
	}
	return ids, true
}

func (s *apiServer) AddAlbumAssets(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	album, user, ok := s.album(w, r, id, roleContributor)
	if !ok {
		return
	}
	if album.Rules != nil {
		writeError(w, http.StatusConflict, "a smart album fills itself from its rules")
		return
	}
	ids, ok := readAssetIDs(w, r)
	if !ok {
		return
	}
	ctx := r.Context()
	// Only the user's own assets: a member cannot pass along what was merely shared with them.
	changed, err := s.queries.AddAlbumAssets(ctx, db.AddAlbumAssetsParams{AlbumID: album.ID, UserID: user.ID, Ids: ids})
	if err == nil {
		err = s.queries.TouchAlbum(ctx, album.ID)
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, api.BulkResponse{Changed: changed})
}

func (s *apiServer) RemoveAlbumAssets(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	album, user, ok := s.album(w, r, id, roleContributor)
	if !ok {
		return
	}
	if album.Rules != nil {
		writeError(w, http.StatusConflict, "a smart album fills itself from its rules")
		return
	}
	ids, ok := readAssetIDs(w, r)
	if !ok {
		return
	}
	ctx := r.Context()
	var changed int64
	var err error
	if roleAtLeast(album.Role, roleEditor) {
		changed, err = s.queries.RemoveAlbumAssets(ctx, db.RemoveAlbumAssetsParams{AlbumID: album.ID, Column2: ids})
	} else {
		changed, err = s.queries.RemoveOwnAlbumAssets(ctx, db.RemoveOwnAlbumAssetsParams{AlbumID: album.ID, Column2: ids, AddedBy: user.ID})
	}
	if err == nil {
		err = s.queries.TouchAlbum(ctx, album.ID)
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, api.BulkResponse{Changed: changed})
}

func (s *apiServer) writeAlbumBuckets(w http.ResponseWriter, r *http.Request, albumID pgtype.UUID, order string) {
	rows, err := s.queries.AlbumBuckets(r.Context(), albumID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := make([]db.TimelineBucketsRow, len(rows))
	for i, row := range rows {
		out[i] = db.TimelineBucketsRow(row)
	}
	writeBuckets(w, out, order == string(api.AlbumOrderOldest))
}

func (s *apiServer) writeAlbumBucket(w http.ResponseWriter, r *http.Request, albumID pgtype.UUID, order, month string, viewer pgtype.UUID) {
	from, to, ok := monthRange(w, month)
	if !ok {
		return
	}
	rows, err := s.queries.AlbumBucket(r.Context(), db.AlbumBucketParams{AlbumID: albumID, FromAt: from, ToAt: to})
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := make([]db.TimelineBucketRow, len(rows))
	for i := range rows {
		out[i] = db.TimelineBucketRow(rows[i])
	}
	writeBucket(w, month, out, viewer, order == string(api.AlbumOrderOldest))
}

func (s *apiServer) GetAlbumBuckets(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	album, _, ok := s.album(w, r, id, roleViewer)
	if !ok {
		return
	}
	s.writeAlbumBuckets(w, r, album.ID, album.AssetOrder)
}

func (s *apiServer) GetAlbumBucket(w http.ResponseWriter, r *http.Request, id openapi_types.UUID, month string) {
	album, user, ok := s.album(w, r, id, roleViewer)
	if !ok {
		return
	}
	s.writeAlbumBucket(w, r, album.ID, album.AssetOrder, month, user.ID)
}

func (s *apiServer) SetAlbumMember(w http.ResponseWriter, r *http.Request, id, userID openapi_types.UUID) {
	album, _, ok := s.album(w, r, id, roleOwner)
	if !ok {
		return
	}
	var body api.MemberRole
	if !readJSON(w, r, &body) {
		return
	}
	if !body.Role.Valid() {
		writeError(w, http.StatusBadRequest, "unknown role")
		return
	}
	if pgUUID(userID) == album.OwnerID {
		writeError(w, http.StatusBadRequest, "the owner already has full access")
		return
	}
	ctx := r.Context()
	exists, err := s.queries.UserExists(ctx, pgUUID(userID))
	if err != nil {
		internalError(w, r, err)
		return
	}
	if !exists {
		writeError(w, http.StatusNotFound, "no such user")
		return
	}
	members, err := s.queries.ListAlbumMembers(ctx, album.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	isNew := true
	for i := range members {
		if members[i].UserID == pgUUID(userID) {
			isNew = false
		}
	}
	err = s.queries.SetAlbumMember(ctx, db.SetAlbumMemberParams{AlbumID: album.ID, UserID: pgUUID(userID), Role: string(body.Role)})
	if err == nil {
		err = s.queries.TouchAlbum(ctx, album.ID)
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	if isNew {
		if err := s.queries.CreateNotification(ctx, db.CreateNotificationParams{
			UserID: pgUUID(userID), Kind: jobs.NotifyAlbumShared, Subject: album.Title, Ref: uuid.UUID(album.ID.Bytes).String(),
		}); err != nil {
			slog.Warn("a notification was not saved", "error", err)
		}
		if person, err := s.queries.GetUserByID(ctx, pgUUID(userID)); err == nil {
			s.sendLater(person.Email, "An album was shared with you: "+album.Title,
				currentUser(r).Name+" shared the album \""+album.Title+"\" with you on Mediarr.")
		}
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) RemoveAlbumMember(w http.ResponseWriter, r *http.Request, id, userID openapi_types.UUID) {
	album, user, ok := s.album(w, r, id, roleViewer)
	if !ok {
		return
	}
	if album.Role != roleOwner && pgUUID(userID) != user.ID {
		writeError(w, http.StatusForbidden, "only the owner can remove other people")
		return
	}
	ctx := r.Context()
	removed, err := s.queries.RemoveAlbumMember(ctx, db.RemoveAlbumMemberParams{AlbumID: album.ID, UserID: pgUUID(userID)})
	if err != nil {
		internalError(w, r, err)
		return
	}
	if removed == 0 {
		writeError(w, http.StatusNotFound, "this user is not a member")
		return
	}
	if err := s.queries.TouchAlbum(ctx, album.ID); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) ListCameras(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	rows, err := s.queries.ListCameras(r.Context(), user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	if rows == nil {
		rows = []string{}
	}
	writeJSON(w, http.StatusOK, rows)
}

// assetInAlbum answers 404 for a photo the album does not show.
func (s *apiServer) assetInAlbum(w http.ResponseWriter, r *http.Request, album, asset pgtype.UUID) bool {
	inAlbum, err := s.queries.AlbumHasAsset(r.Context(), db.AlbumHasAssetParams{PAlbum: album, PAsset: asset})
	if err != nil {
		internalError(w, r, err)
		return false
	}
	if !inAlbum {
		writeError(w, http.StatusNotFound, "this photo is not in the album")
	}
	return inAlbum
}

func (s *apiServer) ListAlbumComments(w http.ResponseWriter, r *http.Request, id openapi_types.UUID, params api.ListAlbumCommentsParams) {
	album, user, ok := s.album(w, r, id, roleViewer)
	if !ok {
		return
	}
	ctx := r.Context()
	asset := pgtype.UUID{}
	out := api.Activity{Comments: []api.Comment{}}
	if params.AssetId != nil {
		asset = pgUUID(*params.AssetId)
		if !s.assetInAlbum(w, r, album.ID, asset) {
			return
		}
		hearts, err := s.queries.CountHearts(ctx, db.CountHeartsParams{UserID: user.ID, AlbumID: album.ID, AssetID: asset})
		if err != nil {
			internalError(w, r, err)
			return
		}
		out.Hearts = hearts.Total
		out.Hearted = hearts.Mine > 0
	}
	rows, err := s.queries.ListComments(ctx, db.ListCommentsParams{AlbumID: album.ID, AssetID: asset})
	if err != nil {
		internalError(w, r, err)
		return
	}
	moderator := roleAtLeast(album.Role, roleEditor)
	for i := range rows {
		row := &rows[i]
		out.Comments = append(out.Comments, api.Comment{
			Id: row.ID.Bytes, UserId: row.UserID.Bytes, UserName: row.Name, Body: row.Body,
			CreatedAt: row.CreatedAt.Time, CanDelete: moderator || row.UserID == user.ID,
		})
	}
	writeJSON(w, http.StatusOK, out)
}

func (s *apiServer) CreateAlbumComment(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	album, user, ok := s.album(w, r, id, roleViewer)
	if !ok {
		return
	}
	var body api.CommentCreate
	if !readJSON(w, r, &body) {
		return
	}
	text := strings.TrimSpace(body.Body)
	if text == "" || len([]rune(text)) > maxCommentBody {
		writeError(w, http.StatusBadRequest, fmt.Sprintf("a comment must have between 1 and %d characters", maxCommentBody))
		return
	}
	asset := pgtype.UUID{}
	if body.AssetId != nil {
		asset = pgUUID(*body.AssetId)
		if !s.assetInAlbum(w, r, album.ID, asset) {
			return
		}
	}
	ctx := r.Context()
	_, err := s.queries.CreateComment(ctx, db.CreateCommentParams{AlbumID: album.ID, AssetID: asset, UserID: user.ID, Body: text})
	if err == nil {
		err = s.queries.TouchAlbum(ctx, album.ID)
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) DeleteAlbumComment(w http.ResponseWriter, r *http.Request, id, commentID openapi_types.UUID) {
	album, user, ok := s.album(w, r, id, roleViewer)
	if !ok {
		return
	}
	ctx := r.Context()
	author, err := s.queries.GetComment(ctx, db.GetCommentParams{ID: pgUUID(commentID), AlbumID: album.ID})
	if db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "no such comment")
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	if author != user.ID && !roleAtLeast(album.Role, roleEditor) {
		writeError(w, http.StatusForbidden, "you can delete only your own comments")
		return
	}
	err = s.queries.DeleteComment(ctx, pgUUID(commentID))
	if err == nil {
		err = s.queries.TouchAlbum(ctx, album.ID)
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) SetAlbumHeart(w http.ResponseWriter, r *http.Request, id, assetID openapi_types.UUID) {
	album, user, ok := s.album(w, r, id, roleViewer)
	if !ok || !s.assetInAlbum(w, r, album.ID, pgUUID(assetID)) {
		return
	}
	if err := s.queries.SetHeart(r.Context(), db.SetHeartParams{AlbumID: album.ID, AssetID: pgUUID(assetID), UserID: user.ID}); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) RemoveAlbumHeart(w http.ResponseWriter, r *http.Request, id, assetID openapi_types.UUID) {
	album, user, ok := s.album(w, r, id, roleViewer)
	if !ok {
		return
	}
	if err := s.queries.RemoveHeart(r.Context(), db.RemoveHeartParams{AlbumID: album.ID, AssetID: pgUUID(assetID), UserID: user.ID}); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) canUploadToAlbum(ctx context.Context, album uuid.UUID, user pgtype.UUID) bool {
	row, err := s.queries.GetAlbumForUser(ctx, db.GetAlbumForUserParams{ID: pgtype.UUID{Bytes: album, Valid: true}, UserID: user})
	return err == nil && row.Rules == nil && roleAtLeast(row.Role, roleContributor)
}

// addUploadToAlbum runs when a file has arrived. The right to add is checked again, because a
// resumable upload can take long enough for access to end in the meantime.
func (s *apiServer) addUploadToAlbum(ctx context.Context, album string, guest bool, owner, asset pgtype.UUID) error {
	if album == "" {
		return nil
	}
	id, err := uuid.Parse(album)
	if err != nil {
		return fmt.Errorf("upload has a bad album: %w", err)
	}
	if !guest && !s.canUploadToAlbum(ctx, id, owner) {
		return nil
	}
	albumID := pgtype.UUID{Bytes: id, Valid: true}
	if _, err := s.queries.AddAlbumAssets(ctx, db.AddAlbumAssetsParams{AlbumID: albumID, UserID: owner, Ids: []pgtype.UUID{asset}}); err != nil {
		return fmt.Errorf("add upload to album: %w", err)
	}
	return s.queries.TouchAlbum(ctx, albumID)
}

// Partners.

func parseSince(since *openapi_types.Date) pgtype.Timestamp {
	if since == nil {
		return pgtype.Timestamp{}
	}
	return pgtype.Timestamp{Time: time.Date(since.Year(), since.Month(), since.Day(), 0, 0, 0, 0, time.UTC), Valid: true}
}

func toPartnerEntry(id pgtype.UUID, name string, since pgtype.Timestamp, inTimeline bool) api.PartnerEntry {
	entry := api.PartnerEntry{UserId: id.Bytes, Name: name, InTimeline: inTimeline}
	if since.Valid {
		entry.Since = &openapi_types.Date{Time: since.Time}
	}
	return entry
}

func (s *apiServer) ListPartners(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	ctx := r.Context()
	given, err := s.queries.ListPartnersGiven(ctx, user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	received, err := s.queries.ListPartnersReceived(ctx, user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := api.Partners{Given: make([]api.PartnerEntry, len(given)), Received: make([]api.PartnerEntry, len(received))}
	for i := range given {
		out.Given[i] = toPartnerEntry(given[i].UserID, given[i].Name, given[i].SinceAt, given[i].InTimeline)
	}
	for i := range received {
		out.Received[i] = toPartnerEntry(received[i].UserID, received[i].Name, received[i].SinceAt, received[i].InTimeline)
	}
	writeJSON(w, http.StatusOK, out)
}

func (s *apiServer) SetPartner(w http.ResponseWriter, r *http.Request, userID openapi_types.UUID) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	var body api.PartnerShare
	if !readJSON(w, r, &body) {
		return
	}
	if pgUUID(userID) == user.ID {
		writeError(w, http.StatusBadRequest, "you already see your own library")
		return
	}
	ctx := r.Context()
	exists, err := s.queries.UserExists(ctx, pgUUID(userID))
	if err != nil {
		internalError(w, r, err)
		return
	}
	if !exists {
		writeError(w, http.StatusNotFound, "no such user")
		return
	}
	if err := s.queries.SetPartner(ctx, db.SetPartnerParams{OwnerID: user.ID, PartnerID: pgUUID(userID), SinceAt: parseSince(body.Since)}); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) RemovePartner(w http.ResponseWriter, r *http.Request, userID openapi_types.UUID) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	removed, err := s.queries.RemovePartner(r.Context(), db.RemovePartnerParams{OwnerID: user.ID, PartnerID: pgUUID(userID)})
	if err != nil {
		internalError(w, r, err)
		return
	}
	if removed == 0 {
		writeError(w, http.StatusNotFound, "you do not share with this user")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) SetPartnerTimeline(w http.ResponseWriter, r *http.Request, userID openapi_types.UUID) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	var body api.PartnerTimeline
	if !readJSON(w, r, &body) {
		return
	}
	changed, err := s.queries.SetPartnerTimeline(r.Context(), db.SetPartnerTimelineParams{OwnerID: pgUUID(userID), PartnerID: user.ID, InTimeline: body.Show})
	if err != nil {
		internalError(w, r, err)
		return
	}
	if changed == 0 {
		writeError(w, http.StatusNotFound, "this user does not share with you")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) partnerSince(w http.ResponseWriter, r *http.Request, owner openapi_types.UUID) (pgtype.Timestamp, *db.User, bool) {
	user := requireUser(w, r)
	if user == nil {
		return pgtype.Timestamp{}, nil, false
	}
	since, err := s.queries.GetPartnerShare(r.Context(), db.GetPartnerShareParams{OwnerID: pgUUID(owner), PartnerID: user.ID})
	if db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "this user does not share with you")
		return since, nil, false
	}
	if err != nil {
		internalError(w, r, err)
		return since, nil, false
	}
	return since, user, true
}

func (s *apiServer) GetPartnerBuckets(w http.ResponseWriter, r *http.Request, userID openapi_types.UUID) {
	since, _, ok := s.partnerSince(w, r, userID)
	if !ok {
		return
	}
	rows, err := s.queries.PartnerBuckets(r.Context(), db.PartnerBucketsParams{OwnerID: pgUUID(userID), SinceAt: since})
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

func (s *apiServer) GetPartnerBucket(w http.ResponseWriter, r *http.Request, userID openapi_types.UUID, month string) {
	since, user, ok := s.partnerSince(w, r, userID)
	if !ok {
		return
	}
	from, to, ok := monthRange(w, month)
	if !ok {
		return
	}
	rows, err := s.queries.PartnerBucket(r.Context(), db.PartnerBucketParams{OwnerID: pgUUID(userID), SinceAt: since, FromAt: from, ToAt: to})
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
