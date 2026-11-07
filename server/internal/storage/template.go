package storage

import (
	"errors"
	"fmt"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

// TemplateFields is what a storage template can put in a path.
type TemplateFields struct {
	// When is the local time it was taken, or when it came in when that is not known.
	When     time.Time
	Name     string
	Camera   string
	Album    string
	Checksum string
}

// TemplateTokens are the fields a template can use, with what each gives.
var TemplateTokens = []struct{ Token, Means string }{
	{"{{y}}", "year, 2024"},
	{"{{yy}}", "year, 24"},
	{"{{MM}}", "month, 07"},
	{"{{dd}}", "day, 05"},
	{"{{hh}}", "hour, 14"},
	{"{{mm}}", "minute, 30"},
	{"{{filename}}", "the name it came with, without the extension"},
	{"{{ext}}", "the extension, jpg"},
	{"{{camera}}", "the camera model"},
	{"{{album}}", "the first album it is in"},
	{"{{hash}}", "the start of its checksum, unique"},
}

const (
	maxTemplateLength   = 200
	maxTemplateSegments = 8
	noCamera            = "Unknown camera"
	noAlbum             = "No album"
)

var (
	templateToken = regexp.MustCompile(`\{\{([a-zA-Z]+)\}\}`)
	knownTokens   = map[string]bool{
		"y": true, "yy": true, "MM": true, "dd": true, "hh": true, "mm": true,
		"filename": true, "ext": true, "camera": true, "album": true, "hash": true,
	}
	// ErrTemplate is a storage template that cannot be used.
	ErrTemplate = errors.New("storage template")
)

// ValidateTemplate checks a template before it is kept. It must name the file, stay inside the
// user's folder, and use only known fields.
func ValidateTemplate(template string) error {
	template = strings.TrimSpace(template)
	switch {
	case template == "":
		return nil
	case len(template) > maxTemplateLength:
		return fmt.Errorf("%w: at most %d characters", ErrTemplate, maxTemplateLength)
	case strings.HasPrefix(template, "/") || strings.Contains(template, "\\"):
		return fmt.Errorf("%w: it is a path inside each user's folder, with / between folders", ErrTemplate)
	case !strings.Contains(template, "{{filename}}") && !strings.Contains(template, "{{hash}}"):
		return fmt.Errorf("%w: it needs {{filename}} or {{hash}}, so files keep their own names", ErrTemplate)
	}
	for _, match := range templateToken.FindAllStringSubmatch(template, -1) {
		if !knownTokens[match[1]] {
			return fmt.Errorf("%w: {{%s}} is not a field", ErrTemplate, match[1])
		}
	}
	if strings.Contains(templateToken.ReplaceAllString(template, ""), "{{") {
		return fmt.Errorf("%w: a field is written {{name}}", ErrTemplate)
	}
	segments := strings.Split(template, "/")
	if len(segments) > maxTemplateSegments {
		return fmt.Errorf("%w: at most %d folders deep", ErrTemplate, maxTemplateSegments-1)
	}
	for _, segment := range segments {
		if trimmed := strings.TrimSpace(segment); trimmed == "" || trimmed == "." || trimmed == ".." {
			return fmt.Errorf("%w: every folder needs a name", ErrTemplate)
		}
	}
	last := segments[len(segments)-1]
	if !strings.Contains(last, "{{filename}}") && !strings.Contains(last, "{{hash}}") {
		return fmt.Errorf("%w: the file's own name, {{filename}} or {{hash}}, goes in the last part", ErrTemplate)
	}
	return nil
}

// RenderTemplate gives the path of a file inside its user's folder. Each part is made safe for any
// disk, so nothing in a name can leave the folder.
func RenderTemplate(template string, f *TemplateFields) string {
	ext := strings.TrimPrefix(strings.ToLower(filepath.Ext(f.Name)), ".")
	stem := strings.TrimSuffix(f.Name, filepath.Ext(f.Name))
	camera := strings.TrimSpace(f.Camera)
	if camera == "" {
		camera = noCamera
	}
	album := strings.TrimSpace(f.Album)
	if album == "" {
		album = noAlbum
	}
	hash := f.Checksum
	if len(hash) > checksumPrefix {
		hash = hash[:checksumPrefix]
	}
	values := map[string]string{
		"y": f.When.Format("2006"), "yy": f.When.Format("06"), "MM": f.When.Format("01"),
		"dd": f.When.Format("02"), "hh": f.When.Format("15"), "mm": f.When.Format("04"),
		"filename": stem, "ext": ext, "camera": camera, "album": album, "hash": hash,
	}
	// A slash in a name is part of the name, not a folder.
	for key, value := range values {
		values[key] = strings.NewReplacer("/", "-", "\\", "-").Replace(value)
	}
	segments := strings.Split(strings.TrimSpace(template), "/")
	for i, segment := range segments {
		filled := templateToken.ReplaceAllStringFunc(segment, func(token string) string {
			return values[strings.Trim(token, "{}")]
		})
		segments[i] = safeSegment(filled)
	}
	return filepath.Join(segments...)
}

// safeSegment keeps a folder or file name to what every disk takes.
func safeSegment(name string) string {
	cleaned := SafeName(name)
	cleaned = strings.Trim(cleaned, " .")
	if cleaned == "" {
		return "_"
	}
	return cleaned
}
