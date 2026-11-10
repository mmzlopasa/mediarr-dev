import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mediarr/cast/chromecast.dart';
import 'package:mediarr/cast/dlna.dart';
import 'package:mediarr/cast/tv.dart';
import 'package:mediarr/cast/tv_controller.dart';
import 'package:mediarr/cast/tv_sheet.dart';
import 'package:mediarr/services/session.dart';
import 'package:mediarr/screens/viewer_screen.dart';
import 'package:mediarr_api/api.dart';

const photo = '22222222-2222-4222-8222-222222222222';
const other = '33333333-3333-4333-8333-333333333333';
const video = '44444444-4444-4444-8444-444444444444';

CastMedia mediaOf(String id, {bool isVideo = false, bool hls = false}) =>
    CastMedia(
      id: id,
      kind: isVideo ? CastMediaKindEnum.video : CastMediaKindEnum.photo,
      image: '/api/tv/{token}/assets/$id/image',
      file: isVideo ? '/api/tv/{token}/assets/$id/original' : null,
      hls: hls ? '/api/tv/{token}/assets/$id/video/master.m3u8' : null,
      mimeType: isVideo ? 'video/mp4' : null,
      durationMs: isVideo ? 12000 : null,
    );

class FakeCastServer implements CastServer {
  final started = <List<String>>[];
  final added = <List<String>>[];
  final stopped = <String>[];

  @override
  String get serverUrl => 'http://192.168.1.5:9851';

  @override
  Future<CastSession> start(List<String> ids) async {
    started.add(ids);
    return CastSession(
      id: 'session-1',
      token: 'tok',
      expiresAt: DateTime.utc(2026, 11, 10, 14),
      media: [for (final id in ids) mediaOf(id, isVideo: id == video)],
    );
  }

  @override
  Future<CastSession> add(String sessionId, List<String> ids) async {
    added.add(ids);
    return CastSession(
      id: sessionId,
      expiresAt: DateTime.utc(2026, 11, 10, 14),
      media: [for (final id in ids) mediaOf(id, isVideo: id == video)],
    );
  }

  @override
  Future<void> stop(String sessionId) async => stopped.add(sessionId);
}

class FakeTv implements TvConnection {
  final shown = <TvMedia>[];
  final calls = <String>[];
  final statuses = StreamController<TvStatus>.broadcast();
  Completer<void>? hold;

  @override
  Stream<TvStatus> get status => statuses.stream;

  @override
  Future<void> open() async => calls.add('open');

  @override
  Future<void> show(TvMedia media) async {
    await hold?.future;
    shown.add(media);
  }

  @override
  Future<void> play() async => calls.add('play');

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> seek(Duration to) async => calls.add('seek ${to.inSeconds}');

  @override
  Future<void> close() async => calls.add('close');
}

const livingRoom = TvDevice(
  id: 'uuid:tv',
  name: 'Living room',
  kind: TvKind.dlna,
  host: '192.168.1.20',
  controlUrl: 'http://192.168.1.20:1400/AVTransport/Control',
);

