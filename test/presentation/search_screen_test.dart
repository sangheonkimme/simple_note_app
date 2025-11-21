import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:novita/src/data/models/note.dart';
import 'package:novita/src/data/providers.dart';
import 'package:novita/src/features/search/presentation/search_screen.dart';

import '../test_helpers.dart';

void main() {
  group('SearchScreen Widget Tests', () {
    late Isar isar;

    setUpAll(() async {
      isar = await setupTestIsar();

      // Prepare mock data
      await isar.writeTxn(() async {
        final note1 = Note()..title = 'Flutter Test'..body = 'Testing widgets in Flutter.';
        final note2 = Note()..title = 'Isar Database'..body = 'A fast database for Flutter.';
        await isar.notes.putAll([note1, note2]);
      });
    });

    tearDownAll(() async {
      await isar.close(deleteFromDisk: true);
    });

    testWidgets('should display initial message when query is empty', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [isarProvider.overrideWithValue(isar)],
          child: const MaterialApp(home: SearchScreen()),
        ),
      );

      // Assert
      expect(find.text('노트의 제목, 내용 또는\n태그를 검색하여 노트를 찾아보세요.'), findsOneWidget);
      expect(find.byType(GridView), findsNothing);
    });

    testWidgets('should display search results when a matching query is entered', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [isarProvider.overrideWithValue(isar)],
          child: const MaterialApp(home: SearchScreen()),
        ),
      );

      // Act
      await tester.enterText(find.byType(TextField), 'Flutter');
      await tester.pumpAndSettle(); // Wait for futures and animations

      // Assert
      expect(find.text('Flutter Test'), findsOneWidget);
      expect(find.text('Isar Database'), findsNothing);
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('should display no results message when query does not match', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [isarProvider.overrideWithValue(isar)],
          child: const MaterialApp(home: SearchScreen()),
        ),
      );

      // Act
      await tester.enterText(find.byType(TextField), 'nonexistent');
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('검색 결과가 없습니다.'), findsOneWidget);
      expect(find.byType(GridView), findsNothing);
    });
  });
}
