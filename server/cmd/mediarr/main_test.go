package main

import (
	"context"
	"testing"
	"time"
)

func TestOpenPoolSetsSessionSettings(t *testing.T) {
	// Nothing connects until the pool is used, so no database is needed here.
	pool, err := openPool(context.Background(), "postgres://mediarr:secret@127.0.0.1:1/mediarr?work_mem=64MB")
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	params := pool.Config().ConnConfig.RuntimeParams
	if params["jit"] != "off" {
		t.Errorf("jit = %q, want off", params["jit"])
	}
	if params["work_mem"] != "64MB" {
		t.Errorf("work_mem = %q, want the 64MB the address asks for", params["work_mem"])
	}
}

// The runtime image has no zoneinfo, so the zones must come with the binary.
func TestTimeZonesComeWithTheBinary(t *testing.T) {
	zone, err := time.LoadLocation("Europe/Zagreb")
	if err != nil {
		t.Fatal(err)
	}
	if _, offset := time.Date(2026, 7, 1, 12, 0, 0, 0, zone).Zone(); offset != 2*60*60 {
		t.Fatalf("offset %d", offset)
	}
}
