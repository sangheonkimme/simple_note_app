import 'package:isar/isar.dart';
import 'package:novita/src/data/models/folder.dart';
import 'package:novita/src/data/models/tag.dart';
import 'package:novita/src/data/models/checklist_item.dart';
import 'package:novita/src/data/models/attachment.dart';

part 'note.g.dart';

enum NoteType { text, checklist }

@collection
class Note {
  Id id = Isar.autoIncrement;

  late String title;

  String? body;

  @Enumerated(EnumType.name)
  NoteType type = NoteType.text;

  bool pinned = false;

  bool archived = false;

  DateTime? trashedAt;

  DateTime createdAt = DateTime.now();

  DateTime updatedAt = DateTime.now();

  final folder = IsarLink<Folder>();

  final tags = IsarLinks<Tag>();

  List<ChecklistItem> checklistItems = [];

  @Backlink(to: 'note')
  final attachments = IsarLinks<Attachment>();
}
