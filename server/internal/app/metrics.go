package app

import (
	"context"
	"crypto/subtle"
	"log/slog"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/collectors"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

const metricsScrapeLimit = 10 * time.Second

// metrics counts requests by route, not by address, so that ids never become labels.
type metrics struct {
	registry *prometheus.Registry
	requests *prometheus.HistogramVec
}

func newMetrics(s *apiServer) *metrics {
	registry := prometheus.NewRegistry()
	requests := prometheus.NewHistogramVec(prometheus.HistogramOpts{
		Name: "mediarr_http_request_seconds", Help: "API requests by route and status.",
		Buckets: []float64{0.01, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 30},
	}, []string{"method", "route", "status"})
	registry.MustRegister(requests, collectors.NewGoCollector(),
		collectors.NewProcessCollector(collectors.ProcessCollectorOpts{}), &libraryCollector{s})
	return &metrics{registry, requests}
}

func (m *metrics) observe(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !strings.HasPrefix(r.URL.Path, "/api/") {
			next.ServeHTTP(w, r)
			return
		}
		start := time.Now()
		wrapped := middleware.NewWrapResponseWriter(w, r.ProtoMajor)
		next.ServeHTTP(wrapped, r)
		route := "unknown"
		if found := chi.RouteContext(r.Context()); found != nil && found.RoutePattern() != "" {
			route = found.RoutePattern()
		}
		m.requests.WithLabelValues(r.Method, route, strconv.Itoa(wrapped.Status())).Observe(time.Since(start).Seconds())
	})
}

// libraryCollector reads the numbers fresh on each scrape, from what the admin overview shows.
type libraryCollector struct{ s *apiServer }

var (
	metricUsers  = prometheus.NewDesc("mediarr_users", "Accounts.", nil, nil)
	metricAssets = prometheus.NewDesc("mediarr_assets", "Assets by kind.", []string{"kind"}, nil)
	metricBad    = prometheus.NewDesc("mediarr_assets_state", "Assets not ready, by state.", []string{"state"}, nil)
	metricBytes  = prometheus.NewDesc("mediarr_library_bytes", "Total size of all originals.", nil, nil)
	metricDisk   = prometheus.NewDesc("mediarr_disk_bytes", "The library disk.", []string{"state"}, nil)
	metricJobs   = prometheus.NewDesc("mediarr_jobs", "Background jobs by state.", []string{"state"}, nil)
)

func (c *libraryCollector) Describe(out chan<- *prometheus.Desc) {
	for _, desc := range []*prometheus.Desc{metricUsers, metricAssets, metricBad, metricBytes, metricDisk, metricJobs} {
		out <- desc
	}
}

func (c *libraryCollector) Collect(out chan<- prometheus.Metric) {
	ctx, cancel := context.WithTimeout(context.Background(), metricsScrapeLimit)
	defer cancel()
	o, err := c.s.adminOverview(ctx)
	if err != nil {
		slog.Warn("the numbers for metrics could not be read", "error", err)
		return
	}
	gauge := func(desc *prometheus.Desc, value int64, labels ...string) {
		out <- prometheus.MustNewConstMetric(desc, prometheus.GaugeValue, float64(value), labels...)
	}
	gauge(metricUsers, o.Users)
	gauge(metricAssets, o.Photos, "photo")
	gauge(metricAssets, o.Videos, "video")
	gauge(metricBad, o.Processing, "processing")
	gauge(metricBad, o.Failed, "failed")
	gauge(metricBytes, o.LibraryBytes)
	gauge(metricDisk, o.DiskTotalBytes, "total")
	gauge(metricDisk, o.DiskFreeBytes, "free")
	gauge(metricJobs, o.Jobs.Queued, "queued")
	gauge(metricJobs, o.Jobs.Running, "running")
	gauge(metricJobs, o.Jobs.Completed, "completed")
	gauge(metricJobs, o.Jobs.Failed, "failed")
}

// serveMetrics exists only when a token is set, and needs that token. It is not part of the API:
// a monitoring system reads it, and it holds nothing about any one person.
func (s *apiServer) serveMetrics(w http.ResponseWriter, r *http.Request) {
	if s.MetricsToken == "" {
		http.NotFound(w, r)
		return
	}
	given := strings.TrimPrefix(r.Header.Get("Authorization"), "Bearer ")
	if subtle.ConstantTimeCompare([]byte(given), []byte(s.MetricsToken)) != 1 {
		w.Header().Set("WWW-Authenticate", "Bearer")
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	promhttp.HandlerFor(s.metrics.registry, promhttp.HandlerOpts{}).ServeHTTP(w, r)
}
