import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:novita/src/data/models/attachment.dart';
import 'package:uuid/uuid.dart';

class AttachmentService {
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  Future<Attachment?> pickImage(ImageSource source) async {
    final XFile? imageFile = await _picker.pickImage(source: source);

    if (imageFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${_uuid.v4()}.${imageFile.path.split('.').last}';
      final savedFile = await File(imageFile.path).copy('${appDir.path}/$fileName');

      final attachment = Attachment()
        ..filePath = savedFile.path
        ..mimeType = imageFile.mimeType ?? 'image/jpeg'
        ..size = await savedFile.length();
      
      return attachment;
    }
    return null;
  }

  Future<void> deleteAttachmentFile(Attachment attachment) async {
    try {
      final file = File(attachment.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Production-ready error handling (e.g., logging to a service)
    }
  }
}
