import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';

class SecureStorageService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  
  static const _storage = FlutterSecureStorage(
    webOptions: WebOptions(
      dbName: 'PaperlyWriterSecureStorage',
      publicKey: 'PaperlyWriterPublicKey',
    ),
  );

  // 토큰 관리
  Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      print('토큰 가져오기 실패: $e');
      return null;
    }
  }

  Future<bool> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      return true;
    } catch (e) {
      print('토큰 저장 실패: $e');
      return false;
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

  Future<bool> saveRefreshToken(String refreshToken) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
      return true;
    } catch (e) {
      print('리프레시 토큰 저장 실패: $e');
      return false;
    }
  }

  Future<bool> saveTokens(String accessToken, String refreshToken) async {
    try {
      await _storage.write(key: _tokenKey, value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
      return true;
    } catch (e) {
      print('토큰들 저장 실패: $e');
      return false;
    }
  }

  Future<bool> removeTokens() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _refreshTokenKey);
      return true;
    } catch (e) {
      print('토큰들 삭제 실패: $e');
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

  // 보안 데이터 확인
  Future<bool> hasToken() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}