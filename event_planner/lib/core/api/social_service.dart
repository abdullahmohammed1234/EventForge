import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class SocialService {
  final String baseUrl = AppConfig.apiBaseUrl;
  final http.Client _client = http.Client();

  SocialService() {
    debugPrint('SocialService initialized with baseUrl: $baseUrl');
  }

  // Groups API
  Future<http.Response> getGroups(String token) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl${Endpoints.groups}'),
            headers: _authHeaders(token),
          )
          .timeout(const Duration(seconds: 15));
      return response;
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  Future<http.Response> createGroup(
      String token, String name, String? description, bool isPrivate) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl${Endpoints.groups}'),
            headers: _authHeaders(token),
            body: jsonEncode({
              'name': name,
              if (description != null) 'description': description,
              'isPrivate': isPrivate,
            }),
          )
          .timeout(const Duration(seconds: 15));
      return response;
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  Future<http.Response> getGroup(String token, String groupId) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl${Endpoints.groups}/$groupId'),
            headers: _authHeaders(token),
          )
          .timeout(const Duration(seconds: 15));
      return response;
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  Future<http.Response> discoverGroups(String token,
      {String search = '', int page = 1}) async {
    try {
      var url = '$baseUrl${Endpoints.groups}/discover?page=$page';
      if (search.isNotEmpty) {
        url += '&search=${Uri.encodeComponent(search)}';
      }
      final response = await _client
          .get(
            Uri.parse(url),
            headers: _authHeaders(token),
          )
          .timeout(const Duration(seconds: 15));
      return response;
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  Future<http.Response> joinGroup(String token, String groupId) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl${Endpoints.groups}/$groupId/join'),
            headers: _authHeaders(token),
          )
          .timeout(const Duration(seconds: 15));
      return response;
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  Future<http.Response> leaveGroup(String token, String groupId) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl${Endpoints.groups}/$groupId/leave'),
            headers: _authHeaders(token),
          )
          .timeout(const Duration(seconds: 15));
      return response;
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  Future<http.Response> inviteUserToGroup(
      String token, String groupId, String userId) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl${Endpoints.groups}/$groupId/invite'),
            headers: _authHeaders(token),
            body: jsonEncode({'userId': userId}),
          )
          .timeout(const Duration(seconds: 15));
      return response;
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  Future<http.Response> updateMemberRole(
      String token, String groupId, String userId, String role) async {
    try {
      final response = await _client
          .put(
            Uri.parse(
                '$baseUrl${Endpoints.groups}/$groupId/members/$userId/role'),
            headers: _authHeaders(token),
            body: jsonEncode({'role': role}),
          )
          .timeout(const Duration(seconds: 15));
      return response;
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  // Friends API
  Future<http.Response> getFriends(String token) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl${Endpoints.friends}'),
            headers: _authHeaders(token),
          )
          .timeout(const Duration(seconds: 15));
      return response;
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  Future<http.Response> getFriendRequests(String token) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl${Endpoints.friendRequests}'),
            headers: _authHeaders(token),
          )
          .timeout(const Duration(seconds: 15));
      return response;
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  Future<http.Response> searchUsers(String token, String query) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl${Endpoints.friendSearch}?q=$query'),
            headers: _authHeaders(token),
          )
          .timeout(const Duration(seconds: 15));
      return response;
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  Future<http.Response> getSuggestions(String token) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl${Endpoints.friendSuggestions}'),
            headers: _authHeaders(token),
          )
          .timeout(const Duration(seconds: 15));
      return response;
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  Future<http.Response> sendFriendRequest(String token, String userId) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl${Endpoints.friendRequest}'),
            headers: _authHeaders(token),
            body: jsonEncode({'userId': userId}),
          )
          .timeout(const Duration(seconds: 15));
      return response;
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  Future<http.Response> acceptFriendRequest(
      String token, String requestId) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl${Endpoints.friends}/accept/$requestId'),
            headers: _authHeaders(token),
          )
          .timeout(const Duration(seconds: 15));
      return response;
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  Future<http.Response> removeFriend(String token, String friendId) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('$baseUrl${Endpoints.friends}/$friendId'),
            headers: _authHeaders(token),
          )
          .timeout(const Duration(seconds: 15));
      return response;
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  // Messages API
  Future<http.Response> getConversations(String token) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl${Endpoints.messages}'),
            headers: _authHeaders(token),
          )
          .timeout(const Duration(seconds: 15));
      return response;
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  Future<http.Response> getOrCreateConversation(
      String token, String userId) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl${Endpoints.messagesConversation}'),
            headers: _authHeaders(token),
            body: jsonEncode({'userId': userId}),
          )
          .timeout(const Duration(seconds: 15));
      return response;
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  Future<http.Response> getOrCreateGroupConversation(
      String token, String groupId) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl${Endpoints.messagesGroup(groupId)}'),
            headers: _authHeaders(token),
          )
          .timeout(const Duration(seconds: 15));
      return response;
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  Future<http.Response> getMessages(String token, String conversationId,
      {int page = 1, int limit = 50}) async {
    try {
      final response = await _client
          .get(
            Uri.parse(
                '$baseUrl${Endpoints.messages}/$conversationId?page=$page&limit=$limit'),
            headers: _authHeaders(token),
          )
          .timeout(const Duration(seconds: 15));
      return response;
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  Future<http.Response> sendMessage(
      String token, String conversationId, String content,
      {String type = 'text', String? eventId}) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl${Endpoints.messages}/$conversationId'),
            headers: _authHeaders(token),
            body: jsonEncode({
              'content': content,
              'type': type,
              if (eventId != null) 'eventId': eventId,
            }),
          )
          .timeout(const Duration(seconds: 15));
      return response;
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  Map<String, String> _authHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}
