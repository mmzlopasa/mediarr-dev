package jobs

import (
	"bytes"
	"context"
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
	"time"
)

func makeVideo(t *testing.T, name string, audio bool, size string) string {
	t.Helper()
	path := filepath.Join(t.TempDir(), name)
	args := []string{"-nostdin", "-v", "error", "-f", "lavfi", "-i", "testsrc2=duration=2:rate=10:size=" + size}
	if audio {
		args = append(args, "-f", "lavfi", "-i", "sine=frequency=440:duration=2", "-c:a", "aac", "-shortest")
	}
	args = append(args, "-c:v", "libx264", "-pix_fmt", "yuv420p", path)
	if out, err := exec.Command("ffmpeg", args...).CombinedOutput(); err != nil {
		t.Fatalf("%v: %s", err, out)
	}
	return path
}

func TestHLSHeightsNeverExceedTheSource(t *testing.T) {
	tests := map[int][]int{
		2160: {360, 720, 1080},
		1080: {360, 720, 1080},
		720:  {360, 720},
		480:  {360},
		240:  {240},
		241:  {240},
	}
	for source, want := range tests {
		if got := hlsHeights(source); !reflect.DeepEqual(got, want) {
			t.Errorf("hlsHeights(%d) = %v, want %v", source, got, want)
		}
	}
}

func TestUnknownAccelFallsBackToSoftware(t *testing.T) {
	for _, accel := range []string{"", "none", "something"} {
		_, output, _ := encoderArgs(accel)
		if !strings.Contains(strings.Join(output, " "), "libx264") {
			t.Errorf("accel %q: %v", accel, output)
		}
	}
	for accel, encoder := range map[string]string{"nvenc": "h264_nvenc", "qsv": "h264_qsv", "vaapi": "h264_vaapi"} {
		_, output, _ := encoderArgs(accel)
		if !strings.Contains(strings.Join(output, " "), encoder) {
			t.Errorf("accel %q: %v", accel, output)
		}
	}
}

func TestSpriteLayout(t *testing.T) {
	short := spriteLayout(5 * time.Second)
	if short.Count != 5 || short.Columns != 5 || short.Rows != 1 || short.Interval != time.Second {
		t.Errorf("short: %+v", short)
	}
	long := spriteLayout(2 * time.Hour)
	if long.Count > spriteMaxFrames || long.Columns != spriteColumns || long.Rows*long.Columns < long.Count {
		t.Errorf("long: %+v", long)
	}
	if none := spriteLayout(0); none.Count != 1 || none.Rows != 1 {
		t.Errorf("no duration: %+v", none)
	}
}

func TestParseProbeRejectsAFileWithoutVideo(t *testing.T) {
	if _, err := parseProbe([]byte(`{"streams":[{"codec_type":"audio","codec_name":"aac"}],"format":{}}`)); err == nil {
		t.Error("accepted audio only")
	}
	if _, err := parseProbe([]byte(`not json`)); err == nil {
		t.Error("accepted garbage")
	}
}

func TestTranscodeWithAndWithoutAudio(t *testing.T) {
	requireTools(t)
	ctx := context.Background()
	for _, audio := range []bool{true, false} {
		source := makeVideo(t, "clip.mp4", audio, "1280x720")
		info, err := ProbeVideo(ctx, source)
		if err != nil {
			t.Fatal(err)
		}
		if info.HasAudio != audio || info.Height != 720 || info.Codec != "h264" || info.Duration < time.Second {
			t.Errorf("info: %+v", info)
		}
		dest := filepath.Join(t.TempDir(), "out", "asset")
		if err := Transcode(ctx, source, dest, "none", info); err != nil {
			t.Fatal(err)
		}
		master, err := os.ReadFile(filepath.Join(dest, "master.m3u8"))
		if err != nil {
			t.Fatal(err)
		}
		if !strings.Contains(string(master), "0.m3u8") || !strings.Contains(string(master), "1.m3u8") {
			t.Errorf("master: %s", master)
		}
		if strings.Contains(string(master), "1080") {
			t.Errorf("a quality above the source: %s", master)
		}
		out, err := exec.Command("ffprobe", "-v", "error", "-show_entries", "stream=codec_type,codec_name,height", "-of", "json", filepath.Join(dest, "1.m3u8")).CombinedOutput()
		if err != nil {
			t.Fatalf("%v: %s", err, out)
		}
		var probe struct {
			Streams []struct {
				CodecType string `json:"codec_type"`
				CodecName string `json:"codec_name"`
				Height    int    `json:"height"`
			} `json:"streams"`
		}
		if err := json.Unmarshal(out, &probe); err != nil {
			t.Fatal(err)
		}
		if len(probe.Streams) == 0 || probe.Streams[0].CodecName != "h264" {
			t.Errorf("stream: %s", out)
		}
		if entries, _ := os.ReadDir(filepath.Dir(dest)); len(entries) != 1 {
			t.Errorf("left temporary files: %v", entries)
		}

		sprite := filepath.Join(t.TempDir(), "sprite.jpg")
		layout, err := MakeSprite(ctx, source, sprite, info.Duration)
		if err != nil {
			t.Fatal(err)
		}
		if layout.Count < 2 {
			t.Errorf("layout: %+v", layout)
		}
		meta, err := ReadMetadata(ctx, sprite)
		if err != nil {
			t.Fatal(err)
		}
		if int(meta.Width) != layout.Columns*spriteFrameWidth {
			t.Errorf("sprite width %d for %+v", meta.Width, layout)
		}
	}
}

