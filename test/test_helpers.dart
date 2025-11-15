import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:novita/src/data/models/attachment.dart';
import 'package:novita/src/data/models/folder.dart';
import 'package:novita/src/data/models/note.dart';
import 'package:novita/src/data/models/tag.dart';

Future<Isar> setupTestIsar() async {
  await Isar.initializeIsarCore(download: true);
  final isar = await Isar.open(
    [NoteSchema, FolderSchema, TagSchema, AttachmentSchema],
    directory: 'test/isar_test_data',
    // Use a unique name for each test run to avoid conflicts
    name: DateTime.now().millisecondsSinceEpoch.toString(),
  );
  return isar;
}
