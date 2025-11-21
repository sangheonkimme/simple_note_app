import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:novita/src/data/models/note.dart';
import 'package:novita/src/data/models/folder.dart';
import 'package:novita/src/data/repositories/sync_repository.dart';

class SyncService {
  final Isar isar;
  final SyncRepository syncRepository;

  SyncService(this.isar, this.syncRepository);

  Future<void> sync() async {
    debugPrint('Starting sync...');
    try {
      await _pushChanges();
      await _pullChanges();
      debugPrint('Sync completed successfully.');
    } catch (e) {
      debugPrint('Sync failed: $e');
    }
  }

  Future<void> _pushChanges() async {
    final dirtyNotes = await isar.notes.filter().isDirtyEqualTo(true).findAll();
    if (dirtyNotes.isNotEmpty) {
      await syncRepository.pushNotes(dirtyNotes);
      await isar.writeTxn(() async {
        for (var note in dirtyNotes) {
          note.isDirty = false;
          note.lastSyncedAt = DateTime.now();
          await isar.notes.put(note);
        }
      });
    }

    final dirtyFolders = await isar.folders.filter().isDirtyEqualTo(true).findAll();
    if (dirtyFolders.isNotEmpty) {
      await syncRepository.pushFolders(dirtyFolders);
      await isar.writeTxn(() async {
        for (var folder in dirtyFolders) {
          folder.isDirty = false;
          folder.lastSyncedAt = DateTime.now();
          await isar.folders.put(folder);
        }
      });
    }
  }

  Future<void> _pullChanges() async {
    // Mock pull implementation - currently does nothing as MockRepository returns empty lists
    final remoteNotes = await syncRepository.pullNotes(null);
    if (remoteNotes.isNotEmpty) {
       // Implement merge logic here
    }
  }
}
