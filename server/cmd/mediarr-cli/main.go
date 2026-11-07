// Command mediarr-cli uploads folders of photos and videos to a Mediarr server: it skips what the
// server already has, continues an interrupted upload, and can delete local files once the server
// has confirmed them.
package main

import (
	"bufio"
	"context"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"net/http"
	"net/url"
	"os"
	"os/signal"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"syscall"
	"time"
)

// version is set when it is built.
var version = "dev"

const usage = `mediarr-cli uploads photos and videos to a Mediarr server.

  mediarr-cli login <server address>        keep the address and an API key
  mediarr-cli upload [flags] <folder or file>...
  mediarr-cli version

Make the API key in Mediarr under Account → API keys. Uploading needs the "upload" right; --album
also needs "read" and "write".

Upload flags:
`

const (
	chunkSize     = 50 << 20
	checkBatch    = 1000
	maxAttempts   = 5
	requestWait   = 60 * time.Second
	keyHeader     = "X-Api-Key"
	tusVersion    = "1.0.0"
	checksumError = 460
)

// media is what is sent; anything else in a folder is left alone.
var media = map[string]bool{
	".jpg": true, ".jpeg": true, ".png": true, ".heic": true, ".heif": true, ".webp": true, ".gif": true,
	".tif": true, ".tiff": true, ".avif": true, ".jxl": true, ".dng": true, ".cr2": true, ".cr3": true,
	".nef": true, ".arw": true, ".raf": true, ".rw2": true, ".orf": true, ".pef": true, ".srw": true,
	".mp4": true, ".mov": true, ".m4v": true, ".mkv": true, ".avi": true, ".webm": true, ".3gp": true,
	".mts": true, ".m2ts": true,
}

type config struct {
	Server string `json:"server"`
	Key    string `json:"key"`
}

func configPath() (string, error) {
	dir, err := os.UserConfigDir()
	if err != nil {
		return "", err
	}
	return filepath.Join(dir, "mediarr", "cli.json"), nil
}

func loadConfig() (*config, error) {
	if server, key := os.Getenv("MEDIARR_SERVER"), os.Getenv("MEDIARR_API_KEY"); server != "" && key != "" {
		return &config{Server: strings.TrimRight(server, "/"), Key: key}, nil
	}
	path, err := configPath()
	if err != nil {
		return nil, err
	}
	data, err := os.ReadFile(path)
	if errors.Is(err, os.ErrNotExist) {
		return nil, errors.New("not signed in: run `mediarr-cli login <server address>` first")
	}
	if err != nil {
		return nil, err
	}
	var c config
	if err := json.Unmarshal(data, &c); err != nil {
		return nil, fmt.Errorf("read %s: %w", path, err)
	}
	return &c, nil
}

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	if err := run(ctx, os.Args[1:], os.Stdin, os.Stdout); err != nil {
		_, _ = fmt.Fprintln(os.Stderr, "mediarr-cli:", err)
		os.Exit(1)
	}
}

func run(ctx context.Context, args []string, in io.Reader, out io.Writer) error {
	if len(args) == 0 {
		_, _ = fmt.Fprint(out, usage)
		uploadFlags(io.Discard).PrintDefaults()
		return nil
	}
	switch args[0] {
	case "login":
		return login(ctx, args[1:], in, out)
	case "upload":
		return upload(ctx, args[1:], out)
	case "version":
		_, _ = fmt.Fprintln(out, version)
		return nil
	case "help", "-h", "--help":
		_, _ = fmt.Fprint(out, usage)
		flags := uploadFlags(io.Discard)
		flags.SetOutput(out)
		flags.PrintDefaults()
		return nil
	}
	return fmt.Errorf("unknown command %q; run mediarr-cli help", args[0])
}

type client struct {
	server string
	key    string
	http   *http.Client
}

