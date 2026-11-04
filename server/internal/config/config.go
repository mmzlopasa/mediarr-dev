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
	ExternalPath      string
	ProxyHops         int
	MaxUploadBytes    int64
	MetricsToken      string
	BackupPath        string
	WorkerConcurrency int
	VideoAccel        string
	MLURL             string
}

// Load returns the settings, with defaults matching the Docker image.
func Load() Config {
	return Config{
		ListenAddr:        env("LISTEN_ADDR", ":8080"),
		DatabaseURL:       os.Getenv("DATABASE_URL"),
		LibraryPath:       env("LIBRARY_PATH", "/data/library"),
		CachePath:         env("CACHE_PATH", "/data/cache"),
		ExternalPath:      env("EXTERNAL_PATH", "/external"),
		ProxyHops:         envInt("TRUSTED_PROXY_HOPS", 0),
		MetricsToken:      os.Getenv("METRICS_TOKEN"),
		BackupPath:        env("BACKUP_MOUNT", "/backup"),
		MaxUploadBytes:    int64(envInt("MAX_UPLOAD_MB", 0)) * 1024 * 1024,
		WorkerConcurrency: concurrency(os.Getenv("WORKER_CONCURRENCY"), runtime.NumCPU()),
		VideoAccel:        os.Getenv("VIDEO_ACCEL"),
		MLURL:             os.Getenv("ML_URL"),
	}
}

func concurrency(value string, cpus int) int {
	if n, err := strconv.Atoi(value); err == nil && n > 0 {
		return n
	}
	return max(1, cpus/2)
}

func envInt(key string, fallback int) int {
	value, err := strconv.Atoi(os.Getenv(key))
	if err != nil {
		return fallback
	}
	return value
}

func env(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}
