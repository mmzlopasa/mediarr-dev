package jobs

import (
	"context"
	"log/slog"

	"github.com/mediarr-app/mediarr/server/db"
)

// Kinds of notification. Clients write the sentence, in the language of the person reading it.
const (
	NotifyAlbumShared = "album_shared"
	// NotifyLinkOpened is a public link's first visitor; its subject is the link's label or album.
	NotifyLinkOpened   = "link_opened"
	notifyImportDone   = "import_done"
	notifyImportFailed = "import_failed"
	notifyBackupFailed = "backup_failed"
)

// NotifyBackupFailed tells the administrators, who are the ones who can fix it.
func NotifyBackupFailed(ctx context.Context, q *db.Queries, message string) error {
	return q.NotifyAdmins(ctx, db.NotifyAdminsParams{Kind: notifyBackupFailed, Subject: message})
}

// notifyImport tells the person who started the import how it ended. Not being able to say so must
// not fail the import.
func notifyImport(ctx context.Context, q *db.Queries, row *db.Import, status string) {
	kind := notifyImportDone
	if status != statusDone {
		kind = notifyImportFailed
	}
	err := q.CreateNotification(ctx, db.CreateNotificationParams{UserID: row.UserID, Kind: kind, Subject: row.Source})
	if err != nil {
		slog.Warn("a notification was not saved", "error", err)
	}
}
