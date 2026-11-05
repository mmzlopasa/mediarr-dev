package app

import (
	"net/http"

	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
)

const notificationsShown = 100

func (s *apiServer) ListNotifications(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	ctx := r.Context()
	rows, err := s.queries.ListNotifications(ctx, db.ListNotificationsParams{UserID: user.ID, Limit: notificationsShown})
	if err != nil {
		internalError(w, r, err)
		return
	}
	unread, err := s.queries.CountUnreadNotifications(ctx, user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	items := make([]api.Notification, len(rows))
	for i := range rows {
		row := &rows[i]
		items[i] = api.Notification{
			Id: openapi_types.UUID(row.ID.Bytes), Kind: api.NotificationKind(row.Kind), Subject: row.Subject,
			Ref: row.Ref, CreatedAt: row.CreatedAt.Time, Read: row.ReadAt.Valid,
		}
	}
	writeJSON(w, http.StatusOK, api.NotificationList{Items: items, Unread: unread})
}

func (s *apiServer) ReadNotifications(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	if err := s.queries.MarkNotificationsRead(r.Context(), user.ID); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) DeleteNotification(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	gone, err := s.queries.DeleteNotification(r.Context(), db.DeleteNotificationParams{ID: pgUUID(id), UserID: user.ID})
	if err != nil {
		internalError(w, r, err)
		return
	}
	if gone == 0 {
		writeError(w, http.StatusNotFound, "no such notification")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
