import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../../l10n/l10n.dart';
import '../../services/session.dart';
import 'admin_common.dart';

const auditPage = 100;

/// Who changed what, newest first, a page at a time. Never the content of a request.
class AuditScreen extends ConsumerStatefulWidget {
  const AuditScreen({super.key});

  @override
  ConsumerState<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends ConsumerState<AuditScreen> {
  late final Session _session = ref.read(sessionProvider).value!;
  List<AuditEntry>? _entries;
  bool _more = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    try {
      final before = more && (_entries?.isNotEmpty ?? false)
          ? _entries!.last.id
          : null;
      final page =
          await _session.api.listAuditLog(before: before, limit: auditPage) ??
          const [];
      if (!mounted) return;
      setState(() {
        _entries = more ? [...?_entries, ...page] : page;
        _more = page.length == auditPage;
        _error = null;
      });
    } on ApiException catch (cause) {
      if (mounted) setState(() => _error = apiProblem(cause));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(l.adminScreenAuditLog)),
    body: AdminBody(
      loading: _entries == null,
      error: _error,
      child: () => RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            if (_entries!.isEmpty) ListTile(title: Text(l.adminAuditEmpty)),
            for (final entry in _entries!)
              ListTile(
                dense: true,
                title: Text('${entry.method} ${entry.route}'),
                subtitle: Text(
                  [
                    adminTime(entry.at),
                    if (entry.userEmail.isNotEmpty) entry.userEmail,
                    if (entry.target.isNotEmpty) entry.target,
                    '${entry.status}',
                    if (entry.ip.isNotEmpty) entry.ip,
                  ].join(' · '),
                ),
              ),
            if (_more)
              Center(
                child: TextButton(
                  onPressed: () => _load(more: true),
                  child: Text(l.adminAuditShowOlder),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
