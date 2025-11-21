import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:novita/firebase_options.dart';
import 'package:novita/src/data/datasources/local/isar_service.dart';
import 'package:novita/src/data/providers.dart';
import 'package:novita/src/features/common/presentation/app_theme.dart';
import 'package:novita/src/features/scaffold/main_scaffold.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:novita/src/features/auth/data/auth_provider.dart';
import 'package:novita/src/features/auth/presentation/auth_screen.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set up Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };


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

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // Remove splash screen when auth state is determined
    if (authState is! AsyncLoading) {
      FlutterNativeSplash.remove();
    }

    return MaterialApp(
      title: 'Novita',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: authState.when(
        data: (isLoggedIn) => isLoggedIn ? const MainScaffold() : const AuthScreen(),
        error: (err, stack) => const AuthScreen(), // Fallback to auth screen on error
        loading: () => const SizedBox.shrink(), // Keep splash screen or show loader
      ),
    );
  }
}
