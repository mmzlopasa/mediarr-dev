package jobs

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"path/filepath"
	"strconv"
	"strings"
)

const (
	minCropSide  = 0.02
	maxEditValue = 100
	// A rounding error of the client, not a crop outside the picture.
	cropTolerance = 0.0001
)

// CropBox is a part of the picture after rotating it, in fractions of its sides.
type CropBox struct {
	X      float64 `json:"x"`
	Y      float64 `json:"y"`
	Width  float64 `json:"width"`
	Height float64 `json:"height"`
}

// Edits is the list of changes to a photo. The original is never touched.
type Edits struct {
	Rotate     int      `json:"rotate,omitempty"`
	Crop       *CropBox `json:"crop,omitempty"`
	Brightness int      `json:"brightness,omitempty"`
	Contrast   int      `json:"contrast,omitempty"`
	Saturation int      `json:"saturation,omitempty"`
}

// IsEmpty says whether the edits leave the picture as it was.
func (e *Edits) IsEmpty() bool {
	return e == nil || *e == Edits{}
}

// Validate refuses what cannot be applied.
func (e *Edits) Validate() error {
	switch e.Rotate {
	case 0, 90, 180, 270:
	default:
		return errors.New("rotate must be 0, 90, 180 or 270")
	}
	for _, value := range []int{e.Brightness, e.Contrast, e.Saturation} {
		if value < -maxEditValue || value > maxEditValue {
			return errors.New("brightness, contrast and saturation must be between -100 and 100")
		}
	}
	if crop := e.Crop; crop != nil {
		if crop.X < 0 || crop.Y < 0 || crop.Width < minCropSide || crop.Height < minCropSide ||
			crop.X+crop.Width > 1+cropTolerance || crop.Y+crop.Height > 1+cropTolerance {
			return errors.New("the crop must be inside the picture")
		}
	}
	return nil
}

// ParseEdits reads what the database holds. Nil means no edits.
func ParseEdits(raw []byte) (*Edits, error) {
	if len(raw) == 0 {
		return nil, nil //nolint:nilnil // No edits is not an error.
	}
	var edits Edits
	if err := json.Unmarshal(raw, &edits); err != nil {
		return nil, fmt.Errorf("read edits: %w", err)
	}
	if edits.IsEmpty() {
		return nil, nil //nolint:nilnil // No edits is not an error.
	}
	return &edits, nil
}

// EditFilter turns the edits into an ffmpeg filter chain. Order matters: the crop is relative to
// the rotated picture, as the user saw it.
func EditFilter(e *Edits) string {
	parts := []string{}
	switch e.Rotate {
	case 90:
		parts = append(parts, "transpose=1")
	case 180:
		parts = append(parts, "hflip", "vflip")
	case 270:
		parts = append(parts, "transpose=2")
	}
	if c := e.Crop; c != nil {
		parts = append(parts, fmt.Sprintf("crop=trunc(iw*%.4f):trunc(ih*%.4f):trunc(iw*%.4f):trunc(ih*%.4f)", min(c.Width, 1), min(c.Height, 1), c.X, c.Y))
	}
	if e.Brightness != 0 || e.Contrast != 0 || e.Saturation != 0 {
		parts = append(parts, fmt.Sprintf("eq=brightness=%.3f:contrast=%.3f:saturation=%.3f",
			float64(e.Brightness)/(2*maxEditValue), 1+float64(e.Contrast)/maxEditValue, 1+float64(e.Saturation)/maxEditValue))
	}
	return strings.Join(parts, ",")
}

// applyEdits writes an edited copy into the work folder and returns its path. libvips first applies
// the camera's rotation and reads HEIC and the like, so ffmpeg gets what the user sees.
func applyEdits(ctx context.Context, source, work string, edits *Edits) (string, error) {
	if edits.IsEmpty() {
		return source, nil
	}
	flat := filepath.Join(work, "flat.jpg")
	size := strconv.Itoa(FullPreviewSize)
	if _, err := runTool(ctx, "vips", "thumbnail", source, flat+"[Q=98,strip]", size, "--height", size, "--size", "down", "--fail-on", "truncated"); err != nil {
		return "", err
	}
	edited := filepath.Join(work, "edited.jpg")
	if _, err := runTool(ctx, "ffmpeg", "-nostdin", "-v", "error", "-y", "-i", flat, "-vf", EditFilter(edits), "-frames:v", "1", "-update", "1", "-q:v", "2", edited); err != nil {
		return "", err
	}
	return edited, nil
}
