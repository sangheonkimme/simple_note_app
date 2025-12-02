import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:novita/src/data/models/note.dart';
import 'package:novita/src/data/models/folder.dart';
import 'package:novita/src/data/models/attachment.dart';

class IsarService {
  static Isar? _isar;

  static Future<Isar> init() async {
    if (_isar != null) return _isar!;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [NoteSchema, FolderSchema, AttachmentSchema],
      directory: dir.path,
    );
    return _isar!;
  }

  static Isar get instance {
    if (_isar == null) {
      throw StateError('Isar has not been initialized. Call init() first.');
    }
    return _isar!;
  }

  static Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}
