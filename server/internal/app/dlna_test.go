package app

import (
	"bytes"
	"html"
	"net/http"
	"regexp"
	"strings"
	"testing"

	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/dlna"
)

func (c *client) soap(service, action, args string) (*http.Response, string) {
	c.s.t.Helper()
	body := `<?xml version="1.0"?><s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Body><u:` + action +
		` xmlns:u="urn:schemas-upnp-org:service:` + service + `:1">` + args + `</u:` + action + `></s:Body></s:Envelope>`
	resp, data := c.do(http.MethodPost, "/dlna/control/"+service, map[string]string{
		"Content-Type": `text/xml; charset="utf-8"`, "SOAPACTION": `"urn:schemas-upnp-org:service:` + service + `:1#` + action + `"`,
	}, strings.NewReader(body))
	return resp, string(data)
}

func browse(object, flag string) string {
	return "<ObjectID>" + object + "</ObjectID><BrowseFlag>" + flag + "</BrowseFlag><Filter>*</Filter>" +
		"<StartingIndex>0</StartingIndex><RequestedCount>0</RequestedCount><SortCriteria></SortCriteria>"
}

func (c *client) dlnaSetting(t *testing.T, on bool) api.ServerSettings {
	t.Helper()
	resp, body := c.get("/api/admin/server-settings")
	expect(t, resp, body, http.StatusOK)
	settings := decode[api.ServerSettings](t, body)
	settings.DlnaServer = &on
	settings.DlnaOwner, settings.DlnaAnnounced = nil, nil
	resp, body = c.send(http.MethodPut, "/api/admin/server-settings", settings)
	expect(t, resp, body, http.StatusOK)
	return decode[api.ServerSettings](t, body)
}

func TestTheDLNAServerIsOffUntilAnAdministratorTurnsItOn(t *testing.T) {
	s := newStack(t)
	admin := s.admin()
	user := s.user(admin, "user@example.com")
	tv := s.client()
	resp, body := tv.get("/dlna/device.xml")
	expect(t, resp, body, http.StatusNotFound)

	settings := admin.dlnaSetting(t, true)
	if settings.DlnaServer == nil || !*settings.DlnaServer || settings.DlnaOwner == nil || *settings.DlnaOwner != "Admin" {
		t.Fatalf("settings: %+v", settings)
	}
	if settings.DlnaAnnounced == nil || *settings.DlnaAnnounced {
		t.Fatal("nothing has announced the server yet")
	}
	resp, body = user.send(http.MethodPut, "/api/admin/server-settings", settings)
	expect(t, resp, body, http.StatusForbidden)

	resp, body = tv.get("/dlna/device.xml")
	expect(t, resp, body, http.StatusOK)
	if !strings.Contains(string(body), "<deviceType>"+dlna.DeviceType+"</deviceType>") || !regexp.MustCompile(`<UDN>uuid:[0-9a-f-]{36}</UDN>`).Match(body) {
		t.Fatalf("description: %s", body)
	}
	// The announcer on the host's network asks with its own header; the administrator then sees it.
	resp, body = tv.do(http.MethodGet, "/dlna/device.xml", map[string]string{dlna.AnnouncerHeader: "1"}, nil)
	expect(t, resp, body, http.StatusOK)
	resp, body = admin.get("/api/admin/server-settings")
	expect(t, resp, body, http.StatusOK)
	if got := decode[api.ServerSettings](t, body); got.DlnaAnnounced == nil || !*got.DlnaAnnounced {
		t.Fatalf("not seen as announced: %s", body)
	}

	// Never to the internet, even through a proxy that is not counted.
	for _, header := range []map[string]string{
		{"X-Forwarded-For": "203.0.113.9"}, {"X-Real-IP": "8.8.8.8"}, {"X-Forwarded-For": "192.168.1.20, 198.51.100.4"},
	} {
		resp, body = tv.do(http.MethodGet, "/dlna/device.xml", header, nil)
		expect(t, resp, body, http.StatusNotFound)
	}
	resp, body = tv.do(http.MethodGet, "/dlna/device.xml", map[string]string{"X-Forwarded-For": "192.168.1.20"}, nil)
	expect(t, resp, body, http.StatusOK)

	settings = admin.dlnaSetting(t, false)
	if *settings.DlnaServer || settings.DlnaOwner != nil {
		t.Fatalf("settings: %+v", settings)
	}
	resp, body = tv.get("/dlna/device.xml")
	expect(t, resp, body, http.StatusNotFound)
}

