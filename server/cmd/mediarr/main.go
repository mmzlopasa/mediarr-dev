// Command mediarr runs the Mediarr server, background worker and maintenance tasks.
package main

import (
	"bufio"
	"context"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net"
	"net/http"
	"os"
	"os/signal"
	"path/filepath"
	"strings"
	"syscall"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/app"
	"github.com/mediarr-app/mediarr/server/internal/auth"
	"github.com/mediarr-app/mediarr/server/internal/config"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
	"github.com/mediarr-app/mediarr/server/internal/storage"
	"github.com/mediarr-app/mediarr/server/internal/upgrade"
)

const (
	usage             = "usage: mediarr <serve|worker|healthcheck|migrate [down]|rollback [list|<name>] [--yes]|user upsert <email> <name> [--admin]|user reset-vault <email>|security reset>"
	stateStorageReady = "storage_initialized"
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	if err := run(ctx, os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, "mediarr:", err)
		os.Exit(1)
	}
}

func run(ctx context.Context, args []string) error {
	if len(args) == 0 {
		return errors.New(usage)
	}
	cfg := config.Load()

	switch args[0] {
	case "serve":
		return serve(ctx, cfg)
	case "worker":
		return worker(ctx, cfg)
	case "healthcheck":
		return healthcheck(ctx, cfg)
	case "migrate":
		if len(args) > 1 && args[1] == "down" {
			return db.MigrateDown(ctx, cfg.DatabaseURL)
		}
		// Asked for by a person, so it also tries a version the database was brought back from.
		return migrate(ctx, cfg, true)
	case "rollback":
		return rollback(ctx, cfg, args[1:])
	case "reprocess":
		return reprocess(ctx, cfg, len(args) > 1 && args[1] == "failed")
	case "user":
		return upsertUser(ctx, cfg, args[1:])
	case "security":
		return securityCommand(ctx, cfg, args[1:])
	case "restore-backup":
		return restoreBackup(ctx, cfg)
	default:
		return errors.New(usage)
	}
}

// prepareStorage checks both directories, and remembers that it did so: from then on a missing
// marker means the disk is not mounted, and starting would write to the wrong disk.
func prepareStorage(ctx context.Context, cfg config.Config, queries *db.Queries) error {
	_, err := queries.GetState(ctx, stateStorageReady)
	if err != nil && !db.IsNotFound(err) {
		return fmt.Errorf("read storage state: %w", err)
	}
	initialized := err == nil
	for _, dir := range []string{cfg.LibraryPath, cfg.CachePath} {
		if err := storage.Prepare(dir, initialized); err != nil {
			return err
		}
	}
	if initialized {
		return nil
	}
	return queries.SetState(ctx, db.SetStateParams{Key: stateStorageReady, Value: "true"})
}

// migrate keeps a snapshot of the database before changing it, so an upgrade can be undone.
func migrate(ctx context.Context, cfg config.Config, force bool) error {
	if err := upgrade.Prepare(ctx, cfg.DatabaseURL, cfg.LibraryPath, app.Version, force); err != nil {
		return err
	}
	if err := db.Migrate(ctx, cfg.DatabaseURL); err != nil {
		return err
	}
	return upgrade.Done(ctx, cfg.DatabaseURL, app.Version)
}

// rollback lists the snapshots, or brings the database back to one.
func rollback(ctx context.Context, cfg config.Config, args []string) error {
	yes := false
	name := ""
	for _, arg := range args {
		switch arg {
		case "--yes":
			yes = true
		case "list":
			return listSnapshots(cfg)
		default:
			name = arg
		}
	}
	return upgrade.Rollback(ctx, cfg.DatabaseURL, cfg.LibraryPath, name, yes, os.Stdin, os.Stdout)
}

func listSnapshots(cfg config.Config) error {
	all, err := upgrade.List(cfg.LibraryPath)
	if err != nil {
		return err
	}
	if len(all) == 0 {
		fmt.Println("No snapshots yet. One is made before each upgrade that changes the database.")
		return nil
	}
	for _, snap := range all {
		from := snap.FromVersion
		if from == "" {
			from = "?"
		}
		fmt.Printf("%s  %s → %s  %s  %d MB\n", snap.Name, from, snap.ToVersion,
			snap.CreatedAt.Local().Format("2006-01-02 15:04"), snap.SizeBytes>>20)
	}
	return nil
}

