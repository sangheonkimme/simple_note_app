import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_note/src/data/providers.dart';
import 'package:simple_note/src/features/notes/presentation/note_editor_screen.dart';
import 'package:simple_note/src/features/search/presentation/search_screen.dart';
import 'package:simple_note/src/features/settings/presentation/settings_screen.dart';
import 'package:simple_note/src/features/notes/presentation/home_screen.dart';

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
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NoteEditorScreen(),
            ),
          );
        },
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(icon: Icon(Icons.home_filled, color: _selectedIndex == 0 ? Theme.of(context).colorScheme.primary : Colors.grey), onPressed: () => _onItemTapped(0)),
            IconButton(icon: Icon(Icons.search, color: _selectedIndex == 1 ? Theme.of(context).colorScheme.primary : Colors.grey), onPressed: () => _onItemTapped(1)),
            const SizedBox(width: 40), // The space for the FAB
            IconButton(icon: Icon(Icons.list_alt_outlined, color: _selectedIndex == 2 ? Theme.of(context).colorScheme.primary : Colors.grey), onPressed: () => _onItemTapped(2)),
            IconButton(icon: Icon(Icons.settings_outlined, color: _selectedIndex == 3 ? Theme.of(context).colorScheme.primary : Colors.grey), onPressed: () => _onItemTapped(3)),
          ],
        ),
      ),
    );
  }
}
