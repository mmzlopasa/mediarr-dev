import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../../services/session.dart';
import '../../theme.dart';
import 'admin_common.dart';

const videoHeights = [720, 1080, 1440, 2160];

/// The same limits the server checks, so a wrong value is said before saving.
String? serverSettingsProblem(ServerSettings s) {
  bool within(num value, num low, num high) => value >= low && value <= high;
  if (!within(s.trashDays, 1, 3650)) {
    return 'The trash keeps photos for 1 to 3650 days.';
  }
  if (!within(s.imageQuality, 40, 100)) {
    return 'Image quality must be between 40 and 100.';
  }
  if (!within(s.previewSize, 720, 4096)) {
    return 'The preview size must be between 720 and 4096.';
  }
  if (!within(s.videoQuality, 18, 40)) {
    return 'Video quality must be between 18 and 40, where lower is better.';
  }
  if (!videoHeights.contains(s.videoMaxHeight)) {
    return 'The largest video must be 720, 1080, 1440 or 2160.';
  }
  if (!within(s.faceMinScore, 0.1, 1)) {
    return 'How sure a face must be is between 0.1 and 1.';
  }
  if (!within(s.faceMaxDistance, 0.1, 2)) {
    return 'How alike two faces must be is between 0.1 and 2.';
  }
  if (!within(s.workerConcurrency, 0, 64)) {
    return 'Background jobs must be between 0 and 64.';
  }
  if (!within(s.videoWorkers, 1, 16) || !within(s.analysisWorkers, 1, 16)) {
    return 'Video and analysis jobs must be between 1 and 16.';
  }
  if (!within(s.externalScanHours, 1, 720)) {
    return 'The scan interval must be between 1 and 720 hours.';
  }
  if (s.loginMessage.trim().length > 1000) {
    return 'The sign-in message is too long.';
  }
  return null;
}

