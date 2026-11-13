package jobs

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net"
	"net/http"
	"slices"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/riverqueue/river"
	"github.com/riverqueue/river/rivertype"

	"github.com/mediarr-app/mediarr/server/db"
)

// The names of the settings and the switch for descriptions, and the models used by default.
const (
	StateOllamaURL         = "ollama_url"
	StateOllamaVisionModel = "ollama_vision_model"
	StateOllamaTextModel   = "ollama_text_model"
	FeatureDescriptions    = "descriptions"
	DefaultVisionModel     = "moondream"
	DefaultTextModel       = "llama3.2:1b"
)

const (
	describeQueue         = "describe"
	describeBackfillEvery = 5 * time.Minute
	describeBatch         = 50
	describeTimeout       = 20 * time.Minute
	ollamaPullTimeout     = 2 * time.Hour
	maxDescription        = 2000
	describePrompt        = "Describe this image."
	askPrompt             = "Turn this question about a photo library into a few search words. Keep names, places and dates. Answer with the words only, in the language of the question.\n\nQuestion: "
	maxOllamaAnswerBytes  = 1 << 20
)

// Ollama talks to a local Ollama server, which the administrator names.
type Ollama struct {
	Address string
	client  *http.Client
}

// ollamaHTTP gives up quickly on a server that is not there. Each call's context sets how long an
// answer may take, as a picture takes minutes on a machine with no graphics card; the overall limit
// is only a backstop, as long as the longest call (a first model download).
var ollamaHTTP = &http.Client{
	Timeout: ollamaPullTimeout,
	Transport: &http.Transport{
		Proxy:               http.ProxyFromEnvironment,
		DialContext:         (&net.Dialer{Timeout: 10 * time.Second, KeepAlive: 30 * time.Second}).DialContext,
		TLSHandshakeTimeout: 10 * time.Second,
		IdleConnTimeout:     90 * time.Second,
	},
}

// NewOllama talks to the Ollama server at address.
func NewOllama(address string) *Ollama {
	return &Ollama{Address: strings.TrimRight(address, "/"), client: ollamaHTTP}
}

func (o *Ollama) post(ctx context.Context, path string, body, out any) error {
	encoded, err := json.Marshal(body)
	if err != nil {
		return err
	}
	request, err := http.NewRequestWithContext(ctx, http.MethodPost, o.Address+path, bytes.NewReader(encoded))
	if err != nil {
		return err
	}
	request.Header.Set("Content-Type", "application/json")
	response, err := o.client.Do(request)
	if err != nil {
		return err
	}
	defer func() { _ = response.Body.Close() }()
	raw, err := io.ReadAll(io.LimitReader(response.Body, maxOllamaAnswerBytes))
	if err != nil {
		return err
	}
	if response.StatusCode != http.StatusOK {
		return fmt.Errorf("ollama answered %d: %s", response.StatusCode, truncate(string(raw), maxToolError))
	}
	if out == nil {
		return nil
	}
	return json.Unmarshal(raw, out)
}

// Generate asks a model, with a picture if one is given.
func (o *Ollama) Generate(ctx context.Context, model, prompt string, picture []byte) (string, error) {
	body := map[string]any{"model": model, "prompt": prompt, "stream": false}
	if picture != nil {
		body["images"] = []string{base64.StdEncoding.EncodeToString(picture)}
	}
	var answer struct {
		Response string `json:"response"`
	}
	if err := o.post(ctx, "/api/generate", body, &answer); err != nil {
		return "", err
	}
	return strings.TrimSpace(answer.Response), nil
}

// Models lists what the server has downloaded.
func (o *Ollama) Models(ctx context.Context) ([]string, error) {
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, o.Address+"/api/tags", http.NoBody)
	if err != nil {
		return nil, err
	}
	response, err := o.client.Do(request)
	if err != nil {
		return nil, err
	}
	defer func() { _ = response.Body.Close() }()
	if response.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("ollama answered %d", response.StatusCode)
	}
	var answer struct {
		Models []struct {
			Name string `json:"name"`
		} `json:"models"`
	}
	if err := json.NewDecoder(io.LimitReader(response.Body, maxOllamaAnswerBytes)).Decode(&answer); err != nil {
		return nil, err
	}
	out := make([]string, len(answer.Models))
	for i := range answer.Models {
		out[i] = answer.Models[i].Name
	}
	return out, nil
}

// HasModel accepts a name with or without its ":latest".
func HasModel(models []string, name string) bool {
	return slices.Contains(models, name) || slices.Contains(models, name+":latest")
}

// EnsureModels downloads what is missing, which only the first time takes long.
func (o *Ollama) EnsureModels(ctx context.Context, names ...string) error {
	models, err := o.Models(ctx)
	if err != nil {
		return err
	}
	for _, name := range names {
		if HasModel(models, name) {
			continue
		}
		pull, cancel := context.WithTimeout(ctx, ollamaPullTimeout)
		err := o.post(pull, "/api/pull", map[string]any{"name": name, "stream": false}, nil)
		cancel()
		if err != nil {
			return fmt.Errorf("download %s: %w", name, err)
		}
	}
	return nil
}

// OllamaSettings reads them, with the default models where none were chosen.
func OllamaSettings(ctx context.Context, q *db.Queries) (address, vision, text string, err error) {
	for key, target := range map[string]*string{
		StateOllamaURL: &address, StateOllamaVisionModel: &vision, StateOllamaTextModel: &text,
	} {
		value, getErr := q.GetState(ctx, key)
		if getErr != nil && !db.IsNotFound(getErr) {
			return "", "", "", getErr
		}
		*target = value
	}
	if vision == "" {
		vision = DefaultVisionModel
	}
	if text == "" {
		text = DefaultTextModel
	}
	return address, vision, text, nil
}

