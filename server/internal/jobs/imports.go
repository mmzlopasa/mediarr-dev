package jobs

import (
	"context"
	"crypto/sha1" //nolint:gosec // Immich names its files by SHA-1, which is checked here only against damage.
	"encoding/base64"
	"encoding/csv"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"math"
	"net"
	"net/http"
	"net/url"
	"os"
	"path"
	"path/filepath"
	"slices"
	"strconv"
	"strings"
	"syscall"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/riverqueue/river"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/storage"
)

const (
	importQueue    = "import"
	importSlice    = 6 * time.Hour
	immichPageSize = 250
	// importRequestWait is how long the other server may stay silent: before its answer starts, and
	// between two pieces of a body, so one that stops halfway does not hold the import queue forever.
	importRequestWait   = 2 * time.Minute
	maxImportError      = 400
	foreignKeyViolation = "23503"
	fingerprintBatch    = 500
	maxImportAnswer     = 64 << 20
	maxSidecarBytes     = 1 << 20
	maxImportPages      = 200000
	minImportFree       = 2 << 30
	statusDone          = "done"
	statusFailed        = "failed"
	sourceImmich        = "immich"
	sourceTakeout       = "takeout"
	sourceICloud        = "icloud"
	kindAlbum           = "album"
	kindPerson          = "person"
)

// ImportArgs brings a library in from somewhere else.
type ImportArgs struct {
	ImportID uuid.UUID `json:"import_id"`
}

// Kind identifies the job in the queue.
func (ImportArgs) Kind() string { return "import" }

// InsertOpts gives imports a queue of their own, because they run for hours.
func (ImportArgs) InsertOpts() river.InsertOpts { return river.InsertOpts{Queue: importQueue} }

type importWorker struct {
	river.WorkerDefaults[ImportArgs]
	*deps
}

// Timeout is above importSlice, because the job pauses itself before it would run out.
func (w *importWorker) Timeout(*river.Job[ImportArgs]) time.Duration { return importSlice + time.Hour }

// errImportRefused is what trying again cannot fix, such as a wrong key.
type errImportRefused struct{ message string }

func (e *errImportRefused) Error() string { return e.message }

var errImportStopped = errors.New("the import was cancelled")

func (w *importWorker) Work(ctx context.Context, job *river.Job[ImportArgs]) error {
	id := toPG(job.Args.ImportID)
	row, err := w.queries.GetImport(ctx, id)
	if db.IsNotFound(err) {
		return river.JobCancel(err)
	}
	if err != nil {
		return err
	}
	if row.Status != "running" {
		return nil
	}
	slice, cancel := context.WithTimeout(ctx, importSlice)
	defer cancel()
	run := &importRun{deps: w.deps, row: &row, origin: row.Source + ":" + row.Address + row.Folder}
	switch row.Source {
	case sourceImmich:
		err = run.immich(slice)
	case sourceTakeout, sourceICloud:
		err = run.export(slice)
	default:
		err = &errImportRefused{"unknown source"}
	}
	var refused *errImportRefused
	switch {
	case err == nil:
		notifyImport(context.WithoutCancel(ctx), w.queries, &row, statusDone)
		if row.FromZip {
			// Everything is in, so the ZIP files are no longer needed.
			removeImportParts(context.WithoutCancel(ctx), w.queries, w.opts.LibraryPath, id)
		}
		return w.finishImport(ctx, id, statusDone, "")
	case errors.Is(err, errImportStopped):
		return nil
	case errors.As(err, &refused):
		notifyImport(context.WithoutCancel(ctx), w.queries, &row, statusFailed)
		return w.finishImport(ctx, id, statusFailed, refused.message)
	case slice.Err() != nil && ctx.Err() == nil:
		// A long import goes on in a new run, from the page it reached, without using up attempts.
		return river.JobSnooze(time.Second)
	case job.Attempt >= maxAttempts:
		notifyImport(context.WithoutCancel(ctx), w.queries, &row, statusFailed)
		return w.finishImport(ctx, id, statusFailed, truncate(err.Error(), maxImportError))
	}
	return err
}

// export reads a Takeout or iCloud export, from a folder or from the user's ZIP files.
func (i *importRun) export(ctx context.Context) error {
	tree, err := i.tree(ctx)
	if err != nil {
		return err
	}
	defer func() { _ = tree.close() }()
	if i.row.Source == sourceICloud {
		return i.icloud(ctx, tree)
	}
	return i.takeout(ctx, tree)
}

// ImportPartsDir is where the ZIP files of an import wait, on the same disk as the library.
func ImportPartsDir(library string, id pgtype.UUID) string {
	return filepath.Join(library, ".imports", uuidString(id))
}

// removeImportParts deletes an import's ZIP files and their records.
func removeImportParts(ctx context.Context, q *db.Queries, library string, id pgtype.UUID) {
	if err := os.RemoveAll(ImportPartsDir(library, id)); err != nil {
		slog.Warn("the ZIP files of an import could not be removed", "import", uuidString(id), "error", err)
		return
	}
	if err := q.DeleteImportParts(ctx, id); err != nil {
		slog.Warn("the ZIP files of an import could not be forgotten", "import", uuidString(id), "error", err)
	}
}

// RemoveStaleImports deletes the ZIP files of imports nobody came back to in a week. One that was
// still waiting for its files is then stopped.
func RemoveStaleImports(ctx context.Context, q *db.Queries, library string) error {
	stale, err := q.ListStaleZipImports(ctx)
	if err != nil {
		return err
	}
	for _, id := range stale {
		removeImportParts(ctx, q, library, id)
		if _, err := q.StopImport(ctx, id); err != nil {
			return err
		}
	}
	return nil
}

