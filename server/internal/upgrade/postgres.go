package upgrade

import (
	"context"
	"net/url"
	"os"
	"os/exec"
)

// PostgresCommand runs pg_dump, pg_restore or psql on a database. The password goes in the tool's
// environment, which no process list shows, and the address it is given has none.
func PostgresCommand(ctx context.Context, databaseURL, tool string, args ...string) *exec.Cmd {
	address, password := splitPassword(databaseURL)
	cmd := exec.CommandContext(ctx, tool, append([]string{"--dbname=" + address}, args...)...) //nolint:gosec // One of the Postgres tools.
	if password != "" {
		cmd.Env = append(os.Environ(), "PGPASSWORD="+password)
	}
	return cmd
}

// splitPassword takes the password out of a postgres:// address. Any other form is left as it is.
func splitPassword(databaseURL string) (address, password string) {
	parsed, err := url.Parse(databaseURL)
	if err != nil || (parsed.Scheme != "postgres" && parsed.Scheme != "postgresql") {
		return databaseURL, ""
	}
	query := parsed.Query()
	if parsed.User != nil {
		if secret, ok := parsed.User.Password(); ok {
			password = secret
			parsed.User = url.User(parsed.User.Username())
		}
	}
	if secret := query.Get("password"); secret != "" {
		password = secret
		query.Del("password")
		parsed.RawQuery = query.Encode()
	}
	return parsed.String(), password
}
