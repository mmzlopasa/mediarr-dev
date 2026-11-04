package jobs

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"html"
	"io"
	"math"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"time"
)

const (
	transcodeTimeout = 6 * time.Hour
	spriteFrameWidth = 160
	spriteColumns    = 10
	spriteMaxFrames  = 100
	segmentSeconds   = 4
	maxMotionScan    = 100 * 1024 * 1024
	// FullPreviewSize is the longest side of the full resolution preview.
	FullPreviewSize = 8192
)

// VideoInfo is what ffprobe reports.
type VideoInfo struct {
	Duration time.Duration
	Codec    string
	Width    int
	Height   int
	HasAudio bool
}

// ProbeVideo reads a video's properties.
func ProbeVideo(ctx context.Context, path string) (*VideoInfo, error) {
	out, err := runTool(ctx, "ffmpeg-probe", "-v", "error", "-show_entries",
		"stream=codec_type,codec_name,width,height:format=duration", "-of", "json", path)
	if err != nil {
		return nil, err
	}
	return parseProbe(out)
}

func parseProbe(out []byte) (*VideoInfo, error) {
	var parsed struct {
		Streams []struct {
			CodecType string `json:"codec_type"`
			CodecName string `json:"codec_name"`
			Width     int    `json:"width"`
			Height    int    `json:"height"`
		} `json:"streams"`
		Format struct {
			Duration string `json:"duration"`
		} `json:"format"`
	}
	if err := json.Unmarshal(out, &parsed); err != nil {
		return nil, &badFileError{msg: toolProblems["ffmpeg"]}
	}
	info := &VideoInfo{}
	for _, stream := range parsed.Streams {
		switch stream.CodecType {
		case "video":
			if info.Codec == "" {
				info.Codec, info.Width, info.Height = stream.CodecName, stream.Width, stream.Height
			}
		case "audio":
			info.HasAudio = true
		}
	}
	if info.Codec == "" {
		return nil, &badFileError{msg: toolProblems["ffmpeg"]}
	}
	if seconds, err := strconv.ParseFloat(parsed.Format.Duration, 64); err == nil && seconds > 0 {
		info.Duration = time.Duration(seconds * float64(time.Second))
	}
	return info, nil
}

// hlsHeights picks the quality levels: never above the source, and always at least one.
func hlsHeights(source int) []int {
	var out []int
	for _, height := range []int{360, 720, 1080} {
		if height <= source {
			out = append(out, height)
		}
	}
	if len(out) == 0 {
		// Even numbers only: H.264 needs them.
		return []int{max(2, source-source%2)}
	}
	return out
}

// encoderArgs chooses the H.264 encoder. Anything unknown falls back to software.
func encoderArgs(accel string) (input, output []string, filter string) {
	switch accel {
	case "nvenc":
		return nil, []string{"-c:v", "h264_nvenc", "-preset", "p4", "-cq", "26"}, ""
	case "qsv":
		return nil, []string{"-c:v", "h264_qsv", "-global_quality", "26"}, ""
	case "vaapi":
		return []string{"-vaapi_device", "/dev/dri/renderD128"}, []string{"-c:v", "h264_vaapi", "-qp", "26"}, ",format=nv12,hwupload"
	default:
		return nil, []string{"-c:v", "libx264", "-preset", "veryfast", "-crf", "26", "-pix_fmt", "yuv420p"}, ""
	}
}

func transcodeArgs(source, dir string, info *VideoInfo, accel string) []string {
	heights := hlsHeights(info.Height)
	input, output, hwFilter := encoderArgs(accel)

	var graph strings.Builder
	fmt.Fprintf(&graph, "[0:v]split=%d", len(heights))
	for i := range heights {
		fmt.Fprintf(&graph, "[s%d]", i)
	}
	for i, height := range heights {
		fmt.Fprintf(&graph, ";[s%d]scale=-2:%d%s[v%d]", i, height, hwFilter, i)
	}

	args := []string{"-n", "15", "ffmpeg", "-protocol_whitelist", "file,pipe,crypto", "-nostdin", "-v", "error", "-y"}
	args = append(args, input...)
	// -map_metadata: a shared stream carries no place, whatever the file itself says.
	args = append(args, "-i", source, "-map_metadata", "-1", "-filter_complex", graph.String())
	streams := make([]string, 0, len(heights))
	for i := range heights {
		args = append(args, "-map", fmt.Sprintf("[v%d]", i))
		if info.HasAudio {
			args = append(args, "-map", "0:a:0")
			streams = append(streams, fmt.Sprintf("v:%d,a:%d", i, i))
		} else {
			streams = append(streams, fmt.Sprintf("v:%d", i))
		}
	}
	args = append(args, output...)
	if info.HasAudio {
		args = append(args, "-c:a", "aac", "-b:a", "128k", "-ac", "2")
	}
	return append(args,
		"-f", "hls",
		"-hls_time", strconv.Itoa(segmentSeconds),
		"-hls_playlist_type", "vod",
		"-hls_segment_type", "mpegts",
		"-var_stream_map", strings.Join(streams, " "),
		"-master_pl_name", "master.m3u8",
		"-hls_segment_filename", filepath.Join(dir, "%v_%03d.ts"),
		filepath.Join(dir, "%v.m3u8"),
	)
}

