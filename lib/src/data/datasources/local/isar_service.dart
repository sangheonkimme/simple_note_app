import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:novita/src/data/models/attachment.dart';
import 'package:novita/src/data/models/folder.dart';
import 'package:novita/src/data/models/note.dart';

class IsarService {
  late final Future<Isar> db;

  IsarService() {
    db = openDB();
  }

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open(
        [NoteSchema, FolderSchema, AttachmentSchema],
        directory: dir.path,
        inspector: true, // Allows to inspect the DB from a browser
      );
    }
    return Future.value(Isar.getInstance());
  }
}
