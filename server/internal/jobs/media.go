package jobs

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"image"
	"image/png"
	"log/slog"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/bbrks/go-blurhash"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/mmzlopasa/mediarr-app/server/db"
)

const (
	thumbSmall   = 250
	thumbLarge   = 1440
	toolTimeout  = 5 * time.Minute
	maxToolError = 300
)

// badFileError means the file itself cannot be processed, so a retry would not help.
type badFileError struct{ msg string }

func (e *badFileError) Error() string { return e.msg }

// toolProblems are what a user sees. The tools' own output can hold internal paths, so it only goes to the log.
var toolProblems = map[string]string{
	"exiftool":  "the file is damaged or not a supported format",
	"vips":      "the image could not be read; it may be damaged",
	"ffmpeg":    "the video could not be read; it may be damaged",
	"dcraw_emu": "the RAW file could not be read; it may be damaged or from an unsupported camera",
}

func runTool(ctx context.Context, name string, args ...string) ([]byte, error) {
	ctx, cancel := context.WithTimeout(ctx, toolTimeout)
	defer cancel()

	var stdout, stderr bytes.Buffer
	cmd := exec.CommandContext(ctx, name, args...)
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	err := cmd.Run()
	if ctx.Err() != nil {
		return nil, fmt.Errorf("%s: %w", name, ctx.Err())
	}
	var exit *exec.ExitError
	if errors.As(err, &exit) {
		slog.Warn("media tool rejected a file", "tool", name, "output", truncate(strings.TrimSpace(stderr.String()), maxToolError))
		return stdout.Bytes(), &badFileError{msg: toolProblems[name]}
	}
	if err != nil {
		return nil, fmt.Errorf("run %s: %w", name, err)
	}
	return stdout.Bytes(), nil
}

// Metadata is what the worker keeps from exiftool's output.
type Metadata struct {
	MIMEType      string
	Kind          string
	Width         int32
	Height        int32
	TakenAt       *time.Time
	OffsetMinutes *int32
	Make          string
	Model         string
	Lens          string
	ISO           int32
	FNumber       float64
	ExposureTime  string
	FocalLength   float64
	Latitude      *float64
	Longitude     *float64
	Raw           []byte
}

// ReadMetadata runs exiftool on a file.
func ReadMetadata(ctx context.Context, path string) (*Metadata, error) {
	out, err := runTool(ctx, "exiftool", "-json", "-n", "-api", "LargeFileSupport=1", path)
	if err != nil {
		return nil, err
	}
	var rows []map[string]any
	if err := json.Unmarshal(out, &rows); err != nil || len(rows) != 1 {
		return nil, &badFileError{msg: "exiftool returned no metadata"}
	}
	return parseMetadata(rows[0])
}

func parseMetadata(row map[string]any) (*Metadata, error) {
	raw, err := json.Marshal(row)
	if err != nil {
		return nil, err
	}
	// Control characters such as NUL are not valid in Postgres jsonb, and metadata can hold anything.
	raw = bytes.ReplaceAll(raw, []byte(`\u0000`), nil)

	meta := &Metadata{
		MIMEType:     text(row, "MIMEType"),
		Make:         text(row, "Make"),
		Model:        text(row, "Model"),
		Lens:         firstText(row, "LensModel", "Lens", "LensInfo"),
		ExposureTime: text(row, "ExposureTime"),
		ISO:          int32(number(row, "ISO")),
		FNumber:      number(row, "FNumber"),
		FocalLength:  number(row, "FocalLength"),
		Width:        int32(firstNumber(row, "ImageWidth", "ExifImageWidth")),
		Height:       int32(firstNumber(row, "ImageHeight", "ExifImageHeight")),
		Raw:          raw,
	}
	if text(row, "Error") != "" {
		return nil, &badFileError{msg: toolProblems["exiftool"]}
	}
	switch {
	case strings.HasPrefix(meta.MIMEType, "image/"):
		meta.Kind = "photo"
	case strings.HasPrefix(meta.MIMEType, "video/"):
		meta.Kind = "video"
	default:
		return nil, &badFileError{msg: fmt.Sprintf("unsupported file type %q", meta.MIMEType)}
	}
	// Orientations 5 to 8 swap the sides on display.
	if orientation := int(number(row, "Orientation")); orientation >= 5 && orientation <= 8 {
		meta.Width, meta.Height = meta.Height, meta.Width
	}
	if meta.Kind == "video" {
		rotation := int(number(row, "Rotation"))
		if rotation == 90 || rotation == 270 {
			meta.Width, meta.Height = meta.Height, meta.Width
		}
	}
	meta.TakenAt, meta.OffsetMinutes = takenAt(row, meta.Kind)

	if lat, lon, ok := gps(row); ok {
		meta.Latitude, meta.Longitude = &lat, &lon
	}
	return meta, nil
}

