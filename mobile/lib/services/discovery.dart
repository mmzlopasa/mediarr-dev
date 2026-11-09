import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';

/// A Mediarr server that answered on this network.
class FoundServer {
  const FoundServer(this.url, this.version);

  final String url;
  final String version;

  @override
  bool operator ==(Object other) => other is FoundServer && other.url == url;

  @override
  int get hashCode => url.hashCode;
}

const mdnsService = '_mediarr._tcp';
const defaultPort = 9851;
const _probeWait = Duration(milliseconds: 700);
const _probesAtOnce = 48;

/// Whether an address belongs to a home or office network, where a server can be looked for.
bool isPrivateIPv4(InternetAddress address) {
  if (address.type != InternetAddressType.IPv4) return false;
  final b = address.rawAddress;
  return b[0] == 10 ||
      (b[0] == 172 && b[1] >= 16 && b[1] <= 31) ||
      (b[0] == 192 && b[1] == 168);
}

/// Every other address of the /24 network this address is on.
List<String> neighboursOf(InternetAddress address) {
  final b = address.rawAddress;
  return [
    for (var last = 1; last < 255; last++)
      if (last != b[3]) '${b[0]}.${b[1]}.${b[2]}.$last',
  ];
}

/// The version, if a Mediarr server answers at this address.
Future<String?> helloFrom(String url, {Duration wait = _probeWait}) async {
  final client = HttpClient()..connectionTimeout = wait;
  try {
    final request = await client
        .getUrl(Uri.parse('$url/api/server/hello'))
        .timeout(wait);
    final response = await request.close().timeout(wait * 2);
    if (response.statusCode != 200) return null;
    final body = await response.transform(utf8.decoder).join().timeout(wait);
    final data = jsonDecode(body);
    if (data is Map && data['app'] == 'mediarr') {
      return data['version']?.toString() ?? '';
    }
    return null;
  } on Object {
    return null;
  } finally {
    client.close(force: true);
  }
}

/// Looks for Mediarr servers on the Wi-Fi this phone is on: by mDNS where the server announces
/// itself, and by asking the addresses of the network, which also finds a server inside Docker.
Stream<FoundServer> discoverServers({
  List<int> ports = const [defaultPort],
  Duration mdnsFor = const Duration(seconds: 4),
}) {
  final out = StreamController<FoundServer>();
  final seen = <String>{};
  void found(String url, String? version) {
    if (version != null && seen.add(url) && !out.isClosed) {
      out.add(FoundServer(url, version));
    }
  }

  Future<void> byMdns() async {
    final discovery = BonsoirDiscovery(type: mdnsService);
    try {
      await discovery.initialize();
      final checks = <Future<void>>[];
      final events = discovery.eventStream?.listen((event) {
        final service = event.service;
        if (service == null) return;
        if (event is BonsoirDiscoveryServiceFoundEvent) {
          discovery.serviceResolver.resolveService(service);
        } else if (event is BonsoirDiscoveryServiceResolvedEvent) {
          for (final host in service.hostAddresses) {
            final address = InternetAddress.tryParse(host);
            if (address == null || address.type != InternetAddressType.IPv4) {
              continue;
            }
            final url = 'http://$host:${service.port}';
            checks.add(helloFrom(url).then((version) => found(url, version)));
          }
        }
      });
      await discovery.start();
      await Future<void>.delayed(mdnsFor);
      await events?.cancel();
      await Future.wait(checks);
    } on Object {
      // Without multicast on this network, the addresses are still asked.
    } finally {
      try {
        await discovery.stop();
      } on Object {
        // Already stopped.
      }
    }
  }

  Future<void> byAddresses() async {
    final List<NetworkInterface> interfaces;
    try {
      interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
    } on Object {
      return;
    }
    final targets = <String>[
      for (final interface in interfaces)
        for (final address in interface.addresses)
          if (isPrivateIPv4(address))
            for (final host in neighboursOf(address))
              for (final port in ports) 'http://$host:$port',
    ];
    var next = 0;
    Future<void> worker() async {
      while (next < targets.length && !out.isClosed) {
        final url = targets[next++];
        found(url, await helloFrom(url));
      }
    }

    await Future.wait([for (var i = 0; i < _probesAtOnce; i++) worker()]);
  }

  Future.wait([byMdns(), byAddresses()]).whenComplete(out.close);
  return out.stream;
}
