import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _settingsKey = 'app_settings';
  static const String _draftsKey = 'local_drafts';

  // 토큰 관리
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('토큰 가져오기 실패: $e');
      return null;
    }
  }

  Future<bool> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_tokenKey, token);
    } catch (e) {
      print('토큰 저장 실패: $e');
      return false;
    }
  }

  Future<bool> removeToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_tokenKey);
    } catch (e) {
      print('토큰 삭제 실패: $e');
      return false;
    }
  }

  // 사용자 데이터 관리
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);
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
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_userKey, json.encode(userData));
    } catch (e) {
      print('사용자 데이터 저장 실패: $e');
      return false;
    }
  }

  Future<bool> removeUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_userKey);
    } catch (e) {
      print('사용자 데이터 삭제 실패: $e');
      return false;
    }
  }

  // 앱 설정 관리
  Future<Map<String, dynamic>?> getSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = prefs.getString(_settingsKey);
      if (settings != null) {
        return json.decode(settings);
      }
      return null;
    } catch (e) {
      print('설정 가져오기 실패: $e');
      return null;
    }
  }

  Future<bool> saveSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_settingsKey, json.encode(settings));
    } catch (e) {
      print('설정 저장 실패: $e');
      return false;
    }
  }

  // 임시 글 저장 (로컬 드래프트)
  Future<List<Map<String, dynamic>>> getLocalDrafts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftsJson = prefs.getString(_draftsKey);
      if (draftsJson != null) {
        final List<dynamic> draftsList = json.decode(draftsJson);
        return draftsList.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('로컬 드래프트 가져오기 실패: $e');
      return [];
    }
  }

  Future<bool> saveLocalDraft(Map<String, dynamic> draft) async {
    try {
      final drafts = await getLocalDrafts();
      
      // 기존 드래프트 업데이트 또는 새로 추가
      final existingIndex = drafts.indexWhere(
        (d) => d['id'] == draft['id']
      );
      
      if (existingIndex != -1) {
        drafts[existingIndex] = draft;
      } else {
        drafts.add(draft);
      }
      
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_draftsKey, json.encode(drafts));
    } catch (e) {
      print('로컬 드래프트 저장 실패: $e');
      return false;
    }
  }

  Future<bool> removeLocalDraft(String draftId) async {
    try {
      final drafts = await getLocalDrafts();
      drafts.removeWhere((draft) => draft['id'] == draftId);
      
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_draftsKey, json.encode(drafts));
    } catch (e) {
      print('로컬 드래프트 삭제 실패: $e');
      return false;
    }
  }

  // 일반적인 키-값 저장
  Future<bool> setBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(key, value);
    } catch (e) {
      print('bool 값 저장 실패: $e');
      return false;
    }
  }

  Future<bool?> getBool(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key);
    } catch (e) {
      print('bool 값 가져오기 실패: $e');
      return null;
    }
  }

  Future<bool> setString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(key, value);
    } catch (e) {
      print('문자열 저장 실패: $e');
      return false;
    }
  }

  Future<String?> getString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      print('문자열 가져오기 실패: $e');
      return null;
    }
  }

  Future<bool> setInt(String key, int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setInt(key, value);
    } catch (e) {
      print('정수 저장 실패: $e');
      return false;
    }
  }

  Future<int?> getInt(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(key);
    } catch (e) {
      print('정수 가져오기 실패: $e');
      return null;
    }
  }

  Future<bool> setDouble(String key, double value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setDouble(key, value);
    } catch (e) {
      print('실수 저장 실패: $e');
      return false;
    }
  }

  Future<double?> getDouble(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(key);
    } catch (e) {
      print('실수 가져오기 실패: $e');
      return null;
    }
  }

  Future<bool> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(key);
    } catch (e) {
      print('키 삭제 실패: $e');
      return false;
    }
  }

  Future<bool> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.clear();
    } catch (e) {
      print('전체 데이터 삭제 실패: $e');
      return false;
    }
  }

  // 앱 첫 실행 여부 확인
  Future<bool> isFirstLaunch() async {
    const key = 'is_first_launch';
    final isFirst = await getBool(key);
    if (isFirst == null) {
      await setBool(key, false);
      return true;
    }
    return false;
  }

  // 튜토리얼 완료 여부
  Future<bool> isTutorialCompleted() async {
    const key = 'tutorial_completed';
    return await getBool(key) ?? false;
  }

  Future<bool> setTutorialCompleted() async {
    const key = 'tutorial_completed';
    return await setBool(key, true);
  }

  // 다크 모드 설정
  Future<bool?> isDarkMode() async {
    const key = 'dark_mode';
    return await getBool(key);
  }

  Future<bool> setDarkMode(bool isDark) async {
    const key = 'dark_mode';
    return await setBool(key, isDark);
  }

  // 알림 설정
  Future<bool> isNotificationEnabled() async {
    const key = 'notification_enabled';
    return await getBool(key) ?? true; // 기본값은 true
  }

  Future<bool> setNotificationEnabled(bool enabled) async {
    const key = 'notification_enabled';
    return await setBool(key, enabled);
  }
}