func (w *importWorker) finishImport(ctx context.Context, id pgtype.UUID, status, message string) error {
	return w.queries.FinishImport(context.WithoutCancel(ctx), db.FinishImportParams{ID: id, Status: status, Column3: message})
}

type importRun struct {
	*deps
	row    *db.Import
	origin string
}

// importItem is one file, with what the place it came from knows about it.
type importItem struct {
	name      string
	takenAt   *time.Time
	latitude  *float64
	longitude *float64
	favorite  bool
	archived  bool
	albums    []pgtype.UUID
	caption   string
	// offset is the time zone in minutes, when the source or the place says it.
	offset *int32
}

func (i *importRun) count(ctx context.Context, added, skipped, failed int32, problem string) error {
	return i.queries.AddImportCounts(ctx, db.AddImportCountsParams{
		ID: i.row.ID, Added: added, Skipped: skipped, Failed: failed, LastError: truncate(problem, maxImportError),
	})
}

// stillRunning lets a cancel from the admin stop the import between two files.
func (i *importRun) stillRunning(ctx context.Context) error {
	row, err := i.queries.GetImport(ctx, i.row.ID)
	if err != nil {
		return err
	}
	if row.Status != "running" {
		return errImportStopped
	}
	return nil
}

// store takes over a complete temporary file. A file the user already has gets no new record, and
// what they deleted stays deleted.
func (i *importRun) store(ctx context.Context, tmp string, item *importItem) (pgtype.UUID, bool, error) {
	var id pgtype.UUID
	sum, err := hashFile(tmp)
	if err != nil {
		return id, false, err
	}
	info, err := os.Stat(tmp)
	if err != nil {
		return id, false, err
	}
	when := time.Now()
	if item.takenAt != nil {
		when = *item.takenAt
	}
	dest := storage.OriginalPath(i.opts.LibraryPath, uuidString(i.row.UserID), when, hex.EncodeToString(sum), item.name)
	isNew := false
	err = pgx.BeginFunc(ctx, i.pool, func(tx pgx.Tx) error {
		q := i.queries.WithTx(tx)
		if err := q.CreateUploadLibrary(ctx, i.row.UserID); err != nil {
			return err
		}
		library, err := q.GetUploadLibrary(ctx, i.row.UserID)
		if err != nil {
			return err
		}
		id, err = q.InsertAsset(ctx, db.InsertAssetParams{
			UserID: i.row.UserID, LibraryID: library, Checksum: sum,
			OriginalName: storage.SafeName(item.name), OriginalPath: dest, SizeBytes: info.Size(),
		})
		if db.IsNotFound(err) {
			id, err = q.GetAssetIDByChecksum(ctx, db.GetAssetIDByChecksumParams{UserID: i.row.UserID, Checksum: sum})
			return err
		}
		if err != nil {
			return err
		}
		isNew = true
		facts := db.SetImportFactsParams{ID: id}
		if item.takenAt != nil {
			facts.ImportTakenAt = pgtype.Timestamptz{Time: *item.takenAt, Valid: true}
		}
		if item.latitude != nil && item.longitude != nil {
			facts.ImportLatitude = pgtype.Float8{Float64: *item.latitude, Valid: true}
			facts.ImportLongitude = pgtype.Float8{Float64: *item.longitude, Valid: true}
		}
		if item.offset != nil {
			facts.ImportOffsetMinutes = pgtype.Int4{Int32: *item.offset, Valid: true}
		}
		facts.Caption = item.caption
		if err := q.SetImportFacts(ctx, facts); err != nil {
			return err
		}
		if _, err := i.client().InsertTx(ctx, tx, MetadataArgs{AssetID: id.Bytes}, nil); err != nil {
			return err
		}
		return storage.Publish(tmp, dest)
	})
	if err != nil {
		return id, false, err
	}
	if !isNew {
		_ = os.Remove(tmp)
	}
	// A photo that was already here still gets what the export says about where it belongs. Its date,
	// place and description stay as they are.
	if item.archived {
		if err := i.queries.MarkImportedArchived(ctx, id); err != nil {
			return id, isNew, err
		}
	}
	if item.favorite {
		if err := i.queries.MarkImportedFavorite(ctx, id); err != nil {
			return id, isNew, err
		}
	}
	for _, album := range item.albums {
		if _, err := i.queries.AddAlbumAssets(ctx, db.AddAlbumAssetsParams{AlbumID: album, UserID: i.row.UserID, Ids: []pgtype.UUID{id}}); err != nil {
			return id, isNew, err
		}
	}
	return id, isNew, nil
}

// roomFor stops an import before it fills the disk, which would also stop the database. It is
// refused, not retried, because trying again will not make room.
func (i *importRun) roomFor(size int64) error {
	var disk syscall.Statfs_t
	if err := syscall.Statfs(i.opts.LibraryPath, &disk); err != nil {
		return nil //nolint:nilerr // Then the copy itself fails if the disk is the problem.
	}
	if int64(disk.Bavail)*disk.Bsize-max(size, 0) < minImportFree { //nolint:gosec // Disk sizes fit.
		return &errImportRefused{"the server's disk is nearly full, so the import stopped"}
	}
	return nil
}

func (i *importRun) tempFile() (*os.File, error) {
	dir := storage.TmpDir(i.opts.LibraryPath)
	if err := os.MkdirAll(dir, 0o750); err != nil {
		return nil, err
	}
	return os.CreateTemp(dir, "import-*")
}

