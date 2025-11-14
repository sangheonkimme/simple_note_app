import 'package:isar/isar.dart';

part 'checklist_item.g.dart';

@embedded
class ChecklistItem {
  String text = ''; // Initialize with an empty string to prevent LateInitializationError

  bool done = false;
  
  int? order;
}
