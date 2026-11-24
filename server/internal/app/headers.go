package app

import (
	"crypto/sha256"
	"encoding/base64"
	"net/http"
	"net/http/httptest"
	"regexp"
	"strings"
)

// apiPolicy is for what the API answers. JSON needs nothing, and a picture or video opened on its
// own still plays. A handler that serves a file of a user sets a stricter one of its own.
const apiPolicy = "default-src 'none'; img-src 'self'; media-src 'self'; frame-ancestors 'self'"

// castSender is where the cast button's library comes from.
const castSender = "https://www.gstatic.com"

// inlineScript finds a script written into the page itself, not loaded from a file.
var inlineScript = regexp.MustCompile(`(?s)<script(\s[^>]*)?>(.*?)</script>`)

// inlineScriptHashes are the hashes the page's own scripts are allowed by: the one that picks light
// or dark before anything shows, and the one that starts the app.
func inlineScriptHashes(page string) []string {
	out := []string{}
	for _, match := range inlineScript.FindAllStringSubmatch(page, -1) {
		if strings.Contains(match[1], "src=") || strings.TrimSpace(match[2]) == "" {
			continue
		}
		sum := sha256.Sum256([]byte(match[2]))
		hash := "'sha256-" + base64.StdEncoding.EncodeToString(sum[:]) + "'"
		if !strings.Contains(strings.Join(out, " "), hash) {
			out = append(out, hash)
		}
	}
	return out
}

// pagePolicy is the policy of the web app. Scripts are the point of it: only the app's own files,
// its two inline scripts and the cast library run. Pictures, map tiles and map styles may come from
// any address, as the administrator chooses the map's source and it may be on plain http.
func pagePolicy(page string) string {
	scripts := append([]string{"'self'"}, inlineScriptHashes(page)...)
	scripts = append(scripts, castSender)
	return strings.Join([]string{
		"default-src 'self'",
		"script-src " + strings.Join(scripts, " "),
		// Svelte sets styles on elements and adds the styles of transitions while they run.
		"style-src 'self' 'unsafe-inline'",
		"img-src 'self' data: blob: http: https:",
		"media-src 'self' blob:",
		"connect-src 'self' http: https:",
		"font-src 'self' data:",
		// The map and the video player do their work in workers made from blobs.
		"worker-src 'self' blob:",
		"child-src 'self' blob:",
		"frame-src 'self' " + castSender,
		"object-src 'none'",
		"base-uri 'self'",
		"frame-ancestors 'self'",
	}, "; ")
}

// embeddedPage is the app's index.html as the binary carries it, or nothing in a build without it.
func embeddedPage(ui http.Handler) string {
	recorder := httptest.NewRecorder()
	ui.ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, "/", nil))
	if recorder.Code != http.StatusOK {
		return ""
	}
	return recorder.Body.String()
}

// securityHeaders goes on every answer. There is no Strict-Transport-Security: Mediarr must keep
// working on http://address:port, and HTTPS is the business of whoever puts a proxy in front.
func securityHeaders(page string) func(http.Handler) http.Handler {
	policy := pagePolicy(page)
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			header := w.Header()
			header.Set("X-Content-Type-Options", "nosniff")
			// A shared link's token is in its address, so other sites get only the origin.
			header.Set("Referrer-Policy", "strict-origin-when-cross-origin")
			header.Set("X-Frame-Options", "SAMEORIGIN")
			header.Set("Cross-Origin-Opener-Policy", "same-origin")
			header.Set("Permissions-Policy", "camera=(), microphone=(), geolocation=(), payment=(), usb=(), interest-cohort=()")
			if strings.HasPrefix(r.URL.Path, "/api/") {
				header.Set("Content-Security-Policy", apiPolicy)
				next.ServeHTTP(w, r)
				return
			}
			// The web app's own handler sets a shorter policy, which this one replaces.
			next.ServeHTTP(&policyWriter{ResponseWriter: w, policy: policy}, r)
		})
	}
}

// policyWriter puts the policy on just before the answer starts, whatever was set before.
type policyWriter struct {
	http.ResponseWriter
	policy string
	sent   bool
}

func (p *policyWriter) WriteHeader(code int) {
	if !p.sent {
		p.sent = true
		p.Header().Set("Content-Security-Policy", p.policy)
	}
	p.ResponseWriter.WriteHeader(code)
}

func (p *policyWriter) Write(data []byte) (int, error) {
	if !p.sent {
		p.WriteHeader(http.StatusOK)
	}
	return p.ResponseWriter.Write(data)
}

func (p *policyWriter) Unwrap() http.ResponseWriter { return p.ResponseWriter }