func (i *importRun) albumFor(ctx context.Context, remote, title, description string) (pgtype.UUID, error) {
	local, err := i.queries.GetImportMap(ctx, db.GetImportMapParams{UserID: i.row.UserID, Origin: i.origin, Kind: kindAlbum, RemoteID: remote})
	if err == nil {
		return local, nil
	}
	if !db.IsNotFound(err) {
		return local, err
	}
	local, err = i.queries.CreateAlbum(ctx, db.CreateAlbumParams{OwnerID: i.row.UserID, Title: title, Description: description})
	if err != nil {
		return local, err
	}
	return local, i.queries.SetImportMap(ctx, db.SetImportMapParams{UserID: i.row.UserID, Origin: i.origin, Kind: kindAlbum, RemoteID: remote, LocalID: local})
}

// --- Immich, through its public API ---

type immichAsset struct {
	ID               string  `json:"id"`
	OriginalFileName string  `json:"originalFileName"`
	Checksum         string  `json:"checksum"`
	IsFavorite       bool    `json:"isFavorite"`
	Visibility       string  `json:"visibility"`
	IsOffline        bool    `json:"isOffline"`
	FileCreatedAt    string  `json:"fileCreatedAt"`
	LivePhotoVideoID *string `json:"livePhotoVideoId"`
}

type immichSearch struct {
	Assets struct {
		Items    []immichAsset `json:"items"`
		NextPage *string       `json:"nextPage"`
	} `json:"assets"`
}

type immichFace struct {
	X1          float64 `json:"boundingBoxX1"`
	Y1          float64 `json:"boundingBoxY1"`
	X2          float64 `json:"boundingBoxX2"`
	Y2          float64 `json:"boundingBoxY2"`
	ImageWidth  float64 `json:"imageWidth"`
	ImageHeight float64 `json:"imageHeight"`
	Person      *struct {
		ID string `json:"id"`
	} `json:"person"`
}

// importHTTP follows no redirects: it would carry the key along, and fetch whatever it is sent to.
var importHTTP = &http.Client{
	Transport: &http.Transport{
		Proxy:                 http.ProxyFromEnvironment,
		DialContext:           (&net.Dialer{Timeout: 30 * time.Second, KeepAlive: 30 * time.Second}).DialContext,
		TLSHandshakeTimeout:   30 * time.Second,
		ResponseHeaderTimeout: importRequestWait,
		IdleConnTimeout:       90 * time.Second,
	},
	CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse },
}

// stallGuard gives a context that ends when what is read through watch stays silent for idle, and
// a stop to call when done. The request made with that context then fails instead of waiting on a
// body that stopped coming.
func stallGuard(ctx context.Context, idle time.Duration) (context.Context, func(io.Reader) io.Reader, func()) {
	ctx, cancel := context.WithCancelCause(ctx)
	timer := time.AfterFunc(idle, func() { cancel(errStalled) })
	watch := func(r io.Reader) io.Reader { return &idleReader{r: r, timer: timer, idle: idle} }
	return ctx, watch, func() {
		timer.Stop()
		cancel(nil)
	}
}

var errStalled = errors.New("the other server stopped sending")

// idleReader puts off its timer each time something arrives.
type idleReader struct {
	r     io.Reader
	timer *time.Timer
	idle  time.Duration
}

func (r *idleReader) Read(p []byte) (int, error) {
	n, err := r.r.Read(p)
	if n > 0 {
		r.timer.Reset(r.idle)
	}
	return n, err
}

// stalledErr names a stall instead of a bare "context canceled".
func stalledErr(ctx context.Context, err error) error {
	if cause := context.Cause(ctx); errors.Is(cause, errStalled) {
		return cause
	}
	return err
}

func (i *importRun) immichCall(ctx context.Context, method, path string, body, out any) error {
	ctx, watch, stop := stallGuard(ctx, importRequestWait)
	defer stop()
	var reader io.Reader
	if body != nil {
		encoded, err := json.Marshal(body)
		if err != nil {
			return err
		}
		reader = strings.NewReader(string(encoded))
	}
	request, err := http.NewRequestWithContext(ctx, method, strings.TrimRight(i.row.Address, "/")+path, reader)
	if err != nil {
		return &errImportRefused{"the address of the Immich server is not valid"}
	}
	request.Header.Set("X-Api-Key", i.row.Secret)
	request.Header.Set("Accept", "application/json")
	if body != nil {
		request.Header.Set("Content-Type", "application/json")
	}
	response, err := importHTTP.Do(request)
	if err != nil {
		return fmt.Errorf("reach Immich: %w", err)
	}
	defer func() { _ = response.Body.Close() }()
	if response.StatusCode == http.StatusUnauthorized || response.StatusCode == http.StatusForbidden {
		return &errImportRefused{"Immich refused the API key, or the key lacks the rights it needs"}
	}
	if response.StatusCode >= http.StatusBadRequest {
		return fmt.Errorf("immich answered %d to %s", response.StatusCode, path)
	}
	if err := json.NewDecoder(watch(io.LimitReader(response.Body, maxImportAnswer))).Decode(out); err != nil {
		return stalledErr(ctx, err)
	}
	return nil
}

