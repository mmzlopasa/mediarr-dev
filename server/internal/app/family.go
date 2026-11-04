package app

import (
	"context"
	"encoding/json"
	"net/http"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
)

const featureFamily = "family"

// inFamily answers by itself when the feature is off or the user is not in the family.
func (s *apiServer) inFamily(w http.ResponseWriter, r *http.Request, user *db.User) bool {
	ctx := r.Context()
	on, err := s.featureOn(ctx, featureFamily)
	if err != nil {
		internalError(w, r, err)
		return false
	}
	member, err := s.queries.IsFamilyMember(ctx, user.ID)
	if err != nil {
		internalError(w, r, err)
		return false
	}
	if !on || !member {
		writeError(w, http.StatusForbidden, "this account is not in the family library")
		return false
	}
	return true
}

func (s *apiServer) GetFamily(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	ctx := r.Context()
	on, err := s.featureOn(ctx, featureFamily)
	if err != nil {
		internalError(w, r, err)
		return
	}
	member, err := s.queries.IsFamilyMember(ctx, user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := api.Family{Enabled: on, Member: member, Members: []api.UserRef{}, Rules: []api.FamilyRule{}}
	if !on || !member {
		writeJSON(w, http.StatusOK, out)
		return
	}
	members, err := s.queries.ListFamilyMembers(ctx)
	if err != nil {
		internalError(w, r, err)
		return
	}
	for i := range members {
		out.Members = append(out.Members, api.UserRef{Id: members[i].ID.Bytes, Name: members[i].Name})
	}
	rules, err := s.queries.ListFamilyRules(ctx, user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	for i := range rules {
		var decoded api.AlbumRules
		if err := json.Unmarshal(rules[i].Rules, &decoded); err != nil {
			internalError(w, r, err)
			return
		}
		out.Rules = append(out.Rules, api.FamilyRule{Id: rules[i].ID.Bytes, Title: rules[i].Title, Rules: decoded})
	}
	writeJSON(w, http.StatusOK, out)
}

func (s *apiServer) CreateFamilyRule(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil || !s.inFamily(w, r, user) {
		return
	}
	var body api.FamilyRuleCreate
	if !readJSON(w, r, &body) {
		return
	}
	title := strings.TrimSpace(body.Title)
	if title == "" || len(title) > maxAlbumTitle {
		writeError(w, http.StatusBadRequest, "give this rule a name")
		return
	}
	rules, err := encodeRules(&body.Rules)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	ctx := r.Context()
	var id pgtype.UUID
	err = pgx.BeginFunc(ctx, s.Pool, func(tx pgx.Tx) error {
		q := s.queries.WithTx(tx)
		var err error
		if id, err = q.CreateFamilyAlbum(ctx, db.CreateFamilyAlbumParams{OwnerID: user.ID, Title: title, Rules: rules}); err != nil {
			return err
		}
		return q.ShareFamilyAlbum(ctx, db.ShareFamilyAlbumParams{AlbumID: id, OwnerID: user.ID})
	})
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusCreated, map[string]openapi_types.UUID{"id": id.Bytes})
}

func (s *apiServer) DeleteFamilyRule(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	changed, err := s.queries.DeleteFamilyRule(r.Context(), db.DeleteFamilyRuleParams{ID: pgUUID(id), OwnerID: user.ID})
	if err != nil {
		internalError(w, r, err)
		return
	}
	if changed == 0 {
		writeError(w, http.StatusNotFound, "no such rule")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) GetFamilyBuckets(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil || !s.inFamily(w, r, user) {
		return
	}
	rows, err := s.queries.FamilyBuckets(r.Context())
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := make([]db.TimelineBucketsRow, len(rows))
	for i := range rows {
		out[i] = db.TimelineBucketsRow(rows[i])
	}
	writeBuckets(w, out, false)
}

func (s *apiServer) GetFamilyBucket(w http.ResponseWriter, r *http.Request, month string) {
	user := requireUser(w, r)
	if user == nil || !s.inFamily(w, r, user) {
		return
	}
	from, to, ok := monthRange(w, month)
	if !ok {
		return
	}
	rows, err := s.queries.FamilyBucket(r.Context(), db.FamilyBucketParams{FromAt: from, ToAt: to})
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

func (s *apiServer) AddFamilyMember(w http.ResponseWriter, r *http.Request, userID openapi_types.UUID) {
	if requireAdmin(w, r) == nil {
		return
	}
	ctx := r.Context()
	if _, err := s.queries.GetUserByID(ctx, pgUUID(userID)); db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "no such user")
		return
	} else if err != nil {
		internalError(w, r, err)
		return
	}
	s.changeFamily(ctx, w, r, func(q *db.Queries) error {
		if err := q.AddFamilyMember(ctx, pgUUID(userID)); err != nil {
			return err
		}
		return q.JoinFamilyAlbums(ctx, pgUUID(userID))
	})
}

// RemoveFamilyMember also stops what they shared. Their photos stay in their own library.
func (s *apiServer) RemoveFamilyMember(w http.ResponseWriter, r *http.Request, userID openapi_types.UUID) {
	if requireAdmin(w, r) == nil {
		return
	}
	ctx := r.Context()
	s.changeFamily(ctx, w, r, func(q *db.Queries) error {
		if err := q.RemoveFamilyMember(ctx, pgUUID(userID)); err != nil {
			return err
		}
		if err := q.LeaveFamilyAlbums(ctx, pgUUID(userID)); err != nil {
			return err
		}
		return q.DeleteOwnFamilyAlbums(ctx, pgUUID(userID))
	})
}

func (s *apiServer) changeFamily(ctx context.Context, w http.ResponseWriter, r *http.Request, change func(*db.Queries) error) {
	err := pgx.BeginFunc(ctx, s.Pool, func(tx pgx.Tx) error { return change(s.queries.WithTx(tx)) })
	if err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) ListFamilyMembersAdmin(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	rows, err := s.queries.ListFamilyMembers(r.Context())
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := make([]api.UserRef, len(rows))
	for i := range rows {
		out[i] = api.UserRef{Id: rows[i].ID.Bytes, Name: rows[i].Name}
	}
	writeJSON(w, http.StatusOK, out)
}
