import 'package:dio/dio.dart';
import 'package:novita/src/core/constants.dart';
import 'package:novita/src/core/exceptions.dart';
import 'package:novita/src/data/models/folder.dart';
import 'package:novita/src/data/models/note.dart';
import 'package:novita/src/data/repositories/sync_repository.dart';

/// API implementation of SyncRepository
class ApiSyncRepository implements SyncRepository {
  final Dio dio;

  ApiSyncRepository({required this.dio});

  @override
  Future<SyncResult> getChangesSince({
    required String since,
    int limit = AppConstants.defaultSyncLimit,
  }) async {
    try {
      final response = await dio.get(
        AppConstants.syncEndpoint,
        queryParameters: {
          'since': since,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return SyncResult.fromJson(data);
      }

      throw SyncException.syncFailed();
    } on DioException {
      rethrow;
    } catch (e) {
      throw SyncException.invalidData();
    }
  }

  @override
  Future<String?> getLatestTimestamp() async {
    try {
      final response = await dio.get(AppConstants.syncMetaEndpoint);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['latestTimestamp'] as String?;
      }

      return null;
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<Folder> createFolder(Folder folder) async {
    try {
      final response = await dio.post(
        AppConstants.foldersEndpoint,
        data: folder.toServerJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        return Folder.fromServerJson(data);
      }

      throw SyncException.syncFailed();
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<Folder> updateFolder(Folder folder) async {
    if (folder.remoteId == null) {
      throw ValidationException.invalidInput('folder remoteId');
    }

    try {
      final response = await dio.put(
        '${AppConstants.foldersEndpoint}/${folder.remoteId}',
        data: folder.toServerJson(),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return Folder.fromServerJson(data);
      }

      throw SyncException.syncFailed();
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<void> deleteFolder(String remoteId) async {
    try {
      await dio.delete('${AppConstants.foldersEndpoint}/$remoteId');
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<Note> createNote(Note note) async {
    try {
      final response = await dio.post(
        AppConstants.notesEndpoint,
        data: note.toServerJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        return Note.fromServerJson(data);
      }

      throw SyncException.syncFailed();
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<Note> updateNote(Note note) async {
    if (note.remoteId == null) {
      throw ValidationException.invalidInput('note remoteId');
    }

    try {
      final response = await dio.put(
        '${AppConstants.notesEndpoint}/${note.remoteId}',
        data: note.toServerJson(),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return Note.fromServerJson(data);
      }

      throw SyncException.syncFailed();
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<void> deleteNote(String remoteId) async {
    try {
      await dio.delete('${AppConstants.notesEndpoint}/$remoteId');
    } on DioException {
      rethrow;
    }
  }
}
