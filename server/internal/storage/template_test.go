package storage

import (
	"errors"
	"testing"
	"time"
)

func TestATemplateMustNameTheFileAndStayInside(t *testing.T) {
	for _, good := range []string{
		"", "{{y}}/{{MM}}/{{filename}}.{{ext}}", "{{album}}/{{hash}}-{{filename}}.{{ext}}",
		"{{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}.{{ext}}", "Camera {{camera}}/{{filename}}.{{ext}}",
	} {
		if err := ValidateTemplate(good); err != nil {
			t.Errorf("%q: %v", good, err)
		}
	}
	for _, bad := range []string{
		"{{y}}/{{MM}}", "/{{y}}/{{filename}}", "{{y}}/../{{filename}}", "{{y}}//{{filename}}",
		"{{year}}/{{filename}}", "{{filename}}/{{y}}", "{{y}}\\{{filename}}", "{{y}/{{filename}}",
		"a/b/c/d/e/f/g/h/{{filename}}",
	} {
		if err := ValidateTemplate(bad); !errors.Is(err, ErrTemplate) {
			t.Errorf("%q was taken: %v", bad, err)
		}
	}
}

func TestATemplateFillsSafeNames(t *testing.T) {
	when := time.Date(2024, 7, 5, 14, 30, 0, 0, time.UTC)
	fields := &TemplateFields{When: when, Name: "IMG 0042.HEIC", Camera: "iPhone 15", Album: "Hvar: ljeto/2024", Checksum: "0123456789abcdef0123"}
	for template, want := range map[string]string{
		"{{y}}/{{MM}}/{{filename}}.{{ext}}":               "2024/07/IMG 0042.heic",
		"{{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}.{{ext}}":  "2024/2024-07-05/IMG 0042.heic",
		"{{album}}/{{hh}}{{mm}}-{{filename}}.{{ext}}":     "Hvar ljeto-2024/1430-IMG 0042.heic",
		"{{camera}}/{{yy}}/{{hash}}-{{filename}}.{{ext}}": "iPhone 15/24/0123456789abcdef-IMG 0042.heic",
	} {
		if got := RenderTemplate(template, fields); got != want {
			t.Errorf("%q: %q, want %q", template, got, want)
		}
	}
	// What is not known still gives a folder, and nothing can climb out.
	empty := &TemplateFields{When: when, Name: "../../etc.jpg"}
	if got := RenderTemplate("{{camera}}/{{album}}/{{filename}}.{{ext}}", empty); got != "Unknown camera/No album/-..-etc.jpg" {
		t.Errorf("%q", got)
	}
}
