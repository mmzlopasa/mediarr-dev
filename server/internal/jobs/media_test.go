package jobs

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
	"time"
)

func requireTools(t *testing.T) {
	t.Helper()
	for _, tool := range []string{"exiftool", "vips", "ffmpeg", "dcraw_emu"} {
		if _, err := exec.LookPath(tool); err != nil {
			t.Skipf("%s is not installed; run through `make test`", tool)
		}
	}
}

func parse(t *testing.T, doc string) (*Metadata, error) {
	t.Helper()
	var row map[string]any
	if err := json.Unmarshal([]byte(doc), &row); err != nil {
		t.Fatal(err)
	}
	return parseMetadata(row)
}

func TestTakenAtKeepsInstantAndOffset(t *testing.T) {
	meta, err := parse(t, `{"MIMEType":"image/jpeg","DateTimeOriginal":"2024:07:01 12:00:00","OffsetTimeOriginal":"+02:00"}`)
	if err != nil {
		t.Fatal(err)
	}
	want := time.Date(2024, 7, 1, 10, 0, 0, 0, time.UTC)
	if meta.TakenAt == nil || !meta.TakenAt.Equal(want) {
		t.Errorf("taken at %v, want %v", meta.TakenAt, want)
	}
	if meta.OffsetMinutes == nil || *meta.OffsetMinutes != 120 {
		t.Errorf("offset %v", meta.OffsetMinutes)
	}
}

func TestTakenAtWithoutZoneKeepsTheDay(t *testing.T) {
	meta, err := parse(t, `{"MIMEType":"image/jpeg","DateTimeOriginal":"2024:07:01 23:30:00"}`)
	if err != nil {
		t.Fatal(err)
	}
	if meta.TakenAt.Day() != 1 || meta.OffsetMinutes != nil {
		t.Errorf("got %v, %v", meta.TakenAt, meta.OffsetMinutes)
	}
}

func TestZeroDateIsIgnored(t *testing.T) {
	meta, err := parse(t, `{"MIMEType":"video/mp4","CreateDate":"0000:00:00 00:00:00"}`)
	if err != nil {
		t.Fatal(err)
	}
	if meta.TakenAt != nil {
		t.Errorf("got %v", meta.TakenAt)
	}
}

func TestOrientationSwapsSides(t *testing.T) {
	meta, err := parse(t, `{"MIMEType":"image/jpeg","ImageWidth":4000,"ImageHeight":3000,"Orientation":6}`)
	if err != nil {
		t.Fatal(err)
	}
	if meta.Width != 3000 || meta.Height != 4000 {
		t.Errorf("got %dx%d", meta.Width, meta.Height)
	}
}

func TestInvalidGPSIsDropped(t *testing.T) {
	meta, err := parse(t, `{"MIMEType":"image/jpeg","GPSLatitude":999,"GPSLongitude":15}`)
	if err != nil {
		t.Fatal(err)
	}
	if meta.Latitude != nil {
		t.Error("kept invalid GPS")
	}
}

func TestUnsupportedTypeIsPermanent(t *testing.T) {
	_, err := parse(t, `{"MIMEType":"text/plain"}`)
	var bad *badFileError
	if !errors.As(err, &bad) {
		t.Fatalf("got %v", err)
	}
}

func TestNulInMetadataDoesNotReachDatabase(t *testing.T) {
	meta, err := parse(t, `{"MIMEType":"image/jpeg","Make":"Can\u0000on"}`)
	if err != nil {
		t.Fatal(err)
	}
	if meta.Make != "Canon" {
		t.Errorf("make = %q", meta.Make)
	}
	if string(meta.Raw) == "" || json.Valid(meta.Raw) == false {
		t.Error("raw is not valid JSON")
	}
}

