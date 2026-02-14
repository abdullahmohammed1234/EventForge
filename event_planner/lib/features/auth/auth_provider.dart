import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api/auth_service.dart';
import '../../core/utils/storage_helper.dart';

class User {
  final String id;
  final String email;
  final String? displayName;
  final String? city;
  final String? createdAt;

  User({
    required this.id,
    required this.email,
    this.displayName,
    this.city,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'],
      email: json['email'],
      displayName: json['displayName'],
      city: json['city'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'city': city,
      'createdAt': createdAt,
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

  AuthProvider({
    required this.authService,
    required this.storage,
    required this.storageHelper,
  }) {
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
      final response = await authService.login(email: email, password: password);

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
        _error = data['error'] ?? data['errors']?.toString() ?? 'Registration failed';
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
    await storageHelper.clearAll();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
