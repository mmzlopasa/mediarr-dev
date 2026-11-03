// Package db holds migrations and generated queries.
package db

import (
	"bufio"
	"bytes"
	"compress/gzip"
	"context"
	"database/sql"
	"embed"
	"errors"
	"fmt"
	"io/fs"
	"strconv"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	_ "github.com/jackc/pgx/v5/stdlib" // Registers the pgx database/sql driver for goose.
	"github.com/pressly/goose/v3"
	"github.com/riverqueue/river/riverdriver/riverpgxv5"
	"github.com/riverqueue/river/rivermigrate"
)

//go:embed migrations/*.sql
var migrations embed.FS

const (
	placeFields    = 5
	placesCapacity = 180000
)

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

//go:embed geodata/places.tsv.gz
var placesData []byte

// LoadPlaces fills the place names once. The data is GeoNames (CC BY), kept in the binary, so a
// server without internet access still names places.
func LoadPlaces(ctx context.Context, pool *pgxpool.Pool) error {
	var count int64
	if err := pool.QueryRow(ctx, "SELECT count(*) FROM places").Scan(&count); err != nil {
		return fmt.Errorf("count places: %w", err)
	}
	if count > 0 {
		return nil
	}
	reader, err := gzip.NewReader(bytes.NewReader(placesData))
	if err != nil {
		return fmt.Errorf("read places: %w", err)
	}
	rows := make([][]any, 0, placesCapacity)
	scanner := bufio.NewScanner(reader)
	for scanner.Scan() {
		parts := strings.Split(scanner.Text(), "\t")
		if len(parts) != placeFields {
			return fmt.Errorf("a place has %d fields", len(parts))
		}
		lat, err := strconv.ParseFloat(parts[3], 32)
		if err != nil {
			return fmt.Errorf("read a latitude: %w", err)
		}
		lon, err := strconv.ParseFloat(parts[4], 32)
		if err != nil {
			return fmt.Errorf("read a longitude: %w", err)
		}
		rows = append(rows, []any{parts[0], parts[1], parts[2], float32(lat), float32(lon)})
	}
	if err := scanner.Err(); err != nil {
		return fmt.Errorf("read places: %w", err)
	}
	_, err = pool.CopyFrom(ctx, pgx.Identifier{"places"}, []string{"name", "state", "country", "lat", "lon"}, pgx.CopyFromRows(rows))
	if err != nil {
		return fmt.Errorf("store places: %w", err)
	}
	return nil
}
