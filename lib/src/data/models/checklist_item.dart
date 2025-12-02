import 'package:isar/isar.dart';

part 'checklist_item.g.dart';

@embedded
class ChecklistItem {
  String content = '';

  bool isCompleted = false;

  int? order;

  /// Create from server JSON
  static ChecklistItem fromServerJson(Map<String, dynamic> json) {
    return ChecklistItem()
      ..content = json['content'] as String? ?? ''
      ..isCompleted = json['isCompleted'] as bool? ?? false
      ..order = json['order'] as int?;
  }

  /// Convert to server JSON
  Map<String, dynamic> toServerJson() {
    return {
      'content': content,
      'isCompleted': isCompleted,
      if (order != null) 'order': order,
    };
  }
}
