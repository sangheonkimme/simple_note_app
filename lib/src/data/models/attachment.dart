import 'package:isar/isar.dart';
import 'package:novita/src/data/models/note.dart';

part 'attachment.g.dart';

@collection
class Attachment {
  Id id = Isar.autoIncrement;

  late String filePath;
  
  late String mimeType;
  
  int? size;

  DateTime createdAt = DateTime.now();

  final note = IsarLink<Note>();
}
