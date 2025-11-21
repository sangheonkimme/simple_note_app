import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:novita/src/data/models/folder.dart';
import 'package:novita/src/data/models/note.dart';
import 'package:novita/src/data/models/attachment.dart';
import 'package:novita/src/data/repositories/folder_repository.dart';
import 'dart:io';

void main() {
  late Isar isar;
  late FolderRepository folderRepository;

  setUp(() async {
    await Isar.initializeIsarCore(download: true);
    
    // Create a temporary directory for the Isar database
    final dir = Directory.systemTemp.createTempSync();
    
    isar = await Isar.open(
      [FolderSchema, NoteSchema, AttachmentSchema],
      directory: dir.path,
    );
    folderRepository = FolderRepository(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  test('createDefaultFolders creates 4 default folders when DB is empty', () async {
    // Arrange
    expect(await isar.folders.count(), 0);

    // Act
    await folderRepository.createDefaultFolders();

    // Assert
    final count = await isar.folders.count();
    expect(count, 4);

    final folders = await isar.folders.where().findAll();
    final names = folders.map((f) => f.name).toList();
    expect(names, containsAll(['개인', '학업', '업무', '기타']));
    expect(folders.every((f) => f.isSystem), true);
  });

  test('createDefaultFolders does nothing when DB is not empty', () async {
    // Arrange
    await isar.writeTxn(() async {
      await isar.folders.put(Folder()..name = 'Custom Folder');
    });
    expect(await isar.folders.count(), 1);

    // Act
    await folderRepository.createDefaultFolders();

    // Assert
    final count = await isar.folders.count();
    expect(count, 1);
    
    final folders = await isar.folders.where().findAll();
    expect(folders.first.name, 'Custom Folder');
  });
}
