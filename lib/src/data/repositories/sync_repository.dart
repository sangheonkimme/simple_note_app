import 'package:novita/src/data/models/note.dart';
import 'package:novita/src/data/models/folder.dart';

abstract class SyncRepository {
  /// Get changes from server since the given timestamp
  Future<SyncResult> getChangesSince({
    required String since,
    int limit = 200,
  });

  /// Get latest timestamp from server
  Future<String?> getLatestTimestamp();

  /// Folder operations
  Future<Folder> createFolder(Folder folder);
  Future<Folder> updateFolder(Folder folder);
  Future<void> deleteFolder(String remoteId);

  /// Note operations
  Future<Note> createNote(Note note);
  Future<Note> updateNote(Note note);
  Future<void> deleteNote(String remoteId);
}

/// Sync result from server
class SyncResult {
  final List<Note> notes;
  final List<String> deletedNoteIds;
  final List<Folder> folders;
  final List<String> deletedFolderIds;
  final String? lastSyncedAt;

  const SyncResult({
    required this.notes,
    required this.deletedNoteIds,
    required this.folders,
    required this.deletedFolderIds,
    this.lastSyncedAt,
  });

  factory SyncResult.fromJson(Map<String, dynamic> json) {
    return SyncResult(
      notes: (json['notes'] as List<dynamic>?)
              ?.map((e) => Note.fromServerJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      deletedNoteIds: (json['deletedNoteIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      folders: (json['folders'] as List<dynamic>?)
              ?.map((e) => Folder.fromServerJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      deletedFolderIds: (json['deletedFolderIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      lastSyncedAt: json['lastSyncedAt'] as String?,
    );
  }
}
