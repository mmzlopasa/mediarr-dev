package app

import (
	"context"
	"crypto/sha256"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/auth"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
	"github.com/mediarr-app/mediarr/server/internal/words"
)

const (
	visitorCookie     = "mediarr_visitor"
	visitorLifetime   = 365 * 24 * time.Hour
	maxVisitorName    = 80
	maxVisiblePeople  = 100
	hideNone          = "none"
	hideExcept        = "except"
	errNameFirstReply = "say who you are first"
	browserOther      = "Browser"
)

func hideFacesOf(value *api.HideFaces) (string, bool) {
	if value == nil {
		return hideNone, true
	}
	return string(*value), value.Valid()
}

// setLinkPrivacy writes what a link leaves out. A change makes the link's private copies anew.
func (s *apiServer) setLinkPrivacy(ctx context.Context, link db.ShareLink, owner pgtype.UUID, body *api.LinkPrivacy) (db.ShareLink, string) {
	hide := link.HideFaces
	if body.HideFaces != nil {
		value, ok := hideFacesOf(body.HideFaces)
		if !ok {
			return link, "choose none, all or except for faces"
		}
		hide = value
	}
	if body.VisiblePeople != nil && len(*body.VisiblePeople) > maxVisiblePeople {
		return link, "name at most 100 people"
	}
	updated, err := s.queries.SetLinkPrivacy(ctx, db.SetLinkPrivacyParams{
		ID: link.ID, AlbumID: link.AlbumID,
		ShowLocation: flag(body.ShowLocation, link.ShowLocation) && !link.UploadOnly,
		HideFaces:    hide,
		StripCamera:  flag(body.StripCamera, link.StripCamera),
		StripDate:    flag(body.StripDate, link.StripDate),
		AskName:      flag(body.AskName, link.AskName),
	})
	if err != nil {
		return link, err.Error()
	}
	if body.VisiblePeople != nil {
		if err := s.queries.ClearLinkVisiblePeople(ctx, link.ID); err != nil {
			return updated, err.Error()
		}
		if err := s.queries.AddLinkVisiblePeople(ctx, db.AddLinkVisiblePeopleParams{
			LinkID: link.ID, People: toPg(*body.VisiblePeople), OwnerID: owner,
		}); err != nil {
			return updated, err.Error()
		}
	}
	// Copies made with the old choices must never be served again.
	s.removeLinkCache(link.ID)
	return updated, ""
}

// linkExtras adds who may be seen and how often the links were opened.
func (s *apiServer) linkExtras(ctx context.Context, links []api.ShareLink) error {
	ids := make([]pgtype.UUID, len(links))
	for i := range links {
		ids[i] = pgUUID(links[i].Id)
	}
	stats, err := s.queries.LinkVisitStats(ctx, ids)
	if err != nil {
		return err
	}
	byLink := map[pgtype.UUID]db.LinkVisitStatsRow{}
	for _, row := range stats {
		byLink[row.LinkID] = row
	}
	for i := range links {
		link := &links[i]
		id := pgUUID(link.Id)
		people, err := s.queries.ListLinkVisiblePeople(ctx, id)
		if err != nil {
			return err
		}
		visible := make([]openapi_types.UUID, len(people))
		for j, person := range people {
			visible[j] = person.Bytes
		}
		link.VisiblePeople = &visible
		visits := 0
		if row, ok := byLink[id]; ok {
			visits = int(row.Visits)
			link.LastVisitAt = &row.LastAt.Time
		}
		link.Visits = &visits
	}
	return nil
}

func (s *apiServer) UpdateAlbumLink(w http.ResponseWriter, r *http.Request, id, linkID openapi_types.UUID) {
	album, user, ok := s.album(w, r, id, roleOwner)
	if !ok {
		return
	}
	var body api.LinkPrivacy
	if !readJSON(w, r, &body) {
		return
	}
	ctx := r.Context()
	link, err := s.queries.GetAlbumLink(ctx, db.GetAlbumLinkParams{ID: pgUUID(linkID), AlbumID: album.ID})
	if db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "no such link")
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	updated, problem := s.setLinkPrivacy(ctx, link, user.ID, &body)
	if problem != "" {
		writeError(w, http.StatusBadRequest, problem)
		return
	}
	out := []api.ShareLink{toAPILink(&updated)}
	if err := s.linkExtras(ctx, out); err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, out[0])
}

