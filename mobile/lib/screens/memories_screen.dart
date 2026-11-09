import '../services/days.dart';

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mediarr_api/api.dart';
import 'package:photo_manager/photo_manager.dart';

import '../l10n/l10n.dart';
import '../services/account_preferences.dart';
import '../services/session.dart';
import '../theme.dart';
import 'asset_picture.dart';
import 'stories_strip.dart';

/// The person's own date decides what today is, not the server's.
/// Today as the person's phone sees it, which decides what a memory is.
String localToday(DateTime now) => dayString(now);

String memoryTitle(Memory memory, DateTime now) =>
    memory.kind == MemoryKindEnum.week
    ? l.memoriesScreenLastWeek
    : l.memoriesScreenOnThisDay(now.year - (memory.year ?? now.year));

class MemoriesScreen extends ConsumerStatefulWidget {
  const MemoriesScreen({super.key});

  @override
  ConsumerState<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends ConsumerState<MemoriesScreen> {
  late final Session _session = ref.read(sessionProvider).value!;
  List<Memory>? _memories;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final memories = await _session.api.listMemories(
        date: localToday(DateTime.now()),
      );
      if (mounted) {
        setState(() {
          _memories = memories ?? const [];
          _failed = false;
        });
      }
    } on ApiException {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final memories = _memories;
    final now = DateTime.now();
    Widget body;
    if (memories == null) {
      body = _failed
          ? EmptyMessage(
              icon: Icons.cloud_off,
              text: l.memoriesScreenLoadFailed,
              action: GoldButton(
                label: l.memoriesScreenTryAgain,
                onPressed: _load,
              ),
            )
          : Center(child: CircularProgressIndicator(color: Palette.gold));
    } else if (memories.isEmpty) {
      body = EmptyMessage(
        icon: Icons.auto_awesome_outlined,
        text: l.memoriesScreenNoneYet,
      );
    } else {
      body = GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          mainAxisSpacing: 14,
          crossAxisSpacing: 12,
          childAspectRatio: 0.7,
        ),
        itemCount: memories.length,
        itemBuilder: (context, index) {
          final memory = memories[index];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => StoryScreen(
                  secondsPerPicture:
                      ref
                          .read(accountPreferencesProvider)
                          .value
                          ?.memorySeconds ??
                      4,
                  session: _session,
                  memory: memory,
                  title: memoryTitle(memory, now),
                ),
              ),
            ),
            child: StoryTile(
              session: _session,
              memory: memory,
              title: memoryTitle(memory, now),
              subtitle: l.memoriesScreenItems(memory.items.length),
            ),
          );
        },
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.memoriesScreenTitle)),
      body: body,
    );
  }
}

/// Plays a memory picture by picture, and can turn it into a video saved on the phone.
class StoryScreen extends StatefulWidget {
  const StoryScreen({
    this.secondsPerPicture = 4,
    super.key,
    required this.session,
    required this.memory,
    required this.title,
  });

  final Session session;
  final Memory memory;
  final String title;
  final int secondsPerPicture;

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  static const _exportPoll = Duration(seconds: 2);

  int _index = 0;
  Timer? _timer;
  bool _exporting = false;

  List<TimelineItem> get _items => widget.memory.items;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      Duration(seconds: widget.secondsPerPicture),
      (_) => _move(1),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _move(int step) => setState(() {
    _index = (_index + step + _items.length) % _items.length;
  });

  void _tell(String message) {
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final api = widget.session.api;
      var story = await api.createStoryExport(
        StoryRequest(
          title: widget.title,
          ids: [for (final item in _items) item.id],
        ),
      );
      while (story?.status == StoryExportStatusEnum.working) {
        await Future<void>.delayed(_exportPoll);
        story = await api.getStoryExport(story!.id);
      }
      if (story?.status != StoryExportStatusEnum.ready) {
        _tell(l.memoriesScreenVideoFailed);
        return;
      }
      await _saveToPhone(story!.id);
      _tell(l.memoriesScreenVideoSaved);
    } on ApiException {
      _tell(l.memoriesScreenVideoFailed);
    } on IOException {
      _tell(l.memoriesScreenVideoNotSaved);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _saveToPhone(String id) async {
    final response = await http.get(
      Uri.parse('${widget.session.serverUrl}/api/stories/$id/video'),
      headers: widget.session.headers,
    );
    if (response.statusCode != HttpStatus.ok) {
      throw const HttpException('the video did not arrive');
    }
    final file = File('${Directory.systemTemp.path}/$id.mp4');
    await file.writeAsBytes(response.bodyBytes);
    try {
      await PhotoManager.editor.saveVideo(file, title: '${widget.title}.mp4');
    } finally {
      await file.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _items[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        actions: [
          _exporting
              ? Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Palette.gold,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _export,
                  child: Text(l.memoriesScreenMakeVideo),
                ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_index + 1) / _items.length,
            color: Palette.gold,
            backgroundColor: Colors.white24,
          ),
          Expanded(
            child: GestureDetector(
              onTapUp: (details) => _move(
                details.localPosition.dx < MediaQuery.sizeOf(context).width / 2
                    ? -1
                    : 1,
              ),
              child: SizedBox.expand(
                child: AssetPicture(
                  key: ValueKey(item.id),
                  session: widget.session,
                  id: item.id,
                  large: true,
                  fit: BoxFit.contain,
                  error: Icon(Icons.broken_image_outlined, color: Palette.dim),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
