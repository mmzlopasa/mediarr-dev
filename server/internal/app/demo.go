package app

import (
	"net/http"
	"strings"
)

// demoReadOnly keeps a shared public account as it is: its password, photos and keys cannot change,
// and nobody can use it to store files or run the slow AI model. Signing in and out still work.
func (s *apiServer) demoReadOnly(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		user := currentUser(r)
		if s.DemoEmail == "" || user == nil || !strings.EqualFold(user.Email, s.DemoEmail) || !demoBlocked(r) {
			next.ServeHTTP(w, r)
			return
		}
		writeError(w, http.StatusForbidden, "this is a public demo, so nothing can be changed here")
	})
}

func demoBlocked(r *http.Request) bool {
	if r.URL.Path == "/api/auth/login" || r.URL.Path == "/api/auth/logout" {
		return false
	}
	return r.Method != http.MethodGet && r.Method != http.MethodHead && r.Method != http.MethodOptions
}
