// Package storage manages the library and cache directories.
package storage

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"
	"unicode"
)

// MarkerName is the file that proves a directory is the expected, mounted disk.
const MarkerName = ".mediarr"

const (
	maxNameLength  = 120
	checksumPrefix = 16
)

// ErrMarkerMissing means a previously used directory no longer holds its marker.
var ErrMarkerMissing = errors.New("storage marker is missing")

// TmpDir holds uploads in progress. It must share a disk with the library for atomic renames.
func TmpDir(library string) string { return filepath.Join(library, ".tmp") }

// SidecarDir holds XMP sidecars, which are never written next to or into originals.
func SidecarDir(library string) string { return filepath.Join(library, ".sidecar") }

// Prepare checks a directory. On first use (initialized=false) it writes the marker; afterwards a
// missing marker is an error, because writing to an unmounted disk's empty mount point would
// silently put files on the wrong disk.
func Prepare(dir string, initialized bool) error {
	if !filepath.IsAbs(dir) {
		return fmt.Errorf("storage path %q must be absolute", dir)
	}
	marker := filepath.Join(dir, MarkerName)
	if _, err := os.Stat(marker); err != nil {
		if !errors.Is(err, os.ErrNotExist) {
			return fmt.Errorf("check %s: %w", marker, err)
		}
		if initialized {
			return fmt.Errorf("%w: %s is empty or not mounted; mount the disk and restart", ErrMarkerMissing, dir)
		}
		if err := os.MkdirAll(dir, 0o750); err != nil {
			return fmt.Errorf("create %s: %w", dir, err)
		}
		if err := os.WriteFile(marker, []byte("Do not delete. Mediarr uses this file to detect an unmounted disk.\n"), 0o640); err != nil {
			return fmt.Errorf("%s is not writable: %w", dir, err)
		}
	}
	return checkRename(dir)
}

// CheckMarker verifies a directory the server has already prepared.
func CheckMarker(dir string) error {
	if _, err := os.Stat(filepath.Join(dir, MarkerName)); err != nil {
		return fmt.Errorf("%w: %s", ErrMarkerMissing, dir)
	}
	return nil
}

// checkRename verifies writes and atomic renames, which some network shares do not support.
func checkRename(dir string) error {
	probe, err := os.CreateTemp(dir, ".probe-*")
	if err != nil {
		return fmt.Errorf("%s is not writable: %w", dir, err)
	}
	defer func() { _ = os.Remove(probe.Name()) }()
	if err := probe.Close(); err != nil {
		return fmt.Errorf("%s is not writable: %w", dir, err)
	}
	renamed := probe.Name() + ".renamed"
	if err := os.Rename(probe.Name(), renamed); err != nil {
		return fmt.Errorf("%s does not support atomic rename: %w", dir, err)
	}
	return os.Remove(renamed)
}

// SafeName reduces a client-supplied file name to a single safe path component.
func SafeName(name string) string {
	name = strings.ReplaceAll(name, "\\", "/")
	name = name[strings.LastIndex(name, "/")+1:]
	cleaned := strings.Map(func(r rune) rune {
		if unicode.IsControl(r) || strings.ContainsRune(`<>:"|?*`, r) {
			return -1
		}
		return r
	}, name)
	cleaned = strings.Trim(cleaned, " .")
	if cleaned == "" {
		return "file"
	}
	ext := filepath.Ext(cleaned)
	if len(ext) > 16 {
		ext = ""
	}
	stem := strings.TrimSuffix(cleaned, ext)
	if runes := []rune(stem); len(runes) > maxNameLength {
		stem = string(runes[:maxNameLength])
	}
	return stem + ext
}

// OriginalPath returns where an original is stored.
func OriginalPath(library, userID string, when time.Time, checksumHex, name string) string {
	when = when.UTC()
	return filepath.Join(library, userID, when.Format("2006"), when.Format("01"), checksumHex[:16]+"-"+SafeName(name))
}

// Publish atomically moves a finished temporary file to its final path, read-only and durable.
func Publish(tmp, dest string) error {
	if err := os.MkdirAll(filepath.Dir(dest), 0o750); err != nil {
		return fmt.Errorf("create directory: %w", err)
	}
	if err := syncFile(tmp); err != nil {
		return err
	}
	if err := os.Chmod(tmp, 0o440); err != nil {
		return fmt.Errorf("make original read-only: %w", err)
	}
	if err := os.Rename(tmp, dest); err != nil {
		return fmt.Errorf("move original: %w", err)
	}
	return syncFile(filepath.Dir(dest))
}

func syncFile(path string) error {
	f, err := os.Open(path)
	if err != nil {
		return err
	}
	defer func() { _ = f.Close() }()
	if err := f.Sync(); err != nil && !errors.Is(err, os.ErrInvalid) {
		return fmt.Errorf("sync %s: %w", path, err)
	}
	return nil
}