func (i *importRun) immichPeople(ctx context.Context) error {
	for page := 1; page < maxImportPages; page++ {
		var answer struct {
			People []struct {
				ID       string `json:"id"`
				Name     string `json:"name"`
				IsHidden bool   `json:"isHidden"`
			} `json:"people"`
			HasNextPage bool `json:"hasNextPage"`
		}
		query := url.Values{"page": {strconv.Itoa(page)}, "size": {"500"}, "withHidden": {"true"}}
		if err := i.immichCall(ctx, http.MethodGet, "/api/people?"+query.Encode(), nil, &answer); err != nil {
			return err
		}
		for _, person := range answer.People {
			key := db.GetImportMapParams{UserID: i.row.UserID, Origin: i.origin, Kind: kindPerson, RemoteID: person.ID}
			_, err := i.queries.GetImportMap(ctx, key)
			if err == nil {
				continue
			}
			if !db.IsNotFound(err) {
				return err
			}
			local, err := i.queries.CreateNamedPerson(ctx, db.CreateNamedPersonParams{UserID: i.row.UserID, Name: person.Name, Hidden: person.IsHidden})
			if err != nil {
				return err
			}
			if err := i.queries.SetImportMap(ctx, db.SetImportMapParams{
				UserID: i.row.UserID, Origin: i.origin, Kind: kindPerson, RemoteID: person.ID, LocalID: local,
			}); err != nil {
				return err
			}
		}
		if !answer.HasNextPage {
			return nil
		}
	}
	return &errImportRefused{"the Immich server does not stop listing people"}
}

// immichAlbums says which albums each asset is in, as the listing of assets does not.
func (i *importRun) immichAlbums(ctx context.Context) (map[string][]pgtype.UUID, error) {
	var albums []struct {
		ID          string `json:"id"`
		AlbumName   string `json:"albumName"`
		Description string `json:"description"`
	}
	if err := i.immichCall(ctx, http.MethodGet, "/api/albums", nil, &albums); err != nil {
		return nil, err
	}
	out := map[string][]pgtype.UUID{}
	for _, album := range albums {
		local, err := i.albumFor(ctx, album.ID, album.AlbumName, album.Description)
		if err != nil {
			return nil, err
		}
		for page := 1; page < maxImportPages; page++ {
			if err := i.stillRunning(ctx); err != nil {
				return nil, err
			}
			var answer immichSearch
			body := map[string]any{"albumIds": []string{album.ID}, "page": page, "size": immichPageSize}
			if err := i.immichCall(ctx, http.MethodPost, "/api/search/metadata", body, &answer); err != nil {
				return nil, err
			}
			for j := range answer.Assets.Items {
				id := answer.Assets.Items[j].ID
				out[id] = append(out[id], local)
			}
			if answer.Assets.NextPage == nil {
				break
			}
		}
	}
	return out, nil
}

func (i *importRun) immichDownload(ctx context.Context, id, checksum string) (string, error) {
	file, err := i.tempFile()
	if err != nil {
		return "", err
	}
	defer func() { _ = file.Close() }()
	remove := func(cause error) (string, error) {
		_ = os.Remove(file.Name())
		return "", cause
	}
	ctx, watch, stop := stallGuard(ctx, importRequestWait)
	defer stop()
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, strings.TrimRight(i.row.Address, "/")+"/api/assets/"+url.PathEscape(id)+"/original", http.NoBody)
	if err != nil {
		return remove(err)
	}
	request.Header.Set("X-Api-Key", i.row.Secret)
	response, err := importHTTP.Do(request)
	if err != nil {
		return remove(err)
	}
	defer func() { _ = response.Body.Close() }()
	if response.StatusCode != http.StatusOK {
		return remove(fmt.Errorf("immich answered %d for a file", response.StatusCode))
	}
	if err := i.roomFor(response.ContentLength); err != nil {
		return remove(err)
	}
	hash := sha1.New() //nolint:gosec // See the import.
	if _, err := io.Copy(io.MultiWriter(file, hash), watch(response.Body)); err != nil {
		return remove(stalledErr(ctx, err))
	}
	if checksum != "" && base64.StdEncoding.EncodeToString(hash.Sum(nil)) != checksum {
		return remove(errors.New("the file was damaged on the way"))
	}
	return file.Name(), nil
}

func (i *importRun) immichHints(ctx context.Context, remote string, local pgtype.UUID) error {
	var faces []immichFace
	if err := i.immichCall(ctx, http.MethodGet, "/api/faces?id="+url.QueryEscape(remote), nil, &faces); err != nil {
		return err
	}
	for j := range faces {
		face := &faces[j]
		if face.Person == nil || face.ImageWidth <= 0 || face.ImageHeight <= 0 {
			continue
		}
		person, err := i.queries.GetImportMap(ctx, db.GetImportMapParams{UserID: i.row.UserID, Origin: i.origin, Kind: kindPerson, RemoteID: face.Person.ID})
		if err != nil {
			continue //nolint:nilerr // Someone who was not listed has nothing to add.
		}
		if err := i.queries.AddFaceHint(ctx, db.AddFaceHintParams{
			AssetID: local, PersonID: person,
			X1: float32(face.X1 / face.ImageWidth), Y1: float32(face.Y1 / face.ImageHeight),
			X2: float32(face.X2 / face.ImageWidth), Y2: float32(face.Y2 / face.ImageHeight),
		}); err != nil {
			// The person was merged away. A hint only helps, and the face still finds its person.
			var failure *pgconn.PgError
			if errors.As(err, &failure) && failure.Code == foreignKeyViolation {
				continue
			}
			return err
		}
	}
	return nil
}

