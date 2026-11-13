package config

import "testing"

func TestTheExampleDatabasePasswordIsNoticed(t *testing.T) {
	for databaseURL, want := range map[string]bool{
		"postgres://mediarr:change-me@db:5432/mediarr":     true,
		"postgres://mediarr:s3cret-long@db:5432/mediarr":   false,
		"postgres://mediarr@db:5432/mediarr":               false,
		"postgres://mediarr:change-me-now@db:5432/mediarr": false,
		"":            false,
		"::not a url": false,
	} {
		if got := UsesExamplePassword(databaseURL); got != want {
			t.Errorf("%q: %v, want %v", databaseURL, got, want)
		}
	}
}
