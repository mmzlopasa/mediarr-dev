import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../../l10n/l10n.dart';
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

  List<Widget> _mlRows(MlServiceStatus ml) {
    final loaded = [
      for (final model in ml.models)
        if (model.loaded) model.name,
    ];
    final acceleration = ml.acceleration;
    return [
      AdminHeading(l.adminMlTitle),
      ListTile(
        key: const Key('admin-ml-state'),
        dense: true,
        title: Text(switch (ml.state) {
          MlServiceStatusStateEnum.connected => l.adminMlConnected,
          MlServiceStatusStateEnum.wrongToken => l.adminMlWrongToken,
          _ => l.adminMlUnreachable,
        }),
      ),
      if (ml.models.isNotEmpty)
        ListTile(
          dense: true,
          title: Text(l.adminMlLoaded),
          subtitle: Text(
            loaded.isEmpty ? l.adminMlNoneLoaded : loaded.join(', '),
          ),
        ),
      if (ml.rssBytes != null) _row(l.adminMlMemory, adminBytes(ml.rssBytes!)),
      if (acceleration != null)
        ListTile(
          dense: true,
          title: Text(l.adminMlAcceleration),
          subtitle: Text(
            '${acceleration.requested} (${acceleration.providers.join(', ')})',
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final overview = _overview;
    final health = _health;
    return Scaffold(
      appBar: AppBar(title: Text(l.adminOverviewTitle)),
      body: AdminBody(
        loading: overview == null,
        error: _error,
        child: () => RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            children: [
              AdminHeading(l.adminOverviewLibrary),
              _row(l.adminOverviewUsers, '${overview!.users}'),
              _row(l.adminOverviewPhotos, '${overview.photos}'),
              _row(l.adminOverviewVideos, '${overview.videos}'),
              _row(l.adminOverviewProcessing, '${overview.processing}'),
              _row(l.adminOverviewFailed, '${overview.failed}'),
              _row(
                l.adminOverviewLibrarySize,
                adminBytes(overview.libraryBytes),
              ),
              AdminHeading(l.adminOverviewDisk),
              _row(l.adminOverviewFree, adminBytes(overview.diskFreeBytes)),
              _row(l.adminOverviewTotal, adminBytes(overview.diskTotalBytes)),
              AdminHeading(l.adminOverviewJobs),
              _row(l.adminOverviewWaiting, '${overview.jobs.queued}'),
              _row(l.adminOverviewRunning, '${overview.jobs.running}'),
              _row(l.adminOverviewDone, '${overview.jobs.completed}'),
              _row(l.adminOverviewFailed, '${overview.jobs.failed}'),
              if (health != null) ...[
                AdminHeading(l.adminOverviewServices),
                _row(
                  l.adminOverviewWorker,
                  health.workerRunning
                      ? l.adminOverviewRunning
                      : l.adminOverviewNotRunning,
                ),
                _row(
                  l.adminOverviewAnalysis,
                  !health.mlEnabled
                      ? l.adminOverviewTurnedOff
                      : health.mlRunning == true
                      ? l.adminOverviewRunning
                      : l.adminOverviewNotRunning,
                ),
                _row(
                  l.adminOverviewDatabaseSize,
                  adminBytes(health.databaseBytes),
                ),
              ],
              if (health?.ml case final ml?) ..._mlRows(ml),
              AdminHeading(l.adminOverviewVersions),
              _row('Mediarr', overview.version),
              _row(l.adminOverviewDatabase, overview.databaseVersion),
            ],
          ),
        ),
      ),
    );
  }
}