func serve(ctx context.Context, cfg config.Config) error {
	if err := migrate(ctx, cfg, false); err != nil {
		return err
	}

	pool, err := pgxpool.New(ctx, cfg.DatabaseURL)
	if err != nil {
		return fmt.Errorf("open database: %w", err)
	}
	defer pool.Close()

	if err := db.LoadPlaces(ctx, pool); err != nil {
		return err
	}
	queries := db.New(pool)
	if err := prepareStorage(ctx, cfg, queries); err != nil {
		return err
	}
	stopTracing, err := app.StartTracing(ctx)
	if err != nil {
		return err
	}
	defer func() { _ = stopTracing(context.WithoutCancel(ctx)) }()
	inserter, err := jobs.NewInserter(pool)
	if err != nil {
		return fmt.Errorf("create job client: %w", err)
	}
	handler, err := app.NewHandler(app.Deps{MLURL: cfg.MLURL, Pinger: queries, Pool: pool, Inserter: inserter, LibraryPath: cfg.LibraryPath, CachePath: cfg.CachePath, ExternalPath: cfg.ExternalPath, ProxyHops: cfg.ProxyHops, DemoEmail: cfg.DemoEmail, CheckUpdates: cfg.CheckUpdates, MaxUploadBytes: cfg.MaxUploadBytes, MetricsToken: cfg.MetricsToken, BackupPath: cfg.BackupPath})
	if err != nil {
		return err
	}

	go app.AdvertiseOnNetwork(ctx, queries, cfg.PublicPort)

	srv := &http.Server{
		Addr:              cfg.ListenAddr,
		Handler:           handler,
		ReadHeaderTimeout: 10 * time.Second,
	}

	errs := make(chan error, 1)
	go func() { errs <- srv.ListenAndServe() }()
	slog.Info("server listening", "addr", srv.Addr)

	select {
	case err := <-errs:
		return err
	case <-ctx.Done():
	}

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	return srv.Shutdown(shutdownCtx)
}

func worker(ctx context.Context, cfg config.Config) error {
	pool, err := pgxpool.New(ctx, cfg.DatabaseURL)
	if err != nil {
		return fmt.Errorf("open database: %w", err)
	}
	defer pool.Close()

	if err := pool.Ping(ctx); err != nil {
		return fmt.Errorf("ping database: %w", err)
	}
	// The server prepares storage before it reports healthy, and the worker starts after that.
	for _, dir := range []string{cfg.LibraryPath, cfg.CachePath} {
		if err := storage.CheckMarker(dir); err != nil {
			return err
		}
	}
	if err := jobs.ReleaseInterrupted(ctx, pool); err != nil {
		return err
	}
	settings, err := jobs.LoadServerSettings(ctx, db.New(pool))
	if err != nil {
		return err
	}
	if settings.WorkerConcurrency > 0 {
		cfg.WorkerConcurrency = settings.WorkerConcurrency
	}
	client, err := jobs.NewWorker(pool, jobs.Options{VideoWorkers: settings.VideoWorkers, AnalysisWorkers: settings.AnalysisWorkers, MLURL: cfg.MLURL, Concurrency: cfg.WorkerConcurrency, LibraryPath: cfg.LibraryPath, CachePath: cfg.CachePath, ExternalPath: cfg.ExternalPath, DatabaseURL: cfg.DatabaseURL, VideoAccel: cfg.VideoAccel})
	if err != nil {
		return fmt.Errorf("create worker: %w", err)
	}
	slog.Info("worker ready", "concurrency", cfg.WorkerConcurrency)
	if err := jobs.RetranscodeUprightVideos(ctx, pool, client); err != nil {
		slog.Warn("upright videos were not queued for transcoding", "error", err)
	}
	if jobs.IsExternalAvailable(cfg.ExternalPath) {
		go func() {
			err := jobs.WatchExternal(ctx, cfg.ExternalPath, jobs.ExternalSettleTime, func() {
				if _, err := client.Insert(ctx, jobs.ExternalScanArgs{}, nil); err != nil {
					slog.Warn("a scan of the external library could not be queued", "error", err)
				}
			})
			if err != nil {
				slog.Warn("the external library is not watched; the periodic scan still finds changes", "error", err)
			}
		}()
	}
	return jobs.Run(ctx, client)
}