func (i *importRun) immichFile(ctx context.Context, asset *immichAsset, albums []pgtype.UUID) error {
	item := importItem{
		name: asset.OriginalFileName, favorite: asset.IsFavorite, archived: asset.Visibility == "archive", albums: albums,
	}
	if when, err := time.Parse(time.RFC3339, asset.FileCreatedAt); err == nil {
		item.takenAt = &when
	}
	local, known, err := i.knownLocally(ctx, asset.Checksum)
	if err != nil {
		return err
	}
	isNew := false
	if known {
		if err := i.applyKnown(ctx, local, &item); err != nil {
			return err
		}
	} else {
		tmp, err := i.immichDownload(ctx, asset.ID, asset.Checksum)
		if err != nil {
			return err
		}
		local, isNew, err = i.store(ctx, tmp, &item)
		if err != nil {
			_ = os.Remove(tmp)
			return err
		}
		if err := i.remember(ctx, local, asset.Checksum); err != nil {
			return err
		}
	}
	if err := i.immichLiveVideo(ctx, asset, item.takenAt); err != nil {
		return err
	}
	if err := i.immichHints(ctx, asset.ID, local); err != nil {
		return err
	}
	added, skipped := int32(0), int32(1)
	if isNew {
		added, skipped = 1, 0
	}
	return i.count(ctx, added, skipped, 0, "")
}

// fingerprintLibrary gives everything this user has the SHA-1 Immich lists, by reading the files
// already here. It is much less work than downloading them all again to find that out.
func (i *importRun) fingerprintLibrary(ctx context.Context) error {
	var after pgtype.UUID
	after.Valid = true
	for {
		rows, err := i.queries.ListAssetsWithoutSHA1(ctx, db.ListAssetsWithoutSHA1Params{
			UserID: i.row.UserID, ID: after, Limit: fingerprintBatch,
		})
		if err != nil || len(rows) == 0 {
			return err
		}
		for _, row := range rows {
			after = row.ID
			if err := i.stillRunning(ctx); err != nil {
				return err
			}
			sum, err := fileSHA1(row.OriginalPath)
			if err != nil {
				// A file that cannot be read now is simply not known. It is compared after a download.
				continue
			}
			if err := i.queries.SetAssetSHA1(ctx, db.SetAssetSHA1Params{ID: row.ID, ChecksumSha1: sum}); err != nil {
				return err
			}
		}
	}
}

func fileSHA1(path string) ([]byte, error) {
	file, err := os.Open(path) //nolint:gosec // From the database.
	if err != nil {
		return nil, err
	}
	defer func() { _ = file.Close() }()
	hash := sha1.New() //nolint:gosec // Only to compare with what Immich lists.
	if _, err := io.Copy(hash, file); err != nil {
		return nil, err
	}
	return hash.Sum(nil), nil
}

// knownLocally finds the asset with the checksum Immich gave, if it is here already.
func (i *importRun) knownLocally(ctx context.Context, checksum string) (pgtype.UUID, bool, error) {
	sum, err := base64.StdEncoding.DecodeString(checksum)
	if err != nil || len(sum) == 0 {
		return pgtype.UUID{}, false, nil //nolint:nilerr // Without a usable checksum, it is downloaded.
	}
	id, err := i.queries.GetAssetIDBySHA1(ctx, db.GetAssetIDBySHA1Params{UserID: i.row.UserID, ChecksumSha1: sum})
	if db.IsNotFound(err) {
		return id, false, nil
	}
	return id, err == nil, err
}

func (i *importRun) remember(ctx context.Context, id pgtype.UUID, checksum string) error {
	sum, err := base64.StdEncoding.DecodeString(checksum)
	if err != nil || len(sum) == 0 {
		return nil //nolint:nilerr // It is worked out from the file next time.
	}
	return i.queries.SetAssetSHA1(ctx, db.SetAssetSHA1Params{ID: id, ChecksumSha1: sum})
}

// applyKnown brings what Immich says about a file that needs no download.
func (i *importRun) applyKnown(ctx context.Context, id pgtype.UUID, item *importItem) error {
	if item.favorite {
		if err := i.queries.MarkImportedFavorite(ctx, id); err != nil {
			return err
		}
	}
	for _, album := range item.albums {
		if _, err := i.queries.AddAlbumAssets(ctx, db.AddAlbumAssetsParams{AlbumID: album, UserID: i.row.UserID, Ids: []pgtype.UUID{id}}); err != nil {
			return err
		}
	}
	return nil
}

// immichLiveVideo brings a Live Photo's video, a file of its own. The two find each other when it is read.
func (i *importRun) immichLiveVideo(ctx context.Context, asset *immichAsset, takenAt *time.Time) error {
	if asset.LivePhotoVideoID == nil || *asset.LivePhotoVideoID == "" {
		return nil
	}
	var details immichAsset
	path := "/api/assets/" + url.PathEscape(*asset.LivePhotoVideoID)
	if err := i.immichCall(ctx, http.MethodGet, path, nil, &details); err != nil {
		return err
	}
	if _, known, err := i.knownLocally(ctx, details.Checksum); err != nil || known {
		return err
	}
	video, err := i.immichDownload(ctx, *asset.LivePhotoVideoID, details.Checksum)
	if err != nil {
		return err
	}
	stem := strings.TrimSuffix(asset.OriginalFileName, filepath.Ext(asset.OriginalFileName))
	local, _, err := i.store(ctx, video, &importItem{name: stem + ".mov", takenAt: takenAt})
	if err != nil {
		_ = os.Remove(video)
		return err
	}
	return i.remember(ctx, local, details.Checksum)
}

