import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../../services/session.dart';
import '../../theme.dart';
import 'admin_common.dart';

/// Addresses one per line or separated by commas, without empty ones.
List<String> parseAddresses(String text) => [
  for (final part in text.split(RegExp(r'[\s,]+')))
    if (part.trim().isNotEmpty) part.trim(),
];

/// Who may reach the server: single sign-on, approved devices, allowed addresses, and attempts.
class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  late final Session _session = ref.read(sessionProvider).value!;
  SecuritySettings? _rules;
  OIDCSettings? _oidc;
  String? _error;
  String? _problem;
  bool _busy = false;
  final _addresses = TextEditingController();
  final _issuer = TextEditingController();
  final _clientId = TextEditingController();
  final _label = TextEditingController();
  final _secret = TextEditingController();
  bool _allowlist = false;
  bool _approval = false;
  bool _autoCreate = false;
  bool _linkAdmins = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final field in [_addresses, _issuer, _clientId, _label, _secret]) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final rules = await _session.api.getSecurity();
      final oidc = await _session.api.getOIDCSettings();
      if (!mounted || rules == null || oidc == null) return;
      setState(() {
        _rules = rules;
        _oidc = oidc;
        _error = null;
        _allowlist = rules.ipAllowlistEnabled;
        _approval = rules.deviceApprovalEnabled;
        _addresses.text = rules.ipAllowlist.join('\n');
        _issuer.text = oidc.issuer;
        _clientId.text = oidc.clientId;
        _label.text = oidc.label;
        _autoCreate = oidc.autoCreate;
        _linkAdmins = oidc.linkAdmins;
      });
    } on ApiException catch (cause) {
      if (mounted) setState(() => _error = apiProblem(cause));
    }
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      await action();
      if (mounted) tellAdmin(context, done);
      await _load();
    } on ApiException catch (cause) {
      if (mounted) setState(() => _problem = apiProblem(cause));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveRules() => _run(
    () => _session.api.setSecurity(
      SecurityUpdate(
        ipAllowlistEnabled: _allowlist,
        ipAllowlist: parseAddresses(_addresses.text),
        deviceApprovalEnabled: _approval,
      ),
    ),
    'The rules are saved.',
  );

  Future<void> _saveOidc() => _run(
    () => _session.api.setOIDCSettings(
      OIDCSettingsUpdate(
        issuer: _issuer.text.trim(),
        clientId: _clientId.text.trim(),
        label: _label.text.trim(),
        autoCreate: _autoCreate,
        linkAdmins: _linkAdmins,
        secret: _secret.text.isEmpty ? null : _secret.text,
      ),
    ),
    'Single sign-on is saved.',
  );

  Future<void> _forget(SecurityDevice device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forget this device?'),
        content: Text('${device.email} on it has to be approved again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Forget', style: TextStyle(color: Palette.err)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(
        () => _session.api.deleteDevice(device.id),
        'The device is forgotten.',
      );
    }
  }

  Widget _text(
    TextEditingController field,
    String label, {
    String? help,
    bool secret = false,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
    child: TextField(
      controller: field,
      obscureText: secret,
      maxLines: secret ? 1 : lines,
      autocorrect: false,
      decoration: InputDecoration(labelText: label, helperText: help),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final rules = _rules;
    final oidc = _oidc;
    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: AdminBody(
        loading: rules == null || oidc == null,
        error: _error,
        child: () => ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            if (_problem != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(_problem!, style: TextStyle(color: Palette.err)),
              ),
            const AdminHeading('Single sign-on'),
            _text(_issuer, 'Issuer', help: 'Empty turns single sign-on off'),
            _text(_clientId, 'Client ID'),
            _text(
              _secret,
              'Client secret',
              secret: true,
              help: oidc!.hasSecret
                  ? 'A secret is saved. Empty keeps it.'
                  : null,
            ),
            _text(_label, 'Button label'),
            SwitchListTile(
              title: const Text('Create an account on first sign-in'),
              value: _autoCreate,
              onChanged: (value) => setState(() => _autoCreate = value),
            ),
            SwitchListTile(
              title: const Text('Administrators may sign in this way'),
              value: _linkAdmins,
              onChanged: (value) => setState(() => _linkAdmins = value),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: _busy ? null : _saveOidc,
                  child: const Text('Save single sign-on'),
                ),
              ),
            ),
            const AdminHeading('Rules'),
            SwitchListTile(
              title: const Text('New devices must be approved'),
              value: _approval,
              onChanged: (value) => setState(() => _approval = value),
            ),
            SwitchListTile(
              title: const Text('Only these addresses may reach the server'),
              subtitle: Text('Your address now: ${rules!.yourAddress}'),
              value: _allowlist,
              onChanged: (value) => setState(() => _allowlist = value),
            ),
            _text(
              _addresses,
              'Addresses and networks',
              help: 'One per line, such as 192.168.1.0/24',
              lines: 4,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: _busy ? null : _saveRules,
                  child: const Text('Save the rules'),
                ),
              ),
            ),
            const AdminHeading('Devices'),
            if (rules.devices.isEmpty)
              const ListTile(
                title: Text('No device has tried to sign in yet.'),
              ),
            for (final device in rules.devices)
              ListTile(
                isThreeLine: true,
                title: Text(device.email),
                subtitle: Text(
                  '${device.userAgent}\n${device.ip} · last ${adminTime(device.lastSeen)}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    if (!device.approved)
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => _run(
                                () => _session.api.approveDevice(device.id),
                                'The device may sign in.',
                              ),
                        child: const Text('Approve'),
                      ),
                    IconButton(
                      tooltip: 'Forget',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: _busy ? null : () => _forget(device),
                    ),
                  ],
                ),
              ),
            ListTile(
              leading: const Icon(Icons.manage_search),
              title: const Text('Attempts to get in'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SecurityEventsScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sign-ins that worked and failed, blocked addresses and devices, newest first.
class SecurityEventsScreen extends ConsumerStatefulWidget {
  const SecurityEventsScreen({super.key});

  @override
  ConsumerState<SecurityEventsScreen> createState() =>
      _SecurityEventsScreenState();
}

class _SecurityEventsScreenState extends ConsumerState<SecurityEventsScreen> {
  late final Session _session = ref.read(sessionProvider).value!;
  List<SecurityEvent>? _events;
  bool _ended = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    try {
      final before = more && (_events?.isNotEmpty ?? false)
          ? _events!.last.id
          : null;
      final page =
          await _session.api.listSecurityEvents(before: before) ?? const [];
      if (!mounted) return;
      setState(() {
        _events = more ? [...?_events, ...page] : page;
        _ended = page.isEmpty;
        _error = null;
      });
    } on ApiException catch (cause) {
      if (mounted) setState(() => _error = apiProblem(cause));
    }
  }

  static String _kind(SecurityEventKindEnum kind) => switch (kind) {
    SecurityEventKindEnum.loginOk => 'Signed in',
    SecurityEventKindEnum.loginFailed => 'Wrong sign-in',
    SecurityEventKindEnum.loginLocked => 'Too many attempts',
    SecurityEventKindEnum.ipBlocked => 'Address blocked',
    SecurityEventKindEnum.deviceBlocked => 'Device not approved',
    SecurityEventKindEnum.passwordReset => 'Password reset',
    _ => kind.value,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Attempts to get in')),
    body: AdminBody(
      loading: _events == null,
      error: _error,
      child: () => RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            if (_events!.isEmpty)
              const ListTile(title: Text('No attempts yet.')),
            for (final event in _events!)
              ListTile(
                dense: true,
                title: Text(
                  '${_kind(event.kind)}${event.email.isEmpty ? '' : ' · ${event.email}'}',
                ),
                subtitle: Text(
                  [
                    adminTime(event.at),
                    event.ip,
                    if (event.detail.isNotEmpty) event.detail,
                    event.userAgent,
                  ].join(' · '),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (_events!.isNotEmpty && !_ended)
              Center(
                child: TextButton(
                  onPressed: () => _load(more: true),
                  child: const Text('Show older'),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
