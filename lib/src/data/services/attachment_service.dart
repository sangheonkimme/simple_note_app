import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:novita/src/data/models/attachment.dart';

class AttachmentService {
  final ImagePicker _imagePicker = ImagePicker();

  Future<Attachment?> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return null;

      // Copy to app directory
      final savedPath = await _saveToAppDirectory(image);

      return Attachment()
        ..fileName = path.basename(savedPath)
        ..url = savedPath
        ..mimeType = _getMimeType(image.path)
        ..fileSize = await File(savedPath).length()
        ..type = AttachmentType.image
        ..createdAt = DateTime.now();
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  Future<String> _saveToAppDirectory(XFile file) async {
    final appDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory('${appDir.path}/attachments');

    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
    final newPath = '${attachmentsDir.path}/$fileName';

    await File(file.path).copy(newPath);
    return newPath;
  }

  String _getMimeType(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.m4a':
        return 'audio/m4a';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> deleteAttachment(Attachment attachment) async {
    try {
      final file = File(attachment.url);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting attachment: $e');
    }
  }
}
