package jobs

import (
	"archive/zip"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path"
	"path/filepath"
	"slices"
	"strings"
	"time"
)

// exportTree is an export from Google or Apple, as an unpacked folder or as the ZIP files it was
// downloaded in. Paths are slash-separated and relative to its top.
type exportTree interface {
	// media lists the photos and videos, sorted so that a resumed import goes the same way.
	media() []string
	// all lists every file, for the CSV files of iCloud.
	all() []string
	// names lists what is in a folder, as Google's sidecars are found by their names.
	names(dir string) []string
	// open gives a file with its size and the time it was last changed.
	open(name string) (io.ReadCloser, int64, time.Time, error)
	// small reads a sidecar or a list, and refuses anything larger than one.
	small(name string) ([]byte, error)
	close() error
}

var errNotSmall = errors.New("not a sidecar")

// --- An unpacked folder, read through the external library's read-only mount ---

type folderTree struct {
	root  string
	files []string
}

func newFolderTree(root string) (*folderTree, error) {
	if _, err := os.ReadDir(root); err != nil {
		return nil, &errImportRefused{"this folder cannot be read"}
	}
	tree := &folderTree{root: root}
	err := filepath.WalkDir(root, func(full string, entry fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			return nil //nolint:nilerr // What cannot be read is left out, as in a scan.
		}
		if entry.Type().IsRegular() {
			rel, err := filepath.Rel(root, full)
			if err == nil {
				tree.files = append(tree.files, filepath.ToSlash(rel))
			}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	slices.Sort(tree.files)
	return tree, nil
}

func (t *folderTree) all() []string { return t.files }

func (t *folderTree) media() []string {
	out := []string{}
	for _, name := range t.files {
		if isExternalMedia(name) {
			out = append(out, name)
		}
	}
	return out
}

func (t *folderTree) full(name string) string {
	return filepath.Join(t.root, filepath.FromSlash(path.Clean("/"+name)))
}

func (t *folderTree) names(dir string) []string {
	entries, err := os.ReadDir(t.full(dir))
	if err != nil {
		return nil
	}
	out := make([]string, 0, len(entries))
	for _, entry := range entries {
		out = append(out, entry.Name())
	}
	return out
}

func (t *folderTree) open(name string) (io.ReadCloser, int64, time.Time, error) {
	full := t.full(name)
	info, err := os.Lstat(full)
	if err != nil {
		return nil, 0, time.Time{}, err
	}
	if !info.Mode().IsRegular() {
		return nil, 0, time.Time{}, errors.New("not a regular file")
	}
	file, err := os.Open(full) //nolint:gosec // Within the chosen folder.
	if err != nil {
		return nil, 0, time.Time{}, err
	}
	return file, info.Size(), info.ModTime(), nil
}

func (t *folderTree) small(name string) ([]byte, error) { return readSmallFile(t.full(name)) }

func (t *folderTree) close() error { return nil }

// --- The ZIP files an export was downloaded in, read without unpacking them ---

// zipTree joins the parts of an export into one tree. Google splits an export across files at any
// point, so a photo's sidecar can be in another part than the photo.
type zipTree struct {
	parts   []*zip.ReadCloser
	entries map[string]*zip.File
	dirs    map[string][]string
	files   []string
}

// cleanEntryName makes a name from inside a ZIP file safe to use as a key. Nothing is ever written
// to disk under it, but a name that climbs out or is absolute is left out all the same.
func cleanEntryName(name string) (string, bool) {
	name = strings.ReplaceAll(name, "\\", "/")
	if name == "" || strings.HasPrefix(name, "/") {
		return "", false
	}
	for _, part := range strings.Split(name, "/") {
		if part == ".." {
			return "", false
		}
	}
	clean := strings.TrimPrefix(path.Clean("/"+name), "/")
	return clean, clean != "" && clean != "."
}

func newZipTree(paths []string) (*zipTree, error) {
	tree := &zipTree{entries: map[string]*zip.File{}, dirs: map[string][]string{}}
	for _, part := range paths {
		reader, err := zip.OpenReader(part)
		if err != nil {
			_ = tree.close()
			return nil, &errImportRefused{fmt.Sprintf("%s is not a ZIP file that can be read", filepath.Base(part))}
		}
		tree.parts = append(tree.parts, reader)
		for _, file := range reader.File {
			// Only plain files: links, folders and anything else are left out.
			if !file.Mode().IsRegular() {
				continue
			}
			name, ok := cleanEntryName(file.Name)
			if !ok {
				continue
			}
			if _, seen := tree.entries[name]; seen {
				continue
			}
			tree.entries[name] = file
			dir, base := path.Split(name)
			dir = strings.TrimSuffix(dir, "/")
			tree.dirs[dir] = append(tree.dirs[dir], base)
			tree.files = append(tree.files, name)
		}
	}
	slices.Sort(tree.files)
	return tree, nil
}

func (t *zipTree) all() []string { return t.files }

func (t *zipTree) media() []string {
	out := []string{}
	for _, name := range t.files {
		if isExternalMedia(name) {
			out = append(out, name)
		}
	}
	return out
}

func (t *zipTree) names(dir string) []string {
	return t.dirs[strings.Trim(dir, "/")]
}

func (t *zipTree) open(name string) (io.ReadCloser, int64, time.Time, error) {
	file, ok := t.entries[name]
	if !ok {
		return nil, 0, time.Time{}, fs.ErrNotExist
	}
	reader, err := file.Open()
	if err != nil {
		return nil, 0, time.Time{}, err
	}
	// The reader stops with an error at the size the ZIP file gives, so a file cannot unpack into
	// more than it said it would.
	return reader, int64(file.UncompressedSize64), file.Modified, nil //nolint:gosec // Sizes fit.
}

func (t *zipTree) small(name string) ([]byte, error) {
	file, ok := t.entries[name]
	if !ok {
		return nil, fs.ErrNotExist
	}
	if file.UncompressedSize64 > maxSidecarBytes {
		return nil, errNotSmall
	}
	reader, err := file.Open()
	if err != nil {
		return nil, err
	}
	defer func() { _ = reader.Close() }()
	return io.ReadAll(io.LimitReader(reader, maxSidecarBytes+1))
}

func (t *zipTree) close() error {
	var first error
	for _, part := range t.parts {
		if err := part.Close(); err != nil && first == nil {
			first = err
		}
	}
	return first
}