func (c *client) request(ctx context.Context, method, path string, body io.Reader, headers map[string]string) (*http.Response, error) {
	target := path
	if !strings.HasPrefix(path, "http://") && !strings.HasPrefix(path, "https://") {
		target = c.server + path
	}
	req, err := http.NewRequestWithContext(ctx, method, target, body)
	if err != nil {
		return nil, err
	}
	req.Header.Set(keyHeader, c.key)
	for name, value := range headers {
		req.Header.Set(name, value)
	}
	return c.http.Do(req)
}

func (c *client) json(ctx context.Context, method, path string, payload, into any) error {
	var body io.Reader
	if payload != nil {
		data, err := json.Marshal(payload)
		if err != nil {
			return err
		}
		body = strings.NewReader(string(data))
	}
	resp, err := c.request(ctx, method, path, body, map[string]string{"Content-Type": "application/json"})
	if err != nil {
		return err
	}
	defer func() { _ = resp.Body.Close() }()
	if resp.StatusCode >= http.StatusBadRequest {
		return serverError(resp)
	}
	if into == nil {
		return nil
	}
	return json.NewDecoder(resp.Body).Decode(into)
}

func serverError(resp *http.Response) error {
	var problem struct {
		Message string `json:"message"`
	}
	data, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))
	if json.Unmarshal(data, &problem) == nil && problem.Message != "" {
		return fmt.Errorf("the server answered %d: %s", resp.StatusCode, problem.Message)
	}
	return fmt.Errorf("the server answered %d", resp.StatusCode)
}

// existing asks which checksums the server already has.
func (c *client) existing(ctx context.Context, sums []string) (map[string]bool, error) {
	var answer struct {
		Existing []string `json:"existing"`
	}
	if err := c.json(ctx, http.MethodPost, "/api/assets/check", map[string][]string{"checksums": sums}, &answer); err != nil {
		return nil, err
	}
	out := map[string]bool{}
	for _, sum := range answer.Existing {
		out[strings.ToLower(sum)] = true
	}
	return out, nil
}

func login(ctx context.Context, args []string, in io.Reader, out io.Writer) error {
	if len(args) != 1 {
		return errors.New("usage: mediarr-cli login <server address>, such as http://192.168.1.10:9851")
	}
	server := strings.TrimRight(strings.TrimSpace(args[0]), "/")
	if parsed, err := url.Parse(server); err != nil || parsed.Host == "" || (parsed.Scheme != "http" && parsed.Scheme != "https") {
		return fmt.Errorf("%q is not a server address; write it as http://192.168.1.10:9851", args[0])
	}
	_, _ = fmt.Fprint(out, "API key (Account → API keys, with the upload right): ")
	key, err := bufio.NewReader(in).ReadString('\n')
	if err != nil && key == "" {
		return errors.New("no key was given")
	}
	key = strings.TrimSpace(key)
	c := &client{server: server, key: key, http: &http.Client{Timeout: requestWait}}
	if _, err := c.existing(ctx, []string{}); err != nil {
		return fmt.Errorf("the key does not work on %s: %w", server, err)
	}
	path, err := configPath()
	if err != nil {
		return err
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return err
	}
	data, err := json.MarshalIndent(config{Server: server, Key: key}, "", "  ")
	if err != nil {
		return err
	}
	// The key opens the library: only its owner reads the file.
	if err := os.WriteFile(path, data, 0o600); err != nil {
		return err
	}
	_, _ = fmt.Fprintf(out, "Signed in to %s. The key is kept in %s.\n", server, path)
	return nil
}

type uploadOptions struct {
	album       string
	recursive   bool
	dryRun      bool
	deleteAfter bool
	jobs        int
}

func uploadFlags(out io.Writer) *flag.FlagSet {
	flags := flag.NewFlagSet("upload", flag.ContinueOnError)
	flags.SetOutput(out)
	flags.String("album", "", "put the files in this album, made if it does not exist")
	flags.Bool("recursive", true, "also the folders inside the folders given")
	flags.Bool("dry-run", false, "only say what would be sent")
	flags.Bool("delete-after", false, "delete each local file once the server has confirmed it")
	flags.Int("jobs", 3, "files sent at the same time")
	return flags
}

type file struct {
	path     string
	size     int64
	modified time.Time
	checksum string
}

