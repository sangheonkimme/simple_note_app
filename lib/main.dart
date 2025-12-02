import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novita/src/data/datasources/local/isar_service.dart';
import 'package:novita/src/data/providers.dart';
import 'package:novita/src/features/common/presentation/app_theme.dart';
import 'package:novita/src/features/scaffold/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Isar database
  final isar = await IsarService.init();

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
      ],
      child: const NovitaApp(),
    ),
  );
}

class NovitaApp extends ConsumerStatefulWidget {
  const NovitaApp({super.key});

  @override
  ConsumerState<NovitaApp> createState() => _NovitaAppState();
}

class _NovitaAppState extends ConsumerState<NovitaApp> {
  @override
  void initState() {
    super.initState();
    // Create default folders on first launch
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await ref.read(folderRepositoryProvider).createDefaultFolders();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Novita',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainScaffold(),
    );
  }
}
