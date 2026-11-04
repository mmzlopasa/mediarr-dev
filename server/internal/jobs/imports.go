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
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"slices"
	"strconv"
	"strings"
	"syscall"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/riverqueue/river"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/storage"
)

const (
	importQueue       = "import"
	importSlice       = 6 * time.Hour
	immichPageSize    = 250
	importRequestWait = 2 * time.Minute
	maxImportError    = 400
	maxImportAnswer   = 64 << 20
	maxSidecarBytes   = 1 << 20
	maxImportPages    = 200000
	minImportFree     = 2 << 30
	statusDone        = "done"
	statusFailed      = "failed"
	sourceImmich      = "immich"
	sourceTakeout     = "takeout"
	sourceICloud      = "icloud"
	kindAlbum         = "album"
	kindPerson        = "person"
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
	case sourceTakeout:
		err = run.takeout(slice)
	case sourceICloud:
		err = run.icloud(slice)
	default:
		err = &errImportRefused{"unknown source"}
	}
	var refused *errImportRefused
	switch {
	case err == nil:
		return w.finishImport(ctx, id, statusDone, "")
	case errors.Is(err, errImportStopped):
		return nil
	case errors.As(err, &refused):
		return w.finishImport(ctx, id, statusFailed, refused.message)
	case slice.Err() != nil && ctx.Err() == nil:
		// A long import goes on in a new run, from the page it reached, without using up attempts.
		return river.JobSnooze(time.Second)
	case job.Attempt >= maxAttempts:
		return w.finishImport(ctx, id, statusFailed, truncate(err.Error(), maxImportError))
	}
	return err
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
		if err := q.SetImportFacts(ctx, facts); err != nil {
			return err
		}
		if item.archived {
			if err := q.MarkImportedArchived(ctx, id); err != nil {
				return err
			}
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
	Transport:     &http.Transport{ResponseHeaderTimeout: importRequestWait},
	CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse },
}

func (i *importRun) immichCall(ctx context.Context, method, path string, body, out any) error {
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
	return json.NewDecoder(io.LimitReader(response.Body, maxImportAnswer)).Decode(out)
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
	if _, err := io.Copy(io.MultiWriter(file, hash), response.Body); err != nil {
		return remove(err)
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
			return err
		}
	}
	return nil
}

