import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

import '../l10n/l10n.dart';
import 'settings.dart';

/// Whether coming back from the background asks for the phone's lock again. [leftAt] is when the
/// app went to the background, null when it never did. A clock that went back locks too.
bool locksOnReturn({
  required bool enabled,
  required LockAfter after,
  required DateTime? leftAt,
  required DateTime now,
}) {
  if (!enabled || leftAt == null) return false;
  final away = now.difference(leftAt);
  return away.isNegative || away >= after.delay;
}

/// A cold start always asks, once the lock is on.
bool locksAtStart({required bool enabled}) => enabled;

/// The phone's own lock: Mediarr keeps no PIN of its own.
abstract class Authenticator {
  /// Whether the phone has any screen lock to ask for.
  Future<bool> hasScreenLock();

  /// Asks for a fingerprint or face, or else the phone's PIN, pattern or password.
  Future<bool> authenticate(String reason);
}

class PhoneAuthenticator implements Authenticator {
  final _auth = LocalAuthentication();

  @override
  Future<bool> hasScreenLock() async {
    try {
      return await _auth.isDeviceSupported();
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        authMessages: [
          IOSAuthMessages(cancelButton: l.appLockCancel),
          AndroidAuthMessages(
            signInTitle: l.appLockTitle,
            signInHint: reason,
            cancelButton: l.appLockCancel,
          ),
        ],
      );
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    } on LocalAuthException {
      return false;
    }
  }
}

final authenticatorProvider = Provider<Authenticator>(
  (ref) => PhoneAuthenticator(),
);

/// The time it is now; tests move it on.
final lockClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

class AppLockState {
  const AppLockState({
    this.ready = false,
    this.locked = false,
    this.covered = false,
  });

  /// The settings have been read, so it is known whether the lock is on.
  final bool ready;

  /// The phone's lock is needed before anything of the library is shown.
  final bool locked;

  /// The app is on its way to the background, and the list of recent apps must not show photos.
  final bool covered;

  /// Whether the app is hidden behind the lock screen.
  bool get hidesApp => !ready || locked || covered;
}

final appLockProvider = NotifierProvider<AppLockNotifier, AppLockState>(
  AppLockNotifier.new,
);

class AppLockNotifier extends Notifier<AppLockState> {
  static const _channel = MethodChannel('app.mediarr/lock');

  DateTime? _leftAt;
  bool _asking = false;
  bool _promptWaiting = false;
  AppLifecycleState? _lifecycle;
  final _waiting = <Completer<void>>[];

  @override
  AppLockState build() {
    unawaited(
      ref.read(settingsProvider.notifier).loaded.then((_) {
        if (ref.mounted) _begin();
      }),
    );
    ref.listen(
      settingsProvider.select((settings) => settings.appLock),
      (_, enabled) => unawaited(_hideFromRecents(enabled)),
    );
    return const AppLockState();
  }

  bool get _enabled => ref.read(settingsProvider).appLock;

  void _begin() {
    final locked = locksAtStart(enabled: _enabled);
    state = AppLockState(ready: true, locked: locked);
    unawaited(_hideFromRecents(_enabled));
    if (locked) {
      _appeared();
    } else {
      _release();
    }
  }

  /// Done once the app is open: share sheets and sign-in links wait for this.
  Future<void> whenUnlocked() {
    if (state.ready && !state.locked) return Future.value();
    final waiting = Completer<void>();
    _waiting.add(waiting);
    return waiting.future;
  }

  void _release() {
    for (final waiting in _waiting) {
      waiting.complete();
    }
    _waiting.clear();
  }

  /// The app moves between the foreground and the background.
  void lifecycleChanged(AppLifecycleState lifecycle) {
    _lifecycle = lifecycle;
    if (!state.ready || !_enabled) return;
    switch (lifecycle) {
      case AppLifecycleState.inactive:
        // The phone's own prompt makes the app inactive too, and must not hide what it asks for.
        if (!_asking && !state.covered) state = _with(covered: true);
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        // The PIN screen of the phone is another app, and leaving for it does not count.
        if (_asking) return;
        _leftAt ??= ref.read(lockClockProvider)();
        if (!state.covered) state = _with(covered: true);
      case AppLifecycleState.resumed:
        final left = _leftAt;
        _leftAt = null;
        final locked =
            state.locked ||
            locksOnReturn(
              enabled: true,
              after: ref.read(settingsProvider).appLockAfter,
              leftAt: left,
              now: ref.read(lockClockProvider)(),
            );
        state = AppLockState(ready: true, locked: locked);
        // Only a real return asks again, so a cancelled prompt does not come back by itself.
        if (locked && left != null) _appeared();
        _promptIfWaiting();
      case AppLifecycleState.detached:
        break;
    }
  }

  AppLockState _with({bool? locked, bool? covered}) => AppLockState(
    ready: state.ready,
    locked: locked ?? state.locked,
    covered: covered ?? state.covered,
  );

  /// The lock screen has just appeared, so the prompt starts by itself, once.
  void _appeared() {
    FocusManager.instance.primaryFocus?.unfocus();
    _promptWaiting = true;
    _promptIfWaiting();
  }

  void _promptIfWaiting() {
    final lifecycle = _lifecycle ?? WidgetsBinding.instance.lifecycleState;
    final visible = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    if (!_promptWaiting || !state.locked || !visible || _asking) return;
    _promptWaiting = false;
    // After the frame, so the lock screen is there behind the prompt.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.mounted) unawaited(unlock());
    });
  }

  /// Asks for the phone's lock and opens the app once it is passed.
  Future<bool> unlock() async {
    if (!state.locked) return true;
    final passed = await confirm(l.appLockReasonOpen);
    if (passed && ref.mounted) {
      state = const AppLockState(ready: true);
      _release();
    }
    return passed;
  }

  /// Asks for the phone's lock without changing what is shown, as turning the lock on or off does.
  Future<bool> confirm(String reason) async {
    if (_asking) return false;
    _asking = true;
    try {
      return await ref.read(authenticatorProvider).authenticate(reason);
    } finally {
      _asking = false;
    }
  }

  /// Android takes its own picture of the app for the list of recent apps; this asks it not to.
  /// Screenshots stay allowed.
  Future<void> _hideFromRecents(bool hidden) async {
    try {
      await _channel.invokeMethod<void>('recents', {'hidden': hidden});
    } on MissingPluginException {
      // iOS is covered by the lock screen alone.
    } on PlatformException {
      // An older Android, which has no such switch.
    }
  }
}
