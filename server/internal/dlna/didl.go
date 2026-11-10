// Package dlna lets TVs on the home network find this server and browse its albums (UPnP
// MediaServer with a ContentDirectory), and announces it over SSDP from a container on the host's
// network.
package dlna

import (
	"bytes"
	"encoding/xml"
	"errors"
	"fmt"
	"io"
	"strings"
	"time"
)

// Root is the object id of the list of albums.
const Root = "0"

// Container is an album, as a TV lists it.
type Container struct {
	ID, ParentID, Title string
	ChildCount          int
}

// Item is a photo or a video in an album.
type Item struct {
	ID, ParentID, Title string
	// Class is object.item.imageItem.photo or object.item.videoItem.
	Class string
	Date  time.Time
	// URL of the file, MimeType its type, and Thumbnail a JPEG for the list.
	URL, MimeType, Thumbnail string
	Size                     int64
	Duration                 time.Duration
	Width, Height            int
}

// The DLNA profile of a JPEG says what TVs may expect; a large one is the safe choice for photos
// up to 4K. OP=01 says the file can be read from any byte, and the flags say it is streamed.
const dlnaFlags = "DLNA.ORG_OP=01;DLNA.ORG_CI=0;DLNA.ORG_FLAGS=01700000000000000000000000000000"

// ProtocolInfo is the res protocolInfo of a file of this type.
func ProtocolInfo(mimeType string) string {
	extra := dlnaFlags
	if mimeType == "image/jpeg" {
		extra = "DLNA.ORG_PN=JPEG_LRG;" + dlnaFlags
	}
	return "http-get:*:" + mimeType + ":" + extra
}

func esc(value string) string {
	var out bytes.Buffer
	_ = xml.EscapeText(&out, []byte(value))
	return out.String()
}

// DIDL writes a DIDL-Lite document with these containers and items.
func DIDL(containers []Container, items []Item) string {
	var b strings.Builder
	b.WriteString(`<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/" xmlns:dlna="urn:schemas-dlna-org:metadata-1-0/">`)
	for _, c := range containers {
		fmt.Fprintf(&b, `<container id="%s" parentID="%s" restricted="1" searchable="0" childCount="%d"><dc:title>%s</dc:title><upnp:class>object.container.album.photoAlbum</upnp:class></container>`,
			esc(c.ID), esc(c.ParentID), c.ChildCount, esc(c.Title))
	}
	for _, it := range items {
		fmt.Fprintf(&b, `<item id="%s" parentID="%s" restricted="1"><dc:title>%s</dc:title><upnp:class>%s</upnp:class>`,
			esc(it.ID), esc(it.ParentID), esc(it.Title), esc(it.Class))
		if !it.Date.IsZero() {
			fmt.Fprintf(&b, `<dc:date>%s</dc:date>`, it.Date.Format("2006-01-02T15:04:05"))
		}
		if it.Thumbnail != "" {
			fmt.Fprintf(&b, `<upnp:albumArtURI dlna:profileID="JPEG_TN">%s</upnp:albumArtURI>`, esc(it.Thumbnail))
		}
		b.WriteString(`<res protocolInfo="` + esc(ProtocolInfo(it.MimeType)) + `"`)
		if it.Size > 0 {
			fmt.Fprintf(&b, ` size="%d"`, it.Size)
		}
		if it.Duration > 0 {
			fmt.Fprintf(&b, ` duration="%s"`, Duration(it.Duration))
		}
		if it.Width > 0 && it.Height > 0 {
			fmt.Fprintf(&b, ` resolution="%dx%d"`, it.Width, it.Height)
		}
		b.WriteString(`>` + esc(it.URL) + `</res></item>`)
	}
	b.WriteString(`</DIDL-Lite>`)
	return b.String()
}

// Duration is how UPnP writes a length of time: H:MM:SS.mmm.
func Duration(d time.Duration) string {
	ms := d.Milliseconds()
	return fmt.Sprintf("%d:%02d:%02d.%03d", ms/3600000, ms/60000%60, ms/1000%60, ms%1000)
}

// Action is a SOAP call a TV made.
type Action struct {
	Service, Name string
	Args          map[string]string
}

// ParseAction reads a SOAP request. The action's name comes from the body, not from the header,
// which some TVs write differently.
func ParseAction(body io.Reader) (Action, error) {
	decoder := xml.NewDecoder(io.LimitReader(body, 64<<10))
	out := Action{Args: map[string]string{}}
	inBody := false
	var current string
	for {
		token, err := decoder.Token()
		if errors.Is(err, io.EOF) {
			break
		}
		if err != nil {
			return out, err
		}
		switch t := token.(type) {
		case xml.StartElement:
			switch {
			case t.Name.Local == "Body":
				inBody = true
			case inBody && out.Name == "":
				out.Name, out.Service = t.Name.Local, t.Name.Space
			case inBody:
				current = t.Name.Local
			}
		case xml.CharData:
			if current != "" {
				out.Args[current] += string(t)
			}
		case xml.EndElement:
			current = ""
		}
	}
	if out.Name == "" {
		return out, fmt.Errorf("no action in the request")
	}
	return out, nil
}

