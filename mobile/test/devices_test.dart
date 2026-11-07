import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/screens/devices_screen.dart';
import 'package:mediarr/services/devices.dart';
import 'package:mediarr_api/api.dart';

BackupDevice device({
  bool quiet = false,
  int failed = 0,
  int files = 10,
  int confirmed = 10,
  int trashed = 0,
  int gone = 0,
}) => BackupDevice(
  id: 'd',
  name: 'Pixel 8',
  platform: 'android',
  appVersion: '0.8.0',
  createdAt: DateTime.utc(2026, 11, 1),
  reportedAt: DateTime.utc(2026, 11, 7),
  quiet: quiet,
  pending: 2,
  working: 1,
  verified: 10,
  failed: failed,
  files: files,
  confirmed: confirmed,
  trashed: trashed,
  gone: gone,
  ownerEmail: 'ana@example.com',
  ownerName: 'Ana',
);

void main() {
  test('each checksum is reported once, in lower case', () {
    expect(
      uniqueChecksums({
        'a': ['AB', 'cd'],
        'b': ['ab'],
        'c': [],
      }),
      ['ab', 'cd'],
    );
  });

  test('a large list goes in parts of at most 5000', () {
    final all = [for (var i = 0; i < 12001; i++) '$i'];
    final parts = chunked(all);
    expect(parts.map((part) => part.length), [5000, 5000, 2001]);
    expect(parts.expand((part) => part), all);
    expect(chunked(const []), isEmpty);
  });

  test('a device is described by what the server counts', () {
    expect(deviceState(device()), 'All good');
    expect(deviceState(device(failed: 1)), 'Needs a look');
    expect(deviceState(device(gone: 1)), 'Needs a look');
    expect(deviceState(device(quiet: true, failed: 1)), 'Quiet');
    expect(describeSafe(device()), '10 files confirmed by the server');
    expect(
      describeSafe(device(files: 12, confirmed: 10)),
      '10 files confirmed by the server, of 12 the device sent',
    );
    expect(describeCounts(device()), 'waiting 3 · not sent 0');
    expect(
      describeCounts(device(trashed: 1, gone: 2)),
      'waiting 3 · not sent 0 · in the trash 1 · no longer on the server 2',
    );
    expect(quietLabel(0), 'Never');
    expect(quietLabel(1), '1 day');
    expect(quietLabel(7), '7 days');
  });
}
