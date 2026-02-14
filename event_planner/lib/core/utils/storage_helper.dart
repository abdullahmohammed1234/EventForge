import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageHelper {
  final FlutterSecureStorage storage;

  StorageHelper(this.storage);

  Future<void> saveToken(String token) async {
    await storage.write(key: 'auth_token', value: token);
  }

  Future<String?> getToken() async {
    return await storage.read(key: 'auth_token');
  }

  Future<void> deleteToken() async {
    await storage.delete(key: 'auth_token');
  }

  Future<void> saveUserData(String userData) async {
    await storage.write(key: 'user_data', value: userData);
  }

  Future<String?> getUserData() async {
    return await storage.read(key: 'user_data');
  }

  Future<void> deleteUserData() async {
    await storage.delete(key: 'user_data');
  }

  Future<void> clearAll() async {
    await storage.deleteAll();
  }
}
