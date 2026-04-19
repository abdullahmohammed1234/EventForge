import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const String appName = 'EventForge';

  // API Base URL - automatically selects correct address based on platform
  // For Android Emulator: http://10.0.2.2:3000/api
  // For iOS Simulator: http://localhost:3000/api
  // For Physical devices: Use computer's IP (e.g., http://192.168.1.x:3000/api)
  // The IP is loaded from the .env file (LOCAL_IP variable)

  static String get apiBaseUrl {
    if (kDebugMode) {
      // Get local IP from .env file
      // Create a .env file in the project root with: LOCAL_IP=192.168.x.x
      final String? localIP = dotenv.env['LOCAL_IP'];

      if (localIP != null && localIP.isNotEmpty) {
        return 'http://$localIP:3000/api';
      }

      // Fallback if .env is not configured - use a default or show error
      // You need to create a .env file with your local IP
      return 'http://localhost:3000/api';
    }
    // Production URL - update this to your deployed backend URL
    return 'https://192.168.1.69:3000/api';
  }

  // Get the base URL without /api suffix (for uploads, etc.)
  static String get baseUrl {
    if (kDebugMode) {
      final String? localIP = dotenv.env['LOCAL_IP'];
      if (localIP != null && localIP.isNotEmpty) {
        return 'http://$localIP:3000';
      }
      return 'http://localhost:3000';
    }
    return 'https://192.168.1.69:3000';
  }

  // Convert a relative URL to absolute URL
  static String getFullUrl(String? relativeUrl) {
    if (relativeUrl == null || relativeUrl.isEmpty) {
      return '';
    }
    // If already absolute URL, return as-is
    if (relativeUrl.startsWith('http://') ||
        relativeUrl.startsWith('https://') ||
        relativeUrl.startsWith('data:')) {
      return relativeUrl;
    }
    // Prepend base URL
    return '$baseUrl$relativeUrl';
  }

  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
}

// API Endpoints
class Endpoints {
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String profile = '/auth/profile';
  static const String uploadAvatar = '/auth/upload-avatar';
  static const String events = '/events';
  static const String myEvents = '/events/my-events';
  static const String registeredEvents = '/events/registered';
  static const String savedEvents = '/events/saved';
  static const String uploadEventCover = '/events/upload-cover';

  // Discovery Engine Endpoints
  static const String discoverFeed = '/discover/feed';
  static const String hiddenGems = '/discover/hidden-gems';
  static const String underground = '/discover/underground';
  static const String externalEvents = '/discover/external';
  static const String discoveryStats = '/discover/stats';

  // Social Endpoints
  static const String groups = '/groups';
  static String groupMemberRole(String groupId, String userId) =>
      '/groups/$groupId/members/$userId/role';
  static const String friends = '/friends';
  static const String friendRequests = '/friends/requests';
  static const String friendSearch = '/friends/search';
  static const String friendSuggestions = '/friends/suggestions';
  static const String friendRequest = '/friends/request';
  static const String messages = '/messages';
  static const String messagesConversation = '/messages/conversation';
  static String messagesGroup(String groupId) => '/messages/group/$groupId';
}

// Helper method to get event registration endpoint
class EventEndpoints {
  static String registerForEvent(String eventId) => '/events/$eventId/register';
  static String unregisterFromEvent(String eventId) =>
      '/events/$eventId/unregister';
  static String saveEvent(String eventId) => '/events/$eventId/save';
  static String unsaveEvent(String eventId) => '/events/$eventId/unsave';
  static String eventCalendar(String eventId) => '/events/$eventId/calendar';
  static String todos(String eventId) => '/events/$eventId/todos';
  static String todo(String eventId, String todoId) =>
      '/events/$eventId/todos/$todoId';
  static String polls(String eventId) => '/events/$eventId/polls';
  static String poll(String eventId, String pollId) =>
      '/events/$eventId/polls/$pollId';
  static String pollVote(String eventId, String pollId) =>
      '/events/$eventId/polls/$pollId/vote';
  static String pollClose(String eventId, String pollId) =>
      '/events/$eventId/polls/$pollId/close';
  static String comments(String eventId) => '/events/$eventId/comments';
  static String comment(String eventId, String commentId) =>
      '/events/$eventId/comments/$commentId';
}
