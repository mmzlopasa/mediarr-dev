package app

import (
	"archive/zip"
	"bytes"
	"context"
	"encoding/binary"
	"encoding/json"
	"net/http"
	"os"
	"path/filepath"
	"slices"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
	"github.com/mediarr-app/mediarr/server/internal/storage"
)

func (s *stack) exportOptions(limit int64) jobs.Options {
	return jobs.Options{LibraryPath: s.library, CachePath: s.cache, ExternalPath: s.external, ExportPartLimit: limit}
}

func (c *client) startExport(t *testing.T, payload map[string]any) api.LibraryExport {
	t.Helper()
	resp, body := c.post("/api/exports", payload)
	expect(t, resp, body, http.StatusCreated)
	return decode[api.LibraryExport](t, body)
}

// runExport runs the job as the worker would, at most parts parts at a time (all when 0).
func (s *stack) runExport(t *testing.T, id uuid.UUID, limit int64, parts int) bool {
	t.Helper()
	finished, err := jobs.ExportOnce(context.Background(), s.pool, s.exportOptions(limit), id, parts)
	if err != nil {
		t.Fatal(err)
	}
	return finished
}

func (c *client) export(t *testing.T, id uuid.UUID) api.LibraryExport {
	t.Helper()
	resp, body := c.get("/api/exports/" + id.String())
	expect(t, resp, body, http.StatusOK)
	return decode[api.LibraryExport](t, body)
}

// unpack downloads every part and puts what they hold together, as unpacking them into one folder
// does. A name in two parts fails the test.
func (c *client) unpack(t *testing.T, export api.LibraryExport) map[string][]byte {
	t.Helper()
	out := map[string][]byte{}
	if len(export.Parts) == 0 {
		t.Fatalf("no parts: %+v", export)
	}
	for _, part := range export.Parts {
		resp, body := c.get("/api/exports/" + export.Id.String() + "/parts/" + strconv.Itoa(int(part.Number)))
		expect(t, resp, body, http.StatusOK)
		if resp.Header.Get("Content-Type") != "application/zip" || !strings.Contains(resp.Header.Get("Content-Disposition"), "part-") {
			t.Fatalf("headers of a part: %v", resp.Header)
		}
		if int64(len(body)) != part.Size {
			t.Fatalf("part %d is %d bytes, and said %d", part.Number, len(body), part.Size)
		}
		archive, err := zip.NewReader(bytes.NewReader(body), int64(len(body)))
		if err != nil {
			t.Fatal(err)
		}
		for _, file := range archive.File {
			if file.Method != zip.Store {
				t.Errorf("%s is compressed", file.Name)
			}
			if _, twice := out[file.Name]; twice {
				t.Errorf("%s is in two parts", file.Name)
			}
			reader, err := file.Open()
			if err != nil {
				t.Fatal(err)
			}
			var data bytes.Buffer
			if _, err := data.ReadFrom(reader); err != nil {
				t.Fatal(err)
			}
			_ = reader.Close()
			out[file.Name] = data.Bytes()
		}
	}
	return out
}

// webpHeader is the start of a lossless WebP of the given size, which is all a preview's size is
// read from.
func webpHeader(width, height uint32) []byte {
	data := []byte("RIFF\x12\x00\x00\x00WEBPVP8L\x05\x00\x00\x00\x2f")
	size := make([]byte, 4)
	binary.LittleEndian.PutUint32(size, (width-1)|(height-1)<<14)
	return append(append(data, size...), 0)
}

type exportedAsset struct {
	ID           string   `json:"id"`
	File         *string  `json:"file"`
	Sidecar      *string  `json:"sidecar"`
	OriginalName string   `json:"originalName"`
	SHA256       string   `json:"sha256"`
	Description  string   `json:"description"`
	Rating       int      `json:"rating"`
	Pick         *string  `json:"pick"`
	Favorite     bool     `json:"favorite"`
	Tags         []string `json:"tags"`
	Albums       []string `json:"albums"`
	Latitude     *float64 `json:"latitude"`
	TakenAt      *string  `json:"takenAt"`
	Faces        []struct {
		PersonID *string `json:"personId"`
		Person   string  `json:"person"`
		Box      *struct {
			X1, Y1, X2, Y2 float64
		} `json:"box"`
	} `json:"faces"`
	Edits json.RawMessage `json:"edits"`
}

