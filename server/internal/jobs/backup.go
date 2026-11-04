package jobs

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/riverqueue/river"
	"github.com/riverqueue/river/rivertype"

	"github.com/mediarr-app/mediarr/server/db"
)

const (
	backupTimeout     = 24 * time.Hour
	backupTickEvery   = 30 * time.Minute
	backupMinInterval = 20 * time.Hour
	backupKindRun     = "backup"
	backupKindTest    = "restore_test"
	backupDumpName    = "mediarr-database.dump"
	maxToolMessage    = 500
	minRestoreFree    = 1 << 30
)

// The names of the backup's settings, and of each feature's switch.
const (
	StateBackupRepository = "backup_repository"
	StateBackupPassword   = "backup_password" //nolint:gosec // The name of a setting.
	StateBackupS3Key      = "backup_s3_key"
	StateBackupS3Secret   = "backup_s3_secret" //nolint:gosec // The name of a setting.
	StateBackupHour       = "backup_hour"
	StateFeaturePrefix    = "feature_"
	FeatureBackup         = "backup"
)

// BackupSettings says where a backup goes.
type BackupSettings struct {
	Repository, Password, S3Key, S3Secret string
}

// ValidRepository allows what needs nothing but restic. Other kinds, such as sftp, can run a command
// named in their options.
func ValidRepository(repository, localRoot string) error {
	switch {
	case strings.HasPrefix(repository, "s3:"), strings.HasPrefix(repository, "b2:"), strings.HasPrefix(repository, "rest:"):
		return nil
	case filepath.IsAbs(repository) && localRoot != "":
		clean := filepath.Clean(repository)
		if clean == localRoot || strings.HasPrefix(clean, strings.TrimSuffix(localRoot, "/")+"/") {
			return nil
		}
		return fmt.Errorf("a local backup must be inside %s", localRoot)
	}
	return errors.New("a backup goes to a folder, or an s3, b2 or rest address")
}

// restic runs it with the secrets in its environment, where no process list or log shows them.
func restic(ctx context.Context, settings *BackupSettings, args ...string) ([]byte, error) {
	if _, err := exec.LookPath("restic"); err != nil {
		return nil, errors.New("restic is not installed in this image")
	}
	cmd := exec.CommandContext(ctx, "restic", args...)
	cmd.Env = append(os.Environ(),
		"RESTIC_REPOSITORY="+settings.Repository, "RESTIC_PASSWORD="+settings.Password,
		"AWS_ACCESS_KEY_ID="+settings.S3Key, "AWS_SECRET_ACCESS_KEY="+settings.S3Secret,
		"B2_ACCOUNT_ID="+settings.S3Key, "B2_ACCOUNT_KEY="+settings.S3Secret,
		"RESTIC_CACHE_DIR="+filepath.Join(os.TempDir(), "restic-cache"))
	var stdout, stderr bytes.Buffer
	cmd.Stdout, cmd.Stderr = &stdout, &stderr
	if err := cmd.Run(); err != nil {
		return stdout.Bytes(), fmt.Errorf("restic %s: %s", args[0], truncate(strings.TrimSpace(stderr.String()), maxToolMessage))
	}
	return stdout.Bytes(), nil
}

func ensureRepository(ctx context.Context, settings *BackupSettings) error {
	// Init first, because asking an S3 bucket for a config it does not have yet is retried for minutes.
	_, err := restic(ctx, settings, "init")
	if err != nil && strings.Contains(err.Error(), "already") {
		return nil
	}
	return err
}

// dumpDatabase uses the plain tools, so that a backup can be read without Mediarr.
func dumpDatabase(ctx context.Context, databaseURL, dest string) error {
	if err := os.MkdirAll(filepath.Dir(dest), 0o750); err != nil {
		return err
	}
	out, err := exec.CommandContext(ctx, "pg_dump", "--format=custom", "--file="+dest, "--dbname="+databaseURL).CombinedOutput()
	if err != nil {
		return fmt.Errorf("pg_dump: %s", truncate(strings.TrimSpace(string(out)), maxToolMessage))
	}
	return nil
}

