import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../../services/session.dart';
import '../../theme.dart';
import 'admin_common.dart';

/// Where the server sends messages from: password resets, quiet phones, shared albums.
class EmailSettingsScreen extends ConsumerStatefulWidget {
  const EmailSettingsScreen({super.key});

  @override
  ConsumerState<EmailSettingsScreen> createState() =>
      _EmailSettingsScreenState();
}

class _EmailSettingsScreenState extends ConsumerState<EmailSettingsScreen> {
  late final Session _session = ref.read(sessionProvider).value!;
  EmailSettings? _settings;
  String? _error;
  String? _problem;
  bool _busy = false;
  final _host = TextEditingController();
  final _port = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _from = TextEditingController();
  final _publicUrl = TextEditingController();
  bool _enabled = false;
  EmailSettingsUpdateSecurityEnum _security =
      EmailSettingsUpdateSecurityEnum.starttls;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final field in [
      _host,
      _port,
      _username,
      _password,
      _from,
      _publicUrl,
    ]) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final settings = await _session.api.getEmailSettings();
      if (!mounted || settings == null) return;
      setState(() {
        _settings = settings;
        _enabled = settings.enabled;
        _host.text = settings.host;
        _port.text = '${settings.port}';
        _username.text = settings.username;
        _from.text = settings.from;
        _publicUrl.text = settings.publicUrl;
        _security =
            EmailSettingsUpdateSecurityEnum.fromJson(settings.security.value) ??
            EmailSettingsUpdateSecurityEnum.starttls;
      });
    } on ApiException catch (cause) {
      if (mounted) setState(() => _error = apiProblem(cause));
    }
  }

  Future<void> _save() async {
    final port = int.tryParse(_port.text.trim());
    if (port == null) {
      setState(() => _problem = 'The port must be a number.');
      return;
    }
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      final saved = await _session.api.setEmailSettings(
        EmailSettingsUpdate(
          enabled: _enabled,
          host: _host.text.trim(),
          port: port,
          username: _username.text.trim(),
          // Left out keeps the password that is saved.
          password: _password.text.isEmpty ? null : _password.text,
          from: _from.text.trim(),
          security: _security,
          publicUrl: _publicUrl.text.trim(),
        ),
      );
      if (!mounted) return;
      setState(() {
        _settings = saved ?? _settings;
        _password.clear();
      });
      tellAdmin(context, 'Email settings are saved.');
    } on ApiException catch (cause) {
      if (mounted) setState(() => _problem = apiProblem(cause));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _test() async {
    setState(() => _busy = true);
    try {
      await _session.api.sendTestEmail();
      if (mounted) tellAdmin(context, 'A test message was sent to you.');
    } on ApiException catch (cause) {
      if (mounted) setState(() => _problem = apiProblem(cause));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _text(
    TextEditingController field,
    String label, {
    String? help,
    bool secret = false,
    TextInputType? type,
  }) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
    child: TextField(
      controller: field,
      obscureText: secret,
      keyboardType: type,
      autocorrect: false,
      decoration: InputDecoration(labelText: label, helperText: help),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Email')),
      body: AdminBody(
        loading: settings == null,
        error: _error,
        child: () => ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            if (_problem != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(_problem!, style: TextStyle(color: Palette.err)),
              ),
            SwitchListTile(
              title: const Text('Send email'),
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
            ),
            _text(_host, 'SMTP server'),
            _text(_port, 'Port', type: TextInputType.number),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: DropdownButtonFormField<EmailSettingsUpdateSecurityEnum>(
                initialValue: _security,
                decoration: const InputDecoration(labelText: 'Encryption'),
                items: const [
                  DropdownMenuItem(
                    value: EmailSettingsUpdateSecurityEnum.starttls,
                    child: Text('STARTTLS'),
                  ),
                  DropdownMenuItem(
                    value: EmailSettingsUpdateSecurityEnum.tls,
                    child: Text('TLS'),
                  ),
                  DropdownMenuItem(
                    value: EmailSettingsUpdateSecurityEnum.none,
                    child: Text('None'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _security = value ?? _security),
              ),
            ),
            _text(_username, 'User name'),
            _text(
              _password,
              'Password',
              secret: true,
              help: settings!.hasPassword
                  ? 'A password is saved. Empty keeps it.'
                  : null,
            ),
            _text(_from, 'From', type: TextInputType.emailAddress),
            _text(
              _publicUrl,
              'Address of this server',
              help: 'For links in messages',
              type: TextInputType.url,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  GoldButton(
                    label: 'Save',
                    busy: _busy,
                    onPressed: _busy ? null : _save,
                  ),
                  OutlinedButton(
                    onPressed: _busy || !settings.enabled ? null : _test,
                    child: const Text('Send a test message'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
