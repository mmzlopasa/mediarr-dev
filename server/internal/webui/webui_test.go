package webui

import (
	"net/http"
	"net/http/httptest"
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