void main() {
  group('the Cast protocol', () {
    test('a message goes there and back, also in pieces', () {
      const message = CastMessage(
        source: 'sender-0',
        destination: 'receiver-0',
        namespace: 'urn:x-cast-com.google.cast.receiver',
        payload: '{"type":"LAUNCH","appId":"CC1AD845","requestId":1,"ü":"ž"}',
      );
      final bytes = message.encode();
      final length =
          (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
      expect(length, bytes.length - 4);
      final framer = CastFramer();
      expect(framer.add(bytes.sublist(0, 7)), isEmpty);
      final got = framer.add([...bytes.sublist(7), ...bytes]);
      expect(got, hasLength(2));
      expect(got.first.destination, 'receiver-0');
      expect(got.first.json['appId'], defaultMediaReceiver);
      expect(got.last.json['ü'], 'ž');
    });

    test('a Chromecast is started, shown a photo, and stopped', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final received = <Map<String, dynamic>>[];
      server.listen((socket) {
        final framer = CastFramer();
        void reply(String namespace, Map<String, Object?> body) => socket.add(
          CastMessage(
            source: 'receiver-0',
            destination: 'sender-0',
            namespace: namespace,
            payload: jsonEncode(body),
          ).encode(),
        );
        socket.listen((data) {
          for (final message in framer.add(data)) {
            final body = message.json;
            received.add({...body, 'to': message.destination});
            switch (body['type']) {
              case 'LAUNCH':
                reply('urn:x-cast-com.google.cast.receiver', {
                  'type': 'RECEIVER_STATUS',
                  'requestId': body['requestId'],
                  'status': {
                    'applications': [
                      {
                        'appId': defaultMediaReceiver,
                        'transportId': 'web-5',
                        'sessionId': 's-1',
                      },
                    ],
                  },
                });
              case 'LOAD' || 'PLAY' || 'PAUSE' || 'SEEK':
                reply('urn:x-cast-com.google.cast.media', {
                  'type': 'MEDIA_STATUS',
                  'requestId': body['requestId'],
                  'status': [
                    {
                      'mediaSessionId': 7,
                      'playerState': body['type'] == 'PAUSE'
                          ? 'PAUSED'
                          : 'PLAYING',
                      'currentTime': 3.5,
                    },
                  ],
                });
            }
          }
        });
      });
      final tv = ChromecastConnection(
        '127.0.0.1',
        server.port,
        connect: (host, port) => Socket.connect(host, port),
      );
      final statuses = <TvStatus>[];
      final listening = tv.status.listen(statuses.add);
      await tv.open();
      await tv.show(
        const TvMedia(
          id: photo,
          url: 'http://192.168.1.5:9851/api/tv/tok/assets/$photo/image',
          contentType: 'image/jpeg',
          video: false,
        ),
      );
      await tv.seek(const Duration(seconds: 30));
      await tv.pause();
      await tv.close();
      await listening.cancel();
      await server.close();

      final load = received.firstWhere((m) => m['type'] == 'LOAD');
      expect(load['to'], 'web-5');
      expect((load['media'] as Map)['contentId'], endsWith('/image'));
      expect((load['media'] as Map)['contentType'], 'image/jpeg');
      final seek = received.firstWhere((m) => m['type'] == 'SEEK');
      expect(seek['mediaSessionId'], 7);
      expect(seek['currentTime'], 30);
      expect(
        received.map((m) => m['type']),
        containsAllInOrder(['CONNECT', 'LAUNCH', 'CONNECT', 'LOAD']),
      );
      expect(received.any((m) => m['type'] == 'STOP'), isTrue);
      expect(statuses.last.playing, isFalse);
    });
  });

  group('DLNA', () {
    test('an answer to a search gives where the TV describes itself', () {
      expect(
        locationOf(
          'HTTP/1.1 200 OK\r\nCACHE-CONTROL: max-age=1800\r\nLocation: http://192.168.1.20:1400/xml/device.xml\r\n'
          'ST: urn:schemas-upnp-org:device:MediaRenderer:1\r\n\r\n',
        ),
        'http://192.168.1.20:1400/xml/device.xml',
      );
      expect(locationOf('NOTIFY * HTTP/1.1\r\nLOCATION: x\r\n\r\n'), isNull);
      final message = searchMessage();
      expect(message, startsWith('M-SEARCH * HTTP/1.1\r\n'));
      expect(message, contains('MAN: "ssdp:discover"\r\n'));
      expect(message, contains('ST: $mediaRenderer\r\n'));
      expect(message, endsWith('\r\n\r\n'));
    });

    test('a description gives the name and the AVTransport address', () {
      const xml = '''<?xml version="1.0"?>
<root xmlns="urn:schemas-upnp-org:device-1-0"><device>
<friendlyName>Living room &amp; kitchen</friendlyName><UDN>uuid:abc</UDN>
<serviceList>
<service><serviceType>urn:schemas-upnp-org:service:RenderingControl:1</serviceType><controlURL>/RC</controlURL></service>
<service><serviceType>urn:schemas-upnp-org:service:AVTransport:1</serviceType><controlURL>AVTransport/Control</controlURL></service>
</serviceList></device></root>''';
      final device = rendererFromDescription(
        'http://192.168.1.20:1400/xml/device.xml',
        xml,
      )!;
      expect(device.name, 'Living room & kitchen');
      expect(device.id, 'uuid:abc');
      expect(
        device.controlUrl,
        'http://192.168.1.20:1400/xml/AVTransport/Control',
      );
      expect(
        rendererFromDescription(
          'http://192.168.1.20/d.xml',
          '<root><URLBase>http://192.168.1.20:9000/</URLBase><device><friendlyName>TV</friendlyName>'
              '<serviceList><service><serviceType>urn:schemas-upnp-org:service:AVTransport:2</serviceType>'
              '<controlURL>/upnp/control/avt</controlURL></service></serviceList></device></root>',
        )!.controlUrl,
        'http://192.168.1.20:9000/upnp/control/avt',
      );
      // A media server, which cannot be told to play anything, is not a TV.
      expect(
        rendererFromDescription(
          'http://192.168.1.21/d.xml',
          '<root><device><friendlyName>NAS</friendlyName><serviceList><service>'
              '<serviceType>urn:schemas-upnp-org:service:ContentDirectory:1</serviceType>'
              '<controlURL>/cd</controlURL></service></serviceList></device></root>',
        ),
        isNull,
      );
    });

    test('a TV is told the address with its metadata, then to play', () async {
      final actions = <String, String>{};
      final client = MockClient((request) async {
        final action = request.headers['SOAPACTION']!.split('#').last;
        actions[action.replaceAll('"', '')] = request.body;
        expect(request.url.toString(), 'http://192.168.1.20:1400/control');
        return http.Response(
          '<s:Envelope><s:Body><u:Response><RelTime>0:00:05</RelTime>'
          '<CurrentTransportState>PLAYING</CurrentTransportState></u:Response></s:Body></s:Envelope>',
          200,
        );
      });
      final tv = DlnaConnection(
        const TvDevice(
          id: 'tv',
          name: 'TV',
          kind: TvKind.dlna,
          host: '192.168.1.20',
          controlUrl: 'http://192.168.1.20:1400/control',
        ),
        client: client,
      );
      await tv.show(
        const TvMedia(
          id: photo,
          url: 'http://192.168.1.5:9851/api/tv/a&b/assets/$photo/image',
          contentType: 'image/jpeg',
          video: false,
          title: 'Summer <3',
        ),
      );
      await tv.seek(const Duration(minutes: 1, seconds: 5));
      await tv.close();
      final set = actions['SetAVTransportURI']!;
      expect(
        set,
        contains(
          '<CurrentURI>http://192.168.1.5:9851/api/tv/a&amp;b/assets/$photo/image</CurrentURI>',
        ),
      );
      // The DIDL goes escaped inside the SOAP, once more.
      expect(set, contains('&lt;DIDL-Lite'));
      expect(set, contains('DLNA.ORG_PN=JPEG_LRG'));
      expect(set, contains('Summer &amp;lt;3'));
      expect(actions['Play'], contains('<Speed>1</Speed>'));
      expect(actions['Seek'], contains('<Target>0:01:05</Target>'));
      expect(actions['Seek'], contains('<Unit>REL_TIME</Unit>'));
      expect(actions, contains('Stop'));
    });

    test('UPnP times are read and written', () {
      expect(
        upnpTime(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
      expect(
        parseUpnpTime('0:01:05.500'),
        const Duration(seconds: 65, milliseconds: 500),
      );
      expect(parseUpnpTime('NOT_IMPLEMENTED'), Duration.zero);
    });

    test('only the home network is asked', () {
      for (final host in [
        '192.168.1.4',
        '10.0.0.2',
        '172.20.1.1',
        '127.0.0.1',
        'fd00::1',
      ]) {
        expect(isLocalHost(host), isTrue, reason: host);
      }
      for (final host in ['8.8.8.8', '172.32.0.1', 'example.com']) {
        expect(isLocalHost(host), isFalse, reason: host);
      }
    });
  });

  group('what a TV is given', () {
    test('a Chromecast plays the stream of a video, and a DLNA TV its file', () {
      final media = mediaOf(video, isVideo: true, hls: true);
      final cast = tvMediaFor(
        media,
        'http://192.168.1.5:9851',
        't/k',
        TvKind.chromecast,
      );
      expect(
        cast.url,
        'http://192.168.1.5:9851/api/tv/t%2Fk/assets/$video/video/master.m3u8',
      );
      expect(cast.contentType, 'application/vnd.apple.mpegurl');
      expect(cast.duration, const Duration(seconds: 12));
      final dlna = tvMediaFor(
        media,
        'http://192.168.1.5:9851',
        't',
        TvKind.dlna,
      );
      expect(dlna.url, endsWith('/api/tv/t/assets/$video/original'));
      expect(dlna.contentType, 'video/mp4');
      final still = tvMediaFor(mediaOf(photo), 'http://h', 't', TvKind.dlna);
      expect(still.contentType, 'image/jpeg');
      expect(still.video, isFalse);
    });
  });

  group('the TV follows the phone', () {
    late FakeTv tv;
    late FakeCastServer server;
    late ProviderContainer container;

    setUp(() {
      tv = FakeTv();
      server = FakeCastServer();
      container = ProviderContainer(
        overrides: [
          tvProvider.overrideWith(() => TvController(connector: (_) => tv)),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('the photo swiped to is sent, and stopping ends the token', () async {
      final controller = container.read(tvProvider.notifier);
      await controller.start(
        server,
        livingRoom,
        const TvAsset(photo, video: false),
      );
      expect(server.started, [
        [photo],
      ]);
      expect(
        tv.shown.single.url,
        'http://192.168.1.5:9851/api/tv/tok/assets/$photo/image',
      );
      expect(container.read(tvProvider).device, livingRoom);

      await controller.follow(const TvAsset(other, video: false));
      expect(server.added, [
        [other],
      ]);
      expect(tv.shown.last.url, endsWith('/api/tv/tok/assets/$other/image'));
      // Back to one the TV already has: no need to ask the server again.
      await controller.follow(const TvAsset(photo, video: false));
      expect(server.added, hasLength(1));
      expect(tv.shown, hasLength(3));

      await controller.follow(const TvAsset(video, video: true));
      expect(container.read(tvProvider).video, isTrue);
      await controller.playOrPause();
      await controller.seek(const Duration(seconds: 4));
      expect(tv.calls, containsAllInOrder(['open', 'pause', 'seek 4']));

      await controller.stop();
      expect(server.stopped, ['session-1']);
      expect(tv.calls.last, 'close');
      expect(container.read(tvProvider).device, isNull);
      // Nothing more goes to a TV that is no longer there.
      await controller.follow(const TvAsset(other, video: false));
      expect(tv.shown, hasLength(4));
    });

    test('fast swiping ends on the last photo', () async {
      final controller = container.read(tvProvider.notifier);
      await controller.start(
        server,
        livingRoom,
        const TvAsset(photo, video: false),
      );
      tv.hold = Completer<void>();
      final first = controller.follow(const TvAsset(other, video: false));
      final second = controller.follow(const TvAsset(video, video: true));
      tv.hold!.complete();
      await Future.wait([first, second]);
      expect(tv.shown.last.id, video);
      expect(container.read(tvProvider).current, video);
    });

    test('a TV that goes away stops casting', () async {
      final controller = container.read(tvProvider.notifier);
      await controller.start(
        server,
        livingRoom,
        const TvAsset(photo, video: false),
      );
      tv.statuses.add(const TvStatus(ended: true));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(tvProvider).device, isNull);
      expect(server.stopped, ['session-1']);
    });
  });

  testWidgets(
    'the viewer\'s buttons fit a narrow phone, with the rest in a menu',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final pressed = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(
                actions: fitActions(context, [
                  for (final (index, name) in [
                    'Slideshow',
                    'Favorite',
                    'Edit',
                    'Play on TV',
                    'Share',
                    'Details',
                    'Delete',
                  ].indexed)
                    ViewerAction(
                      priority: switch (name) {
                        'Share' => 0,
                        'Details' => 1,
                        'Edit' => 10,
                        _ => index + 2,
                      },
                      tooltip: name,
                      icon: const Icon(Icons.circle),
                      onPressed: () => pressed.add(name),
                    ),
                ]),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Share'), findsOneWidget);
      expect(find.byTooltip('Details'), findsOneWidget);
      expect(find.byTooltip('Edit'), findsNothing);
      await tester.tap(find.byTooltip('More actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(pressed, ['Edit']);
    },
  );

  testWidgets('the list of TVs and the bar fit a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final tv = FakeTv();
    final server = FakeCastServer();
    final container = ProviderContainer(
      overrides: [
        tvProvider.overrideWith(() => TvController(connector: (_) => tv)),
      ],
    );
    addTearDown(container.dispose);
    const longName = TvDevice(
      id: 'uuid:long',
      name: 'The very large television in the living room downstairs',
      kind: TvKind.dlna,
      host: '192.168.1.30',
      controlUrl: 'http://192.168.1.30/c',
    );
    container.read(tvProvider.notifier).addDevice(longName);
    await container
        .read(tvProvider.notifier)
        .start(server, longName, const TvAsset(video, video: true));
    final session = Session(
      serverUrl: 'http://server',
      cookie: 'mediarr_session=x',
      user: User(
        id: 'u',
        email: 'a@example.com',
        name: 'A',
        isAdmin: false,
        totpEnabled: false,
      ),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            bottomNavigationBar: const TvBar(),
            body: TvSheet(
              session: session,
              asset: const TvAsset(photo, video: false),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text(longName.name), findsOneWidget);
    expect(find.byTooltip('Pause on the TV'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(tester.getSize(find.byType(TvBar)).height, lessThan(100));
    await tester.tap(find.text('Add a TV by its address'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('tv-address')), findsOneWidget);
    // Discovery is still running; it is left to end on its own.
    await tester.pump(const Duration(seconds: 5));
  });
}
