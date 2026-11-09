package app

import (
	"context"
	"errors"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgtype"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/auth"
	"github.com/mediarr-app/mediarr/server/internal/storage"
)

const (
	maxAvatarUpload = 20 << 20
	avatarSize      = "512x512"
	avatarWait      = time.Minute
	maxNameLength   = 200
)

// avatarPath is where a person's picture is kept: with the library, so that a backup has it.
func avatarPath(library string, id uuid.UUID) string {
	return filepath.Join(library, ".avatars", id.String()+".webp")
}

func (s *apiServer) UpdateProfile(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	var body api.ProfileUpdate
	if !readJSON(w, r, &body) {
		return
	}
	name, email, language := user.Name, user.Email, user.Language
	if body.Language != nil {
		if !body.Language.Valid() {
			writeError(w, http.StatusBadRequest, "that language is not offered")
			return
		}
		language = pgtype.Text{String: string(*body.Language), Valid: true}
	}
	if body.Name != nil {
		name = strings.TrimSpace(*body.Name)
		if name == "" || len(name) > maxNameLength {
			writeError(w, http.StatusBadRequest, "enter a name")
			return
		}
	}
	if body.Email != nil {
		normalized, err := auth.NormalizeEmail(*body.Email)
		if err != nil {
			writeError(w, http.StatusBadRequest, err.Error())
			return
		}
		// Signing in goes by the email address, so changing it takes the password.
		if normalized != user.Email {
			if body.CurrentPassword == nil || !auth.VerifyPassword(user.PasswordHash, *body.CurrentPassword) {
				writeError(w, http.StatusUnauthorized, "enter your current password to change your email address")
				return
			}
		}
		email = normalized
	}
	updated, err := s.queries.SetUserProfile(r.Context(), db.SetUserProfileParams{ID: user.ID, Name: name, Email: email, Language: language})
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) && pgErr.Code == uniqueViolated {
		writeError(w, http.StatusConflict, "another account has this email address")
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, toAPIUser(&updated))
}

// SetAvatar takes any picture a browser or phone can send and keeps a square WebP of it, cut where
// the picture is busiest, which is usually the face.
func (s *apiServer) SetAvatar(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	if !strings.HasPrefix(r.Header.Get("Content-Type"), "image/") {
		writeError(w, http.StatusBadRequest, "send a picture")
		return
	}
	tmpDir := storage.TmpDir(s.LibraryPath)
	if err := os.MkdirAll(tmpDir, 0o750); err != nil {
		internalError(w, r, err)
		return
	}
	in, err := os.CreateTemp(tmpDir, "avatar-*")
	if err != nil {
		internalError(w, r, err)
		return
	}
	defer func() { _ = os.Remove(in.Name()) }()
	written, err := io.Copy(in, io.LimitReader(r.Body, maxAvatarUpload+1))
	_ = in.Close()
	if err != nil {
		writeError(w, http.StatusBadRequest, "the picture did not arrive whole")
		return
	}
	if written > maxAvatarUpload {
		writeError(w, http.StatusRequestEntityTooLarge, "the picture is larger than 20 MB")
		return
	}
	id := uuid.UUID(user.ID.Bytes)
	dest := avatarPath(s.LibraryPath, id)
	if err := os.MkdirAll(filepath.Dir(dest), 0o750); err != nil {
		internalError(w, r, err)
		return
	}
	out := dest + ".new.webp"
	if err := makeAvatar(r.Context(), in.Name(), out); err != nil {
		_ = os.Remove(out)
		writeError(w, http.StatusBadRequest, "this picture cannot be read")
		return
	}
	if err := os.Rename(out, dest); err != nil {
		internalError(w, r, err)
		return
	}
	updated, err := s.queries.SetUserAvatar(r.Context(), db.SetUserAvatarParams{ID: user.ID, Present: true})
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, toAPIUser(&updated))
}

// makeAvatar cuts a square with libvips, the tool the previews are made with.
func makeAvatar(ctx context.Context, in, out string) error {
	ctx, cancel := context.WithTimeout(ctx, avatarWait)
	defer cancel()
	//nolint:gosec // Both paths are made here, not taken from the request.
	cmd := exec.CommandContext(ctx, "vipsthumbnail", in, "--size", avatarSize, "--smartcrop", "attention", "-o", out+"[Q=82,strip]")
	return cmd.Run()
}

func (s *apiServer) RemoveAvatar(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	if err := os.Remove(avatarPath(s.LibraryPath, uuid.UUID(user.ID.Bytes))); err != nil && !errors.Is(err, os.ErrNotExist) {
		internalError(w, r, err)
		return
	}
	updated, err := s.queries.SetUserAvatar(r.Context(), db.SetUserAvatarParams{ID: user.ID, Present: false})
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, toAPIUser(&updated))
}

// GetAvatar shows a person's picture to anyone signed in here, as the people one shares albums with
// are shown by it. Its address carries the version, so it can be kept for long.
func (s *apiServer) GetAvatar(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	if requireUser(w, r) == nil {
		return
	}
	owner, err := s.queries.GetUserByID(r.Context(), pgtype.UUID{Bytes: id, Valid: true})
	if err != nil || owner.AvatarVersion == 0 {
		writeError(w, http.StatusNotFound, "no picture")
		return
	}
	file, err := os.Open(avatarPath(s.LibraryPath, id))
	if err != nil {
		writeError(w, http.StatusNotFound, "no picture")
		return
	}
	defer func() { _ = file.Close() }()
	w.Header().Set("Content-Type", "image/webp")
	w.Header().Set("Cache-Control", "private, max-age=31536000, immutable")
	w.Header().Set("ETag", strconv.Quote(strconv.Itoa(int(owner.AvatarVersion))))
	http.ServeContent(w, r, "avatar.webp", time.Time{}, file)
}
