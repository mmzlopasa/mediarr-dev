package dlna

import (
	"bufio"
	"bytes"
	"context"
	"fmt"
	"io"
	"log/slog"
	"math/rand/v2"
	"net"
	"net/http"
	"net/http/httputil"
	"net/url"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"time"
)

// SSDP is how UPnP devices find each other: a multicast group every device on the network listens to.
const (
	ssdpAddress = "239.255.255.250:1900"
	maxAge      = 1800
	// Announcements are sent again well before they expire, as UPnP asks.
	notifyEvery = 10 * time.Minute
	checkEvery  = 30 * time.Second
	// AnnouncerHeader marks the announcer's own requests, so the server can tell the administrator
	// that TVs can find it.
	AnnouncerHeader = "X-Mediarr-Dlna-Announcer"
)

// Types are the search targets this server answers to, besides its own uuid.
var Types = []string{"upnp:rootdevice", DeviceType, ContentDirectory, ConnectionManager}

// Search is an M-SEARCH a device sent.
type Search struct {
	Target string
	// MX is how many seconds the answer may wait, so that not all devices answer at once.
	MX int
}

// ParseSearch reads an M-SEARCH. Anything else is not one, and gets no answer.
func ParseSearch(packet []byte) (Search, bool) {
	request, err := http.ReadRequest(bufio.NewReader(bytes.NewReader(packet)))
	if err != nil || request.Method != "M-SEARCH" {
		return Search{}, false
	}
	if strings.Trim(request.Header.Get("Man"), `"`) != "ssdp:discover" {
		return Search{}, false
	}
	mx, _ := strconv.Atoi(request.Header.Get("Mx"))
	return Search{Target: request.Header.Get("St"), MX: mx}, true
}

// Matches says which of this server's types answer a search: all of them for ssdp:all.
func Matches(target, udn string) []string {
	all := append([]string{"uuid:" + udn}, Types...)
	if target == "ssdp:all" {
		return all
	}
	for _, kind := range all {
		if strings.EqualFold(kind, target) {
			return []string{kind}
		}
	}
	return nil
}

// usn names one announced type of this device.
func usn(udn, kind string) string {
	if kind == "uuid:"+udn {
		return kind
	}
	return "uuid:" + udn + "::" + kind
}

func serverHeader(version string) string {
	return "Linux/1 UPnP/1.0 Mediarr/" + version
}

// SearchResponse is the answer to a search, sent straight back to who asked.
func SearchResponse(kind, udn, location, version string, now time.Time) string {
	return "HTTP/1.1 200 OK\r\n" +
		fmt.Sprintf("CACHE-CONTROL: max-age=%d\r\n", maxAge) +
		"DATE: " + now.UTC().Format(http.TimeFormat) + "\r\n" +
		"EXT:\r\n" +
		"LOCATION: " + location + "\r\n" +
		"SERVER: " + serverHeader(version) + "\r\n" +
		"ST: " + kind + "\r\n" +
		"USN: " + usn(udn, kind) + "\r\n" +
		"CONTENT-LENGTH: 0\r\n\r\n"
}

// Notify is an announcement to the whole network: ssdp:alive with the address, or ssdp:byebye.
func Notify(kind, udn, location, version string, alive bool) string {
	out := "NOTIFY * HTTP/1.1\r\n" +
		"HOST: " + ssdpAddress + "\r\n" +
		"NT: " + kind + "\r\n" +
		"USN: " + usn(udn, kind) + "\r\n"
	if !alive {
		return out + "NTS: ssdp:byebye\r\n\r\n"
	}
	return out + fmt.Sprintf("CACHE-CONTROL: max-age=%d\r\n", maxAge) +
		"LOCATION: " + location + "\r\n" +
		"NTS: ssdp:alive\r\n" +
		"SERVER: " + serverHeader(version) + "\r\n\r\n"
}

// Announcer runs on the host's network: it announces the server while its administrator has the
// DLNA server on, and passes a TV's requests under /dlna/ (and nothing else) to the server.
type Announcer struct {
	// Upstream is the server, as this machine reaches it.
	Upstream *url.URL
	// Port is where TVs reach the announcer's HTTP side.
	Port    int
	Version string
	Client  *http.Client

	mu   sync.Mutex
	udn  string
	conn *net.UDPConn
}

var udnPattern = regexp.MustCompile(`<UDN>uuid:([0-9a-fA-F-]{36})</UDN>`)

