import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class SecureStorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  static const String _deviceIdKey = 'device_id';
  
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // 토큰 관리
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e) {
      print('액세스 토큰 가져오기 실패: $e');
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      print('리프레시 토큰 가져오기 실패: $e');
      return null;
    }
  }

  Future<bool> saveTokens(String accessToken, String refreshToken) async {
    try {
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
      return true;
    } catch (e) {
      print('토큰 저장 실패: $e');
      return false;
    }
  }

  Future<bool> removeTokens() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      return true;
    } catch (e) {
      print('토큰 삭제 실패: $e');
      return false;
    }
  }

  // 사용자 데이터 관리
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final userData = await _storage.read(key: _userKey);
      if (userData != null) {
        return json.decode(userData);
      }
      return null;
    } catch (e) {
      print('사용자 데이터 가져오기 실패: $e');
      return null;
    }
  }

  Future<bool> saveUserData(Map<String, dynamic> userData) async {
    try {
      await _storage.write(key: _userKey, value: json.encode(userData));
      return true;
    } catch (e) {
      print('사용자 데이터 저장 실패: $e');
      return false;
    }
  }

  Future<bool> removeUserData() async {
    try {
      await _storage.delete(key: _userKey);
      return true;
    } catch (e) {
      print('사용자 데이터 삭제 실패: $e');
      return false;
    }
  }

  // 디바이스 ID 관리
  Future<String?> getDeviceId() async {
    try {
      return await _storage.read(key: _deviceIdKey);
    } catch (e) {
      print('디바이스 ID 가져오기 실패: $e');
      return null;
    }
  }

  Future<bool> saveDeviceId(String deviceId) async {
    try {
      await _storage.write(key: _deviceIdKey, value: deviceId);
      return true;
    } catch (e) {
      print('디바이스 ID 저장 실패: $e');
      return false;
    }
  }

  // 전체 인증 데이터 삭제
  Future<bool> clearAuthData() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _userKey);
      return true;
    } catch (e) {
      print('인증 데이터 삭제 실패: $e');
      return false;
    }
  }

  // 전체 보안 데이터 삭제
  Future<bool> clearAll() async {
    try {
      await _storage.deleteAll();
      return true;
    } catch (e) {
      print('전체 보안 데이터 삭제 실패: $e');
      return false;
    }
  }

  // 인증 상태 확인
  Future<bool> hasTokens() async {
    try {
      final accessToken = await _storage.read(key: _accessTokenKey);
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      return accessToken != null && refreshToken != null;
    } catch (e) {
      return false;
    }
  }
}