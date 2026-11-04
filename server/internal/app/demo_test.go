package app

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/mediarr-app/mediarr/server/db"
)

func TestTheDemoAccountChangesNothing(t *testing.T) {
	s := &apiServer{Deps: Deps{DemoEmail: "demo@mediarr.app"}}
	handler := s.demoReadOnly(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	}))
	send := func(email, method, path string) int {
		request := httptest.NewRequestWithContext(context.Background(), method, path, http.NoBody)
		if email != "" {
			request = request.WithContext(context.WithValue(request.Context(), userKey{}, &db.User{Email: email}))
		}
		answer := httptest.NewRecorder()
		handler.ServeHTTP(answer, request)
		return answer.Code
	}
	for _, tc := range []struct {
		email, method, path string
		want                int
	}{
		{"demo@mediarr.app", http.MethodGet, "/api/timeline/buckets", http.StatusNoContent},
		{"DEMO@mediarr.app", http.MethodPost, "/api/uploads", http.StatusForbidden},
		{"demo@mediarr.app", http.MethodPatch, "/api/uploads/x", http.StatusForbidden},
		{"demo@mediarr.app", http.MethodDelete, "/api/assets/x", http.StatusForbidden},
		{"demo@mediarr.app", http.MethodPost, "/api/me/password", http.StatusForbidden},
		{"demo@mediarr.app", http.MethodPost, "/api/me/api-keys", http.StatusForbidden},
		{"demo@mediarr.app", http.MethodPost, "/api/search/ask", http.StatusForbidden},
		{"demo@mediarr.app", http.MethodPost, "/api/auth/logout", http.StatusNoContent},
		{"someone@example.com", http.MethodDelete, "/api/assets/x", http.StatusNoContent},
		{"", http.MethodPost, "/api/auth/login", http.StatusNoContent},
	} {
		if got := send(tc.email, tc.method, tc.path); got != tc.want {
			t.Errorf("%s %s %s: %d", tc.email, tc.method, tc.path, got)
		}
	}
}
