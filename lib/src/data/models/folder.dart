import 'package:isar/isar.dart';
import 'package:simple_note/src/data/models/note.dart';

part 'folder.g.dart';

@collection
class Folder {
  Id id = Isar.autoIncrement;

  late String name;

  bool isSystem = false;

  int? sortOrder;

  DateTime createdAt = DateTime.now();

  DateTime updatedAt = DateTime.now();

  @Backlink(to: 'folder')
  final notes = IsarLinks<Note>();
}
