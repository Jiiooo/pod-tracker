import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/pod_provider.dart';
import 'add_config_screen.dart';
import 'info_screen.dart';
import 'profile_screen.dart';
import 'views/archive_view.dart';
import 'views/stats_view.dart';
import 'views/tracker_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _trackerIndex = 2;
  int _selectedIndex = _trackerIndex;

  static const _pages = <Widget>[
    StatsView(),
    ArchiveView(),
    TrackerView(),
    InfoScreen(),
    ProfileScreen(),
  ];
  static const _titles = [
    'Statistik',
    'Arsip',
    'Tracker',
    'Panduan',
    'Profil',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PodProvider>().syncData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 72,
        title: Text(_titles[_selectedIndex],
            style: Theme.of(context)
                .textTheme
                .displayMedium
                ?.copyWith(fontSize: 28)),
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      floatingActionButton: _selectedIndex == _trackerIndex
          ? FloatingActionButton(
              tooltip: 'Tambah pod',
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AddConfigScreen()));
              },
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) {
          if (i == _selectedIndex) return;
          HapticFeedback.selectionClick();
          setState(() => _selectedIndex = i);
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights_rounded),
              label: 'Statistik'),
          NavigationDestination(
              icon: Icon(Icons.archive_outlined),
              selectedIcon: Icon(Icons.archive_rounded),
              label: 'Arsip'),
          NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt_rounded),
              label: 'Tracker'),
          NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'Panduan'),
          NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profil'),
        ],
      ),
    );
  }
}
