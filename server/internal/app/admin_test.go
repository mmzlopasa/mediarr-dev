package app

import (
	"encoding/json"
	"net/http"
	"testing"

	"github.com/mediarr-app/mediarr/server/internal/api"
)

func TestAdminOverviewComesFromRealData(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	user := s.user(admin, "ana@example.com")

	resp, body := user.get("/api/admin/overview")
	expect(t, resp, body, http.StatusForbidden)
	resp, body = s.client().get("/api/admin/overview")
	expect(t, resp, body, http.StatusUnauthorized)

	read := func() api.AdminOverview {
		t.Helper()
		resp, body := admin.get("/api/admin/overview")
		expect(t, resp, body, http.StatusOK)
		var overview api.AdminOverview
		if err := json.Unmarshal(body, &overview); err != nil {
			t.Fatal(err)
		}
		return overview
	}

	before := read()
	if before.Users != 2 || before.LibraryBytes != 0 || before.Processing != 0 {
		t.Errorf("before: %+v", before)
	}
	if before.DiskTotalBytes <= 0 || before.DiskFreeBytes <= 0 || before.DatabaseVersion == "" {
		t.Errorf("no disk or database information: %+v", before)
	}

	user.upload("a.jpg", randomBytes(t, 1000), nil)
	admin.upload("b.jpg", randomBytes(t, 500), nil)

	after := read()
	if after.LibraryBytes != 1500 || after.Processing != 2 || after.Jobs.Queued != 2 {
		t.Errorf("after uploads: %+v", after)
	}
}
