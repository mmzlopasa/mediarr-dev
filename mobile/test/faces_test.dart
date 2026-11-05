import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/screens/faces_section.dart';
import 'package:mediarr/services/session.dart';
import 'package:mediarr_api/api.dart';

void main() {
  testWidgets('a crop shows only the face, out of the whole picture', (
    tester,
  ) async {
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
      MaterialApp(
        home: Center(
          child: FaceCrop(
            session: session,
            assetId: 'a',
            face: AssetFace(id: 'f', x1: 0.25, y1: 0.5, x2: 0.5, y2: 0.75),
          ),
        ),
      ),
    );
    final picture = tester.widget<Positioned>(find.byType(Positioned));
    expect(picture.width, 192);
    expect(picture.height, 192);
    expect(picture.left, -48);
    expect(picture.top, -96);
  });
}