func (s *apiServer) ListLinkVisits(w http.ResponseWriter, r *http.Request, id, linkID openapi_types.UUID) {
	album, _, ok := s.album(w, r, id, roleOwner)
	if !ok {
		return
	}
	ctx := r.Context()
	if _, err := s.queries.GetAlbumLink(ctx, db.GetAlbumLinkParams{ID: pgUUID(linkID), AlbumID: album.ID}); err != nil {
		if db.IsNotFound(err) {
			writeError(w, http.StatusNotFound, "no such link")
			return
		}
		internalError(w, r, err)
		return
	}
	rows, err := s.queries.ListLinkVisits(ctx, pgUUID(linkID))
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := make([]api.LinkVisit, len(rows))
	for i, row := range rows {
		out[i] = api.LinkVisit{
			At: row.At.Time, Device: row.Device, Viewed: int(row.Viewed), Downloaded: int(row.Downloaded),
			Name: optional(row.Name, row.Name != ""), City: optional(row.City, row.City != ""),
			Country: optional(row.Country, row.Country != ""),
		}
	}
	writeJSON(w, http.StatusOK, out)
}

func (s *apiServer) GetAlbumPrivacy(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	album, _, ok := s.album(w, r, id, roleOwner)
	if !ok {
		return
	}
	facts, err := s.queries.AlbumPrivacyFacts(r.Context(), album.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, api.AlbumPrivacy{Photos: int(facts.Photos), Unchecked: int(facts.Unchecked), Videos: int(facts.Videos)})
}

// visitorOf is this browser for one link: a hash of its own cookie, so visits are never a person.
func visitorOf(r *http.Request, link pgtype.UUID) ([]byte, bool) {
	cookie, err := r.Cookie(visitorCookie)
	if err != nil || cookie.Value == "" {
		return nil, false
	}
	sum := sha256.Sum256(append([]byte(cookie.Value), link.Bytes[:]...))
	return sum[:], true
}

// isOwnerLooking is the album's owner trying their own link; that is not a visit.
func isOwnerLooking(r *http.Request, link *db.GetLinkByTokenRow) bool {
	user := currentUser(r)
	return user != nil && user.ID == link.OwnerID
}

// recordVisit notes the first time a browser opens a link, roughly where from and on what, and tells
// the owner when the link is opened for the very first time.
func (s *apiServer) recordVisit(w http.ResponseWriter, r *http.Request, token string, link *db.GetLinkByTokenRow) {
	if isOwnerLooking(r, link) {
		return
	}
	if _, err := r.Cookie(visitorCookie); err != nil {
		value, _, err := auth.NewToken()
		if err != nil {
			return
		}
		cookie := &http.Cookie{
			Name: visitorCookie, Value: value, Path: publicPathPrefix + token, MaxAge: int(visitorLifetime.Seconds()),
			HttpOnly: true, SameSite: http.SameSiteLaxMode, Secure: isHTTPS(r),
		}
		http.SetCookie(w, cookie)
		r.AddCookie(cookie)
	}
	visitor, ok := visitorOf(r, link.ID)
	if !ok {
		return
	}
	ctx := r.Context()
	city, country := s.geo.Place(hostOnly(clientIP(r)))
	visit, err := s.queries.RecordLinkVisit(ctx, db.RecordLinkVisitParams{
		LinkID: link.ID, VisitorHash: visitor, City: city, Country: country, Device: deviceOf(r.UserAgent()),
	})
	if err != nil || !visit.Fresh {
		return
	}
	count, err := s.queries.CountAllLinkVisits(ctx, link.ID)
	if err != nil || count != 1 {
		return
	}
	subject := link.Label
	if subject == "" {
		subject = link.Title
	}
	if err := s.queries.CreateNotification(ctx, db.CreateNotificationParams{
		UserID: link.OwnerID, Kind: jobs.NotifyLinkOpened, Subject: subject, Ref: uuid.UUID(link.AlbumID.Bytes).String(),
	}); err != nil {
		slog.Warn("a notification was not saved", "error", err)
	}
	if owner, err := s.queries.GetUserByID(ctx, link.OwnerID); err == nil {
		s.sendLater(owner.Email, words.Say(owner.Language.String, words.LinkSubject, subject),
			words.Say(owner.Language.String, words.LinkBody, subject))
	}
}

