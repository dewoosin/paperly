import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/error_translation_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;

  User? _user;
  String? _token;
  bool _isLoading = true;
  String? _error;

  AuthProvider({
    required ApiService apiService,
    required StorageService storageService,
  }) : _apiService = apiService, _storageService = storageService {
    _initAuth();
  }

  // Getters
  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null && _token != null;
  String? get error => _error;

  Future<void> _initAuth() async {
    try {
      _isLoading = true;
      notifyListeners();

      // 저장된 토큰 확인
      final savedToken = await _storageService.getToken();
      if (savedToken != null) {
        _token = savedToken;
        
        // 토큰으로 사용자 정보 가져오기
        try {
          final userData = await _apiService.getCurrentUser(savedToken);
          _user = User.fromJson(userData);
          _error = null;
        } catch (e) {
          // 토큰이 유효하지 않으면 삭제
          await _storageService.removeToken();
          _token = null;
          _user = null;
          _error = '로그인이 만료되었습니다.';
        }
      }
    } catch (e) {
      _error = '인증 초기화 실패: $e';
      print('Auth init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('🔑 AuthProvider: 로그인 시작 - $email');
      final response = await _apiService.login(email, password);
      print('📦 AuthProvider: 서버 응답 받음 - ${response.toString()}');
      
      // 백엔드 응답 형식: { "success": true, "data": { "user": {...}, "tokens": {...} } }
      final data = response['data'] ?? response;
      final tokens = data['tokens'] ?? {};
      final userData = data['user'] ?? {};
      
      _token = tokens['accessToken'] ?? response['accessToken'] ?? response['access_token'];
      _user = User.fromJson(userData);
      
      print('🎫 AuthProvider: 토큰 추출됨 - ${_token?.substring(0, 20)}...');
      print('👤 AuthProvider: 사용자 정보 - ${_user?.name}');
      
      // 토큰 저장
      if (_token != null) {
        await _storageService.saveToken(_token!);
        print('💾 AuthProvider: 토큰 저장 완료');
      }
      
      _error = null;
      _isLoading = false;
      notifyListeners();
      
      print('✅ AuthProvider: 로그인 완료');
      return true;
    } catch (e) {
      print('❌ AuthProvider: 로그인 실패 - $e');
      _error = ErrorTranslationService.translateFromError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String username,
    String? bio,
    DateTime? birthDate,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.register(
        email: email,
        password: password,
        name: name,
        username: username,
        bio: bio,
        birthDate: birthDate,
      );
      
      // 백엔드 응답 형식: { "success": true, "data": { "user": {...}, "tokens": {...} } }
      final data = response['data'] ?? response;
      final tokens = data['tokens'] ?? {};
      final userData = data['user'] ?? {};
      
      _token = tokens['accessToken'] ?? response['accessToken'] ?? response['access_token'];
      _user = User.fromJson(userData);
      
      // 토큰 저장
      if (_token != null) {
        await _storageService.saveToken(_token!);
      }
      
      _error = null;
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = ErrorTranslationService.translateFromError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 프로필 완성 여부 확인
  bool get needsProfileSetup => _user != null && !_user!.profileCompleted;

  Future<void> logout() async {
    try {
      // 서버에 로그아웃 요청 (선택적)
      if (_token != null) {
        try {
          await _apiService.logout(_token!);
        } catch (e) {
          print('Server logout failed: $e');
        }
      }
    } finally {
      // 로컬 데이터 정리
      await _storageService.removeToken();
      _token = null;
      _user = null;
      _error = null;
      notifyListeners();
    }
  }

  Future<bool> refreshToken() async {
    try {
      if (_token == null) return false;
      
      final response = await _apiService.refreshToken(_token!);
      _token = response['accessToken'] ?? response['access_token'];
      
      if (_token != null) {
        await _storageService.saveToken(_token!);
        return true;
      }
      
      return false;
    } catch (e) {
      print('Token refresh failed: $e');
      await logout();
      return false;
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? bio,
    String? profileImageUrl,
  }) async {
    try {
      if (_token == null || _user == null) return false;
      
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.updateProfile(
        token: _token!,
        name: name,
        bio: bio,
        profileImageUrl: profileImageUrl,
      );
      
      _user = User.fromJson(response);
      _error = null;
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = '프로필 업데이트 실패: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> checkUsernameAvailability(String username) async {
    try {
      final result = await _apiService.checkUsername(username);
      return result;
    } catch (e) {
      print('Username check failed: $e');
      return null;
    }
  }
}