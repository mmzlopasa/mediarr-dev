package webui

import (
	"bytes"
	"compress/gzip"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"testing/fstest"
)

func TestHandler(t *testing.T) {
	root := fstest.MapFS{
		"index.html":   {Data: []byte("<html>app</html>")},
		"_app/main.js": {Data: []byte("console.log(1)")},
	}

	tests := []struct {
		name     string
		method   string
		path     string
		wantCode int
		wantBody string
	}{
		{"root serves index", http.MethodGet, "/", http.StatusOK, "<html>app</html>"},
		{"client route serves index", http.MethodGet, "/albums/1", http.StatusOK, "<html>app</html>"},
		{"asset served", http.MethodGet, "/_app/main.js", http.StatusOK, "console.log(1)"},
		{"missing asset is 404", http.MethodGet, "/_app/none.js", http.StatusNotFound, ""},
		{"traversal stays inside root", http.MethodGet, "/../../etc/passwd", http.StatusOK, "<html>app</html>"},
		{"post is 404", http.MethodPost, "/", http.StatusNotFound, ""},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rec := httptest.NewRecorder()
			req := httptest.NewRequest(tt.method, tt.path, http.NoBody)

			handler(root).ServeHTTP(rec, req)

			if rec.Code != tt.wantCode {
				t.Errorf("status = %d, want %d", rec.Code, tt.wantCode)
			}
			if tt.wantBody != "" && rec.Body.String() != tt.wantBody {
				t.Errorf("body = %q, want %q", rec.Body.String(), tt.wantBody)
			}
		})
	}
}

func TestHandlerCachesAndCompresses(t *testing.T) {
	script := []byte(strings.Repeat("console.log('a long script');\n", 200))
	root := fstest.MapFS{
		"index.html":                    {Data: []byte("<html>app</html>")},
		"_app/immutable/entry/start.js": {Data: script},
		"favicon.svg":                   {Data: []byte("<svg/>")},
	}
	h := handler(root)

	get := func(path string, headers map[string]string) *httptest.ResponseRecorder {
		rec := httptest.NewRecorder()
		req := httptest.NewRequest(http.MethodGet, path, http.NoBody)
		for name, value := range headers {
			req.Header.Set(name, value)
		}
		h.ServeHTTP(rec, req)
		return rec
	}

	rec := get("/_app/immutable/entry/start.js", map[string]string{"Accept-Encoding": "br, gzip"})
	if got := rec.Header().Get("Cache-Control"); got != "public, max-age=31536000, immutable" {
		t.Errorf("hashed file Cache-Control = %q", got)
	}
	if rec.Header().Get("Content-Encoding") != "gzip" {
		t.Fatalf("hashed script was not compressed")
	}
	unpacked, err := gzip.NewReader(rec.Body)
	if err != nil {
		t.Fatal(err)
	}
	if body, _ := io.ReadAll(unpacked); !bytes.Equal(body, script) {
		t.Error("compressed script does not unpack to the script")
	}

	plain := get("/_app/immutable/entry/start.js", nil)
	if plain.Header().Get("Content-Encoding") != "" || !bytes.Equal(plain.Body.Bytes(), script) {
		t.Error("a browser that does not ask for gzip got it anyway")
	}

	tag := plain.Header().Get("ETag")
	if tag == "" {
		t.Fatal("no ETag")
	}
	if again := get("/_app/immutable/entry/start.js", map[string]string{"If-None-Match": tag}); again.Code != http.StatusNotModified {
		t.Errorf("revalidation = %d, want 304", again.Code)
	}

	for _, path := range []string{"/", "/albums/1", "/favicon.svg"} {
		if got := get(path, nil).Header().Get("Cache-Control"); got != "no-cache" {
			t.Errorf("%s Cache-Control = %q, want no-cache", path, got)
		}
	}
}
