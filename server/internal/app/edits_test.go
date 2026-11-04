package app

import (
	"bytes"
	"context"
	"image"
	"image/jpeg"
	"net/http"
	"os"
	"testing"
	"time"

	_ "golang.org/x/image/webp" // Previews are WebP.

	"github.com/mediarr-app/mediarr/server/internal/api"
)

func landscapeJPEG(t *testing.T) []byte {
	t.Helper()
	var out bytes.Buffer
	if err := jpeg.Encode(&out, image.NewRGBA(image.Rect(0, 0, 800, 400)), nil); err != nil {
		t.Fatal(err)
	}
	return out.Bytes()
}

func (c *client) previewSize(t *testing.T, id, size string) (width, height int) {
	t.Helper()
	resp, body := c.get("/api/assets/" + id + "/thumbnail?size=" + size)
	expect(t, resp, body, http.StatusOK)
	config, _, err := image.DecodeConfig(bytes.NewReader(body))
	if err != nil {
		t.Fatal(err)
	}
	return config.Width, config.Height
}

func (c *client) waitForEdit(t *testing.T, id string) api.AssetDetail {
	t.Helper()
	end := time.Now().Add(30 * time.Second)
	for time.Now().Before(end) {
		detail := c.detail(id)
		if detail.IsEditing == nil || !*detail.IsEditing {
			return detail
		}
		time.Sleep(100 * time.Millisecond)
	}
	t.Fatal("the new previews never came")
	return api.AssetDetail{}
}

func TestEditsChangePreviewsAndNeverTheOriginal(t *testing.T) {
	s := newStack(t)
	s.startWorker(t)
	c := s.admin()
	other := s.user(c, "other@example.com")
	source := landscapeJPEG(t)
	id := uploadedID(t, c.upload("a.jpg", source, nil))
	waitForAsset(t, c, "a.jpg")
	end := time.Now().Add(30 * time.Second)
	for c.detail(id).Status != api.AssetDetailStatusReady && time.Now().Before(end) {
		time.Sleep(100 * time.Millisecond)
	}
	path := "/api/assets/" + id + "/edits"

	// Not someone else's, and not nonsense.
	resp, body := other.send(http.MethodPut, path, map[string]any{"rotate": 90})
	expect(t, resp, body, http.StatusNotFound)
	resp, body = c.send(http.MethodPut, path, map[string]any{"rotate": 45})
	expect(t, resp, body, http.StatusBadRequest)
	resp, body = other.get("/api/assets/" + id + "/thumbnail?size=source")
	expect(t, resp, body, http.StatusNotFound)

	// The full preview exists first, to prove it does not stay as it was.
	if w, h := c.previewSize(t, id, "full"); w < h {
		t.Fatalf("before: %dx%d", w, h)
	}
	resp, body = c.send(http.MethodPut, path, map[string]any{
		"rotate": 90, "crop": map[string]float64{"x": 0, "y": 0, "width": 1, "height": 0.5},
	})
	expect(t, resp, body, http.StatusNoContent)
	detail := c.waitForEdit(t, id)
	if detail.Edits == nil || detail.Edits.Rotate == nil || *detail.Edits.Rotate != 90 {
		t.Fatalf("detail: %+v", detail.Edits)
	}
	// 400x800 after turning, and the top half of that.
	for _, size := range []string{"large", "full"} {
		if w, h := c.previewSize(t, id, size); w != h {
			t.Fatalf("%s after the edit: %dx%d", size, w, h)
		}
	}
	// The editor still gets the whole picture, and the original is byte for byte the same.
	if w, h := c.previewSize(t, id, "source"); w <= h {
		t.Fatalf("source: %dx%d", w, h)
	}
	resp, body = c.get("/api/assets/" + id + "/original")
	expect(t, resp, body, http.StatusOK)
	if !bytes.Equal(body, source) {
		t.Fatal("the original changed")
	}

	resp, body = c.do(http.MethodDelete, path, nil, nil)
	expect(t, resp, body, http.StatusNoContent)
	detail = c.waitForEdit(t, id)
	if detail.Edits != nil {
		t.Fatalf("after clearing: %+v", detail.Edits)
	}
	if w, h := c.previewSize(t, id, "large"); w <= h {
		t.Fatalf("after clearing: %dx%d", w, h)
	}

	var stored string
	if err := s.pool.QueryRow(context.Background(), "SELECT original_path FROM assets WHERE id=$1", id).Scan(&stored); err != nil {
		t.Fatal(err)
	}
	onDisk, err := os.ReadFile(stored)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(onDisk, source) {
		t.Fatal("the file on disk changed")
	}
}

func TestOnlyPhotosCanBeEdited(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	id := c.newPhoto(t, "v.mp4", "2024-01-01T10:00:00Z")
	if _, err := s.pool.Exec(context.Background(), "UPDATE assets SET kind='video' WHERE id=$1", id); err != nil {
		t.Fatal(err)
	}
	resp, body := c.send(http.MethodPut, "/api/assets/"+id+"/edits", map[string]any{"rotate": 90})
	expect(t, resp, body, http.StatusConflict)
}
