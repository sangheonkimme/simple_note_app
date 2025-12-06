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

  String? color;

  int? sortOrder;

  DateTime createdAt = DateTime.now();

  DateTime updatedAt = DateTime.now();

  @Backlink(to: 'folder')
  final notes = IsarLinks<Note>();

  /// Convert to server JSON format for API requests
  Map<String, dynamic> toServerJson() {
    return {
      if (remoteId != null) 'id': remoteId,
      'name': name,
      if (color != null) 'color': color,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create Folder from server JSON response
  static Folder fromServerJson(Map<String, dynamic> json) {
    return Folder()
      ..remoteId = json['id'] as String?
      ..name = json['name'] as String? ?? ''
      ..color = json['color'] as String?
      ..createdAt = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now()
      ..updatedAt = json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now()
      ..deletedAt = json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null
      ..lastSyncedAt = DateTime.now()
      ..isDirty = false;
  }
}
