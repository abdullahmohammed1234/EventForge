import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:typed_data';
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
    if (category != null && category.isNotEmpty)
      queryParams['category'] = category;

    final uri = Uri.parse('$baseUrl${Endpoints.events}')
        .replace(queryParameters: queryParams);

    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return _client
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 10));
  }

  Future<http.Response> getEvent(String id, {String? token}) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return _client
        .get(
          Uri.parse('$baseUrl${Endpoints.events}/$id'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 10));
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
    List<String>? tags,
    String? coverImageUrl,
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
    if (tags != null && tags.isNotEmpty) body['tags'] = tags;
    if (coverImageUrl != null) body['coverImageUrl'] = coverImageUrl;

    return _client
        .post(
          Uri.parse('$baseUrl${Endpoints.events}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
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

  Future<http.Response> getRegisteredEvents({
    required String token,
    int page = 1,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$baseUrl${Endpoints.registeredEvents}').replace(
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

  Future<http.Response> registerForEvent({
    required String eventId,
    required String token,
  }) async {
    return _client.post(
      Uri.parse('$baseUrl${EventEndpoints.registerForEvent(eventId)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));
  }

  Future<http.Response> unregisterFromEvent({
    required String eventId,
    required String token,
  }) async {
    return _client.post(
      Uri.parse('$baseUrl${EventEndpoints.unregisterFromEvent(eventId)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));
  }

  Future<http.Response> getSavedEvents({
    required String token,
    int page = 1,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$baseUrl${Endpoints.savedEvents}').replace(
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

  Future<http.Response> saveEvent({
    required String eventId,
    required String token,
  }) async {
    return _client.post(
      Uri.parse('$baseUrl${EventEndpoints.saveEvent(eventId)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));
  }

  Future<http.Response> unsaveEvent({
    required String eventId,
    required String token,
  }) async {
    return _client.post(
      Uri.parse('$baseUrl${EventEndpoints.unsaveEvent(eventId)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));
  }

  Future<http.Response> searchEvents({
    required String query,
    String? category,
    int page = 1,
    int limit = 20,
    String? token,
  }) async {
    final queryParams = <String, String>{
      'search': query,
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (category != null && category.isNotEmpty && category != 'all') {
      queryParams['category'] = category;
    }

    final uri = Uri.parse('$baseUrl${Endpoints.events}')
        .replace(queryParameters: queryParams);

    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return _client
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 10));
  }

  Future<http.Response> uploadEventCover({
    required String token,
    required File imageFile,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl${Endpoints.uploadEventCover}');
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
      return await http.Response.fromStream(streamedResponse);
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  // Web-compatible version using bytes
  Future<http.Response> uploadEventCoverWeb({
    required String token,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl${Endpoints.uploadEventCover}');
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: fileName,
        ),
      );

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
      return await http.Response.fromStream(streamedResponse);
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  // Discovery Engine methods
  Future<http.Response> getHiddenGems({
    String? city,
    String? category,
    int? maxAttendees,
    bool? isFree,
    int page = 1,
    int limit = 20,
    String? token,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (city != null && city.isNotEmpty) queryParams['city'] = city;
    if (category != null && category.isNotEmpty)
      queryParams['category'] = category;
    if (maxAttendees != null)
      queryParams['maxAttendees'] = maxAttendees.toString();
    if (isFree != null) queryParams['isFree'] = isFree.toString();

    final uri = Uri.parse('$baseUrl${Endpoints.hiddenGems}').replace(
      queryParameters: queryParams,
    );

    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return _client
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 10));
  }

  Future<http.Response> getUnderground({
    String? city,
    int page = 1,
    int limit = 20,
    String? token,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (city != null && city.isNotEmpty) queryParams['city'] = city;

    final uri = Uri.parse('$baseUrl${Endpoints.underground}').replace(
      queryParameters: queryParams,
    );

    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return _client
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 10));
  }

  Future<http.Response> downloadEventCalendar({
    required String eventId,
  }) async {
    return _client.get(
      Uri.parse('$baseUrl${EventEndpoints.eventCalendar(eventId)}'),
      headers: {'Content-Type': 'text/calendar'},
    ).timeout(const Duration(seconds: 10));
  }

  Future<http.Response> addTodoItem({
    required String eventId,
    required String title,
    String? description,
    String? assignedTo,
    required String token,
  }) async {
    final body = <String, dynamic>{
      'title': title,
    };
    if (description != null) body['description'] = description;
    if (assignedTo != null) body['assignedTo'] = assignedTo;

    return _client
        .post(
          Uri.parse('$baseUrl${EventEndpoints.todos(eventId)}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
  }

  Future<http.Response> updateTodoItem({
    required String eventId,
    required String todoId,
    String? title,
    String? description,
    String? assignedTo,
    bool? isCompleted,
    required String token,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (assignedTo != null) body['assignedTo'] = assignedTo;
    if (isCompleted != null) body['isCompleted'] = isCompleted;

    return _client
        .put(
          Uri.parse('$baseUrl${EventEndpoints.todo(eventId, todoId)}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
  }

  Future<http.Response> deleteTodoItem({
    required String eventId,
    required String todoId,
    required String token,
  }) async {
    return _client.delete(
      Uri.parse('$baseUrl${EventEndpoints.todo(eventId, todoId)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));
  }

  Future<http.Response> addPoll({
    required String eventId,
    required String question,
    required List<String> options,
    bool isMultipleChoice = false,
    bool allowsNewOptions = true,
    String? expiresAt,
    required String token,
  }) async {
    final body = <String, dynamic>{
      'question': question,
      'options': options.map((o) => {'text': o}).toList(),
      'isMultipleChoice': isMultipleChoice,
      'allowsNewOptions': allowsNewOptions,
    };
    if (expiresAt != null) body['expiresAt'] = expiresAt;

    return _client
        .post(
          Uri.parse('$baseUrl${EventEndpoints.polls(eventId)}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
  }

  Future<http.Response> voteOnPoll({
    required String eventId,
    required String pollId,
    int? optionIndex,
    String? optionText,
    required String token,
  }) async {
    final body = <String, dynamic>{};
    if (optionIndex != null) body['optionIndex'] = optionIndex;
    if (optionText != null) body['optionText'] = optionText;

    return _client
        .post(
          Uri.parse('$baseUrl${EventEndpoints.pollVote(eventId, pollId)}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
  }

  Future<http.Response> closePoll({
    required String eventId,
    required String pollId,
    required String token,
  }) async {
    return _client.post(
      Uri.parse('$baseUrl${EventEndpoints.pollClose(eventId, pollId)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));
  }

  Future<http.Response> deletePoll({
    required String eventId,
    required String pollId,
    required String token,
  }) async {
    return _client.delete(
      Uri.parse('$baseUrl${EventEndpoints.poll(eventId, pollId)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));
  }

  Future<http.Response> addComment({
    required String eventId,
    required String content,
    required String token,
  }) async {
    return _client
        .post(
          Uri.parse('$baseUrl${EventEndpoints.comments(eventId)}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'content': content}),
        )
        .timeout(const Duration(seconds: 10));
  }

  Future<http.Response> deleteComment({
    required String eventId,
    required String commentId,
    required String token,
  }) async {
    return _client.delete(
      Uri.parse('$baseUrl${EventEndpoints.comment(eventId, commentId)}'),
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