// collect finds the photos and videos in what was given. Hidden files and folders are left alone.
func collect(paths []string, recursive bool) ([]file, error) {
	var out []file
	seen := map[string]bool{}
	add := func(path string, info fs.FileInfo) {
		abs, err := filepath.Abs(path)
		if err != nil || seen[abs] || !media[strings.ToLower(filepath.Ext(path))] || strings.HasPrefix(info.Name(), ".") {
			return
		}
		seen[abs] = true
		out = append(out, file{path: abs, size: info.Size(), modified: info.ModTime()})
	}
	for _, root := range paths {
		info, err := os.Stat(root)
		if err != nil {
			return nil, err
		}
		if !info.IsDir() {
			add(root, info)
			continue
		}
		err = filepath.WalkDir(root, func(path string, entry fs.DirEntry, walkErr error) error {
			if walkErr != nil {
				return walkErr
			}
			if entry.IsDir() {
				if path != root && (!recursive || strings.HasPrefix(entry.Name(), ".")) {
					return filepath.SkipDir
				}
				return nil
			}
			if !entry.Type().IsRegular() {
				return nil
			}
			info, err := entry.Info()
			if err != nil {
				return err
			}
			add(path, info)
			return nil
		})
		if err != nil {
			return nil, err
		}
	}
	sort.Slice(out, func(i, j int) bool { return out[i].path < out[j].path })
	return out, nil
}

func checksumOf(path string) (string, error) {
	f, err := os.Open(path)
	if err != nil {
		return "", err
	}
	defer func() { _ = f.Close() }()
	hash := sha256.New()
	if _, err := io.Copy(hash, f); err != nil {
		return "", err
	}
	return hex.EncodeToString(hash.Sum(nil)), nil
}

// albumID finds the album by its name, or makes it.
func (c *client) albumID(ctx context.Context, title string) (string, error) {
	var albums []struct {
		ID    string `json:"id"`
		Title string `json:"title"`
		Role  string `json:"role"`
	}
	if err := c.json(ctx, http.MethodGet, "/api/albums", nil, &albums); err != nil {
		return "", fmt.Errorf("list albums (the key needs the read right): %w", err)
	}
	for _, album := range albums {
		if album.Title == title && album.Role != "viewer" {
			return album.ID, nil
		}
	}
	var made struct {
		ID string `json:"id"`
	}
	if err := c.json(ctx, http.MethodPost, "/api/albums", map[string]string{"title": title}, &made); err != nil {
		return "", fmt.Errorf("make the album (the key needs the write right): %w", err)
	}
	return made.ID, nil
}

