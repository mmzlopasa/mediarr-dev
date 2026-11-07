package app

import (
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"testing"

	"github.com/mediarr-app/mediarr/server/internal/api"
)

func makeFile(t *testing.T, name string, steps ...[]string) []byte {
	t.Helper()
	for _, step := range steps {
		if out, err := exec.Command(step[0], step[1:]...).CombinedOutput(); err != nil {
			t.Fatalf("%v: %v: %s", step, err, out)
		}
	}
	data, err := os.ReadFile(name)
	if err != nil {
		t.Fatal(err)
	}
	return data
}

func TestJPEGXLAndPanoramasAreShown(t *testing.T) {
	for _, tool := range []string{"vips", "exiftool"} {
		if _, err := exec.LookPath(tool); err != nil {
			t.Skip("media tools are not installed; run through `make test`")
		}
	}
	s := newStack(t)
	c := s.admin()
	s.startWorker(t)
	dir := t.TempDir()
	base := filepath.Join(dir, "base.jpg")
	jxl := filepath.Join(dir, "photo.jxl")
	pano := filepath.Join(dir, "pano.jpg")

	jxlData := makeFile(t, jxl,
		[]string{"vips", "gaussnoise", base, "800", "600"},
		[]string{"vips", "copy", base, jxl})
	panoData := makeFile(t, pano,
		[]string{"vips", "gaussnoise", pano + ".src.jpg", "1600", "800"},
		[]string{
			"exiftool", "-q", "-XMP-GPano:ProjectionType=equirectangular", "-XMP-GPano:UsePanoramaViewer=True",
			"-o", pano, pano + ".src.jpg",
		})

	jxlID := uploadedID(t, c.upload("photo.jxl", jxlData, nil))
	panoID := uploadedID(t, c.upload("pano.jpg", panoData, nil))
	if got := waitForAsset(t, c, "photo.jxl"); got.Status != api.AssetStatusReady {
		t.Fatalf("the JPEG XL file: %+v", got)
	}
	waitForAsset(t, c, "pano.jpg")

	// JPEG XL gets the same pictures as any photo, which every browser can show.
	for _, size := range []string{"", "?size=preview", "?size=full"} {
		resp, body := c.get("/api/assets/" + jxlID + "/thumbnail" + size)
		expect(t, resp, body, http.StatusOK)
		if resp.Header.Get("Content-Type") != "image/webp" || len(body) == 0 {
			t.Errorf("%s: %v", size, resp.Header)
		}
	}
	detail := c.detail(jxlID)
	if detail.MimeType == nil || *detail.MimeType != "image/jxl" || detail.Projection != nil {
		t.Errorf("%+v", detail)
	}

	// A panorama says so, on the timeline and in its details.
	panoDetail := c.detail(panoID)
	if panoDetail.Projection == nil || *panoDetail.Projection != "equirectangular" {
		t.Errorf("%+v", panoDetail)
	}
	month := c.readBucket(panoDetail.LocalAt[:7])
	panoramas := 0
	for _, item := range month.Items {
		if item.IsPanorama != nil && *item.IsPanorama {
			panoramas++
			if item.Id.String() != panoID {
				t.Errorf("%s is not the panorama", item.Id)
			}
		}
	}
	if panoramas != 1 {
		t.Errorf("%d panoramas in %+v", panoramas, month.Items)
	}
}
