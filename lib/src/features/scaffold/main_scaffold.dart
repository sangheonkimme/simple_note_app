import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novita/src/data/providers.dart';
import 'package:novita/src/features/board/presentation/board_screen.dart';
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

  // Screens displayed for each tab
  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const SearchScreen(),
    const BoardScreen(),
    const SettingsScreen(),
  ];

  // Screen names for analytics, matching the order of destinations
  static const List<String> _screenNames = <String>[
    'Home',
    'Search',
    'Board',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    ref.read(analyticsServiceProvider).logScreenView(_screenNames[0]);
  }

  void _onItemTapped(int index) {
    // The NavigationBar has 4 destinations, so the index will be 0, 1, 2, or 3.
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    ref.read(analyticsServiceProvider).logScreenView(_screenNames[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use IndexedStack to keep the state of each screen
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      floatingActionButton: Container(
        height: 72,
        width: 72,
        margin: const EdgeInsets.only(bottom: 20),
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
                color: Theme.of(context).colorScheme.primary.withAlpha((255 * 0.4).round()),
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
              color: Colors.black.withAlpha((255 * 0.08).round()),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            // A custom implementation to handle the FAB gap
            child: _CustomNavBar(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Navigation Bar to handle the gap for the FAB
class _CustomNavBar extends StatelessWidget {
  const _CustomNavBar({required this.selectedIndex, required this.onItemTapped});

  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  @override
  Widget build(BuildContext context) {
    final destinations = <({IconData icon, IconData selectedIcon, String label})>[
      (icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.search_outlined, selectedIcon: Icons.search_rounded, label: 'Search'),
      (icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard_rounded, label: 'Board'),
      (icon: Icons.settings_outlined, selectedIcon: Icons.settings_rounded, label: 'Settings'),
    ];

    return Container(
      color: Theme.of(context).colorScheme.surface.withAlpha((255 * 0.85).round()),
      height: 76,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(destinations.length + 1, (index) {
          if (index == 2) {
            // This is the empty space for the FAB
            return const SizedBox(width: 48);
          }
          final itemIndex = index < 2 ? index : index - 1;
          final item = destinations[itemIndex];
          final isSelected = selectedIndex == itemIndex;
          return Expanded(
            child: InkWell(
              onTap: () => onItemTapped(itemIndex),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelected ? item.selectedIcon : item.icon,
                    color: isSelected ? const Color(0xFF6C4CF5) : Theme.of(context).iconTheme.color?.withAlpha((255 * 0.6).round()),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? const Color(0xFF6C4CF5) : Theme.of(context).textTheme.bodySmall?.color?.withAlpha((255 * 0.8).round()),
                        ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
