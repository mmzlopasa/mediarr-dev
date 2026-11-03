import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/screens/backup_card.dart';
import 'package:mediarr/services/backup.dart';
import 'package:mediarr/theme.dart';

const _channel = MethodChannel('app.mediarr/backup');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void reply(Map<String, Object?> status) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          _channel,
          (call) async => call.method == 'status' ? status : null,
        );
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildTheme(),
          home: const Scaffold(
            body: SingleChildScrollView(child: BackupCard()),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  test('the status map from the native engine is read', () {
    final status = BackupStatus.fromMap({
      'enabled': true,
      'wifiOnly': false,
      'pending': 2,
      'working': 1,
      'verified': 7,
      'failed': 1,
      'lastFinished': 1000,
      'failures': [
        {'id': 'a', 'error': 'damaged'},
      ],
    });
    expect(status.total, 11);
    expect(status.wifiOnly, isFalse);
    expect(status.lastFinished, DateTime.fromMillisecondsSinceEpoch(1000000));
    expect(status.failures.single.error, 'damaged');
  });

  test('a missing or empty status is safe', () {
    final status = BackupStatus.fromMap(const {});
    expect(status.enabled, isFalse);
    expect(status.total, 0);
  });

  test('the last backup is described in plain words', () {
    final now = DateTime(2026, 11, 3, 12);
    expect(describeLastBackup(null, now), contains('Nothing'));
    expect(
      describeLastBackup(now.subtract(const Duration(seconds: 5)), now),
      contains('just now'),
    );
    expect(
      describeLastBackup(now.subtract(const Duration(minutes: 9)), now),
      contains('9 min'),
    );
    expect(
      describeLastBackup(now.subtract(const Duration(hours: 3)), now),
      contains('3 h'),
    );
    expect(
      describeLastBackup(now.subtract(const Duration(days: 2)), now),
      contains('2 d'),
    );
  });

  testWidgets('when it is off, the limits of iOS are explained', (
    tester,
  ) async {
    reply({'enabled': false});
    await show(tester);
    expect(find.text('Automatic backup'), findsOneWidget);
    expect(find.textContaining('swipe the app away'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('when it is on, the real counts are shown', (tester) async {
    reply({
      'enabled': true,
      'pending': 3,
      'working': 2,
      'verified': 5,
      'failed': 1,
    });
    await show(tester);
    expect(find.text('5 of 11 verified on the server'), findsOneWidget);
    expect(find.textContaining('2 sending'), findsOneWidget);
    expect(find.text('Try the 1 failed again'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
