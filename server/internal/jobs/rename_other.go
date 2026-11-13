//go:build !linux

package jobs

// renameNoReplace moves from to to, and fails with os.ErrExist instead of writing over a file that
// is already there.
func renameNoReplace(from, to string) error {
	return linkThenRemove(from, to)
}
