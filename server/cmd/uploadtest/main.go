// Command uploadtest uploads a directory through the real API and checks the phase 2 gate.
package main

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"net/http"
	"net/http/cookiejar"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"
)

type tester struct {
	base   string
	client *http.Client
}

func (t *tester) request(ctx context.Context, method, path string, headers map[string]string, body io.Reader) (*http.Response, []byte, error) {
	url := path
	if strings.HasPrefix(path, "/") {
		url = t.base + path
	}
	req, err := http.NewRequestWithContext(ctx, method, url, body)
	if err != nil {
		return nil, nil, err
	}
	for key, value := range headers {
		req.Header.Set(key, value)
	}
	resp, err := t.client.Do(req)
	if err != nil {
		return nil, nil, err
	}
	defer func() { _ = resp.Body.Close() }()
	data, err := io.ReadAll(resp.Body)
	return resp, data, err
}

func (t *tester) upload(ctx context.Context, path string) (duplicate bool, err error) {
	f, err := os.Open(path)
	if err != nil {
		return false, err
	}
	defer func() { _ = f.Close() }()
	info, err := f.Stat()
	if err != nil {
		return false, err
	}
	meta := "filename " + base64.StdEncoding.EncodeToString([]byte(filepath.Base(path)))
	resp, body, err := t.request(ctx, http.MethodPost, "/api/uploads", map[string]string{
		"Tus-Resumable":   "1.0.0",
		"Upload-Length":   strconv.FormatInt(info.Size(), 10),
		"Upload-Metadata": meta,
	}, nil)
	if err != nil {
		return false, err
	}
	if resp.StatusCode != http.StatusCreated {
		return false, fmt.Errorf("create: %d %s", resp.StatusCode, body)
	}
	location := resp.Header.Get("Location")
	resp, body, err = t.request(ctx, http.MethodPatch, location, map[string]string{
		"Tus-Resumable": "1.0.0",
		"Upload-Offset": "0",
		"Content-Type":  "application/offset+octet-stream",
	}, f)
	if err != nil {
		return false, err
	}
	if resp.StatusCode != http.StatusNoContent {
		return false, fmt.Errorf("patch: %d %s", resp.StatusCode, body)
	}
	return resp.Header.Get("X-Asset-Duplicate") == "true", nil
}

type pass struct {
	uploaded, duplicates, failed atomic.Int64
}

func (t *tester) uploadAll(ctx context.Context, files []string, parallel int) *pass {
	result := &pass{}
	work := make(chan string)
	var wg sync.WaitGroup
	for range parallel {
		wg.Go(func() {
			for path := range work {
				duplicate, err := t.upload(ctx, path)
				switch {
				case err != nil:
					result.failed.Add(1)
					fmt.Printf("FAILED %s: %v\n", path, err)
				case duplicate:
					result.duplicates.Add(1)
				default:
					result.uploaded.Add(1)
				}
			}
		})
	}
	for _, path := range files {
		work <- path
	}
	close(work)
	wg.Wait()
	return result
}

type asset struct {
	OriginalName string `json:"originalName"`
	Error        string `json:"error"`
	Status       string `json:"status"`
}

type assetList struct {
	Items      []asset `json:"items"`
	Total      int64   `json:"total"`
	Processing int64   `json:"processing"`
	Failed     int64   `json:"failed"`
}

func (t *tester) status(ctx context.Context) (*assetList, error) {
	resp, body, err := t.request(ctx, http.MethodGet, "/api/assets?limit=200", nil, nil)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("list: %d %s", resp.StatusCode, body)
	}
	var list assetList
	return &list, json.Unmarshal(body, &list)
}

func (t *tester) failedNames(ctx context.Context) ([]asset, error) {
	resp, body, err := t.request(ctx, http.MethodGet, "/api/assets?limit=200&status=failed", nil, nil)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("list: %d %s", resp.StatusCode, body)
	}
	var list assetList
	err = json.Unmarshal(body, &list)
	return list.Items, err
}

func collect(dir string) (good, broken []string, err error) {
	err = filepath.WalkDir(dir, func(path string, entry fs.DirEntry, walkErr error) error {
		if walkErr != nil || entry.IsDir() {
			return walkErr
		}
		if strings.Contains(path, string(filepath.Separator)+"broken"+string(filepath.Separator)) {
			broken = append(broken, path)
		} else {
			good = append(good, path)
		}
		return nil
	})
	return good, broken, err
}