// RunBackup sends the originals and the database. Previews are left out: they can be made again.
func RunBackup(ctx context.Context, settings *BackupSettings, databaseURL, libraryPath, cachePath string) (int64, error) {
	if err := ensureRepository(ctx, settings); err != nil {
		return 0, err
	}
	dump := filepath.Join(cachePath, "backup", backupDumpName)
	defer func() { _ = os.Remove(dump) }()
	if err := dumpDatabase(ctx, databaseURL, dump); err != nil {
		return 0, err
	}
	out, err := restic(ctx, settings, "backup", "--json", "--tag", "mediarr", "--exclude", filepath.Join(libraryPath, ".tmp"), libraryPath, dump)
	if err != nil {
		return 0, err
	}
	var files int64
	for line := range bytes.SplitSeq(out, []byte("\n")) {
		var summary struct {
			Type       string `json:"message_type"`
			TotalFiles int64  `json:"total_files_processed"`
		}
		if json.Unmarshal(line, &summary) == nil && summary.Type == "summary" {
			files = summary.TotalFiles
		}
	}
	if _, err := restic(ctx, settings, "forget", "--tag", "mediarr", "--keep-daily", "7", "--keep-weekly", "4", "--keep-monthly", "12", "--prune"); err != nil {
		return files, err
	}
	return files, nil
}

func restoreDatabase(ctx context.Context, databaseURL, dump string) error {
	out, err := exec.CommandContext(ctx, "pg_restore", "--clean", "--if-exists", "--no-owner", "--dbname="+databaseURL, dump).CombinedOutput()
	if err != nil {
		return fmt.Errorf("pg_restore: %s", truncate(strings.TrimSpace(string(out)), maxToolMessage))
	}
	return nil
}

func withDatabaseName(databaseURL, name string) (string, error) {
	parsed, err := url.Parse(databaseURL)
	if err != nil {
		return "", errors.New("the database address cannot be read")
	}
	parsed.Path = "/" + name
	return parsed.String(), nil
}

// roomForRestore makes sure a whole copy fits, because the test really brings everything back.
func roomForRestore(ctx context.Context, settings *BackupSettings, cachePath string) error {
	out, err := restic(ctx, settings, "stats", "latest", "--json", "--tag", "mediarr", "--mode", "restore-size")
	if err != nil {
		return err
	}
	var stats struct {
		TotalSize int64 `json:"total_size"`
	}
	if err := json.Unmarshal(out, &stats); err != nil {
		return err
	}
	var disk syscall.Statfs_t
	if err := syscall.Statfs(cachePath, &disk); err != nil {
		return err
	}
	if free := int64(disk.Bavail) * disk.Bsize; free < stats.TotalSize+minRestoreFree { //nolint:gosec // Disk sizes fit.
		return fmt.Errorf("the test needs %d MB free on the cache disk, and there are %d", (stats.TotalSize+minRestoreFree)>>20, free>>20)
	}
	return nil
}

