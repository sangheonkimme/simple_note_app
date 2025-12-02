import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:novita/src/data/datasources/local/token_storage.dart';
import 'package:novita/src/data/models/note.dart';
import 'package:novita/src/data/models/folder.dart';
import 'package:novita/src/data/repositories/sync_repository.dart';

class SyncService {
  final Isar _isar;
  final SyncRepository _syncRepository;
  final TokenStorage _tokenStorage;

  SyncService(this._isar, this._syncRepository, this._tokenStorage);

  /// Perform full sync
  Future<void> sync() async {
    try {
      // Check if user is logged in
      final hasTokens = await _tokenStorage.hasValidTokens();
      if (!hasTokens) {
        debugPrint('Skipping sync: user not logged in');
        return;
      }

      // Get last sync timestamp
      final lastSyncedAt = await _tokenStorage.getLastSyncTimestamp() ??
          DateTime.now().subtract(const Duration(days: 365)).toIso8601String();

      // Push local changes first
      await _pushLocalChanges();

      // Then pull server changes
      await _pullServerChanges(lastSyncedAt);

      debugPrint('Sync completed successfully');
    } catch (e) {
      debugPrint('Sync failed: $e');
      rethrow;
    }
  }

  /// Push local changes to server
  Future<void> _pushLocalChanges() async {
    // Push dirty folders
    final dirtyFolders = await _isar.folders.filter().isDirtyEqualTo(true).findAll();
    for (final folder in dirtyFolders) {
      try {
        Folder serverFolder;
        if (folder.remoteId == null) {
          serverFolder = await _syncRepository.createFolder(folder);
        } else if (folder.deletedAt != null) {
          await _syncRepository.deleteFolder(folder.remoteId!);
          await _isar.writeTxn(() => _isar.folders.delete(folder.id));
          continue;
        } else {
          serverFolder = await _syncRepository.updateFolder(folder);
        }

        // Update local folder with server data
        await _isar.writeTxn(() async {
          folder.remoteId = serverFolder.remoteId;
          folder.isDirty = false;
          folder.lastSyncedAt = DateTime.now();
          await _isar.folders.put(folder);
        });
      } catch (e) {
        debugPrint('Failed to push folder ${folder.name}: $e');
      }
    }

    // Push dirty notes
    final dirtyNotes = await _isar.notes.filter().isDirtyEqualTo(true).findAll();
    for (final note in dirtyNotes) {
      try {
        Note serverNote;
        if (note.remoteId == null) {
          serverNote = await _syncRepository.createNote(note);
        } else if (note.deletedAt != null) {
          await _syncRepository.deleteNote(note.remoteId!);
          await _isar.writeTxn(() => _isar.notes.delete(note.id));
          continue;
        } else {
          serverNote = await _syncRepository.updateNote(note);
        }

        // Update local note with server data
        await _isar.writeTxn(() async {
          note.remoteId = serverNote.remoteId;
          note.isDirty = false;
          note.lastSyncedAt = DateTime.now();
          await _isar.notes.put(note);
        });
      } catch (e) {
        debugPrint('Failed to push note ${note.title}: $e');
      }
    }
  }

  /// Pull server changes to local
  Future<void> _pullServerChanges(String since) async {
    final result = await _syncRepository.getChangesSince(since: since);

    await _isar.writeTxn(() async {
      // Handle folders
      for (final serverFolder in result.folders) {
        final existingFolder = await _isar.folders
            .filter()
            .remoteIdEqualTo(serverFolder.remoteId)
            .findFirst();

        if (existingFolder != null) {
          serverFolder.id = existingFolder.id;
        }
        await _isar.folders.put(serverFolder);
      }

      // Handle deleted folders
      for (final deletedId in result.deletedFolderIds) {
        final folder = await _isar.folders
            .filter()
            .remoteIdEqualTo(deletedId)
            .findFirst();
        if (folder != null) {
          await _isar.folders.delete(folder.id);
        }
      }

      // Handle notes
      for (final serverNote in result.notes) {
        final existingNote = await _isar.notes
            .filter()
            .remoteIdEqualTo(serverNote.remoteId)
            .findFirst();

        if (existingNote != null) {
          serverNote.id = existingNote.id;
        }
        await _isar.notes.put(serverNote);
      }

      // Handle deleted notes
      for (final deletedId in result.deletedNoteIds) {
        final note = await _isar.notes
            .filter()
            .remoteIdEqualTo(deletedId)
            .findFirst();
        if (note != null) {
          await _isar.notes.delete(note.id);
        }
      }
    });

    // Save last sync timestamp
    if (result.lastSyncedAt != null) {
      await _tokenStorage.saveLastSyncTimestamp(result.lastSyncedAt!);
    }
  }
}
