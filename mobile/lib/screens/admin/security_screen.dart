import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../../services/session.dart';
import '../../theme.dart';
import 'admin_common.dart';
import '../../l10n/l10n.dart';

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
    l.adminSecurityRulesSaved,
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
    l.adminSecuritySsoSaved,
  );

  Future<void> _forget(SecurityDevice device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.adminSecurityForgetTitle),
        content: Text(l.adminSecurityApproveAgain(device.email)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.adminSecurityCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l.adminSecurityForget,
              style: TextStyle(color: Palette.err),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(
        () => _session.api.deleteDevice(device.id),
        l.adminSecurityDeviceForgotten,
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
      appBar: AppBar(title: Text(l.adminSecurityTitle)),
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
            AdminHeading(l.adminSecuritySingleSignOn),
            _text(
              _issuer,
              l.adminSecurityIssuer,
              help: l.adminSecurityIssuerHelp,
            ),
            _text(_clientId, l.adminSecurityClientId),
            _text(
              _secret,
              l.adminSecurityClientSecret,
              secret: true,
              help: oidc!.hasSecret ? l.adminSecuritySecretSaved : null,
            ),
            _text(_label, l.adminSecurityButtonLabel),
            SwitchListTile(
              title: Text(l.adminSecurityAutoCreate),
              value: _autoCreate,
              onChanged: (value) => setState(() => _autoCreate = value),
            ),
            SwitchListTile(
              title: Text(l.adminSecurityLinkAdmins),
              value: _linkAdmins,
              onChanged: (value) => setState(() => _linkAdmins = value),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: _busy ? null : _saveOidc,
                  child: Text(l.adminSecuritySaveSso),
                ),
              ),
            ),
            AdminHeading(l.adminSecurityRules),
            SwitchListTile(
              title: Text(l.adminSecurityApprovalRequired),
              value: _approval,
              onChanged: (value) => setState(() => _approval = value),
            ),
            SwitchListTile(
              title: Text(l.adminSecurityAllowlist),
              subtitle: Text(l.adminSecurityYourAddress(rules!.yourAddress)),
              value: _allowlist,
              onChanged: (value) => setState(() => _allowlist = value),
            ),
            _text(
              _addresses,
              l.adminSecurityAddresses,
              help: l.adminSecurityAddressesHelp,
              lines: 4,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: _busy ? null : _saveRules,
                  child: Text(l.adminSecuritySaveRules),
                ),
              ),
            ),
            AdminHeading(l.adminSecurityDevices),
            if (rules.devices.isEmpty)
              ListTile(title: Text(l.adminSecurityNoDevices)),
            for (final device in rules.devices)
              ListTile(
                isThreeLine: true,
                title: Text(device.email),
                subtitle: Text(
                  '${device.userAgent}\n${device.ip} · ${l.adminSecurityLastSeen(adminTime(device.lastSeen))}',
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
                                l.adminSecurityDeviceApproved,
                              ),
                        child: Text(l.adminSecurityApprove),
                      ),
                    IconButton(
                      tooltip: l.adminSecurityForget,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: _busy ? null : () => _forget(device),
                    ),
                  ],
                ),
              ),
            ListTile(
              leading: const Icon(Icons.manage_search),
              title: Text(l.adminSecurityAttempts),
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
    SecurityEventKindEnum.loginOk => l.adminSecuritySignedIn,
    SecurityEventKindEnum.loginFailed => l.adminSecurityWrongSignIn,
    SecurityEventKindEnum.loginLocked => l.adminSecurityTooManyAttempts,
    SecurityEventKindEnum.ipBlocked => l.adminSecurityAddressBlocked,
    SecurityEventKindEnum.deviceBlocked => l.adminSecurityDeviceNotApproved,
    SecurityEventKindEnum.passwordReset => l.adminSecurityPasswordReset,
    _ => kind.value,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(l.adminSecurityAttempts)),
    body: AdminBody(
      loading: _events == null,
      error: _error,
      child: () => RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            if (_events!.isEmpty)
              ListTile(title: Text(l.adminSecurityNoAttempts)),
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
                  child: Text(l.adminSecurityShowOlder),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
