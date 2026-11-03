// Package ml talks to the optional machine learning service.
package ml

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
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
)

// ErrDisabled means no service is configured.
var ErrDisabled = errors.New("picture analysis is not turned on")

// Client calls the service. An empty URL makes every call return ErrDisabled.
type Client struct {
	url  string
	http *http.Client
}

// New returns a client for the service at url.
func New(url string) *Client {
	return &Client{url: strings.TrimRight(url, "/"), http: &http.Client{}}
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
	if !c.Enabled() {
		return ErrDisabled
	}
	ctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.url+path, bytes.NewReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", contentType)
	resp, err := c.http.Do(req)
	if err != nil {
		return fmt.Errorf("call %s: %w", path, err)
	}
	defer func() { _ = resp.Body.Close() }()
	data, err := io.ReadAll(io.LimitReader(resp.Body, maxResponse))
	if err != nil {
		return fmt.Errorf("read %s: %w", path, err)
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

// Unreadable reports that the service could not read the picture, which trying again will not fix.
func (e *StatusError) Unreadable() bool { return e.Code == http.StatusUnprocessableEntity }

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
	client *Client
	mu     sync.Mutex
	values map[string]string
	order  []string
}

// NewCache wraps a client.
func NewCache(client *Client) *Cache {
	return &Cache{client: client, values: map[string]string{}}
}

// Enabled reports whether a service is configured.
func (c *Cache) Enabled() bool { return c.client.Enabled() }

// Text returns the query's vector, ready for pgvector.
func (c *Cache) Text(ctx context.Context, text string) (string, error) {
	c.mu.Lock()
	value, ok := c.values[text]
	c.mu.Unlock()
	if ok {
		return value, nil
	}
	embedding, err := c.client.EmbedText(ctx, text)
	if err != nil {
		return "", err
	}
	value = Vector(embedding)
	c.mu.Lock()
	defer c.mu.Unlock()
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
