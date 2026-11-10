import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../services/session.dart';
import '../theme.dart';
import 'dlna.dart';
import 'tv.dart';
import 'tv_controller.dart';

/// Whether what a session shows may go to a TV: not the trash, and not the locked folder.
bool castable(Session session) =>
    session is! CollectionSession ||
    (session.scope != 'vault' && session.scope != 'trash');

/// The system's AirPlay button on iOS. Choosing an Apple TV sends the videos the app plays there.
class AirPlayButton extends StatelessWidget {
  const AirPlayButton({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: UiKitView(
      viewType: 'app.mediarr/airplay-button',
      creationParams: {'tint': Palette.ink.toARGB32() & 0xFFFFFF},
      creationParamsCodec: const StandardMessageCodec(),
    ),
  );
}

/// Opens the list of TVs, and starts showing this asset on the one chosen.
Future<void> showTvSheet(
  BuildContext context,
  Session session,
  TvAsset asset,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => TvSheet(session: session, asset: asset),
);

class TvSheet extends ConsumerStatefulWidget {
  const TvSheet({super.key, required this.session, required this.asset});

  final Session session;
  final TvAsset asset;

  @override
  ConsumerState<TvSheet> createState() => _TvSheetState();
}

class _TvSheetState extends ConsumerState<TvSheet> {
  final _found = <TvDevice>[];
  final _address = TextEditingController();
  final _subscriptions = <StreamSubscription<TvDevice>>[];
  int _searching = 0;
  bool _adding = false;
  bool _showAddress = false;
  String? _problem;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _address.dispose();
    super.dispose();
  }

  void _search() {
    setState(() {
      _found.clear();
      _problem = null;
    });
    for (final stream in [findChromecasts(), DlnaFinder().find()]) {
      setState(() => _searching++);
      _subscriptions.add(
        stream.listen(
          (device) {
            if (!mounted || _found.contains(device)) return;
            setState(() => _found.add(device));
          },
          onDone: () {
            if (mounted) setState(() => _searching--);
          },
        ),
      );
    }
  }

  Future<void> _add() async {
    setState(() {
      _adding = true;
      _problem = null;
    });
    final device = await DlnaFinder().byAddress(_address.text);
    if (!mounted) return;
    setState(() => _adding = false);
    if (device == null) {
      setState(() => _problem = l.tvSheetNotFoundAt);
      return;
    }
    ref.read(tvProvider.notifier).addDevice(device);
    _address.clear();
    setState(() => _showAddress = false);
  }

  Future<void> _choose(TvDevice device) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final start = ref
          .read(tvProvider.notifier)
          .start(ApiCastServer(widget.session), device, widget.asset);
      navigator.pop();
      await start;
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(l.tvSheetFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tv = ref.watch(tvProvider);
    final devices = [
      ...tv.added,
      ..._found.where((device) => !tv.added.contains(device)),
    ];
    final ios = !kIsWeb && Platform.isIOS;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  l.tvSheetTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (tv.device != null)
                ListTile(
                  leading: Icon(Icons.cast_connected, color: Palette.gold),
                  title: Text(
                    l.tvSheetPlayingOn(tv.device!.name),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: TextButton(
                    onPressed: () {
                      ref.read(tvProvider.notifier).stop();
                      Navigator.of(context).pop();
                    },
                    child: Text(l.tvSheetStop),
                  ),
                ),
              if (ios)
                ListTile(
                  leading: const AirPlayButton(),
                  title: Text(l.tvSheetAirPlay),
                  subtitle: Text(l.tvSheetAirPlayHint),
                  isThreeLine: true,
                ),
              for (final device in devices)
                ListTile(
                  key: ValueKey('tv-${device.id}'),
                  leading: Icon(
                    device.kind == TvKind.chromecast ? Icons.cast : Icons.tv,
                    color: Palette.dim,
                  ),
                  title: Text(
                    device.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    device.kind == TvKind.chromecast
                        ? l.tvSheetChromecast
                        : l.tvSheetDlna,
                  ),
                  selected: tv.device == device,
                  onTap: () => _choose(device),
                ),
              if (_searching > 0)
                ListTile(
                  leading: const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  title: Text(l.tvSheetSearching),
                )
              else if (devices.isEmpty)
                ListTile(
                  leading: Icon(Icons.wifi_find, color: Palette.dim),
                  title: Text(l.tvSheetNoneFound),
                ),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                children: [
                  if (_searching == 0)
                    TextButton(
                      onPressed: _search,
                      child: Text(l.tvSheetSearchAgain),
                    ),
                  if (!_showAddress)
                    TextButton(
                      onPressed: () => setState(() => _showAddress = true),
                      child: Text(l.tvSheetAddByAddress),
                    ),
                ],
              ),
              if (_showAddress)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const ValueKey('tv-address'),
                          controller: _address,
                          autocorrect: false,
                          keyboardType: TextInputType.url,
                          decoration: InputDecoration(
                            labelText: l.tvSheetAddressLabel,
                            errorText: _problem,
                            errorMaxLines: 2,
                          ),
                          onSubmitted: (_) => _add(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _adding
                          ? const SizedBox.square(
                              dimension: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : TextButton(
                              onPressed: _add,
                              child: Text(l.tvSheetAdd),
                            ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(
                  l.tvSheetSameNetwork,
                  style: TextStyle(color: Palette.dim, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// While a TV shows what is on the screen: its name, and for a video, play, pause and seeking.
class TvBar extends ConsumerWidget {
  const TvBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tv = ref.watch(tvProvider);
    final device = tv.device;
    if (device == null) return const SizedBox.shrink();
    final controller = ref.read(tvProvider.notifier);
    final total = tv.duration?.inMilliseconds ?? 0;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white24),
        ),
        // A slider takes all the height it is given, and the bar must stay a bar.
        height: 52,
        child: Row(
          children: [
            Icon(
              tv.connecting ? Icons.cast : Icons.cast_connected,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: tv.video && total > 0 && !tv.connecting
                  ? Semantics(
                      label: l.tvSheetPosition,
                      child: Slider(
                        value: tv.position.inMilliseconds
                            .clamp(0, total)
                            .toDouble(),
                        max: total.toDouble(),
                        onChanged: (value) => controller.seek(
                          Duration(milliseconds: value.round()),
                        ),
                      ),
                    )
                  : Text(
                      tv.connecting
                          ? l.tvSheetConnecting
                          : l.tvSheetPlayingOn(device.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white),
                    ),
            ),
            if (tv.video && !tv.connecting)
              IconButton(
                tooltip: tv.playing ? l.tvSheetPause : l.tvSheetPlay,
                color: Colors.white,
                icon: Icon(tv.playing ? Icons.pause : Icons.play_arrow),
                onPressed: controller.playOrPause,
              ),
            TextButton(
              onPressed: controller.stop,
              child: Text(
                l.tvSheetStop,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
