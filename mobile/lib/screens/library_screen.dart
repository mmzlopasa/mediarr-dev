import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

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
        AppHeader(title: l.libraryScreenTitle),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 110),
            children: [
              OrganizeLinks(
                leading: [
                  (
                    Icons.explore_outlined,
                    l.libraryScreenExplore,
                    const ExploreScreen(),
                  ),
                  (
                    Icons.people_outline,
                    l.libraryScreenShared,
                    const SharedScreen(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
