import 'package:isar/isar.dart';
import 'package:novita/src/data/models/note.dart';
import 'package:novita/src/data/models/attachment.dart';

class StorageService {
  final Isar _isar;

  StorageService(this._isar);

  Future<StorageInfo> getStorageUsage() async {
    final noteCount = await _isar.notes.count();
    final attachmentCount = await _isar.attachments.count();

    // Calculate total attachment size
    final attachments = await _isar.attachments.where().findAll();
    int totalSize = 0;
    for (final attachment in attachments) {
      totalSize += attachment.fileSize;
    }

    // Convert to GB
    final usedSpaceGB = totalSize / (1024 * 1024 * 1024);
    const totalSpaceGB = 5.0; // 5GB free tier

    return StorageInfo(
      noteCount: noteCount,
      attachmentCount: attachmentCount,
      usedSpaceBytes: totalSize,
      usedSpaceGB: usedSpaceGB,
      totalSpaceGB: totalSpaceGB,
    );
  }
}

class StorageInfo {
  final int noteCount;
  final int attachmentCount;
  final int usedSpaceBytes;
  final double usedSpaceGB;
  final double totalSpaceGB;

  const StorageInfo({
    required this.noteCount,
    required this.attachmentCount,
    required this.usedSpaceBytes,
    required this.usedSpaceGB,
    required this.totalSpaceGB,
  });

  double get usedPercentage => (usedSpaceGB / totalSpaceGB * 100).clamp(0, 100);
}