/// Every server setting the web has, in the app.
class ServerSettingsScreen extends ConsumerStatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  ConsumerState<ServerSettingsScreen> createState() =>
      _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends ConsumerState<ServerSettingsScreen> {
  late final Session _session = ref.read(sessionProvider).value!;
  ServerSettings? _settings;
  String? _error;
  String? _problem;
  bool _saving = false;
  final Map<String, TextEditingController> _fields = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final settings = await _session.api.getServerSettings();
      if (!mounted || settings == null) return;
      setState(() {
        _settings = settings;
        _error = null;
        _fill(settings);
      });
    } on ApiException catch (cause) {
      if (mounted) setState(() => _error = apiProblem(cause));
    }
  }

  TextEditingController _field(String key) =>
      _fields.putIfAbsent(key, TextEditingController.new);

  void _fill(ServerSettings s) {
    _field('trashDays').text = '${s.trashDays}';
    _field('imageQuality').text = '${s.imageQuality}';
    _field('previewSize').text = '${s.previewSize}';
    _field('videoQuality').text = '${s.videoQuality}';
    _field('faceMinScore').text = '${s.faceMinScore}';
    _field('faceMaxDistance').text = '${s.faceMaxDistance}';
    _field('workerConcurrency').text = '${s.workerConcurrency}';
    _field('videoWorkers').text = '${s.videoWorkers}';
    _field('analysisWorkers').text = '${s.analysisWorkers}';
    _field('externalScanHours').text = '${s.externalScanHours}';
    _field('loginMessage').text = s.loginMessage;
    _field('serverName').text = s.serverName ?? 'Mediarr';
  }

  /// The form's values in a copy of the settings, or null when a number is not a number.
  ServerSettings? _read() {
    final s = _settings!;
    int? whole(String key) => int.tryParse(_field(key).text.trim());
    double? real(String key) =>
        double.tryParse(_field(key).text.trim().replaceAll(',', '.'));
    final values = [
      whole('trashDays'),
      whole('imageQuality'),
      whole('previewSize'),
      whole('videoQuality'),
      real('faceMinScore'),
      real('faceMaxDistance'),
      whole('workerConcurrency'),
      whole('videoWorkers'),
      whole('analysisWorkers'),
      whole('externalScanHours'),
    ];
    if (values.contains(null)) return null;
    return ServerSettings(
      trashDays: whole('trashDays')!,
      imageQuality: whole('imageQuality')!,
      previewSize: whole('previewSize')!,
      videoQuality: whole('videoQuality')!,
      videoMaxHeight: s.videoMaxHeight,
      loginMessage: _field('loginMessage').text,
      passwordLogin: s.passwordLogin,
      maintenance: s.maintenance,
      faceMinScore: real('faceMinScore')!,
      faceMaxDistance: real('faceMaxDistance')!,
      workerConcurrency: whole('workerConcurrency')!,
      videoWorkers: whole('videoWorkers')!,
      analysisWorkers: whole('analysisWorkers')!,
      externalScanHours: whole('externalScanHours')!,
      visibleOnNetwork: s.visibleOnNetwork ?? true,
      serverName: _field('serverName').text.trim(),
    );
  }

  Future<void> _save() async {
    final next = _read();
    if (next == null) {
      setState(() => _problem = 'Every number field needs a number.');
      return;
    }
    final problem = serverSettingsProblem(next);
    if (problem != null) {
      setState(() => _problem = problem);
      return;
    }
    setState(() {
      _saving = true;
      _problem = null;
    });
    try {
      final saved = await _session.api.setServerSettings(next);
      if (!mounted) return;
      setState(() => _settings = saved ?? next);
      tellAdmin(context, 'The settings are saved.');
    } on ApiException catch (cause) {
      if (mounted) setState(() => _problem = apiProblem(cause));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _number(
    String key,
    String label, {
    String? help,
    bool decimal = false,
  }) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
    child: TextField(
      key: ValueKey('setting-$key'),
      controller: _field(key),
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      decoration: InputDecoration(labelText: label, helperText: help),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final s = _settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Server settings')),
      bottomNavigationBar: s == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: GoldButton(
                  label: 'Save',
                  busy: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ),
            ),
      body: AdminBody(
        loading: s == null,
        error: _error,
        child: () => ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            if (_problem != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(_problem!, style: TextStyle(color: Palette.err)),
              ),
            const AdminHeading('Trash'),
            _number(
              'trashDays',
              'Days photos stay in the trash',
              help: '1 to 3650',
            ),
            const AdminHeading('Pictures and videos'),
            _number('imageQuality', 'Image quality', help: '40 to 100'),
            _number(
              'previewSize',
              'Preview size in pixels',
              help: '720 to 4096',
            ),
            _number(
              'videoQuality',
              'Video quality',
              help: '18 to 40, lower is better and larger',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: DropdownButtonFormField<int>(
                initialValue: s!.videoMaxHeight,
                decoration: const InputDecoration(labelText: 'Largest video'),
                items: [
                  for (final height in videoHeights)
                    DropdownMenuItem(value: height, child: Text('${height}p')),
                ],
                onChanged: (value) => setState(
                  () => s.videoMaxHeight = value ?? s.videoMaxHeight,
                ),
              ),
            ),
            const AdminHeading('Faces'),
            _number(
              'faceMinScore',
              'How sure a face must be',
              help: '0.1 to 1',
              decimal: true,
            ),
            _number(
              'faceMaxDistance',
              'How alike two faces must be to be one person',
              help: '0.1 to 2',
              decimal: true,
            ),
            const AdminHeading('Background jobs'),
            _number(
              'workerConcurrency',
              'Jobs at once',
              help: '0 uses WORKER_CONCURRENCY; applies after the worker restarts',
            ),
            _number(
              'videoWorkers',
              'Videos at once',
              help: '1 to 16; applies after the worker restarts',
            ),
            _number(
              'analysisWorkers',
              'Analyses at once',
              help: '1 to 16; applies after the worker restarts',
            ),
            _number(
              'externalScanHours',
              'Scan external folders every … hours',
              help: '1 to 720',
            ),
            const AdminHeading('Signing in'),
            SwitchListTile(
              title: const Text('Allow signing in with a password'),
              value: s.passwordLogin,
              onChanged: (value) => setState(() => s.passwordLogin = value),
            ),
            SwitchListTile(
              title: const Text('Maintenance mode'),
              subtitle: const Text('Only administrators can use the server'),
              value: s.maintenance,
              onChanged: (value) => setState(() => s.maintenance = value),
            ),
            SwitchListTile(
              key: const ValueKey('setting-visibleOnNetwork'),
              title: const Text(
                'Apps on the same network can find this server',
              ),
              subtitle: const Text('Signing in still needs an account.'),
              value: s.visibleOnNetwork ?? true,
              onChanged: (value) => setState(() => s.visibleOnNetwork = value),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: TextField(
                controller: _field('serverName'),
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: "The server's name",
                  hintText: 'Mediarr',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: TextField(
                controller: _field('loginMessage'),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Message on the sign-in page',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