func TestPipelineOnRealFiles(t *testing.T) {
	requireTools(t)
	ctx := context.Background()
	dir := t.TempDir()

	jpeg := filepath.Join(dir, "photo.jpg")
	if out, err := exec.Command("vips", "gaussnoise", jpeg, "2000", "1000").CombinedOutput(); err != nil {
		t.Fatalf("%v: %s", err, out)
	}
	if out, err := exec.Command("exiftool", "-q", "-overwrite_original", "-DateTimeOriginal=2024:05:06 07:08:09", "-OffsetTimeOriginal=+01:00", jpeg).CombinedOutput(); err != nil {
		t.Fatalf("%v: %s", err, out)
	}
	before, err := os.ReadFile(jpeg)
	if err != nil {
		t.Fatal(err)
	}

	meta, err := ReadMetadata(ctx, jpeg)
	if err != nil {
		t.Fatal(err)
	}
	if meta.Kind != "photo" || meta.Width != 2000 || meta.TakenAt == nil {
		t.Errorf("metadata: %+v", meta)
	}

	result, err := MakeThumbnails(ctx, jpeg, meta.Kind, filepath.Join(dir, "thumbs"), "asset", nil)
	if err != nil {
		t.Fatal(err)
	}
	if result.Ratio < 1.99 || result.Ratio > 2.01 {
		t.Errorf("ratio %f, want 2", result.Ratio)
	}
	if result.Small.Size == 0 || result.Large.Size == 0 || result.Blurhash == "" {
		t.Errorf("result: %+v", result)
	}
	small, err := ReadMetadata(ctx, result.Small.Path)
	if err != nil {
		t.Fatal(err)
	}
	if small.Width != thumbSmall {
		t.Errorf("small width %d", small.Width)
	}
	large, err := ReadMetadata(ctx, result.Large.Path)
	if err != nil {
		t.Fatal(err)
	}
	if large.Width != thumbLarge {
		t.Errorf("large width %d", large.Width)
	}

	// Running again after a crash must work.
	if _, err := MakeThumbnails(ctx, jpeg, meta.Kind, filepath.Join(dir, "thumbs"), "asset", nil); err != nil {
		t.Errorf("second run: %v", err)
	}

	sidecar := filepath.Join(dir, "side", "a.xmp")
	for range 2 {
		if size, err := WriteSidecar(ctx, jpeg, sidecar); err != nil || size == 0 {
			t.Fatalf("sidecar: %d, %v", size, err)
		}
	}

	after, err := os.ReadFile(jpeg)
	if err != nil {
		t.Fatal(err)
	}
	if string(before) != string(after) {
		t.Error("the original changed")
	}
}

func TestVideoThumbnail(t *testing.T) {
	requireTools(t)
	ctx := context.Background()
	dir := t.TempDir()
	video := filepath.Join(dir, "clip.mp4")
	if out, err := exec.Command("ffmpeg", "-nostdin", "-v", "error", "-f", "lavfi", "-i", "testsrc=duration=1:size=640x360:rate=10", "-pix_fmt", "yuv420p", video).CombinedOutput(); err != nil {
		t.Fatalf("%v: %s", err, out)
	}
	meta, err := ReadMetadata(ctx, video)
	if err != nil {
		t.Fatal(err)
	}
	if meta.Kind != "video" {
		t.Errorf("kind %q", meta.Kind)
	}
	if _, err := MakeThumbnails(ctx, video, meta.Kind, filepath.Join(dir, "t"), "v", nil); err != nil {
		t.Error(err)
	}
}

func TestCorruptFileIsPermanentFailure(t *testing.T) {
	requireTools(t)
	dir := t.TempDir()
	path := filepath.Join(dir, "broken.jpg")
	if err := os.WriteFile(path, []byte{0xff, 0xd8, 0xff, 0xe0, 1, 2, 3}, 0o600); err != nil {
		t.Fatal(err)
	}
	_, err := MakeThumbnails(context.Background(), path, "photo", filepath.Join(dir, "t"), "b", nil)
	var bad *badFileError
	if !errors.As(err, &bad) {
		t.Fatalf("got %v", err)
	}
	if entries, _ := os.ReadDir(filepath.Join(dir, "t")); len(entries) != 0 {
		t.Errorf("left files behind: %v", entries)
	}
}

func TestFileNamesAreNotParsedAsOptions(t *testing.T) {
	requireTools(t)
	dir := t.TempDir()
	path := filepath.Join(dir, "holiday [1] 100%.jpg")
	if out, err := exec.Command("vips", "gaussnoise", path, "300", "200").CombinedOutput(); err != nil {
		t.Fatalf("%v: %s", err, out)
	}
	result, err := MakeThumbnails(context.Background(), path, "photo", filepath.Join(dir, "t"), "b", nil)
	if err != nil {
		t.Fatal(err)
	}
	if result.Small.Size == 0 {
		t.Error("empty thumbnail")
	}
}

func Test16BitImageStaysBright(t *testing.T) {
	requireTools(t)
	dir := t.TempDir()
	raw := filepath.Join(dir, "noise.v")
	if out, err := exec.Command("vips", "gaussnoise", raw, "300", "200", "--mean", "40000", "--sigma", "100").CombinedOutput(); err != nil {
		t.Fatalf("%v: %s", err, out)
	}
	path := filepath.Join(dir, "deep.png")
	if out, err := exec.Command("vips", "cast", raw, path, "ushort").CombinedOutput(); err != nil {
		t.Fatalf("%v: %s", err, out)
	}
	result, err := MakeThumbnails(context.Background(), path, "photo", filepath.Join(dir, "t"), "d", nil)
	if err != nil {
		t.Fatal(err)
	}
	out, err := exec.Command("vips", "avg", result.Small.Path).CombinedOutput()
	if err != nil {
		t.Fatalf("%v: %s", err, out)
	}
	average, err := strconv.ParseFloat(strings.TrimSpace(string(out)), 64)
	if err != nil {
		t.Fatal(err)
	}
	if average < 100 {
		t.Errorf("average brightness %f: a 16-bit image came out dark", average)
	}
}

