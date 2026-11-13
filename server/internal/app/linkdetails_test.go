package app

import (
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
)

func detailForLink() api.AssetDetail {
	return api.AssetDetail{
		Id:            uuid.MustParse("1a2b3c4d-0000-0000-0000-000000000000"),
		Kind:          api.AssetDetailKind("photo"),
		OriginalName:  "IMG_20240317_143012.JPG",
		LocalAt:       "2024-03-17T14:30:12",
		CreatedAt:     time.Date(2024, 3, 17, 13, 30, 12, 0, time.UTC),
		OffsetMinutes: optional(60, true),
		Camera:        optional("Pixel 8", true),
		Lens:          optional("wide", true),
		Iso:           optional(100, true),
		FNumber:       optional(1.8, true),
		ExposureTime:  optional("1/120", true),
		FocalLength:   optional(6.9, true),
	}
}

func TestALinkThatStripsTheCameraShowsNoCamera(t *testing.T) {
	detail := detailForLink()
	hideLinkDetails(&detail, &db.GetLinkByTokenRow{StripCamera: true})
	if detail.Camera != nil || detail.Lens != nil || detail.Iso != nil || detail.FNumber != nil ||
		detail.ExposureTime != nil || detail.FocalLength != nil {
		t.Errorf("camera details stayed: %+v", detail)
	}
	if detail.LocalAt != "2024-03-17T14:30:12" || detail.OffsetMinutes == nil {
		t.Errorf("the date went too: %s", detail.LocalAt)
	}
	if detail.OriginalName != "IMG_20240317_143012.JPG" {
		t.Errorf("file name %q", detail.OriginalName)
	}
}

func TestALinkThatStripsTheDateShowsOnlyTheMonth(t *testing.T) {
	detail := detailForLink()
	hideLinkDetails(&detail, &db.GetLinkByTokenRow{StripDate: true})
	if detail.LocalAt != "2024-03-01T00:00:00" || !detail.CreatedAt.Equal(time.Date(2024, 3, 1, 0, 0, 0, 0, time.UTC)) {
		t.Errorf("date %s / %s", detail.LocalAt, detail.CreatedAt)
	}
	if detail.OffsetMinutes != nil || detail.HasCaptureTime == nil || *detail.HasCaptureTime {
		t.Errorf("time zone or capture time stayed")
	}
	if detail.Camera == nil {
		t.Errorf("the camera went too")
	}
	if detail.OriginalName != "photo-1a2b3c4d.jpg" {
		t.Errorf("file name %q", detail.OriginalName)
	}
}

func TestALinkThatStripsNothingKeepsEverything(t *testing.T) {
	detail := detailForLink()
	hideLinkDetails(&detail, &db.GetLinkByTokenRow{})
	if detail.OriginalName != "IMG_20240317_143012.JPG" || detail.Camera == nil || detail.LocalAt != "2024-03-17T14:30:12" {
		t.Errorf("details changed: %+v", detail)
	}
}

func TestAVideoPlaysFromItsOriginalOnlyWithoutADownloadLimit(t *testing.T) {
	for _, tc := range []struct {
		link db.GetLinkByTokenRow
		want bool
	}{
		{db.GetLinkByTokenRow{AllowDownload: true}, true},
		{db.GetLinkByTokenRow{AllowDownload: false}, false},
		{db.GetLinkByTokenRow{AllowDownload: true, DownloadLimit: pgtype.Int4{Int32: 5, Valid: true}}, false},
	} {
		if got := playsOriginal(&tc.link); got != tc.want {
			t.Errorf("%+v: %v", tc.link, got)
		}
	}
}

func TestOnlyANameWithADateIsRenamed(t *testing.T) {
	for name, renamed := range map[string]bool{
		"IMG_20240317_143012.JPG":   true,
		"Screenshot 2024-03-17.png": true,
		"PXL_20231231_235959.mp4":   true,
		"IMG_1234.JPG":              false,
		"holiday.jpg":               false,
	} {
		detail := detailForLink()
		detail.OriginalName = name
		hideLinkDetails(&detail, &db.GetLinkByTokenRow{StripDate: true})
		if got := detail.OriginalName != name; got != renamed {
			t.Errorf("%s: became %q", name, detail.OriginalName)
		}
	}
}
