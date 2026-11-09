import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/dispose_later.dart';
import '../services/session.dart';
import '../theme.dart';
import '../timeline/layout.dart';
import '../l10n/l10n.dart';

const _gb = 1024 * 1024 * 1024;

/// Whether a key sent to [address] could be read on the way: plain HTTP outside the home network.
bool isExposedAddress(String address) {
  final url = Uri.tryParse(address.trim());
  if (url == null || url.scheme != 'http') return false;
  final host = url.host;
  if (host == 'localhost' || host.endsWith('.local')) return false;
  return !RegExp(
    r'^(127\.|10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.|100\.(6[4-9]|[7-9]\d|1[01]\d|12[0-7])\.)',
  ).hasMatch(host);
}

String _when(DateTime? value) => value == null
    ? l.backupScreenNotYet
    : value.toLocal().toString().substring(0, 16);

/// One line about another Mediarr that keeps a copy of this server's backup.
String describeDestination(BackupDestination destination) =>
    '${destination.address} · ${l.backupScreenLastBackup(_when(destination.lastSuccessAt))} · ${l.backupScreenUpTo(formatBytes(destination.quotaBytes))}';

/// One line about a server whose backup this one keeps.
String describeGuest(KeepGuest guest) {
  final status = switch (guest.status) {
    KeepGuestStatusEnum.invited => l.backupScreenInvited,
    KeepGuestStatusEnum.stopped => l.backupScreenStopped,
    _ => l.backupScreenActive,
  };
  final deleted = guest.deletedBytes > 0
      ? ' · ${l.backupScreenDeletedKept(formatBytes(guest.deletedBytes))}'
      : '';
  return '$status · ${formatBytes(guest.usedBytes)} / ${formatBytes(guest.quotaBytes)} · ${l.backupScreenLastBackup(_when(guest.lastBackupAt))}$deleted';
}