func TestATVBrowsesTheAlbumsOfTheAdministrator(t *testing.T) {
	needMediaTools(t)
	s := newStack(t)
	s.startWorker(t)
	admin := s.admin()
	user := s.user(admin, "user@example.com")
	tv := s.client()
	photo := uploadedID(t, admin.upload("beach.jpg", pictureOf(t, 30), nil))
	loose := uploadedID(t, admin.upload("loose.jpg", pictureOf(t, 31), nil))
	theirs := uploadedID(t, user.upload("theirs.jpg", pictureOf(t, 32), nil))
	s.settle(t)
	album := admin.newAlbum(map[string]any{"title": "Summer & sea"})
	resp, body := admin.post("/api/albums/"+album+"/assets", map[string]any{"ids": []string{photo}})
	expect(t, resp, body, http.StatusOK)
	userAlbum := user.newAlbum(map[string]any{"title": "Not shown"})
	resp, body = user.post("/api/albums/"+userAlbum+"/assets", map[string]any{"ids": []string{theirs}})
	expect(t, resp, body, http.StatusOK)
	admin.dlnaSetting(t, true)

	for _, path := range []string{"/dlna/ContentDirectory.xml", "/dlna/ConnectionManager.xml"} {
		resp, body := tv.get(path)
		expect(t, resp, body, http.StatusOK)
		if !strings.Contains(string(body), "<scpd") {
			t.Errorf("%s: %s", path, body)
		}
	}

	resp, reply := tv.soap("ContentDirectory", "Browse", browse("0", "BrowseDirectChildren"))
	expect(t, resp, []byte(reply), http.StatusOK)
	result := html.UnescapeString(reply)
	if !strings.Contains(reply, "<u:BrowseResponse") || !strings.Contains(result, `<container id="`+album+`" parentID="0" restricted="1" searchable="0" childCount="1">`) ||
		!strings.Contains(result, "<dc:title>Summer &amp; sea</dc:title>") || strings.Contains(result, "Not shown") ||
		!strings.Contains(reply, "<NumberReturned>1</NumberReturned><TotalMatches>1</TotalMatches>") {
		t.Fatalf("albums: %s", reply)
	}

	resp, reply = tv.soap("ContentDirectory", "Browse", browse(album, "BrowseDirectChildren"))
	expect(t, resp, []byte(reply), http.StatusOK)
	result = html.UnescapeString(reply)
	item := `<item id="` + album + "/" + photo + `" parentID="` + album + `" restricted="1">`
	url := "http://" + strings.TrimPrefix(s.url, "http://") + "/dlna/media/" + photo + "/image.jpg"
	if !strings.Contains(result, item) || !strings.Contains(result, "<upnp:class>object.item.imageItem.photo</upnp:class>") ||
		!strings.Contains(result, `protocolInfo="http-get:*:image/jpeg:DLNA.ORG_PN=JPEG_LRG;`) || !strings.Contains(result, ">"+url+"</res>") ||
		strings.Contains(result, loose) {
		t.Fatalf("photos: %s", result)
	}
	resp, reply = tv.soap("ContentDirectory", "Browse", browse(album+"/"+photo, "BrowseMetadata"))
	expect(t, resp, []byte(reply), http.StatusOK)
	if !strings.Contains(html.UnescapeString(reply), item) {
		t.Fatalf("one photo: %s", reply)
	}

	resp, data := tv.get("/dlna/media/" + photo + "/image.jpg")
	expect(t, resp, data, http.StatusOK)
	if !bytes.HasPrefix(data, []byte{0xFF, 0xD8}) || bytes.Contains(data, []byte("Exif")) {
		t.Fatal("not a clean JPEG")
	}
	// Only what is in the administrator's albums.
	for _, id := range []string{loose, theirs} {
		resp, data = tv.get("/dlna/media/" + id + "/image.jpg")
		expect(t, resp, data, http.StatusNotFound)
	}
	for _, object := range []string{userAlbum, "nonsense", album + "/" + loose + "x"} {
		resp, reply = tv.soap("ContentDirectory", "Browse", browse(object, "BrowseDirectChildren"))
		if resp.StatusCode != http.StatusInternalServerError || !strings.Contains(reply, "<errorCode>701</errorCode>") {
			t.Errorf("%s: %d %s", object, resp.StatusCode, reply)
		}
	}

	resp, reply = tv.soap("ConnectionManager", "GetProtocolInfo", "")
	expect(t, resp, []byte(reply), http.StatusOK)
	if !strings.Contains(reply, "<Source>http-get:*:image/jpeg:") {
		t.Fatalf("protocols: %s", reply)
	}
	resp, reply = tv.soap("ContentDirectory", "GetSystemUpdateID", "")
	expect(t, resp, []byte(reply), http.StatusOK)
	resp, reply = tv.soap("ContentDirectory", "DestroyObject", "<ObjectID>"+album+"</ObjectID>")
	if resp.StatusCode != http.StatusInternalServerError || !strings.Contains(reply, "<errorCode>401</errorCode>") {
		t.Fatalf("a TV changed something: %s", reply)
	}
}