// Response is the SOAP answer to an action, with its values in this order.
func Response(service, action string, values [][2]string) string {
	var b strings.Builder
	b.WriteString(`<?xml version="1.0" encoding="utf-8"?>` + "\n")
	b.WriteString(`<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body>`)
	fmt.Fprintf(&b, `<u:%sResponse xmlns:u="%s">`, action, esc(service))
	for _, value := range values {
		fmt.Fprintf(&b, `<%s>%s</%s>`, value[0], esc(value[1]), value[0])
	}
	fmt.Fprintf(&b, `</u:%sResponse></s:Body></s:Envelope>`, action)
	return b.String()
}

// Fault is the SOAP answer to an action that cannot be done. 701 is "no such object", 401 "invalid
// action" and 402 "invalid arguments".
func Fault(code int, description string) string {
	return fmt.Sprintf(`<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><s:Fault><faultcode>s:Client</faultcode><faultstring>UPnPError</faultstring><detail><UPnPError xmlns="urn:schemas-upnp-org:control-1-0"><errorCode>%d</errorCode><errorDescription>%s</errorDescription></UPnPError></detail></s:Fault></s:Body></s:Envelope>`,
		code, esc(description))
}

// Service types of what the server offers.
const (
	DeviceType        = "urn:schemas-upnp-org:device:MediaServer:1"
	ContentDirectory  = "urn:schemas-upnp-org:service:ContentDirectory:1"
	ConnectionManager = "urn:schemas-upnp-org:service:ConnectionManager:1"
)

// DeviceDescription is the description a TV reads first, from the address in an announcement.
// Every address in it is relative to that one.
func DeviceDescription(udn, name, version string) string {
	return fmt.Sprintf(`<?xml version="1.0" encoding="utf-8"?>
<root xmlns="urn:schemas-upnp-org:device-1-0" xmlns:dlna="urn:schemas-dlna-org:device-1-0">
<specVersion><major>1</major><minor>0</minor></specVersion>
<device>
<deviceType>%s</deviceType>
<friendlyName>%s</friendlyName>
<manufacturer>Mediarr</manufacturer>
<manufacturerURL>https://mediarr.app</manufacturerURL>
<modelName>Mediarr</modelName>
<modelNumber>%s</modelNumber>
<UDN>uuid:%s</UDN>
<dlna:X_DLNADOC>DMS-1.50</dlna:X_DLNADOC>
<serviceList>
<service><serviceType>%s</serviceType><serviceId>urn:upnp-org:serviceId:ContentDirectory</serviceId><SCPDURL>/dlna/ContentDirectory.xml</SCPDURL><controlURL>/dlna/control/ContentDirectory</controlURL><eventSubURL>/dlna/event/ContentDirectory</eventSubURL></service>
<service><serviceType>%s</serviceType><serviceId>urn:upnp-org:serviceId:ConnectionManager</serviceId><SCPDURL>/dlna/ConnectionManager.xml</SCPDURL><controlURL>/dlna/control/ConnectionManager</controlURL><eventSubURL>/dlna/event/ConnectionManager</eventSubURL></service>
</serviceList>
</device>
</root>`, DeviceType, esc(name), esc(version), esc(udn), ContentDirectory, ConnectionManager)
}

func argument(name, direction, variable string) string {
	return fmt.Sprintf(`<argument><name>%s</name><direction>%s</direction><relatedStateVariable>%s</relatedStateVariable></argument>`, name, direction, variable)
}

func variable(name, dataType string, values ...string) string {
	allowed := ""
	if len(values) > 0 {
		allowed = "<allowedValueList>"
		for _, value := range values {
			allowed += "<allowedValue>" + value + "</allowedValue>"
		}
		allowed += "</allowedValueList>"
	}
	return fmt.Sprintf(`<stateVariable sendEvents="no"><name>%s</name><dataType>%s</dataType>%s</stateVariable>`, name, dataType, allowed)
}

func scpd(actions, variables string) string {
	return `<?xml version="1.0" encoding="utf-8"?>
<scpd xmlns="urn:schemas-upnp-org:service-1-0"><specVersion><major>1</major><minor>0</minor></specVersion><actionList>` +
		actions + `</actionList><serviceStateTable>` + variables + `</serviceStateTable></scpd>`
}

