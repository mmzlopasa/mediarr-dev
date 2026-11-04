package app

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"

	"github.com/jackc/pgx/v5/pgtype"

	"github.com/mmzlopasa/mediarr-app/server/db"
	"github.com/mmzlopasa/mediarr-app/server/internal/api"
	"github.com/mmzlopasa/mediarr-app/server/internal/jobs"
)

type fakeOllama struct {
	*httptest.Server
	mu     sync.Mutex
	pulled []string
	images int
	models []string
	answer string
}

func newFakeOllama(t *testing.T) *fakeOllama {
	t.Helper()
	f := &fakeOllama{answer: "A dog runs along a sandy beach."}
	f.Server = httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		f.mu.Lock()
		defer f.mu.Unlock()
		switch r.URL.Path {
		case "/api/tags":
			list := []map[string]string{}
			for _, name := range f.models {
				list = append(list, map[string]string{"name": name})
			}
			_ = json.NewEncoder(w).Encode(map[string]any{"models": list})
		case "/api/pull":
			var body struct {
				Name string `json:"name"`
			}
			_ = json.NewDecoder(r.Body).Decode(&body)
			f.pulled = append(f.pulled, body.Name)
			f.models = append(f.models, body.Name)
			_ = json.NewEncoder(w).Encode(map[string]string{"status": "success"})
		case "/api/generate":
			var body struct {
				Images []string `json:"images"`
				Prompt string   `json:"prompt"`
			}
			_ = json.NewDecoder(r.Body).Decode(&body)
			f.images += len(body.Images)
			_ = json.NewEncoder(w).Encode(map[string]string{"response": f.answer})
		}
	}))
	t.Cleanup(f.Close)
	return f
}

func TestDescriptionsMakePhotosFindable(t *testing.T) {
	s := newStack(t)
	s.startWorker(t)
	c := s.admin()
	other := s.user(c, "other@example.com")
	ctx := context.Background()
	ollama := newFakeOllama(t)
	id := uploadedID(t, c.upload("IMG_0001.jpg", landscapeJPEG(t), nil))
	s.settle(t)

	// Not there before.
	resp, body := c.get("/api/search?q=sandy")
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.SearchResult](t, body); len(got.Items) != 0 {
		t.Fatalf("%s", body)
	}
	resp, body = c.send(http.MethodPut, "/api/admin/ai", map[string]any{"address": "file:///etc", "visionModel": "", "textModel": ""})
	expect(t, resp, body, http.StatusBadRequest)
	resp, body = other.send(http.MethodPut, "/api/admin/ai", map[string]any{"address": ollama.URL, "visionModel": "", "textModel": ""})
	expect(t, resp, body, http.StatusForbidden)
	resp, body = c.send(http.MethodPut, "/api/admin/ai", map[string]any{"address": ollama.URL, "visionModel": "", "textModel": ""})
	expect(t, resp, body, http.StatusOK)
	settings := decode[api.AISettings](t, body)
	if !settings.Reachable || settings.ModelsReady || settings.VisionModel != jobs.DefaultVisionModel {
		t.Fatalf("%s", body)
	}

	// The models come down by themselves, and the picture is described from its preview.
	client := jobs.NewOllama(ollama.URL)
	if err := client.EnsureModels(ctx, jobs.DefaultVisionModel, jobs.DefaultTextModel); err != nil {
		t.Fatal(err)
	}
	if err := client.EnsureModels(ctx, jobs.DefaultVisionModel, jobs.DefaultTextModel); err != nil {
		t.Fatal(err)
	}
	if len(ollama.pulled) != 2 {
		t.Fatalf("pulled: %v", ollama.pulled)
	}
	var asset pgtype.UUID
	if err := asset.Scan(id); err != nil {
		t.Fatal(err)
	}
	if err := jobs.Describe(ctx, db.New(s.pool), client, jobs.DefaultVisionModel, asset); err != nil {
		t.Fatal(err)
	}
	if ollama.images != 1 {
		t.Fatalf("images: %d", ollama.images)
	}

	resp, body = c.get("/api/search?q=sandy")
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.SearchResult](t, body); len(got.Items) != 1 || got.Items[0].Id.String() != id {
		t.Fatalf("%s", body)
	}
	resp, body = c.get("/api/assets/" + id)
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.AssetDetail](t, body); got.Description == nil || !strings.Contains(*got.Description, "sandy beach") {
		t.Fatalf("%s", body)
	}
	// Someone else finds nothing through it.
	resp, body = other.get("/api/search?q=sandy")
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.SearchResult](t, body); len(got.Items) != 0 {
		t.Fatalf("%s", body)
	}
}

func TestAskingTurnsAQuestionIntoASearch(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	ollama := newFakeOllama(t)
	ollama.answer = "\"torta rođendan 2024\"\nHere are your words."
	ask := func() (*http.Response, []byte) {
		return c.post("/api/search/ask", map[string]string{"question": "fotke s rođendana 2024. gdje je torta"})
	}
	resp, body := ask()
	expect(t, resp, body, http.StatusConflict)
	resp, body = c.send(http.MethodPut, "/api/admin/features/descriptions", map[string]bool{"enabled": true})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = c.send(http.MethodPut, "/api/admin/ai", map[string]any{"address": ollama.URL, "visionModel": "", "textModel": ""})
	expect(t, resp, body, http.StatusOK)
	resp, body = ask()
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.AskAnswer](t, body); got.Query != "torta rođendan 2024" {
		t.Fatalf("%s", body)
	}
	// When the model is gone, the question itself is searched.
	ollama.Close()
	resp, body = ask()
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.AskAnswer](t, body); got.Query != "fotke s rođendana 2024. gdje je torta" {
		t.Fatalf("%s", body)
	}
	resp, body = c.post("/api/search/ask", map[string]string{"question": " "})
	expect(t, resp, body, http.StatusBadRequest)
}
