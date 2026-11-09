import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../l10n/l10n.dart';
import '../services/backup.dart';
import '../services/discovery.dart';
import '../services/session.dart';
import '../theme.dart';

/// What this phone is called where a signed-in screen asks whether to allow it.
Future<String> thisDeviceName() async {
  try {
    final name = (await BackupService().status()).deviceName.trim();
    if (name.isNotEmpty) return name;
  } on Object {
    // The native side may not be ready; the kind of phone is enough.
  }
  return Platform.isIOS ? 'iPhone' : 'Android';
}

/// The camera, until it sees a Mediarr sign-in code.
class SignInScanner extends StatefulWidget {
  const SignInScanner({super.key});

  @override
  State<SignInScanner> createState() => _SignInScannerState();
}

class _SignInScannerState extends State<SignInScanner> {
  bool _done = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(l.qrSignInScanTitle)),
    body: Stack(
      children: [
        MobileScanner(
          onDetect: (capture) {
            if (_done) return;
            for (final barcode in capture.barcodes) {
              final link = parseSignInLink(barcode.rawValue ?? '');
              if (link != null) {
                _done = true;
                Navigator.pop(context, link);
                return;
              }
            }
          },
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 40,
          child: Text(
            l.qrSignInScanHelp,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
      ],
    ),
  );
}

/// Mediarr servers found on this Wi-Fi, as they answer. A tap fills in the address.
class FoundServers extends StatefulWidget {
  const FoundServers({required this.onPick, super.key});

  final void Function(String url) onPick;

  @override
  State<FoundServers> createState() => _FoundServersState();
}

class _FoundServersState extends State<FoundServers> {
  final _found = <FoundServer>[];
  StreamSubscription<FoundServer>? _search;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _search?.cancel();
    setState(() {
      _found.clear();
      _searching = true;
    });
    _search = discoverServers().listen(
      (server) => setState(() => _found.add(server)),
      onDone: () {
        if (mounted) setState(() => _searching = false);
      },
    );
  }

  @override
  void dispose() {
    _search?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _searching
                    ? l.qrSignInLooking
                    : _found.isEmpty
                    ? l.qrSignInNoneFound
                    : l.qrSignInOnThisNetwork,
                style: text.bodySmall,
              ),
            ),
            if (_searching)
              const SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              TextButton(onPressed: _start, child: Text(l.qrSignInLookAgain)),
          ],
        ),
        for (final server in _found)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.dns_outlined),
            title: Text(
              server.name == 'Mediarr'
                  ? Uri.parse(server.url).authority
                  : '${server.name} · ${Uri.parse(server.url).authority}',
            ),
            subtitle: Text('Mediarr ${server.version}'),
            onTap: () => widget.onPick(server.url),
          ),
      ],
    );
  }
}

/// Shows a code that another device scans to sign in to this account, and asks before it does.
class ShowSignInCodeScreen extends ConsumerStatefulWidget {
  const ShowSignInCodeScreen({super.key});

  @override
  ConsumerState<ShowSignInCodeScreen> createState() =>
      _ShowSignInCodeScreenState();
}

class _ShowSignInCodeScreenState extends ConsumerState<ShowSignInCodeScreen> {
  QRSignIn? _code;
  QRSignInState? _state;
  String? _error;
  Timer? _timer;
  bool _answering = false;
  DateTime _now = DateTime.now();

  DefaultApi get _api => ref.read(sessionProvider).value!.api;

  @override
  void initState() {
    super.initState();
    _fresh();
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _status {
    final state = _state?.status.value;
    if (state != null) return state;
    final code = _code;
    if (code != null && code.expiresAt.isBefore(_now)) return 'expired';
    return 'waiting';
  }

  Future<void> _fresh() async {
    setState(() {
      _code = null;
      _state = null;
      _error = null;
    });
    try {
      final code = await _api.createQRSignIn();
      if (mounted) setState(() => _code = code);
    } on ApiException catch (cause) {
      if (mounted) {
        setState(() => _error = cause.message ?? l.qrSignInMakeCodeFailed);
      }
    }
  }

  Future<void> _tick() async {
    if (!mounted) return;
    setState(() => _now = DateTime.now());
    final code = _code;
    if (code == null || _status != 'waiting') return;
    try {
      final state = await _api.getQRSignIn(code.id);
      if (mounted) setState(() => _state = state);
    } on ApiException {
      // Asked again on the next tick.
    }
  }

  Future<void> _answer(bool allow) async {
    final code = _code;
    if (code == null) return;
    setState(() => _answering = true);
    try {
      await _api.answerQRSignIn(code.id, QRAnswer(allow: allow));
      final state = await _api.getQRSignIn(code.id);
      if (mounted) setState(() => _state = state);
    } on ApiException catch (cause) {
      if (mounted) setState(() => _error = cause.message);
    } finally {
      if (mounted) setState(() => _answering = false);
    }
  }

  String _left(DateTime expires) {
    final seconds = expires.difference(_now).inSeconds.clamp(0, 3600);
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final code = _code;
    final device = _state?.device ?? l.qrSignInTheDevice;
    return Scaffold(
      appBar: AppBar(title: Text(l.qrSignInTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_error != null) ...[
            Text(_error!, style: text.bodyMedium?.copyWith(color: Palette.err)),
            const SizedBox(height: 16),
          ],
          if (code == null && _error == null)
            const Center(child: CircularProgressIndicator())
          else if (code != null && _status == 'waiting') ...[
            Text(
              l.qrSignInHowTo,
              textAlign: TextAlign.center,
              style: text.bodyMedium,
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: QrImageView(
                  data: code.link,
                  size: 220,
                  semanticsLabel: l.qrSignInQrLabel,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l.qrSignInOrType,
              textAlign: TextAlign.center,
              style: text.bodySmall,
            ),
            SelectableText(
              code.code,
              key: const ValueKey('qr-code'),
              textAlign: TextAlign.center,
              style: text.headlineSmall?.copyWith(
                letterSpacing: 3,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              l.qrSignInValidFor(_left(code.expiresAt)),
              textAlign: TextAlign.center,
              style: text.bodySmall,
            ),
          ] else if (_status == 'requested') ...[
            Text(
              l.qrSignInAllowOn(device),
              textAlign: TextAlign.center,
              style: text.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l.qrSignInAllowOnlyIf,
              textAlign: TextAlign.center,
              style: text.bodyMedium,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: _answering ? null : () => _answer(false),
                  child: Text(l.qrSignInDeny),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _answering ? null : () => _answer(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Palette.buttonGold,
                    foregroundColor: Palette.onGold,
                  ),
                  child: Text(l.qrSignInAllow),
                ),
              ],
            ),
          ] else if (_status == 'allowed' || _status == 'used') ...[
            Text(
              l.qrSignInSignedIn(device),
              textAlign: TextAlign.center,
              style: text.bodyMedium,
            ),
            const SizedBox(height: 16),
            Center(
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l.qrSignInDone),
              ),
            ),
          ] else ...[
            Text(
              _status == 'denied' ? l.qrSignInDenied : l.qrSignInExpired,
              textAlign: TextAlign.center,
              style: text.bodyMedium,
            ),
            const SizedBox(height: 16),
            Center(
              child: FilledButton(
                onPressed: _fresh,
                child: Text(l.qrSignInNewCode),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
