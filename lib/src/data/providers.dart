import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:simple_note/src/data/datasources/local/isar_service.dart';
import 'package:simple_note/src/data/models/folder.dart';
import 'package:simple_note/src/data/models/note.dart';
import 'package:simple_note/src/data/models/tag.dart';
import 'package:simple_note/src/data/repositories/folder_repository.dart';
import 'package:simple_note/src/data/repositories/note_repository.dart';
import 'package:simple_note/src/data/repositories/tag_repository.dart';
import 'package:simple_note/src/data/services/attachment_service.dart';

// Provider for the IsarService class
final isarServiceProvider = Provider<IsarService>((ref) {
  return IsarService();
});

// Provider for the Isar instance itself
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('isarProvider was not overridden');
});

// --- Service Providers ---
final attachmentServiceProvider = Provider<AttachmentService>((ref) {
  return AttachmentService();
});

// --- Note Providers ---
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final isar = ref.watch(isarProvider);
  final attachmentService = ref.watch(attachmentServiceProvider);
  return NoteRepository(isar, attachmentService);
});

final notesStreamProvider = StreamProvider<List<Note>>((ref) {
  final noteRepository = ref.watch(noteRepositoryProvider);
  return noteRepository.watchAllNotes();
});

final notesInFolderProvider = StreamProvider.family<List<Note>, int>((ref, folderId) {
  final noteRepository = ref.watch(noteRepositoryProvider);
  return noteRepository.watchNotesInFolder(folderId);
});

// --- Folder Providers ---
final folderRepositoryProvider = Provider<FolderRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return FolderRepository(isar);
});

final foldersStreamProvider = StreamProvider<List<Folder>>((ref) {
  final folderRepository = ref.watch(folderRepositoryProvider);
  return folderRepository.watchAllFolders();
});

// --- Tag Providers ---
final tagRepositoryProvider = Provider<TagRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return TagRepository(isar);
});

final tagsStreamProvider = StreamProvider<List<Tag>>((ref) {
  final tagRepository = ref.watch(tagRepositoryProvider);
  return tagRepository.watchAllTags();
});

// --- Search Providers ---
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultProvider = FutureProvider<List<Note>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) {
    return [];
  }
  final noteRepository = ref.watch(noteRepositoryProvider);
  return await noteRepository.searchNotes(query);
});
