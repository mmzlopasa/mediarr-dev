package jobs

import (
	"os"
)

// linkThenRemove gives the file its new name with a hard link, which fails when the name is taken,
// and then drops the old name.
func linkThenRemove(from, to string) error {
	if err := os.Link(from, to); err != nil {
		return err
	}
	if err := os.Remove(from); err != nil {
		// The original stays where it was, under one name only.
		_ = os.Remove(to)
		return err
	}
	return nil
}

func wrapRename(from, to string, err error) error {
	return &os.LinkError{Op: "rename", Old: from, New: to, Err: err}
}