func (i *importRun) immich(ctx context.Context) error {
	if err := i.fingerprintLibrary(ctx); err != nil {
		return err
	}
	if err := i.immichPeople(ctx); err != nil {
		return err
	}
	albums, err := i.immichAlbums(ctx)
	if err != nil {
		return err
	}
	for page := int(i.row.Page); page < maxImportPages; page++ {
		var answer immichSearch
		body := map[string]any{"page": page, "size": immichPageSize}
		if err := i.immichCall(ctx, http.MethodPost, "/api/search/metadata", body, &answer); err != nil {
			return err
		}
		for j := range answer.Assets.Items {
			asset := &answer.Assets.Items[j]
			if err := i.stillRunning(ctx); err != nil {
				return err
			}
			// What Immich keeps locked is the user's to move on purpose, not by an import. "hidden" is
			// the moving part of a Live Photo, which comes with its picture.
			if asset.IsOffline || asset.Visibility == "locked" || asset.Visibility == "hidden" {
				continue
			}
			if err := i.immichFile(ctx, asset, albums[asset.ID]); err != nil {
				if ctx.Err() != nil {
					return err
				}
				var refused *errImportRefused
				if errors.As(err, &refused) {
					return err
				}
				slog.Warn("a file could not be imported", "name", asset.OriginalFileName, "error", err)
				if err := i.count(ctx, 0, 0, 1, asset.OriginalFileName+": "+err.Error()); err != nil {
					return err
				}
			}
		}
		if answer.Assets.NextPage == nil {
			return nil
		}
		if err := i.queries.SetImportPage(ctx, db.SetImportPageParams{ID: i.row.ID, Page: int32(page + 1)}); err != nil { //nolint:gosec // A page number.
			return err
		}
	}
	return &errImportRefused{"the Immich server does not stop listing photos"}
}

// --- Exports: an unpacked folder through the read-only mount, or the user's own ZIP files ---

// tree opens what this import reads from.
func (i *importRun) tree(ctx context.Context) (exportTree, error) {
	if !i.row.FromZip {
		root := filepath.Join(i.opts.ExternalPath, filepath.Clean("/"+i.row.Folder))
		info, err := os.Stat(root)
		if err != nil || !info.IsDir() {
			return nil, &errImportRefused{"this folder was not found in the external library's mount"}
		}
		return newFolderTree(root)
	}
	parts, err := i.queries.ListImportParts(ctx, i.row.ID)
	if err != nil {
		return nil, err
	}
	if len(parts) == 0 {
		return nil, &errImportRefused{"there are no ZIP files to bring in"}
	}
	paths := make([]string, len(parts))
	for n := range parts {
		paths[n] = parts[n].Path
	}
	return newZipTree(paths)
}

func (i *importRun) copyIn(ctx context.Context, tree exportTree, name string, item *importItem) error {
	source, size, modified, err := tree.open(name)
	if err != nil {
		return err
	}
	defer func() { _ = source.Close() }()
	if err := i.roomFor(size); err != nil {
		return err
	}
	file, err := i.tempFile()
	if err != nil {
		return err
	}
	defer func() { _ = file.Close() }()
	if _, err := io.Copy(file, source); err != nil {
		_ = os.Remove(file.Name())
		return err
	}
	if item.takenAt == nil && !modified.IsZero() {
		item.takenAt = &modified
	}
	i.placeInTime(item)
	_, isNew, err := i.store(ctx, file.Name(), item)
	if err != nil {
		_ = os.Remove(file.Name())
		return err
	}
	if isNew {
		return i.count(ctx, 1, 0, 0, "")
	}
	return i.count(ctx, 0, 1, 0, "")
}

func (i *importRun) copyOrCount(ctx context.Context, tree exportTree, name string, item *importItem) error {
	err := i.copyIn(ctx, tree, name, item)
	if err == nil || ctx.Err() != nil {
		return err
	}
	var refused *errImportRefused
	if errors.As(err, &refused) {
		return err
	}
	slog.Warn("a file could not be imported", "name", item.name, "error", err)
	reason := truncate(err.Error(), maxImportError)
	if problem := i.queries.AddImportProblem(ctx, db.AddImportProblemParams{ImportID: i.row.ID, Name: name, Reason: reason}); problem != nil {
		return problem
	}
	return i.count(ctx, 0, 0, 1, item.name+": "+reason)
}

// begin counts what there is to bring in, so progress can be shown as a share of it.
func (i *importRun) begin(ctx context.Context, files []string) error {
	return i.queries.SetImportTotal(ctx, db.SetImportTotalParams{ID: i.row.ID, Total: int32(min(len(files), math.MaxInt32))}) //nolint:gosec // Bounded.
}

// sidecarXMP finds an XMP file left beside a photo by another program, as photo.jpg.xmp or photo.xmp.
func sidecarXMP(name string, names []string) string {
	base := path.Base(name)
	stem := strings.TrimSuffix(base, path.Ext(base))
	for _, candidate := range []string{base + ".xmp", base + ".XMP", stem + ".xmp", stem + ".XMP"} {
		if slices.Contains(names, candidate) {
			return candidate
		}
	}
	return ""
}

