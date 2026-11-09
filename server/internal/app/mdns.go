package app

import (
	"context"
	"io"
	"log"
	"log/slog"
	"net"
	"time"

	"github.com/hashicorp/mdns"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

// MDNSService is what apps on the same network look for.
const MDNSService = "_mediarr._tcp"

const mdnsCheckEvery = time.Minute

// localAddresses are this machine's own addresses on its networks, without loopback.
func localAddresses() []net.IP {
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return nil
	}
	var out []net.IP
	for _, addr := range addrs {
		if ipNet, ok := addr.(*net.IPNet); ok && !ipNet.IP.IsLoopback() && !ipNet.IP.IsLinkLocalUnicast() {
			out = append(out, ipNet.IP)
		}
	}
	return out
}

// AdvertiseOnNetwork announces the server over mDNS while the administrator lets it be found. Inside
// Docker's default bridge network the announcement does not leave the container; there the app
// finds the server by asking the addresses of its network instead.
func AdvertiseOnNetwork(ctx context.Context, queries *db.Queries, port int) {
	var server *mdns.Server
	announced := ""
	stop := func() {
		if server != nil {
			_ = server.Shutdown()
			server = nil
		}
	}
	defer stop()
	ticker := time.NewTicker(mdnsCheckEvery)
	defer ticker.Stop()
	for {
		settings, err := jobs.LoadServerSettings(ctx, queries)
		visible := err == nil && !settings.HiddenOnNetwork
		if server != nil && settings.Name() != announced {
			stop()
		}
		switch {
		case visible && server == nil:
			announced = settings.Name()
			service, err := mdns.NewMDNSService(settings.Name(), MDNSService, "", "", port, localAddresses(), []string{"version=" + Version, "name=" + settings.Name()})
			if err == nil {
				server, err = mdns.NewServer(&mdns.Config{Zone: service, Logger: log.New(io.Discard, "", 0)})
			}
			if err != nil {
				slog.Info("this server is not announced on the network", "reason", err)
				server = nil
			}
		case !visible:
			stop()
		}
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
		}
	}
}
