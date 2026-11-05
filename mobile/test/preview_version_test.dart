import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/services/session.dart';

void main() {
  test('an edit gives a preview a new address, and no blurhash gives none', () {
    final before = previewVersion('LEHV6nWB2yk8pyo0adR*.7kCMdnj');
    final after = previewVersion('L6PZfSi_.AyE_3t7t7R**0o#DgR4');
    expect(before, isNotNull);
    expect(before, isNot(after));
    expect(previewVersion(null), isNull);
    expect(previewVersion(''), isNull);
    expect(previewQuery(null, null), '');
    expect(previewQuery('large', null), '?size=large');
    expect(previewQuery('large', 'abc'), '?size=large&v=abc');
    expect(previewQuery(null, 'abc'), '?v=abc');
  });
}
