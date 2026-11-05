package app

import (
	"context"
	"net/http"
	"os"
	"testing"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

func TestIntegrityFindsMissingAndChangedFiles(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	ctx := context.Background()
	resp, body := c.get("/api/admin/integrity")
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.IntegrityReport](t, body); got.FinishedAt != nil {
		t.Fatalf("a report before any check: %+v", got)
	}
	for _, name := range []string{"good.jpg", "gone.jpg", "edited.jpg"} {
		c.newPhoto(t, name, "2024-01-01T10:00:00Z")
	}
	paths := map[string]string{}
	rows, err := s.pool.Query(ctx, `SELECT original_name, original_path FROM assets`)
	if err != nil {
		t.Fatal(err)
	}
	for rows.Next() {
		var name, path string
		if err := rows.Scan(&name, &path); err != nil {
			t.Fatal(err)
		}
		paths[name] = path
	}
	rows.Close()
	for name, path := range paths {
		if err := os.Chmod(path, 0o600); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(path, []byte(name), 0o600); err != nil {
			t.Fatal(err)
		}
		if _, err := s.pool.Exec(ctx, `UPDATE assets SET checksum = sha256($1::bytea) WHERE original_name = $2`, []byte(name), name); err != nil {
			t.Fatal(err)
		}
	}
	if err := os.Remove(paths["gone.jpg"]); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(paths["edited.jpg"], []byte("something else"), 0o600); err != nil {
		t.Fatal(err)
	}
	queries := db.New(s.pool)
	if err := os.Chmod(paths["edited.jpg"], 0o600); err != nil {
		t.Fatal(err)
	}

	report, err := jobs.CheckIntegrity(ctx, queries, false)
	if err != nil {
		t.Fatal(err)
	}
	if report.Checked != 3 || report.Total != 1 || report.Problems[0].Problem != "missing" {
		t.Fatalf("quick: %+v", report)
	}
	report, err = jobs.CheckIntegrity(ctx, queries, true)
	if err != nil {
		t.Fatal(err)
	}
	if report.Total != 2 {
		t.Fatalf("thorough: %+v", report)
	}
	resp, body = c.get("/api/admin/integrity")
	expect(t, resp, body, http.StatusOK)
	saved := decode[api.IntegrityReport](t, body)
	if saved.Total != 2 || saved.FinishedAt == nil || !saved.Thorough {
		t.Fatalf("saved: %+v", saved)
	}
	// Nothing was changed by looking.
	if got, _ := os.ReadFile(paths["edited.jpg"]); string(got) != "something else" {
		t.Fatal("a file was changed")
	}
}

func TestServerSettingsRefuseWorkerAndFaceValuesOutOfRange(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	resp, body := c.get("/api/admin/server-settings")
	expect(t, resp, body, http.StatusOK)
	good := decode[api.ServerSettings](t, body)
	if good.FaceMinScore != 0.6 || good.FaceMaxDistance != 0.7 || good.VideoWorkers != 1 || good.AnalysisWorkers != 1 || good.ExternalScanHours != 6 {
		t.Fatalf("defaults: %+v", good)
	}
	for name, change := range map[string]func(*api.ServerSettings){
		"score":    func(v *api.ServerSettings) { v.FaceMinScore = 2 },
		"distance": func(v *api.ServerSettings) { v.FaceMaxDistance = 0 },
		"jobs":     func(v *api.ServerSettings) { v.WorkerConcurrency = 65 },
		"video":    func(v *api.ServerSettings) { v.VideoWorkers = 0 },
		"analysis": func(v *api.ServerSettings) { v.AnalysisWorkers = 17 },
		"scan":     func(v *api.ServerSettings) { v.ExternalScanHours = 0 },
	} {
		bad := good
		change(&bad)
		resp, body := c.send(http.MethodPut, "/api/admin/server-settings", bad)
		if resp.StatusCode != http.StatusBadRequest {
			t.Errorf("%s: %d %s", name, resp.StatusCode, body)
		}
	}
}

func TestMaintenanceKeepsPeopleOutButNotAdmins(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	person := s.user(admin, "person@example.com")
	resp, body := admin.get("/api/admin/server-settings")
	expect(t, resp, body, http.StatusOK)
	settings := decode[api.ServerSettings](t, body)
	settings.Maintenance = true
	resp, body = admin.send(http.MethodPut, "/api/admin/server-settings", settings)
	expect(t, resp, body, http.StatusOK)

	resp, body = person.get("/api/timeline/buckets")
	expect(t, resp, body, http.StatusServiceUnavailable)
	resp, body = admin.get("/api/timeline/buckets")
	expect(t, resp, body, http.StatusOK)
	resp, body = s.client().get("/api/auth/status")
	expect(t, resp, body, http.StatusOK)
	resp, body = s.client().post("/api/auth/login", api.LoginRequest{Email: "person@example.com", Password: testPassword})
	expect(t, resp, body, http.StatusForbidden)
	// Signing in still works for an administrator, who can turn it off.
	resp, body = s.client().post("/api/auth/login", api.LoginRequest{Email: "admin@example.com", Password: testPassword})
	expect(t, resp, body, http.StatusOK)

	settings.Maintenance = false
	resp, body = admin.send(http.MethodPut, "/api/admin/server-settings", settings)
	expect(t, resp, body, http.StatusOK)
	resp, body = person.get("/api/timeline/buckets")
	expect(t, resp, body, http.StatusOK)
}
