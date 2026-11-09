package jobs

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/mediarr-app/mediarr/server/db"
)

const (
	maxRating  = 5
	maxCaption = 2000
)

// The marks of a photo while going through a shoot.
const (
	// PickRejected is a photo turned down.
	PickRejected = -1
	// PickPicked is a photo chosen to keep.
	PickPicked = 1
)

// sidecarBeside finds an XMP file that another program left next to an original, as photo.jpg.xmp
// or photo.xmp. A link is not followed, as an original is not, because anyone who can write to an
// external folder could point it anywhere.
func sidecarBeside(original string) string {
	base := strings.TrimSuffix(original, filepath.Ext(original))
	for _, candidate := range []string{original + ".xmp", original + ".XMP", base + ".xmp", base + ".XMP"} {
		if info, err := os.Lstat(candidate); err == nil && info.Mode().IsRegular() {
			return candidate
		}
	}
	return ""
}

// overlaySidecar puts what a sidecar says over what the file says. Editors write their changes to the
// sidecar and leave the file as it was, so the sidecar is newer.
func (m *Metadata) overlaySidecar(row map[string]any) {
	if when, offset := takenAt(row, "photo"); when != nil {
		m.TakenAt, m.OffsetMinutes = when, offset
	}
	if lat, lon, ok := gps(row); ok {
		m.Latitude, m.Longitude = &lat, &lon
	}
	if _, rated := row["Rating"]; rated {
		m.Rating = clampRating(number(row, "Rating"))
	}
	if caption := text(row, "Description"); caption != "" {
		m.Caption = caption
	}
}

func clampRating(value float64) int16 {
	return int16(min(max(value, 0), maxRating))
}

func readSidecarBeside(ctx context.Context, original string, meta *Metadata) error {
	path := sidecarBeside(original)
	if path == "" {
		return nil
	}
	out, err := runTool(ctx, "exiftool", "-json", "-n", path)
	if err != nil {
		// A damaged sidecar must not stop the photo from being read.
		return nil //nolint:nilerr // See above.
	}
	var rows []map[string]any
	if err := json.Unmarshal(out, &rows); err != nil || len(rows) != 1 {
		return nil //nolint:nilerr // See above.
	}
	meta.overlaySidecar(rows[0])
	return nil
}

// SidecarFacts is what Mediarr knows about a photo beyond its file.
type SidecarFacts struct {
	Rating    int16
	Pick      int16
	Caption   string
	TakenAt   *time.Time
	Offset    *int32
	Latitude  *float64
	Longitude *float64
	People    []string
	Tags      []string
}

// LoadSidecarFacts reads them from the database.
func LoadSidecarFacts(ctx context.Context, q *db.Queries, asset *db.Asset) (*SidecarFacts, error) {
	facts := &SidecarFacts{Rating: asset.Rating, Pick: asset.Pick, Caption: asset.Caption}
	if asset.ManualTakenAt.Valid {
		when := asset.ManualTakenAt.Time
		facts.TakenAt = &when
		if asset.ManualOffsetMinutes.Valid {
			offset := asset.ManualOffsetMinutes.Int32
			facts.Offset = &offset
		}
	}
	if asset.ManualLatitude.Valid && asset.ManualLongitude.Valid {
		lat, lon := asset.ManualLatitude.Float64, asset.ManualLongitude.Float64
		facts.Latitude, facts.Longitude = &lat, &lon
	}
	people, err := q.ListAssetPeople(ctx, asset.ID)
	if err != nil {
		return nil, err
	}
	for i := range people {
		facts.People = append(facts.People, people[i].Name)
	}
	if facts.Tags, err = q.ListAssetTags(ctx, asset.ID); err != nil {
		return nil, err
	}
	return facts, nil
}

// exiftoolArguments writes the facts, so that another program reads what was decided in Mediarr.
func (f *SidecarFacts) exiftoolArguments() []string {
	args := []string{"-XMP-xmp:Rating=" + strconv.Itoa(int(f.Rating))}
	// Without a mark nothing is said, so that a label the file itself has stays as it is.
	switch f.Pick {
	case PickPicked:
		args = append(args, "-XMP-xmp:Label=Pick")
	case PickRejected:
		args = append(args, "-XMP-xmp:Label=Reject")
	}
	if f.Caption != "" {
		args = append(args, "-XMP-dc:Description="+f.Caption)
	}
	if f.TakenAt != nil {
		zone := time.UTC
		if f.Offset != nil {
			zone = time.FixedZone("", int(*f.Offset)*60)
		}
		args = append(args, "-XMP-exif:DateTimeOriginal="+f.TakenAt.In(zone).Format("2006:01:02 15:04:05-07:00"))
	}
	if f.Latitude != nil && f.Longitude != nil {
		args = append(args,
			"-XMP-exif:GPSLatitude="+strconv.FormatFloat(*f.Latitude, 'f', -1, 64),
			"-XMP-exif:GPSLongitude="+strconv.FormatFloat(*f.Longitude, 'f', -1, 64))
	}
	for _, person := range f.People {
		args = append(args, "-XMP-iptcExt:PersonInImage="+person)
	}
	for _, tag := range f.Tags {
		args = append(args, "-XMP-dc:Subject="+tag)
	}
	return args
}

// WriteSidecarWithFacts exports what the file says and adds what Mediarr knows. Nothing is written
// next to or into the original.
func WriteSidecarWithFacts(ctx context.Context, original, path string, facts *SidecarFacts) (int64, error) {
	_, err := WriteSidecar(ctx, original, path)
	var bad *badFileError
	switch {
	case errors.As(err, &bad):
		// What the file says cannot be read, and what Mediarr knows is still worth having.
		tmp := path + ".tmp.xmp"
		_ = os.Remove(tmp)
		args := append([]string{"-q", "-q", "-m", "-o", tmp}, facts.exiftoolArguments()...)
		if _, err := runTool(ctx, "exiftool", args...); err != nil {
			_ = os.Remove(tmp)
			return 0, fmt.Errorf("write the sidecar: %w", err)
		}
		if err := os.Rename(tmp, path); err != nil {
			return 0, fmt.Errorf("store sidecar: %w", err)
		}
	case err != nil:
		return 0, err
	default:
		args := append([]string{"-q", "-q", "-m", "-overwrite_original"}, facts.exiftoolArguments()...)
		if _, err := runTool(ctx, "exiftool", append(args, path)...); err != nil {
			return 0, fmt.Errorf("add facts to the sidecar: %w", err)
		}
	}
	info, err := os.Stat(path)
	if err != nil {
		return 0, err
	}
	return info.Size(), nil
}
