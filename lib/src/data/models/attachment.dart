import 'package:isar/isar.dart';
import 'package:novita/src/data/models/note.dart';

part 'attachment.g.dart';

@collection
class Attachment {
  Id id = Isar.autoIncrement;

  @Index()
  String? remoteId;

  late String fileName;

  late String url;

  late String mimeType;

  int fileSize = 0;

  @Enumerated(EnumType.name)
  AttachmentType type = AttachmentType.file;

  String? hash;

  String? thumbnailUrl;

  DateTime createdAt = DateTime.now();

  final note = IsarLink<Note>();

  /// Create from server JSON
  static Attachment fromServerJson(Map<String, dynamic> json) {
    return Attachment()
      ..remoteId = json['id'] as String?
      ..fileName = json['fileName'] as String? ?? ''
      ..url = json['url'] as String? ?? ''
      ..mimeType = json['mimeType'] as String? ?? ''
      ..fileSize = json['fileSize'] as int? ?? 0
      ..type = _parseAttachmentType(json['type'] as String?)
      ..hash = json['hash'] as String?
      ..thumbnailUrl = json['thumbnailUrl'] as String?
      ..createdAt = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now();
  }

  /// Convert to server JSON
  Map<String, dynamic> toServerJson() {
    return {
      if (remoteId != null) 'id': remoteId,
      'fileName': fileName,
      'url': url,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'type': type.name.toUpperCase(),
      if (hash != null) 'hash': hash,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
    };
  }

  static AttachmentType _parseAttachmentType(String? type) {
    switch (type?.toUpperCase()) {
      case 'IMAGE':
        return AttachmentType.image;
      case 'AUDIO':
        return AttachmentType.audio;
      case 'FILE':
      default:
        return AttachmentType.file;
    }
  }
}

enum AttachmentType { image, audio, file }
