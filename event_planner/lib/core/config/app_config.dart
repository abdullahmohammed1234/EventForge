class AppConfig {
  static const String appName = 'Event Planner';
  // For Android Emulator use: http://10.0.2.2:3000/api
  // For iOS Simulator use: http://localhost:3000/api
  // For Physical device testing, use your computer's IP address (e.g., http://192.168.1.x:3000/api)
  static const String apiBaseUrl = 'http://192.168.4.28:3000/api'; // Default
  // For Android Emulator use: http://10.0.2.2:3000/api
  // For iOS Simulator use: http://localhost:3000/api
  // For Physical device use: http://YOUR_IP:3000/api

  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
}

// API Endpoints
class Endpoints {
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String events = '/events';
  static const String myEvents = '/events/my-events';
<<<<<<< Updated upstream
=======
  static const String registeredEvents = '/events/registered';
  static const String savedEvents = '/events/saved';
  static const String uploadEventCover = '/events/upload-cover';
  static const String uploadAvatar = '/auth/upload-avatar';
  static const String profile = '/auth/profile';
}

// Helper method to get event registration endpoint
class EventEndpoints {
  static String registerForEvent(String eventId) => '/events/$eventId/register';
  static String unregisterFromEvent(String eventId) =>
      '/events/$eventId/unregister';
  static String saveEvent(String eventId) => '/events/$eventId/save';
  static String unsaveEvent(String eventId) => '/events/$eventId/unsave';
>>>>>>> Stashed changes
}