/// Backup for administrators, as on the web: where it goes, copies at other Mediarr servers, and the
/// backups this server keeps for others.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  late final Session _session = ref.read(sessionProvider).value!;
  final _repository = TextEditingController();
  final _password = TextEditingController();
  final _s3Key = TextEditingController();
  final _s3Secret = TextEditingController();
  final _hour = TextEditingController(text: '3');
  final _code = TextEditingController();
  bool? _enabled;
  BackupSettings? _settings;
  List<BackupRun> _runs = const [];
  List<BackupDestination>? _destinations;
  List<KeepGuest>? _guests;
  List<UpgradeSnapshot> _snapshots = const [];
  bool _failed = false;
  bool _pairing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in [
      _repository,
      _password,
      _s3Key,
      _s3Secret,
      _hour,
      _code,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final api = _session.api;
      final results = await Future.wait([
        api.getFeatures(),
        api.getBackupSettings(),
        api.listBackupRuns(),
        api.listBackupDestinations(),
        api.listKeepGuests(),
        api.listUpgradeSnapshots(),
      ]);
      if (!mounted) return;
      final settings = results[1] as BackupSettings?;
      setState(() {
        _enabled = (results[0] as Map<String, bool>?)?['backup'] ?? false;
        if (_settings == null && settings != null) {
          _repository.text = settings.repository;
          _hour.text = '${settings.hour}';
        }
        _settings = settings;
        _runs = (results[2] as List<BackupRun>?) ?? const [];
        _destinations = (results[3] as List<BackupDestination>?) ?? const [];
        _guests = (results[4] as List<KeepGuest>?) ?? const [];
        _snapshots = (results[5] as List<UpgradeSnapshot>?) ?? const [];
        _failed = false;
      });
    } on ApiException {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _tell(String message) {
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _act(Future<void> Function() work, [String? done]) async {
    try {
      await work();
      if (done != null) _tell(done);
    } on ApiException catch (cause) {
      _tell(cause.message ?? l.backupScreenActionFailed);
    }
    await _load();
  }

  Future<void> _save() => _act(() async {
    await _session.api.setBackupSettings(
      BackupSettingsUpdate(
        repository: _repository.text.trim(),
        hour: int.tryParse(_hour.text) ?? 3,
        password: _password.text.isEmpty ? null : _password.text,
        s3Key: _s3Key.text.isEmpty ? null : _s3Key.text,
        s3Secret: _s3Secret.text.isEmpty ? null : _s3Secret.text,
      ),
    );
    _password.clear();
    _s3Key.clear();
    _s3Secret.clear();
  }, l.backupScreenSaved);

  Future<void> _run(BackupRunRequestKindEnum kind, [String? destination]) =>
      _act(
        () => _session.api.startBackupRun(
          BackupRunRequest(kind: kind, destinationId: destination),
        ),
        kind == BackupRunRequestKindEnum.backup
            ? l.backupScreenBackupStarted
            : l.backupScreenRestoreTestStarted,
      );

  Future<void> _scan() async {
    final code = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const KeepCodeScanner()));
    if (code != null) setState(() => _code.text = code);
  }

  Future<void> _pair() async {
    setState(() => _pairing = true);
    await _act(() async {
      await _session.api.addBackupDestination(
        BackupDestinationCreate(code: _code.text),
      );
      _code.clear();
    }, l.backupScreenPaired);
    if (mounted) setState(() => _pairing = false);
  }

  Future<void> _invite() async {
    final name = TextEditingController();
    final size = TextEditingController(text: '100');
    final address = TextEditingController(text: _session.serverUrl);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.backupScreenKeepForSomeone),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: InputDecoration(labelText: l.backupScreenForWhom),
              ),
              TextField(
                controller: size,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l.backupScreenAtMostGb),
              ),
              TextField(
                controller: address,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: l.backupScreenOtherServerAddress,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.backupScreenCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.backupScreenInvite),
          ),
        ],
      ),
    );
    final body = KeepGuestCreate(
      name: name.text.trim(),
      quotaBytes: ((double.tryParse(size.text) ?? 0) * _gb).round(),
      address: address.text.trim(),
    );
    disposeLater([name, size, address]);
    if (ok != true) return;
    try {
      final invite = await _session.api.inviteKeepGuest(body);
      await _load();
      if (invite != null && mounted) await _showInvite(invite);
    } on ApiException catch (cause) {
      _tell(cause.message ?? l.backupScreenInvitationFailed);
    }
  }

  Future<void> _showInvite(KeepInvite invite) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.backupScreenCodeFor(invite.guest.name)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: QrImageView(data: invite.code, size: 220),
            ),
            const SizedBox(height: 12),
            Text(
              l.backupScreenSendItToAdmin(_when(invite.expiresAt)),
              style: TextStyle(color: Palette.dim),
            ),
            const SizedBox(height: 8),
            SelectableText(invite.code, style: monoData(12)),
            if (isExposedAddress(invite.guest.address)) ...[
              const SizedBox(height: 8),
              Text(
                l.backupScreenPlainHttp,
                style: TextStyle(color: Palette.err),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Clipboard.setData(ClipboardData(text: invite.code)),
          child: Text(l.backupScreenCopy),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.backupScreenDone),
        ),
      ],
    ),
  );

  Future<void> _resize(KeepGuest guest) async {
    final size = TextEditingController(
      text: '${(guest.quotaBytes / _gb).round()}',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.backupScreenHowMuchFor(guest.name)),
        content: TextField(
          controller: size,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'GB'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.backupScreenCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.backupScreenSave),
          ),
        ],
      ),
    );
    final bytes = ((double.tryParse(size.text) ?? 0) * _gb).round();
    disposeLater([size]);
    if (ok != true) return;
    await _act(
      () => _session.api.updateKeepGuest(
        guest.id,
        KeepGuestUpdate(
          quotaBytes: bytes,
          status: guest.status == KeepGuestStatusEnum.stopped
              ? KeepGuestUpdateStatusEnum.stopped
              : KeepGuestUpdateStatusEnum.active,
        ),
      ),
    );
  }

  Future<void> _remove(KeepGuest guest) async {
    final typed = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(l.backupScreenDeleteCopyOf(guest.name)),
          content: TextField(
            controller: typed,
            onChanged: (_) => update(() {}),
            decoration: InputDecoration(
              labelText: l.backupScreenTypeToDelete(guest.name),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.backupScreenCancel),
            ),
            TextButton(
              onPressed: typed.text == guest.name
                  ? () => Navigator.pop(context, true)
                  : null,
              child: Text(
                l.backupScreenDeleteTheCopy,
                style: TextStyle(
                  color: typed.text == guest.name ? Palette.err : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    disposeLater([typed]);
    if (ok != true) return;
    await _act(() => _session.api.removeKeepGuest(guest.id, name: guest.name));
  }

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );

  Widget _note(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
    child: Text(text, style: TextStyle(color: Palette.dim)),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool secret = false,
    TextInputType? keyboard,
  }) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
    child: TextField(
      controller: controller,
      obscureText: secret,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label),
    ),
  );

  List<Widget> _backupSection() {
    final settings = _settings;
    return [
      SwitchListTile(
        title: Text(l.backupScreenScheduledBackup),
        subtitle: Text(l.backupScreenOnceADay),
        value: _enabled ?? false,
        onChanged: (on) => _act(
          () => _session.api.setFeature('backup', FeatureUpdate(enabled: on)),
        ),
      ),
      _note(
        l.backupScreenExplain(
          settings?.localFolder ?? l.backupScreenBackupFolder,
        ),
      ),
      _field(_repository, l.backupScreenDestination),
      _field(
        _password,
        settings?.hasPassword == true
            ? l.backupScreenPasswordSaved
            : l.backupScreenBackupPassword,
        secret: true,
      ),
      _field(
        _s3Key,
        settings?.hasS3Key == true
            ? l.backupScreenAccessKeySaved
            : l.backupScreenAccessKey,
      ),
      _field(_s3Secret, l.backupScreenSecretKey, secret: true),
      _field(_hour, l.backupScreenHourOfDay, keyboard: TextInputType.number),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(onPressed: _save, child: Text(l.backupScreenSave)),
            OutlinedButton(
              onPressed: () => _run(BackupRunRequestKindEnum.backup),
              child: Text(l.backupScreenBackUpNow),
            ),
            OutlinedButton(
              onPressed: () => _run(BackupRunRequestKindEnum.restoreTest),
              child: Text(l.backupScreenTestBringingBack),
            ),
          ],
        ),
      ),
      if (_runs.isNotEmpty) ...[
        _heading(l.backupScreenHistory),
        for (final run in _runs.take(8))
          ListTile(
            dense: true,
            title: Text(
              '${run.kind == BackupRunKindEnum.backup ? l.backupScreenRunBackup : l.backupScreenRunRestoreTest}${run.destinationName == null ? '' : ' → ${run.destinationName}'}',
            ),
            subtitle: Text(
              '${run.status.value} · ${_when(run.startedAt)} · ${l.backupScreenFiles('${run.files}')}${run.message.isEmpty ? '' : '\n${run.message}'}',
            ),
          ),
      ],
    ];
  }

  List<Widget> _destinationSection() {
    final destinations = _destinations ?? const [];
    return [
      _heading(l.backupScreenMyCopyAtOthers),
      _note(l.backupScreenTwoServers),
      for (final destination in destinations)
        ListTile(
          title: Text(destination.name),
          subtitle: Text(
            describeDestination(destination) +
                (destination.lastError.isEmpty
                    ? ''
                    : '\n${destination.lastError}') +
                (isExposedAddress(destination.address)
                    ? '\n${l.backupScreenNoHttps}'
                    : ''),
          ),
          isThreeLine: destination.lastError.isNotEmpty,
          trailing: PopupMenuButton<String>(
            tooltip: l.backupScreenMore,
            onSelected: (choice) => choice == 'test'
                ? _run(BackupRunRequestKindEnum.restoreTest, destination.id)
                : _act(
                    () => _session.api.removeBackupDestination(destination.id),
                  ),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'test',
                child: Text(l.backupScreenTestBringingBack),
              ),
              PopupMenuItem(value: 'remove', child: Text(l.backupScreenRemove)),
            ],
          ),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
        child: TextField(
          controller: _code,
          minLines: 2,
          maxLines: 4,
          style: monoData(13),
          decoration: InputDecoration(
            labelText: l.backupScreenCodeFromOther,
            suffixIcon: IconButton(
              tooltip: l.backupScreenScanQr,
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: _scan,
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: _pairing ? null : _pair,
            child: Text(_pairing ? l.backupScreenPairing : l.backupScreenPair),
          ),
        ),
      ),
    ];
  }

  /// Snapshots of the database made before upgrades. Going back is a command, with the server off.
  List<Widget> _snapshotSection() {
    final text = Theme.of(context).textTheme;
    return [
      _heading(l.backupScreenSnapshots),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text(l.backupScreenSnapshotsExplain, style: text.bodySmall),
      ),
      if (_snapshots.isEmpty) ListTile(title: Text(l.backupScreenNoSnapshots)),
      for (final snap in _snapshots)
        ListTile(
          title: Text(
            '${snap.fromVersion.isEmpty ? l.backupScreenEarlierVersion : snap.fromVersion} → ${snap.toVersion}',
          ),
          subtitle: Text(
            '${MaterialLocalizations.of(context).formatMediumDate(snap.createdAt.toLocal())} · '
            '${formatBytes(snap.sizeBytes)}',
          ),
          trailing: IconButton(
            tooltip: l.backupScreenDeleteSnapshot,
            icon: Icon(Icons.delete_outline, color: Palette.err),
            onPressed: () => _deleteSnapshot(snap),
          ),
        ),
      if (_snapshots.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: SelectableText(
            '${l.backupScreenGoBackHow}\n'
            'docker compose stop server worker\n'
            'docker compose run --rm server rollback',
            style: text.bodySmall,
          ),
        ),
    ];
  }

  Future<void> _deleteSnapshot(UpgradeSnapshot snap) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.backupScreenDeleteThisSnapshot),
        content: Text(l.backupScreenNoGoingBack),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.backupScreenCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.backupScreenDelete),
          ),
        ],
      ),
    );
    if (sure != true) return;
    try {
      await _session.api.deleteUpgradeSnapshot(snap.name);
      await _load();
    } on ApiException catch (cause) {
      _tell(cause.message ?? l.backupScreenNotDeleted);
    }
  }

  List<Widget> _guestSection() {
    final guests = _guests ?? const [];
    return [
      _heading(l.backupScreenIKeepForOthers),
      for (final guest in guests)
        ListTile(
          title: Text(guest.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(describeGuest(guest)),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: (guest.usedBytes / guest.quotaBytes).clamp(0, 1),
                color: Palette.gold,
                backgroundColor: Palette.bg3,
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            tooltip: l.backupScreenMore,
            onSelected: (choice) async {
              switch (choice) {
                case 'code':
                  try {
                    final invite = await _session.api.reinviteKeepGuest(
                      guest.id,
                    );
                    await _load();
                    if (invite != null && mounted) await _showInvite(invite);
                  } on ApiException catch (cause) {
                    _tell(cause.message ?? l.backupScreenNoNewCode);
                  }
                case 'pause':
                  await _act(
                    () => _session.api.updateKeepGuest(
                      guest.id,
                      KeepGuestUpdate(
                        quotaBytes: guest.quotaBytes,
                        status: guest.status == KeepGuestStatusEnum.stopped
                            ? KeepGuestUpdateStatusEnum.active
                            : KeepGuestUpdateStatusEnum.stopped,
                      ),
                    ),
                  );
                case 'size':
                  await _resize(guest);
                case 'restore':
                  await _act(() async {
                    final result = await _session.api.restoreKeepGuestDeleted(
                      guest.id,
                    );
                    _tell(
                      l.backupScreenFilesBroughtBack(
                        '${result?.restored ?? 0}',
                      ),
                    );
                  });
                case 'remove':
                  await _remove(guest);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'code', child: Text(l.backupScreenNewCode)),
              if (guest.status != KeepGuestStatusEnum.invited)
                PopupMenuItem(
                  value: 'pause',
                  child: Text(
                    guest.status == KeepGuestStatusEnum.stopped
                        ? l.backupScreenResume
                        : l.backupScreenStop,
                  ),
                ),
              PopupMenuItem(value: 'size', child: Text(l.backupScreenSize)),
              if (guest.deletedBytes > 0)
                PopupMenuItem(
                  value: 'restore',
                  child: Text(l.backupScreenBringBackDeleted),
                ),
              PopupMenuItem(value: 'remove', child: Text(l.backupScreenRemove)),
            ],
          ),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _invite,
            icon: const Icon(Icons.person_add_alt),
            label: Text(l.backupScreenInvite),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ready = _destinations != null && _guests != null;
    return Scaffold(
      appBar: AppBar(title: Text(l.backupScreenTitle)),
      body: !ready
          ? _failed
                ? EmptyMessage(
                    icon: Icons.cloud_off,
                    text: l.backupScreenLoadFailed,
                  )
                : Center(child: CircularProgressIndicator(color: Palette.gold))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 40),
                children: [
                  ..._backupSection(),
                  ..._destinationSection(),
                  ..._guestSection(),
                  ..._snapshotSection(),
                ],
              ),
            ),
    );
  }
}

/// Scans the QR code another Mediarr shows for pairing, and gives back its text.
class KeepCodeScanner extends StatefulWidget {
  const KeepCodeScanner({super.key});

  @override
  State<KeepCodeScanner> createState() => _KeepCodeScannerState();
}

class _KeepCodeScannerState extends State<KeepCodeScanner> {
  bool _done = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(l.backupScreenScanTheCode)),
    body: MobileScanner(
      onDetect: (capture) {
        if (_done) return;
        for (final barcode in capture.barcodes) {
          final value = barcode.rawValue ?? '';
          if (value.startsWith('mediarr-keep:')) {
            _done = true;
            Navigator.pop(context, value);
            return;
          }
        }
      },
    ),
  );
}
