import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:novita/src/data/models/folder.dart';
import 'package:novita/src/data/models/note.dart';
import 'package:novita/src/data/repositories/folder_repository.dart';
import 'package:novita/src/data/repositories/note_repository.dart';
import 'package:novita/src/data/services/analytics_service.dart';
import 'package:novita/src/data/services/attachment_service.dart';
import 'package:novita/src/data/services/storage_service.dart';
import 'package:novita/src/data/services/sync_service.dart';
import 'package:novita/src/data/repositories/sync_repository.dart';

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

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return MockSyncRepository();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final isar = ref.watch(isarProvider);
  final syncRepository = ref.watch(syncRepositoryProvider);
  return SyncService(isar, syncRepository);
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




// --- Data Stream Providers ---
final allNotesStreamProvider = StreamProvider<List<Note>>((ref) {
  final noteRepository = ref.watch(noteRepositoryProvider);
  return noteRepository.watchAllNotes();
});

final pinnedNotesStreamProvider = StreamProvider<List<Note>>((ref) {
  final noteRepository = ref.watch(noteRepositoryProvider);
  return noteRepository.watchPinnedNotes();
});

final notesInFolderProvider = StreamProvider.family<List<Note>, int>((ref, folderId) {
  final noteRepository = ref.watch(noteRepositoryProvider);
  return noteRepository.watchNotesInFolder(folderId);
});

final foldersStreamProvider = StreamProvider<List<Folder>>((ref) {
  final folderRepository = ref.watch(folderRepositoryProvider);
  return folderRepository.watchAllFolders();
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
