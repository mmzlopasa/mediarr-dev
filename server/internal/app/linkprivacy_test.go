package app

import (
	"bytes"
	"context"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"

	"github.com/mediarr-app/mediarr/server/internal/api"
)

func TestADeviceIsNamedFromItsBrowser(t *testing.T) {
	for agent, want := range map[string]string{
		"Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 Version/18.0 Mobile/15E148 Safari/604.1": "iPhone · Safari",
		"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/131.0 Safari/537.36 Edg/131.0":                   "Windows · Edge",
		"Mozilla/5.0 (X11; Linux x86_64; rv:133.0) Gecko/20100101 Firefox/133.0":                                              "Linux · Firefox",
		"": "Computer · Browser",
	} {
		if got := deviceOf(agent); got != want {
			t.Errorf("%q: %s", agent, got)
		}
	}
}

// privatePhoto uploads a real photo with a camera and a date, and waits for its previews.
func privatePhoto(t *testing.T, c *client) string {
	t.Helper()
	for _, tool := range []string{"vips", "exiftool"} {
		if _, err := exec.LookPath(tool); err != nil {
			t.Skip("media tools are not installed; run through `make test`")
		}
	}
	dir := t.TempDir()
	plain, photo := filepath.Join(dir, "plain.jpg"), filepath.Join(dir, "face.jpg")
	for _, step := range [][]string{
		{"vips", "sines", plain, "640", "480"},
		{
			"exiftool", "-q", "-Make=Canon", "-Model=EOS R5", "-SerialNumber=123456", "-Artist=Ana",
			"-DateTimeOriginal=2024:07:05 10:00:00", "-o", photo, plain,
		},
	} {
		if out, err := exec.Command(step[0], step[1:]...).CombinedOutput(); err != nil {
			t.Fatalf("%v: %s", err, out)
		}
	}
	data, err := os.ReadFile(photo)
	if err != nil {
		t.Fatal(err)
	}
	id := uploadedID(t, c.upload("face.jpg", data, nil))
	waitForAsset(t, c, "face.jpg")
	return id
}

