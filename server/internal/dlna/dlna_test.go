package dlna

import (
	"strings"
	"testing"
	"time"
)

const udn = "2f6b1f7e-6a43-5a8e-9b8d-1c2d3e4f5a6b"

func TestASearchIsRead(t *testing.T) {
	packet := "M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: \"ssdp:discover\"\r\nMX: 2\r\nST: urn:schemas-upnp-org:device:MediaServer:1\r\n\r\n"
	search, ok := ParseSearch([]byte(packet))
	if !ok || search.Target != DeviceType || search.MX != 2 {
		t.Fatalf("%+v %v", search, ok)
	}
	for _, other := range []string{
		"NOTIFY * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nNT: upnp:rootdevice\r\n\r\n",
		"M-SEARCH * HTTP/1.1\r\nST: ssdp:all\r\n\r\n",
		"not http at all",
	} {
		if _, ok := ParseSearch([]byte(other)); ok {
			t.Errorf("answered %q", other)
		}
	}
}

func TestOnlyWhatTheServerIsAnswers(t *testing.T) {
	if got := Matches("ssdp:all", udn); len(got) != 5 || got[0] != "uuid:"+udn {
		t.Fatalf("ssdp:all: %v", got)
	}
	if got := Matches("urn:schemas-upnp-org:service:ContentDirectory:1", udn); len(got) != 1 {
		t.Fatalf("ContentDirectory: %v", got)
	}
	if got := Matches("uuid:"+udn, udn); len(got) != 1 {
		t.Fatalf("own uuid: %v", got)
	}
	for _, target := range []string{"urn:schemas-upnp-org:device:MediaRenderer:1", "urn:dial-multiscreen-org:service:dial:1", ""} {
		if got := Matches(target, udn); got != nil {
			t.Errorf("%s answered: %v", target, got)
		}
	}
}

func TestAnnouncementsAreWrittenAsUPnPAsks(t *testing.T) {
	location := "http://192.168.1.10:8200/dlna/device.xml"
	at := time.Date(2026, 11, 10, 9, 0, 0, 0, time.UTC)
	got := SearchResponse(DeviceType, udn, location, "1.2.3", at)
	want := "HTTP/1.1 200 OK\r\nCACHE-CONTROL: max-age=1800\r\nDATE: Tue, 10 Nov 2026 09:00:00 GMT\r\nEXT:\r\n" +
		"LOCATION: " + location + "\r\nSERVER: Linux/1 UPnP/1.0 Mediarr/1.2.3\r\nST: " + DeviceType + "\r\n" +
		"USN: uuid:" + udn + "::" + DeviceType + "\r\nCONTENT-LENGTH: 0\r\n\r\n"
	if got != want {
		t.Fatalf("search response:\n%q\nwant\n%q", got, want)
	}
	alive := Notify("upnp:rootdevice", udn, location, "1.2.3", true)
	for _, line := range []string{
		"NOTIFY * HTTP/1.1\r\n", "HOST: 239.255.255.250:1900\r\n", "NT: upnp:rootdevice\r\n",
		"NTS: ssdp:alive\r\n", "USN: uuid:" + udn + "::upnp:rootdevice\r\n", "LOCATION: " + location + "\r\n", "CACHE-CONTROL: max-age=1800\r\n",
	} {
		if !strings.Contains(alive, line) {
			t.Errorf("alive lacks %q", line)
		}
	}
	if !strings.HasSuffix(alive, "\r\n\r\n") {
		t.Error("alive does not end with an empty line")
	}
	bye := Notify("uuid:"+udn, udn, location, "1.2.3", false)
	if !strings.Contains(bye, "NTS: ssdp:byebye\r\n") || !strings.Contains(bye, "USN: uuid:"+udn+"\r\n") || strings.Contains(bye, "LOCATION") {
		t.Errorf("byebye: %q", bye)
	}
}

func TestDIDLEscapesWhatPeopleWrite(t *testing.T) {
	out := DIDL([]Container{{ID: "a", ParentID: Root, Title: `Ana & "Marko" <3`, ChildCount: 2}}, []Item{{
		ID: "a/b", ParentID: "a", Title: "2024-07-01 10:00", Class: "object.item.videoItem", Date: time.Date(2024, 7, 1, 10, 0, 0, 0, time.UTC),
		URL: "http://192.168.1.10:8200/dlna/media/b/video?x=1&y=2", MimeType: "video/mp4", Size: 1234, Duration: 83*time.Second + 250*time.Millisecond,
		Thumbnail: "http://192.168.1.10:8200/dlna/media/b/image.jpg",
	}})
	for _, part := range []string{
		`<dc:title>Ana &amp; &#34;Marko&#34; &lt;3</dc:title>`, `childCount="2"`, `<upnp:class>object.container.album.photoAlbum</upnp:class>`,
		`<dc:date>2024-07-01T10:00:00</dc:date>`, `duration="0:01:23.250"`, `size="1234"`,
		`protocolInfo="http-get:*:video/mp4:DLNA.ORG_OP=01;`, `>http://192.168.1.10:8200/dlna/media/b/video?x=1&amp;y=2</res>`,
	} {
		if !strings.Contains(out, part) {
			t.Errorf("DIDL lacks %s:\n%s", part, out)
		}
	}
}

func TestASOAPActionIsRead(t *testing.T) {
	body := `<?xml version="1.0"?><s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Body>` +
		`<u:Browse xmlns:u="urn:schemas-upnp-org:service:ContentDirectory:1"><ObjectID>0</ObjectID><BrowseFlag>BrowseDirectChildren</BrowseFlag>` +
		`<Filter>*</Filter><StartingIndex>5</StartingIndex><RequestedCount>10</RequestedCount><SortCriteria></SortCriteria></u:Browse></s:Body></s:Envelope>`
	call, err := ParseAction(strings.NewReader(body))
	if err != nil {
		t.Fatal(err)
	}
	if call.Name != "Browse" || call.Service != ContentDirectory || call.Args["ObjectID"] != "0" || call.Args["StartingIndex"] != "5" || call.Args["BrowseFlag"] != "BrowseDirectChildren" {
		t.Fatalf("%+v", call)
	}
	if _, err := ParseAction(strings.NewReader("<nothing/>")); err == nil {
		t.Fatal("no action was found in nothing")
	}
	reply := Response(ContentDirectory, "Browse", [][2]string{{"Result", "<DIDL-Lite/>"}, {"NumberReturned", "0"}})
	if !strings.Contains(reply, `<u:BrowseResponse xmlns:u="`+ContentDirectory+`"><Result>&lt;DIDL-Lite/&gt;</Result><NumberReturned>0</NumberReturned></u:BrowseResponse>`) {
		t.Fatalf("response: %s", reply)
	}
	if fault := Fault(701, "no such object"); !strings.Contains(fault, "<errorCode>701</errorCode>") {
		t.Fatalf("fault: %s", fault)
	}
}
