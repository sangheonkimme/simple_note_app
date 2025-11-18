import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novita/src/data/providers.dart';
import 'package:novita/src/features/notes/presentation/note_editor_screen.dart';
import 'package:novita/src/features/search/presentation/search_screen.dart';
import 'package:novita/src/features/settings/presentation/settings_screen.dart';
import 'package:novita/src/features/notes/presentation/home_screen.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const SearchScreen(),
    const Scaffold(body: Center(child: Text('Coming Soon'))), // Placeholder for other screens
    const SettingsScreen(), // Use the new SettingsScreen
  ];

  // Screen names for analytics
  static const List<String> _screenNames = <String>[
    'Home',
    'Search',
    'Placeholder', // Or a more descriptive name
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    // Log initial screen view
    ref.read(analyticsServiceProvider).logScreenView(_screenNames[0]);
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return; // Avoid logging for the same screen

    setState(() {
      _selectedIndex = index;
    });

    // Log screen view event
    ref.read(analyticsServiceProvider).logScreenView(_screenNames[index]);
  }

  @override
  Widget build(BuildContext context) {
    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home_filled),
        label: '홈',
      ),
      NavigationDestination(
        icon: const Icon(Icons.search_outlined),
        selectedIcon: const Icon(Icons.search),
        label: '검색',
      ),
      NavigationDestination(
        icon: const Icon(Icons.dashboard_outlined),
        selectedIcon: const Icon(Icons.dashboard_customize_rounded),
        label: '보드',
      ),
      NavigationDestination(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings),
        label: '설정',
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      floatingActionButton: SizedBox(
        height: 68,
        width: 68,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 30),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NoteEditorScreen(),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: NavigationBar(
            height: 72,
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            destinations: destinations,
          ),
        ),
      ),
    );
  }
}
