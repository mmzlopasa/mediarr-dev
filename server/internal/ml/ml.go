// Package ml talks to the optional machine learning service.
package ml

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"strings"
	"sync"
	"time"
)

const (
	// The first answer can take long, because the service fetches its models then.
	analyzeTimeout = 15 * time.Minute
	textTimeout    = 2 * time.Minute
	maxResponse    = 8 * 1024 * 1024
	cacheSize      = 500
	statusTimeout  = 3 * time.Second
	dialTimeout    = 5 * time.Second
	// After the service fails, searches go without it for this long instead of each waiting again.
	downBackoff = 15 * time.Second
)

// ErrDisabled means no service is configured.
var ErrDisabled = errors.New("picture analysis is not turned on")

// ErrWrongToken means the service refused ML_TOKEN, or asks for one that is not set here.
var ErrWrongToken = errors.New("the analysis service refused the token: ML_TOKEN must be the same on both sides")

// unreachableError means no answer came, as opposed to an answer that was an error.
type unreachableError struct{ cause error }

func (e *unreachableError) Error() string { return e.cause.Error() }
func (e *unreachableError) Unwrap() error { return e.cause }

// Unavailable reports that the service cannot do its work now, whatever the picture or the query.
// Trying again later is the right answer to all of these; a wrong token also needs the owner.
func Unavailable(err error) bool {
	var (
		unreachable *unreachableError
		status      *StatusError
	)
	if errors.Is(err, ErrWrongToken) || errors.As(err, &unreachable) {
		return true
	}
	return errors.As(err, &status) && status.Code >= http.StatusBadGateway && status.Code <= http.StatusGatewayTimeout
}

// Client calls the service. An empty URL makes every call return ErrDisabled.
type Client struct {
	url   string
	token string
	http  *http.Client
}

// New returns a client for the service at url. The token, if any, goes to that address only:
// redirects are not followed.
func New(url, token string) *Client {
	transport := http.DefaultTransport.(*http.Transport).Clone() //nolint:errcheck,forcetypeassert // Always this type.
	transport.DialContext = (&net.Dialer{Timeout: dialTimeout, KeepAlive: 30 * time.Second}).DialContext
	return &Client{url: strings.TrimRight(url, "/"), token: strings.TrimSpace(token), http: &http.Client{
		Transport:     transport,
		CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse },
	}}
}

// Enabled reports whether a service is configured.
func (c *Client) Enabled() bool { return c.url != "" }

// Face is one face on a picture.
type Face struct {
	Box       [4]float32 `json:"box"`
	Score     float32    `json:"score"`
	Embedding []float32  `json:"embedding"`
}

func (c *Client) post(ctx context.Context, path, contentType string, body []byte, timeout time.Duration, out any) error {
	return c.call(ctx, http.MethodPost, path, contentType, body, timeout, out)
}

func (c *Client) call(ctx context.Context, method, path, contentType string, body []byte, timeout time.Duration, out any) error {
	if !c.Enabled() {
		return ErrDisabled
	}
	ctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	req, err := http.NewRequestWithContext(ctx, method, c.url+path, bytes.NewReader(body))
	if err != nil {
		return err
	}
	if contentType != "" {
		req.Header.Set("Content-Type", contentType)
	}
	if c.token != "" {
		req.Header.Set("Authorization", "Bearer "+c.token)
	}
	resp, err := c.http.Do(req)
	if err != nil {
		return &unreachableError{fmt.Errorf("call %s: %w", path, err)}
	}
	defer func() { _ = resp.Body.Close() }()
	data, err := io.ReadAll(io.LimitReader(resp.Body, maxResponse))
	if err != nil {
		return &unreachableError{fmt.Errorf("read %s: %w", path, err)}
	}
	if resp.StatusCode == http.StatusUnauthorized {
		return ErrWrongToken
	}
	if resp.StatusCode != http.StatusOK {
		return &StatusError{Path: path, Code: resp.StatusCode}
	}
	return json.Unmarshal(data, out)
}

// StatusError is an answer other than success.
type StatusError struct {
	Path string
	Code int
}

func (e *StatusError) Error() string { return fmt.Sprintf("%s answered %d", e.Path, e.Code) }

// Unreadable reports that the service could not read the picture (422), or would not take it because
// it is larger than its limit (413). Trying again fixes neither.
func (e *StatusError) Unreadable() bool {
	return e.Code == http.StatusUnprocessableEntity || e.Code == http.StatusRequestEntityTooLarge
}

