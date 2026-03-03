import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const String appName = 'EventForge';
  
  // API Base URL - For local development, uses the IP from .env file
  // For Android Emulator: http://10.0.2.2:3000/api
  // For iOS Simulator: http://localhost:3000/api
  // For Physical devices: Use computer's IP (e.g., http://192.168.1.x:3000/api)
  // The IP is loaded from the .env file (LOCAL_IP variable)
  //
  // IMPORTANT: For installed APK to work with local backend, ensure:
  // 1. Your phone is connected to the same WiFi as your computer
  // 2. The .env file has your computer's local IP address
  // 3. Your firewall allows connections on port 3000
  static String get apiBaseUrl {
    // Get local IP from .env file
    // Create a .env file in the project root with: LOCAL_IP=192.168.x.x
    final String? localIP = dotenv.env['LOCAL_IP'];
    
    // Debug: Print the loaded IP
    debugPrint('DEBUG: LOCAL_IP from .env = $localIP');
    
    if (localIP != null && localIP.isNotEmpty) {
      debugPrint('DEBUG: Using IP-based URL: http://$localIP:3000/api');
      return 'http://$localIP:3000/api';
    }
    
    // Fallback if .env is not configured
    // For Android emulator: 10.0.2.2 is the emulator's alias to the host's localhost
    // For iOS simulator: localhost works
    // For USB debugging with flutter run: localhost works (adb reverse is auto-configured)
    if (kDebugMode) {
      debugPrint('DEBUG: Using localhost (debug mode)');
      // Use localhost for debug builds - works with:
      // - Android emulator (10.0.2.2 or localhost)
      // - iOS simulator (localhost)
      // - USB device when running via 'flutter run' (adb reverse auto-configured)
      return 'http://localhost:3000/api';
    }
    
    debugPrint('DEBUG: Using production URL');
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
