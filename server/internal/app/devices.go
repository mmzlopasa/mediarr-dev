package app

import (
	"encoding/hex"
	"encoding/json"
	"net/http"
	"strings"
	"time"

	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
)

const (
	maxReportChecksums = 5000
	maxReportFailures  = 100
	maxQuietDays       = 60
	maxDeviceCount     = 10_000_000
)

func deviceCount(value int) int32 {
	return int32(min(max(value, 0), maxDeviceCount)) //nolint:gosec // Clamped to a small range.
}

func deviceToAPI(row *db.ListBackupDevicesRow, now time.Time) api.BackupDevice {
	reported := row.ReportedAt.Time
	quiet := row.QuietDays > 0 && now.Sub(reported) > time.Duration(row.QuietDays)*24*time.Hour
	return api.BackupDevice{
		Id: openapi_types.UUID(row.ID.Bytes), Name: row.Name, Platform: row.Platform, AppVersion: row.AppVersion,
		CreatedAt: row.CreatedAt.Time, ReportedAt: reported, Quiet: quiet,
		Pending: int(row.Pending), Working: int(row.Working), Verified: int(row.Verified), Failed: int(row.Failed),
		Files: row.Files, Confirmed: row.Confirmed, Trashed: row.Trashed,
		Gone:       max(row.Files-row.Confirmed-row.Trashed, 0),
		OwnerEmail: row.OwnerEmail, OwnerName: row.OwnerName,
	}
}

