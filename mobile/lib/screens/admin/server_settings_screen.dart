import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../../l10n/l10n.dart';
import '../../services/session.dart';
import '../../theme.dart';
import 'admin_common.dart';

const videoHeights = [720, 1080, 1440, 2160];

/// The same limits the server checks, so a wrong value is said before saving.
String? serverSettingsProblem(ServerSettings s) {
  bool within(num value, num low, num high) => value >= low && value <= high;
  if (!within(s.trashDays, 1, 3650)) {
    return l.adminServerSettingsTrashDaysProblem;
  }
  if (!within(s.imageQuality, 40, 100)) {
    return l.adminServerSettingsImageQualityProblem;
  }
  if (!within(s.previewSize, 720, 4096)) {
    return l.adminServerSettingsPreviewSizeProblem;
  }
  if (!within(s.videoQuality, 18, 40)) {
    return l.adminServerSettingsVideoQualityProblem;
  }
  if (!videoHeights.contains(s.videoMaxHeight)) {
    return l.adminServerSettingsVideoHeightProblem;
  }
  if (!within(s.faceMinScore, 0.1, 1)) {
    return l.adminServerSettingsFaceScoreProblem;
  }
  if (!within(s.faceMaxDistance, 0.1, 2)) {
    return l.adminServerSettingsFaceDistanceProblem;
  }
  if (!within(s.workerConcurrency, 0, 64)) {
    return l.adminServerSettingsJobsProblem;
  }
  if (!within(s.videoWorkers, 1, 16) || !within(s.analysisWorkers, 1, 16)) {
    return l.adminServerSettingsWorkersProblem;
  }
  if (!within(s.externalScanHours, 1, 720)) {
    return l.adminServerSettingsScanProblem;
  }
  if (s.loginMessage.trim().length > 1000) {
    return l.adminServerSettingsMessageProblem;
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
      setState(() => _problem = l.adminServerSettingsNeedNumbers);
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
      tellAdmin(context, l.adminServerSettingsSaved);
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
      appBar: AppBar(title: Text(l.adminServerSettingsTitle)),
      bottomNavigationBar: s == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: GoldButton(
                  label: l.albumScreenSave,
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
            AdminHeading(l.adminServerSettingsTrash),
            _number(
              'trashDays',
              l.adminServerSettingsTrashDays,
              help: l.adminServerSettingsRange('1', '3650'),
            ),
            AdminHeading(l.adminServerSettingsPicturesAndVideos),
            _number(
              'imageQuality',
              l.adminServerSettingsImageQuality,
              help: l.adminServerSettingsRange('40', '100'),
            ),
            _number(
              'previewSize',
              l.adminServerSettingsPreviewSize,
              help: l.adminServerSettingsRange('720', '4096'),
            ),
            _number(
              'videoQuality',
              l.adminServerSettingsVideoQuality,
              help: l.adminServerSettingsVideoQualityHelp,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: DropdownButtonFormField<int>(
                initialValue: s!.videoMaxHeight,
                decoration: InputDecoration(
                  labelText: l.adminServerSettingsLargestVideo,
                ),
                items: [
                  for (final height in videoHeights)
                    DropdownMenuItem(value: height, child: Text('${height}p')),
                ],
                onChanged: (value) => setState(
                  () => s.videoMaxHeight = value ?? s.videoMaxHeight,
                ),
              ),
            ),
            AdminHeading(l.adminServerSettingsFaces),
            _number(
              'faceMinScore',
              l.adminServerSettingsFaceScore,
              help: l.adminServerSettingsRange('0.1', '1'),
              decimal: true,
            ),
            _number(
              'faceMaxDistance',
              l.adminServerSettingsFaceDistance,
              help: l.adminServerSettingsRange('0.1', '2'),
              decimal: true,
            ),
            AdminHeading(l.adminServerSettingsBackgroundJobs),
            _number(
              'workerConcurrency',
              l.adminServerSettingsJobsAtOnce,
              help: l.adminServerSettingsJobsAtOnceHelp,
            ),
            _number(
              'videoWorkers',
              l.adminServerSettingsVideosAtOnce,
              help: l.adminServerSettingsWorkersHelp,
            ),
            _number(
              'analysisWorkers',
              l.adminServerSettingsAnalysesAtOnce,
              help: l.adminServerSettingsWorkersHelp,
            ),
            _number(
              'externalScanHours',
              l.adminServerSettingsScanHours,
              help: l.adminServerSettingsRange('1', '720'),
            ),
            AdminHeading(l.adminServerSettingsSigningIn),
            SwitchListTile(
              title: Text(l.adminServerSettingsPasswordLogin),
              value: s.passwordLogin,
              onChanged: (value) => setState(() => s.passwordLogin = value),
            ),
            SwitchListTile(
              title: Text(l.adminServerSettingsMaintenance),
              subtitle: Text(l.adminServerSettingsMaintenanceHelp),
              value: s.maintenance,
              onChanged: (value) => setState(() => s.maintenance = value),
            ),
            SwitchListTile(
              key: const ValueKey('setting-visibleOnNetwork'),
              title: Text(l.adminServerSettingsVisibleOnNetwork),
              subtitle: Text(l.adminServerSettingsVisibleOnNetworkHelp),
              value: s.visibleOnNetwork ?? true,
              onChanged: (value) => setState(() => s.visibleOnNetwork = value),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: TextField(
                controller: _field('serverName'),
                maxLength: 60,
                decoration: InputDecoration(
                  labelText: l.adminServerSettingsServerName,
                  hintText: 'Mediarr',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: TextField(
                controller: _field('loginMessage'),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l.adminServerSettingsLoginMessage,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
