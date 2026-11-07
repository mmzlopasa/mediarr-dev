package jobs

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"strings"
	"time"

	"github.com/riverqueue/river"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/mail"
)

const (
	notifyDeviceQuiet = "device_quiet"
	deviceQuietEvery  = time.Hour
	stateEmail        = "email_settings"
)

// DeviceQuietArgs looks for phones that stopped reporting on their backup.
type DeviceQuietArgs struct{}

// Kind identifies the job in the queue.
func (DeviceQuietArgs) Kind() string { return "device_quiet" }

type deviceQuietWorker struct {
	river.WorkerDefaults[DeviceQuietArgs]
	*deps
}

// Work tells each owner once per silence: the device is marked as told, and reporting again clears it.
func (w *deviceQuietWorker) Work(ctx context.Context, _ *river.Job[DeviceQuietArgs]) error {
	return TellQuietDevices(ctx, w.queries)
}

// TellQuietDevices warns the owners of devices that went quiet. The worker runs it every hour.
func TellQuietDevices(ctx context.Context, q *db.Queries) error {
	rows, err := q.QuietBackupDevices(ctx)
	if err != nil {
		return fmt.Errorf("find quiet devices: %w", err)
	}
	settings, publicURL := emailSettings(ctx, q)
	for _, row := range rows {
		name := row.Name
		if name == "" {
			name = "A device"
		}
		err := q.CreateNotification(ctx, db.CreateNotificationParams{UserID: row.UserID, Kind: notifyDeviceQuiet, Subject: name})
		if err != nil {
			return fmt.Errorf("notify: %w", err)
		}
		if err := q.MarkBackupDeviceQuietTold(ctx, row.ID); err != nil {
			return fmt.Errorf("mark told: %w", err)
		}
		if settings != nil {
			body := quietEmail(name, row.ReportedAt.Time, publicURL)
			if err := mail.Send(ctx, settings, row.Email, name+" has stopped backing up to Mediarr", body); err != nil {
				// The notification is there in any case.
				slog.Warn("a quiet device e-mail was not sent", "error", err)
			}
		}
	}
	return nil
}

func quietEmail(name string, last time.Time, publicURL string) string {
	var b strings.Builder
	fmt.Fprintf(&b, "%s last reported on its backup on %s.\n\n", name, last.UTC().Format("2 January 2006 at 15:04 UTC"))
	b.WriteString("New photos on it may not be safe on your Mediarr server yet. Open Mediarr on the device: " +
		"it reports when it starts. If backup was turned off or the app was signed out, turn it on again in Backup.\n")
	if publicURL != "" {
		fmt.Fprintf(&b, "\nYour devices: %s/account/devices\n", strings.TrimRight(publicURL, "/"))
	}
	return b.String()
}

// emailSettings reads what the administrator set for e-mail, or nil when e-mail is off.
func emailSettings(ctx context.Context, q *db.Queries) (*mail.Settings, string) {
	raw, err := q.GetState(ctx, stateEmail)
	if err != nil || raw == "" {
		return nil, ""
	}
	var stored struct {
		Enabled   bool   `json:"enabled"`
		Host      string `json:"host"`
		Port      int    `json:"port"`
		Username  string `json:"username"`
		Password  string `json:"password"`
		From      string `json:"from"`
		Security  string `json:"security"`
		PublicURL string `json:"publicUrl"`
	}
	if json.Unmarshal([]byte(raw), &stored) != nil || !stored.Enabled || stored.Host == "" {
		return nil, ""
	}
	return &mail.Settings{
		Host: stored.Host, Port: stored.Port, Username: stored.Username, Password: stored.Password,
		From: stored.From, Security: stored.Security,
	}, stored.PublicURL
}
