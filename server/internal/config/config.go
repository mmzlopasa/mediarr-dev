// Package config reads settings from the environment.
package config

import (
	"os"
	"runtime"
	"strconv"
)

// Config holds the settings shared by the server and the worker.
type Config struct {
	ListenAddr        string
	DatabaseURL       string
	LibraryPath       string
	CachePath         string
	WorkerConcurrency int
	VideoAccel        string
}

// Load returns the settings, with defaults matching the Docker image.
func Load() Config {
	return Config{
		ListenAddr:        env("LISTEN_ADDR", ":8080"),
		DatabaseURL:       os.Getenv("DATABASE_URL"),
		LibraryPath:       env("LIBRARY_PATH", "/data/library"),
		CachePath:         env("CACHE_PATH", "/data/cache"),
		WorkerConcurrency: concurrency(os.Getenv("WORKER_CONCURRENCY"), runtime.NumCPU()),
		VideoAccel:        os.Getenv("VIDEO_ACCEL"),
	}
}

func concurrency(value string, cpus int) int {
	if n, err := strconv.Atoi(value); err == nil && n > 0 {
		return n
	}
	return max(1, cpus/2)
}

func env(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}
