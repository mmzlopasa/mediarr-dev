import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/screens/documents_screen.dart';
import 'package:mediarr/screens/photo_editor_screen.dart';
import 'package:mediarr_api/api.dart';

void main() {
  test('an empty album says why', () {
    expect(
      documentsEmptyText(Documents(enabled: false, analysisOn: true)),
      contains('administrator'),
    );
    expect(
      documentsEmptyText(Documents(enabled: true, analysisOn: false)),
      contains('analysis'),
    );
    expect(
      documentsEmptyText(Documents(enabled: true, analysisOn: true)),
      contains('No photos'),
    );
  });

  test('every look has a full colour matrix, and none leaves the picture as it was', () {
    expect(lookMatrix(null), isNull);
    for (final look in AssetEditsFilterEnum.values) {
      expect(lookMatrix(look), hasLength(20), reason: '$look');
    }
  });
}
