import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:novita/src/data/models/note.dart';
import 'package:novita/src/data/models/tag.dart';
import 'package:novita/src/data/repositories/note_repository.dart';
import 'package:novita/src/data/services/attachment_service.dart';

import '../test_helpers.dart';

void main() {
  group('NoteRepository Tests', () {
    late Isar isar;
    late NoteRepository noteRepository;

    setUp(() async {
      isar = await setupTestIsar();
      // For unit tests, we can mock the attachment service if it involves file system operations.
      // However, for this integration-style test, we'll use the real one and ensure cleanup.
      noteRepository = NoteRepository(isar, AttachmentService());
    });

    tearDown(() async {
      await isar.writeTxn(() async => await isar.clear());
      await isar.close();
    });

    test('should save a new note successfully', () async {
      // Arrange
      final note = Note()..title = 'Test Note'..body = 'This is a test.';

      // Act
      await noteRepository.saveNote(note, [], []);
      final savedNote = await isar.notes.get(note.id);

      // Assert
      expect(savedNote, isNotNull);
      expect(savedNote!.title, 'Test Note');
    });

    test('should find a note by title query', () async {
      // Arrange
      final note1 = Note()..title = 'First Note'..body = 'Content one';
      final note2 = Note()..title = 'Second Note'..body = 'Content two';
      await noteRepository.saveNote(note1, [], []);
      await noteRepository.saveNote(note2, [], []);

      // Act
      final results = await noteRepository.searchNotes('First');

      // Assert
      expect(results.length, 1);
      expect(results.first.title, 'First Note');
    });

    test('should find notes by body content query', () async {
      // Arrange
      final note1 = Note()..title = 'Note A'..body = 'This contains a keyword';
      final note2 = Note()..title = 'Note B'..body = 'Another different content';
      await noteRepository.saveNote(note1, [], []);
      await noteRepository.saveNote(note2, [], []);

      // Act
      final results = await noteRepository.searchNotes('keyword');

      // Assert
      expect(results.length, 1);
      expect(results.first.title, 'Note A');
    });

    test('should find a note by tag query', () async {
      // Arrange
      final tag = Tag()..name = 'important';
      final note = Note()..title = 'Tagged Note';
      await noteRepository.saveNote(note, [], [], tags: [tag]);
      
      // Act
      final results = await noteRepository.searchNotes('important');

      // Assert
      expect(results.length, 1);
      expect(results.first.title, 'Tagged Note');
    });

    test('should delete a note successfully', () async {
      // Arrange
      final note = Note()..title = 'To be deleted';
      await noteRepository.saveNote(note, [], []);
      final noteId = note.id;

      // Act
      await noteRepository.deleteNote(noteId);
      final deletedNote = await isar.notes.get(noteId);

      // Assert
      expect(deletedNote, isNull);
    });
  });
}
