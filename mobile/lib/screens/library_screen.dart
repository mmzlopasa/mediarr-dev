import 'package:flutter/material.dart';

import '../theme.dart';
import 'explore_screen.dart';
import 'app_header.dart';
import 'organize_screens.dart';
import 'shared_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Column(
      children: [
        const AppHeader(title: 'Library'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 110),
            children: [
              GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const RingIcon(Icons.explore_outlined),
                      title: const Text('Explore'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ExploreScreen(),
                        ),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const RingIcon(Icons.people_outline),
                      title: const Text('Shared'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SharedScreen(),
                        ),
                      ),
                    ),
                    const OrganizeLinks(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
