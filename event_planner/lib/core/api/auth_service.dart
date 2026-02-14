import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class AuthService {
  final String baseUrl = AppConfig.apiBaseUrl;

  http.Client get _client => http.Client();

  Future<http.Response> register({
    required String email,
    required String password,
    String? displayName,
    String? city,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl${Endpoints.register}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          if (displayName != null) 'displayName': displayName,
          if (city != null) 'city': city,
        }),
      ).timeout(const Duration(seconds: 15));
      return response;
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  Future<http.Response> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl${Endpoints.login}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));
      return response;
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  Future<http.Response> logout(String token) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl${Endpoints.logout}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));
      return response;
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  Future<http.Response> getMe(String token) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl${Endpoints.me}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));
      return response;
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
