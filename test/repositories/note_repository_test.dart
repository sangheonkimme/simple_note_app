import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:novita/src/data/models/folder.dart';
import 'package:novita/src/data/models/note.dart';
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
    test('should create multiple notes in the same folder', () async {
      // Arrange
      final folder = Folder()..name = 'Test Folder';
      await isar.writeTxn(() async {
        await isar.folders.put(folder);
      });

      final note1 = Note()..title = 'Note 1';
      final note2 = Note()..title = 'Note 2';

      // Act
      await noteRepository.saveNote(note1, [], [], folder: folder);
      await noteRepository.saveNote(note2, [], [], folder: folder);

      // Assert
      final allNotes = await isar.notes.where().findAll();
      debugPrint('DEBUG TEST: Found ${allNotes.length} total notes in DB');
      for (var n in allNotes) {
        debugPrint('DEBUG TEST: Note ID: ${n.id}, Title: ${n.title}, Folder ID: ${n.folder.value?.id}, RemoteID: ${n.remoteId}');
      }

      final notesInFolder = await isar.notes
          .filter()
          .folder((q) => q.idEqualTo(folder.id))
          .findAll();
      
      debugPrint('DEBUG TEST: Found ${notesInFolder.length} notes in folder');
      for (var n in notesInFolder) {
        debugPrint('DEBUG TEST: Note ID: ${n.id}, Title: ${n.title}, Folder ID: ${n.folder.value?.id}');
      }

      expect(notesInFolder.length, 2);
      expect(notesInFolder.any((n) => n.title == 'Note 1'), isTrue);
      expect(notesInFolder.any((n) => n.title == 'Note 2'), isTrue);
    });
  });
}
