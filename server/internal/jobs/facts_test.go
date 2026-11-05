package jobs

import (
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgtype"

	"github.com/mediarr-app/mediarr/server/db"
)

func TestWhatTheOwnerSaidWinsOverTheFile(t *testing.T) {
	file := time.Date(2020, 1, 1, 0, 0, 0, 0, time.UTC)
	lat, lon := 1.0, 2.0
	offset := int32(60)
	said := time.Date(2001, 2, 3, 4, 5, 6, 0, time.UTC)
	meta := Metadata{TakenAt: &file, OffsetMinutes: &offset, Latitude: &lat, Longitude: &lon}
	meta.fillFromManual(&db.Asset{
		ManualTakenAt:       pgtype.Timestamptz{Time: said, Valid: true},
		ManualOffsetMinutes: pgtype.Int4{Int32: 120, Valid: true},
		ManualLatitude:      pgtype.Float8{Float64: 45, Valid: true},
		ManualLongitude:     pgtype.Float8{Float64: 16, Valid: true},
	})
	if !meta.TakenAt.Equal(said) || *meta.OffsetMinutes != 120 || *meta.Latitude != 45 || *meta.Longitude != 16 {
		t.Fatalf("got %+v", meta)
	}

	untouched := Metadata{TakenAt: &file, Latitude: &lat, Longitude: &lon}
	untouched.fillFromManual(&db.Asset{})
	if !untouched.TakenAt.Equal(file) || *untouched.Latitude != 1 {
		t.Fatalf("nothing said, but changed: %+v", untouched)
	}
}
