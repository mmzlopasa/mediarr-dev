package jobs

import (
	"context"
	"image"
	"image/color"
	"image/png"
	"os"
	"os/exec"
	"path/filepath"
	"testing"
)

func TestAFaceBoxIsWidenedAndStaysInThePicture(t *testing.T) {
	left, top, w, h := pixelBox([4]float32{0.4, 0.4, 0.6, 0.6}, 1000, 500)
	if left != 350 || top != 175 || w != 300 || h != 150 {
		t.Fatalf("%d %d %d %d", left, top, w, h)
	}
	left, top, w, h = pixelBox([4]float32{0.9, 0.9, 1.0, 1.0}, 100, 100)
	if left+w > 100 || top+h > 100 || left < 0 {
		t.Fatalf("%d %d %d %d", left, top, w, h)
	}
}

func TestFacesAreBlurredAndTheRestIsNot(t *testing.T) {
	if _, err := exec.LookPath("vips"); err != nil {
		t.Skip("media tools are not installed; run through `make test`")
	}
	dir := t.TempDir()
	source := filepath.Join(dir, "in.png")
	// A fine checkerboard: blurring turns it grey, so a change is easy to see.
	picture := image.NewGray(image.Rect(0, 0, 200, 200))
	for y := range 200 {
		for x := range 200 {
			if (x/2+y/2)%2 == 0 {
				picture.SetGray(x, y, color.Gray{Y: 255})
			}
		}
	}
	file, err := os.Create(source)
	if err != nil {
		t.Fatal(err)
	}
	if err := png.Encode(file, picture); err != nil {
		t.Fatal(err)
	}
	_ = file.Close()

	dest := filepath.Join(dir, "out.png")
	privacy := Privacy{Faces: [][4]float32{{0.1, 0.1, 0.3, 0.3}}, Date: true}
	if err := BlurFaces(context.Background(), source, dest, privacy); err != nil {
		t.Fatal(err)
	}
	out, err := os.Open(dest)
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = out.Close() }()
	got, err := png.Decode(out)
	if err != nil {
		t.Fatal(err)
	}
	gray := func(x, y int) uint8 { return color.GrayModel.Convert(got.At(x, y)).(color.Gray).Y }
	// Inside the face: neither black nor white any more.
	if v := gray(40, 40); v < 40 || v > 215 {
		t.Fatalf("the face was not blurred: %d", v)
	}
	// Far from it: exactly as it was.
	for _, at := range [][2]int{{150, 150}, {151, 150}, {120, 180}} {
		if gray(at[0], at[1]) != picture.GrayAt(at[0], at[1]).Y {
			t.Fatalf("%v changed", at)
		}
	}
}
