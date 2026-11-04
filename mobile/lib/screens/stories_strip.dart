import 'package:flutter/material.dart';
import 'package:mediarr_api/api.dart';

import '../services/session.dart';
import 'asset_picture.dart';
import 'memories_screen.dart';

String storyLabel(Memory memory, int thisYear) {
  final year = memory.year;
  if (year == null) return 'The last week';
  final years = thisYear - year;
  return years == 1 ? '1 year ago' : '$years years ago';
}

/// Memories above the timeline. Nothing shows when there are none.
class StoriesStrip extends StatefulWidget {
  const StoriesStrip({super.key, required this.session});

  final Session session;

  @override
  State<StoriesStrip> createState() => _StoriesStripState();
}

class _StoriesStripState extends State<StoriesStrip> {
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
    final thisYear = DateTime.now().year;
    return SizedBox(
      height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        itemCount: _memories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final memory = _memories[index];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const MemoriesScreen()),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 170,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AssetPicture(
                      session: widget.session,
                      id: memory.items.first.id,
                      fit: BoxFit.cover,
                      error: const SizedBox.shrink(),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.center,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black87],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      bottom: 8,
                      child: Text(
                        storyLabel(memory, thisYear),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