func action(name string, arguments ...string) string {
	return "<action><name>" + name + "</name><argumentList>" + strings.Join(arguments, "") + "</argumentList></action>"
}

// ContentDirectorySCPD describes the actions of the ContentDirectory.
func ContentDirectorySCPD() string {
	return scpd(
		action("Browse",
			argument("ObjectID", "in", "A_ARG_TYPE_ObjectID"),
			argument("BrowseFlag", "in", "A_ARG_TYPE_BrowseFlag"),
			argument("Filter", "in", "A_ARG_TYPE_Filter"),
			argument("StartingIndex", "in", "A_ARG_TYPE_Index"),
			argument("RequestedCount", "in", "A_ARG_TYPE_Count"),
			argument("SortCriteria", "in", "A_ARG_TYPE_SortCriteria"),
			argument("Result", "out", "A_ARG_TYPE_Result"),
			argument("NumberReturned", "out", "A_ARG_TYPE_Count"),
			argument("TotalMatches", "out", "A_ARG_TYPE_Count"),
			argument("UpdateID", "out", "A_ARG_TYPE_UpdateID"))+
			action("GetSearchCapabilities", argument("SearchCaps", "out", "SearchCapabilities"))+
			action("GetSortCapabilities", argument("SortCaps", "out", "SortCapabilities"))+
			action("GetSystemUpdateID", argument("Id", "out", "SystemUpdateID")),
		variable("A_ARG_TYPE_ObjectID", "string")+
			variable("A_ARG_TYPE_BrowseFlag", "string", "BrowseMetadata", "BrowseDirectChildren")+
			variable("A_ARG_TYPE_Filter", "string")+
			variable("A_ARG_TYPE_Index", "ui4")+
			variable("A_ARG_TYPE_Count", "ui4")+
			variable("A_ARG_TYPE_SortCriteria", "string")+
			variable("A_ARG_TYPE_Result", "string")+
			variable("A_ARG_TYPE_UpdateID", "ui4")+
			variable("SearchCapabilities", "string")+
			variable("SortCapabilities", "string")+
			`<stateVariable sendEvents="yes"><name>SystemUpdateID</name><dataType>ui4</dataType></stateVariable>`)
}

// ConnectionManagerSCPD describes the actions of the ConnectionManager.
func ConnectionManagerSCPD() string {
	return scpd(
		action("GetProtocolInfo", argument("Source", "out", "SourceProtocolInfo"), argument("Sink", "out", "SinkProtocolInfo"))+
			action("GetCurrentConnectionIDs", argument("ConnectionIDs", "out", "CurrentConnectionIDs"))+
			action("GetCurrentConnectionInfo",
				argument("ConnectionID", "in", "A_ARG_TYPE_ConnectionID"),
				argument("RcsID", "out", "A_ARG_TYPE_RcsID"),
				argument("AVTransportID", "out", "A_ARG_TYPE_AVTransportID"),
				argument("ProtocolInfo", "out", "A_ARG_TYPE_ProtocolInfo"),
				argument("PeerConnectionManager", "out", "A_ARG_TYPE_ConnectionManager"),
				argument("PeerConnectionID", "out", "A_ARG_TYPE_ConnectionID"),
				argument("Direction", "out", "A_ARG_TYPE_Direction"),
				argument("Status", "out", "A_ARG_TYPE_ConnectionStatus")),
		`<stateVariable sendEvents="yes"><name>SourceProtocolInfo</name><dataType>string</dataType></stateVariable>`+
			`<stateVariable sendEvents="yes"><name>SinkProtocolInfo</name><dataType>string</dataType></stateVariable>`+
			`<stateVariable sendEvents="yes"><name>CurrentConnectionIDs</name><dataType>string</dataType></stateVariable>`+
			variable("A_ARG_TYPE_ConnectionStatus", "string", "OK", "ContentFormatMismatch", "InsufficientBandwidth", "UnreliableChannel", "Unknown")+
			variable("A_ARG_TYPE_ConnectionManager", "string")+
			variable("A_ARG_TYPE_Direction", "string", "Input", "Output")+
			variable("A_ARG_TYPE_ProtocolInfo", "string")+
			variable("A_ARG_TYPE_ConnectionID", "i4")+
			variable("A_ARG_TYPE_AVTransportID", "i4")+
			variable("A_ARG_TYPE_RcsID", "i4"))
}

// SourceProtocols are the kinds of file this server gives.
var SourceProtocols = strings.Join([]string{
	ProtocolInfo("image/jpeg"), "http-get:*:video/mp4:*", "http-get:*:video/quicktime:*",
	"http-get:*:video/x-matroska:*", "http-get:*:video/webm:*", "http-get:*:video/x-msvideo:*", "http-get:*:video/mpeg:*",
}, ",")
