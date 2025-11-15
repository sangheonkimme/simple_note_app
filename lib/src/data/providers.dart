import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:novita/src/data/datasources/local/isar_service.dart';
import 'package:novita/src/data/models/folder.dart';
import 'package:novita/src/data/models/note.dart';
import 'package:novita/src/data/models/tag.dart';
import 'package:novita/src/data/repositories/folder_repository.dart';
import 'package:novita/src/data/repositories/note_repository.dart';
import 'package:novita/src/data/repositories/tag_repository.dart';
import 'package:novita/src/data/services/analytics_service.dart';
import 'package:novita/src/data/services/attachment_service.dart';
import 'package:novita/src/data/services/storage_service.dart';

// --- Core Providers ---
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('isarProvider was not overridden');
});

// --- Service Providers ---
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

final attachmentServiceProvider = Provider<AttachmentService>((ref) {
  return AttachmentService();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  final isar = ref.watch(isarProvider);
  return StorageService(isar);
});

final storageInfoProvider = FutureProvider<StorageInfo>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return storageService.getStorageUsage();
});


// --- Repository Providers ---
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final isar = ref.watch(isarProvider);
  final attachmentService = ref.watch(attachmentServiceProvider);
  return NoteRepository(isar, attachmentService);
});

final folderRepositoryProvider = Provider<FolderRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return FolderRepository(isar);
});

final tagRepositoryProvider = Provider<TagRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return TagRepository(isar);
});


// --- Data Stream Providers ---
final notesStreamProvider = StreamProvider<List<Note>>((ref) {
  final noteRepository = ref.watch(noteRepositoryProvider);
  return noteRepository.watchAllNotes();
});

final notesInFolderProvider = StreamProvider.family<List<Note>, int>((ref, folderId) {
  final noteRepository = ref.watch(noteRepositoryProvider);
  return noteRepository.watchNotesInFolder(folderId);
});

final foldersStreamProvider = StreamProvider<List<Folder>>((ref) {
  final folderRepository = ref.watch(folderRepositoryProvider);
  return folderRepository.watchAllFolders();
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