// check asks the server whether TVs should see it, and with which id.
func (a *Announcer) check(ctx context.Context) string {
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, a.Upstream.JoinPath("/dlna/device.xml").String(), nil)
	if err != nil {
		return ""
	}
	request.Header.Set(AnnouncerHeader, "1")
	response, err := a.Client.Do(request)
	if err != nil {
		return ""
	}
	defer func() { _ = response.Body.Close() }()
	if response.StatusCode != http.StatusOK {
		return ""
	}
	body, _ := io.ReadAll(io.LimitReader(response.Body, 64<<10))
	match := udnPattern.FindSubmatch(body)
	if match == nil {
		return ""
	}
	return string(match[1])
}

// localAddressFor is this machine's address on the way to another, which a TV can reach.
func localAddressFor(remote *net.UDPAddr) net.IP {
	conn, err := net.DialUDP("udp4", nil, remote)
	if err != nil {
		return nil
	}
	defer func() { _ = conn.Close() }()
	return conn.LocalAddr().(*net.UDPAddr).IP
}

func (a *Announcer) location(ip net.IP) string {
	return fmt.Sprintf("http://%s/dlna/device.xml", net.JoinHostPort(ip.String(), strconv.Itoa(a.Port)))
}

// Run announces until the context ends. It needs the host's network: inside Docker's own network
// nothing it sends reaches a TV.
func (a *Announcer) Run(ctx context.Context) error {
	group, err := net.ResolveUDPAddr("udp4", ssdpAddress)
	if err != nil {
		return err
	}
	conn, err := net.ListenMulticastUDP("udp4", nil, group)
	if err != nil {
		return fmt.Errorf("listen for SSDP (this needs network_mode: host): %w", err)
	}
	a.conn = conn
	defer func() { _ = conn.Close() }()

	proxy := httputil.NewSingleHostReverseProxy(a.Upstream)
	web := &http.Server{
		Addr:              fmt.Sprintf(":%d", a.Port),
		ReadHeaderTimeout: 10 * time.Second,
		Handler: http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// Only what a TV needs: the rest of Mediarr is not reachable this way.
			if !strings.HasPrefix(r.URL.Path, "/dlna/") {
				http.NotFound(w, r)
				return
			}
			r.Header.Del(AnnouncerHeader)
			proxy.ServeHTTP(w, r)
		}),
	}
	go func() {
		if err := web.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			slog.Error("the DLNA address could not be served", "port", a.Port, "error", err)
		}
	}()
	defer func() { _ = web.Close() }()

	go a.answer(ctx, conn)

	ticker := time.NewTicker(checkEvery)
	defer ticker.Stop()
	lastNotify := time.Time{}
	for {
		udn := a.check(ctx)
		a.mu.Lock()
		previous := a.udn
		a.udn = udn
		a.mu.Unlock()
		if previous != "" && previous != udn {
			a.notifyAll(group, previous, false)
			lastNotify = time.Time{}
		}
		if udn != "" && time.Since(lastNotify) > notifyEvery {
			a.notifyAll(group, udn, true)
			lastNotify = time.Now()
		}
		select {
		case <-ctx.Done():
			if udn != "" {
				a.notifyAll(group, udn, false)
			}
			return nil
		case <-ticker.C:
		}
	}
}

func (a *Announcer) notifyAll(group *net.UDPAddr, udn string, alive bool) {
	ip := localAddressFor(group)
	if ip == nil {
		return
	}
	for _, kind := range append([]string{"uuid:" + udn}, Types...) {
		_, _ = a.conn.WriteToUDP([]byte(Notify(kind, udn, a.location(ip), a.Version, alive)), group)
	}
}

func (a *Announcer) answer(ctx context.Context, conn *net.UDPConn) {
	buffer := make([]byte, 8192)
	for ctx.Err() == nil {
		n, from, err := conn.ReadFromUDP(buffer)
		if err != nil {
			if ctx.Err() != nil {
				return
			}
			continue
		}
		search, ok := ParseSearch(buffer[:n])
		if !ok {
			continue
		}
		a.mu.Lock()
		udn := a.udn
		a.mu.Unlock()
		if udn == "" {
			continue
		}
		kinds := Matches(search.Target, udn)
		if len(kinds) == 0 {
			continue
		}
		go a.reply(from, search, kinds, udn)
	}
}

func (a *Announcer) reply(to *net.UDPAddr, search Search, kinds []string, udn string) {
	wait := min(max(search.MX, 1), 5)
	time.Sleep(time.Duration(rand.Int64N(int64(wait) * int64(time.Second)))) //nolint:gosec // Only spreads the answers over time, as UPnP asks.
	ip := localAddressFor(to)
	if ip == nil {
		return
	}
	// From a socket of its own, so the answer comes from an ordinary port as UPnP asks.
	conn, err := net.DialUDP("udp4", nil, to)
	if err != nil {
		return
	}
	defer func() { _ = conn.Close() }()
	for _, kind := range kinds {
		_, _ = conn.Write([]byte(SearchResponse(kind, udn, a.location(ip), a.Version, time.Now())))
	}
}