// upsertUser creates a user or resets their password and two-factor sign-in from the command line,
// which is how a self-hosted administrator recovers access. The password comes from stdin.
func upsertUser(ctx context.Context, cfg config.Config, args []string) error {
	if len(args) == 2 && args[0] == "delete" {
		return deleteUser(ctx, cfg, args[1])
	}
	if len(args) == 2 && args[0] == "reset-vault" {
		return resetVault(ctx, cfg, args[1])
	}
	if len(args) < 3 || args[0] != "upsert" {
		return errors.New(usage)
	}
	email, err := auth.NormalizeEmail(args[1])
	if err != nil {
		return err
	}
	isAdmin := len(args) > 3 && args[3] == "--admin"

	line, err := bufio.NewReader(os.Stdin).ReadString('\n')
	if err != nil && !errors.Is(err, io.EOF) {
		return fmt.Errorf("read password: %w", err)
	}
	password := strings.TrimRight(line, "\r\n")
	if err := auth.ValidatePassword(password); err != nil {
		return err
	}
	hash, err := auth.HashPassword(password)
	if err != nil {
		return err
	}

	pool, err := pgxpool.New(ctx, cfg.DatabaseURL)
	if err != nil {
		return fmt.Errorf("open database: %w", err)
	}
	defer pool.Close()
	queries := db.New(pool)
	user, err := queries.UpsertUser(ctx, db.UpsertUserParams{Email: email, Name: args[2], PasswordHash: hash, IsAdmin: isAdmin})
	if err != nil {
		return err
	}
	// A reset is what someone does after losing control of the account.
	if err := queries.DeleteUserAPIKeys(ctx, user.ID); err != nil {
		return err
	}
	if err := queries.DeleteUserPasskeys(ctx, user.ID); err != nil {
		return err
	}
	if err := queries.DeleteUserOIDCIdentities(ctx, user.ID); err != nil {
		return err
	}
	return queries.DeleteOtherSessions(ctx, db.DeleteOtherSessionsParams{UserID: user.ID})
}

// reprocess queues every ready asset for processing again, so files from an older version get what
// a newer one adds. With onlyFailed, it gives files that could not be read another try. Originals are
// not touched.
func reprocess(ctx context.Context, cfg config.Config, onlyFailed bool) error {
	pool, err := pgxpool.New(ctx, cfg.DatabaseURL)
	if err != nil {
		return fmt.Errorf("open database: %w", err)
	}
	defer pool.Close()
	inserter, err := jobs.NewInserter(pool)
	if err != nil {
		return err
	}
	list := db.New(pool).ListReadyAssetIDs
	if onlyFailed {
		list = db.New(pool).ListFailedAssetIDs
	}
	ids, err := list(ctx)
	if err != nil {
		return err
	}
	for _, id := range ids {
		if _, err := inserter.Insert(ctx, jobs.MetadataArgs{AssetID: id.Bytes}, nil); err != nil {
			return fmt.Errorf("queue job: %w", err)
		}
	}
	fmt.Printf("queued %d assets\n", len(ids))
	return nil
}

// deleteUser removes a user with all their assets and files. It cannot be undone.
// resetVault clears a lost PIN. The photos stay in the vault, and the user sets a new PIN to reach them.
func resetVault(ctx context.Context, cfg config.Config, rawEmail string) error {
	email, err := auth.NormalizeEmail(rawEmail)
	if err != nil {
		return err
	}
	pool, err := pgxpool.New(ctx, cfg.DatabaseURL)
	if err != nil {
		return fmt.Errorf("open database: %w", err)
	}
	defer pool.Close()
	queries := db.New(pool)
	user, err := queries.GetUserByEmail(ctx, email)
	if err != nil {
		return fmt.Errorf("find user: %w", err)
	}
	if err := queries.SetVaultPin(ctx, db.SetVaultPinParams{ID: user.ID}); err != nil {
		return err
	}
	return queries.DeleteVaultSessions(ctx, user.ID)
}