// visitorNamed is whether a link that asks for a name has been told one by this browser.
func (s *apiServer) visitorNamed(r *http.Request, link *db.GetLinkByTokenRow) bool {
	if !link.AskName || isOwnerLooking(r, link) {
		return true
	}
	visitor, ok := visitorOf(r, link.ID)
	if !ok {
		return false
	}
	named, err := s.queries.LinkVisitNamed(r.Context(), db.LinkVisitNamedParams{LinkID: link.ID, VisitorHash: visitor})
	return err == nil && named
}

func (s *apiServer) NameLinkVisitor(w http.ResponseWriter, r *http.Request, token string) {
	link, ok := s.openLink(w, r, token)
	if !ok {
		return
	}
	var body api.LinkVisitor
	if !readJSON(w, r, &body) {
		return
	}
	name := strings.TrimSpace(body.Name)
	if name == "" || utf8.RuneCountInString(name) > maxVisitorName {
		writeError(w, http.StatusBadRequest, "say who you are, in up to 80 characters")
		return
	}
	visitor, ok := visitorOf(r, link.ID)
	if !ok {
		writeError(w, http.StatusBadRequest, "open the link first")
		return
	}
	if _, err := s.queries.NameLinkVisit(r.Context(), db.NameLinkVisitParams{LinkID: link.ID, VisitorHash: visitor, Name: name}); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// countVisit adds to what a visitor looked at or took.
func (s *apiServer) countVisit(r *http.Request, link *db.GetLinkByTokenRow, download bool) {
	if isOwnerLooking(r, link) {
		return
	}
	visitor, ok := visitorOf(r, link.ID)
	if !ok {
		return
	}
	params := db.CountLinkVisitViewParams{LinkID: link.ID, VisitorHash: visitor}
	var err error
	if download {
		err = s.queries.CountLinkVisitDownload(r.Context(), db.CountLinkVisitDownloadParams(params))
	} else {
		err = s.queries.CountLinkVisitView(r.Context(), params)
	}
	if err != nil {
		slog.Warn("a visit was not counted", "error", err)
	}
}

// facesOf are the boxes to blur in a picture on this link, in parts of its upright preview.
func (s *apiServer) facesOf(ctx context.Context, link *db.GetLinkByTokenRow, asset pgtype.UUID) ([][4]float32, error) {
	visible := []pgtype.UUID{}
	if link.HideFaces == hideExcept {
		people, err := s.queries.ListLinkVisiblePeople(ctx, link.ID)
		if err != nil {
			return nil, err
		}
		visible = people
	}
	rows, err := s.queries.FacesToBlur(ctx, db.FacesToBlurParams{AssetID: asset, Visible: visible})
	if err != nil || len(rows) == 0 {
		return nil, err
	}
	width, height, err := s.previewSize(ctx, asset)
	if err != nil {
		return nil, err
	}
	boxes := make([][4]float32, len(rows))
	for i, row := range rows {
		boxes[i] = jobs.RelativeBox(row.X1, row.Y1, row.X2, row.Y2, width, height)
	}
	return boxes, nil
}

// privateCopy is a picture of this link with the faces blurred, made once per link and choice.
func (s *apiServer) privateCopy(ctx context.Context, link *db.GetLinkByTokenRow, asset pgtype.UUID, kind, source, ext string, keepDate bool) (string, error) {
	revision, err := s.editRevision(ctx, asset)
	if err != nil {
		return "", err
	}
	name := fmt.Sprintf("%s-%s-faces-v%d-r%d%s", uuid.UUID(asset.Bytes), kind, link.PrivacyVersion, revision, ext)
	dest := filepath.Join(s.linkCacheDir(link.ID), name)
	if _, err := os.Stat(dest); err == nil {
		return dest, nil
	}
	faces, err := s.facesOf(ctx, link, asset)
	if err != nil {
		return "", err
	}
	select {
	case s.fullPreviews <- struct{}{}:
		defer func() { <-s.fullPreviews }()
	case <-ctx.Done():
		return "", ctx.Err()
	}
	privacy := jobs.Privacy{Faces: faces, Date: !keepDate || link.StripDate, Location: true, Camera: true}
	if err := jobs.BlurFaces(ctx, source, dest, privacy); err != nil {
		return "", err
	}
	return dest, nil
}

// hidesFaces is a link whose pictures show only blurred faces.
func hidesFaces(link *db.GetLinkByTokenRow) bool { return link.HideFaces != hideNone }

// deviceOf names the kind of device and browser from what the browser says it is.
func deviceOf(agent string) string {
	device := "Computer"
	for _, known := range []struct{ marker, name string }{
		{"iPhone", "iPhone"},
		{"iPad", "iPad"},
		{"Android", "Android"},
		{"Windows", "Windows"},
		{"Macintosh", "Mac"},
		{"CrOS", "Chromebook"},
		{"Linux", "Linux"},
	} {
		if strings.Contains(agent, known.marker) {
			device = known.name
			break
		}
	}
	browser := browserOther
	for _, known := range []struct{ marker, name string }{
		{"Edg/", "Edge"},
		{"OPR/", "Opera"},
		{"Firefox/", "Firefox"},
		{"FxiOS", "Firefox"},
		{"CriOS", "Chrome"},
		{"Chrome/", "Chrome"},
		{"Safari/", "Safari"},
	} {
		if strings.Contains(agent, known.marker) {
			browser = known.name
			break
		}
	}
	return device + " · " + browser
}

func (s *apiServer) GetShareableAsset(w http.ResponseWriter, r *http.Request, id openapi_types.UUID, params api.GetShareableAssetParams) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	ctx := r.Context()
	row, err := s.queries.GetVisibleAsset(ctx, db.GetVisibleAssetParams{ID: pgUUID(id), UserID: user.ID})
	if db.IsNotFound(err) {
		writeError(w, http.StatusNotFound, "no such asset")
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	hide, valid := hideFacesOf(params.Faces)
	if !valid || hide == hideExcept {
		writeError(w, http.StatusBadRequest, "faces can be hidden all, or none")
		return
	}
	privacy := jobs.Privacy{Location: !flag(params.Location, false), Camera: !flag(params.Camera, false)}
	var faces func(context.Context) ([][4]float32, error)
	if hide != hideNone {
		faces = func(ctx context.Context) ([][4]float32, error) {
			rows, err := s.queries.FacesToBlur(ctx, db.FacesToBlurParams{AssetID: row.ID, Visible: []pgtype.UUID{}})
			if err != nil || len(rows) == 0 {
				return nil, err
			}
			width, height, err := s.previewSize(ctx, row.ID)
			if err != nil {
				return nil, err
			}
			boxes := make([][4]float32, len(rows))
			for i, face := range rows {
				boxes[i] = jobs.RelativeBox(face.X1, face.Y1, face.X2, face.Y2, width, height)
			}
			return boxes, nil
		}
	}
	dir := filepath.Join(s.CachePath, "shareable", uuid.UUID(user.ID.Bytes).String())
	viewer := pgtype.UUID{}
	if row.UserID == user.ID {
		viewer = user.ID
	}
	s.servePrivate(w, r, &row, dir, privacy, faces, true, viewer)
}
