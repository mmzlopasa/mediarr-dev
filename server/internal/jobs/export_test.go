package jobs

import (
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgtype"

	"github.com/mediarr-app/mediarr/server/db"
)

func TestExportNamesStayApartWithoutCase(t *testing.T) {
	names := exportNames{}
	july := time.Date(2024, 7, 1, 10, 0, 0, 0, time.UTC)
	for _, row := range []struct {
		when time.Time
		name string
		want string
	}{
		{july, "IMG_1.jpg", "originals/2024/07/IMG_1.jpg"},
		{july, "img_1.JPG", "originals/2024/07/img_1 (2).JPG"},
		{july, "IMG_1.jpg", "originals/2024/07/IMG_1 (3).jpg"},
		{july.AddDate(0, 1, 0), "IMG_1.jpg", "originals/2024/08/IMG_1.jpg"},
		{july, "../../etc/passwd", "originals/2024/07/passwd"},
		// A file named like the sidecar of another keeps clear of it.
		{july, "IMG_1.jpg.xmp", "originals/2024/07/IMG_1.jpg (2).xmp"},
	} {
		if got := names.place(row.when, row.name); got != row.want {
			t.Errorf("%s: %s, want %s", row.name, got, row.want)
		}
	}
}

func TestAlbumFoldersNestAndStayApart(t *testing.T) {
	id := func(n byte) pgtype.UUID { return pgtype.UUID{Bytes: [16]byte{n}, Valid: true} }
	folders := albumFolders([]db.ExportAlbumsRow{
		{ID: id(1), Title: "Trip"},
		{ID: id(2), Title: "Day 1", ParentID: id(1)},
		{ID: id(3), Title: "trip"},
		{ID: id(4), Title: "  "},
		{ID: id(5), Title: "a/b"},
	})
	for n, want := range map[byte]string{1: "albums/Trip", 2: "albums/Trip/Day 1", 3: "albums/trip (2)", 4: "albums/Album", 5: "albums/b"} {
		if folders[id(n)] != want {
			t.Errorf("album %d: %s, want %s", n, folders[id(n)], want)
		}
	}
}
