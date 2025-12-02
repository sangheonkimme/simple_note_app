import 'package:flutter/foundation.dart';

class AnalyticsService {
  Future<void> logNoteCreated({
    required String folder,
    required bool hasImage,
  }) async {
    debugPrint('Analytics: Note created in $folder, hasImage: $hasImage');
    // TODO: Implement Firebase Analytics
  }

  Future<void> logNoteDeleted() async {
    debugPrint('Analytics: Note deleted');
  }

  Future<void> logSearch(String query) async {
    debugPrint('Analytics: Search query: $query');
  }

  Future<void> logLogin(String method) async {
    debugPrint('Analytics: Login with $method');
  }

  Future<void> logSignup(String method) async {
    debugPrint('Analytics: Signup with $method');
  }

  Future<void> logScreenView(String screenName) async {
    debugPrint('Analytics: Screen view: $screenName');
  }
}