func encodeMetadata(fields map[string]string) string {
	keys := make([]string, 0, len(fields))
	for key := range fields {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	parts := make([]string, 0, len(keys))
	for _, key := range keys {
		parts = append(parts, key+" "+base64.StdEncoding.EncodeToString([]byte(fields[key])))
	}
	return strings.Join(parts, ",")
}

// send uploads one file with tus, in parts, going on from where the server has it after a break.
// The server compares the checksum and refuses a damaged file.
func (c *client) send(ctx context.Context, f *file, album string) error {
	meta := map[string]string{
		"filename": filepath.Base(f.path), "checksum": f.checksum,
		"lastModified": strconv.FormatInt(f.modified.UnixMilli(), 10),
	}
	if album != "" {
		meta["albumId"] = album
	}
	resp, err := c.request(ctx, http.MethodPost, "/api/uploads", nil, map[string]string{
		"Tus-Resumable": tusVersion, "Upload-Length": strconv.FormatInt(f.size, 10),
		"Upload-Metadata": encodeMetadata(meta),
	})
	if err != nil {
		return err
	}
	_ = resp.Body.Close()
	if resp.StatusCode != http.StatusCreated {
		return serverError(resp)
	}
	location, err := resp.Location()
	if err != nil {
		return fmt.Errorf("the server gave no address for the upload: %w", err)
	}
	var offset int64
	for attempt := 1; offset < f.size || f.size == 0; {
		next, err := c.part(ctx, location.String(), f, offset)
		if err == nil {
			offset = next
			attempt = 1
			if f.size == 0 {
				return nil
			}
			continue
		}
		var refused *refusedError
		if errors.As(err, &refused) || ctx.Err() != nil || attempt >= maxAttempts {
			return err
		}
		attempt++
		time.Sleep(time.Duration(attempt) * time.Second)
		// Where the server has it now, after the break.
		if at, headErr := c.offset(ctx, location.String()); headErr == nil {
			offset = at
		}
	}
	return nil
}

type refusedError struct{ err error }

func (e *refusedError) Error() string { return e.err.Error() }

func (c *client) part(ctx context.Context, location string, f *file, offset int64) (int64, error) {
	source, err := os.Open(f.path)
	if err != nil {
		return 0, &refusedError{err}
	}
	defer func() { _ = source.Close() }()
	if _, err := source.Seek(offset, io.SeekStart); err != nil {
		return 0, &refusedError{err}
	}
	length := min(int64(chunkSize), f.size-offset)
	req, err := http.NewRequestWithContext(ctx, http.MethodPatch, location, io.LimitReader(source, length))
	if err != nil {
		return 0, err
	}
	req.ContentLength = length
	req.Header.Set(keyHeader, c.key)
	req.Header.Set("Tus-Resumable", tusVersion)
	req.Header.Set("Upload-Offset", strconv.FormatInt(offset, 10))
	req.Header.Set("Content-Type", "application/offset+octet-stream")
	resp, err := (&http.Client{}).Do(req)
	if err != nil {
		return 0, err
	}
	defer func() { _ = resp.Body.Close() }()
	switch {
	case resp.StatusCode == http.StatusNoContent:
		return strconv.ParseInt(resp.Header.Get("Upload-Offset"), 10, 64)
	case resp.StatusCode == checksumError:
		return 0, &refusedError{errors.New("the file was damaged on the way, or changed while it was sent")}
	case resp.StatusCode >= http.StatusInternalServerError || resp.StatusCode == http.StatusConflict:
		return 0, serverError(resp)
	default:
		return 0, &refusedError{serverError(resp)}
	}
}

func (c *client) offset(ctx context.Context, location string) (int64, error) {
	resp, err := c.request(ctx, http.MethodHead, location, nil, map[string]string{"Tus-Resumable": tusVersion})
	if err != nil {
		return 0, err
	}
	_ = resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return 0, fmt.Errorf("the server answered %d", resp.StatusCode)
	}
	return strconv.ParseInt(resp.Header.Get("Upload-Offset"), 10, 64)
}

func formatBytes(n int64) string {
	const unit = 1024
	if n < unit {
		return fmt.Sprintf("%d B", n)
	}
	value, exp := float64(n), 0
	for value >= unit && exp < 4 {
		value /= unit
		exp++
	}
	return fmt.Sprintf("%.1f %s", value, []string{"B", "KB", "MB", "GB", "TB"}[exp])
}