func deleteUser(ctx context.Context, cfg config.Config, rawEmail string) error {
	email, err := auth.NormalizeEmail(rawEmail)
	if err != nil {
		return err
	}
	pool, err := pgxpool.New(ctx, cfg.DatabaseURL)
	if err != nil {
		return fmt.Errorf("open database: %w", err)
	}
	defer pool.Close()
	queries := db.New(pool)

	user, err := queries.GetUserByEmail(ctx, email)
	if db.IsNotFound(err) {
		return nil
	}
	if err != nil {
		return err
	}
	if err := queries.DeleteUserAssets(ctx, user.ID); err != nil {
		return fmt.Errorf("delete assets: %w", err)
	}
	if err := queries.DeleteUser(ctx, user.ID); err != nil {
		return fmt.Errorf("delete user: %w", err)
	}
	id := uuid.UUID(user.ID.Bytes).String()
	for _, dir := range []string{
		filepath.Join(cfg.LibraryPath, id),
		filepath.Join(storage.SidecarDir(cfg.LibraryPath), id),
		filepath.Join(cfg.CachePath, "thumbs", id),
	} {
		if err := os.RemoveAll(dir); err != nil {
			return fmt.Errorf("delete files: %w", err)
		}
	}
	return nil
}

// restoreBackup brings a backup back onto an empty installation, on a server that lost everything:
// the settings in its database are gone too, so they come from the environment.
func restoreBackup(ctx context.Context, cfg config.Config) error {
	settings := &jobs.BackupSettings{
		Repository: os.Getenv("RESTIC_REPOSITORY"), Password: os.Getenv("RESTIC_PASSWORD"),
		S3Key: os.Getenv("AWS_ACCESS_KEY_ID"), S3Secret: os.Getenv("AWS_SECRET_ACCESS_KEY"),
		RestUser: os.Getenv("RESTIC_REST_USERNAME"), RestPassword: os.Getenv("RESTIC_REST_PASSWORD"),
	}
	// A copy kept by another Mediarr: its administrator gives a new code, which works once.
	if text := os.Getenv("MEDIARR_KEEP_CODE"); text != "" {
		code, err := jobs.ParseKeepCode(text)
		if err != nil {
			return err
		}
		pairing, err := jobs.PairWithHost(ctx, code)
		if err != nil {
			return err
		}
		destination := &db.BackupDestination{Address: code.Address, GuestID: pgtype.UUID{Bytes: pairing.GuestID, Valid: true}, Secret: pairing.Secret}
		settings = jobs.DestinationSettings(destination, settings.Password)
	}
	if settings.Repository == "" || settings.Password == "" {
		return errors.New("set RESTIC_PASSWORD, and RESTIC_REPOSITORY or MEDIARR_KEEP_CODE")
	}
	return jobs.RestoreBackup(ctx, settings, cfg.DatabaseURL, cfg.CachePath)
}

func healthcheck(ctx context.Context, cfg config.Config) error {
	_, port, err := net.SplitHostPort(cfg.ListenAddr)
	if err != nil {
		return fmt.Errorf("parse LISTEN_ADDR: %w", err)
	}

	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	url := "http://" + net.JoinHostPort("127.0.0.1", port) + "/health"
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, http.NoBody)
	if err != nil {
		return err
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}
	defer func() { _ = resp.Body.Close() }()
	_, _ = io.Copy(io.Discard, resp.Body)

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("health returned %d", resp.StatusCode)
	}
	return nil
}

// securityCommand is the way back in for someone who locked themselves out.
func securityCommand(ctx context.Context, cfg config.Config, args []string) error {
	if len(args) != 1 || args[0] != "reset" {
		return errors.New(usage)
	}
	pool, err := pgxpool.New(ctx, cfg.DatabaseURL)
	if err != nil {
		return err
	}
	defer pool.Close()
	return app.ResetSecurity(ctx, db.New(pool))
}
