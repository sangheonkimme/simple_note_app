/// Application-wide constants
class AppConstants {
  AppConstants._();

  /// API Configuration
  static const String baseUrl = 'https://worklife-dashboard.onrender.com';
  static const String apiVersion = 'v1';

  /// Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  /// Sync Configuration
  static const int defaultSyncLimit = 200;
  static const int maxSyncLimit = 500;

  /// Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String lastSyncTimestampKey = 'last_sync_timestamp';

  /// File Upload
  static const int maxAttachmentSizeMB = 10;
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const List<String> supportedAudioFormats = ['mp3', 'wav', 'm4a', 'aac'];
  static const List<String> supportedDocFormats = ['pdf', 'doc', 'docx', 'txt'];

  /// API Endpoints

  // Auth
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String googleLoginEndpoint = '/api/auth/google';
  static const String refreshTokenEndpoint = '/api/auth/refresh';
  static const String logoutEndpoint = '/api/auth/logout';
  static const String meEndpoint = '/api/auth/me';
  static const String profileEndpoint = '/api/auth/profile';

  // Sync
  static const String syncEndpoint = '/api/sync';
  static const String syncMetaEndpoint = '/api/sync/meta';

  // Notes
  static const String notesEndpoint = '/api/notes';
  static const String trashEndpoint = '/api/notes/trash';
  static const String searchEndpoint = '/api/notes/search';
  static const String searchSuggestionsEndpoint = '/api/notes/search/suggestions';

  // Checklist
  static const String checklistEndpoint = '/api/checklist';

  // Folders
  static const String foldersEndpoint = '/api/folders';
}
