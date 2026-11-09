import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../brand.dart';
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

  @override
  void initState() {
    super.initState();
    ref.read(sessionProvider.notifier).lastServer().then((value) {
      if (value != null && mounted) _server.text = value;
    });
  }

  @override
  void dispose() {
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
      setState(() => _error = 'Enter the address of your server first.');
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
        'Allow this sign-in on the screen that shows the code.',
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
        child: const Text('Cancel'),
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
                                ? 'Enter the 6-digit code from your authenticator app.'
                                : 'Sign in to your Mediarr server.',
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
                              decoration: const InputDecoration(
                                labelText: 'Code',
                              ),
                            )
                          else ...[
                            TextField(
                              controller: _server,
                              keyboardType: TextInputType.url,
                              autocorrect: false,
                              decoration: const InputDecoration(
                                labelText: 'Server address',
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
                              decoration: const InputDecoration(
                                labelText: 'Email',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _password,
                              obscureText: true,
                              autofillHints: const [AutofillHints.password],
                              decoration: const InputDecoration(
                                labelText: 'Password',
                              ),
                              onSubmitted: (_) => _submit(),
                            ),
                          ],
                          const SizedBox(height: 20),
                          GoldButton(
                            label: _needsCode ? 'Verify' : 'Sign in',
                            busy: _busy,
                            onPressed: _submit,
                          ),
                          if (!_needsCode) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _busy ? null : _singleSignOn,
                              child: const Text('Use single sign-on'),
                            ),
                            const Divider(height: 28),
                            OutlinedButton.icon(
                              onPressed: _busy ? null : _scan,
                              icon: const Icon(Icons.qr_code_scanner),
                              label: const Text('Scan QR code'),
                            ),
                            TextButton(
                              onPressed: _busy ? null : _typeCode,
                              child: const Text('Enter a sign-in code'),
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
    title: const Text('Sign-in code'),
    content: TextField(
      controller: _field,
      autofocus: true,
      autocorrect: false,
      textCapitalization: TextCapitalization.characters,
      decoration: const InputDecoration(
        labelText: 'Code',
        hintText: 'K7QM-2XPA',
      ),
      onSubmitted: (value) => Navigator.pop(context, value),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, _field.text),
        child: const Text('Sign in'),
      ),
    ],
  );
}
