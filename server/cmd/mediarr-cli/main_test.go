package main

import (
	"context"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strconv"
	"sync"
	"testing"
	"time"
)

// A server that takes the first part halfway and then fails, as a dropped connection would.
func TestAnUploadGoesOnFromWhereTheServerHasIt(t *testing.T) {
	data := make([]byte, 3000)
	for i := range data {
		data[i] = byte(i)
	}
	var (
		mu       sync.Mutex
		received []byte
		failed   bool
	)
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		mu.Lock()
		defer mu.Unlock()
		if r.Header.Get(keyHeader) != "key" {
			w.WriteHeader(http.StatusUnauthorized)
			return
		}
		switch r.Method {
		case http.MethodPost:
			w.Header().Set("Location", "/api/uploads/1")
			w.WriteHeader(http.StatusCreated)
		case http.MethodHead:
			w.Header().Set("Upload-Offset", strconv.Itoa(len(received)))
		case http.MethodPatch:
			offset, _ := strconv.Atoi(r.Header.Get("Upload-Offset"))
			if offset != len(received) {
				w.WriteHeader(http.StatusConflict)
				return
			}
			body, _ := io.ReadAll(r.Body)
			if !failed {
				failed = true
				received = append(received, body[:1000]...)
				w.WriteHeader(http.StatusBadGateway)
				return
			}
			received = append(received, body...)
			w.Header().Set("Upload-Offset", strconv.Itoa(len(received)))
			w.WriteHeader(http.StatusNoContent)
		}
	}))
	defer server.Close()

	path := filepath.Join(t.TempDir(), "photo.jpg")
	if err := os.WriteFile(path, data, 0o600); err != nil {
		t.Fatal(err)
	}
	c := &client{server: server.URL, key: "key", http: &http.Client{Timeout: 10 * time.Second}}
	f := &file{path: path, size: int64(len(data)), modified: time.Now(), checksum: "x"}
	if err := c.send(context.Background(), f, ""); err != nil {
		t.Fatal(err)
	}
	if string(received) != string(data) {
		t.Fatalf("the server has %d bytes, not the file", len(received))
	}
}

func TestOnlyPhotosAndVideosAreCollected(t *testing.T) {
	root := t.TempDir()
	for _, name := range []string{"a.JPG", "b.mov", "c.txt", ".d.jpg", "inner/e.heic", ".cache/f.jpg"} {
		path := filepath.Join(root, name)
		if err := os.MkdirAll(filepath.Dir(path), 0o750); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(path, []byte(name), 0o600); err != nil {
			t.Fatal(err)
		}
	}
	all, err := collect([]string{root}, true)
	if err != nil || len(all) != 3 {
		t.Fatalf("%v %+v", err, all)
	}
	top, err := collect([]string{root, filepath.Join(root, "a.JPG")}, false)
	if err != nil || len(top) != 2 {
		t.Fatalf("%v %+v", err, top)
	}
	if got := encodeMetadata(map[string]string{"filename": "a.jpg", "checksum": "ab"}); got != "checksum YWI=,filename YS5qcGc=" {
		t.Fatal(got)
	}
}