func descriptionsOn(ctx context.Context, q *db.Queries) (bool, error) {
	value, err := q.GetState(ctx, StateFeaturePrefix+FeatureDescriptions)
	if db.IsNotFound(err) {
		return false, nil
	}
	return value == "1", err
}

// jpegForModel: the previews are WebP, which not every model's loader reads.
func jpegForModel(ctx context.Context, path string) ([]byte, error) {
	return runTool(ctx, "ffmpeg", "-nostdin", "-v", "error", "-i", path, "-frames:v", "1", "-f", "image2pipe", "-c:v", "mjpeg", "-q:v", "4", "-")
}

// Describe writes a description of one photo, from its preview. The original stays out of it.
func Describe(ctx context.Context, q *db.Queries, client *Ollama, vision string, id pgtype.UUID) error {
	path, err := q.GetAssetFile(ctx, db.GetAssetFileParams{AssetID: id, Kind: "thumb_large"})
	if db.IsNotFound(err) {
		return nil
	}
	if err != nil {
		return err
	}
	picture, err := jpegForModel(ctx, path)
	if err != nil {
		var bad *badFileError
		if errors.As(err, &bad) {
			// Something unreadable gets an empty description, so that it is not tried forever.
			return q.UpsertDescription(ctx, db.UpsertDescriptionParams{AssetID: id, Description: "", Model: vision})
		}
		return err
	}
	text, err := client.Generate(ctx, vision, describePrompt, picture)
	if err != nil {
		return err
	}
	return q.UpsertDescription(ctx, db.UpsertDescriptionParams{AssetID: id, Description: truncate(text, maxDescription), Model: vision})
}

// DescribeArgs describes one photo.
type DescribeArgs struct {
	AssetID uuid.UUID `json:"asset_id"`
}

// Kind identifies the job in the queue.
func (DescribeArgs) Kind() string { return "describe" }

// InsertOpts gives it a queue of its own, one at a time, and one job per photo.
func (DescribeArgs) InsertOpts() river.InsertOpts {
	return river.InsertOpts{Queue: describeQueue, UniqueOpts: river.UniqueOpts{ByArgs: true, ByState: []rivertype.JobState{
		rivertype.JobStateAvailable, rivertype.JobStatePending, rivertype.JobStateRetryable,
		rivertype.JobStateRunning, rivertype.JobStateScheduled,
	}}}
}

type describeWorker struct {
	river.WorkerDefaults[DescribeArgs]
	*deps
}

func (w *describeWorker) Timeout(*river.Job[DescribeArgs]) time.Duration { return describeTimeout }

func (w *describeWorker) Work(ctx context.Context, job *river.Job[DescribeArgs]) error {
	on, err := descriptionsOn(ctx, w.queries)
	if err != nil {
		return err
	}
	address, vision, _, err := OllamaSettings(ctx, w.queries)
	if err != nil {
		return err
	}
	if !on || address == "" {
		return nil
	}
	return Describe(ctx, w.queries, NewOllama(address), vision, toPG(job.Args.AssetID))
}

// DescribeBackfillArgs queues photos that have no description yet.
type DescribeBackfillArgs struct{}

// Kind identifies the job in the queue.
func (DescribeBackfillArgs) Kind() string { return "describe_backfill" }

// InsertOpts keeps one at a time, on the same queue, because downloading a model takes long.
func (DescribeBackfillArgs) InsertOpts() river.InsertOpts {
	return river.InsertOpts{Queue: describeQueue, UniqueOpts: river.UniqueOpts{ByArgs: true, ByState: []rivertype.JobState{
		rivertype.JobStateAvailable, rivertype.JobStatePending, rivertype.JobStateRetryable,
		rivertype.JobStateRunning, rivertype.JobStateScheduled,
	}}}
}

type describeBackfillWorker struct {
	river.WorkerDefaults[DescribeBackfillArgs]
	*deps
}

func (w *describeBackfillWorker) Timeout(*river.Job[DescribeBackfillArgs]) time.Duration {
	return ollamaPullTimeout + time.Minute
}

func (w *describeBackfillWorker) Work(ctx context.Context, _ *river.Job[DescribeBackfillArgs]) error {
	on, err := descriptionsOn(ctx, w.queries)
	if err != nil {
		return err
	}
	address, vision, text, err := OllamaSettings(ctx, w.queries)
	if err != nil {
		return err
	}
	if !on || address == "" {
		return nil
	}
	if err := NewOllama(address).EnsureModels(ctx, vision, text); err != nil {
		slog.Warn("the models for descriptions are not ready", "error", err)
		return nil
	}
	ids, err := w.queries.ListUndescribed(ctx, describeBatch)
	if err != nil {
		return err
	}
	for _, id := range ids {
		if _, err := w.client().Insert(ctx, DescribeArgs{AssetID: id.Bytes}, nil); err != nil {
			return err
		}
	}
	return nil
}

// AskModel answers with search words, or nothing if the model cannot say.
func AskModel(ctx context.Context, client *Ollama, model, question string) string {
	answer, err := client.Generate(ctx, model, askPrompt+question, nil)
	if err != nil {
		slog.Warn("a question was searched as it is", "error", err)
		return ""
	}
	return answer
}
