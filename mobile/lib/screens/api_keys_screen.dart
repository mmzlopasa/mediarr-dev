import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../services/dispose_later.dart';
import '../services/session.dart';
import '../theme.dart';

const keyScopes = <ApiKeyCreateScopesEnum, String>{
  ApiKeyCreateScopesEnum.read: 'Read',
  ApiKeyCreateScopesEnum.upload: 'Upload',
  ApiKeyCreateScopesEnum.write: 'Change and delete',
};

/// What the list shows for a key, without the key itself.
String describeKey(ApiKey key) {
  final rights = key.scopes.map((scope) => scope.value).join(', ');
  final expires = key.expiresAt;
  return expires == null
      ? rights
      : '$rights · expires ${expires.toLocal().toString().split(' ').first}';
}

class ApiKeysScreen extends ConsumerStatefulWidget {
  const ApiKeysScreen({super.key});

  @override
  ConsumerState<ApiKeysScreen> createState() => _ApiKeysScreenState();
}

class _ApiKeysScreenState extends ConsumerState<ApiKeysScreen> {
  late final Session _session = ref.read(sessionProvider).value!;
  List<ApiKey>? _keys;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final keys = await _session.api.listAPIKeys();
      if (mounted) {
        setState(() {
          _keys = keys ?? const [];
          _failed = false;
        });
      }
    } on ApiException {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _tell(String message) {
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _create() async {
    final name = TextEditingController();
    final chosen = <ApiKeyCreateScopesEnum>{ApiKeyCreateScopesEnum.read};
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('New key'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Key name'),
              ),
              for (final scope in keyScopes.entries)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(scope.value),
                  value: chosen.contains(scope.key),
                  onChanged: (on) => update(() {
                    if (on == true) {
                      chosen.add(scope.key);
                    } else {
                      chosen.remove(scope.key);
                    }
                  }),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    final text = name.text;
    disposeLater([name]);
    if (confirmed != true) return;
    try {
      final made = await _session.api.createAPIKey(
        ApiKeyCreate(name: text, scopes: chosen.toList()),
      );
      await _load();
      if (mounted && made != null) await _show(made.key);
    } on ApiException catch (cause) {
      _tell('The key could not be created. ${cause.message ?? ''}');
    }
  }

  Future<void> _show(String key) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Save it now'),
      content: SelectableText(key),
      actions: [
        TextButton(
          onPressed: () => Clipboard.setData(ClipboardData(text: key)),
          child: const Text('Copy'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    ),
  );

  Future<void> _revoke(ApiKey key) async {
    try {
      await _session.api.revokeDeviceKey(key.id);
      await _load();
    } on ApiException {
      _tell('The key could not be revoked.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final keys = _keys;
    return Scaffold(
      appBar: AppBar(
        title: const Text('API keys'),
        actions: [
          IconButton(
            tooltip: 'New key',
            icon: const Icon(Icons.add),
            onPressed: _create,
          ),
        ],
      ),
      body: keys == null
          ? _failed
                ? const EmptyMessage(
                    icon: Icons.cloud_off,
                    text: 'The keys could not be loaded.',
                  )
                : Center(child: CircularProgressIndicator(color: Palette.gold))
          : keys.isEmpty
          ? const EmptyMessage(
              icon: Icons.key_outlined,
              text:
                  'No keys yet. A key gives a program only the chosen rights.',
            )
          : ListView(
              children: [
                for (final key in keys)
                  ListTile(
                    title: Text(key.name),
                    subtitle: Text(describeKey(key)),
                    trailing: IconButton(
                      tooltip: 'Revoke',
                      icon: const Icon(Icons.close),
                      onPressed: () => _revoke(key),
                    ),
                  ),
              ],
            ),
    );
  }
}
