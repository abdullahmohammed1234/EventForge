import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'Event Planner';
  
  // API Base URL - automatically selects correct address based on platform
  // For Android Emulator: http://10.0.2.2:3000/api
  // For iOS Simulator: http://localhost:3000/api
  // For Physical devices: Use computer's IP (e.g., http://192.168.1.x:3000/api)
  // Override this by changing the kDebugMode check below or setting USE_LOCALHOST_IP to true
  static String get apiBaseUrl {
    if (kDebugMode) {
      // For physical device testing during development:
      // Change the IP below to your computer's local IP address
      // To find your IP: ipconfig (Windows) or ifconfig (Mac/Linux)
      const String localIP = '192.168.4.28'; // <-- CHANGE THIS to your computer's IP
      const bool useLocalhostIP = false; // Set to true for emulator/simulator, false for physical device
      
      if (useLocalhostIP) {
        return 'http://10.0.2.2:3000/api'; // Android Emulator
      }
      return 'http://$localIP:3000/api';
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
}
