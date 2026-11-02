// Package db holds migrations and generated queries.
package db

import (
	"context"
	"database/sql"
	"embed"
	"errors"
	"fmt"
	"io/fs"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	_ "github.com/jackc/pgx/v5/stdlib" // Registers the pgx database/sql driver for goose.
	"github.com/pressly/goose/v3"
	"github.com/riverqueue/river/riverdriver/riverpgxv5"
	"github.com/riverqueue/river/rivermigrate"
)

//go:embed migrations/*.sql
var migrations embed.FS

func provider(conn *sql.DB) (*goose.Provider, error) {
	sub, err := fs.Sub(migrations, "migrations")
	if err != nil {
		return nil, err
	}
	p, err := goose.NewProvider(goose.DialectPostgres, conn, sub)
	if err != nil {
		return nil, fmt.Errorf("create migration provider: %w", err)
	}
	return p, nil
}

// Migrate applies all pending schema and job queue migrations.
func Migrate(ctx context.Context, databaseURL string) error {
	conn, err := sql.Open("pgx", databaseURL)
	if err != nil {
		return fmt.Errorf("open database: %w", err)
	}
	defer func() { _ = conn.Close() }()

	p, err := provider(conn)
	if err != nil {
		return err
	}
	if _, err := p.Up(ctx); err != nil {
		return fmt.Errorf("run migrations: %w", err)
	}

	pool, err := pgxpool.New(ctx, databaseURL)
	if err != nil {
		return fmt.Errorf("open database: %w", err)
	}
	defer pool.Close()
	migrator, err := rivermigrate.New(riverpgxv5.New(pool), nil)
	if err != nil {
		return fmt.Errorf("create job queue migrator: %w", err)
	}
	if _, err := migrator.Migrate(ctx, rivermigrate.DirectionUp, nil); err != nil {
		return fmt.Errorf("run job queue migrations: %w", err)
	}
	return nil
}

// MigrateDown reverts the newest schema migration.
func MigrateDown(ctx context.Context, databaseURL string) error {
	conn, err := sql.Open("pgx", databaseURL)
	if err != nil {
		return fmt.Errorf("open database: %w", err)
	}
	defer func() { _ = conn.Close() }()

	p, err := provider(conn)
	if err != nil {
		return err
	}
	if _, err := p.Down(ctx); err != nil {
		return fmt.Errorf("revert migration: %w", err)
	}
	return nil
}

// IsNotFound reports whether a query found no row.
func IsNotFound(err error) bool {
	return errors.Is(err, pgx.ErrNoRows)
}