// Transcode writes HLS into dest, through a temporary folder so a crash leaves nothing half done.
func Transcode(ctx context.Context, source, dest, accel string, info *VideoInfo) error {
	ctx, cancel := context.WithTimeout(ctx, transcodeTimeout)
	defer cancel()
	if err := os.MkdirAll(filepath.Dir(dest), 0o750); err != nil {
		return fmt.Errorf("create video directory: %w", err)
	}
	work, err := os.MkdirTemp(filepath.Dir(dest), ".transcode-*")
	if err != nil {
		return fmt.Errorf("create work directory: %w", err)
	}
	defer func() { _ = os.RemoveAll(work) }()

	if _, err := runToolNoLimit(ctx, "nice", transcodeArgs(source, work, info, accel)...); err != nil {
		return err
	}
	if err := os.RemoveAll(dest); err != nil {
		return err
	}
	return os.Rename(work, dest)
}

// SpriteInfo describes a scrub strip: a grid of evenly spaced frames.
type SpriteInfo struct {
	Columns, Rows, Count int
	Interval             time.Duration
}

func spriteLayout(duration time.Duration) SpriteInfo {
	seconds := max(duration.Seconds(), 1)
	interval := max(seconds/spriteMaxFrames, 1)
	count := int(math.Ceil(seconds / interval))
	columns := min(spriteColumns, count)
	return SpriteInfo{
		Columns:  columns,
		Rows:     int(math.Ceil(float64(count) / float64(columns))),
		Count:    count,
		Interval: time.Duration(interval * float64(time.Second)),
	}
}

// MakeSprite writes the scrub strip.
func MakeSprite(ctx context.Context, source, dest string, duration time.Duration) (*SpriteInfo, error) {
	layout := spriteLayout(duration)
	if err := os.MkdirAll(filepath.Dir(dest), 0o750); err != nil {
		return nil, err
	}
	tmp := dest + ".tmp.jpg"
	filter := fmt.Sprintf("fps=1/%.3f,scale=%d:-2,tile=%dx%d", layout.Interval.Seconds(), spriteFrameWidth, layout.Columns, layout.Rows)
	if _, err := runToolNoLimit(ctx, "nice", "-n", "15", "ffmpeg", "-nostdin", "-v", "error", "-y", "-i", source,
		"-vf", filter, "-frames:v", "1", "-q:v", "6", tmp); err != nil {
		_ = os.Remove(tmp)
		return nil, err
	}
	if err := os.Rename(tmp, dest); err != nil {
		return nil, err
	}
	return &layout, nil
}

var ftypBrand = regexp.MustCompile(`ftyp(isom|iso[0-9]|mp4[0-9]|mp42|avc1|qt  |hvc1|hev1)`)

