import 'package:isar/isar.dart';
import 'package:novita/src/data/models/note.dart';

part 'folder.g.dart';

@collection
class Folder {
  Id id = Isar.autoIncrement;

  @Index()
  String? remoteId;

  DateTime? lastSyncedAt;

  bool isDirty = false;

  DateTime? deletedAt;

  late String name;

  bool isSystem = false;

  int? sortOrder;

  DateTime createdAt = DateTime.now();

  DateTime updatedAt = DateTime.now();

  @Backlink(to: 'folder')
  final notes = IsarLinks<Note>();
}
