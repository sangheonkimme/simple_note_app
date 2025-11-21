import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:novita/src/data/models/attachment.dart';
import 'package:novita/src/data/models/folder.dart';
import 'package:novita/src/data/models/note.dart';

Future<Isar> setupTestIsar() async {
  await Isar.initializeIsarCore(download: true);
  final dir = await Directory.systemTemp.createTemp();
  final isar = await Isar.open(
    [NoteSchema, FolderSchema, AttachmentSchema],
    directory: dir.path,
    // Use a unique name for each test run to avoid conflicts
    name: DateTime.now().millisecondsSinceEpoch.toString(),
  );
  return isar;
}