func upload(ctx context.Context, args []string, out io.Writer) error {
	flags := uploadFlags(out)
	if err := flags.Parse(args); err != nil {
		return err
	}
	opts := uploadOptions{
		album:       flags.Lookup("album").Value.String(),
		recursive:   flags.Lookup("recursive").Value.String() == "true",
		dryRun:      flags.Lookup("dry-run").Value.String() == "true",
		deleteAfter: flags.Lookup("delete-after").Value.String() == "true",
	}
	opts.jobs, _ = strconv.Atoi(flags.Lookup("jobs").Value.String())
	opts.jobs = min(max(opts.jobs, 1), 16)
	if flags.NArg() == 0 {
		return errors.New("say which folders or files to upload")
	}
	cfg, err := loadConfig()
	if err != nil {
		return err
	}
	c := &client{server: cfg.Server, key: cfg.Key, http: &http.Client{Timeout: requestWait}}

	files, err := collect(flags.Args(), opts.recursive)
	if err != nil {
		return err
	}
	var total int64
	for i := range files {
		total += files[i].size
	}
	_, _ = fmt.Fprintf(out, "%d photos and videos, %s. Checking what the server already has…\n", len(files), formatBytes(total))
	for i := range files {
		if ctx.Err() != nil {
			return ctx.Err()
		}
		if files[i].checksum, err = checksumOf(files[i].path); err != nil {
			return fmt.Errorf("read %s: %w", files[i].path, err)
		}
	}
	have := map[string]bool{}
	for start := 0; start < len(files); start += checkBatch {
		end := min(start+checkBatch, len(files))
		sums := make([]string, 0, end-start)
		for _, f := range files[start:end] {
			sums = append(sums, f.checksum)
		}
		found, err := c.existing(ctx, sums)
		if err != nil {
			return err
		}
		for sum := range found {
			have[sum] = true
		}
	}
	var waiting []*file
	already := 0
	for i := range files {
		if have[files[i].checksum] {
			already++
			continue
		}
		waiting = append(waiting, &files[i])
	}
	if opts.dryRun {
		for _, f := range waiting {
			_, _ = fmt.Fprintf(out, "would send %s (%s)\n", f.path, formatBytes(f.size))
		}
		_, _ = fmt.Fprintf(out, "Dry run: %d would be sent, %d are already on the server.\n", len(waiting), already)
		return nil
	}
	album := ""
	if opts.album != "" {
		if album, err = c.albumID(ctx, opts.album); err != nil {
			return err
		}
	}

	var (
		sent, failed atomic.Int64
		bytes        atomic.Int64
		mu           sync.Mutex
		problems     []string
		wg           sync.WaitGroup
	)
	work := make(chan *file)
	for range opts.jobs {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for f := range work {
				err := c.send(ctx, f, album)
				mu.Lock()
				if err != nil {
					failed.Add(1)
					problems = append(problems, fmt.Sprintf("%s: %v", f.path, err))
					_, _ = fmt.Fprintf(out, "✗ %s: %v\n", filepath.Base(f.path), err)
				} else {
					n := sent.Add(1)
					done := bytes.Add(f.size)
					_, _ = fmt.Fprintf(out, "✓ %s  (%d/%d, %s)\n", filepath.Base(f.path), n, len(waiting), formatBytes(done))
				}
				mu.Unlock()
			}
		}()
	}
	for _, f := range waiting {
		if ctx.Err() != nil {
			break
		}
		work <- f
	}
	close(work)
	wg.Wait()

	deleted := 0
	if opts.deleteAfter && ctx.Err() == nil {
		deleted, err = deleteConfirmed(ctx, c, files)
		if err != nil {
			_, _ = fmt.Fprintf(out, "Not deleted: %v\n", err)
		}
	}
	_, _ = fmt.Fprintf(out, "Sent %d (%s), already on the server %d, failed %d.", sent.Load(), formatBytes(bytes.Load()), already, failed.Load())
	if opts.deleteAfter {
		_, _ = fmt.Fprintf(out, " Deleted here: %d.", deleted)
	}
	_, _ = fmt.Fprintln(out)
	if ctx.Err() != nil {
		return errors.New("stopped; run the same command again to go on")
	}
	if failed.Load() > 0 {
		return fmt.Errorf("%d files were not sent", failed.Load())
	}
	return nil
}

// deleteConfirmed deletes local files only after asking the server once more which checksums it
// has: a file goes only when the server has exactly it.
func deleteConfirmed(ctx context.Context, c *client, files []file) (int, error) {
	deleted := 0
	for start := 0; start < len(files); start += checkBatch {
		end := min(start+checkBatch, len(files))
		sums := make([]string, 0, end-start)
		for _, f := range files[start:end] {
			sums = append(sums, f.checksum)
		}
		have, err := c.existing(ctx, sums)
		if err != nil {
			return deleted, err
		}
		for _, f := range files[start:end] {
			if !have[f.checksum] {
				continue
			}
			// The file must still be the one the server has.
			now, err := checksumOf(f.path)
			if err != nil || now != f.checksum {
				continue
			}
			if os.Remove(f.path) == nil {
				deleted++
			}
		}
	}
	return deleted, nil
}
