import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../brand.dart';
import '../l10n/l10n.dart';
import '../services/app_lock.dart';
import '../theme.dart';

/// Sits above the app's navigator. While the app is locked, or on its way to the background with
/// the lock on, the app is not painted at all: only the logo is, so neither someone holding the
/// phone nor the list of recent apps sees a photo. What runs keeps running behind it.
class LockGate extends ConsumerStatefulWidget {
  const LockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      ref.read(appLockProvider.notifier).lifecycleChanged(state);

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(appLockProvider);
    final hidden = lock.hidesApp;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Offstage paints nothing and takes no taps, but keeps every screen as it was.
        Offstage(offstage: hidden, child: widget.child),
        if (hidden) LockScreen(canUnlock: lock.ready && lock.locked),
      ],
    );
  }
}

/// The logo, and the button that asks for the phone's lock.
class LockScreen extends ConsumerWidget {
  const LockScreen({super.key, required this.canUnlock});

  /// Shown only while locked: the cover on the way to the background has nothing to unlock.
  final bool canUnlock;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Material(
    color: Palette.bg,
    child: SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandLogo(size: 30),
            const SizedBox(height: 36),
            // Keeps its place, so the logo does not move when the button comes.
            Visibility(
              visible: canUnlock,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: FilledButton.icon(
                onPressed: canUnlock
                    ? () => ref.read(appLockProvider.notifier).unlock()
                    : null,
                icon: const Icon(Icons.lock_open),
                label: Text(l.appLockUnlock),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
