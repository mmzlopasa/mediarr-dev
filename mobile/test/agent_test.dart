import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/services/agent.dart';

void main() {
  test('a user agent is named in plain words', () {
    expect(
      describeAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/156.0.0.0 Safari/537.36 Edg/156.0.0.0',
      ).title,
      'Edge on Windows',
    );
    final phone = describeAgent(
      'Mozilla/5.0 (iPhone; CPU iPhone OS 19_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/19.0 Mobile/15E148 Safari/604.1',
    );
    expect(phone.title, 'Safari on iPhone');
    expect(phone.phone, isTrue);
    expect(describeAgent('Dart/3.9 (dart:io)').title, 'Mediarr app');
    expect(describeAgent('').title, 'Unknown device');
  });

  test('time ago picks the largest unit', () {
    final now = DateTime(2026, 11, 6, 12);
    expect(since(DateTime(2026, 11, 6, 9), now), '3 hours ago');
    expect(since(DateTime(2026, 11, 5, 12), now), '1 day ago');
    expect(since(DateTime(2026, 11, 6, 11, 59, 30), now), 'now');
  });
}
