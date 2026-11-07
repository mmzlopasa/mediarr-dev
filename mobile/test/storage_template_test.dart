import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/screens/storage_template_screen.dart';
import 'package:mediarr_api/api.dart';

StorageReport report({
  bool dryRun = true,
  bool running = false,
  String template = '{{y}}/{{filename}}.{{ext}}',
  int moved = 3,
  int failed = 0,
}) => StorageReport(
  template: template,
  dryRun: dryRun,
  running: running,
  startedAt: DateTime.utc(2026, 11, 7),
  checked: 10,
  moved: moved,
  failed: failed,
);

StorageTemplate current(
  StorageReport? last, {
  String template = '{{y}}/{{filename}}.{{ext}}',
}) => StorageTemplate(
  template: template,
  defaultLayout: '{{y}}/{{MM}}/{{hash}}-{{filename}}.{{ext}}',
  report: last,
);

void main() {
  test('a report says what moved, or would', () {
    expect(describeStorageReport(report()), 'Dry run: 3 of 10 would move.');
    expect(describeStorageReport(report(dryRun: false)), 'Moved 3 of 10.');
    expect(
      describeStorageReport(report(dryRun: false, failed: 2)),
      'Moved 3 of 10. Failed: 2.',
    );
    expect(describeStorageReport(report(running: true)), 'Dry run… 10');
  });

  test('files move only after a dry run of the very template that is kept', () {
    expect(mayMoveFiles(current(report())), isTrue);
    expect(mayMoveFiles(current(null)), isFalse);
    expect(mayMoveFiles(current(report(dryRun: false))), isFalse);
    expect(mayMoveFiles(current(report(running: true))), isFalse);
    expect(mayMoveFiles(current(report(moved: 0))), isFalse);
    expect(
      mayMoveFiles(current(report(template: '{{filename}}.{{ext}}'))),
      isFalse,
    );
    expect(mayMoveFiles(current(report(), template: '')), isFalse);
  });
}
