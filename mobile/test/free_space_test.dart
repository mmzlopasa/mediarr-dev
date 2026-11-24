import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/services/free_space.dart';

void main() {
  const a = 'aaaa';
  const b = 'bbbb';
  const c = 'cccc';

  Future<Map<String, List<String>>> record() async => {
    'one': [a],
    'live': [b, c],
    'gone': [c],
  };

  test('only what the server still has may leave the phone', () async {
    final ids = await stillSafeToRemove(
      ids: ['one', 'live'],
      verified: record,
      onServer: (sums) async => {a, b},
    );
    // The Live Photo's video is no longer there, so neither of its files may go.
    expect(ids, ['one']);
  });

  test('an asset the backup no longer counts as sent stays', () async {
    final ids = await stillSafeToRemove(
      ids: ['one', 'unknown'],
      verified: record,
      onServer: (sums) async => {a, b, c},
    );
    expect(ids, ['one']);
  });

  test('checksums are compared whatever their case', () async {
    final ids = await stillSafeToRemove(
      ids: ['one'],
      verified: () async => {
        'one': ['AAAA'],
      },
      onServer: (sums) async {
        expect(sums, ['aaaa']);
        return {'aaaa'};
      },
    );
    expect(ids, ['one']);
  });

  test('a file changed on the phone since it was sent stays', () async {
    final ids = await stillSafeToRemove(
      ids: ['one', 'gone'],
      verified: record,
      onServer: (sums) async => {a, b, c},
      currentChecksum: (id) async => id == 'one' ? 'ffff' : c,
    );
    expect(ids, ['gone']);
  });

  test('a file that cannot be read again stays', () async {
    final ids = await stillSafeToRemove(
      ids: ['one', 'gone'],
      verified: record,
      onServer: (sums) async => {a, b, c},
      currentChecksum: (id) async {
        if (id == 'one') throw const FileSystemException('gone');
        return null;
      },
    );
    expect(ids, isEmpty);
  });

  test('when the server cannot be asked, the error reaches the caller', () {
    expect(
      stillSafeToRemove(
        ids: ['one'],
        verified: record,
        onServer: (sums) async => throw const SocketException('down'),
      ),
      throwsA(isA<SocketException>()),
    );
  });

  test('a file is hashed as the backup hashes it', () async {
    final dir = await Directory.systemTemp.createTemp('free-space');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/photo.jpg')..writeAsStringSync('abc');
    expect(
      await fileSha256(file.path),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });
}
