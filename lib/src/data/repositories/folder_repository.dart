import 'package:isar/isar.dart';
import 'package:novita/src/data/models/folder.dart';

class FolderRepository {
  final Isar isar;

  FolderRepository(this.isar);

  Future<void> createDefaultFolders() async {
    final count = await isar.folders.count();
    if (count == 0) {
      final defaultFolders = [
        Folder()..name = '개인'..isSystem = true,
        Folder()..name = '학업'..isSystem = true,
        Folder()..name = '업무'..isSystem = true,
        Folder()..name = '기타'..isSystem = true,
      ];
      await isar.writeTxn(() async {
        await isar.folders.putAll(defaultFolders);
      });
    }
  }

  Future<void> saveFolder(Folder folder) async {
    await isar.writeTxn(() async {
      await isar.folders.put(folder);
    });
  }

  Stream<List<Folder>> watchAllFolders() {
    return isar.folders.where().sortByName().watch(fireImmediately: true);
  }
}
