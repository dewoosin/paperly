// apps/mobile/lib/providers/auth_provider.dart

import 'package:flutter/foundation.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';

/// 인증 상태 관리 Provider
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  
  User? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  AuthProvider({required AuthService authService}) : _authService = authService;

  /// 현재 로그인한 사용자
  User? get currentUser => _currentUser;
  
  /// 로딩 상태
  bool get isLoading => _isLoading;
  
  /// 초기화 완료 여부
  bool get isInitialized => _isInitialized;
  
  /// 에러 메시지
  String? get error => _error;
  
  /// 로그인 여부
  bool get isAuthenticated => _currentUser != null;
  
  /// 이메일 인증 여부
  bool get isEmailVerified => _currentUser?.emailVerified ?? false;

  /// 초기화 (앱 시작 시 토큰 확인)
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _setLoading(true);
      
      // 저장된 사용자 정보 불러오기
      _currentUser = await _authService.getCurrentUser();
      
      // 토큰이 있으면 유효성 검증
      if (_currentUser != null) {
        final accessToken = await _authService.getAccessToken();
        if (accessToken == null) {
          // 토큰이 없으면 로그아웃 처리
          _currentUser = null;
        }
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      _currentUser = null;
      _isInitialized = true;
    } finally {
      _setLoading(false);
    }
  }

  /// 회원가입
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      _setLoading(true);
      _clearError();
      
      final response = await _authService.register(request);
      _currentUser = response.user;
      
      notifyListeners();
      return response;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 로그인
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      _setLoading(true);
      _clearError();
      
      final response = await _authService.login(request);
      _currentUser = response.user;
      
      notifyListeners();
      return response;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 로그아웃
  Future<void> logout({bool allDevices = false}) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _authService.logout(allDevices: allDevices);
      _currentUser = null;
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 이메일 인증
  Future<void> verifyEmail(String token) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _authService.verifyEmail(token);
      
      // 사용자 정보 업데이트
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(emailVerified: true);
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 인증 메일 재전송
  Future<void> resendVerificationEmail() async {
    try {
      _setLoading(true);
      _clearError();
      
      await _authService.resendVerificationEmail();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 사용자 정보 새로고침
  Future<void> refreshUser() async {
    try {
      _currentUser = await _authService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to refresh user: $e');
    }
  }

  /// 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 에러 설정
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// 에러 초기화
  void _clearError() {
    _error = null;
  }
}
