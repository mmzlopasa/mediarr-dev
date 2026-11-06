import 'package:flutter/material.dart';

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
              const OrganizeLinks(
                leading: [
                  (Icons.explore_outlined, 'Explore', ExploreScreen()),
                  (Icons.people_outline, 'Shared', SharedScreen()),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
