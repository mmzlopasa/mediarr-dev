// Package geo tells roughly where an address is, by city and country, from DB-IP Lite (CC BY 4.0,
// https://db-ip.com). The database is fetched the first time it is needed and once a month after,
// into the cache, so installations that never share a link never download it.
package geo

import (
	"compress/gzip"
	"context"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"net/netip"
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/oschwald/maxminddb-golang/v2"
)

const (
	fileName   = "dbip-city-lite.mmdb"
	refreshAge = 35 * 24 * time.Hour
	retryAfter = time.Hour
	fetchLimit = 10 * time.Minute
	maxSize    = 512 << 20
)

// Source is where a month's database is; a variable so tests can serve their own.
var Source = func(month string) string {
	return "https://download.db-ip.com/free/dbip-city-lite-" + month + ".mmdb.gz"
}

// Finder looks addresses up. It is safe to share.
type Finder struct {
	dir     string
	enabled bool

	mu       sync.Mutex
	reader   *maxminddb.Reader
	fetching bool
	tried    time.Time
}

// New keeps the database in dir. A finder that is not enabled never downloads and knows nothing.
func New(dir string, enabled bool) *Finder {
	return &Finder{dir: dir, enabled: enabled}
}

type record struct {
	City struct {
		Names map[string]string `maxminddb:"names"`
	} `maxminddb:"city"`
	Country struct {
		Names map[string]string `maxminddb:"names"`
	} `maxminddb:"country"`
}

// Place is the city and country of an address, in English, or nothing while it is not known.
func (f *Finder) Place(address string) (city, country string) {
	ip, err := netip.ParseAddr(address)
	if err != nil || ip.IsLoopback() || ip.IsPrivate() || ip.IsLinkLocalUnicast() || !f.enabled {
		return "", ""
	}
	reader := f.ready()
	if reader == nil {
		return "", ""
	}
	var found record
	if err := reader.Lookup(ip.Unmap()).Decode(&found); err != nil {
		return "", ""
	}
	return found.City.Names["en"], found.Country.Names["en"]
}

// ready opens the database when it is there, and fetches it in the background when it is not or is old.
func (f *Finder) ready() *maxminddb.Reader {
	f.mu.Lock()
	defer f.mu.Unlock()
	path := filepath.Join(f.dir, fileName)
	info, statErr := os.Stat(path)
	if f.reader == nil && statErr == nil {
		if reader, err := maxminddb.Open(path); err == nil {
			f.reader = reader
		}
	}
	stale := statErr != nil || time.Since(info.ModTime()) > refreshAge
	if stale && !f.fetching && time.Since(f.tried) > retryAfter {
		f.fetching, f.tried = true, time.Now()
		go f.fetch()
	}
	return f.reader
}

func (f *Finder) fetch() {
	ctx, cancel := context.WithTimeout(context.Background(), fetchLimit)
	defer cancel()
	err := f.download(ctx)
	f.mu.Lock()
	defer f.mu.Unlock()
	f.fetching = false
	if err != nil {
		slog.Info("the map of addresses to places could not be fetched; visits show no place", "reason", err)
		return
	}
	reader, err := maxminddb.Open(filepath.Join(f.dir, fileName))
	if err != nil {
		slog.Warn("the map of addresses to places could not be read", "error", err)
		return
	}
	if f.reader != nil {
		_ = f.reader.Close()
	}
	f.reader = reader
}

// download takes this month's database, or last month's early in a month before it is published.
func (f *Finder) download(ctx context.Context) error {
	now := time.Now().UTC()
	var last error
	for _, month := range []time.Time{now, now.AddDate(0, -1, 0)} {
		if last = f.downloadMonth(ctx, month.Format("2006-01")); last == nil {
			return nil
		}
	}
	return last
}

func (f *Finder) downloadMonth(ctx context.Context, month string) error {
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, Source(month), http.NoBody)
	if err != nil {
		return err
	}
	response, err := http.DefaultClient.Do(request)
	if err != nil {
		return err
	}
	defer func() { _ = response.Body.Close() }()
	if response.StatusCode != http.StatusOK {
		return fmt.Errorf("%s: %s", month, response.Status)
	}
	unzipped, err := gzip.NewReader(response.Body)
	if err != nil {
		return err
	}
	if err := os.MkdirAll(f.dir, 0o750); err != nil {
		return err
	}
	tmp, err := os.CreateTemp(f.dir, ".geo-*")
	if err != nil {
		return err
	}
	defer func() { _ = os.Remove(tmp.Name()) }()
	written, err := io.Copy(tmp, io.LimitReader(unzipped, maxSize+1))
	if closeErr := tmp.Close(); err == nil {
		err = closeErr
	}
	if err != nil {
		return err
	}
	if written > maxSize {
		return errors.New("the database is larger than expected")
	}
	check, err := maxminddb.Open(tmp.Name())
	if err != nil {
		return err
	}
	_ = check.Close()
	return os.Rename(tmp.Name(), filepath.Join(f.dir, fileName))
}