func TestDamagedVideoIsAPermanentFailure(t *testing.T) {
	requireTools(t)
	path := filepath.Join(t.TempDir(), "broken.mp4")
	if err := os.WriteFile(path, []byte("not a video"), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := ProbeVideo(context.Background(), path); err == nil {
		t.Error("accepted a damaged video")
	}
}

func TestExtractMotionVideo(t *testing.T) {
	dir := t.TempDir()
	photo := bytes.Repeat([]byte{0xff, 0xd8, 0x10}, 1000)
	video := append([]byte{0, 0, 0, 0x18, 'f', 't', 'y', 'p', 'i', 's', 'o', 'm'}, bytes.Repeat([]byte{7}, 500)...)
	path := filepath.Join(dir, "motion.jpg")
	if err := os.WriteFile(path, append(append([]byte{}, photo...), video...), 0o600); err != nil {
		t.Fatal(err)
	}

	for name, offset := range map[string]int64{"stated offset": int64(len(video)), "searching": 0} {
		dest := filepath.Join(t.TempDir(), "v", "m.mp4")
		found, err := ExtractMotionVideo(path, dest, offset)
		if err != nil || !found {
			t.Fatalf("%s: found %v, %v", name, found, err)
		}
		got, err := os.ReadFile(dest)
		if err != nil {
			t.Fatal(err)
		}
		if !bytes.Equal(got, video) {
			t.Errorf("%s: wrong bytes (%d)", name, len(got))
		}
	}

	// A wrong offset must not save part of the photo as a video.
	if found, err := ExtractMotionVideo(path, filepath.Join(dir, "x.mp4"), 100); err != nil || found {
		t.Errorf("wrong offset: %v, %v", found, err)
	}
	plain := filepath.Join(dir, "plain.jpg")
	if err := os.WriteFile(plain, photo, 0o600); err != nil {
		t.Fatal(err)
	}
	if found, err := ExtractMotionVideo(plain, filepath.Join(dir, "y.mp4"), 0); err != nil || found {
		t.Errorf("plain photo: %v, %v", found, err)
	}
}

func TestMetadataReadsLivePhotoAndMotionPhotoTags(t *testing.T) {
	live, err := parse(t, `{"MIMEType":"image/heic","ContentIdentifier":"ABC-1"}`)
	if err != nil || live.ContentID != "ABC-1" || live.IsMotion {
		t.Errorf("live: %+v, %v", live, err)
	}
	motion, err := parse(t, `{"MIMEType":"image/jpeg","MicroVideo":1,"MicroVideoOffset":4096}`)
	if err != nil || !motion.IsMotion || motion.MotionOffset != 4096 {
		t.Errorf("motion: %+v, %v", motion, err)
	}
}

func TestFullPreviewKeepsFullSize(t *testing.T) {
	requireTools(t)
	dir := t.TempDir()
	path := filepath.Join(dir, "big [1].jpg")
	if out, err := exec.Command("vips", "gaussnoise", path, "3000", "2000").CombinedOutput(); err != nil {
		t.Fatalf("%v: %s", err, out)
	}
	dest := filepath.Join(dir, "out", "full.webp")
	if err := MakeFullPreview(context.Background(), path, dest, nil); err != nil {
		t.Fatal(err)
	}
	meta, err := ReadMetadata(context.Background(), dest)
	if err != nil {
		t.Fatal(err)
	}
	if meta.Width != 3000 {
		t.Errorf("width %d, want 3000", meta.Width)
	}
}