func TestTruncatedImageIsReported(t *testing.T) {
	requireTools(t)
	dir := t.TempDir()
	whole := filepath.Join(dir, "whole.jpg")
	if out, err := exec.Command("vips", "gaussnoise", whole, "2000", "1500").CombinedOutput(); err != nil {
		t.Fatalf("%v: %s", err, out)
	}
	data, err := os.ReadFile(whole)
	if err != nil {
		t.Fatal(err)
	}
	cut := filepath.Join(dir, "cut.jpg")
	if err := os.WriteFile(cut, data[:len(data)/2], 0o600); err != nil {
		t.Fatal(err)
	}
	_, err = MakeThumbnails(context.Background(), cut, "photo", filepath.Join(dir, "t"), "c", nil)
	var bad *badFileError
	if !errors.As(err, &bad) {
		t.Fatalf("got %v", err)
	}
}

func TestRemoveStaleUploads(t *testing.T) {
	dir := t.TempDir()
	old := filepath.Join(dir, "old")
	fresh := filepath.Join(dir, "fresh")
	for _, path := range []string{old, fresh} {
		if err := os.WriteFile(path, nil, 0o600); err != nil {
			t.Fatal(err)
		}
	}
	past := time.Now().Add(-30 * 24 * time.Hour)
	if err := os.Chtimes(old, past, past); err != nil {
		t.Fatal(err)
	}
	if err := removeStaleUploads(dir, time.Now().Add(-7*24*time.Hour)); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(old); !errors.Is(err, os.ErrNotExist) {
		t.Error("old upload still exists")
	}
	if _, err := os.Stat(fresh); err != nil {
		t.Error("fresh upload removed")
	}
	if err := removeStaleUploads(filepath.Join(dir, "missing"), time.Now()); err != nil {
		t.Errorf("missing directory: %v", err)
	}
}

func TestWatermarkMarksACopy(t *testing.T) {
	requireTools(t)
	ctx := context.Background()
	dir := t.TempDir()
	source := filepath.Join(dir, "source.webp")
	if _, err := runTool(ctx, "vips", "black", source, "800", "600"); err != nil {
		t.Fatal(err)
	}
	before, err := os.ReadFile(source)
	if err != nil {
		t.Fatal(err)
	}
	dest := filepath.Join(dir, "cache", "marked.webp")
	// Markup in the text stays plain text, and a very long text still fits.
	if err := Watermark(ctx, source, `<b>Studio</b> & "Co" `+strings.Repeat("long ", 40), dest); err != nil {
		t.Fatal(err)
	}
	after, err := os.ReadFile(source)
	if err != nil || !bytes.Equal(before, after) {
		t.Fatalf("the source changed: %v", err)
	}
	out, err := runTool(ctx, "vips", "max", dest)
	if err != nil {
		t.Fatal(err)
	}
	if strings.TrimSpace(string(out)) == "0" {
		t.Fatal("no text was drawn on the black picture")
	}
	if width, err := imageDimension(ctx, dest, "width"); err != nil || width != 800 {
		t.Fatalf("size changed: %d, %v", width, err)
	}
}

func TestAVideoWithoutAReadablePictureSaysSo(t *testing.T) {
	if _, err := exec.LookPath("ffmpeg"); err != nil {
		t.Skip("ffmpeg is not installed")
	}
	dir := t.TempDir()
	whole := filepath.Join(dir, "whole.mp4")
	if out, err := exec.CommandContext(context.Background(), "ffmpeg", "-nostdin", "-v", "error", "-y",
		"-f", "lavfi", "-i", "testsrc=duration=1:size=320x240:rate=10",
		"-movflags", "+faststart", whole).CombinedOutput(); err != nil {
		t.Fatalf("%v: %s", err, out)
	}
	data, err := os.ReadFile(whole)
	if err != nil {
		t.Fatal(err)
	}
	// The index stays at the start and the pictures are gone, so ffmpeg finds nothing to decode.
	index := bytes.Index(data, []byte("mdat"))
	if index < 0 {
		t.Fatal("no media data in the test video")
	}
	broken := filepath.Join(dir, "broken.mov")
	if err := os.WriteFile(broken, data[:index+8], 0o600); err != nil {
		t.Fatal(err)
	}
	frame := filepath.Join(dir, "frame.jpg")
	err = extractFrame(context.Background(), broken, frame)
	var bad *badFileError
	if !errors.As(err, &bad) {
		t.Fatalf("not reported as a bad file: %v", err)
	}
	if err := extractFrame(context.Background(), whole, frame); err != nil {
		t.Fatalf("a good video: %v", err)
	}
}
