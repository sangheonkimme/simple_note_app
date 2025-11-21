import 'package:flutter/foundation.dart';
import 'package:novita/src/data/models/note.dart';
import 'package:novita/src/data/models/folder.dart';

abstract class SyncRepository {
  Future<List<Note>> pullNotes(DateTime? lastSyncedAt);
  Future<List<Folder>> pullFolders(DateTime? lastSyncedAt);

  Future<void> pushNotes(List<Note> notes);
  Future<void> pushFolders(List<Folder> folders);
}

class MockSyncRepository implements SyncRepository {
  @override
  Future<List<Note>> pullNotes(DateTime? lastSyncedAt) async {
    await Future.delayed(const Duration(seconds: 1));
    return [];
  }

  @override
  Future<List<Folder>> pullFolders(DateTime? lastSyncedAt) async {
    await Future.delayed(const Duration(seconds: 1));
    return [];
  }

  @override
  Future<void> pushNotes(List<Note> notes) async {
    await Future.delayed(const Duration(seconds: 1));
    debugPrint('Pushed ${notes.length} notes');
  }

  @override
  Future<void> pushFolders(List<Folder> folders) async {
    await Future.delayed(const Duration(seconds: 1));
    debugPrint('Pushed ${folders.length} folders');
  }
}

