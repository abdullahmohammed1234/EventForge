import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

enum FeedType {
  discover,
  hiddenGems,
  underground,
  external,
}

class DiscoveryService {
  final String baseUrl = AppConfig.apiBaseUrl;
  final http.Client _client = http.Client();

  Future<http.Response> getDiscoverFeed({
    FeedType feedType = FeedType.discover,
    String? city,
    String? category,
    int page = 1,
    int limit = 20,
    String? token,
  }) async {
    String feedTypeStr;
    switch (feedType) {
      case FeedType.hiddenGems:
        feedTypeStr = 'hidden_gems';
        break;
      case FeedType.underground:
        feedTypeStr = 'underground';
        break;
      case FeedType.external:
        feedTypeStr = 'external';
        break;
      default:
        feedTypeStr = 'all';
    }

    final queryParams = <String, String>{
      'feedType': feedTypeStr,
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (city != null && city.isNotEmpty) {
      queryParams['city'] = city;
    }
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }

    final uri = Uri.parse('$baseUrl${Endpoints.discoverFeed}').replace(
      queryParameters: queryParams,
    );

    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return _client.get(uri, headers: headers).timeout(const Duration(seconds: 10));
  }

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
    if (category != null && category.isNotEmpty) queryParams['category'] = category;
    if (maxAttendees != null) queryParams['maxAttendees'] = maxAttendees.toString();
    if (isFree != null) queryParams['isFree'] = isFree.toString();

    final uri = Uri.parse('$baseUrl${Endpoints.hiddenGems}').replace(
      queryParameters: queryParams,
    );

    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return _client.get(uri, headers: headers).timeout(const Duration(seconds: 10));
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

    return _client.get(uri, headers: headers).timeout(const Duration(seconds: 10));
  }

  Future<http.Response> getExternalEvents({
    String? source,
    String? city,
    int? hiddenScoreMin,
    bool? isUnderground,
    int page = 1,
    int limit = 20,
    String? token,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (source != null && source.isNotEmpty) queryParams['source'] = source;
    if (city != null && city.isNotEmpty) queryParams['city'] = city;
    if (hiddenScoreMin != null) queryParams['hiddenScoreMin'] = hiddenScoreMin.toString();
    if (isUnderground != null) queryParams['isUnderground'] = isUnderground.toString();

    final uri = Uri.parse('$baseUrl${Endpoints.externalEvents}').replace(
      queryParameters: queryParams,
    );

    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return _client.get(uri, headers: headers).timeout(const Duration(seconds: 10));
  }

  Future<http.Response> getDiscoveryStats({String? token}) async {
    final uri = Uri.parse('$baseUrl${Endpoints.discoveryStats}');

    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return _client.get(uri, headers: headers).timeout(const Duration(seconds: 10));
  }

  void dispose() {
    _client.close();
  }
}