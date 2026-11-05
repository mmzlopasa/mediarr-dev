package app

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

const maxLoginMessage = 1000

func settingsToAPI(in *jobs.ServerSettings) api.ServerSettings {
	return api.ServerSettings{
		TrashDays: in.TrashDays, ImageQuality: in.ImageQuality, PreviewSize: in.PreviewSize,
		VideoQuality: in.VideoQuality, VideoMaxHeight: in.VideoMaxHeight,
		LoginMessage: in.LoginMessage, PasswordLogin: in.PasswordLogin,
	}
}

func (s *apiServer) GetServerSettings(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	settings, err := jobs.LoadServerSettings(r.Context(), s.queries)
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, settingsToAPI(&settings))
}

func (s *apiServer) SetServerSettings(w http.ResponseWriter, r *http.Request) {
	if requireAdmin(w, r) == nil {
		return
	}
	var body api.ServerSettings
	if !readJSON(w, r, &body) {
		return
	}
	body.LoginMessage = strings.TrimSpace(body.LoginMessage)
	problem := ""
	switch {
	case body.TrashDays < 1 || body.TrashDays > 3650:
		problem = "the trash keeps photos for 1 to 3650 days"
	case body.ImageQuality < 40 || body.ImageQuality > 100:
		problem = "image quality must be between 40 and 100"
	case body.PreviewSize < 720 || body.PreviewSize > 4096:
		problem = "the preview size must be between 720 and 4096"
	case body.VideoQuality < 18 || body.VideoQuality > 40:
		problem = "video quality must be between 18 and 40, where lower is better"
	case body.VideoMaxHeight != 720 && body.VideoMaxHeight != 1080 && body.VideoMaxHeight != 1440 && body.VideoMaxHeight != 2160:
		problem = "the largest video must be 720, 1080, 1440 or 2160"
	case len(body.LoginMessage) > maxLoginMessage:
		problem = "the sign-in message is too long"
	}
	if problem != "" {
		writeError(w, http.StatusBadRequest, problem)
		return
	}
	ctx := r.Context()
	if !body.PasswordLogin {
		oidc, err := s.loadOIDC(ctx)
		if err != nil {
			internalError(w, r, err)
			return
		}
		if !oidc.enabled() {
			writeError(w, http.StatusBadRequest, "set up single sign-on before turning off passwords, or nobody could sign in")
			return
		}
	}
	data, err := json.Marshal(jobs.ServerSettings{
		TrashDays: body.TrashDays, ImageQuality: body.ImageQuality, PreviewSize: body.PreviewSize,
		VideoQuality: body.VideoQuality, VideoMaxHeight: body.VideoMaxHeight,
		LoginMessage: body.LoginMessage, PasswordLogin: body.PasswordLogin,
	})
	if err != nil {
		internalError(w, r, err)
		return
	}
	if err := s.queries.SetState(ctx, db.SetStateParams{Key: jobs.StateServerSettings, Value: string(data)}); err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, body)
}
