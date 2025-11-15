import 'package:isar/isar.dart';
import 'package:novita/src/data/models/tag.dart';

class TagRepository {
  final Isar isar;

  TagRepository(this.isar);

  Future<Tag> getOrCreateTag(String name) async {
    final existingTag = await isar.tags.filter().nameEqualTo(name).findFirst();
    if (existingTag != null) {
      return existingTag;
    } else {
      final newTag = Tag()..name = name;
      await isar.writeTxn(() async {
        await isar.tags.put(newTag);
      });
      return newTag;
    }
  }

  Stream<List<Tag>> watchAllTags() {
    return isar.tags.where().sortByName().watch(fireImmediately: true);
  }
}
