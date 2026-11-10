import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'tv.dart';

/// UPnP's way of finding devices: a question to everyone on the network.
const ssdpGroup = '239.255.255.250';
const ssdpPort = 1900;
const mediaRenderer = 'urn:schemas-upnp-org:device:MediaRenderer:1';
const avTransport = 'urn:schemas-upnp-org:service:AVTransport:1';

String searchMessage({String target = mediaRenderer, int wait = 2}) =>
    'M-SEARCH * HTTP/1.1\r\n'
    'HOST: $ssdpGroup:$ssdpPort\r\n'
    'MAN: "ssdp:discover"\r\n'
    'MX: $wait\r\n'
    'ST: $target\r\n'
    'USER-AGENT: Mediarr UPnP/1.0\r\n\r\n';

/// The LOCATION of an answer to a search, if it is one.
String? locationOf(String answer) {
  final lines = answer.split(RegExp(r'\r?\n'));
  if (lines.isEmpty || !lines.first.startsWith('HTTP/1.1 200')) return null;
  for (final line in lines.skip(1)) {
    final at = line.indexOf(':');
    if (at > 0 && line.substring(0, at).trim().toUpperCase() == 'LOCATION') {
      return line.substring(at + 1).trim();
    }
  }
  return null;
}

String _tag(String xml, String name) {
  final match = RegExp(
    '<(?:[A-Za-z0-9_]+:)?$name(?:\\s[^>]*)?>([\\s\\S]*?)</(?:[A-Za-z0-9_]+:)?$name>',
  ).firstMatch(xml);
  return match == null ? '' : _unescape(match.group(1)!.trim());
}

String _unescape(String text) => text
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&amp;', '&');

