package jobs

import (
	"context"
	"encoding/json"
	"sync/atomic"

	"github.com/mediarr-app/mediarr/server/db"
)

// StateServerSettings holds what the administrator chose. What is not chosen takes its default.
const StateServerSettings = "server_settings"

// ServerSettings are read by both the server and the worker.
type ServerSettings struct {
	TrashDays      int    `json:"trashDays"`
	ImageQuality   int    `json:"imageQuality"`
	PreviewSize    int    `json:"previewSize"`
	VideoQuality   int    `json:"videoQuality"`
	VideoMaxHeight int    `json:"videoMaxHeight"`
	LoginMessage   string `json:"loginMessage"`
	PasswordLogin  bool   `json:"passwordLogin"`
}

// DefaultServerSettings are what a new installation uses.
func DefaultServerSettings() ServerSettings {
	return ServerSettings{
		TrashDays: 30, ImageQuality: 82, PreviewSize: thumbLarge, VideoQuality: 26,
		VideoMaxHeight: 1080, PasswordLogin: true,
	}
}

// LoadServerSettings reads them, or the defaults if nothing was saved.
func LoadServerSettings(ctx context.Context, q *db.Queries) (ServerSettings, error) {
	out := DefaultServerSettings()
	raw, err := q.GetState(ctx, StateServerSettings)
	if db.IsNotFound(err) {
		return out, nil
	}
	if err != nil {
		return out, err
	}
	if err := json.Unmarshal([]byte(raw), &out); err != nil {
		return DefaultServerSettings(), nil //nolint:nilerr // Unreadable choices are the same as none.
	}
	return out, nil
}

var mediaSettings atomic.Pointer[ServerSettings]

func currentMedia() ServerSettings {
	if settings := mediaSettings.Load(); settings != nil {
		return *settings
	}
	return DefaultServerSettings()
}

// refreshMedia is called before media work, so that a change applies to the next file.
func refreshMedia(ctx context.Context, q *db.Queries) {
	if settings, err := LoadServerSettings(ctx, q); err == nil {
		mediaSettings.Store(&settings)
	}
}
