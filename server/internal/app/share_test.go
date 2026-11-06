package app

import (
	"bytes"
	"net/http"
	"os/exec"
	"testing"
)

func TestAPhotoIsSentAsItIsOrSmallerForMessages(t *testing.T) {
	if _, err := exec.LookPath("vipsthumbnail"); err != nil {
		t.Skip("libvips is not installed; run through `make test`")
	}
	s := newStack(t)
	s.startWorker(t)
	admin := s.admin()
	stranger := s.user(admin, "stranger@example.com")
	original := pictureOf(t, 60)
	id := uploadedID(t, admin.upload("beach.jpg", original, nil))
	s.settle(t)

	resp, body := admin.get("/api/assets/" + id + "/share")
	expect(t, resp, body, http.StatusOK)
	if !bytes.Equal(body, original) || resp.Header.Get("Content-Disposition") != `attachment; filename=beach.jpg` {
		t.Fatalf("the original did not come as it is: %s", resp.Header.Get("Content-Disposition"))
	}

	resp, body = admin.get("/api/assets/" + id + "/share?small=true")
	expect(t, resp, body, http.StatusOK)
	if resp.Header.Get("Content-Type") != "image/jpeg" || !bytes.HasPrefix(body, []byte{0xFF, 0xD8}) {
		t.Fatalf("not a JPEG: %s", resp.Header.Get("Content-Type"))
	}
	if bytes.Contains(body, []byte("Exif")) {
		t.Fatal("the smaller file still carries its metadata")
	}

	resp, body = stranger.get("/api/assets/" + id + "/share")
	expect(t, resp, body, http.StatusNotFound)
}
