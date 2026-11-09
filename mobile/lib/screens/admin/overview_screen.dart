import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../../services/session.dart';
import 'admin_common.dart';

/// Live statistics of the whole server, as on the web's overview.
class AdminOverviewScreen extends ConsumerStatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  ConsumerState<AdminOverviewScreen> createState() =>
      _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends ConsumerState<AdminOverviewScreen> {
  late final Session _session = ref.read(sessionProvider).value!;
  AdminOverview? _overview;
  AdminHealth? _health;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final overview = await _session.api.getAdminOverview();
      final health = await _session.api.getAdminHealth();
      if (mounted) {
        setState(() {
          _overview = overview;
          _health = health;
          _error = null;
        });
      }
    } on ApiException catch (cause) {
      if (mounted) setState(() => _error = apiProblem(cause));
    }
  }

  Widget _row(String label, String value) => ListTile(
    dense: true,
    title: Text(label),
    trailing: Text(value, style: Theme.of(context).textTheme.bodyLarge),
  );

  @override
  Widget build(BuildContext context) {
    final overview = _overview;
    final health = _health;
    return Scaffold(
      appBar: AppBar(title: const Text('Overview')),
      body: AdminBody(
        loading: overview == null,
        error: _error,
        child: () => RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            children: [
              const AdminHeading('Library'),
              _row('Users', '${overview!.users}'),
              _row('Photos', '${overview.photos}'),
              _row('Videos', '${overview.videos}'),
              _row('Being processed', '${overview.processing}'),
              _row('Failed', '${overview.failed}'),
              _row('Library size', adminBytes(overview.libraryBytes)),
              const AdminHeading('Disk'),
              _row('Free', adminBytes(overview.diskFreeBytes)),
              _row('Total', adminBytes(overview.diskTotalBytes)),
              const AdminHeading('Jobs'),
              _row('Waiting', '${overview.jobs.queued}'),
              _row('Running', '${overview.jobs.running}'),
              _row('Done', '${overview.jobs.completed}'),
              _row('Failed', '${overview.jobs.failed}'),
              if (health != null) ...[
                const AdminHeading('Services'),
                _row(
                  'Worker',
                  health.workerRunning ? 'Running' : 'Not running',
                ),
                _row(
                  'Analysis (ML)',
                  !health.mlEnabled
                      ? 'Turned off'
                      : health.mlRunning == true
                      ? 'Running'
                      : 'Not running',
                ),
                _row('Database size', adminBytes(health.databaseBytes)),
              ],
              const AdminHeading('Versions'),
              _row('Mediarr', overview.version),
              _row('Database', overview.databaseVersion),
            ],
          ),
        ),
      ),
    );
  }
}
