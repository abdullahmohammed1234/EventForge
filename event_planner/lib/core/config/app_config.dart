class AppConfig {
  static const String appName = 'Event Planner';
  static const String apiBaseUrl = 'http://192.168.1.69:3000/api';
  // For physical device testing, use your computer's IP address
  // static const String apiBaseUrl = 'http://192.168.1.x:3000/api';

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
}
