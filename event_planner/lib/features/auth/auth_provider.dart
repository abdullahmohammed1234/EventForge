import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api/auth_service.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/storage_helper.dart';

class User {
  final String id;
  final String email;
  final String? displayName;
  final String? city;
  final String? createdAt;
  final String? avatarUrl;

  User({
    required this.id,
    required this.email,
    this.displayName,
    this.city,
    this.createdAt,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'],
      email: json['email'],
      displayName: json['displayName'],
      city: json['city'],
      createdAt: json['createdAt'],
      avatarUrl: json['avatarUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'city': city,
      'createdAt': createdAt,
      'avatarUrl': avatarUrl,
    };
  }
}

class AuthProvider with ChangeNotifier {
  final AuthService authService;
  final FlutterSecureStorage storage;
  final StorageHelper storageHelper;

  User? _user;
  String? _token;
  bool _isCheckingAuth = true;
  bool _isLoading = false;
  String? _error;

  // Profile image - cleared on logout to prevent showing old user's image
  Uint8List? _profileImage;
  Uint8List? get profileImage => _profileImage;

  Future<void> setProfileImage(Uint8List? image) async {
    _profileImage = image;
    // Save to persistent storage
    if (image != null) {
      final base64Image = base64Encode(image);
      await storage.write(key: 'profile_image', value: base64Image);
    } else {
      await storage.delete(key: 'profile_image');
    }
    notifyListeners();
  }

  Future<void> _loadProfileImage() async {
    try {
      final base64Image = await storage.read(key: 'profile_image');
      if (base64Image != null) {
        _profileImage = base64Decode(base64Image);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load profile image: $e');
    }
  }

  AuthProvider({
    required this.authService,
    required this.storage,
    required this.storageHelper,
  }) {
    debugPrint('AuthProvider initialized');
    _checkAuthStatus();
  }

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isCheckingAuth => _isCheckingAuth;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _checkAuthStatus() async {
    _isCheckingAuth = true;
    notifyListeners();

    try {
      _token = await storageHelper.getToken();
      if (_token != null) {
        final userData = await storageHelper.getUserData();
        if (userData != null) {
          _user = User.fromJson(jsonDecode(userData));
        }
        // Load profile image from storage
        await _loadProfileImage();
      }
    } catch (e) {
      _error = 'Error checking auth status';
      _token = null;
      _user = null;
    } finally {
      _isCheckingAuth = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint(
          'Attempting login to: ${authService.baseUrl}${Endpoints.login}');
      final response =
          await authService.login(email: email, password: password);
      debugPrint('Login response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['data']['token'];
        _user = User.fromJson(data['data']['user']);

        await storageHelper.saveToken(_token!);
        await storageHelper.saveUserData(jsonEncode(_user!.toJson()));

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['error'] ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Login error: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    String? displayName,
    String? city,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await authService.register(
        email: email,
        password: password,
        displayName: displayName,
        city: city,
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _token = data['data']['token'];
        _user = User.fromJson(data['data']['user']);

        await storageHelper.saveToken(_token!);
        await storageHelper.saveUserData(jsonEncode(_user!.toJson()));

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['error'] ??
            data['errors']?.toString() ??
            'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    if (_token != null) {
      try {
        await authService.logout(_token!);
      } catch (e) {
        // Ignore logout API errors
      }
    }

    _token = null;
    _user = null;
    _error = null;
    _profileImage = null;
    // Only clear auth-related data, not onboarding state
    await storageHelper.deleteToken();
    await storageHelper.deleteUserData();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> updateProfile({
    String? displayName,
    String? city,
  }) async {
    if (_token == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await authService.updateProfile(
        token: _token!,
        displayName: displayName,
        city: city,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = User.fromJson(data['data']['user']);

        await storageHelper.saveUserData(jsonEncode(_user!.toJson()));

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['error'] ?? 'Update failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadAvatar(File imageFile) async {
    if (_token == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await authService.uploadAvatar(
        token: _token!,
        imageFile: imageFile,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Convert relative URL to absolute URL
        final relativeUrl = data['data']['avatarUrl'];
        final avatarUrl = AppConfig.getFullUrl(relativeUrl);

        // Update user with new avatar URL
        _user = User(
          id: _user!.id,
          email: _user!.email,
          displayName: _user!.displayName,
          city: _user!.city,
          createdAt: _user!.createdAt,
          avatarUrl: avatarUrl,
        );

        await storageHelper.saveUserData(jsonEncode(_user!.toJson()));

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['message'] ?? 'Upload failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
