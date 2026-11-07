// Package upgrade keeps a snapshot of the database before a new version changes it, and brings
// the database back to one with a single command.
package upgrade

import (
	"bufio"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/storage"
)

const (
	// DirName is the folder in the library that holds the snapshots. Backups leave it out.
	DirName = ".mediarr-snapshots"
	// Keep is how many snapshots stay; older ones are removed after a new one is made.
	Keep          = 3
	stateVersion  = "app_version"
	stateRollback = "rolled_back"
	// SkipEnv turns snapshots off, for whoever has their own way back.
	SkipEnv     = "MEDIARR_UPGRADE_SNAPSHOT"
	roomFactor  = 2
	maxToolText = 2000
)

var (
	// ErrNoRoom stops an upgrade when the snapshot would not fit.
	ErrNoRoom = errors.New("not enough room for a snapshot of the database before the upgrade")
	// ErrRolledBack stops the version the database was brought back from.
	ErrRolledBack = errors.New("the database was brought back from this version")
	// ErrNoSnapshot is a rollback with nothing to go back to.
	ErrNoSnapshot = errors.New("no snapshot to go back to")
	validName     = regexp.MustCompile(`^schema-\d+-to-\d+-\d{8}T\d{6}Z$`)
)

// Snapshot is the database as it was before one upgrade.
type Snapshot struct {
	Name        string    `json:"name"`
	FromVersion string    `json:"fromVersion"`
	ToVersion   string    `json:"toVersion"`
	FromSchema  int64     `json:"fromSchema"`
	ToSchema    int64     `json:"toSchema"`
	CreatedAt   time.Time `json:"createdAt"`
	SizeBytes   int64     `json:"sizeBytes"`
}

type rollback struct {
	// From is the version that was left; To is the one to run instead.
	From string `json:"from"`
	To   string `json:"to"`
}

// FreeSpace measures the room left where a snapshot goes. Tests replace it.
var FreeSpace = func(dir string) (int64, error) {
	var disk syscall.Statfs_t
	if err := syscall.Statfs(dir, &disk); err != nil {
		return 0, err
	}
	return int64(disk.Bavail) * disk.Bsize, nil //nolint:gosec // Disk sizes fit.
}

// Dir is where the snapshots of a library are.
func Dir(library string) string { return filepath.Join(library, DirName) }

func dumpPath(library, name string) string { return filepath.Join(Dir(library), name+".dump") }

// ValidName says whether a name is one of ours, so nothing outside the folder is touched.
func ValidName(name string) bool { return validName.MatchString(name) }

// List gives the snapshots, newest first. A snapshot whose dump is missing is not listed.
func List(library string) ([]Snapshot, error) {
	entries, err := os.ReadDir(Dir(library))
	if errors.Is(err, os.ErrNotExist) {
		return []Snapshot{}, nil
	}
	if err != nil {
		return nil, fmt.Errorf("read snapshots: %w", err)
	}
	out := []Snapshot{}
	for _, entry := range entries {
		name, ok := strings.CutSuffix(entry.Name(), ".json")
		if !ok || !ValidName(name) {
			continue
		}
		data, err := os.ReadFile(filepath.Join(Dir(library), entry.Name()))
		if err != nil {
			continue
		}
		var snap Snapshot
		if json.Unmarshal(data, &snap) != nil || snap.Name != name {
			continue
		}
		if _, err := os.Stat(dumpPath(library, name)); err != nil {
			continue
		}
		out = append(out, snap)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].CreatedAt.After(out[j].CreatedAt) })
	return out, nil
}

// Delete removes one snapshot.
func Delete(library, name string) error {
	if !ValidName(name) {
		return os.ErrNotExist
	}
	if _, err := os.Stat(dumpPath(library, name)); err != nil {
		return err
	}
	if err := os.Remove(dumpPath(library, name)); err != nil {
		return err
	}
	return os.Remove(filepath.Join(Dir(library), name+".json"))
}

func connect(ctx context.Context, databaseURL string) (*pgx.Conn, error) {
	conn, err := pgx.Connect(ctx, databaseURL)
	if err != nil {
		return nil, fmt.Errorf("open database: %w", err)
	}
	return conn, nil
}

// state reads a value from system_state, which a database too old or too new may not have.
func state(ctx context.Context, conn *pgx.Conn, key string) string {
	var value string
	err := conn.QueryRow(ctx, `SELECT value FROM system_state WHERE key = $1`, key).Scan(&value)
	if err != nil {
		return ""
	}
	return value
}

func setState(ctx context.Context, conn *pgx.Conn, key, value string) error {
	_, err := conn.Exec(ctx, `INSERT INTO system_state (key, value) VALUES ($1, $2)
		ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value`, key, value)
	return err
}