// TestRestore brings the newest backup back beside the live data, in a folder and a database of its
// own, and compares every original with the checksum the restored database has for it.
func TestRestore(ctx context.Context, settings *BackupSettings, databaseURL, cachePath string) (int64, error) {
	// A run that was killed leaves its copy behind, which would soon fill the disk.
	if old, err := filepath.Glob(filepath.Join(cachePath, ".restore-test-*")); err == nil {
		for _, dir := range old {
			_ = os.RemoveAll(dir)
		}
	}
	if err := roomForRestore(ctx, settings, cachePath); err != nil {
		return 0, err
	}
	work, err := os.MkdirTemp(cachePath, ".restore-test-*")
	if err != nil {
		return 0, err
	}
	defer func() { _ = os.RemoveAll(work) }()
	if _, err := restic(ctx, settings, "restore", "latest", "--tag", "mediarr", "--target", work); err != nil {
		return 0, err
	}
	var dump string
	err = filepath.WalkDir(work, func(path string, entry os.DirEntry, walkErr error) error {
		if walkErr == nil && !entry.IsDir() && entry.Name() == backupDumpName {
			dump = path
		}
		return walkErr
	})
	if err != nil {
		return 0, err
	}
	if dump == "" {
		return 0, errors.New("the backup holds no database")
	}
	name := "mediarr_restore_test_" + strings.ReplaceAll(uuid.NewString(), "-", "")
	admin, err := pgx.Connect(ctx, databaseURL)
	if err != nil {
		return 0, err
	}
	defer func() { _ = admin.Close(context.WithoutCancel(ctx)) }()
	if _, err := admin.Exec(ctx, "CREATE DATABASE "+name); err != nil {
		return 0, fmt.Errorf("create a database to test with: %w", err)
	}
	defer func() { _, _ = admin.Exec(context.WithoutCancel(ctx), "DROP DATABASE "+name+" WITH (FORCE)") }()
	target, err := withDatabaseName(databaseURL, name)
	if err != nil {
		return 0, err
	}
	if err := restoreDatabase(ctx, target, dump); err != nil {
		return 0, err
	}
	restored, err := pgx.Connect(ctx, target)
	if err != nil {
		return 0, err
	}
	defer func() { _ = restored.Close(context.WithoutCancel(ctx)) }()
	rows, err := db.New(restored).ListUploadOriginals(ctx)
	if err != nil {
		return 0, err
	}
	var checked int64
	for i := range rows {
		sum, err := hashFile(filepath.Join(work, rows[i].OriginalPath))
		if err != nil {
			return checked, fmt.Errorf("the backup lacks a file: %s", filepath.Base(rows[i].OriginalPath))
		}
		if !bytes.Equal(sum, rows[i].Checksum) {
			return checked, fmt.Errorf("a file in the backup is damaged: %s", filepath.Base(rows[i].OriginalPath))
		}
		checked++
	}
	return checked, nil
}

// RestoreBackup puts a backup back on an empty installation, in the paths it came from.
func RestoreBackup(ctx context.Context, settings *BackupSettings, databaseURL, cachePath string) error {
	work, err := os.MkdirTemp(cachePath, ".restore-*")
	if err != nil {
		return err
	}
	defer func() { _ = os.RemoveAll(work) }()
	if _, err := restic(ctx, settings, "restore", "latest", "--tag", "mediarr", "--target", "/", "--exclude", backupDumpName); err != nil {
		return err
	}
	if _, err := restic(ctx, settings, "restore", "latest", "--tag", "mediarr", "--target", work, "--include", "**/"+backupDumpName); err != nil {
		return err
	}
	var dump string
	err = filepath.WalkDir(work, func(path string, entry os.DirEntry, walkErr error) error {
		if walkErr == nil && !entry.IsDir() && entry.Name() == backupDumpName {
			dump = path
		}
		return walkErr
	})
	if err != nil {
		return err
	}
	if dump == "" {
		return errors.New("the backup holds no database")
	}
	return restoreDatabase(ctx, databaseURL, dump)
}

// BackupArgs runs a backup or a test of bringing one back.
type BackupArgs struct {
	What string    `json:"what"`
	Run  uuid.UUID `json:"run"`
}

// Kind identifies the job in the queue.
func (BackupArgs) Kind() string { return "backup" }

// InsertOpts shares the queue of long jobs, so that an import and a backup do not fight over the disk.
func (BackupArgs) InsertOpts() river.InsertOpts { return river.InsertOpts{Queue: importQueue} }

type backupWorker struct {
	river.WorkerDefaults[BackupArgs]
	*deps
}

func (w *backupWorker) Timeout(*river.Job[BackupArgs]) time.Duration { return backupTimeout }

