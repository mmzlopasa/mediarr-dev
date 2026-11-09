import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../brand.dart';
import '../l10n/l10n.dart';
import '../services/session.dart';
import '../theme.dart';
import 'qr_sign_in.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _server = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  bool _needsCode = false;
  bool _busy = false;
  bool _waiting = false;
  bool _cancelWait = false;
  String? _error;
  StreamSubscription<Uri>? _links;

  @override
  void initState() {
    super.initState();
    ref.read(sessionProvider.notifier).lastServer().then((value) {
      if (value != null && mounted) _server.text = value;
    });
    _listenForLinks();
  }

  /// A sign-in code scanned with the phone's own camera opens the app here, and signs in.
  void _listenForLinks() {
    try {
      final links = AppLinks();
      _links = links.uriLinkStream.listen(_fromLink, onError: (Object _) {});
    } on Object {
      // Without the platform's links, the code is scanned in the app.
    }
  }

  void _fromLink(Uri uri) {
    final link = parseSignInLink(uri.toString());
    if (link != null && mounted && !_waiting) _signInWith(link);
  }

  @override
  void dispose() {
    _links?.cancel();
    _server.dispose();
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(sessionProvider.notifier)
          .signIn(
            server: _server.text,
            email: _email.text,
            password: _password.text,
            code: _needsCode ? _code.text.replaceAll(' ', '') : null,
          );
    } on LoginFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        if (failure.totpRequired && !_needsCode) {
          _needsCode = true;
        } else {
          _error = failure.message;
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _singleSignOn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(sessionProvider.notifier).signInWithProvider(_server.text);
    } on LoginFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Hands the code to the server, then waits for the signed-in screen to allow this phone.
  Future<void> _signInWith(SignInLink link) async {
    _server.text = link.server;
    setState(() {
      _waiting = true;
      _cancelWait = false;
      _error = null;
    });
    try {
      await ref
          .read(sessionProvider.notifier)
          .signInWithCode(
            server: link.server,
            code: link.code,
            device: await thisDeviceName(),
            cancelled: () => _cancelWait || !mounted,
          );
    } on LoginFailure catch (failure) {
      if (mounted && !_cancelWait) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _waiting = false);
    }
  }

  Future<void> _scan() async {
    final link = await Navigator.push<SignInLink>(
      context,
      MaterialPageRoute(builder: (_) => const SignInScanner()),
    );
    if (link != null && mounted) await _signInWith(link);
  }

  Future<void> _typeCode() async {
    if (_server.text.trim().isEmpty) {
      setState(() => _error = l.loginScreenEnterServerFirst);
      return;
    }
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const _CodeDialog(),
    );
    if (code != null && code.trim().isNotEmpty && mounted) {
      await _signInWith(SignInLink(_server.text, code));
    }
  }

  Widget _waitingPanel(TextTheme text) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Center(child: BrandLogo(size: 30)),
      const SizedBox(height: 28),
      const Center(child: CircularProgressIndicator()),
      const SizedBox(height: 20),
      Text(
        l.loginScreenAllowOnCodeScreen,
        key: const ValueKey('qr-waiting'),
        textAlign: TextAlign.center,
        style: text.bodyMedium,
      ),
      const SizedBox(height: 12),
      TextButton(
        onPressed: () => setState(() {
          _cancelWait = true;
          _waiting = false;
        }),
        child: Text(l.loginScreenCancel),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _waiting
                  ? _waitingPanel(text)
                  : AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: BrandLogo(size: 30)),
                          const SizedBox(height: 12),
                          Text(
                            _needsCode
                                ? l.loginScreenEnterTotp
                                : l.loginScreenSignInToServer,
                            textAlign: TextAlign.center,
                            style: text.bodyMedium,
                          ),
                          const SizedBox(height: 28),
                          if (_error != null) ...[
                            Text(
                              _error!,
                              style: text.bodyMedium?.copyWith(
                                color: Palette.err,
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          if (_needsCode)
                            TextField(
                              controller: _code,
                              keyboardType: TextInputType.number,
                              autofillHints: const [AutofillHints.oneTimeCode],
                              decoration: InputDecoration(
                                labelText: l.loginScreenCode,
                              ),
                            )
                          else ...[
                            TextField(
                              controller: _server,
                              keyboardType: TextInputType.url,
                              autocorrect: false,
                              decoration: InputDecoration(
                                labelText: l.loginScreenServerAddress,
                                hintText: '192.168.1.10:9851',
                              ),
                            ),
                            FoundServers(
                              onPick: (url) =>
                                  setState(() => _server.text = url),
                            ),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              autofillHints: const [AutofillHints.username],
                              decoration: InputDecoration(
                                labelText: l.loginScreenEmail,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _password,
                              obscureText: true,
                              autofillHints: const [AutofillHints.password],
                              decoration: InputDecoration(
                                labelText: l.loginScreenPassword,
                              ),
                              onSubmitted: (_) => _submit(),
                            ),
                          ],
                          const SizedBox(height: 20),
                          GoldButton(
                            label: _needsCode
                                ? l.loginScreenVerify
                                : l.loginScreenSignIn,
                            busy: _busy,
                            onPressed: _submit,
                          ),
                          if (!_needsCode) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _busy ? null : _singleSignOn,
                              child: Text(l.loginScreenSingleSignOn),
                            ),
                            const Divider(height: 28),
                            OutlinedButton.icon(
                              onPressed: _busy ? null : _scan,
                              icon: const Icon(Icons.qr_code_scanner),
                              label: Text(l.loginScreenScanQr),
                            ),
                            TextButton(
                              onPressed: _busy ? null : _typeCode,
                              child: Text(l.loginScreenEnterSignInCode),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks for the code shown on a signed-in screen. It owns its field, so closing it is safe.
class _CodeDialog extends StatefulWidget {
  const _CodeDialog();

  @override
  State<_CodeDialog> createState() => _CodeDialogState();
}

class _CodeDialogState extends State<_CodeDialog> {
  final _field = TextEditingController();

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(l.loginScreenSignInCode),
    content: TextField(
      controller: _field,
      autofocus: true,
      autocorrect: false,
      textCapitalization: TextCapitalization.characters,
      decoration: InputDecoration(
        labelText: l.loginScreenCode,
        hintText: 'K7QM-2XPA',
      ),
      onSubmitted: (value) => Navigator.pop(context, value),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(l.loginScreenCancel),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, _field.text),
        child: Text(l.loginScreenSignIn),
      ),
    ],
  );
}
