package app

import (
	"context"
	"net/http"
	"strconv"
	"testing"
	"time"

	"github.com/mediarr-app/mediarr/server/internal/api"
)

func TestAQuotaStopsUploadsOfThatUserOnly(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	user := s.user(admin, "user@example.com")
	id := s.userID("user@example.com")
	resp, body := admin.send(http.MethodPut, "/api/admin/users/"+id+"/quota", map[string]any{"quotaBytes": 150})
	expect(t, resp, body, http.StatusNoContent)

	if got := user.upload("a.jpg", randomBytes(t, 100), nil); got.StatusCode != http.StatusNoContent {
		t.Fatalf("under the quota: %d", got.StatusCode)
	}
	over, overBody := user.do(http.MethodPost, "/api/uploads", map[string]string{"Tus-Resumable": "1.0.0", "Upload-Length": "100"}, nil)
	expect(t, over, overBody, http.StatusRequestEntityTooLarge)
	// Someone else is not affected.
	if got := admin.upload("c.jpg", randomBytes(t, 100), nil); got.StatusCode != http.StatusNoContent {
		t.Fatalf("another user: %d", got.StatusCode)
	}

	resp, body = admin.get("/api/admin/storage")
	expect(t, resp, body, http.StatusOK)
	found := false
	for _, row := range decode[[]api.UserStorage](t, body) {
		if row.Email == "user@example.com" {
			found = row.StoredBytes == 100 && row.QuotaBytes != nil && *row.QuotaBytes == 150
		}
	}
	if !found {
		t.Fatalf("%s", body)
	}

	// Taking the quota away lets it through again.
	resp, body = admin.send(http.MethodPut, "/api/admin/users/"+id+"/quota", map[string]any{})
	expect(t, resp, body, http.StatusNoContent)
	if got := user.upload("b.jpg", randomBytes(t, 100), nil); got.StatusCode != http.StatusNoContent {
		t.Fatalf("without a quota: %d", got.StatusCode)
	}
	resp, body = admin.send(http.MethodPut, "/api/admin/users/"+id+"/quota", map[string]any{"quotaBytes": -1})
	expect(t, resp, body, http.StatusBadRequest)
}

func TestAPausedQueueWaitsAndThenContinues(t *testing.T) {
	s := newStack(t)
	s.startWorker(t)
	c := s.admin()
	// The worker registers its queues when it starts.
	time.Sleep(time.Second)
	resp, body := c.post("/api/admin/jobs/queues/default/pause", map[string]any{})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = c.post("/api/admin/jobs/queues/nonsense/pause", map[string]any{})
	expect(t, resp, body, http.StatusNotFound)
	resp, body = c.get("/api/admin/jobs")
	expect(t, resp, body, http.StatusOK)
	paused := false
	for _, queue := range decode[api.AdminJobs](t, body).Queues {
		if queue.Name == "default" {
			paused = queue.Paused
		}
	}
	if !paused {
		t.Fatalf("%s", body)
	}
	time.Sleep(2 * time.Second)

	id := uploadedID(t, c.upload("a.jpg", landscapeJPEG(t), nil))
	time.Sleep(3 * time.Second)
	if status := c.detail(id).Status; status != api.AssetDetailStatusProcessing {
		t.Fatalf("worked while paused: %s", status)
	}
	resp, body = c.post("/api/admin/jobs/queues/default/resume", map[string]any{})
	expect(t, resp, body, http.StatusNoContent)
	end := time.Now().Add(30 * time.Second)
	for c.detail(id).Status != api.AssetDetailStatusReady {
		if time.Now().After(end) {
			t.Fatal("it never continued")
		}
		time.Sleep(200 * time.Millisecond)
	}
}

func TestAFailedJobCanBeTriedAgain(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	ctx := context.Background()
	var id int64
	if err := s.pool.QueryRow(ctx, `INSERT INTO river_job (kind, args, state, attempt, max_attempts, attempted_at, finalized_at, queue, priority, errors)
		VALUES ('cleanup', '{}', 'discarded', 5, 5, now(), now(), 'default', 1,
		        ARRAY['{"error":"the disk was full","attempt":5}'::jsonb]) RETURNING id`).Scan(&id); err != nil {
		t.Fatal(err)
	}
	resp, body := c.get("/api/admin/jobs")
	expect(t, resp, body, http.StatusOK)
	failed := decode[api.AdminJobs](t, body).Failed
	if len(failed) != 1 || failed[0].Error != "the disk was full" {
		t.Fatalf("%s", body)
	}
	resp, body = c.post("/api/admin/jobs/"+strconv.FormatInt(id, 10)+"/retry", map[string]any{})
	expect(t, resp, body, http.StatusNoContent)
	var state string
	if err := s.pool.QueryRow(ctx, "SELECT state::text FROM river_job WHERE id=$1", id).Scan(&state); err != nil {
		t.Fatal(err)
	}
	if state != "available" {
		t.Fatalf("state: %s", state)
	}
	resp, body = c.post("/api/admin/jobs/999999/retry", map[string]any{})
	expect(t, resp, body, http.StatusNotFound)
}

func TestHealthTellsWhatIsRunning(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	resp, body := c.get("/api/admin/health")
	expect(t, resp, body, http.StatusOK)
	health := decode[api.AdminHealth](t, body)
	if health.WorkerRunning || health.MlEnabled || health.DatabaseBytes <= 0 {
		t.Fatalf("no worker has run here: %s", body)
	}
}

func TestADryRunChangesNothing(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	other := s.user(c, "other@example.com")
	a := c.newPhoto(t, "a.jpg", "2024-01-01T10:00:00Z")
	b := c.newPhoto(t, "b.jpg", "2024-01-02T10:00:00Z")
	foreign := other.newPhoto(t, "c.jpg", "2024-01-03T10:00:00Z")

	resp, body := c.post("/api/assets/bulk", map[string]any{"ids": []string{a, b, foreign}, "action": "delete", "dryRun": true})
	if got := changedBy(t, resp, body); got != 2 {
		t.Fatalf("would change %d", got)
	}
	if got := len(timelineOf(t, c)); got != 2 {
		t.Fatalf("something was deleted: %d left", got)
	}

	c.bulk(t, "delete", a)
	resp, body = c.get("/api/trash/summary")
	expect(t, resp, body, http.StatusOK)
	summary := decode[api.TrashSummary](t, body)
	if summary.Assets != 1 || summary.Bytes != 100 {
		t.Fatalf("%s", body)
	}
}