// LoadBackupSettings reads them, empty if they were not set.
func LoadBackupSettings(ctx context.Context, q *db.Queries) (*BackupSettings, error) {
	out := &BackupSettings{}
	for key, target := range map[string]*string{
		StateBackupRepository: &out.Repository, StateBackupPassword: &out.Password,
		StateBackupS3Key: &out.S3Key, StateBackupS3Secret: &out.S3Secret,
	} {
		value, err := q.GetState(ctx, key)
		if err != nil && !db.IsNotFound(err) {
			return nil, err
		}
		*target = value
	}
	return out, nil
}

func (w *backupWorker) Work(ctx context.Context, job *river.Job[BackupArgs]) error {
	id := toPG(job.Args.Run)
	settings, err := LoadBackupSettings(ctx, w.queries)
	if err != nil {
		return err
	}
	var files int64
	switch {
	case settings.Repository == "" || settings.Password == "":
		err = errors.New("the backup has no destination or password")
	case job.Args.What == backupKindTest:
		files, err = TestRestore(ctx, settings, w.opts.DatabaseURL, w.opts.CachePath)
	default:
		files, err = RunBackup(ctx, settings, w.opts.DatabaseURL, w.opts.LibraryPath, w.opts.CachePath)
	}
	status, message := statusDone, ""
	if err != nil {
		status, message = statusFailed, truncate(err.Error(), maxToolMessage)
	}
	finishErr := w.queries.FinishBackupRun(context.WithoutCancel(ctx), db.FinishBackupRunParams{ID: id, Status: status, Message: message, Files: files})
	if finishErr != nil {
		return finishErr
	}
	w.emitWebhook(ctx, EventBackupFinished, map[string]string{"kind": job.Args.What, "status": status})
	// A failure is written down for the administrator. Trying again by itself would not fix a full
	// disk or a wrong password, and the next scheduled run tries anyway.
	return nil
}

// BackupTickArgs checks whether the scheduled backup is due.
type BackupTickArgs struct{}

// Kind identifies the job in the queue.
func (BackupTickArgs) Kind() string { return "backup_tick" }

// InsertOpts keeps one at a time.
func (BackupTickArgs) InsertOpts() river.InsertOpts {
	return river.InsertOpts{UniqueOpts: river.UniqueOpts{ByArgs: true, ByState: []rivertype.JobState{
		rivertype.JobStateAvailable, rivertype.JobStatePending, rivertype.JobStateRetryable,
		rivertype.JobStateRunning, rivertype.JobStateScheduled,
	}}}
}

type backupTickWorker struct {
	river.WorkerDefaults[BackupTickArgs]
	*deps
}

// BackupDue decides from the settings: once a day, at the chosen hour.
func BackupDue(now, last time.Time, hour int) bool {
	return now.Hour() == hour && now.Sub(last) >= backupMinInterval
}

func (w *backupTickWorker) Work(ctx context.Context, _ *river.Job[BackupTickArgs]) error {
	on, err := w.queries.GetState(ctx, StateFeaturePrefix+FeatureBackup)
	if db.IsNotFound(err) || on != "1" {
		return nil
	}
	if err != nil {
		return err
	}
	settings, err := LoadBackupSettings(ctx, w.queries)
	if err != nil {
		return err
	}
	if settings.Repository == "" || settings.Password == "" {
		return nil
	}
	hour := 3
	if value, err := w.queries.GetState(ctx, StateBackupHour); err == nil {
		if parsed, err := strconv.Atoi(value); err == nil {
			hour = parsed
		}
	}
	last, err := w.queries.LastSuccessfulBackup(ctx)
	if err != nil {
		return err
	}
	if !BackupDue(time.Now(), last.Time, hour) {
		return nil
	}
	return pgx.BeginFunc(ctx, w.pool, func(tx pgx.Tx) error {
		run, err := w.queries.WithTx(tx).CreateBackupRun(ctx, backupKindRun)
		if err != nil {
			return err
		}
		_, err = w.client().InsertTx(ctx, tx, BackupArgs{What: backupKindRun, Run: uuid.UUID(run.Bytes)}, nil)
		return err
	})
}