// takenAt returns the capture time as a UTC instant plus the original UTC offset.
func takenAt(row map[string]any, kind string) (*time.Time, *int32) {
	offset, hasOffset := parseOffset(firstText(row, "OffsetTimeOriginal", "OffsetTime", "OffsetTimeDigitized"))

	for _, key := range []string{"SubSecDateTimeOriginal", "DateTimeOriginal", "CreationDate", "CreateDate", "MediaCreateDate"} {
		value := text(row, key)
		if value == "" || strings.HasPrefix(value, "0000") {
			continue
		}
		if parsed, zoneMinutes, ok := parseExifTime(value); ok {
			if zoneMinutes != nil {
				return &parsed, zoneMinutes
			}
			// QuickTime dates without a zone are UTC by specification.
			if kind == "video" && (key == "CreateDate" || key == "MediaCreateDate") {
				return &parsed, nil
			}
			if hasOffset {
				utc := parsed.Add(-time.Duration(offset) * time.Minute)
				return &utc, &offset
			}
			// No zone at all: keep local wall time as if it were UTC, so the day does not shift.
			return &parsed, nil
		}
	}
	return nil, nil
}

func parseExifTime(value string) (time.Time, *int32, bool) {
	for _, layout := range []string{"2006:01:02 15:04:05.999999999Z07:00", "2006:01:02 15:04:05Z07:00"} {
		if parsed, err := time.Parse(layout, value); err == nil {
			_, seconds := parsed.Zone()
			minutes := int32(seconds / 60) //nolint:gosec // Time zone offsets are small.
			utc := parsed.UTC()
			return utc, &minutes, true
		}
	}
	for _, layout := range []string{"2006:01:02 15:04:05.999999999", "2006:01:02 15:04:05"} {
		if parsed, err := time.Parse(layout, value); err == nil {
			return parsed, nil, true
		}
	}
	return time.Time{}, nil, false
}

func parseOffset(value string) (int32, bool) {
	if value == "" {
		return 0, false
	}
	parsed, err := time.Parse("-07:00", value)
	if err != nil {
		return 0, false
	}
	_, seconds := parsed.Zone()
	return int32(seconds / 60), true //nolint:gosec // Time zone offsets are small.
}

func gps(row map[string]any) (lat, lon float64, ok bool) {
	lat, latOK := row["GPSLatitude"].(float64)
	lon, lonOK := row["GPSLongitude"].(float64)
	if !latOK || !lonOK || lat < -90 || lat > 90 || lon < -180 || lon > 180 {
		return 0, 0, false
	}
	return lat, lon, true
}

func text(row map[string]any, key string) string {
	switch value := row[key].(type) {
	case string:
		return strings.ToValidUTF8(strings.ReplaceAll(value, "\x00", ""), "")
	case float64:
		return strconv.FormatFloat(value, 'f', -1, 64)
	default:
		return ""
	}
}

func firstText(row map[string]any, keys ...string) string {
	for _, key := range keys {
		if value := text(row, key); value != "" {
			return value
		}
	}
	return ""
}

