import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/screens/backup_screen.dart';
import 'package:mediarr_api/api.dart';

void main() {
  test('a key over plain HTTP is exposed outside the home network only', () {
    expect(isExposedAddress('https://photos.example.com'), isFalse);
    expect(isExposedAddress('http://192.168.1.10:9851'), isFalse);
    expect(isExposedAddress('http://100.101.2.3:9851'), isFalse);
    expect(isExposedAddress('http://nas.local:9851'), isFalse);
    expect(isExposedAddress('http://photos.example.com'), isTrue);
    expect(isExposedAddress('http://8.8.8.8:9851'), isTrue);
  });

  test('a guest says how much it keeps and what it deleted', () {
    final guest = KeepGuest(
      id: 'g',
      name: 'Mum and dad',
      status: KeepGuestStatusEnum.active,
      quotaBytes: 100 * 1024 * 1024 * 1024,
      usedBytes: 0,
      deletedBytes: 1024 * 1024,
      address: 'https://x',
      createdAt: DateTime(2026),
    );
    final line = describeGuest(guest);
    expect(line, startsWith('Active · '));
    expect(line, contains('last backup not yet'));
    expect(line, contains('deleted, kept'));
  });

  test('a copy at another Mediarr says where and when it last went', () {
    final destination = BackupDestination(
      id: 'd',
      name: 'Mum and dad',
      address: 'https://keep.example.com',
      quotaBytes: 1024 * 1024 * 1024,
      lastError: '',
      createdAt: DateTime(2026),
    );
    expect(
      describeDestination(destination),
      startsWith('https://keep.example.com · last backup not yet'),
    );
  });
}
