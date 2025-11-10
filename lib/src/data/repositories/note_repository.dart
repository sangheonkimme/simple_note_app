import 'package:isar/isar.dart';
import 'package:simple_note/src/data/models/note.dart';

class NoteRepository {
  final Isar isar;

  NoteRepository(this.isar);

  Future<void> saveNote(Note note) async {
    await isar.writeTxn(() async {
      await isar.notes.put(note);
    });
  }

  Future<List<Note>> getAllNotes() async {
    return await isar.notes.where().sortByUpdatedAtDesc().findAll();
  }

  Stream<List<Note>> watchAllNotes() {
    return isar.notes.where().sortByUpdatedAtDesc().watch(fireImmediately: true);
  }

  Future<void> deleteNote(int id) async {
    await isar.writeTxn(() async {
      await isar.notes.delete(id);
    });
  }
}
