import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/uploads.dart';
import '../theme.dart';
import 'account_screen.dart';
import 'timeline_screen.dart';
import 'upload_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final working = ref
        .watch(uploadsProvider)
        .where((task) => !task.finished)
        .length;
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [TimelineScreen(), UploadScreen(), AccountScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.photo_outlined),
            selectedIcon: Icon(Icons.photo, color: Palette.gold),
            label: 'Photos',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: working > 0,
              label: Text('$working'),
              child: const Icon(Icons.upload_outlined),
            ),
            selectedIcon: const Icon(Icons.upload, color: Palette.gold),
            label: 'Upload',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Palette.gold),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
