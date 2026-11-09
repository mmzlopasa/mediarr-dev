package jobs

import (
	"context"
	"fmt"
	"math"
	"os"
	"path/filepath"
	"strconv"
)

// Privacy is what a copy of a picture leaves out, for someone else to see or keep.
type Privacy struct {
	// Faces are blurred: boxes in parts of the picture as it is shown, upright.
	Faces [][4]float32
	// Location, Camera and Date are taken out of the file's details.
	Location, Camera, Date bool
}

// faceMargin widens a face's box, so hair, ears and chin go with it.
const faceMargin = 0.25

// stripCameraTags are the details that tell whose camera took a picture.
var stripCameraTags = []string{
	"-Make=", "-Model=", "-LensModel=", "-LensMake=", "-Lens=", "-LensInfo=", "-LensSerialNumber=",
	"-SerialNumber=", "-BodySerialNumber=", "-InternalSerialNumber=", "-CameraSerialNumber=",
	"-OwnerName=", "-CameraOwnerName=", "-Artist=", "-Copyright=", "-XMP-dc:Creator=", "-IPTC:By-line=",
	"-Software=", "-HostComputer=", "-MakerNotes:all=", "-XMP-aux:all=", "-Keys:Make=", "-Keys:Model=",
	"-Keys:Software=", "-UserData:Make=", "-UserData:Model=",
}

var stripLocationTags = []string{
	"-gps:all=", "-xmp:gps*=", "-xmp:geotag=", "-xmp:Location*=", "-iptc:City=", "-iptc:Country*=",
	"-xmp:City=", "-xmp:Country=", "-xmp:State=", "-Keys:GPSCoordinates=", "-UserData:GPSCoordinates=",
	"-ItemList:GPSCoordinates=",
}

var stripDateTags = []string{"-time:all=", "-xmp:all:DateCreated=", "-iptc:DateCreated=", "-iptc:TimeCreated="}

// StripDetails writes a copy of a file without the details asked. The original is not touched.
func StripDetails(ctx context.Context, original, dest string, privacy Privacy) error {
	args := []string{"-q", "-m"}
	if privacy.Location {
		args = append(args, stripLocationTags...)
	}
	if privacy.Camera {
		args = append(args, stripCameraTags...)
	}
	if privacy.Date {
		args = append(args, stripDateTags...)
	}
	return intoPlace(dest, func(tmp string) error {
		if len(args) == 2 {
			data, err := os.ReadFile(original) //nolint:gosec // From the database.
			if err != nil {
				return err
			}
			return os.WriteFile(tmp, data, 0o600) //nolint:gosec // A file of our own making, next to dest.
		}
		_, err := runToolNoLimit(ctx, "exiftool", append(args, "-o", tmp, original)...)
		return err
	})
}

// intoPlace writes through a temporary file next to dest, so a half-written file is never served.
func intoPlace(dest string, write func(tmp string) error) error {
	if err := os.MkdirAll(filepath.Dir(dest), 0o750); err != nil {
		return err
	}
	work, err := os.MkdirTemp(filepath.Dir(dest), ".private-*")
	if err != nil {
		return err
	}
	defer func() { _ = os.RemoveAll(work) }()
	tmp := filepath.Join(work, "out"+filepath.Ext(dest))
	if err := write(tmp); err != nil {
		return err
	}
	return os.Rename(tmp, dest)
}

// pixelBox turns a box in parts of the picture into pixels, widened and kept inside it.
func pixelBox(box [4]float32, width, height int) (left, top, w, h int) {
	x1, y1, x2, y2 := float64(box[0]), float64(box[1]), float64(box[2]), float64(box[3])
	dx, dy := (x2-x1)*faceMargin, (y2-y1)*faceMargin
	x1, x2 = math.Max(0, x1-dx), math.Min(1, x2+dx)
	y1, y2 = math.Max(0, y1-dy), math.Min(1, y2+dy)
	left, top = int(x1*float64(width)), int(y1*float64(height))
	w, h = max(1, int(x2*float64(width))-left), max(1, int(y2*float64(height))-top)
	return left, top, min(w, width-left), min(h, height-top)
}

// BlurFaces writes a copy of a picture, upright, with every face blurred beyond recognition. The copy
// keeps no details at all, except those StripDetails then leaves in. dest's extension sets the format.
func BlurFaces(ctx context.Context, source, dest string, privacy Privacy) error {
	return intoPlace(dest, func(tmp string) error {
		work := filepath.Dir(tmp)
		base := filepath.Join(work, "base.v")
		if _, err := runTool(ctx, "vips", "autorot", source, base); err != nil {
			return err
		}
		width, err := imageDimension(ctx, base, "width")
		if err != nil {
			return err
		}
		height, err := imageDimension(ctx, base, "height")
		if err != nil {
			return err
		}
		if len(privacy.Faces) > 0 {
			blurred := filepath.Join(work, "blurred.v")
			// Strong enough that a face cannot be told apart at any size.
			sigma := strconv.FormatFloat(math.Max(8, float64(max(width, height))/40), 'f', 1, 64)
			if _, err := runTool(ctx, "vips", "gaussblur", base, blurred, sigma); err != nil {
				return err
			}
			for i, box := range privacy.Faces {
				left, top, w, h := pixelBox(box, width, height)
				if w <= 0 || h <= 0 {
					continue
				}
				patch := filepath.Join(work, fmt.Sprintf("patch-%d.v", i))
				next := filepath.Join(work, fmt.Sprintf("base-%d.v", i))
				if _, err := runTool(ctx, "vips", "extract_area", blurred, patch,
					strconv.Itoa(left), strconv.Itoa(top), strconv.Itoa(w), strconv.Itoa(h)); err != nil {
					return err
				}
				if _, err := runTool(ctx, "vips", "insert", base, patch, next, strconv.Itoa(left), strconv.Itoa(top)); err != nil {
					return err
				}
				base = next
			}
		}
		out := tmp + "[strip]"
		if ext := filepath.Ext(tmp); ext == ".jpg" || ext == ".webp" {
			out = tmp + "[Q=88,strip]"
		}
		if _, err := runTool(ctx, "vips", "copy", base, out); err != nil {
			return err
		}
		if privacy.Date {
			return nil
		}
		// Only the date may come back, when the link keeps it; nothing else does.
		_, err = runToolNoLimit(ctx, "exiftool", "-q", "-m", "-overwrite_original", "-TagsFromFile", source,
			"-DateTimeOriginal", "-CreateDate", "-OffsetTimeOriginal", tmp)
		return err
	})
}