func number(row map[string]any, key string) float64 {
	value, _ := row[key].(float64)
	return value
}

func firstNumber(row map[string]any, keys ...string) float64 {
	for _, key := range keys {
		if value := number(row, key); value != 0 {
			return value
		}
	}
	return 0
}

func pgText(s string) pgtype.Text { return pgtype.Text{String: s, Valid: s != ""} }

func (m *Metadata) assetParams(id pgtype.UUID) db.UpdateAssetMetadataParams {
	params := db.UpdateAssetMetadataParams{
		ID:       id,
		MimeType: pgText(m.MIMEType),
		Kind:     m.Kind,
		Width:    pgtype.Int4{Int32: m.Width, Valid: m.Width > 0},
		Height:   pgtype.Int4{Int32: m.Height, Valid: m.Height > 0},
	}
	if m.TakenAt != nil {
		params.TakenAt = pgtype.Timestamptz{Time: *m.TakenAt, Valid: true}
	}
	if m.OffsetMinutes != nil {
		params.TakenOffsetMinutes = pgtype.Int4{Int32: *m.OffsetMinutes, Valid: true}
	}
	return params
}

func (m *Metadata) exifParams(id pgtype.UUID) db.UpsertExifParams {
	params := db.UpsertExifParams{
		AssetID:      id,
		Make:         pgText(m.Make),
		Model:        pgText(m.Model),
		Lens:         pgText(m.Lens),
		Iso:          pgtype.Int4{Int32: m.ISO, Valid: m.ISO > 0},
		FNumber:      pgtype.Float8{Float64: m.FNumber, Valid: m.FNumber > 0},
		ExposureTime: pgText(m.ExposureTime),
		FocalLength:  pgtype.Float8{Float64: m.FocalLength, Valid: m.FocalLength > 0},
		Raw:          m.Raw,
	}
	if m.Latitude != nil {
		params.Latitude = pgtype.Float8{Float64: *m.Latitude, Valid: true}
		params.Longitude = pgtype.Float8{Float64: *m.Longitude, Valid: true}
	}
	return params
}

// ThumbFile is one generated thumbnail.
type ThumbFile struct {
	Path string
	Size int64
}

// ThumbResult holds everything MakeThumbnails produced.
type ThumbResult struct {
	Small    ThumbFile
	Large    ThumbFile
	Blurhash string
}

// MakeThumbnails generates both thumbnails and the blurhash. It can safely run again after a crash.
func MakeThumbnails(ctx context.Context, original, kind, dir, name string) (*ThumbResult, error) {
	if err := os.MkdirAll(dir, 0o750); err != nil {
		return nil, fmt.Errorf("create thumbnail directory: %w", err)
	}
	work, err := os.MkdirTemp(dir, ".work-*")
	if err != nil {
		return nil, fmt.Errorf("create work directory: %w", err)
	}
	defer func() { _ = os.RemoveAll(work) }()

	source, err := thumbnailSource(ctx, original, kind, work)
	if err != nil {
		return nil, err
	}
	small, err := makeThumb(ctx, source, work, dir, name, thumbSmall)
	if err != nil {
		return nil, err
	}
	large, err := makeThumb(ctx, source, work, dir, name, thumbLarge)
	if err != nil {
		return nil, err
	}
	hash, err := makeBlurhash(ctx, small.Path, work)
	if err != nil {
		return nil, err
	}
	return &ThumbResult{Small: small, Large: large, Blurhash: hash}, nil
}

