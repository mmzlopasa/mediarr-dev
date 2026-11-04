package jobs

import (
	"context"
	"os"
	"path/filepath"
	"testing"
)

func TestEditFilterKeepsTheOrder(t *testing.T) {
	got := EditFilter(&Edits{Rotate: 90, Crop: &CropBox{X: 0.25, Y: 0, Width: 0.5, Height: 1}, Brightness: 20})
	want := "transpose=1,crop=trunc(iw*0.5000):trunc(ih*1.0000):trunc(iw*0.2500):trunc(ih*0.0000),eq=brightness=0.100:contrast=1.000:saturation=1.000"
	if got != want {
		t.Fatalf("%s", got)
	}
}

func TestEditsAreValidated(t *testing.T) {
	for name, edits := range map[string]Edits{
		"angle":      {Rotate: 45},
		"brightness": {Brightness: 101},
		"outside":    {Crop: &CropBox{X: 0.6, Width: 0.6, Height: 1}},
		"negative":   {Crop: &CropBox{X: -0.1, Width: 0.5, Height: 1}},
		"tiny":       {Crop: &CropBox{Width: 0.001, Height: 1}},
	} {
		if err := edits.Validate(); err == nil {
			t.Errorf("%s was accepted", name)
		}
	}
	good := Edits{Rotate: 270, Crop: &CropBox{X: 0.5, Y: 0.5, Width: 0.5, Height: 0.5}, Saturation: -100}
	if err := good.Validate(); err != nil {
		t.Error(err)
	}
}

func TestEditedPreviewsLeaveTheOriginalAlone(t *testing.T) {
	dir := t.TempDir()
	ctx := context.Background()
	original := filepath.Join(dir, "a.jpg")
	if _, err := runTool(ctx, "ffmpeg", "-nostdin", "-v", "error", "-y", "-f", "lavfi", "-i", "testsrc2=size=800x400:rate=1", "-frames:v", "1", "-update", "1", original); err != nil {
		t.Fatal(err)
	}
	before, err := os.ReadFile(original)
	if err != nil {
		t.Fatal(err)
	}

	plain, err := MakeThumbnails(ctx, original, "photo", filepath.Join(dir, "plain"), "a", nil)
	if err != nil {
		t.Fatal(err)
	}
	if plain.Ratio < 1.9 {
		t.Fatalf("plain ratio %f", plain.Ratio)
	}
	turned, err := MakeThumbnails(ctx, original, "photo", filepath.Join(dir, "turned"), "a", &Edits{Rotate: 90})
	if err != nil {
		t.Fatal(err)
	}
	if turned.Ratio > 0.6 {
		t.Fatalf("rotated ratio %f", turned.Ratio)
	}
	// Half of the width of the rotated picture, which is 400 wide and 800 high.
	cropped, err := MakeThumbnails(ctx, original, "photo", filepath.Join(dir, "cropped"), "a", &Edits{
		Rotate: 90, Crop: &CropBox{X: 0.5, Y: 0, Width: 0.5, Height: 1}, Contrast: 10,
	})
	if err != nil {
		t.Fatal(err)
	}
	if cropped.Ratio > 0.3 {
		t.Fatalf("cropped ratio %f", cropped.Ratio)
	}

	full := filepath.Join(dir, "full.webp")
	if err := MakeFullPreview(ctx, original, full, &Edits{Rotate: 90}); err != nil {
		t.Fatal(err)
	}
	info, err := ReadMetadata(ctx, full)
	if err != nil {
		t.Fatal(err)
	}
	if info.Width > info.Height {
		t.Fatalf("the full preview did not turn: %dx%d", info.Width, info.Height)
	}

	after, err := os.ReadFile(original)
	if err != nil {
		t.Fatal(err)
	}
	if string(before) != string(after) {
		t.Fatal("the original changed")
	}
}

func TestAFilterChangesThePreviewAndOnlyThat(t *testing.T) {
	dir := t.TempDir()
	ctx := context.Background()
	original := filepath.Join(dir, "a.jpg")
	if _, err := runTool(ctx, "ffmpeg", "-nostdin", "-v", "error", "-y", "-f", "lavfi", "-i", "testsrc2=size=320x240:rate=1", "-frames:v", "1", "-update", "1", original); err != nil {
		t.Fatal(err)
	}
	mono, err := MakeThumbnails(ctx, original, "photo", filepath.Join(dir, "mono"), "a", &Edits{Filter: "mono"})
	if err != nil {
		t.Fatal(err)
	}
	out, err := runTool(ctx, "ffmpeg", "-nostdin", "-v", "error", "-i", mono.Large.Path, "-vf", "format=rgb24", "-frames:v", "1", "-f", "rawvideo", "-")
	if err != nil {
		t.Fatal(err)
	}
	for i := 0; i+2 < len(out); i += 3 {
		r, g, b := int(out[i]), int(out[i+1]), int(out[i+2])
		if max(r, g, b)-min(r, g, b) > 12 {
			t.Fatalf("colour is left at %d: %d %d %d", i, r, g, b)
		}
	}
	if err := (&Edits{Filter: "nonsense"}).Validate(); err == nil {
		t.Error("an unknown filter was accepted")
	}
}

func TestEveryLookKeepsColoursInRange(t *testing.T) {
	for _, name := range EditFilters {
		for _, value := range []float64{0, 0.5, 1} {
			r, g, b := filterColor(name, value, 1-value, value)
			for _, channel := range []float64{r, g, b} {
				if channel < 0 || channel > 1 {
					t.Errorf("%s: %f", name, channel)
				}
			}
		}
	}
}
