import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../../services/session.dart';
import '../../theme.dart';
import 'admin_common.dart';

/// A quota typed in gigabytes; empty means no limit. Null when it is not a number.
({bool ok, int? bytes}) parseQuotaGb(String text) {
  final trimmed = text.trim().replaceAll(',', '.');
  if (trimmed.isEmpty) return (ok: true, bytes: null);
  final value = double.tryParse(trimmed);
  if (value == null || value <= 0) return (ok: false, bytes: null);
  return (ok: true, bytes: (value * 1024 * 1024 * 1024).round());
}

/// Every user, how much each stores and may store, and adding new ones.
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  late final Session _session = ref.read(sessionProvider).value!;
  List<User>? _users;
  Map<String, UserStorage> _storage = const {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final users = await _session.api.listUsers() ?? const [];
      final storage = await _session.api.getAdminStorage() ?? const [];
      if (mounted) {
        setState(() {
          _users = users;
          _storage = {for (final row in storage) row.id: row};
          _error = null;
        });
      }
    } on ApiException catch (cause) {
      if (mounted) setState(() => _error = apiProblem(cause));
    }
  }

  Future<void> _create() async {
    final created = await showDialog<User>(
      context: context,
      builder: (_) => _NewUserDialog(session: _session),
    );
    if (created != null) {
      if (mounted) tellAdmin(context, '${created.email} was added.');
      await _load();
    }
  }

  Future<void> _quota(User user) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _QuotaDialog(
        session: _session,
        user: user,
        current: _storage[user.id]?.quotaBytes,
      ),
    );
    if (changed == true) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Users')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _create,
      icon: const Icon(Icons.person_add_alt),
      label: const Text('Add a user'),
    ),
    body: AdminBody(
      loading: _users == null,
      error: _error,
      child: () => RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 88),
          children: [
            for (final user in _users!)
              ListTile(
                leading: CircleAvatar(
                  child: Text(
                    user.name.isEmpty ? '?' : user.name.characters.first,
                  ),
                ),
                title: Text(user.name.isEmpty ? user.email : user.name),
                subtitle: Text(
                  [
                    user.email,
                    if (user.isAdmin) 'Administrator',
                    if (_storage[user.id] case final row?)
                      '${adminBytes(row.storedBytes)} of '
                          '${row.quotaBytes == null ? 'no limit' : adminBytes(row.quotaBytes!)}',
                  ].join(' · '),
                ),
                trailing: IconButton(
                  tooltip: 'How much ${user.email} may store',
                  icon: const Icon(Icons.data_usage),
                  onPressed: () => _quota(user),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _NewUserDialog extends StatefulWidget {
  const _NewUserDialog({required this.session});

  final Session session;

  @override
  State<_NewUserDialog> createState() => _NewUserDialogState();
}

class _NewUserDialogState extends State<_NewUserDialog> {
  final _email = TextEditingController();
  final _name = TextEditingController();
  final _password = TextEditingController();
  bool _admin = false;
  bool _busy = false;
  String? _problem;

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      final user = await widget.session.api.createUser(
        CreateUserRequest(
          email: _email.text.trim(),
          name: _name.text.trim(),
          password: _password.text,
          isAdmin: _admin,
        ),
      );
      if (mounted) Navigator.pop(context, user);
    } on ApiException catch (cause) {
      if (mounted) setState(() => _problem = apiProblem(cause));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add a user'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_problem != null)
            Text(_problem!, style: TextStyle(color: Palette.err)),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Administrator'),
            value: _admin,
            onChanged: (value) => setState(() => _admin = value),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      TextButton(onPressed: _busy ? null : _save, child: const Text('Add')),
    ],
  );
}

class _QuotaDialog extends StatefulWidget {
  const _QuotaDialog({
    required this.session,
    required this.user,
    required this.current,
  });

  final Session session;
  final User user;
  final int? current;

  @override
  State<_QuotaDialog> createState() => _QuotaDialogState();
}

class _QuotaDialogState extends State<_QuotaDialog> {
  late final _field = TextEditingController(
    text: widget.current == null
        ? ''
        : (widget.current! / (1024 * 1024 * 1024)).toStringAsFixed(1),
  );
  String? _problem;
  bool _busy = false;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final parsed = parseQuotaGb(_field.text);
    if (!parsed.ok) {
      setState(
        () => _problem = 'Type a number of gigabytes, or nothing for no limit.',
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.session.api.setUserQuota(
        widget.user.id,
        QuotaUpdate(quotaBytes: parsed.bytes),
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (cause) {
      if (mounted) setState(() => _problem = apiProblem(cause));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Storage for ${widget.user.email}'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_problem != null)
          Text(_problem!, style: TextStyle(color: Palette.err)),
        TextField(
          controller: _field,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Limit in GB',
            helperText: 'Empty means no limit.',
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      TextButton(onPressed: _busy ? null : _save, child: const Text('Save')),
    ],
  );
}