func TestALinkHidesFacesTakesOutDetailsAndKnowsWhoOpenedIt(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	s.startWorker(t)
	id := privatePhoto(t, c)
	album := c.newAlbum(map[string]any{"title": "Summer"})
	resp, body := c.post("/api/albums/"+album+"/assets", map[string]any{"ids": []string{id}})
	expect(t, resp, body, http.StatusOK)
	// A face in the middle of the preview, as the analysis would have found it.
	s.exec(t, `INSERT INTO faces (asset_id, user_id, x1, y1, x2, y2, score, embedding)
		SELECT a.id, a.user_id, 0.4 * a.width, 0.4 * a.height, 0.6 * a.width, 0.6 * a.height, 0.9, array_fill(0.1, ARRAY[512])::real[]::vector
		FROM assets a WHERE a.id = $1`, id)

	resp, body = c.post("/api/albums/"+album+"/links", map[string]any{"askName": true})
	expect(t, resp, body, http.StatusCreated)
	link := decode[api.ShareLink](t, body)
	if link.StripCamera == nil || !*link.StripCamera || link.HideFaces == nil || *link.HideFaces != api.HideFacesNone {
		t.Fatalf("a new link takes camera details out: %s", body)
	}
	token := *link.Token
	public := "/api/public/" + token

	// The visitor is asked who they are before seeing anything.
	guest := s.client()
	resp, body = guest.get(public)
	expect(t, resp, body, http.StatusOK)
	if opened := decode[api.PublicLink](t, body); opened.AskName == nil || !*opened.AskName || *opened.Named {
		t.Fatalf("%s", body)
	}
	resp, body = guest.get(public + "/buckets")
	expect(t, resp, body, http.StatusForbidden)
	resp, body = guest.post(public+"/visitor", map[string]string{"name": "Marko"})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = guest.get(public + "/buckets")
	expect(t, resp, body, http.StatusOK)

	// The download has no camera, serial number or author, and keeps its date.
	resp, body = guest.get(public + "/assets/" + id + "/original?download=true")
	expect(t, resp, body, http.StatusOK)
	details := exifOf(t, body)
	for _, gone := range []string{"Canon", "123456", "Ana"} {
		if strings.Contains(details, gone) {
			t.Fatalf("%s is still in the download: %s", gone, details)
		}
	}
	if !strings.Contains(details, "2024:07:05") {
		t.Fatalf("the date went: %s", details)
	}

	// Faces hidden: the preview changes, and the download is a blurred JPEG without details.
	resp, body = c.get(public + "/assets/" + id + "/thumbnail?size=large")
	expect(t, resp, body, http.StatusOK)
	plainPreview := body
	resp, body = c.send(http.MethodPatch, "/api/albums/"+album+"/links/"+link.Id.String(), map[string]any{"hideFaces": "all", "askName": false})
	expect(t, resp, body, http.StatusOK)
	resp, body = guest.get(public + "/assets/" + id + "/thumbnail?size=large")
	expect(t, resp, body, http.StatusOK)
	if bytes.Equal(body, plainPreview) {
		t.Fatal("the preview did not change when faces were hidden")
	}
	resp, body = guest.get(public + "/assets/" + id + "/original?download=true")
	expect(t, resp, body, http.StatusOK)
	if !bytes.HasPrefix(body, []byte{0xFF, 0xD8}) || strings.Contains(exifOf(t, body), "Canon") {
		t.Fatal("the download is not a blurred JPEG without details")
	}

	// Who opened it: one visit for the guest, however often, and none for the owner.
	resp, body = guest.get(public)
	expect(t, resp, body, http.StatusOK)
	resp, body = c.get(public)
	expect(t, resp, body, http.StatusOK)
	resp, body = c.get("/api/albums/" + album + "/links/" + link.Id.String() + "/visits")
	expect(t, resp, body, http.StatusOK)
	visits := decode[[]api.LinkVisit](t, body)
	if len(visits) != 1 || visits[0].Name == nil || *visits[0].Name != "Marko" || visits[0].Downloaded != 2 {
		t.Fatalf("%s", body)
	}
	resp, body = c.get("/api/notifications")
	expect(t, resp, body, http.StatusOK)
	if !strings.Contains(string(body), "link_opened") {
		t.Fatalf("the owner was not told: %s", body)
	}
	// Someone else cannot read them.
	other := s.user(c, "other@example.com")
	resp, body = other.get("/api/albums/" + album + "/links/" + link.Id.String() + "/visits")
	if resp.StatusCode < http.StatusBadRequest {
		t.Fatalf("%d %s", resp.StatusCode, body)
	}

	resp, body = c.get("/api/albums/" + album + "/privacy")
	expect(t, resp, body, http.StatusOK)
	if facts := decode[api.AlbumPrivacy](t, body); facts.Photos != 1 {
		t.Fatalf("%s", body)
	}
}

func TestMyPhotoIsSharedWithoutWhatIKeep(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	s.startWorker(t)
	id := privatePhoto(t, c)
	resp, body := c.get("/api/assets/" + id + "/shareable")
	expect(t, resp, body, http.StatusOK)
	if details := exifOf(t, body); strings.Contains(details, "Canon") {
		t.Fatalf("%s", details)
	}
	resp, body = c.get("/api/assets/" + id + "/shareable?camera=true")
	expect(t, resp, body, http.StatusOK)
	if details := exifOf(t, body); !strings.Contains(details, "Canon") {
		t.Fatalf("%s", details)
	}
	resp, body = c.get("/api/assets/" + id + "/shareable?faces=all")
	expect(t, resp, body, http.StatusOK)
	resp, body = s.user(c, "other@example.com").get("/api/assets/" + id + "/shareable")
	expect(t, resp, body, http.StatusNotFound)
}

// exifOf reads what a file says about itself.
func exifOf(t *testing.T, data []byte) string {
	t.Helper()
	path := filepath.Join(t.TempDir(), "file.jpg")
	if err := os.WriteFile(path, data, 0o600); err != nil {
		t.Fatal(err)
	}
	out, err := exec.CommandContext(context.Background(), "exiftool", "-s", "-Make", "-SerialNumber", "-Artist", "-DateTimeOriginal", path).CombinedOutput()
	if err != nil {
		t.Fatalf("%v: %s", err, out)
	}
	return string(out)
}
