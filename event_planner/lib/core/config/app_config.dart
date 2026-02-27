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
    return 'https://your-production-api.com/api';
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
  static const String events = '/events';
  static const String myEvents = '/events/my-events';
  static const String registeredEvents = '/events/registered';
}

// Helper method to get event registration endpoint
class EventEndpoints {
  static String registerForEvent(String eventId) => '/events/$eventId/register';
  static String unregisterFromEvent(String eventId) => '/events/$eventId/unregister';
}
