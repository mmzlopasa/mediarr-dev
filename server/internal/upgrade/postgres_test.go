package upgrade

import (
	"context"
	"slices"
	"strings"
	"testing"
)

func TestPostgresCommandKeepsThePasswordOffTheCommandLine(t *testing.T) {
	cmd := PostgresCommand(context.Background(), "postgres://mediarr:s3cret@db:5432/mediarr?sslmode=disable", "pg_dump", "--format=custom")
	line := strings.Join(cmd.Args, " ")
	if strings.Contains(line, "s3cret") {
		t.Errorf("the password is on the command line: %s", line)
	}
	if !strings.Contains(line, "--dbname=postgres://mediarr@db:5432/mediarr?sslmode=disable") {
		t.Errorf("the address is wrong: %s", line)
	}
	if !slices.Contains(cmd.Env, "PGPASSWORD=s3cret") {
		t.Error("the password is not in the environment")
	}

	address, password := splitPassword("postgres://u@h/d?password=p%40ss&sslmode=disable")
	if password != "p@ss" || strings.Contains(address, "p%40ss") {
		t.Errorf("a password in the query stayed: %s %s", address, password)
	}
	if address, password := splitPassword("host=db user=u"); address != "host=db user=u" || password != "" {
		t.Errorf("a keyword address was changed: %s", address)
	}
}
