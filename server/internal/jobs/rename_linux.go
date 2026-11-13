package jobs

import (
	"errors"

	"golang.org/x/sys/unix"
)

// renameNoReplace moves from to to, and fails with os.ErrExist instead of writing over a file that
// is already there. The kernel checks and renames in one step, so two moves at once cannot land on
// the same name. Filesystems without that (some network and FUSE mounts) fall back to a hard link.
func renameNoReplace(from, to string) error {
	err := unix.Renameat2(unix.AT_FDCWD, from, unix.AT_FDCWD, to, unix.RENAME_NOREPLACE)
	if errors.Is(err, unix.EINVAL) || errors.Is(err, unix.ENOSYS) || errors.Is(err, unix.EOPNOTSUPP) {
		return linkThenRemove(from, to)
	}
	if err != nil {
		return wrapRename(from, to, err)
	}
	return nil
}
