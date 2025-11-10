import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:simple_note/src/data/models/attachment.dart';
import 'package:simple_note/src/data/models/checklist_item.dart';
import 'package:simple_note/src/data/models/folder.dart';
import 'package:simple_note/src/data/models/note.dart';
import 'package:simple_note/src/data/models/tag.dart';

class IsarService {
  late final Future<Isar> db;

  IsarService() {
    db = openDB();
  }

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open(
        [NoteSchema, FolderSchema, TagSchema, AttachmentSchema],
        directory: dir.path,
        inspector: true, // Allows to inspect the DB from a browser
      );
    }
    return Future.value(Isar.getInstance());
  }
}
