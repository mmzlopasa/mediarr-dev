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
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/mmzlopasa/mediarr-app/server/db"
	"github.com/mmzlopasa/mediarr-app/server/internal/app"
	"github.com/mmzlopasa/mediarr-app/server/internal/auth"
	"github.com/mmzlopasa/mediarr-app/server/internal/config"
	"github.com/mmzlopasa/mediarr-app/server/internal/jobs"
	"github.com/mmzlopasa/mediarr-app/server/internal/storage"
)

const (
	usage             = "usage: mediarr <serve|worker|healthcheck|migrate [down]|user upsert <email> <name> [--admin]>"
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
		return db.Migrate(ctx, cfg.DatabaseURL)
	case "user":
		return upsertUser(ctx, cfg, args[1:])
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

func serve(ctx context.Context, cfg config.Config) error {
	if err := db.Migrate(ctx, cfg.DatabaseURL); err != nil {
		return err
	}

	pool, err := pgxpool.New(ctx, cfg.DatabaseURL)
	if err != nil {
		return fmt.Errorf("open database: %w", err)
	}
	defer pool.Close()

	queries := db.New(pool)
	if err := prepareStorage(ctx, cfg, queries); err != nil {
		return err
	}
	inserter, err := jobs.NewInserter(pool)
	if err != nil {
		return fmt.Errorf("create job client: %w", err)
	}
	handler, err := app.NewHandler(app.Deps{Pinger: queries, Pool: pool, Inserter: inserter, LibraryPath: cfg.LibraryPath})
	if err != nil {
		return err
	}

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
	client, err := jobs.NewWorker(pool, jobs.Options{Concurrency: cfg.WorkerConcurrency, LibraryPath: cfg.LibraryPath, CachePath: cfg.CachePath})
	if err != nil {
		return fmt.Errorf("create worker: %w", err)
	}
	slog.Info("worker ready", "concurrency", cfg.WorkerConcurrency)
	return jobs.Run(ctx, client)
}

// upsertUser creates a user or resets their password and two-factor sign-in from the command line,
// which is how a self-hosted administrator recovers access. The password comes from stdin.
func upsertUser(ctx context.Context, cfg config.Config, args []string) error {
	if len(args) == 2 && args[0] == "delete" {
		return deleteUser(ctx, cfg, args[1])
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
	_, err = db.New(pool).UpsertUser(ctx, db.UpsertUserParams{Email: email, Name: args[2], PasswordHash: hash, IsAdmin: isAdmin})
	return err
}

// deleteUser removes a user with all their assets and files. It cannot be undone.
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
