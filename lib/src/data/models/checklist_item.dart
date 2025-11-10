import 'package:isar/isar.dart';

part 'checklist_item.g.dart';

@embedded
class ChecklistItem {
  late String text;

  bool done = false;
  
  int? order;
}
