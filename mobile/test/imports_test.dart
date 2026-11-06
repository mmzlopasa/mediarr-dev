import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/screens/imports_screen.dart';
import 'package:mediarr_api/api.dart';

UserImport entry({
  UserImportStatusEnum status = UserImportStatusEnum.running,
  int total = 10,
  int added = 3,
  int skipped = 1,
  int failed = 1,
  List<ImportPart> parts = const [],
}) => UserImport(
  id: 'a',
  source_: UserImportSource_Enum.takeout,
  status: status,
  fromZip: true,
  parts: parts,
  total: total,
  added: added,
  skipped: skipped,
  failed: failed,
  lastError: '',
  createdAt: DateTime(2026, 11, 6),
);

void main() {
  test('a running import says what it did and how far it is', () {
    final running = entry();
    expect(importSourceName(running), 'Google Takeout');
    expect(importStatus(running), 'Running');
    expect(
      describeImport(running),
      'added 3 · already here or deleted 1 · failed 1 · 5 / 10',
    );
    expect(importProgress(running), 0.5);
  });

  test('before it has counted its files, there is no share to show', () {
    expect(importProgress(entry(total: 0)), isNull);
  });

  test('an import waiting for its files counts them', () {
    final waiting = entry(
      status: UserImportStatusEnum.uploading,
      parts: [ImportPart(id: 'p', name: 'takeout-001.zip', size: 10)],
    );
    expect(importStatus(waiting), 'Waiting for files');
    expect(describeImport(waiting), '1 ZIP file uploaded');
  });
}
