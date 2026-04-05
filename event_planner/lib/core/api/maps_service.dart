/**
 * OpenRouteService API Service
 * Provides directions, distance calculations, and location search
 * Uses the backend API to protect API keys
 */

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class MapsService {
  /// Get directions between two points
  /// [fromLng] - Starting longitude
  /// [fromLat] - Starting latitude  
  /// [toLng] - Destination longitude
  /// [toLat] - Destination latitude
  /// [profile] - Travel profile (driving-car, cycling-regular, foot-walking)
  static Future<Map<String, dynamic>?> getDirections({
    required double fromLng,
    required double fromLat,
    required double toLng,
    required double toLat,
    String profile = 'driving-car',
  }) async {
    try {
      final baseUrl = AppConfig.apiBaseUrl;
      final uri = Uri.parse('$baseUrl/maps/directions').replace(
        queryParameters: {
          'from_lng': fromLng.toString(),
          'from_lat': fromLat.toString(),
          'to_lng': toLng.toString(),
          'to_lat': toLat.toString(),
          'profile': profile,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Error getting directions: $e');
      return null;
    }
  }

  /// Get distance and duration between two points
  /// Returns distance in meters and duration in seconds
  static Future<Map<String, dynamic>?> getDistance({
    required double fromLng,
    required double fromLat,
    required double toLng,
    required double toLat,
    String profile = 'driving-car',
  }) async {
    try {
      final baseUrl = AppConfig.apiBaseUrl;
      final uri = Uri.parse('$baseUrl/maps/distance').replace(
        queryParameters: {
          'from_lng': fromLng.toString(),
          'from_lat': fromLat.toString(),
          'to_lng': toLng.toString(),
          'to_lat': toLat.toString(),
          'profile': profile,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Error getting distance: $e');
      return null;
    }
  }

  /// Convert address to coordinates (geocoding)
  static Future<Map<String, dynamic>?> geocode(String address) async {
    try {
      final baseUrl = AppConfig.apiBaseUrl;
      final uri = Uri.parse('$baseUrl/maps/geocode').replace(
        queryParameters: {
          'address': address,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Error geocoding address: $e');
      return null;
    }
  }

  /// Convert coordinates to address (reverse geocoding)
  static Future<Map<String, dynamic>?> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    try {
      final baseUrl = AppConfig.apiBaseUrl;
      final uri = Uri.parse('$baseUrl/maps/reverse-geocode').replace(
        queryParameters: {
          'lat': lat.toString(),
          'lng': lng.toString(),
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Error reverse geocoding: $e');
      return null;
    }
  }

  /// Search for locations by query
  static Future<List<Map<String, dynamic>>?> searchLocations(String query) async {
    try {
      final baseUrl = AppConfig.apiBaseUrl;
      final uri = Uri.parse('$baseUrl/maps/search').replace(
        queryParameters: {
          'query': query,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> listData = data['data'] as List<dynamic>;
          return listData.map((e) => e as Map<String, dynamic>).toList();
        }
      }
      return null;
    } catch (e) {
      print('Error searching locations: $e');
      return null;
    }
  }

  /// Get driving directions URL for OpenStreetMap
  static String getDrivingDirectionsUrl({
    required double fromLng,
    required double fromLat,
    required double toLng,
    required double toLat,
  }) {
    return 'https://www.openstreetmap.org/directions?from=$fromLat%2C$fromLng&to=$toLat%2C$toLng&route=car';
  }

  /// Get public transit directions URL
  static String getTransitDirectionsUrl({
    required double toLng,
    required double toLat,
  }) {
    return 'https://www.openstreetmap.org/directions?from=&to=$toLat%2C$toLng&route=pedestrian';
  }

  /// Get walking directions URL
  static String getWalkingDirectionsUrl({
    required double fromLng,
    required double fromLat,
    required double toLng,
    required double toLat,
  }) {
    return 'https://www.openstreetmap.org/directions?from=$fromLat%2C$fromLng&to=$toLat%2C$toLng&route=pedestrian';
  }

  /// Get OpenStreetMap search URL for an address (address primary, city fallback)
  static Future<Map<String, dynamic>?> getOsmSearchUrl({
    required String address,
    String? city,
  }) async {
    try {
      final baseUrl = AppConfig.apiBaseUrl;
      String searchQuery = address;
      if (city != null && city.isNotEmpty) {
        searchQuery = '$address, $city';
      }
      final uri = Uri.parse('$baseUrl/maps/osm-search').replace(
        queryParameters: {
          'address': searchQuery,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Error getting OSM search URL: $e');
      return null;
    }
  }
}