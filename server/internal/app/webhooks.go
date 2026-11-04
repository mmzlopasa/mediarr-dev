package app

import (
	"net/http"
	"net/url"
	"slices"
	"strings"

	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

func (s *apiServer) ListWebhooks(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	rows, err := s.queries.ListWebhooks(r.Context())
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := make([]api.Webhook, len(rows))
	for i := range rows {
		row := &rows[i]
		events := make([]api.WebhookEvents, len(row.Events))
		for j, event := range row.Events {
			events[j] = api.WebhookEvents(event)
		}
		out[i] = api.Webhook{
			Id: row.ID.Bytes, Url: row.Url, Events: events, LastStatus: int(row.LastStatus), LastError: row.LastError,
			LastAt: optional(row.LastAt.Time, row.LastAt.Valid),
		}
	}
	writeJSON(w, http.StatusOK, out)
}

func (s *apiServer) CreateWebhook(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	var body api.WebhookCreate
	if !readJSON(w, r, &body) {
		return
	}
	address := strings.TrimSpace(body.Url)
	parsed, err := url.Parse(address)
	if err != nil || parsed.Host == "" || (parsed.Scheme != "http" && parsed.Scheme != "https") {
		writeError(w, http.StatusBadRequest, "a webhook needs an http or https address")
		return
	}
	known := []string{jobs.EventAssetReady, jobs.EventPersonCreated, jobs.EventBackupFinished}
	events := []string{}
	for _, event := range body.Events {
		if !slices.Contains(known, string(event)) {
			writeError(w, http.StatusBadRequest, "unknown event: "+string(event))
			return
		}
		events = append(events, string(event))
	}
	if len(events) == 0 {
		writeError(w, http.StatusBadRequest, "choose at least one event")
		return
	}
	secret, err := randomText()
	if err != nil {
		internalError(w, r, err)
		return
	}
	id, err := s.queries.CreateWebhook(r.Context(), db.CreateWebhookParams{Url: address, Secret: secret, Events: events})
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusCreated, api.WebhookCreated{Id: id.Bytes, Secret: secret})
}

func (s *apiServer) DeleteWebhook(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	if requireAdmin(w, r) == nil {
		return
	}
	if err := s.queries.DeleteWebhook(r.Context(), pgUUID(id)); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) TestWebhook(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	if requireAdmin(w, r) == nil {
		return
	}
	ctx := r.Context()
	if _, err := s.queries.GetWebhook(ctx, pgUUID(id)); db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "no such webhook")
		return
	} else if err != nil {
		internalError(w, r, err)
		return
	}
	body, err := jobs.WebhookBody(jobs.EventTest, nil)
	if err != nil {
		internalError(w, r, err)
		return
	}
	if _, err := s.Inserter.Insert(ctx, jobs.WebhookArgs{Webhook: id, Event: jobs.EventTest, Body: body}, nil); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusAccepted)
}
