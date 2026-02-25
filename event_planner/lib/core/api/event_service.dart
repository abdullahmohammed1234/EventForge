import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class EventService {
  final String baseUrl = AppConfig.apiBaseUrl;
  final http.Client _client = http.Client();

  Future<http.Response> getEvents({
    String? city,
    String? category,
    int page = 1,
    int limit = 20,
    String? token,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (city != null && city.isNotEmpty) queryParams['city'] = city;
    if (category != null && category.isNotEmpty) queryParams['category'] = category;

    final uri = Uri.parse('$baseUrl${Endpoints.events}')
        .replace(queryParameters: queryParams);

    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return _client.get(uri, headers: headers).timeout(const Duration(seconds: 10));
  }

  Future<http.Response> getEvent(String id, {String? token}) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return _client.get(
      Uri.parse('$baseUrl${Endpoints.events}/$id'),
      headers: headers,
    ).timeout(const Duration(seconds: 10));
  }

  Future<http.Response> createEvent({
    required String title,
    String? description,
    required String category,
    required String city,
    String? address,
    double? latitude,
    double? longitude,
    required String startTime,
    String? endTime,
    int? maxAttendees,
    required String token,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'category': category,
      'city': city,
      'startTime': startTime,
    };

    if (description != null) body['description'] = description;
    if (address != null) body['address'] = address;
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;
    if (endTime != null) body['endTime'] = endTime;
    if (maxAttendees != null) body['maxAttendees'] = maxAttendees;

    return _client.post(
      Uri.parse('$baseUrl${Endpoints.events}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10));
  }

  Future<http.Response> getMyEvents({
    required String token,
    int page = 1,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$baseUrl${Endpoints.myEvents}').replace(
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    return _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));
  }

  void dispose() {
    _client.close();
  }
}
