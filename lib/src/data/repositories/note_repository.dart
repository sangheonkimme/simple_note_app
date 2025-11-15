import 'package:isar/isar.dart';
import 'package:novita/src/data/models/attachment.dart';
import 'package:novita/src/data/models/folder.dart';
import 'package:novita/src/data/models/note.dart';
import 'package:novita/src/data/models/tag.dart';
import 'package:novita/src/data/services/attachment_service.dart';

class NoteRepository {
  final Isar isar;
  final AttachmentService attachmentService;

  NoteRepository(this.isar, this.attachmentService);

  Future<void> saveNote(
    Note note,
    List<Attachment> attachmentsToSave,
    List<Attachment> attachmentsToDelete,
      {Folder? folder, List<Tag>? tags}) async {
    await isar.writeTxn(() async {
      // Delete attachments marked for deletion
      for (var attachment in attachmentsToDelete) {
        await isar.attachments.delete(attachment.id);
        await attachmentService.deleteAttachmentFile(attachment);
      }
      
      // Save note
      await isar.notes.put(note);

      // Link to folder
      if (folder != null) {
        note.folder.value = folder;
      }
      await note.folder.save();

      // Link to tags
      if (tags != null) {
        note.tags.clear();
        note.tags.addAll(tags);
      }
      await note.tags.save();
      
      // Save new attachments and link to note
      await isar.attachments.putAll(attachmentsToSave);
      note.attachments.addAll(attachmentsToSave);
      await note.attachments.save();
    });
  }

  Future<List<Note>> getAllNotes() async {
    return await isar.notes.where().sortByUpdatedAtDesc().findAll();
  }

  Stream<List<Note>> watchAllNotes() {
    return isar.notes.where().sortByUpdatedAtDesc().watch(fireImmediately: true);
  }

  Stream<List<Note>> watchNotesInFolder(int folderId) {
    return isar.notes
        .filter()
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
        .titleContains(query, caseSensitive: false)
        .or()
        .bodyContains(query, caseSensitive: false)
        .or()
        .tags((q) => q.nameContains(query, caseSensitive: false))
        .sortByUpdatedAtDesc()
        .findAll();
  }

  Future<void> deleteNote(int id) async {
    await isar.writeTxn(() async {
      final note = await isar.notes.get(id);
      if (note != null) {
        await note.attachments.load();
        for (var attachment in note.attachments) {
          await attachmentService.deleteAttachmentFile(attachment);
        }
      }
      await isar.notes.delete(id);
    });
  }
}