type exportedLibrary struct {
	Format string `json:"format"`
	Owner  struct {
		Email string `json:"email"`
	} `json:"owner"`
	People []struct {
		ID   string `json:"id"`
		Name string `json:"name"`
	} `json:"people"`
	Tags   []string        `json:"tags"`
	Assets []exportedAsset `json:"assets"`
	Albums []struct {
		ID     string   `json:"id"`
		Title  string   `json:"title"`
		Folder string   `json:"folder"`
		Assets []string `json:"assets"`
	} `json:"albums"`
}

func TestExportHoldsTheWholeLibraryAndNothingElse(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	owner := s.user(admin, "owner@example.com")
	other := s.user(admin, "other@example.com")
	ownerID := s.userID("owner@example.com")

	first, second, clip := randomBytes(t, 3000), randomBytes(t, 2000), randomBytes(t, 1500)
	one := uploadedID(t, owner.upload("IMG_1.jpg", first, nil))
	preview := s.markReady(t, one, "2024-07-01T10:00:00Z", nil)
	two := uploadedID(t, owner.upload("img_1.JPG", second, nil))
	s.markReady(t, two, "2024-07-02T10:00:00Z", nil)
	three := uploadedID(t, owner.upload("clip.mp4", clip, nil))
	s.markReady(t, three, "2023-01-05T10:00:00Z", nil)
	theirs := uploadedID(t, other.upload("secret-of-other.jpg", randomBytes(t, 500), nil))
	s.markReady(t, theirs, "2024-07-01T10:00:00Z", nil)

	// What Mediarr knows about the first photo.
	sidecar := filepath.Join(storage.SidecarDir(s.library), ownerID, one[:2], one+".xmp")
	sidecarData := []byte("<x:xmpmeta>rating 4</x:xmpmeta>")
	if err := os.MkdirAll(filepath.Dir(sidecar), 0o750); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(sidecar, sidecarData, 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(preview, webpHeader(400, 200), 0o600); err != nil {
		t.Fatal(err)
	}
	s.exec(t, `INSERT INTO asset_files (asset_id, kind, path, size_bytes) VALUES ($1, 'sidecar', $2, 10)`, one, sidecar)
	s.exec(t, `UPDATE assets SET caption = 'Sunset at the pier', rating = 4, pick = 1, is_favorite = true,
		edits = '{"rotate":90}' WHERE id = $1`, one)
	s.exec(t, `INSERT INTO exif (asset_id, latitude, longitude, city, country, raw) VALUES ($1, 45.8, 15.9, 'Zagreb', 'Croatia', '{}')`, one)
	s.exec(t, `INSERT INTO people (id, user_id, name) VALUES ('11111111-1111-4111-8111-111111111111', $1, 'Ana')`, ownerID)
	s.exec(t, `INSERT INTO faces (asset_id, user_id, person_id, x1, y1, x2, y2, score, embedding)
		VALUES ($1, $2, '11111111-1111-4111-8111-111111111111', 100, 50, 200, 150, 0.9, array_fill(0.1::real, ARRAY[512])::vector)`, one, ownerID)
	resp, body := owner.post("/api/assets/tags", map[string]any{"ids": []string{one}, "name": "holiday"})
	expect(t, resp, body, http.StatusOK)

	// An album with a nested one, shared with someone who adds a photo of their own.
	trip := owner.newAlbum(map[string]any{"title": "Trip"})
	day := owner.newAlbum(map[string]any{"title": "Day 1"})
	s.exec(t, `UPDATE albums SET parent_id = $1 WHERE id = $2`, trip, day)
	resp, body = owner.post("/api/albums/"+trip+"/assets", map[string]any{"ids": []string{one, two}})
	expect(t, resp, body, http.StatusOK)
	resp, body = owner.post("/api/albums/"+day+"/assets", map[string]any{"ids": []string{one}})
	expect(t, resp, body, http.StatusOK)
	resp, body = owner.send(http.MethodPut, "/api/albums/"+trip+"/members/"+s.userID("other@example.com"), map[string]string{"role": "contributor"})
	expect(t, resp, body, http.StatusNoContent)
	resp, body = other.post("/api/albums/"+trip+"/assets", map[string]any{"ids": []string{theirs}})
	expect(t, resp, body, http.StatusOK)
	// The trash and the locked folder stay out.
	trashed := owner.newPhoto(t, "trashed.jpg", "2024-07-03T10:00:00Z")
	s.exec(t, `UPDATE assets SET deleted_at = now() WHERE id = $1`, trashed)
	locked := owner.newPhoto(t, "locked.jpg", "2024-07-03T10:00:00Z")
	s.exec(t, `UPDATE assets SET vault_at = now() WHERE id = $1`, locked)

	started := owner.startExport(t, map[string]any{})
	if started.Status != api.LibraryExportStatusRunning || started.StartedByAdmin || !started.CanDownload {
		t.Fatalf("started: %+v", started)
	}
	if !s.runExport(t, started.Id, 0, 0) {
		t.Fatal("the export did not finish")
	}
	done := owner.export(t, started.Id)
	if done.Status != api.LibraryExportStatusDone || done.TotalFiles != 3 || done.DoneFiles != 3 || done.ExpiresAt == nil ||
		time.Until(*done.ExpiresAt) < 6*24*time.Hour {
		t.Fatalf("done: %+v", done)
	}
	files := owner.unpack(t, done)

	// Originals as they were uploaded, two of the same name apart, sidecar beside its photo. The one
	// first by id keeps the name.
	firstName, secondName := "originals/2024/07/IMG_1.jpg", "originals/2024/07/img_1 (2).JPG"
	if two < one {
		firstName, secondName = "originals/2024/07/IMG_1 (2).jpg", "originals/2024/07/img_1.JPG"
	}
	for name, want := range map[string][]byte{
		firstName: first, secondName: second, "originals/2023/01/clip.mp4": clip, firstName + ".xmp": sidecarData,
	} {
		if !bytes.Equal(files[name], want) {
			t.Errorf("%s: %d bytes, want %d", name, len(files[name]), len(want))
		}
	}
	for name, data := range files {
		if strings.Contains(name, "secret-of-other") || strings.Contains(name, "trashed") || strings.Contains(name, "locked") ||
			bytes.Contains(data, []byte("secret-of-other")) {
			t.Errorf("%s should not be in the export", name)
		}
	}

	var trip1 struct {
		Title string   `json:"title"`
		Files []string `json:"files"`
	}
	if err := json.Unmarshal(files["albums/Trip/album.json"], &trip1); err != nil {
		t.Fatal(err, string(files["albums/Trip/album.json"]))
	}
	slices.Sort(trip1.Files)
	wantTrip := []string{firstName, secondName}
	slices.Sort(wantTrip)
	if trip1.Title != "Trip" || !slices.Equal(trip1.Files, wantTrip) {
		t.Fatalf("album: %+v", trip1)
	}
	if !bytes.Contains(files["albums/Trip/Day 1/album.json"], []byte(`"`+firstName+`"`)) {
		t.Fatalf("nested album: %s", files["albums/Trip/Day 1/album.json"])
	}
	if !bytes.Contains(files["README.txt"], []byte("Unpack every part")) {
		t.Fatal("no README")
	}

	metadata := files[jobs.ExportMetadataName]
	var library exportedLibrary
	if err := json.Unmarshal(metadata, &library); err != nil {
		t.Fatal(err, string(metadata))
	}
	if library.Format != "mediarr-export" || library.Owner.Email != "owner@example.com" || len(library.Assets) != 3 ||
		len(library.People) != 1 || library.People[0].Name != "Ana" || !slices.Equal(library.Tags, []string{"holiday"}) {
		t.Fatalf("library: %s", metadata)
	}
	var photo *exportedAsset
	for i := range library.Assets {
		if library.Assets[i].ID == one {
			photo = &library.Assets[i]
		}
	}
	if photo == nil || photo.File == nil || *photo.File != firstName || photo.Sidecar == nil ||
		photo.Description != "Sunset at the pier" || photo.Rating != 4 || photo.Pick == nil || *photo.Pick != "picked" ||
		!photo.Favorite || !slices.Equal(photo.Tags, []string{"holiday"}) || len(photo.Albums) != 2 ||
		photo.Latitude == nil || *photo.Latitude != 45.8 || photo.TakenAt == nil || string(photo.Edits) != `{"rotate":90}` {
		t.Fatalf("photo: %+v %s", photo, photo.Edits)
	}
	if len(photo.Faces) != 1 || photo.Faces[0].Person != "Ana" || photo.Faces[0].Box == nil ||
		photo.Faces[0].Box.X1 != 0.25 || photo.Faces[0].Box.Y2 != 0.75 {
		t.Fatalf("faces: %+v", photo.Faces)
	}
	for _, album := range library.Albums {
		if album.Title == "Trip" && (album.Folder != "albums/Trip" || len(album.Assets) != 2 || slices.Contains(album.Assets, theirs)) {
			t.Fatalf("album in the metadata: %+v", album)
		}
	}
	// Never anything that lets someone in.
	var hash string
	if err := s.pool.QueryRow(context.Background(), "SELECT password_hash FROM users WHERE email = 'owner@example.com'").Scan(&hash); err != nil {
		t.Fatal(err)
	}
	lower := strings.ToLower(string(metadata))
	for _, secret := range []string{hash, "password", "token", "secret", "session", "other@example.com"} {
		if strings.Contains(lower, strings.ToLower(secret)) {
			t.Errorf("the metadata holds %q", secret)
		}
	}
	// The list of files is no longer needed.
	var left int
	if err := s.pool.QueryRow(context.Background(), "SELECT count(*) FROM export_files").Scan(&left); err != nil || left != 0 {
		t.Fatalf("export_files left: %d %v", left, err)
	}
}

func TestExportSplitsIntoPartsAndGoesOnAfterARestart(t *testing.T) {
	s := newStack(t)
	owner := s.admin()
	originals := map[string][]byte{}
	for n := range 5 {
		name := "photo-" + strconv.Itoa(n) + ".jpg"
		data := randomBytes(t, 3000)
		id := uploadedID(t, owner.upload(name, data, nil))
		s.markReady(t, id, "2024-05-0"+strconv.Itoa(n+1)+"T10:00:00Z", nil)
		originals["originals/2024/05/"+name] = data
	}
	const limit = 7000
	started := owner.startExport(t, map[string]any{})

	// The worker stops after the first part, and had begun the second.
	if s.runExport(t, started.Id, limit, 1) {
		t.Fatal("the export finished in one part")
	}
	partway := owner.export(t, started.Id)
	if partway.Status != api.LibraryExportStatusRunning || partway.DoneFiles != 2 || len(partway.Parts) != 0 {
		t.Fatalf("part way: %+v", partway)
	}
	dir := jobs.ExportDir(s.cache, pgUUID(started.Id))
	leftover := filepath.Join(dir, "part-002.zip.partial")
	if err := os.WriteFile(leftover, []byte("cut off"), 0o600); err != nil {
		t.Fatal(err)
	}
	if !s.runExport(t, started.Id, limit, 0) {
		t.Fatal("the export did not finish after the restart")
	}
	if _, err := os.Stat(leftover); !os.IsNotExist(err) {
		t.Fatal("the unfinished part was left behind")
	}
	done := owner.export(t, started.Id)
	if done.Status != api.LibraryExportStatusDone || done.DoneFiles != 5 || len(done.Parts) < 3 {
		t.Fatalf("done: %+v", done)
	}
	for _, part := range done.Parts {
		if part.Size > limit {
			t.Errorf("part %d is %d bytes", part.Number, part.Size)
		}
	}
	files := owner.unpack(t, done)
	for name, data := range originals {
		if !bytes.Equal(files[name], data) {
			t.Errorf("%s is not as uploaded", name)
		}
	}
	if len(files[jobs.ExportMetadataName]) == 0 {
		t.Fatal("no metadata")
	}
}

func TestExportIsCancelledAndCleanedUpAfterAWeek(t *testing.T) {
	s := newStack(t)
	owner := s.admin()
	for n := range 3 {
		id := uploadedID(t, owner.upload("p"+strconv.Itoa(n)+".jpg", randomBytes(t, 3000), nil))
		s.markReady(t, id, "2024-05-01T10:00:00Z", nil)
	}
	started := owner.startExport(t, map[string]any{})
	resp, body := owner.post("/api/exports", map[string]any{})
	expect(t, resp, body, http.StatusConflict)
	s.runExport(t, started.Id, 4000, 1)
	dir := jobs.ExportDir(s.cache, pgUUID(started.Id))
	if _, err := os.Stat(filepath.Join(dir, "part-001.zip")); err != nil {
		t.Fatal(err)
	}
	resp, body = owner.post("/api/exports/"+started.Id.String()+"/cancel", nil)
	expect(t, resp, body, http.StatusNoContent)
	if !s.runExport(t, started.Id, 4000, 0) {
		t.Fatal("a cancelled export goes on")
	}
	if _, err := os.Stat(dir); !os.IsNotExist(err) {
		t.Fatal("the parts of a cancelled export are still there")
	}
	if got := owner.export(t, started.Id); got.Status != api.LibraryExportStatusCancelled {
		t.Fatalf("cancelled: %+v", got)
	}
	resp, body = owner.post("/api/exports/"+started.Id.String()+"/cancel", nil)
	expect(t, resp, body, http.StatusConflict)
	resp, body = owner.send(http.MethodDelete, "/api/exports/"+started.Id.String(), nil)
	expect(t, resp, body, http.StatusNoContent)

	// A finished export is kept for a week, and then its parts go.
	again := owner.startExport(t, map[string]any{})
	s.runExport(t, again.Id, 0, 0)
	dir = jobs.ExportDir(s.cache, pgUUID(again.Id))
	stray := filepath.Join(s.cache, "exports", uuid.NewString())
	if err := os.MkdirAll(stray, 0o750); err != nil {
		t.Fatal(err)
	}
	queries := db.New(s.pool)
	if err := jobs.CleanExports(context.Background(), queries, s.cache, time.Now().Add(6*24*time.Hour)); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(dir); err != nil {
		t.Fatal("removed before the week was over")
	}
	if _, err := os.Stat(stray); !os.IsNotExist(err) {
		t.Fatal("a folder of no export stays")
	}
	if err := jobs.CleanExports(context.Background(), queries, s.cache, time.Now().Add(8*24*time.Hour)); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(dir); !os.IsNotExist(err) {
		t.Fatal("the parts are still there after a week")
	}
	gone := owner.export(t, again.Id)
	if gone.Status != api.LibraryExportStatusRemoved || len(gone.Parts) != 0 {
		t.Fatalf("after a week: %+v", gone)
	}
	resp, body = owner.get("/api/exports/" + again.Id.String() + "/parts/1")
	expect(t, resp, body, http.StatusNotFound)
}

func TestExportPartsDownloadInRanges(t *testing.T) {
	s := newStack(t)
	owner := s.admin()
	id := uploadedID(t, owner.upload("a.jpg", randomBytes(t, 5000), nil))
	s.markReady(t, id, "2024-05-01T10:00:00Z", nil)
	started := owner.startExport(t, map[string]any{})
	s.runExport(t, started.Id, 0, 0)
	path := "/api/exports/" + started.Id.String() + "/parts/1"
	_, whole := owner.get(path)
	resp, body := owner.do(http.MethodGet, path, map[string]string{"Range": "bytes=100-199"}, nil)
	expect(t, resp, body, http.StatusPartialContent)
	if !bytes.Equal(body, whole[100:200]) || !strings.HasPrefix(resp.Header.Get("Content-Range"), "bytes 100-199/") {
		t.Fatalf("range: %d bytes, %s", len(body), resp.Header.Get("Content-Range"))
	}
	resp, body = owner.get("/api/exports/" + started.Id.String() + "/parts/2")
	expect(t, resp, body, http.StatusNotFound)
}

func TestExportRights(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	user := s.user(admin, "user@example.com")
	stranger := s.user(admin, "stranger@example.com")
	resp, body := admin.post("/api/admin/users", api.CreateUserRequest{Email: "second@example.com", Name: "Second", Password: testPassword, IsAdmin: true})
	expect(t, resp, body, http.StatusCreated)
	second := s.client()
	resp, body = second.post("/api/auth/login", api.LoginRequest{Email: "second@example.com", Password: testPassword})
	expect(t, resp, body, http.StatusOK)
	userID := s.userID("user@example.com")
	photo := uploadedID(t, user.upload("mine.jpg", randomBytes(t, 2000), nil))
	s.markReady(t, photo, "2024-05-01T10:00:00Z", nil)

	// Only an administrator exports someone else's library.
	resp, body = stranger.post("/api/exports", map[string]any{"userId": userID})
	expect(t, resp, body, http.StatusForbidden)
	started := admin.startExport(t, map[string]any{"userId": userID})
	if !started.StartedByAdmin || started.StartedBy != "Admin" || started.UserEmail != "user@example.com" {
		t.Fatalf("started for someone: %+v", started)
	}
	// The real worker takes it from the queue.
	s.startWorker(t)
	deadline := time.Now().Add(30 * time.Second)
	for admin.export(t, started.Id).Status == api.LibraryExportStatusRunning {
		if time.Now().After(deadline) {
			t.Fatal("the worker did not finish the export")
		}
		time.Sleep(100 * time.Millisecond)
	}

	// The owner sees it among their own, and who started it.
	resp, body = user.get("/api/exports")
	expect(t, resp, body, http.StatusOK)
	mine := decode[[]api.LibraryExport](t, body)
	if len(mine) != 1 || !mine[0].StartedByAdmin || !mine[0].CanDownload || mine[0].Status != api.LibraryExportStatusDone {
		t.Fatalf("the owner's list: %s", body)
	}
	resp, body = admin.get("/api/admin/exports")
	expect(t, resp, body, http.StatusOK)
	if all := decode[[]api.LibraryExport](t, body); len(all) != 1 || !all[0].CanDownload {
		t.Fatalf("the administrator's list: %s", body)
	}
	resp, body = user.get("/api/admin/exports")
	expect(t, resp, body, http.StatusForbidden)

	part := "/api/exports/" + started.Id.String() + "/parts/1"
	for _, c := range []*client{user, admin} {
		resp, body = c.get(part)
		expect(t, resp, body, http.StatusOK)
	}
	// Another administrator follows it, and does not get the photos.
	resp, body = second.get("/api/exports/" + started.Id.String())
	expect(t, resp, body, http.StatusOK)
	if decode[api.LibraryExport](t, body).CanDownload {
		t.Fatal("another administrator may download")
	}
	resp, body = second.get(part)
	expect(t, resp, body, http.StatusForbidden)
	// Someone else does not even learn it exists.
	for _, path := range []string{"/api/exports/" + started.Id.String(), part} {
		resp, body = stranger.get(path)
		expect(t, resp, body, http.StatusNotFound)
	}
	resp, body = stranger.send(http.MethodDelete, "/api/exports/"+started.Id.String(), nil)
	expect(t, resp, body, http.StatusNotFound)

	// Without room on the disk the export does not start, and says why.
	s.exec(t, `UPDATE assets SET size_bytes = $2 WHERE id = $1`, photo, int64(1)<<60)
	resp, body = user.post("/api/exports", map[string]any{})
	expect(t, resp, body, http.StatusInsufficientStorage)
	if !strings.Contains(string(body), "not enough free space") {
		t.Fatalf("the reason: %s", body)
	}
}
