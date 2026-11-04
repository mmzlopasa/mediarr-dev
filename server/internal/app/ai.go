package app

import (
	"context"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

const (
	askTimeout     = 90 * time.Second
	aiCheckTimeout = 3 * time.Second
	maxQuestion    = 500
	maxAskWords    = 12
)

func (s *apiServer) aiToAPI(ctx context.Context) (api.AISettings, error) {
	var out api.AISettings
	address, vision, text, err := jobs.OllamaSettings(ctx, s.queries)
	if err != nil {
		return out, err
	}
	progress, err := s.queries.DescriptionProgress(ctx)
	if err != nil {
		return out, err
	}
	out = api.AISettings{Address: address, VisionModel: vision, TextModel: text, Described: progress.Described, Total: progress.Total}
	if address != "" {
		check, cancel := context.WithTimeout(ctx, aiCheckTimeout)
		defer cancel()
		models, err := jobs.NewOllama(address).Models(check)
		out.Reachable = err == nil
		out.ModelsReady = err == nil && jobs.HasModel(models, vision) && jobs.HasModel(models, text)
	}
	return out, nil
}

func (s *apiServer) GetAISettings(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	out, err := s.aiToAPI(r.Context())
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, out)
}

// SetAISettings is for administrators, since the server then sends previews to the address it is given.
func (s *apiServer) SetAISettings(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	var body api.AISettingsUpdate
	if !readJSON(w, r, &body) {
		return
	}
	address := strings.TrimRight(strings.TrimSpace(body.Address), "/")
	if address != "" {
		parsed, err := url.Parse(address)
		if err != nil || parsed.Host == "" || (parsed.Scheme != "http" && parsed.Scheme != "https") {
			writeError(w, http.StatusBadRequest, "the address must be http or https")
			return
		}
	}
	ctx := r.Context()
	for key, value := range map[string]string{
		jobs.StateOllamaURL: address, jobs.StateOllamaVisionModel: strings.TrimSpace(body.VisionModel), jobs.StateOllamaTextModel: strings.TrimSpace(body.TextModel),
	} {
		if err := s.queries.SetState(ctx, db.SetStateParams{Key: key, Value: value}); err != nil {
			internalError(w, r, err)
			return
		}
	}
	out, err := s.aiToAPI(ctx)
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, out)
}

// AskSearch turns a question into words to search for. If the model cannot answer, the question
// itself is searched, so asking never fails because of the model.
func (s *apiServer) AskSearch(w http.ResponseWriter, r *http.Request) {
	if requireUser(w, r) == nil {
		return
	}
	var body api.AskRequest
	if !readJSON(w, r, &body) {
		return
	}
	question := strings.TrimSpace(body.Question)
	if question == "" || len(question) > maxQuestion {
		writeError(w, http.StatusBadRequest, "the question must have between 1 and 500 characters")
		return
	}
	ctx := r.Context()
	on, err := s.featureOn(ctx, jobs.FeatureDescriptions)
	if err != nil {
		internalError(w, r, err)
		return
	}
	address, _, text, err := jobs.OllamaSettings(ctx, s.queries)
	if err != nil {
		internalError(w, r, err)
		return
	}
	if !on || address == "" {
		writeError(w, http.StatusConflict, "asking is not turned on")
		return
	}
	ask, cancel := context.WithTimeout(ctx, askTimeout)
	defer cancel()
	query := cleanAskAnswer(jobs.AskModel(ask, jobs.NewOllama(address), text, question))
	if query == "" {
		query = question
	}
	writeJSON(w, http.StatusOK, api.AskAnswer{Query: query})
}

// cleanAskAnswer takes the first line, without the quotes models like to add.
func cleanAskAnswer(answer string) string {
	line, _, _ := strings.Cut(strings.TrimSpace(answer), "\n")
	line = strings.Trim(strings.TrimSpace(line), "\"'`.")
	if len(line) > maxQueryLength {
		return ""
	}
	// A small model sometimes refuses or explains instead, which is no use as search words.
	if len(strings.Fields(line)) > maxAskWords {
		return ""
	}
	folded := strings.ToLower(line)
	for _, refusal := range []string{"i can't", "i cannot", "i'm sorry", "i am sorry", "as an ai"} {
		if strings.Contains(folded, refusal) {
			return ""
		}
	}
	return line
}
