import 'package:isar/isar.dart';
import 'package:novita/src/data/models/folder.dart';
import 'package:novita/src/data/models/checklist_item.dart';
import 'package:novita/src/data/models/attachment.dart';

part 'note.g.dart';

enum NoteType { text, checklist, markdown, quick }

enum NoteVisibility { private_, public_, protected_ }

@collection
class Note {
  Id id = Isar.autoIncrement;

  @Index()
  String? remoteId;

  DateTime? lastSyncedAt;

  bool isDirty = false;

  DateTime? deletedAt;

  late String title;

  String? content;

  @Enumerated(EnumType.name)
  NoteType type = NoteType.text;

  @Enumerated(EnumType.name)
  NoteVisibility visibility = NoteVisibility.private_;

  String? password;

  bool isPinned = false;

  bool isFavorite = false;

  bool isArchived = false;

  String? publishedUrl;

  int deviceRevision = 0;

  DateTime createdAt = DateTime.now();

  DateTime updatedAt = DateTime.now();

  final folder = IsarLink<Folder>();

  List<ChecklistItem> checklistItems = [];

  @Backlink(to: 'note')
  final attachments = IsarLinks<Attachment>();

  /// Convert to server JSON format for API requests
  Map<String, dynamic> toServerJson() {
    return {
      if (remoteId != null) 'id': remoteId,
      'title': title,
      'content': content ?? '',
      'type': _noteTypeToServer(type),
      'visibility': _visibilityToServer(visibility),
      if (password != null) 'password': password,
      'isPinned': isPinned,
      'isFavorite': isFavorite,
      'isArchived': isArchived,
      if (folder.value?.remoteId != null) 'folderId': folder.value!.remoteId,
      if (checklistItems.isNotEmpty)
        'checklistItems': checklistItems.map((item) => item.toServerJson()).toList(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create Note from server JSON response
  static Note fromServerJson(Map<String, dynamic> json) {
    final note = Note()
      ..remoteId = json['id'] as String?
      ..title = json['title'] as String? ?? ''
      ..content = json['content'] as String?
      ..type = _serverToNoteType(json['type'] as String?)
      ..visibility = _serverToVisibility(json['visibility'] as String?)
      ..password = json['password'] as String?
      ..isPinned = json['isPinned'] as bool? ?? false
      ..isFavorite = json['isFavorite'] as bool? ?? false
      ..isArchived = json['isArchived'] as bool? ?? false
      ..publishedUrl = json['publishedUrl'] as String?
      ..deviceRevision = json['deviceRevision'] as int? ?? 0
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

    // Parse checklist items
    if (json['checklistItems'] != null) {
      final items = (json['checklistItems'] as List<dynamic>)
          .map((item) => ChecklistItem.fromServerJson(item as Map<String, dynamic>))
          .toList();
      note.checklistItems = items;
    }

    return note;
  }

  static String _noteTypeToServer(NoteType type) {
    switch (type) {
      case NoteType.text:
        return 'TEXT';
      case NoteType.checklist:
        return 'CHECKLIST';
      case NoteType.markdown:
        return 'MARKDOWN';
      case NoteType.quick:
        return 'QUICK';
    }
  }

  static NoteType _serverToNoteType(String? type) {
    switch (type) {
      case 'CHECKLIST':
        return NoteType.checklist;
      case 'MARKDOWN':
        return NoteType.markdown;
      case 'QUICK':
        return NoteType.quick;
      case 'TEXT':
      default:
        return NoteType.text;
    }
  }

  static String _visibilityToServer(NoteVisibility visibility) {
    switch (visibility) {
      case NoteVisibility.private_:
        return 'PRIVATE';
      case NoteVisibility.public_:
        return 'PUBLIC';
      case NoteVisibility.protected_:
        return 'PROTECTED';
    }
  }

  static NoteVisibility _serverToVisibility(String? visibility) {
    switch (visibility) {
      case 'PUBLIC':
        return NoteVisibility.public_;
      case 'PROTECTED':
        return NoteVisibility.protected_;
      case 'PRIVATE':
      default:
        return NoteVisibility.private_;
    }
  }
}
