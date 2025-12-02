import 'package:isar/isar.dart';
import 'package:novita/src/data/models/folder.dart';

class FolderRepository {
  final Isar _isar;

  FolderRepository(this._isar);

  /// Watch all folders (excluding deleted)
  Stream<List<Folder>> watchAllFolders() {
    return _isar.folders
        .filter()
        .deletedAtIsNull()
        .sortBySortOrder()
        .watch(fireImmediately: true);
  }

  /// Get all folders
  Future<List<Folder>> getAllFolders() async {
    return _isar.folders
        .filter()
        .deletedAtIsNull()
        .sortBySortOrder()
        .findAll();
  }

  /// Get folder by ID
  Future<Folder?> getFolderById(int id) async {
    return _isar.folders.get(id);
  }

  /// Get folder by remote ID
  Future<Folder?> getFolderByRemoteId(String remoteId) async {
    return _isar.folders.filter().remoteIdEqualTo(remoteId).findFirst();
  }

  /// Save folder
  Future<void> saveFolder(Folder folder) async {
    await _isar.writeTxn(() async {
      folder.isDirty = true;
      folder.updatedAt = DateTime.now();
      await _isar.folders.put(folder);
    });
  }

  /// Delete folder (soft delete)
  Future<void> softDeleteFolder(int folderId) async {
    await _isar.writeTxn(() async {
      final folder = await _isar.folders.get(folderId);
      if (folder != null) {
        folder.deletedAt = DateTime.now();
        folder.isDirty = true;
        await _isar.folders.put(folder);
      }
    });
  }

  /// Permanently delete folder
  Future<void> permanentlyDeleteFolder(int folderId) async {
    await _isar.writeTxn(() async {
      await _isar.folders.delete(folderId);
    });
  }

  /// Get dirty folders for sync
  Future<List<Folder>> getDirtyFolders() async {
    return _isar.folders.filter().isDirtyEqualTo(true).findAll();
  }

  /// Mark folder as synced
  Future<void> markFolderSynced(int folderId, String remoteId) async {
    await _isar.writeTxn(() async {
      final folder = await _isar.folders.get(folderId);
      if (folder != null) {
        folder.remoteId = remoteId;
        folder.isDirty = false;
        folder.lastSyncedAt = DateTime.now();
        await _isar.folders.put(folder);
      }
    });
  }

  /// Upsert folder from server
  Future<void> upsertFromServer(Folder serverFolder) async {
    await _isar.writeTxn(() async {
      final existingFolder = await _isar.folders
          .filter()
          .remoteIdEqualTo(serverFolder.remoteId)
          .findFirst();

      if (existingFolder != null) {
        serverFolder.id = existingFolder.id;
      }
      await _isar.folders.put(serverFolder);
    });
  }

  /// Create default folders if none exist
  Future<void> createDefaultFolders() async {
    final folders = await getAllFolders();
    if (folders.isEmpty) {
      await _isar.writeTxn(() async {
        final defaultFolders = [
          Folder()..name = '개인'..sortOrder = 0,
          Folder()..name = '업무'..sortOrder = 1,
          Folder()..name = '학업'..sortOrder = 2,
          Folder()..name = '기타'..sortOrder = 3,
        ];
        await _isar.folders.putAll(defaultFolders);
      });
    }
  }
}
