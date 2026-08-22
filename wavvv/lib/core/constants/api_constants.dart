import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl {
    final url = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static String get socketUrl {
    return dotenv.env['SOCKET_URL'] ?? 'http://localhost:3000';
  }

  static String get youtubeApiKey {
    return dotenv.env['YOUTUBE_API_KEY'] ?? '';
  }

  // Endpoints
  static const String authVerify = '/api/auth/verify';
  static const String userMe = '/api/users/me';
  static const String userHistory = '/api/users/me/history';
  static const String userStreak = '/api/users/me/streak';
  static const String rooms = '/api/rooms';
  static const String roomsCode = '/api/rooms/code';
  static const String youtubeSearch = '/api/youtube/search';
  static const String youtubeVideo = '/api/youtube/video';
}