// Prepare runs before migrations. When this version has migrations the database does not, it
// makes a snapshot first. It refuses when there is no room for one, and when the database was
// brought back from this very version, unless force is set (`mediarr migrate`).
func Prepare(ctx context.Context, databaseURL, library, appVersion string, force bool) error {
	current, latest, err := db.SchemaVersions(ctx, databaseURL)
	if err != nil {
		return err
	}
	// A new installation has nothing to lose.
	if current == 0 || current >= latest {
		return nil
	}
	conn, err := connect(ctx, databaseURL)
	if err != nil {
		return err
	}
	defer func() { _ = conn.Close(ctx) }()

	if raw := state(ctx, conn, stateRollback); raw != "" && !force {
		var back rollback
		if json.Unmarshal([]byte(raw), &back) == nil && back.From != "" && back.From == appVersion {
			to := back.To
			if to == "" {
				to = "the version before"
			}
			return fmt.Errorf("%w (%s). Set MEDIARR_VERSION=%s in .env and run `docker compose up -d`, "+
				"or run `docker compose run --rm server migrate` to try %s again", ErrRolledBack, appVersion, to, appVersion)
		}
	}
	if strings.EqualFold(os.Getenv(SkipEnv), "false") {
		slog.Warn("no snapshot of the database before the upgrade, as " + SkipEnv + "=false")
		return nil
	}

	// Written to the library only while its disk is there, never to an empty mount point.
	if err := storage.CheckMarker(library); err != nil {
		return err
	}
	var size int64
	if err := conn.QueryRow(ctx, `SELECT pg_database_size(current_database())`).Scan(&size); err != nil {
		return fmt.Errorf("measure the database: %w", err)
	}
	if err := os.MkdirAll(Dir(library), 0o750); err != nil {
		return fmt.Errorf("create %s: %w", Dir(library), err)
	}
	free, err := FreeSpace(Dir(library))
	if err != nil {
		return fmt.Errorf("measure free space: %w", err)
	}
	if free < roomFactor*size {
		return fmt.Errorf("%w: it needs about %d MB in %s and %d MB are free. Free some space and start again, "+
			"or set %s=false in .env to upgrade without one", ErrNoRoom, roomFactor*size>>20, Dir(library), free>>20, SkipEnv)
	}

	now := time.Now().UTC()
	snap := Snapshot{
		Name:        fmt.Sprintf("schema-%d-to-%d-%s", current, latest, now.Format("20060102T150405Z")),
		FromVersion: state(ctx, conn, stateVersion), ToVersion: appVersion,
		FromSchema: current, ToSchema: latest, CreatedAt: now,
	}
	slog.Info("a snapshot of the database is made before the upgrade", "from", current, "to", latest)
	final := dumpPath(library, snap.Name)
	partial := final + ".partial"
	out, err := exec.CommandContext(ctx, "pg_dump", "--format=custom", "--file="+partial, "--dbname="+databaseURL).CombinedOutput()
	if err != nil {
		_ = os.Remove(partial)
		return fmt.Errorf("snapshot before the upgrade: pg_dump: %s", clip(string(out)))
	}
	info, err := os.Stat(partial)
	if err != nil {
		return err
	}
	snap.SizeBytes = info.Size()
	// The description is written first: a dump without one is not listed, and one only renamed
	// once it is whole is never half there.
	data, err := json.MarshalIndent(snap, "", "  ")
	if err != nil {
		return err
	}
	if err := os.WriteFile(filepath.Join(Dir(library), snap.Name+".json"), data, 0o640); err != nil {
		return fmt.Errorf("describe the snapshot: %w", err)
	}
	if err := os.Rename(partial, final); err != nil {
		return fmt.Errorf("finish the snapshot: %w", err)
	}
	prune(library)
	return nil
}

func prune(library string) {
	all, err := List(library)
	if err != nil {
		return
	}
	for _, old := range all[min(len(all), Keep):] {
		if err := Delete(library, old.Name); err != nil {
			slog.Warn("an old snapshot was not removed", "name", old.Name, "error", err)
		}
	}
}

// Done runs after the migrations: it remembers which version the database is for, and forgets a
// rollback, as this version now works with it.
func Done(ctx context.Context, databaseURL, appVersion string) error {
	conn, err := connect(ctx, databaseURL)
	if err != nil {
		return err
	}
	defer func() { _ = conn.Close(ctx) }()
	if err := setState(ctx, conn, stateVersion, appVersion); err != nil {
		return fmt.Errorf("remember the version: %w", err)
	}
	_, err = conn.Exec(ctx, `DELETE FROM system_state WHERE key = $1`, stateRollback)
	return err
}

