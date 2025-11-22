import 'package:isar/isar.dart';
import 'package:novita/src/data/models/attachment.dart';
import 'package:novita/src/data/models/folder.dart';
import 'package:novita/src/data/models/note.dart';
import 'package:novita/src/data/services/attachment_service.dart';

class NoteRepository {
  final Isar isar;
  final AttachmentService attachmentService;

  NoteRepository(this.isar, this.attachmentService);

  Future<void> saveNote(
    Note note,
    List<Attachment> attachmentsToSave,
    List<Attachment> attachmentsToDelete,
      {Folder? folder}) async {
    await isar.writeTxn(() async {
      // Delete attachments marked for deletion
      for (var attachment in attachmentsToDelete) {
        await isar.attachments.delete(attachment.id);
        await attachmentService.deleteAttachmentFile(attachment);
      }
      
      // Save note
      note.isDirty = true;
      await isar.notes.put(note);

      // Link to folder
      if (folder != null) {
        // Reload folder to ensure it's attached to the current transaction/Isar instance
        final folderToLink = await isar.folders.get(folder.id);
        if (folderToLink != null) {
          note.folder.value = folderToLink;
          await note.folder.save();
        }
      }
      
      // Save new attachments and link to note
      await isar.attachments.putAll(attachmentsToSave);
      note.attachments.addAll(attachmentsToSave);
      await note.attachments.save();
    });
  }

  Future<List<Note>> getAllNotes() async {
    return await isar.notes.where().filter().deletedAtIsNull().sortByUpdatedAtDesc().findAll();
  }

  Stream<List<Note>> watchAllNotes() {
    return isar.notes.where().filter().deletedAtIsNull().sortByUpdatedAtDesc().watch(fireImmediately: true);
  }

  Stream<List<Note>> watchPinnedNotes() {
    return isar.notes
        .where()
        .filter()
        .pinnedEqualTo(true)
        .deletedAtIsNull()
        .sortByUpdatedAtDesc()
        .watch(fireImmediately: true);
  }

  Stream<List<Note>> watchNotesInFolder(int folderId) {
    return isar.notes
        .filter()
        .deletedAtIsNull()
        .folder((q) => q.idEqualTo(folderId))
        .sortByUpdatedAtDesc()
        .watch(fireImmediately: true);
  }

  Future<List<Note>> searchNotes(String query) async {
    if (query.isEmpty) {
      return [];
    }
    return await isar.notes
        .filter()
        .deletedAtIsNull()
        .group((q) => q
            .titleContains(query, caseSensitive: false)
            .or()
            .bodyContains(query, caseSensitive: false))
        .sortByUpdatedAtDesc()
        .findAll();
  }

  Future<void> togglePinStatus(int id) async {
    await isar.writeTxn(() async {
      final note = await isar.notes.get(id);
      if (note != null) {
        note.pinned = !note.pinned;
        note.isDirty = true;
        note.updatedAt = DateTime.now();
        await isar.notes.put(note);
      }
    });
  }

  Future<void> deleteNote(int id) async {
    await isar.writeTxn(() async {
      final note = await isar.notes.get(id);
      if (note != null) {
        note.deletedAt = DateTime.now();
        note.isDirty = true;
        await isar.notes.put(note);
      }
    });
  }
}
