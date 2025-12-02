import 'package:isar/isar.dart';
import 'package:novita/src/data/models/note.dart';
import 'package:novita/src/data/models/folder.dart';
import 'package:novita/src/data/models/attachment.dart';
import 'package:novita/src/data/services/attachment_service.dart';

class NoteRepository {
  final Isar _isar;
  final AttachmentService _attachmentService;

  NoteRepository(this._isar, this._attachmentService);

  /// Watch all notes (excluding deleted)
  Stream<List<Note>> watchAllNotes() {
    return _isar.notes
        .filter()
        .deletedAtIsNull()
        .sortByUpdatedAtDesc()
        .watch(fireImmediately: true);
  }

  /// Watch pinned notes
  Stream<List<Note>> watchPinnedNotes() {
    return _isar.notes
        .filter()
        .deletedAtIsNull()
        .isPinnedEqualTo(true)
        .sortByUpdatedAtDesc()
        .watch(fireImmediately: true);
  }

  /// Watch notes in a specific folder
  Stream<List<Note>> watchNotesInFolder(int folderId) {
    return _isar.notes
        .filter()
        .deletedAtIsNull()
        .folder((q) => q.idEqualTo(folderId))
        .sortByUpdatedAtDesc()
        .watch(fireImmediately: true);
  }

  /// Watch favorite notes
  Stream<List<Note>> watchFavoriteNotes() {
    return _isar.notes
        .filter()
        .deletedAtIsNull()
        .isFavoriteEqualTo(true)
        .sortByUpdatedAtDesc()
        .watch(fireImmediately: true);
  }

  /// Watch archived notes
  Stream<List<Note>> watchArchivedNotes() {
    return _isar.notes
        .filter()
        .deletedAtIsNull()
        .isArchivedEqualTo(true)
        .sortByUpdatedAtDesc()
        .watch(fireImmediately: true);
  }

  /// Watch deleted notes (trash)
  Stream<List<Note>> watchDeletedNotes() {
    return _isar.notes
        .filter()
        .deletedAtIsNotNull()
        .sortByDeletedAtDesc()
        .watch(fireImmediately: true);
  }

  /// Get note by ID
  Future<Note?> getNoteById(int id) async {
    return _isar.notes.get(id);
  }

  /// Get note by remote ID
  Future<Note?> getNoteByRemoteId(String remoteId) async {
    return _isar.notes.filter().remoteIdEqualTo(remoteId).findFirst();
  }

  /// Search notes by title and content
  Future<List<Note>> searchNotes(String query) async {
    final lowerQuery = query.toLowerCase();
    return _isar.notes
        .filter()
        .deletedAtIsNull()
        .group((q) => q
            .titleContains(lowerQuery, caseSensitive: false)
            .or()
            .contentContains(lowerQuery, caseSensitive: false))
        .sortByUpdatedAtDesc()
        .findAll();
  }

  /// Save note with attachments
  Future<void> saveNote(
    Note note,
    List<Attachment> newAttachments,
    List<Attachment> deletedAttachments, {
    Folder? folder,
  }) async {
    await _isar.writeTxn(() async {
      // Mark as dirty for sync
      note.isDirty = true;
      note.updatedAt = DateTime.now();

      // Save note
      await _isar.notes.put(note);

      // Link folder
      if (folder != null) {
        note.folder.value = folder;
        await note.folder.save();
      }

      // Handle deleted attachments
      for (final attachment in deletedAttachments) {
        await _attachmentService.deleteAttachment(attachment);
        await _isar.attachments.delete(attachment.id);
      }

      // Handle new attachments
      for (final attachment in newAttachments) {
        attachment.note.value = note;
        await _isar.attachments.put(attachment);
        await attachment.note.save();
      }
    });
  }

  /// Toggle pin status
  Future<void> togglePinStatus(int noteId) async {
    await _isar.writeTxn(() async {
      final note = await _isar.notes.get(noteId);
      if (note != null) {
        note.isPinned = !note.isPinned;
        note.isDirty = true;
        note.updatedAt = DateTime.now();
        await _isar.notes.put(note);
      }
    });
  }

  /// Toggle favorite status
  Future<void> toggleFavoriteStatus(int noteId) async {
    await _isar.writeTxn(() async {
      final note = await _isar.notes.get(noteId);
      if (note != null) {
        note.isFavorite = !note.isFavorite;
        note.isDirty = true;
        note.updatedAt = DateTime.now();
        await _isar.notes.put(note);
      }
    });
  }

  /// Toggle archive status
  Future<void> toggleArchiveStatus(int noteId) async {
    await _isar.writeTxn(() async {
      final note = await _isar.notes.get(noteId);
      if (note != null) {
        note.isArchived = !note.isArchived;
        note.isDirty = true;
        note.updatedAt = DateTime.now();
        await _isar.notes.put(note);
      }
    });
  }

  /// Soft delete note (move to trash)
  Future<void> softDeleteNote(int noteId) async {
    await _isar.writeTxn(() async {
      final note = await _isar.notes.get(noteId);
      if (note != null) {
        note.deletedAt = DateTime.now();
        note.isDirty = true;
        await _isar.notes.put(note);
      }
    });
  }

  /// Restore note from trash
  Future<void> restoreNote(int noteId) async {
    await _isar.writeTxn(() async {
      final note = await _isar.notes.get(noteId);
      if (note != null) {
        note.deletedAt = null;
        note.isDirty = true;
        note.updatedAt = DateTime.now();
        await _isar.notes.put(note);
      }
    });
  }

  /// Permanently delete note
  Future<void> permanentlyDeleteNote(int noteId) async {
    await _isar.writeTxn(() async {
      final note = await _isar.notes.get(noteId);
      if (note != null) {
        // Delete attachments
        await note.attachments.load();
        for (final attachment in note.attachments) {
          await _attachmentService.deleteAttachment(attachment);
          await _isar.attachments.delete(attachment.id);
        }
        // Delete note
        await _isar.notes.delete(noteId);
      }
    });
  }

  /// Get dirty notes for sync
  Future<List<Note>> getDirtyNotes() async {
    return _isar.notes.filter().isDirtyEqualTo(true).findAll();
  }

  /// Mark note as synced
  Future<void> markNoteSynced(int noteId, String remoteId) async {
    await _isar.writeTxn(() async {
      final note = await _isar.notes.get(noteId);
      if (note != null) {
        note.remoteId = remoteId;
        note.isDirty = false;
        note.lastSyncedAt = DateTime.now();
        await _isar.notes.put(note);
      }
    });
  }

  /// Upsert note from server
  Future<void> upsertFromServer(Note serverNote) async {
    await _isar.writeTxn(() async {
      final existingNote = await _isar.notes
          .filter()
          .remoteIdEqualTo(serverNote.remoteId)
          .findFirst();

      if (existingNote != null) {
        // Update existing note
        serverNote.id = existingNote.id;
      }
      await _isar.notes.put(serverNote);
    });
  }
}