func run() error {
	base := flag.String("url", "http://127.0.0.1:9852", "server URL")
	dir := flag.String("dir", "", "directory to upload")
	email := flag.String("email", "", "user email")
	parallel := flag.Int("parallel", 4, "parallel uploads")
	wait := flag.Duration("wait", 2*time.Hour, "how long to wait for processing")
	flag.Parse()
	password := os.Getenv("UPLOADTEST_PASSWORD")
	if *dir == "" || *email == "" || password == "" {
		return errors.New("needs -dir, -email and UPLOADTEST_PASSWORD")
	}

	jar, err := cookiejar.New(nil)
	if err != nil {
		return err
	}
	t := &tester{base: *base, client: &http.Client{Jar: jar}}
	ctx := context.Background()

	login, err := json.Marshal(map[string]string{"email": *email, "password": password})
	if err != nil {
		return err
	}
	resp, body, err := t.request(ctx, http.MethodPost, "/api/auth/login", map[string]string{"Content-Type": "application/json"}, bytes.NewReader(login))
	if err != nil {
		return err
	}
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("login: %d %s", resp.StatusCode, body)
	}

	good, broken, err := collect(*dir)
	if err != nil {
		return err
	}
	before, err := t.status(ctx)
	if err != nil {
		return err
	}
	fmt.Printf("files: %d good, %d broken; assets before: %d\n", len(good), len(broken), before.Total)

	started := time.Now()
	first := t.uploadAll(ctx, append(append([]string{}, good...), broken...), *parallel)
	fmt.Printf("first pass: %d new, %d duplicates, %d failed, %s\n", first.uploaded.Load(), first.duplicates.Load(), first.failed.Load(), time.Since(started).Round(time.Second))

	deadline := time.Now().Add(*wait)
	var list *assetList
	for {
		list, err = t.status(ctx)
		if err != nil {
			fmt.Printf("status error, retrying: %v\n", err)
		} else if list.Processing == 0 {
			break
		} else {
			fmt.Printf("processing: %d of %d, failed %d, %s\n", list.Processing, list.Total, list.Failed, time.Since(started).Round(time.Second))
		}
		if time.Now().After(deadline) {
			return errors.New("processing did not finish in time")
		}
		time.Sleep(15 * time.Second)
	}
	fmt.Printf("processed in %s: total %d, failed %d\n", time.Since(started).Round(time.Second), list.Total, list.Failed)

	second := t.uploadAll(ctx, good, *parallel)
	fmt.Printf("second pass: %d new, %d duplicates, %d failed\n", second.uploaded.Load(), second.duplicates.Load(), second.failed.Load())

	var problems []string
	failed, err := t.failedNames(ctx)
	if err != nil {
		return err
	}
	expected := map[string]bool{}
	for _, path := range broken {
		expected[filepath.Base(path)] = true
	}
	for _, asset := range failed {
		fmt.Printf("failed: %s: %s\n", asset.OriginalName, asset.Error)
		if !expected[asset.OriginalName] {
			problems = append(problems, asset.OriginalName+" failed, but it is not broken on purpose")
		}
		if strings.Contains(asset.Error, "/data/") {
			problems = append(problems, asset.OriginalName+" shows an internal path in its error")
		}
	}
	if len(broken) > 0 && len(failed) == 0 {
		problems = append(problems, "no broken file was reported as failed")
	}
	if first.failed.Load() != 0 {
		problems = append(problems, "the first pass had failed uploads")
	}
	if second.uploaded.Load() != 0 {
		problems = append(problems, "the second pass was not fully deduplicated")
	}
	if second.failed.Load() != 0 {
		problems = append(problems, "the second pass had failed uploads")
	}
	if int64(len(failed)) != list.Failed {
		problems = append(problems, fmt.Sprintf("%d failed assets were checked, out of %d; the list limit is too small", len(failed), list.Failed))
	}
	if len(problems) > 0 {
		return errors.New(strings.Join(problems, "; "))
	}
	fmt.Println("gate passed")
	return nil
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "uploadtest:", err)
		os.Exit(1)
	}
}
