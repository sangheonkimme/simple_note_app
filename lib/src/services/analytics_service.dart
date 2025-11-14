import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // A helper method to log events.
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  // Log screen views
  Future<void> logScreenView(String screenName) async {
    await _analytics.setCurrentScreen(screenName: screenName);
  }

  // Log when a note is created
  Future<void> logNoteCreated({required String folder, required bool hasImage}) async {
    await logEvent('note_created', parameters: {
      'folder': folder,
      'has_image': hasImage.toString(),
    });
  }

  // Log when a folder is created
  Future<void> logFolderCreated(String folderName) async {
    await logEvent('folder_created', parameters: {'name': folderName});
  }

  // Log when a search is performed
  Future<void> logSearch(String searchTerm) async {
    await logEvent('search', parameters: {'search_term': searchTerm});
  }
}