// thumbnailSource returns a file libvips can read: the original, a video frame or a RAW preview.
func thumbnailSource(ctx context.Context, original, kind, work string) (string, error) {
	if kind == "video" {
		frame := filepath.Join(work, "frame.jpg")
		if _, err := runTool(ctx, "ffmpeg", "-nostdin", "-v", "error", "-y", "-i", original, "-frames:v", "1", "-q:v", "2", frame); err != nil {
			return "", err
		}
		return frame, nil
	}
	if !isRaw(original) {
		// A fixed link name, because libvips reads "[...]" in a file name as load options.
		link := filepath.Join(work, "source"+strings.ToLower(filepath.Ext(original)))
		if err := os.Symlink(original, link); err != nil {
			return "", fmt.Errorf("link original: %w", err)
		}
		return link, nil
	}
	for _, tag := range []string{"-JpgFromRaw", "-PreviewImage", "-OtherImage"} {
		preview, err := runTool(ctx, "exiftool", "-b", tag, original)
		if err != nil {
			return "", err
		}
		if len(preview) > 0 {
			path := filepath.Join(work, "preview.jpg")
			if err := os.WriteFile(path, preview, 0o600); err != nil {
				return "", err
			}
			return path, nil
		}
	}
	// No embedded preview, as in some DNG files: decode the sensor data at half size.
	decoded := filepath.Join(work, "decoded.tiff")
	if _, err := runTool(ctx, "dcraw_emu", "-w", "-h", "-T", "-Z", decoded, original); err != nil {
		return "", err
	}
	return decoded, nil
}

func isRaw(path string) bool {
	switch strings.ToLower(filepath.Ext(path)) {
	case ".arw", ".cr2", ".cr3", ".dng", ".nef", ".orf", ".raf", ".rw2", ".pef", ".srw":
		return true
	}
	return false
}

func makeThumb(ctx context.Context, source, work, dir, name string, size int) (ThumbFile, error) {
	file := fmt.Sprintf("%s-%d.webp", name, size)
	tmp := filepath.Join(work, file)
	// "down" never enlarges, and "truncated" reports damaged files as errors instead of half-empty
	// thumbnails. libvips also applies EXIF rotation and picks the first page or frame.
	if _, err := runTool(ctx, "vips", "thumbnail", source, tmp+"[Q=82,strip]", strconv.Itoa(size),
		"--height", strconv.Itoa(size), "--size", "down", "--fail-on", "truncated"); err != nil {
		return ThumbFile{}, err
	}
	dest := filepath.Join(dir, file)
	if err := os.Rename(tmp, dest); err != nil {
		return ThumbFile{}, fmt.Errorf("store thumbnail: %w", err)
	}
	info, err := os.Stat(dest)
	if err != nil {
		return ThumbFile{}, err
	}
	return ThumbFile{Path: dest, Size: info.Size()}, nil
}

func makeBlurhash(ctx context.Context, thumb, work string) (string, error) {
	tiny := filepath.Join(work, "tiny.png")
	if _, err := runTool(ctx, "vips", "thumbnail", thumb, tiny, "32", "--height", "32"); err != nil {
		return "", err
	}
	f, err := os.Open(tiny)
	if err != nil {
		return "", err
	}
	defer func() { _ = f.Close() }()
	var img image.Image
	if img, err = png.Decode(f); err != nil {
		return "", fmt.Errorf("decode blurhash source: %w", err)
	}
	return blurhash.Encode(4, 3, img)
}

// WriteSidecar exports a file's metadata to an XMP file next to nothing but other sidecars.
func WriteSidecar(ctx context.Context, original, path string) (int64, error) {
	if err := os.MkdirAll(filepath.Dir(path), 0o750); err != nil {
		return 0, fmt.Errorf("create sidecar directory: %w", err)
	}
	tmp := path + ".tmp.xmp"
	_ = os.Remove(tmp) // exiftool refuses to overwrite what an interrupted run left behind.
	if _, err := runTool(ctx, "exiftool", "-q", "-q", "-api", "LargeFileSupport=1", "-o", tmp, original); err != nil {
		_ = os.Remove(tmp)
		return 0, err
	}
	if err := os.Rename(tmp, path); err != nil {
		return 0, fmt.Errorf("store sidecar: %w", err)
	}
	info, err := os.Stat(path)
	if err != nil {
		return 0, err
	}
	return info.Size(), nil
}
