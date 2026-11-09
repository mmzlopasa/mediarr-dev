import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../../l10n/l10n.dart';
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
      appBar: AppBar(title: Text(l.adminJobsTitle)),
      body: AdminBody(
        loading: jobs == null,
        error: _error,
        child: () => RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            children: [
              AdminHeading(l.adminJobsQueues),
              for (final queue in jobs!.queues)
                ListTile(
                  title: Text(queue.name),
                  subtitle: Text(
                    queue.paused
                        ? l.adminJobsQueueStatePaused(
                            '${queue.queued}',
                            '${queue.running}',
                          )
                        : l.adminJobsQueueState(
                            '${queue.queued}',
                            '${queue.running}',
                          ),
                  ),
                  trailing: TextButton(
                    onPressed: () => _act(
                      () => queue.paused
                          ? _session.api.resumeJobQueue(queue.name)
                          : _session.api.pauseJobQueue(queue.name),
                      queue.paused
                          ? l.adminJobsContinues(queue.name)
                          : l.adminJobsIsPaused(queue.name),
                    ),
                    child: Text(
                      queue.paused ? l.adminJobsResume : l.adminJobsPause,
                    ),
                  ),
                ),
              AdminHeading(l.adminJobsFailed),
              if (jobs.failed.isEmpty)
                ListTile(title: Text(l.adminJobsNoneFailed))
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
                        l.adminJobsQueuedAgain,
                      ),
                      child: Text(l.adminJobsTryAgain),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
