import 'dart:io';
import 'package:isar/isar.dart';

class StorageInfo {
  final double usedSpaceGB;
  final double totalSpaceGB;

  StorageInfo({required this.usedSpaceGB, required this.totalSpaceGB});
}

class StorageService {
  final Isar isar;

  StorageService(this.isar);

  Future<StorageInfo> getStorageUsage() async {
    // Get Isar database file path
    final path = isar.path;
    if (path == null) {
      // Return default values if path is not available
      return StorageInfo(usedSpaceGB: 0, totalSpaceGB: 25.0);
    }

    final file = File(path);
    final fileExists = await file.exists();
    if (!fileExists) {
      return StorageInfo(usedSpaceGB: 0, totalSpaceGB: 25.0);
    }

    // Get database size in bytes and convert to Gigabytes
    final dbSizeBytes = await file.length();
    final dbSizeGB = dbSizeBytes / (1024 * 1024 * 1024);

    // The design specifies a 25GB total, which likely represents a future cloud storage limit.
    // We will use this fixed value for the total space for now.
    const totalSpaceGB = 25.0;

    return StorageInfo(
      usedSpaceGB: dbSizeGB,
      totalSpaceGB: totalSpaceGB,
    );
  }
}