// Rollback brings the database back to a snapshot: the newest when name is empty. The server and
// worker must be stopped. It says what will be lost and asks first, unless yes is set.
func Rollback(ctx context.Context, databaseURL, library, name string, yes bool, in io.Reader, out io.Writer) error {
	all, err := List(library)
	if err != nil {
		return err
	}
	var snap *Snapshot
	for i := range all {
		if name == "" || all[i].Name == name {
			snap = &all[i]
			break
		}
	}
	if snap == nil {
		if name == "" {
			return ErrNoSnapshot
		}
		return fmt.Errorf("%w: %s; see `rollback list`", ErrNoSnapshot, name)
	}
	conn, err := connect(ctx, databaseURL)
	if err != nil {
		return err
	}
	defer func() { _ = conn.Close(ctx) }()

	var others int
	err = conn.QueryRow(ctx, `SELECT count(*) FROM pg_stat_activity
		WHERE datname = current_database() AND pid <> pg_backend_pid() AND backend_type = 'client backend'`).Scan(&others)
	if err != nil {
		return fmt.Errorf("check who uses the database: %w", err)
	}
	if others > 0 {
		return errors.New("the database is in use: stop Mediarr first with `docker compose stop server worker`")
	}
	var added int
	_ = conn.QueryRow(ctx, `SELECT count(*) FROM assets WHERE created_at > $1`, snap.CreatedAt).Scan(&added)

	before := snap.FromVersion
	if before == "" {
		before = "the version before"
	}
	_, _ = fmt.Fprintf(out, "Back to the database of %s, as it was on %s (schema %d).\n",
		before, snap.CreatedAt.Local().Format("2 January 2006 15:04"), snap.FromSchema)
	if added > 0 {
		_, _ = fmt.Fprintf(out, "%d photos and videos were added since then. Their files stay in the library, "+
			"but the database will not know them; upload them again after the rollback.\n", added)
	}
	if !yes {
		_, _ = fmt.Fprint(out, "Type yes to go on: ")
		answer, _ := bufio.NewReader(in).ReadString('\n')
		if strings.TrimSpace(strings.ToLower(answer)) != "yes" {
			return errors.New("nothing was changed")
		}
	}
	if err := restore(ctx, databaseURL, dumpPath(library, snap.Name)); err != nil {
		return err
	}
	marker, err := json.Marshal(rollback{From: snap.ToVersion, To: snap.FromVersion})
	if err != nil {
		return err
	}
	if err := setState(ctx, conn, stateRollback, string(marker)); err != nil {
		return fmt.Errorf("mark the rollback: %w", err)
	}
	if snap.FromVersion != "" {
		_, _ = fmt.Fprintf(out, "Done. Set MEDIARR_VERSION=%s in .env, then run `docker compose up -d`.\n", snap.FromVersion)
	} else {
		_, _ = fmt.Fprint(out, "Done. Set MEDIARR_VERSION in .env to the version you had before, then run `docker compose up -d`.\n")
	}
	return nil
}

// restore replaces everything in the database with the snapshot, in one transaction: if any of
// it fails, the database stays as it was. Tables a newer version added go with the old schema.
func restore(ctx context.Context, databaseURL, dump string) error {
	dumped := exec.CommandContext(ctx, "pg_restore", "--no-owner", "--file=-", dump)
	script, err := dumped.StdoutPipe()
	if err != nil {
		return err
	}
	var dumpErr strings.Builder
	dumped.Stderr = &dumpErr
	apply := exec.CommandContext(ctx, "psql", "--quiet", "--single-transaction", "--set=ON_ERROR_STOP=1",
		"--dbname="+databaseURL)
	apply.Stdin = io.MultiReader(strings.NewReader("DROP SCHEMA public CASCADE;\nCREATE SCHEMA public;\n"), script)
	var applyOut strings.Builder
	apply.Stdout = &applyOut
	apply.Stderr = &applyOut
	if err := dumped.Start(); err != nil {
		return fmt.Errorf("pg_restore: %w", err)
	}
	applyErr := apply.Run()
	waitErr := dumped.Wait()
	if waitErr != nil {
		return fmt.Errorf("pg_restore: %s", clip(dumpErr.String()))
	}
	if applyErr != nil {
		return fmt.Errorf("the rollback failed and nothing was changed: %s", clip(applyOut.String()))
	}
	return nil
}

func clip(text string) string {
	text = strings.TrimSpace(text)
	if len(text) > maxToolText {
		return text[len(text)-maxToolText:]
	}
	return text
}
