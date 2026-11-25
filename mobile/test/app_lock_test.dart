import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/screens/lock_screen.dart';
import 'package:mediarr/screens/settings_screen.dart';
import 'package:mediarr/services/app_lock.dart';
import 'package:mediarr/services/settings.dart';

class FakeAuthenticator implements Authenticator {
  bool screenLock = true;
  bool passes = true;
  int asked = 0;

  @override
  Future<bool> hasScreenLock() async => screenLock;

  @override
  Future<bool> authenticate(String reason) async {
    asked++;
    return passes;
  }
}

void main() {
  final left = DateTime(2026, 11, 25, 12);

  group('when the lock comes back', () {
    bool locks(LockAfter after, Duration away, {bool enabled = true}) =>
        locksOnReturn(
          enabled: enabled,
          after: after,
          leftAt: left,
          now: left.add(away),
        );

    test('a cold start always locks, once the lock is on', () {
      expect(locksAtStart(enabled: true), isTrue);
      expect(locksAtStart(enabled: false), isFalse);
    });

    test('immediately locks after any time away', () {
      expect(locks(LockAfter.immediately, Duration.zero), isTrue);
      expect(locks(LockAfter.immediately, const Duration(seconds: 1)), isTrue);
    });

    test('after 1 minute waits a whole minute', () {
      expect(locks(LockAfter.oneMinute, const Duration(seconds: 59)), isFalse);
      expect(locks(LockAfter.oneMinute, const Duration(minutes: 1)), isTrue);
    });

    test('after 5 minutes waits five', () {
      expect(locks(LockAfter.fiveMinutes, const Duration(minutes: 4)), isFalse);
      expect(locks(LockAfter.fiveMinutes, const Duration(minutes: 5)), isTrue);
    });

    test('with the lock off nothing locks', () {
      expect(
        locks(LockAfter.immediately, const Duration(hours: 1), enabled: false),
        isFalse,
      );
    });

    test(
      'never having left does not lock, and a clock that went back does',
      () {
        expect(
          locksOnReturn(
            enabled: true,
            after: LockAfter.fiveMinutes,
            leftAt: null,
            now: left,
          ),
          isFalse,
        );
        expect(
          locks(LockAfter.fiveMinutes, const Duration(minutes: -10)),
          isTrue,
        );
      },
    );

    test('the settings keep the lock and its delay', () {
      final saved = AppSettings.fromJson(
        const AppSettings(
          appLock: true,
          appLockAfter: LockAfter.fiveMinutes,
        ).toJson(),
      );
      expect(saved.appLock, isTrue);
      expect(saved.appLockAfter, LockAfter.fiveMinutes);
      expect(AppSettings.fromJson(const {}).appLock, isFalse);
      expect(
        AppSettings.fromJson(const {}).appLockAfter,
        LockAfter.immediately,
      );
    });
  });

  group('the lock screen', () {
    late FakeAuthenticator auth;
    late DateTime now;

    setUp(() {
      auth = FakeAuthenticator();
      now = left;
    });

    Future<ProviderContainer> start(
      WidgetTester tester, {
      required bool enabled,
      LockAfter after = LockAfter.immediately,
    }) async {
      FlutterSecureStorage.setMockInitialValues({
        'app_settings': jsonEncode(
          AppSettings(appLock: enabled, appLockAfter: after).toJson(),
        ),
      });
      final container = ProviderContainer(
        overrides: [
          authenticatorProvider.overrideWithValue(auth),
          lockClockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            builder: (context, child) => LockGate(child: child!),
            home: const Scaffold(body: Text('A photo of the beach')),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      return container;
    }

    Future<void> leaveAndReturn(WidgetTester tester, Duration away) async {
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump();
      now = now.add(away);
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump();
      await tester.pump();
    }

    testWidgets('with the lock off the library shows at once', (tester) async {
      await start(tester, enabled: false);
      expect(find.text('A photo of the beach'), findsOneWidget);
      expect(find.byType(LockScreen), findsNothing);
      expect(auth.asked, 0);
    });

    testWidgets('a cold start hides the library and asks by itself, once', (
      tester,
    ) async {
      auth.passes = false;
      await start(tester, enabled: true);
      expect(find.text('A photo of the beach'), findsNothing);
      expect(find.text('Unlock'), findsOneWidget);
      expect(auth.asked, 1);

      // Cancelling leaves the lock screen, and does not ask again by itself.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(auth.asked, 1);
      expect(find.text('A photo of the beach'), findsNothing);

      auth.passes = true;
      await tester.tap(find.text('Unlock'));
      await tester.pump();
      expect(auth.asked, 2);
      expect(find.text('A photo of the beach'), findsOneWidget);
      expect(find.byType(LockScreen), findsNothing);
    });

    testWidgets('coming back locks only once the chosen time has passed', (
      tester,
    ) async {
      final container = await start(
        tester,
        enabled: true,
        after: LockAfter.oneMinute,
      );
      // The prompt at the start passed.
      expect(find.text('A photo of the beach'), findsOneWidget);

      await leaveAndReturn(tester, const Duration(seconds: 30));
      expect(find.text('A photo of the beach'), findsOneWidget);
      expect(auth.asked, 1);

      auth.passes = false;
      await leaveAndReturn(tester, const Duration(minutes: 2));
      expect(container.read(appLockProvider).locked, isTrue);
      expect(find.text('A photo of the beach'), findsNothing);
      expect(auth.asked, 2);
    });

    testWidgets('on the way to the background only the logo shows', (
      tester,
    ) async {
      await start(tester, enabled: true, after: LockAfter.fiveMinutes);
      expect(find.text('A photo of the beach'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(find.text('A photo of the beach'), findsNothing);
      expect(find.byType(LockScreen), findsOneWidget);
      // Nothing to unlock: it is only a cover.
      expect(
        tester
            .widget<Visibility>(
              find.descendant(
                of: find.byType(LockScreen),
                matching: find.byType(Visibility),
              ),
            )
            .visible,
        isFalse,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('A photo of the beach'), findsOneWidget);
    });

    testWidgets('a shared file waits until the lock is passed', (tester) async {
      auth.passes = false;
      final container = await start(tester, enabled: true);
      var taken = false;
      container
          .read(appLockProvider.notifier)
          .whenUnlocked()
          .then((_) => taken = true);
      await tester.pump();
      expect(taken, isFalse);
      auth.passes = true;
      await container.read(appLockProvider.notifier).unlock();
      await tester.pump();
      expect(taken, isTrue);
    });
  });

  group('the setting', () {
    late FakeAuthenticator auth;

    Future<ProviderContainer> open(WidgetTester tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [authenticatorProvider.overrideWithValue(auth)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AppLockSettings()),
        ),
      );
      await tester.pump();
      return container;
    }

    setUp(() => auth = FakeAuthenticator());

    testWidgets('turning it on and off asks for the phone lock', (
      tester,
    ) async {
      final container = await open(tester);
      expect(container.read(settingsProvider).appLock, isFalse);

      auth.passes = false;
      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(auth.asked, 1);
      expect(container.read(settingsProvider).appLock, isFalse);

      auth.passes = true;
      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(container.read(settingsProvider).appLock, isTrue);

      await tester.tap(find.text('After 5 minutes'));
      await tester.pump();
      expect(
        container.read(settingsProvider).appLockAfter,
        LockAfter.fiveMinutes,
      );

      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(auth.asked, 3);
      expect(container.read(settingsProvider).appLock, isFalse);
    });

    testWidgets('a phone without a screen lock cannot turn it on', (
      tester,
    ) async {
      auth.screenLock = false;
      final container = await open(tester);
      expect(
        find.text(
          "This phone has no screen lock. Set one in the phone's settings first.",
        ),
        findsOneWidget,
      );
      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(auth.asked, 0);
      expect(container.read(settingsProvider).appLock, isFalse);
    });
  });
}
