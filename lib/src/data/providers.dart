import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:simple_note/src/data/datasources/local/isar_service.dart';
import 'package:simple_note/src/data/models/note.dart';
import 'package:simple_note/src/data/repositories/note_repository.dart';

// Provider for the IsarService class
final isarServiceProvider = Provider<IsarService>((ref) {
  return IsarService();
});

// Provider for the Isar instance itself
// This is overridden in main.dart after the DB is opened
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('isarProvider was not overridden');
});

// Provider for the NoteRepository
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return NoteRepository(isar);
});

// StreamProvider to watch all notes
final notesStreamProvider = StreamProvider<List<Note>>((ref) {
  final noteRepository = ref.watch(noteRepositoryProvider);
  return noteRepository.watchAllNotes();
});
