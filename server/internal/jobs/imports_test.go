package jobs

import (
	"context"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func TestSidecarsAreFoundUnderGooglesNames(t *testing.T) {
	for _, row := range []struct {
		name  string
		names []string
		want  string
	}{
		{"IMG_1.jpg", []string{"IMG_1.jpg", "IMG_1.jpg.json"}, "IMG_1.jpg.json"},
		{"IMG_1.jpg", []string{"IMG_1.jpg", "IMG_1.jpg.supplemental-metadata.json"}, "IMG_1.jpg.supplemental-metadata.json"},
		{"IMG_1(1).jpg", []string{"IMG_1(1).jpg", "IMG_1.jpg(1).json", "IMG_1.jpg.json"}, "IMG_1.jpg(1).json"},
		{"IMG_1(1).jpg", []string{"IMG_1.jpg.supplemental-metadata(1).json"}, "IMG_1.jpg.supplemental-metadata(1).json"},
		{"IMG_2.jpg", []string{"IMG_1.jpg.json", "metadata.json"}, ""},
		{"a-very-long-photo-name-that-google-has-shortened-here.jpg", []string{"a-very-long-photo-name-that-google-has-shorte.json"}, "a-very-long-photo-name-that-google-has-shorte.json"},
	} {
		if got := FindTakeoutSidecar(row.name, row.names); got != row.want {
			t.Errorf("%s in %v: %q", row.name, row.names, got)
		}
	}
}

func TestTakeoutSidecarSaysWhenAndWhere(t *testing.T) {
	item, trashed, err := parseTakeoutSidecar([]byte(`{"photoTakenTime":{"timestamp":"1688205600"},
		"geoData":{"latitude":45.8,"longitude":15.9},"favorited":true,"archived":true}`))
	if err != nil || trashed {
		t.Fatal(err, trashed)
	}
	if !item.takenAt.Equal(time.Unix(1688205600, 0)) || *item.latitude != 45.8 || !item.favorite || !item.archived {
		t.Fatalf("%+v", item)
	}
	// Zero is what Google writes when it does not know.
	item, trashed, err = parseTakeoutSidecar([]byte(`{"geoData":{"latitude":0,"longitude":0},"trashed":true}`))
	if err != nil || !trashed || item.latitude != nil || item.takenAt != nil {
		t.Fatalf("%+v %v %v", item, trashed, err)
	}
}

func TestICloudDetailsAreReadByColumnName(t *testing.T) {
	rows, err := ReadICloudDetails(strings.NewReader("\ufeffimgName,fileChecksum,favorite,hidden,deleted,originalCreationDate\n" +
		"IMG_1.HEIC,x,yes,no,no,\"Monday May 1,2023 10:00 AM GMT\"\nIMG_2.jpg,y,no,yes,yes,not a date\n"))
	if err != nil {
		t.Fatal(err)
	}
	one := rows["img_1.heic"]
	if !one.Favorite || one.Hidden || one.TakenAt == nil || one.TakenAt.Year() != 2023 {
		t.Fatalf("%+v", one)
	}
	two := rows["img_2.jpg"]
	if !two.Deleted || !two.Hidden || two.TakenAt != nil {
		t.Fatalf("%+v", two)
	}
	if _, err := ReadICloudDetails(strings.NewReader("something,else\n")); err == nil {
		t.Fatal("a file without names of photos is an error")
	}
}

func TestAFaceGoesToTheHintThatCoversIt(t *testing.T) {
	face := [4]float32{0.1, 0.1, 0.3, 0.3}
	if overlap(face, [4]float32{0.1, 0.1, 0.3, 0.3}) < 0.99 {
		t.Error("the same box")
	}
	if overlap(face, [4]float32{0.5, 0.5, 0.7, 0.7}) != 0 {
		t.Error("boxes apart")
	}
	if got := overlap(face, [4]float32{0.2, 0.1, 0.4, 0.3}); got < 0.3 || got > 0.4 {
		t.Errorf("half covered: %f", got)
	}
}

func TestAnImportGivesUpOnABodyThatStopsComing(t *testing.T) {
	release := make(chan struct{})
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Length", "1000")
		_, _ = w.Write([]byte("start"))
		w.(http.Flusher).Flush()
		<-release
	}))
	defer server.Close()
	defer close(release) // Runs first, so the handler ends before the server closes.
	ctx, watch, stop := stallGuard(context.Background(), 100*time.Millisecond)
	defer stop()
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, server.URL, http.NoBody)
	if err != nil {
		t.Fatal(err)
	}
	response, err := importHTTP.Do(request)
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = response.Body.Close() }()
	done := make(chan error, 1)
	go func() {
		_, err := io.Copy(io.Discard, watch(response.Body))
		done <- stalledErr(ctx, err)
	}()
	select {
	case err := <-done:
		if !errors.Is(err, errStalled) {
			t.Errorf("error %v, want a stall", err)
		}
	case <-time.After(5 * time.Second):
		t.Fatal("the copy still waits on a body that stopped")
	}
}