// readXMP puts what an XMP file beside a photo says into what the import knows about it. A damaged
// one is passed over: the photo still comes in.
func (i *importRun) readXMP(ctx context.Context, tree exportTree, name string, item *importItem) {
	dir := path.Dir(name)
	found := sidecarXMP(name, tree.names(dir))
	if found == "" {
		return
	}
	raw, err := tree.small(path.Join(dir, found))
	if err != nil {
		return
	}
	file, err := i.tempFile()
	if err != nil {
		return
	}
	defer func() { _ = os.Remove(file.Name()) }()
	_, err = file.Write(raw)
	_ = file.Close()
	if err != nil {
		return
	}
	out, err := runTool(ctx, "exiftool", "-json", "-n", file.Name())
	if err != nil {
		return
	}
	var rows []map[string]any
	if json.Unmarshal(out, &rows) != nil || len(rows) != 1 {
		return
	}
	var meta Metadata
	meta.overlaySidecar(rows[0])
	if meta.TakenAt != nil {
		item.takenAt, item.offset = meta.TakenAt, meta.OffsetMinutes
	}
	if meta.Latitude != nil && meta.Longitude != nil {
		item.latitude, item.longitude = meta.Latitude, meta.Longitude
	}
	if meta.Caption != "" {
		item.caption = meta.Caption
	}
}

// takeoutSidecar is the part of Google's JSON that matters here.
type takeoutSidecar struct {
	Description    string `json:"description"`
	PhotoTakenTime struct {
		Timestamp string `json:"timestamp"`
	} `json:"photoTakenTime"`
	GeoData struct {
		Latitude  float64 `json:"latitude"`
		Longitude float64 `json:"longitude"`
	} `json:"geoData"`
	Favorited bool `json:"favorited"`
	Archived  bool `json:"archived"`
	Trashed   bool `json:"trashed"`
}

// FindTakeoutSidecar finds the JSON beside a file. Google shortens long names, adds
// ".supplemental-metadata" in newer exports, and moves "(1)" to after the extension.
func FindTakeoutSidecar(name string, names []string) string {
	stem, extension := name, filepath.Ext(name)
	number := ""
	base := strings.TrimSuffix(name, extension)
	if open := strings.LastIndex(base, "("); open > 0 && strings.HasSuffix(base, ")") {
		number = base[open:]
		stem = base[:open] + extension
	}
	candidates := []string{name + ".json", stem + number + ".json", stem + ".supplemental-metadata" + number + ".json"}
	for _, candidate := range candidates {
		if slices.Contains(names, candidate) {
			return candidate
		}
	}
	// A shortened name: the JSON's name, up to where it was cut, starts this file's name.
	best := ""
	for _, other := range names {
		if !strings.HasSuffix(other, ".json") || other == "metadata.json" {
			continue
		}
		cut := strings.TrimSuffix(other, ".json")
		if number != "" {
			if !strings.HasSuffix(cut, number) {
				continue
			}
			cut = strings.TrimSuffix(cut, number)
		}
		if len(cut) >= 10 && strings.HasPrefix(stem, cut) && len(cut) > len(best) {
			best = other
		}
		if dot := strings.Index(cut, ".su"); dot > 0 && strings.HasPrefix(stem, cut[:dot]+extension) && len(cut) > len(best) {
			best = other
		}
	}
	return best
}

// parseTakeoutSidecar reads what Google knows about a file.
func parseTakeoutSidecar(raw []byte) (*importItem, bool, error) {
	var sidecar takeoutSidecar
	if err := json.Unmarshal(raw, &sidecar); err != nil {
		return nil, false, err
	}
	item := &importItem{favorite: sidecar.Favorited, archived: sidecar.Archived, caption: strings.TrimSpace(sidecar.Description)}
	if seconds, err := strconv.ParseInt(sidecar.PhotoTakenTime.Timestamp, 10, 64); err == nil && seconds > 0 {
		when := time.Unix(seconds, 0).UTC()
		item.takenAt = &when
	}
	// Zero is what Google writes when it does not know.
	if sidecar.GeoData.Latitude != 0 || sidecar.GeoData.Longitude != 0 {
		lat, lon := sidecar.GeoData.Latitude, sidecar.GeoData.Longitude
		item.latitude, item.longitude = &lat, &lon
	}
	return item, sidecar.Trashed, nil
}

// readSmallFile reads a sidecar only if it is one: a link or a pipe in an export could hang or read
// something else, and a huge file could use up the memory.
func readSmallFile(path string) ([]byte, error) {
	info, err := os.Lstat(path)
	if err != nil {
		return nil, err
	}
	if !info.Mode().IsRegular() || info.Size() > maxSidecarBytes {
		return nil, errNotSmall
	}
	return os.ReadFile(path) //nolint:gosec // Within the chosen folder.
}

// TakeoutAlbum names a folder's album, with its description, from its metadata.json, which year
// folders do not have.
func TakeoutAlbum(raw []byte) (title, description string) {
	var album struct {
		Title       string `json:"title"`
		Description string `json:"description"`
	}
	if json.Unmarshal(raw, &album) != nil {
		return "", ""
	}
	return strings.TrimSpace(album.Title), strings.TrimSpace(album.Description)
}

func (i *importRun) takeout(ctx context.Context, tree exportTree) error {
	files := tree.media()
	if err := i.begin(ctx, files); err != nil {
		return err
	}
	albums := map[string]pgtype.UUID{}
	for _, name := range files {
		if err := i.stillRunning(ctx); err != nil {
			return err
		}
		dir, base := path.Dir(name), path.Base(name)
		names := tree.names(dir)
		item := &importItem{}
		if sidecar := FindTakeoutSidecar(base, names); sidecar != "" {
			if raw, err := tree.small(path.Join(dir, sidecar)); err == nil {
				if parsed, trashed, err := parseTakeoutSidecar(raw); err == nil {
					if trashed {
						if err := i.count(ctx, 0, 1, 0, ""); err != nil {
							return err
						}
						continue
					}
					item = parsed
				}
			}
		}
		item.name = base
		i.readXMP(ctx, tree, name, item)
		album, known := albums[dir]
		if !known && slices.Contains(names, "metadata.json") {
			if raw, err := tree.small(path.Join(dir, "metadata.json")); err == nil {
				if title, description := TakeoutAlbum(raw); title != "" {
					// The folder names the album, as Google cuts names short and two albums can share one.
					local, err := i.albumFor(ctx, path.Base(dir), title, description)
					if err != nil {
						return err
					}
					album = local
				}
			}
			albums[dir] = album
		}
		if album.Valid {
			item.albums = []pgtype.UUID{album}
		}
		if err := i.copyOrCount(ctx, tree, name, item); err != nil {
			return err
		}
	}
	return nil
}