String escapeXml(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

/// A renderer as its description tells it: its name and where its AVTransport takes orders.
/// Null when it is not a TV that can be told to play something.
TvDevice? rendererFromDescription(String location, String xml) {
  final services = RegExp(r'<(?:\w+:)?service>([\s\S]*?)</(?:\w+:)?service>')
      .allMatches(xml);
  String? control;
  for (final service in services) {
    final body = service.group(1)!;
    if (_tag(
      body,
      'serviceType',
    ).startsWith('urn:schemas-upnp-org:service:AVTransport:')) {
      control = _tag(body, 'controlURL');
      break;
    }
  }
  if (control == null || control.isEmpty) return null;
  final base = _tag(xml, 'URLBase');
  final resolved = Uri.parse(base.isEmpty ? location : base).resolve(control);
  final name = _tag(xml, 'friendlyName');
  final udn = _tag(xml, 'UDN');
  return TvDevice(
    id: udn.isEmpty ? location : udn,
    name: name.isEmpty ? resolved.host : name,
    kind: TvKind.dlna,
    host: resolved.host,
    port: resolved.port,
    controlUrl: resolved.toString(),
  );
}

/// The metadata a TV wants with an address: many will not play without it.
String didlFor(TvMedia media) {
  final kind = media.video
      ? 'object.item.videoItem'
      : 'object.item.imageItem.photo';
  final profile = media.contentType == 'image/jpeg'
      ? 'DLNA.ORG_PN=JPEG_LRG;'
      : '';
  final info =
      'http-get:*:${media.contentType}:${profile}DLNA.ORG_OP=01;DLNA.ORG_FLAGS=01700000000000000000000000000000';
  return '<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" '
      'xmlns:dc="http://purl.org/dc/elements/1.1/" '
      'xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">'
      '<item id="${escapeXml(media.id)}" parentID="0" restricted="1">'
      '<dc:title>${escapeXml(media.title)}</dc:title>'
      '<upnp:class>$kind</upnp:class>'
      '<res protocolInfo="${escapeXml(info)}">${escapeXml(media.url)}</res>'
      '</item></DIDL-Lite>';
}

/// A SOAP call to a renderer's AVTransport.
String soapBody(String action, Map<String, String> args) {
  final values = args.entries
      .map((e) => '<${e.key}>${escapeXml(e.value)}</${e.key}>')
      .join();
  return '<?xml version="1.0" encoding="utf-8"?>'
      '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" '
      's:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body>'
      '<u:$action xmlns:u="$avTransport">$values</u:$action>'
      '</s:Body></s:Envelope>';
}

/// How UPnP writes a time: H:MM:SS.
String upnpTime(Duration d) =>
    '${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:'
    '${(d.inSeconds % 60).toString().padLeft(2, '0')}';

Duration parseUpnpTime(String text) {
  final parts = text.split(':');
  if (parts.length != 3) return Duration.zero;
  final seconds = double.tryParse(parts[2]) ?? 0;
  return Duration(
    hours: int.tryParse(parts[0]) ?? 0,
    minutes: int.tryParse(parts[1]) ?? 0,
    milliseconds: (seconds * 1000).round(),
  );
}

/// A DLNA TV, told what to play over SOAP. It fetches the file itself from the address it is given.
class DlnaConnection implements TvConnection {
  DlnaConnection(this.device, {http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final TvDevice device;
  final http.Client _client;
  final bool _ownsClient;
  final _status = StreamController<TvStatus>.broadcast();
  Timer? _poll;

  @override
  Stream<TvStatus> get status => _status.stream;

  Future<String> _call(
    String action, [
    Map<String, String> extra = const {},
  ]) async {
    final response = await _client
        .post(
          Uri.parse(device.controlUrl!),
          headers: {
            'Content-Type': 'text/xml; charset="utf-8"',
            'SOAPACTION': '"$avTransport#$action"',
          },
          body: soapBody(action, {'InstanceID': '0', ...extra}),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw TvException('the TV refused $action (${response.statusCode})');
    }
    return utf8.decode(response.bodyBytes, allowMalformed: true);
  }

  @override
  Future<void> open() async {}

  @override
  Future<void> show(TvMedia media) async {
    // Some TVs take a new address only once the old one has stopped.
    await _call('Stop').catchError((_) => '');
    await _call('SetAVTransportURI', {
      'CurrentURI': media.url,
      'CurrentURIMetaData': didlFor(media),
    });
    await _call('Play', {'Speed': '1'});
    _poll?.cancel();
    if (media.video) {
      _poll = Timer.periodic(const Duration(seconds: 2), (_) => _position());
    }
  }

  Future<void> _position() async {
    try {
      final info = await _call('GetPositionInfo');
      final state = await _call('GetTransportInfo');
      if (_status.isClosed) return;
      _status.add(
        TvStatus(
          playing: _tag(state, 'CurrentTransportState') == 'PLAYING',
          position: parseUpnpTime(_tag(info, 'RelTime')),
        ),
      );
    } catch (_) {
      // The next one may answer.
    }
  }

  @override
  Future<void> play() => _call('Play', {'Speed': '1'});

  @override
  Future<void> pause() => _call('Pause');

  @override
  Future<void> seek(Duration to) =>
      _call('Seek', {'Unit': 'REL_TIME', 'Target': upnpTime(to)});

  @override
  Future<void> close() async {
    _poll?.cancel();
    try {
      await _call('Stop');
    } catch (_) {
      // Already off.
    }
    if (!_status.isClosed) await _status.close();
    if (_ownsClient) _client.close();
  }
}

/// Finds DLNA TVs. Android lets an app ask the whole network at once. iOS allows that only to apps
/// with an entitlement that a sideloaded app cannot have, so there each address of the phone's own
/// network is asked in turn, which TVs answer as well.
class DlnaFinder {
  DlnaFinder({http.Client? client, this.askEachAddress})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Null asks each address on iOS only.
  final bool? askEachAddress;

  Stream<TvDevice> find({Duration wait = const Duration(seconds: 4)}) {
    final out = StreamController<TvDevice>();
    final seen = <String>{};
    RawDatagramSocket? socket;
    Future<void> describe(String location) async {
      if (!seen.add(location)) return;
      final uri = Uri.tryParse(location);
      // Only a TV on the home network, never an address a TV made up somewhere else.
      if (uri == null || !isLocalHost(uri.host)) return;
      try {
        final response = await _client
            .get(uri)
            .timeout(const Duration(seconds: 4));
        final device = rendererFromDescription(
          location,
          utf8.decode(response.bodyBytes, allowMalformed: true),
        );
        if (device != null && !out.isClosed) out.add(device);
      } catch (_) {
        // Not a TV that answers.
      }
    }

    Future<void> run() async {
      try {
        socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
        socket!.listen((event) {
          if (event != RawSocketEvent.read) return;
          final packet = socket?.receive();
          if (packet == null) return;
          final location = locationOf(
            utf8.decode(packet.data, allowMalformed: true),
          );
          if (location != null) describe(location);
        });
        final message = utf8.encode(searchMessage());
        try {
          socket!.send(message, InternetAddress(ssdpGroup), ssdpPort);
        } catch (_) {
          // Not allowed on this phone; the addresses are asked one by one below.
        }
        if (askEachAddress ?? Platform.isIOS) {
          for (final address in await neighbours()) {
            socket?.send(message, address, ssdpPort);
            await Future<void>.delayed(const Duration(milliseconds: 4));
          }
        }
        await Future<void>.delayed(wait);
      } catch (_) {
        // No network; nothing is found.
      } finally {
        socket?.close();
        if (!out.isClosed) await out.close();
      }
    }

    run();
    return out.stream;
  }

  /// Reads a description from an address someone typed: a whole address, or only the TV's IP.
  Future<TvDevice?> byAddress(String text) async {
    final input = text.trim();
    if (input.isEmpty) return null;
    if (input.startsWith('http://') || input.startsWith('https://')) {
      try {
        final response = await _client
            .get(Uri.parse(input))
            .timeout(const Duration(seconds: 5));
        return rendererFromDescription(
          input,
          utf8.decode(response.bodyBytes, allowMalformed: true),
        );
      } catch (_) {
        return null;
      }
    }
    final address = InternetAddress.tryParse(input);
    if (address == null) return null;
    final completer = Completer<TvDevice?>();
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.listen((event) async {
        final packet = socket?.receive();
        final location = packet == null
            ? null
            : locationOf(utf8.decode(packet.data, allowMalformed: true));
        if (location == null || completer.isCompleted) return;
        completer.complete(await byAddress(location));
      });
      socket.send(utf8.encode(searchMessage()), address, ssdpPort);
      return await completer.future.timeout(
        const Duration(seconds: 4),
        onTimeout: () => null,
      );
    } catch (_) {
      return null;
    } finally {
      socket?.close();
    }
  }
}

/// Whether an address is on a home network, where a TV is.
bool isLocalHost(String host) {
  final address = InternetAddress.tryParse(host);
  if (address == null) return false;
  if (address.isLoopback || address.isLinkLocal) return true;
  final b = address.rawAddress;
  if (address.type == InternetAddressType.IPv4) {
    return b[0] == 10 ||
        (b[0] == 172 && b[1] >= 16 && b[1] < 32) ||
        (b[0] == 192 && b[1] == 168);
  }
  return (b[0] & 0xfe) == 0xfc;
}

/// The other addresses of the phone's own /24 network, where a TV would be.
Future<List<InternetAddress>> neighbours() async {
  final out = <InternetAddress>[];
  for (final interface in await NetworkInterface.list(
    type: InternetAddressType.IPv4,
  )) {
    for (final address in interface.addresses) {
      final b = address.rawAddress;
      if (address.isLoopback || !isLocalHost(address.address)) continue;
      for (var last = 1; last < 255; last++) {
        if (last == b[3]) continue;
        out.add(InternetAddress('${b[0]}.${b[1]}.${b[2]}.$last'));
      }
    }
  }
  return out;
}
