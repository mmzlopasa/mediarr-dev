package jobs

import "testing"

func TestAFileWithANumberAddedIsAlreadyInPlace(t *testing.T) {
	for path, want := range map[string]bool{
		"/l/u/2024/a.jpg":      true,
		"/l/u/2024/a-1.jpg":    true,
		"/l/u/2024/a-12.jpg":   true,
		"/l/u/2024/a-x.jpg":    false,
		"/l/u/2024/a-.jpg":     false,
		"/l/u/2024/ab.jpg":     false,
		"/l/u/2023/a-1.jpg":    false,
		"/l/u/2024/a-1.jpg.gz": false,
	} {
		if got := placedAs(path, "/l/u/2024/a.jpg"); got != want {
			t.Errorf("%s: %v", path, got)
		}
	}
}
