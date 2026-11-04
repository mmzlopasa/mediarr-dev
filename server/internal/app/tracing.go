package app

import (
	"context"
	"fmt"
	"net/http"
	"os"

	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/sdk/trace"
)

// StartTracing sends traces only if OTEL_EXPORTER_OTLP_ENDPOINT is set, and otherwise costs nothing.
// The returned function sends what is left when the server stops.
func StartTracing(ctx context.Context) (func(context.Context) error, error) {
	if os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT") == "" {
		return func(context.Context) error { return nil }, nil
	}
	exporter, err := otlptracehttp.New(ctx)
	if err != nil {
		return nil, fmt.Errorf("start tracing: %w", err)
	}
	provider := trace.NewTracerProvider(trace.WithBatcher(exporter))
	otel.SetTracerProvider(provider)
	return provider.Shutdown, nil
}

func traced(next http.Handler) http.Handler {
	if os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT") == "" {
		return next
	}
	return otelhttp.NewHandler(next, "mediarr",
		// The address holds link tokens, so a span is named by its method alone.
		otelhttp.WithSpanNameFormatter(func(_ string, r *http.Request) string { return r.Method }))
}
