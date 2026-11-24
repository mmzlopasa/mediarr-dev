// Package webui serves the SvelteKit client embedded into the binary.
package webui

import (
	"bytes"
	"compress/gzip"
	"crypto/sha256"
	"embed"
	"encoding/hex"
	"io/fs"
	"mime"
	"net/http"
	"path"
	"strings"
	"sync"
	"time"
)

// dist is populated by `make web-build` and by the Docker image build.
//
//go:embed all:dist
var dist embed.FS

// immutableDir holds the files SvelteKit names after their content, so they never change.
const immutableDir = "_app/immutable/"

// compressible are the kinds of file worth sending compressed; pictures and fonts already are.
var compressible = map[string]bool{
	".js": true, ".mjs": true, ".css": true, ".html": true, ".svg": true, ".json": true,
	".txt": true, ".xml": true, ".webmanifest": true, ".map": true,
}

// Handler serves static files, falling back to index.html for client-side routes.
func Handler() http.Handler {
	root, err := fs.Sub(dist, "dist")
	if err != nil {
		panic(err) // dist is embedded at compile time, so this cannot fail at runtime.
	}
	return handler(root)
}

// file is what is known about one embedded file, worked out the first time it is asked for.
type file struct {
	data   []byte
	etag   string
	gzip   []byte
	gzETag string
}

type server struct {
	root  fs.FS
	mu    sync.Mutex
	files map[string]*file
}

// load reads a file once. Embedded files have no time of change, so the ETag, from the content,
// is what lets a browser keep what it has.
func (s *server) load(name string) (*file, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if f, ok := s.files[name]; ok {
		return f, nil
	}
	data, err := fs.ReadFile(s.root, name)
	if err != nil {
		return nil, err
	}
	sum := sha256.Sum256(data)
	tag := hex.EncodeToString(sum[:12])
	f := &file{data: data, etag: `"` + tag + `"`}
	if compressible[path.Ext(name)] && len(data) > 1024 {
		var packed bytes.Buffer
		writer, _ := gzip.NewWriterLevel(&packed, gzip.BestCompression)
		_, _ = writer.Write(data)
		_ = writer.Close()
		if packed.Len() < len(data) {
			f.gzip, f.gzETag = packed.Bytes(), `"`+tag+`-gz"`
		}
	}
	s.files[name] = f
	return f, nil
}

func acceptsGzip(r *http.Request) bool {
	for part := range strings.SplitSeq(r.Header.Get("Accept-Encoding"), ",") {
		coding, quality, _ := strings.Cut(strings.TrimSpace(part), ";")
		if strings.EqualFold(strings.TrimSpace(coding), "gzip") && strings.ReplaceAll(quality, " ", "") != "q=0" {
			return true
		}
	}
	return false
}

func (s *server) serve(w http.ResponseWriter, r *http.Request, name string, f *file) {
	if strings.HasPrefix(name, immutableDir) {
		w.Header().Set("Cache-Control", "public, max-age=31536000, immutable")
	} else {
		w.Header().Set("Cache-Control", "no-cache")
	}
	if kind := mime.TypeByExtension(path.Ext(name)); kind != "" {
		w.Header().Set("Content-Type", kind)
	}
	body, tag := f.data, f.etag
	if f.gzip != nil {
		w.Header().Add("Vary", "Accept-Encoding")
		// A range of the compressed bytes is no use to anyone, so a range gets the plain file.
		if acceptsGzip(r) && r.Header.Get("Range") == "" {
			body, tag = f.gzip, f.gzETag
			w.Header().Set("Content-Encoding", "gzip")
		}
	}
	w.Header().Set("ETag", tag)
	http.ServeContent(w, r, "", time.Time{}, bytes.NewReader(body))
}

func handler(root fs.FS) http.Handler {
	s := &server{root: root, files: map[string]*file{}}

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Another site must not be able to show this in a frame and trick someone into clicking it.
		w.Header().Set("X-Frame-Options", "SAMEORIGIN")
		w.Header().Set("Content-Security-Policy", "frame-ancestors 'self'")
		w.Header().Set("X-Content-Type-Options", "nosniff")
		if r.Method != http.MethodGet && r.Method != http.MethodHead {
			http.NotFound(w, r)
			return
		}

		name := strings.TrimPrefix(path.Clean("/"+r.URL.Path), "/")
		if name != "" && name != "index.html" {
			if info, err := fs.Stat(root, name); err == nil && !info.IsDir() {
				if f, err := s.load(name); err == nil {
					s.serve(w, r, name, f)
					return
				}
			}
		}

		// Missing assets must 404 so browsers do not parse HTML as a script.
		if path.Ext(name) != "" && name != "index.html" {
			http.NotFound(w, r)
			return
		}

		index, err := s.load("index.html")
		if err != nil {
			http.NotFound(w, r)
			return
		}
		s.serve(w, r, "index.html", index)
	})
}
