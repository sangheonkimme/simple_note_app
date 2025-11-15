import 'package:isar/isar.dart';
import 'package:novita/src/data/models/note.dart';

part 'tag.g.dart';

@collection
class Tag {
  Id id = Isar.autoIncrement;

  late String name;

  @Backlink(to: 'tags')
  final notes = IsarLinks<Note>();
}
