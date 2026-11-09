import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/services/session.dart';
import 'package:mediarr/screens/link_privacy.dart';
import 'package:mediarr_api/api.dart';

ShareLink _link({int? visits, DateTime? last}) => ShareLink(
  id: 'l1',
  label: 'Family',
  hasPassword: false,
  downloadCount: 0,
  allowDownload: true,
  allowUpload: false,
  uploadOnly: false,
  showLocation: true,
  createdAt: DateTime.utc(2026, 11),
  hideFaces: HideFaces.except,
  visiblePeople: ['p1'],
  stripCamera: true,
  stripDate: true,
  askName: true,
  visits: visits,
  lastVisitAt: last,
);

LinkVisit _visit({String? city, String? country}) => LinkVisit(
  at: DateTime.utc(2026, 11, 9, 10),
  city: city,
  country: country,
  device: 'Phone · Safari',
  viewed: 3,
  downloaded: 1,
);

void main() {
  test('a new link removes camera details and hides no faces', () {
    const choice = LinkPrivacyChoice();
    expect(choice.hideFaces, HideFaces.none);
    expect(choice.stripCamera, isTrue);
    expect(choice.stripDate, isFalse);
    expect(choice.askName, isFalse);
  });

  test(
    'a link that exists keeps its choices, and an old one removed nothing',
    () {
      final choice = LinkPrivacyChoice.of(_link());
      expect(choice.hideFaces, HideFaces.except);
      expect(choice.visiblePeople, ['p1']);
      expect(choice.askName, isTrue);
      final old = LinkPrivacyChoice.of(
        ShareLink(
          id: 'l2',
          label: '',
          hasPassword: false,
          downloadCount: 0,
          allowDownload: true,
          allowUpload: false,
          uploadOnly: false,
          showLocation: false,
          createdAt: DateTime.utc(2026),
        ),
      );
      expect(old.hideFaces, HideFaces.none);
      expect(old.stripCamera, isFalse);
    },
  );

  test(
    'people are chosen and unchosen, and only count when the rest is hidden',
    () {
      var choice = const LinkPrivacyChoice(hideFaces: HideFaces.except);
      choice = choice.togglePerson('a').togglePerson('b').togglePerson('a');
      expect(choice.visiblePeople, ['b']);
      expect(choice.sentPeople, ['b']);
      expect(choice.copyWith(hideFaces: HideFaces.all).sentPeople, isEmpty);
    },
  );

  test(
    'the change keeps the location, and the date goes only with the camera',
    () {
      const choice = LinkPrivacyChoice(
        hideFaces: HideFaces.all,
        stripCamera: false,
        stripDate: true,
      );
      final update = choice.toUpdate(showLocation: true);
      expect(update.showLocation, isTrue);
      expect(update.hideFaces, HideFaces.all);
      expect(update.stripCamera, isFalse);
      expect(update.stripDate, isFalse);
      expect(update.toJson()['hideFaces'], HideFaces.all);
    },
  );

  test('how often a link was opened', () {
    expect(linkOpenedLine(_link()), 'Not opened yet');
    final last = DateTime.utc(2026, 11, 9, 10);
    expect(
      linkOpenedLine(_link(visits: 1, last: last)),
      'Opened once · last ${visitTime(last)}',
    );
    expect(
      linkOpenedLine(_link(visits: 4, last: last)),
      startsWith('Opened 4 times · last '),
    );
  });

  test('a visit says where it came from, or that it is not known', () {
    expect(
      visitPlace(_visit(city: 'Split', country: 'Croatia')),
      'Split, Croatia',
    );
    expect(visitPlace(_visit(country: 'Croatia')), 'Croatia');
    expect(visitPlace(_visit(city: ' ')), 'Unknown place');
    expect(visitActivity(_visit()), '3 viewed · 1 downloaded');
  });

  test('hiding faces says what it does not cover', () {
    final facts = albumPrivacyFacts(
      AlbumPrivacy(photos: 10, unchecked: 2, videos: 1),
    );
    expect(facts.first, contains('2 of 10 photos'));
    expect(facts.any((fact) => fact.contains('still')), isTrue);
    final checked = albumPrivacyFacts(
      AlbumPrivacy(photos: 5, unchecked: 0, videos: 0),
    );
    expect(
      checked.first,
      'Every photo in the album has been checked for faces.',
    );
    expect(checked.any((fact) => fact.contains('still')), isFalse);
  });

  testWidgets('the settings of a link fit a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final session = Session(
      serverUrl: 'http://127.0.0.1:9',
      cookie: 'c',
      user: User(
        id: 'u',
        email: 'a@b.c',
        name: 'A',
        isAdmin: false,
        totpEnabled: false,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: LinkSettingsScreen(
          session: session,
          albumId: 'a1',
          link: _link(visits: 12, last: DateTime.utc(2026, 11, 9, 10)),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('All but chosen people'), findsOneWidget);
    expect(find.text('Ask for a name'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
