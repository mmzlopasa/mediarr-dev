package app

import (
	"context"
	"net"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/dlna"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

// The DLNA server is UPnP, not the Mediarr API: TVs speak SOAP and read XML, and have no way to sign
// in. So it answers only while an administrator has it on, only to the home network, and only with
// the albums of the administrator who turned it on.
const (
	dlnaMaxPage       = 500
	dlnaAnnouncedFor  = 3 * time.Minute
	dlnaNamespaceUUID = "6f1c3a52-5d0e-4c1b-9b7e-2f4a8d9c0e11"
)

func (s *apiServer) mountDLNA(r chi.Router) {
	r.Route("/dlna", func(r chi.Router) {
		r.Use(s.dlnaOnly)
		r.Get("/device.xml", s.dlnaDevice)
		r.Get("/ContentDirectory.xml", dlnaXML(dlna.ContentDirectorySCPD))
		r.Get("/ConnectionManager.xml", dlnaXML(dlna.ConnectionManagerSCPD))
		r.Post("/control/ContentDirectory", s.dlnaContentDirectory)
		r.Post("/control/ConnectionManager", dlnaConnectionManager)
		r.Get("/media/{id}/image.jpg", s.dlnaImage)
		r.Get("/media/{id}/video", s.dlnaVideo)
	})
}

// privateAddress says whether an address is on a home network: never one on the internet.
func privateAddress(value string) bool {
	host := strings.TrimSpace(value)
	if h, _, err := net.SplitHostPort(host); err == nil {
		host = h
	}
	ip := net.ParseIP(host)
	return ip != nil && (ip.IsPrivate() || ip.IsLoopback() || ip.IsLinkLocalUnicast())
}

// fromHomeNetwork checks every address the request passed through, so that a reverse proxy in front
// of Mediarr that is not counted in TRUSTED_PROXIES does not let the internet in.
func fromHomeNetwork(r *http.Request) bool {
	if !privateAddress(r.RemoteAddr) {
		return false
	}
	if proxied := r.Header.Get("X-Real-IP"); proxied != "" && !privateAddress(proxied) {
		return false
	}
	for _, hop := range strings.Split(r.Header.Get("X-Forwarded-For"), ",") {
		if strings.TrimSpace(hop) != "" && !privateAddress(hop) {
			return false
		}
	}
	return true
}

type dlnaOwnerKey struct{}

func (s *apiServer) dlnaOwner(ctx context.Context) (db.User, bool, error) {
	settings, err := jobs.LoadServerSettings(ctx, s.queries)
	if err != nil || settings.DLNAUserID == "" {
		return db.User{}, false, err
	}
	id, err := uuid.Parse(settings.DLNAUserID)
	if err != nil {
		return db.User{}, false, nil //nolint:nilerr // A broken choice is the same as none.
	}
	user, err := s.queries.GetUserByID(ctx, pgtype.UUID{Bytes: id, Valid: true})
	if db.IsNotFound(err) {
		return db.User{}, false, nil
	}
	return user, err == nil, err
}

func (s *apiServer) dlnaOnly(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !fromHomeNetwork(r) {
			http.NotFound(w, r)
			return
		}
		owner, on, err := s.dlnaOwner(r.Context())
		if err != nil {
			internalError(w, r, err)
			return
		}
		if !on {
			http.NotFound(w, r)
			return
		}
		next.ServeHTTP(w, r.WithContext(context.WithValue(r.Context(), dlnaOwnerKey{}, &owner)))
	})
}

func dlnaUser(r *http.Request) *db.User {
	user, _ := r.Context().Value(dlnaOwnerKey{}).(*db.User)
	return user
}

// dlnaUDN stays the same for as long as the same person's albums are shown.
func dlnaUDN(owner pgtype.UUID) string {
	return uuid.NewSHA1(uuid.MustParse(dlnaNamespaceUUID), owner.Bytes[:]).String()
}

func writeXML(w http.ResponseWriter, body string) {
	w.Header().Set("Content-Type", `text/xml; charset="utf-8"`)
	w.Header().Set("X-Content-Type-Options", "nosniff")
	_, _ = w.Write([]byte(body))
}

func dlnaXML(body func() string) http.HandlerFunc {
	return func(w http.ResponseWriter, _ *http.Request) { writeXML(w, body()) }
}

func (s *apiServer) dlnaDevice(w http.ResponseWriter, r *http.Request) {
	if r.Header.Get(dlna.AnnouncerHeader) != "" {
		s.dlnaSeen.Store(time.Now().Unix())
	}
	settings, err := jobs.LoadServerSettings(r.Context(), s.queries)
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeXML(w, dlna.DeviceDescription(dlnaUDN(dlnaUser(r).ID), settings.Name(), Version))
}

// dlnaAnnounced says whether the announcer asked lately, which it does only from the host's network.
func (s *apiServer) dlnaAnnounced() bool {
	seen := s.dlnaSeen.Load()
	return seen > 0 && time.Since(time.Unix(seen, 0)) < dlnaAnnouncedFor
}

