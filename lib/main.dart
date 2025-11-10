import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_note/src/data/datasources/local/isar_service.dart';
import 'package:simple_note/src/data/providers.dart';
import 'package:simple_note/src/features/notes/presentation/home_screen.dart';

Future<void> main() async {
  // Ensure that Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Isar DB
  final isarService = IsarService();
  final isar = await isarService.db;

  runApp(
    ProviderScope(
      overrides: [
        // Override the isarProvider with the actual Isar instance
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
    return MaterialApp(
      title: 'Simple Note',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(), // 임시로 홈 화면을 시작 페이지로 설정
    );
  }
}
