import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/l10n/l10n.dart';
import 'package:mediarr/screens/exports_screen.dart';
import 'package:mediarr_api/api.dart';

LibraryExport entry({
  LibraryExportStatusEnum status = LibraryExportStatusEnum.running,
  int totalFiles = 10,
  int totalBytes = 1000,
  int doneFiles = 3,
  int doneBytes = 250,
}) => LibraryExport(
  id: 'e1',
  userId: 'u1',
  userEmail: 'me@example.com',
  status: status,
  startedByAdmin: false,
  startedBy: 'Me',
  totalFiles: totalFiles,
  totalBytes: totalBytes,
  doneFiles: doneFiles,
  doneBytes: doneBytes,
  missing: 0,
  lastError: '',
  createdAt: DateTime.utc(2026, 11, 9, 10),
  parts: const [],
  canDownload: true,
);

void main() {
  test('a running export says how far it has come', () {
    final running = entry();
    expect(exportStatus(running), 'Running');
    expect(describeExport(running), '3 of 10 files · 250 B of 1000 B');
    expect(exportProgress(running), 0.25);
  });

  test(
    'progress goes by files until the bytes are known, and is full once ready',
    () {
      expect(exportProgress(entry(totalBytes: 0)), closeTo(0.3, 1e-9));
      expect(exportProgress(entry(totalBytes: 0, totalFiles: 0)), isNull);
      expect(
        exportProgress(
          entry(status: LibraryExportStatusEnum.done, doneBytes: 0),
        ),
        1,
      );
    },
  );

  test('every state has its words', () {
    expect(exportStatus(entry(status: LibraryExportStatusEnum.done)), 'Ready');
    expect(
      exportStatus(entry(status: LibraryExportStatusEnum.removed)),
      'Removed after 7 days',
    );
  });

  test('a part is saved under the name the server gives it', () {
    expect(
      exportPartName(entry(), 2),
      'mediarr-export-2026-11-09-part-002.zip',
    );
  });

  test('a broken download goes on from what is already on the phone', () {
    expect(resumeHeaders(0), isEmpty);
    expect(resumeHeaders(1024), {'Range': 'bytes=1024-'});
  });

  test('Croatian counts its files in the right form', () {
    useLanguage('hr');
    addTearDown(() => useLanguage('en'));
    expect(l.exportsScreenFiles(1), '1 datoteka');
    expect(l.exportsScreenFiles(3), '3 datoteke');
    expect(l.exportsScreenFiles(5), '5 datoteka');
  });
}