const pictureType = "application/octet-stream"

// EmbedImage turns a picture into a vector.
func (c *Client) EmbedImage(ctx context.Context, picture []byte) ([]float32, error) {
	var out struct {
		Embedding []float32 `json:"embedding"`
	}
	err := c.post(ctx, "/clip/image", pictureType, picture, analyzeTimeout, &out)
	return out.Embedding, err
}

// EmbedText turns a search query into a vector.
func (c *Client) EmbedText(ctx context.Context, text string) ([]float32, error) {
	body, err := json.Marshal(map[string]string{"text": text})
	if err != nil {
		return nil, err
	}
	var out struct {
		Embedding []float32 `json:"embedding"`
	}
	err = c.post(ctx, "/clip/text", "application/json", body, textTimeout, &out)
	return out.Embedding, err
}

// Faces finds the faces on a picture.
func (c *Client) Faces(ctx context.Context, picture []byte) ([]Face, error) {
	var out struct {
		Faces []Face `json:"faces"`
	}
	err := c.post(ctx, "/faces", pictureType, picture, analyzeTimeout, &out)
	return out.Faces, err
}

// ReadText reads the text on a picture.
func (c *Client) ReadText(ctx context.Context, picture []byte) (string, error) {
	var out struct {
		Text string `json:"text"`
	}
	err := c.post(ctx, "/ocr", pictureType, picture, analyzeTimeout, &out)
	return out.Text, err
}

// ModelStatus is one model of the service.
type ModelStatus struct {
	Name        string   `json:"name"`
	Loaded      bool     `json:"loaded"`
	InUse       int      `json:"in_use"`
	IdleSeconds *float64 `json:"idle_seconds"`
}

// Status is what the service says about itself.
type Status struct {
	Models       []ModelStatus `json:"models"`
	RSSBytes     *int64        `json:"rss_bytes"`
	Acceleration struct {
		Requested string   `json:"requested"`
		Providers []string `json:"providers"`
	} `json:"acceleration"`
	IdleMinutes float64 `json:"idle_minutes"`
}

// Status asks the service how it is, without waiting long for one that is not there.
func (c *Client) Status(ctx context.Context) (*Status, error) {
	var out Status
	if err := c.call(ctx, http.MethodGet, "/status", "", nil, statusTimeout, &out); err != nil {
		return nil, err
	}
	return &out, nil
}

// Vector writes a vector the way pgvector reads it.
func Vector(values []float32) string {
	var out strings.Builder
	out.WriteByte('[')
	for i, value := range values {
		if i > 0 {
			out.WriteByte(',')
		}
		fmt.Fprintf(&out, "%g", value)
	}
	out.WriteByte(']')
	return out.String()
}

// Cache remembers the vectors of recent queries, because people repeat and refine them.
type Cache struct {
	client    *Client
	mu        sync.Mutex
	values    map[string]string
	order     []string
	downUntil time.Time
}

// NewCache wraps a client.
func NewCache(client *Client) *Cache {
	return &Cache{client: client, values: map[string]string{}}
}

// Enabled reports whether a service is configured.
func (c *Cache) Enabled() bool { return c.client.Enabled() }

// Client is the client this cache wraps.
func (c *Cache) Client() *Client { return c.client }

// ErrCoolingOff means the service failed moments ago, so it was not asked again.
var ErrCoolingOff = errors.New("the analysis service was not available moments ago")

// Text returns the query's vector, ready for pgvector.
func (c *Cache) Text(ctx context.Context, text string) (string, error) {
	c.mu.Lock()
	value, ok := c.values[text]
	cooling := time.Now().Before(c.downUntil)
	c.mu.Unlock()
	if ok {
		return value, nil
	}
	if cooling {
		return "", ErrCoolingOff
	}
	embedding, err := c.client.EmbedText(ctx, text)
	if err != nil {
		// Someone closing the page says nothing about the service.
		if Unavailable(err) && !errors.Is(err, context.Canceled) {
			c.mu.Lock()
			c.downUntil = time.Now().Add(downBackoff)
			c.mu.Unlock()
		}
		return "", err
	}
	value = Vector(embedding)
	c.mu.Lock()
	defer c.mu.Unlock()
	c.downUntil = time.Time{}
	if _, known := c.values[text]; !known {
		c.values[text] = value
		c.order = append(c.order, text)
		if len(c.order) > cacheSize {
			delete(c.values, c.order[0])
			c.order = c.order[1:]
		}
	}
	return value, nil
}