// ICloudRow is one line of Apple's "Photo Details.csv".
type ICloudRow struct {
	Favorite, Hidden, Deleted bool
	TakenAt                   *time.Time
}

// ParseICloudDate reads Apple's way of writing a date, such as "Monday May 1,2023 10:00 AM GMT".
func ParseICloudDate(value string) *time.Time {
	for _, layout := range []string{"Monday January 2,2006 3:04 PM MST", "Monday January 2, 2006 3:04 PM MST"} {
		if when, err := time.Parse(layout, strings.TrimSpace(value)); err == nil {
			return &when
		}
	}
	return nil
}

// ReadICloudDetails reads "Photo Details.csv" by its column names, wherever they are.
func ReadICloudDetails(source io.Reader) (map[string]ICloudRow, error) {
	reader := csv.NewReader(source)
	reader.FieldsPerRecord = -1
	header, err := reader.Read()
	if err != nil {
		return nil, err
	}
	column := map[string]int{}
	for position, name := range header {
		column[strings.TrimSpace(strings.TrimPrefix(name, "\ufeff"))] = position
	}
	at, ok := column["imgName"]
	if !ok {
		return nil, errors.New("no imgName column")
	}
	field := func(row []string, name string) string {
		if position, ok := column[name]; ok && position < len(row) {
			return strings.TrimSpace(row[position])
		}
		return ""
	}
	out := map[string]ICloudRow{}
	for {
		row, err := reader.Read()
		if errors.Is(err, io.EOF) {
			return out, nil
		}
		if err != nil {
			return nil, err
		}
		if at >= len(row) {
			continue
		}
		yes := func(name string) bool { return strings.EqualFold(field(row, name), "yes") }
		out[strings.ToLower(row[at])] = ICloudRow{
			Favorite: yes("favorite"), Hidden: yes("hidden"), Deleted: yes("deleted"),
			TakenAt: ParseICloudDate(field(row, "originalCreationDate")),
		}
	}
}

// ICloudDetails finds a photo's row: from the list in its own folder first, and by its name alone
// only where no other list has the same name, so two photos of the same name do not mix.
type ICloudDetails struct {
	byFolder map[string]ICloudRow
	byName   map[string][]ICloudRow
}

// Add takes the rows of the list found in dir.
func (d *ICloudDetails) Add(dir string, rows map[string]ICloudRow) {
	if d.byFolder == nil {
		d.byFolder, d.byName = map[string]ICloudRow{}, map[string][]ICloudRow{}
	}
	for name, row := range rows {
		d.byFolder[dir+"/"+name] = row
		d.byName[name] = append(d.byName[name], row)
	}
}

// Find gives the row for the photo at name.
func (d *ICloudDetails) Find(name string) ICloudRow {
	key := strings.ToLower(path.Base(name))
	if row, ok := d.byFolder[path.Dir(name)+"/"+key]; ok {
		return row
	}
	if rows := d.byName[key]; len(rows) == 1 {
		return rows[0]
	}
	return ICloudRow{}
}

func (i *importRun) icloud(ctx context.Context, tree exportTree) error {
	var details ICloudDetails
	albums := map[string][]pgtype.UUID{}
	for _, name := range tree.all() {
		if !strings.EqualFold(path.Ext(name), ".csv") {
			continue
		}
		source, _, _, err := tree.open(name)
		if err != nil {
			continue
		}
		base := path.Base(name)
		switch {
		case strings.HasPrefix(base, "Photo Details"):
			if rows, err := ReadICloudDetails(source); err == nil {
				details.Add(path.Dir(name), rows)
			}
		case path.Base(path.Dir(name)) == "Albums":
			title := strings.TrimSuffix(base, path.Ext(base))
			album, err := i.albumFor(ctx, name, title, "")
			if err != nil {
				_ = source.Close()
				return err
			}
			reader := csv.NewReader(source)
			reader.FieldsPerRecord = -1
			for first := true; ; first = false {
				row, err := reader.Read()
				if err != nil {
					break
				}
				if !first && len(row) > 0 {
					key := strings.ToLower(strings.TrimSpace(row[0]))
					albums[key] = append(albums[key], album)
				}
			}
		}
		_ = source.Close()
	}
	files := tree.media()
	if err := i.begin(ctx, files); err != nil {
		return err
	}
	for _, name := range files {
		if err := i.stillRunning(ctx); err != nil {
			return err
		}
		row := details.Find(name)
		if row.Deleted {
			if err := i.count(ctx, 0, 1, 0, ""); err != nil {
				return err
			}
			continue
		}
		base := path.Base(name)
		item := &importItem{name: base, takenAt: row.TakenAt, favorite: row.Favorite, archived: row.Hidden, albums: albums[strings.ToLower(base)]}
		i.readXMP(ctx, tree, name, item)
		if err := i.copyOrCount(ctx, tree, name, item); err != nil {
			return err
		}
	}
	return nil
}
