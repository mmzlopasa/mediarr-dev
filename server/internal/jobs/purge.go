package jobs

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/mediarr-app/mediarr/server/db"
)

// TrashLifetime is how long a deleted photo can still be restored, unless the administrator chose otherwise.
const TrashLifetime = 30 * 24 * time.Hour

// PurgeExpiredTrash permanently removes what has been in the trash for longer than TrashLifetime.
func PurgeExpiredTrash(ctx context.Context, q *db.Queries, cachePath string, now time.Time) error {
	settings, err := LoadServerSettings(ctx, q)
	if err != nil {
		return err
	}
	keep := time.Duration(settings.TrashDays) * 24 * time.Hour
	for {
		ids, err := q.ListExpiredTrash(ctx, pgtype.Timestamptz{Time: now.Add(-keep), Valid: true})
		if err != nil {
			return err
		}
		if len(ids) == 0 {
			return nil
		}
		if err := PurgeAssets(ctx, q, cachePath, ids); err != nil {
			return err
		}
	}
}

// PurgeAssets deletes the records first and the files after: a failure then leaves only a stray
// file, never a record pointing at nothing. Files of an external library are the user's own and
// stay where they are.
func PurgeAssets(ctx context.Context, q *db.Queries, cachePath string, ids []pgtype.UUID) error {
	rows, err := q.ListPurgeFamily(ctx, ids)
	if err != nil {
		return fmt.Errorf("find assets to delete: %w", err)
	}
	var paths []string
	family := make([]pgtype.UUID, len(rows))
	for i := range rows {
		row := &rows[i]
		family[i] = row.ID
		if row.LibraryKind != "external" {
			paths = append(paths, row.OriginalPath)
		}
		files, err := q.ListAssetFiles(ctx, row.ID)
		if err != nil {
			return fmt.Errorf("find asset files: %w", err)
		}
		for j := range files {
			paths = append(paths, files[j].Path)
		}
		copies, err := cachedCopies(cachePath, uuid.UUID(row.ID.Bytes).String())
		if err != nil {
			return err
		}
		paths = append(paths, copies...)
	}
	if err := q.DeleteAssetsByID(ctx, family); err != nil {
		return fmt.Errorf("delete assets: %w", err)
	}
	for _, path := range paths {
		if err := os.RemoveAll(path); err != nil {
			slog.Warn("remove a deleted asset's file", "path", path, "error", err)
		}
	}
	return nil
}

// cachedCopies are the copies made of one asset for others to see: the marked and stripped ones of
// each share link, and the pictures and videos made for a TV.
func cachedCopies(cachePath, id string) ([]string, error) {
	var out []string
	for _, pattern := range []string{
		filepath.Join(cachePath, "links", "*", id+"-*"),
		filepath.Join(cachePath, "links", "*", "v*", id+"-*"),
		filepath.Join(cachePath, "tv", id[:2], id+"-*"),
	} {
		found, err := filepath.Glob(pattern)
		if err != nil {
			return nil, err
		}
		out = append(out, found...)
	}
	return out, nil
}
