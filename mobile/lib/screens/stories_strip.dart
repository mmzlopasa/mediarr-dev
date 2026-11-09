import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../l10n/l10n.dart';
import '../services/account_preferences.dart';
import '../services/session.dart';
import 'asset_picture.dart';
import 'memories_screen.dart';

String storyLabel(Memory memory, int thisYear) {
  if (memory.kind == MemoryKindEnum.week) return l.storiesStripLastWeek;
  final year = memory.year;
  if (memory.kind != MemoryKindEnum.onThisDay || year == null) {
    return memoryTitle(memory, DateTime(thisYear));
  }
  final years = thisYear - year;
  return l.storiesStripYearsAgo(years);
}

/// Memories above the timeline as stories: a row of tall cards, each playing as a story when
/// tapped, as on the web. Nothing shows when there are none.
class StoriesStrip extends ConsumerStatefulWidget {
  const StoriesStrip({super.key, required this.session});

  final Session session;

  @override
  ConsumerState<StoriesStrip> createState() => _StoriesStripState();
}

class _StoriesStripState extends ConsumerState<StoriesStrip> {
  List<Memory> _memories = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final memories = await widget.session.api.listMemories(
        date: localToday(DateTime.now()),
        smart: true,
      );
      if (!mounted) return;
      setState(() {
        _memories = [
          for (final memory in memories ?? const <Memory>[])
            if (memory.items.isNotEmpty) memory,
        ];
      });
    } on ApiException {
      // The timeline below reports a server that does not answer.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_memories.isEmpty) return const SizedBox.shrink();
    final now = DateTime.now();
    final thisYear = now.year;
    return SizedBox(
      height: 172,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
        itemCount: _memories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final memory = _memories[index];
          final count = memory.items.length;
          return Semantics(
            button: true,
            label: storyLabel(memory, thisYear),
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) => StoryScreen(
                    secondsPerPicture:
                        ref
                            .read(accountPreferencesProvider)
                            .value
                            ?.memorySeconds ??
                        4,
                    session: widget.session,
                    memory: memory,
                    title: memoryTitle(memory, now),
                    onHidden: () => setState(() {
                      _memories = [
                        for (final other in _memories)
                          if (!identical(other, memory)) other,
                      ];
                    }),
                  ),
                ),
              ),
              child: SizedBox(
                width: 112,
                child: StoryTile(
                  session: widget.session,
                  memory: memory,
                  title: storyLabel(memory, thisYear),
                  subtitle: l.storiesStripItems(count),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A memory as a tall card: its first picture, a shade at the foot and the words on it.
class StoryTile extends StatelessWidget {
  const StoryTile({
    super.key,
    required this.session,
    required this.memory,
    required this.title,
    required this.subtitle,
  });

  final Session session;
  final Memory memory;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: Stack(
      fit: StackFit.expand,
      children: [
        AssetPicture(
          session: session,
          id: memory.items.first.id,
          fit: BoxFit.cover,
          error: const SizedBox.shrink(),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(0, 0.1),
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xB8000000)],
            ),
          ),
        ),
        Positioned(
          left: 10,
          right: 10,
          bottom: 9,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 2,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xD1FFFFFF),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