func soapReply(w http.ResponseWriter, body string, fault bool) {
	w.Header().Set("Content-Type", `text/xml; charset="utf-8"`)
	w.Header().Set("Ext", "")
	if fault {
		w.WriteHeader(http.StatusInternalServerError)
	}
	_, _ = w.Write([]byte(body))
}

func dlnaConnectionManager(w http.ResponseWriter, r *http.Request) {
	call, err := dlna.ParseAction(r.Body)
	if err != nil {
		soapReply(w, dlna.Fault(401, "invalid action"), true)
		return
	}
	switch call.Name {
	case "GetProtocolInfo":
		soapReply(w, dlna.Response(dlna.ConnectionManager, call.Name, [][2]string{{"Source", dlna.SourceProtocols}, {"Sink", ""}}), false)
	case "GetCurrentConnectionIDs":
		soapReply(w, dlna.Response(dlna.ConnectionManager, call.Name, [][2]string{{"ConnectionIDs", "0"}}), false)
	case "GetCurrentConnectionInfo":
		soapReply(w, dlna.Response(dlna.ConnectionManager, call.Name, [][2]string{
			{"RcsID", "-1"},
			{"AVTransportID", "-1"},
			{"ProtocolInfo", ""},
			{"PeerConnectionManager", ""},
			{"PeerConnectionID", "-1"},
			{"Direction", "Output"},
			{"Status", "OK"},
		}), false)
	default:
		soapReply(w, dlna.Fault(401, "invalid action"), true)
	}
}

// Object ids: "0" is the list of albums, an album is its id, and a photo is album/asset, so that it
// knows where it is.
func splitObject(id string) (album, asset uuid.UUID, kind int) {
	before, after, found := strings.Cut(id, "/")
	a, err := uuid.Parse(before)
	if err != nil {
		return uuid.Nil, uuid.Nil, 0
	}
	if !found {
		return a, uuid.Nil, 1
	}
	b, err := uuid.Parse(after)
	if err != nil {
		return uuid.Nil, uuid.Nil, 0
	}
	return a, b, 2
}

func absoluteURL(r *http.Request, path string) string {
	return "http://" + r.Host + path
}

func dlnaItem(r *http.Request, album uuid.UUID, row *db.ListDLNAAlbumAssetsRow) dlna.Item {
	id := uuid.UUID(row.ID.Bytes)
	base := "/dlna/media/" + id.String()
	item := dlna.Item{
		ID: album.String() + "/" + id.String(), ParentID: album.String(),
		Title: strings.TrimSuffix(row.OriginalName, extOf(row.OriginalName)), Thumbnail: absoluteURL(r, base+"/image.jpg"),
	}
	if row.LocalAt.Valid {
		item.Date = row.LocalAt.Time
		item.Title = row.LocalAt.Time.Format("2006-01-02 15:04")
	}
	if row.Kind == "video" {
		item.Class, item.URL, item.MimeType, item.Size = "object.item.videoItem", absoluteURL(r, base+"/video"), row.MimeType.String, row.SizeBytes
		if row.DurationMs.Valid {
			item.Duration = time.Duration(row.DurationMs.Int64) * time.Millisecond
		}
		if item.MimeType == "" {
			item.MimeType = "video/mp4"
		}
		return item
	}
	item.Class, item.URL, item.MimeType = "object.item.imageItem.photo", item.Thumbnail, "image/jpeg"
	return item
}

func extOf(name string) string {
	if at := strings.LastIndex(name, "."); at > 0 {
		return name[at:]
	}
	return ""
}

func browseValues(result string, returned, total int) [][2]string {
	return [][2]string{
		{"Result", result},
		{"NumberReturned", strconv.Itoa(returned)},
		{"TotalMatches", strconv.Itoa(total)},
		{"UpdateID", "1"},
	}
}

func (s *apiServer) dlnaContentDirectory(w http.ResponseWriter, r *http.Request) {
	call, err := dlna.ParseAction(r.Body)
	if err != nil {
		soapReply(w, dlna.Fault(401, "invalid action"), true)
		return
	}
	switch call.Name {
	case "GetSearchCapabilities":
		soapReply(w, dlna.Response(dlna.ContentDirectory, call.Name, [][2]string{{"SearchCaps", ""}}), false)
	case "GetSortCapabilities":
		soapReply(w, dlna.Response(dlna.ContentDirectory, call.Name, [][2]string{{"SortCaps", ""}}), false)
	case "GetSystemUpdateID":
		soapReply(w, dlna.Response(dlna.ContentDirectory, call.Name, [][2]string{{"Id", "1"}}), false)
	case "Browse":
		s.dlnaBrowse(w, r, call)
	default:
		soapReply(w, dlna.Fault(401, "invalid action"), true)
	}
}