func (i *importRun) immichFile(ctx context.Context, asset *immichAsset, albums []pgtype.UUID) error {
	tmp, err := i.immichDownload(ctx, asset.ID, asset.Checksum)
	if err != nil {
		return err
	}
	item := importItem{
		name: asset.OriginalFileName, favorite: asset.IsFavorite, archived: asset.Visibility == "archive", albums: albums,
	}
	if when, err := time.Parse(time.RFC3339, asset.FileCreatedAt); err == nil {
		item.takenAt = &when
	}
	local, isNew, err := i.store(ctx, tmp, &item)
	if err != nil {
		_ = os.Remove(tmp)
		return err
	}
	// A Live Photo's video is a file of its own, and they find each other when it is read.
	if asset.LivePhotoVideoID != nil && *asset.LivePhotoVideoID != "" {
		video, err := i.immichDownload(ctx, *asset.LivePhotoVideoID, "")
		if err != nil {
			return err
		}
		stem := strings.TrimSuffix(asset.OriginalFileName, filepath.Ext(asset.OriginalFileName))
		if _, _, err := i.store(ctx, video, &importItem{name: stem + ".mov", takenAt: item.takenAt}); err != nil {
			_ = os.Remove(video)
			return err
		}
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

func (i *importRun) immich(ctx context.Context) error {
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

// --- Folders given through the read-only mount ---

func (i *importRun) folder() (string, error) {
	root := filepath.Join(i.opts.ExternalPath, filepath.Clean("/"+i.row.Folder))
	info, err := os.Stat(root)
	if err != nil || !info.IsDir() {
		return "", &errImportRefused{"this folder was not found in the external library's mount"}
	}
	return root, nil
}

func (i *importRun) copyIn(ctx context.Context, path string, item *importItem) error {
	source, err := os.Open(path) //nolint:gosec // Found by walking the chosen folder.
	if err != nil {
		return err
	}
	defer func() { _ = source.Close() }()
	if info, err := source.Stat(); err == nil {
		if err := i.roomFor(info.Size()); err != nil {
			return err
		}
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
	if info, err := source.Stat(); err == nil && item.takenAt == nil {
		when := info.ModTime()
		item.takenAt = &when
	}
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

func (i *importRun) copyOrCount(ctx context.Context, path string, item *importItem) error {
	err := i.copyIn(ctx, path, item)
	if err == nil || ctx.Err() != nil {
		return err
	}
	slog.Warn("a file could not be imported", "name", item.name, "error", err)
	return i.count(ctx, 0, 0, 1, item.name+": "+err.Error())
}

// sortedMedia is stable from run to run, which keeps a resumed import from looking random.
func sortedMedia(root string) ([]string, error) {
	found, _, err := walkExternal(root)
	if err != nil {
		return nil, err
	}
	out := make([]string, 0, len(found))
	for path := range found {
		out = append(out, path)
	}
	slices.Sort(out)
	return out, nil
}

// takeoutSidecar is the part of Google's JSON that matters here.
type takeoutSidecar struct {
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
	item := &importItem{favorite: sidecar.Favorited, archived: sidecar.Archived}
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
		return nil, errors.New("not a sidecar")
	}
	return os.ReadFile(path) //nolint:gosec // Within the chosen folder.
}

// takeoutAlbum names a folder's album from its metadata.json, which year folders do not have.
func takeoutAlbum(dir string) string {
	raw, err := readSmallFile(filepath.Join(dir, "metadata.json"))
	if err != nil {
		return ""
	}
	var album struct {
		Title string `json:"title"`
	}
	if json.Unmarshal(raw, &album) != nil {
		return ""
	}
	return strings.TrimSpace(album.Title)
}

func (i *importRun) takeout(ctx context.Context) error {
	root, err := i.folder()
	if err != nil {
		return err
	}
	files, err := sortedMedia(root)
	if err != nil {
		return err
	}
	listing := map[string][]string{}
	for _, path := range files {
		dir := filepath.Dir(path)
		if _, known := listing[dir]; known {
			continue
		}
		entries, err := os.ReadDir(dir)
		if err != nil {
			return err
		}
		names := make([]string, 0, len(entries))
		for _, entry := range entries {
			names = append(names, entry.Name())
		}
		listing[dir] = names
	}
	for _, path := range files {
		if err := i.stillRunning(ctx); err != nil {
			return err
		}
		dir, name := filepath.Dir(path), filepath.Base(path)
		item := &importItem{}
		if sidecar := FindTakeoutSidecar(name, listing[dir]); sidecar != "" {
			raw, err := readSmallFile(filepath.Join(dir, sidecar))
			if err == nil {
				parsed, trashed, err := parseTakeoutSidecar(raw)
				if err == nil {
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
		item.name = name
		if title := takeoutAlbum(dir); title != "" {
			album, err := i.albumFor(ctx, dir, title, "")
			if err != nil {
				return err
			}
			item.albums = []pgtype.UUID{album}
		}
		if err := i.copyOrCount(ctx, path, item); err != nil {
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

func (i *importRun) icloud(ctx context.Context) error {
	root, err := i.folder()
	if err != nil {
		return err
	}
	details := map[string]ICloudRow{}
	albums := map[string][]pgtype.UUID{}
	err = filepath.WalkDir(root, func(path string, entry os.DirEntry, walkErr error) error {
		if walkErr != nil || entry.IsDir() || !strings.EqualFold(filepath.Ext(path), ".csv") {
			return nil //nolint:nilerr // What cannot be read is reported where the files are copied.
		}
		file, err := os.Open(path) //nolint:gosec // Within the chosen folder.
		if err != nil {
			return nil //nolint:nilerr // As above.
		}
		defer func() { _ = file.Close() }()
		if strings.HasPrefix(filepath.Base(path), "Photo Details") {
			rows, err := ReadICloudDetails(file)
			if err != nil {
				return nil //nolint:nilerr // As above.
			}
			for name, row := range rows {
				details[name] = row
			}
			return nil
		}
		if filepath.Base(filepath.Dir(path)) != "Albums" {
			return nil
		}
		title := strings.TrimSuffix(filepath.Base(path), filepath.Ext(path))
		album, err := i.albumFor(ctx, path, title, "")
		if err != nil {
			return err
		}
		reader := csv.NewReader(file)
		reader.FieldsPerRecord = -1
		for first := true; ; first = false {
			row, err := reader.Read()
			if err != nil {
				break
			}
			if !first && len(row) > 0 {
				name := strings.ToLower(strings.TrimSpace(row[0]))
				albums[name] = append(albums[name], album)
			}
		}
		return nil
	})
	if err != nil {
		return err
	}
	files, err := sortedMedia(root)
	if err != nil {
		return err
	}
	for _, path := range files {
		if err := i.stillRunning(ctx); err != nil {
			return err
		}
		name := filepath.Base(path)
		key := strings.ToLower(name)
		row := details[key]
		if row.Deleted {
			if err := i.count(ctx, 0, 1, 0, ""); err != nil {
				return err
			}
			continue
		}
		item := &importItem{name: name, takenAt: row.TakenAt, favorite: row.Favorite, archived: row.Hidden, albums: albums[key]}
		if err := i.copyOrCount(ctx, path, item); err != nil {
			return err
		}
	}
	return nil
}