func (s *apiServer) listDevices(w http.ResponseWriter, r *http.Request, user *db.User, all bool) {
	rows, err := s.queries.ListBackupDevices(r.Context(), db.ListBackupDevicesParams{AllUsers: all, UserID: user.ID})
	if err != nil {
		internalError(w, r, err)
		return
	}
	days, err := s.queries.GetBackupQuietDays(r.Context(), user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	now := time.Now()
	out := api.BackupDeviceList{Devices: make([]api.BackupDevice, 0, len(rows)), QuietDays: int(days)}
	for i := range rows {
		out.Devices = append(out.Devices, deviceToAPI(&rows[i], now))
	}
	writeJSON(w, http.StatusOK, out)
}

// ListBackupDevices shows the current user's own devices.
func (s *apiServer) ListBackupDevices(w http.ResponseWriter, r *http.Request) {
	if user := requireUser(w, r); user != nil {
		s.listDevices(w, r, user, false)
	}
}

// ListAllBackupDevices shows every user's devices, for an administrator.
func (s *apiServer) ListAllBackupDevices(w http.ResponseWriter, r *http.Request) {
	if user := requireAdmin(w, r); user != nil {
		s.listDevices(w, r, user, true)
	}
}

func (s *apiServer) SetBackupQuietDays(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	var body api.BackupQuietDays
	if !readJSON(w, r, &body) {
		return
	}
	if body.Days < 0 || body.Days > maxQuietDays {
		writeError(w, http.StatusBadRequest, "days must be between 0 and 60")
		return
	}
	err := s.queries.SetBackupQuietDays(r.Context(), db.SetBackupQuietDaysParams{
		ID: user.ID, BackupQuietDays: int32(body.Days), //nolint:gosec // Checked above.
	})
	if err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func decodeChecksums(values []string) ([][]byte, bool) {
	out := make([][]byte, 0, len(values))
	for _, value := range values {
		value = strings.ToLower(value)
		if !checksumHex.MatchString(value) {
			return nil, false
		}
		sum, err := hex.DecodeString(value)
		if err != nil {
			return nil, false
		}
		out = append(out, sum)
	}
	return out, true
}

// ReportBackupDevice takes what a phone says about its backup. Its counts are shown as the phone's;
// what is safe the server counts itself from the checksums.
func (s *apiServer) ReportBackupDevice(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	var body api.BackupDeviceReport
	if !readJSON(w, r, &body) {
		return
	}
	var checksums []string
	if body.Checksums != nil {
		checksums = *body.Checksums
	}
	if len(checksums) > maxReportChecksums {
		writeError(w, http.StatusBadRequest, "too many checksums at once")
		return
	}
	sums, ok := decodeChecksums(checksums)
	if !ok {
		writeError(w, http.StatusBadRequest, "checksums must be hex SHA-256")
		return
	}
	failures := []api.BackupDeviceFailure{}
	if body.Failures != nil {
		failures = *body.Failures
	}
	if len(failures) > maxReportFailures {
		failures = failures[:maxReportFailures]
	}
	failuresJSON, err := json.Marshal(failures)
	if err != nil {
		internalError(w, r, err)
		return
	}
	trim := func(value string, limit int) string {
		value = strings.TrimSpace(value)
		if len(value) > limit {
			return value[:limit]
		}
		return value
	}
	tx, err := s.Pool.Begin(r.Context())
	if err != nil {
		internalError(w, r, err)
		return
	}
	defer func() { _ = tx.Rollback(r.Context()) }()
	q := s.queries.WithTx(tx)
	_, err = q.ReportBackupDevice(r.Context(), db.ReportBackupDeviceParams{
		ID: pgUUID(id), UserID: user.ID,
		Name: trim(body.Name, 120), Platform: trim(body.Platform, 40), AppVersion: trim(body.AppVersion, 40),
		Pending: deviceCount(body.Pending), Working: deviceCount(body.Working),
		Verified: deviceCount(body.Verified), Failed: deviceCount(body.Failed),
		Failures: failuresJSON, KeepFailures: body.Failures == nil,
	})
	if db.IsNotFound(err) {
		// The id belongs to someone else's device.
		writeError(w, http.StatusNotFound, "device not found")
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	if body.Replace != nil && *body.Replace {
		if err := q.ClearBackupDeviceFiles(r.Context(), pgUUID(id)); err != nil {
			internalError(w, r, err)
			return
		}
	}
	if len(sums) > 0 {
		if err := q.AddBackupDeviceFiles(r.Context(), db.AddBackupDeviceFilesParams{DeviceID: pgUUID(id), Checksums: sums}); err != nil {
			internalError(w, r, err)
			return
		}
	}
	if err := tx.Commit(r.Context()); err != nil {
		internalError(w, r, err)
		return
	}
	rows, err := s.queries.ListBackupDevices(r.Context(), db.ListBackupDevicesParams{UserID: user.ID})
	if err != nil {
		internalError(w, r, err)
		return
	}
	for i := range rows {
		if rows[i].ID.Bytes == id {
			writeJSON(w, http.StatusOK, deviceToAPI(&rows[i], time.Now()))
			return
		}
	}
	writeError(w, http.StatusNotFound, "device not found")
}

func (s *apiServer) DeleteBackupDevice(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	n, err := s.queries.DeleteBackupDevice(r.Context(), db.DeleteBackupDeviceParams{ID: pgUUID(id), UserID: user.ID})
	if err != nil {
		internalError(w, r, err)
		return
	}
	if n == 0 {
		writeError(w, http.StatusNotFound, "device not found")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *apiServer) ListBackupDeviceMissing(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	device, err := s.queries.GetBackupDevice(r.Context(), db.GetBackupDeviceParams{ID: pgUUID(id), UserID: user.ID})
	if db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "device not found")
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := api.BackupDeviceMissing{Failures: []api.BackupDeviceFailure{}, Gone: []api.BackupDeviceGone{}}
	_ = json.Unmarshal(device.Failures, &out.Failures)
	if out.Failures == nil {
		out.Failures = []api.BackupDeviceFailure{}
	}
	rows, err := s.queries.MissingBackupDeviceFiles(r.Context(), pgUUID(id))
	if err != nil {
		internalError(w, r, err)
		return
	}
	for _, row := range rows {
		out.Gone = append(out.Gone, api.BackupDeviceGone{Checksum: hex.EncodeToString(row.Checksum), Name: row.Name, InTrash: row.InTrash})
	}
	writeJSON(w, http.StatusOK, out)
}
