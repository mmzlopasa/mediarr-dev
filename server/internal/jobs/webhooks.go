package jobs

import (
	"bytes"
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"syscall"
	"time"

	"github.com/google/uuid"
	"github.com/riverqueue/river"

	"github.com/mmzlopasa/mediarr-app/server/db"
)

const (
	webhookWait     = 10 * time.Second
	maxWebhookError = 300
	featureWebhooks = "webhooks"
)

// What a webhook can listen to, and the one the test button sends.
const (
	EventAssetReady     = "asset.ready"
	EventPersonCreated  = "person.created"
	EventBackupFinished = "backup.finished"
	EventTest           = "test"
)

// WebhookArgs sends one event to one address.
type WebhookArgs struct {
	Webhook uuid.UUID       `json:"webhook"`
	Body    json.RawMessage `json:"body"`
	Event   string          `json:"event"`
}

// Kind identifies the job in the queue.
func (WebhookArgs) Kind() string { return "webhook" }

// IsBlockedAddress keeps a webhook away from this machine and from cloud metadata services. Addresses
// on the local network stay allowed, because that is where Home Assistant and the like live.
func IsBlockedAddress(ip net.IP) bool {
	return ip.IsLoopback() || ip.IsLinkLocalUnicast() || ip.IsLinkLocalMulticast() || ip.IsMulticast() || ip.IsUnspecified()
}

// webhookClient checks the address it actually connects to, so that a name which resolves to
// something else later (DNS rebinding) gets no further. It follows no redirects, for the same reason.
func webhookClient(allowLocal bool) *http.Client {
	dialer := &net.Dialer{
		Timeout: webhookWait,
		Control: func(_, address string, _ syscall.RawConn) error {
			host, _, err := net.SplitHostPort(address)
			if err != nil {
				return err
			}
			if ip := net.ParseIP(host); !allowLocal && (ip == nil || IsBlockedAddress(ip)) {
				return fmt.Errorf("a webhook cannot reach %s", host)
			}
			return nil
		},
	}
	return &http.Client{
		Timeout:       webhookWait,
		Transport:     &http.Transport{DialContext: dialer.DialContext},
		CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse },
	}
}

// SignWebhook is what a receiver computes to know that the message is from this server.
func SignWebhook(secret string, body []byte) string {
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write(body)
	return "sha256=" + hex.EncodeToString(mac.Sum(nil))
}

type webhookWorker struct {
	river.WorkerDefaults[WebhookArgs]
	*deps
}

func (w *webhookWorker) Work(ctx context.Context, job *river.Job[WebhookArgs]) error {
	id := toPG(job.Args.Webhook)
	hook, err := w.queries.GetWebhook(ctx, id)
	if db.IsNotFound(err) {
		return river.JobCancel(err)
	}
	if err != nil {
		return err
	}
	status, sendErr := deliverWebhook(ctx, webhookClient(w.opts.AllowLocalWebhooks), hook.Url, hook.Secret, job.Args.Event, job.Args.Body)
	message := ""
	if sendErr != nil {
		message = truncate(sendErr.Error(), maxWebhookError)
	}
	if err := w.queries.RecordWebhookDelivery(ctx, db.RecordWebhookDeliveryParams{ID: id, LastStatus: int32(status), LastError: message}); err != nil { //nolint:gosec // An HTTP status.
		return err
	}
	// A refusal stays a refusal. Only a server in trouble, or none at all, is worth trying again.
	if sendErr != nil || status >= http.StatusInternalServerError {
		return fmt.Errorf("webhook delivery: status %d: %s", status, message)
	}
	return nil
}

func deliverWebhook(ctx context.Context, client *http.Client, address, secret, event string, body []byte) (int, error) {
	request, err := http.NewRequestWithContext(ctx, http.MethodPost, address, bytes.NewReader(body))
	if err != nil {
		return 0, err
	}
	request.Header.Set("Content-Type", "application/json")
	request.Header.Set("X-Mediarr-Event", event)
	request.Header.Set("X-Mediarr-Signature", SignWebhook(secret, body))
	response, err := client.Do(request)
	if err != nil {
		return 0, err
	}
	defer func() { _ = response.Body.Close() }()
	return response.StatusCode, nil
}

// WebhookBody says what happened by ids alone. Names, places and pictures stay on this server.
func WebhookBody(event string, fields map[string]string) (json.RawMessage, error) {
	out := map[string]string{"event": event, "at": time.Now().UTC().Format(time.RFC3339)}
	for key, value := range fields {
		out[key] = value
	}
	return json.Marshal(out)
}

// emitWebhook queues the event for each address that listens to it. Failing to do so must never
// fail the work the event is about, so it only logs.
func (d *deps) emitWebhook(ctx context.Context, event string, fields map[string]string) {
	on, err := d.queries.GetState(ctx, StateFeaturePrefix+featureWebhooks)
	if err != nil || on != "1" {
		if err != nil && !db.IsNotFound(err) {
			slog.Warn("webhooks could not be checked", "error", err)
		}
		return
	}
	hooks, err := d.queries.WebhooksForEvent(ctx, event)
	if err != nil {
		slog.Warn("webhooks could not be listed", "error", err)
		return
	}
	body, err := WebhookBody(event, fields)
	if err != nil {
		return
	}
	for _, hook := range hooks {
		if _, err := d.client().Insert(ctx, WebhookArgs{Webhook: uuid.UUID(hook.Bytes), Event: event, Body: body}, nil); err != nil {
			slog.Warn("a webhook could not be queued", "error", err)
		}
	}
}
