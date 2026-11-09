import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../../services/session.dart';
import '../../theme.dart';
import 'admin_common.dart';

/// The job queues, pausing them, and the jobs that gave up, to try again.
class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> {
  late final Session _session = ref.read(sessionProvider).value!;
  AdminJobs? _jobs;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final jobs = await _session.api.getAdminJobs();
      if (mounted) {
        setState(() {
          _jobs = jobs;
          _error = null;
        });
      }
    } on ApiException catch (cause) {
      if (mounted) setState(() => _error = apiProblem(cause));
    }
  }

  Future<void> _act(Future<void> Function() action, String done) async {
    try {
      await action();
      if (mounted) tellAdmin(context, done);
      await _load();
    } on ApiException catch (cause) {
      if (mounted) tellAdmin(context, apiProblem(cause));
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobs = _jobs;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Jobs')),
      body: AdminBody(
        loading: jobs == null,
        error: _error,
        child: () => RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            children: [
              const AdminHeading('Queues'),
              for (final queue in jobs!.queues)
                ListTile(
                  title: Text(queue.name),
                  subtitle: Text(
                    '${queue.queued} waiting · ${queue.running} running'
                    '${queue.paused ? ' · paused' : ''}',
                  ),
                  trailing: TextButton(
                    onPressed: () => _act(
                      () => queue.paused
                          ? _session.api.resumeJobQueue(queue.name)
                          : _session.api.pauseJobQueue(queue.name),
                      queue.paused
                          ? '${queue.name} continues.'
                          : '${queue.name} is paused.',
                    ),
                    child: Text(queue.paused ? 'Resume' : 'Pause'),
                  ),
                ),
              const AdminHeading('Failed'),
              if (jobs.failed.isEmpty)
                const ListTile(title: Text('No job has failed.'))
              else
                for (final job in jobs.failed)
                  ListTile(
                    isThreeLine: true,
                    title: Text('${job.kind} · ${job.queue}'),
                    subtitle: Text(
                      '${adminTime(job.at)}\n${job.error}',
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(color: Palette.err),
                    ),
                    trailing: TextButton(
                      onPressed: () => _act(
                        () => _session.api.retryJob(job.id),
                        'The job is queued again.',
                      ),
                      child: const Text('Try again'),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
