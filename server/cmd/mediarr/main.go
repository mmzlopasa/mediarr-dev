// Command mediarr runs the Mediarr server, background worker and maintenance tasks.
package main

import (
	"context"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/mmzlopasa/mediarr-app/server/db"
	"github.com/mmzlopasa/mediarr-app/server/internal/app"
)

const usage = "usage: mediarr <serve|worker|healthcheck|migrate>"

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	if err := run(ctx, os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, "mediarr:", err)
		os.Exit(1)
	}
}

func run(ctx context.Context, args []string) error {
	if len(args) != 1 {
		return errors.New(usage)
	}

	switch args[0] {
	case "serve":
		return serve(ctx)
	case "worker":
		return worker(ctx)
	case "healthcheck":
		return healthcheck(ctx)
	case "migrate":
		return db.Migrate(ctx, databaseURL())
	default:
		return errors.New(usage)
	}
}

func serve(ctx context.Context) error {
	if err := db.Migrate(ctx, databaseURL()); err != nil {
		return err
	}

	pool, err := pgxpool.New(ctx, databaseURL())
	if err != nil {
		return fmt.Errorf("open database: %w", err)
	}
	defer pool.Close()

	srv := &http.Server{
		Addr:              listenAddr(),
		Handler:           app.NewHandler(db.New(pool)),
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

// worker only verifies database access for now; River jobs arrive in phase 2.
func worker(ctx context.Context) error {
	pool, err := pgxpool.New(ctx, databaseURL())
	if err != nil {
		return fmt.Errorf("open database: %w", err)
	}
	defer pool.Close()

	if err := pool.Ping(ctx); err != nil {
		return fmt.Errorf("ping database: %w", err)
	}
	slog.Info("worker ready")

	<-ctx.Done()
	return nil
}

func healthcheck(ctx context.Context) error {
	_, port, err := net.SplitHostPort(listenAddr())
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

func listenAddr() string {
	if addr := os.Getenv("LISTEN_ADDR"); addr != "" {
		return addr
	}
	return ":8080"
}

func databaseURL() string {
	return os.Getenv("DATABASE_URL")
}