func (s *apiServer) dlnaBrowse(w http.ResponseWriter, r *http.Request, call dlna.Action) {
	ctx := r.Context()
	owner := dlnaUser(r)
	start, _ := strconv.Atoi(call.Args["StartingIndex"])
	count, _ := strconv.Atoi(call.Args["RequestedCount"])
	if count <= 0 || count > dlnaMaxPage {
		count = dlnaMaxPage
	}
	start = max(start, 0)
	children := call.Args["BrowseFlag"] == "BrowseDirectChildren"
	if call.Args["BrowseFlag"] != "BrowseMetadata" && !children {
		soapReply(w, dlna.Fault(402, "invalid BrowseFlag"), true)
		return
	}
	reply := func(containers []dlna.Container, items []dlna.Item, total int) {
		soapReply(w, dlna.Response(dlna.ContentDirectory, "Browse",
			browseValues(dlna.DIDL(containers, items), len(containers)+len(items), total)), false)
	}
	object := call.Args["ObjectID"]
	if object == dlna.Root {
		albums, err := s.queries.ListDLNAAlbums(ctx, owner.ID)
		if err != nil {
			internalError(w, r, err)
			return
		}
		if !children {
			reply([]dlna.Container{{ID: dlna.Root, ParentID: "-1", Title: "Mediarr", ChildCount: len(albums)}}, nil, 1)
			return
		}
		page := albums[min(start, len(albums)):min(start+count, len(albums))]
		containers := make([]dlna.Container, 0, len(page))
		for _, album := range page {
			total, err := s.queries.CountDLNAAlbumAssets(ctx, db.CountDLNAAlbumAssetsParams{AlbumID: album.ID, UserID: owner.ID})
			if err != nil {
				internalError(w, r, err)
				return
			}
			containers = append(containers, dlna.Container{
				ID: uuid.UUID(album.ID.Bytes).String(), ParentID: dlna.Root, Title: album.Title, ChildCount: int(total),
			})
		}
		reply(containers, nil, len(albums))
		return
	}
	albumID, assetID, kind := splitObject(object)
	if kind == 0 {
		soapReply(w, dlna.Fault(701, "no such object"), true)
		return
	}
	album, err := s.queries.GetDLNAAlbum(ctx, db.GetDLNAAlbumParams{ID: pgtype.UUID{Bytes: albumID, Valid: true}, OwnerID: owner.ID})
	if db.IsNotFound(err) {
		soapReply(w, dlna.Fault(701, "no such object"), true)
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	total, err := s.queries.CountDLNAAlbumAssets(ctx, db.CountDLNAAlbumAssetsParams{AlbumID: album.ID, UserID: owner.ID})
	if err != nil {
		internalError(w, r, err)
		return
	}
	if kind == 1 && !children {
		reply([]dlna.Container{{ID: albumID.String(), ParentID: dlna.Root, Title: album.Title, ChildCount: int(total)}}, nil, 1)
		return
	}
	if kind == 2 && children {
		reply(nil, nil, 0)
		return
	}
	if kind == 2 {
		row, err := s.queries.GetDLNAAsset(ctx, db.GetDLNAAssetParams{ID: pgtype.UUID{Bytes: assetID, Valid: true}, UserID: owner.ID})
		if db.IsNotFound(err) {
			soapReply(w, dlna.Fault(701, "no such object"), true)
			return
		}
		if err != nil {
			internalError(w, r, err)
			return
		}
		one := db.ListDLNAAlbumAssetsRow{
			ID: row.ID, Kind: row.Kind, MimeType: row.MimeType, OriginalName: row.OriginalName, LocalAt: row.LocalAt,
			DurationMs: row.DurationMs, SizeBytes: row.SizeBytes, Width: row.Width, Height: row.Height,
		}
		reply(nil, []dlna.Item{dlnaItem(r, albumID, &one)}, 1)
		return
	}
	rows, err := s.queries.ListDLNAAlbumAssets(ctx, db.ListDLNAAlbumAssetsParams{
		AlbumID: album.ID, UserID: owner.ID, Max: int32(count), Skip: int32(start), //nolint:gosec // Both are limited above.
	})
	if err != nil {
		internalError(w, r, err)
		return
	}
	items := make([]dlna.Item, 0, len(rows))
	for i := range rows {
		items = append(items, dlnaItem(r, albumID, &rows[i]))
	}
	reply(nil, items, int(total))
}

func (s *apiServer) dlnaAsset(w http.ResponseWriter, r *http.Request) (*db.Asset, bool) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		http.NotFound(w, r)
		return nil, false
	}
	row, err := s.queries.GetDLNAAsset(r.Context(), db.GetDLNAAssetParams{ID: pgtype.UUID{Bytes: id, Valid: true}, UserID: dlnaUser(r).ID})
	if db.IsNotFound(err) {
		http.NotFound(w, r)
		return nil, false
	}
	if err != nil {
		internalError(w, r, err)
		return nil, false
	}
	return &row, true
}

func (s *apiServer) dlnaImage(w http.ResponseWriter, r *http.Request) {
	if row, ok := s.dlnaAsset(w, r); ok {
		w.Header().Set("TransferMode.DLNA.ORG", "Interactive")
		s.serveTVImage(w, r, row)
	}
}

func (s *apiServer) dlnaVideo(w http.ResponseWriter, r *http.Request) {
	if row, ok := s.dlnaAsset(w, r); ok {
		w.Header().Set("TransferMode.DLNA.ORG", "Streaming")
		s.serveTVVideo(w, r, row, dlnaUser(r).ID)
	}
}
