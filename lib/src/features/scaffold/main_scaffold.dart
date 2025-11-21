import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novita/src/data/providers.dart';
import 'package:novita/src/features/notes/presentation/note_editor_screen.dart';
import 'package:novita/src/features/search/presentation/search_screen.dart';
import 'package:novita/src/features/settings/presentation/settings_screen.dart';
import 'package:novita/src/features/notes/presentation/home_screen.dart';
// import 'package:novita/src/features/calendar/presentation/calendar_screen.dart';

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
    const SizedBox.shrink(), // Placeholder for FAB gap
    // const CalendarScreen(),
    const Scaffold(body: Center(child: Text('Coming Soon'))),
    const SettingsScreen(), // Use the new SettingsScreen
  ];

  // Screen names for analytics
  static const List<String> _screenNames = <String>[
    'Home',
    'Search',
    'Calendar',
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
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      floatingActionButton: Container(
        height: 72,
        width: 72,
        margin: const EdgeInsets.only(bottom: 20), // Adjust for custom nav bar height
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                const Color(0xFF8E72FF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 36),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: NavigationBar(
              height: 76,
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined,
                      color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.6)),
                  selectedIcon: const Icon(Icons.home_rounded, color: Color(0xFF6C4CF5)),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.search_outlined,
                      color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.6)),
                  selectedIcon: const Icon(Icons.search_rounded, color: Color(0xFF6C4CF5)),
                  label: 'Search',
                ),
                const SizedBox(width: 48), // Space for FAB
                NavigationDestination(
                  icon: Icon(Icons.calendar_today_outlined,
                      color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.6)),
                  selectedIcon:
                      const Icon(Icons.calendar_today_rounded, color: Color(0xFF6C4CF5)),
                  label: 'Calendar',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined,
                      color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.6)),
                  selectedIcon:
                      const Icon(Icons.settings_rounded, color: Color(0xFF6C4CF5)),
                  label: 'Settings',
                ),
              ],
              backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }
}
