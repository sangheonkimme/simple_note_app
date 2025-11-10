import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:simple_note/src/data/datasources/local/isar_service.dart';
import 'package:simple_note/src/data/providers.dart';
import 'package:simple_note/src/features/scaffold/main_scaffold.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isarService = IsarService();
  final isar = await isarService.db;

  final container = ProviderContainer(overrides: [
    isarProvider.overrideWithValue(isar),
  ]);

  await container.read(folderRepositoryProvider).createDefaultFolders();
  container.dispose();

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final seedColor = const Color(0xFF6C4CF5);

    return MaterialApp(
      title: 'Simple Note',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system, // Automatically switch based on system settings
      home: const MainScaffold(),
    );
  }
}