// ExtractMotionVideo copies the video embedded in an Android Motion Photo. The offset counts from
// the end of the file. Newer files may not state it, so the MP4 header is searched for instead.
// It returns false when the file has no video.
func ExtractMotionVideo(original, dest string, offsetFromEnd int64) (bool, error) {
	f, err := os.Open(original)
	if err != nil {
		return false, err
	}
	defer func() { _ = f.Close() }()
	info, err := f.Stat()
	if err != nil {
		return false, err
	}

	start := int64(-1)
	if offsetFromEnd > 0 && offsetFromEnd < info.Size() {
		start = info.Size() - offsetFromEnd
	} else {
		if info.Size() > maxMotionScan {
			return false, nil
		}
		data, err := io.ReadAll(f)
		if err != nil {
			return false, err
		}
		// The header starts 4 bytes before "ftyp". Skip the start: that is the photo.
		if at := ftypBrand.FindIndex(data); at != nil && at[0] >= 4 {
			start = int64(at[0] - 4)
		}
	}
	if start < 0 {
		return false, nil
	}

	var header [12]byte
	if _, err := f.ReadAt(header[:], start); err != nil {
		if errors.Is(err, io.EOF) {
			return false, nil
		}
		return false, err
	}
	if !bytes.Equal(header[4:8], []byte("ftyp")) {
		return false, nil
	}

	if err := os.MkdirAll(filepath.Dir(dest), 0o750); err != nil {
		return false, err
	}
	tmp := dest + ".tmp"
	out, err := os.Create(tmp)
	if err != nil {
		return false, err
	}
	_, copyErr := io.Copy(out, io.NewSectionReader(f, start, info.Size()-start))
	closeErr := out.Close()
	if err := errors.Join(copyErr, closeErr); err != nil {
		_ = os.Remove(tmp)
		return false, err
	}
	return true, os.Rename(tmp, dest)
}

// MakeFullPreview writes a full resolution WebP that browsers can show: for HEIC, AVIF and RAW.
func MakeFullPreview(ctx context.Context, original, dest string, edits *Edits) error {
	if err := os.MkdirAll(filepath.Dir(dest), 0o750); err != nil {
		return err
	}
	work, err := os.MkdirTemp(filepath.Dir(dest), ".full-*")
	if err != nil {
		return err
	}
	defer func() { _ = os.RemoveAll(work) }()

	source := filepath.Join(work, "source"+strings.ToLower(filepath.Ext(original)))
	if isRaw(original) {
		// The full sensor data, unlike the previews inside the file.
		source = filepath.Join(work, "decoded.tiff")
		if _, err := runTool(ctx, "dcraw_emu", "-w", "-T", "-Z", source, original); err != nil {
			return err
		}
	} else if err := os.Symlink(original, source); err != nil {
		return err
	}

	source, err = applyEdits(ctx, source, work, edits)
	if err != nil {
		return err
	}
	tmp := filepath.Join(work, "full.webp")
	size := strconv.Itoa(FullPreviewSize)
	if _, err := runTool(ctx, "vips", "thumbnail", source, tmp+"[Q=88,strip]", size, "--height", size, "--size", "down", "--fail-on", "truncated"); err != nil {
		return err
	}
	return os.Rename(tmp, dest)
}

// Watermark writes a copy of a preview with text in its corner. The source is never changed.
func Watermark(ctx context.Context, source, text, dest string) error {
	if err := os.MkdirAll(filepath.Dir(dest), 0o750); err != nil {
		return err
	}
	work, err := os.MkdirTemp(filepath.Dir(dest), ".mark-*")
	if err != nil {
		return err
	}
	defer func() { _ = os.RemoveAll(work) }()

	width, err := imageDimension(ctx, source, "width")
	if err != nil {
		return err
	}
	height, err := imageDimension(ctx, source, "height")
	if err != nil {
		return err
	}
	const margin = 12
	// The text keeps the same share of the picture on every preview size.
	dpi := max(width*3/10, 60)
	label := filepath.Join(work, "label.png")
	// vips reads the text as markup, so what the user typed is escaped and stays plain text.
	markup := `<span foreground="white" background="#00000099"> ` + html.EscapeString(text) + ` </span>`
	if _, err := runTool(ctx, "vips", "text", label, markup, "--rgba", "--dpi", strconv.Itoa(dpi),
		"--width", strconv.Itoa(max(width-2*margin, 1)), "--font", "DejaVu Sans 8"); err != nil {
		return err
	}
	labelWidth, err := imageDimension(ctx, label, "width")
	if err != nil {
		return err
	}
	labelHeight, err := imageDimension(ctx, label, "height")
	if err != nil {
		return err
	}
	tmp := filepath.Join(work, "marked.webp")
	if _, err := runTool(ctx, "vips", "composite2", source, label, tmp+"[Q=85,strip]", "over",
		"--x", strconv.Itoa(max(width-labelWidth-margin, 0)),
		"--y", strconv.Itoa(max(height-labelHeight-margin, 0))); err != nil {
		return err
	}
	return os.Rename(tmp, dest)
}

func imageDimension(ctx context.Context, path, field string) (int, error) {
	out, err := runTool(ctx, "vipsheader", "-f", field, path)
	if err != nil {
		return 0, err
	}
	return strconv.Atoi(strings.TrimSpace(string(out)))
}
