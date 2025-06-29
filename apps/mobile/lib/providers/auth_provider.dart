/// Paperly 인증 상태 관리 Provider
/// 
/// 이 파일은 앱 전체의 로그인/로그아웃 상태를 관리합니다.
/// Provider 패턴을 사용하여 상태 변화를 모든 위젯에 전파합니다.
/// 
/// 주요 기능:
/// - 로그인/로그아웃 처리
/// - 회원가입 및 이메일 인증
/// - 토큰 자동 갱신
/// - 사용자 정보 캐싱
/// - 앱 시작 시 자동 로그인 시도
/// 
/// 상태 관리:
/// - ChangeNotifier를 상속하여 상태 변화 시 UI 자동 업데이트
/// - 비동기 작업 중 로딩 상태 관리
/// - 에러 상태 관리 및 사용자 피드백

import 'package:flutter/foundation.dart';      // ChangeNotifier용
import '../models/auth_models.dart';            // 사용자 모델
import '../services/auth_service.dart';         // 인증 API 서비스
/// 인증 상태 관리 Provider 클래스
/// 
/// ChangeNotifier를 상속하여 상태가 변경될 때마다
/// 이를 구독하는 모든 위젯들에게 자동으로 알립니다.
class AuthProvider extends ChangeNotifier {
  // 의존성 주입: 인증 관련 API 호출을 담당하는 서비스
  final AuthService _authService;
  
  // ============================================================================
  // 🔐 내부 상태 변수들 (private)
  // ============================================================================
  
  User? _currentUser;          // 현재 로그인한 사용자 정보
  bool _isLoading = false;     // 비동기 작업 진행 중 여부
  bool _isInitialized = false; // 앱 시작 시 초기화 완료 여부
  String? _error;              // 최근 발생한 에러 메시지

  /// 생성자: AuthService를 주입받아 초기화
  AuthProvider({required AuthService authService}) : _authService = authService;

  // ============================================================================
  // 📖 공개 Getter들 (외부에서 상태 조회용)
  // ============================================================================
  
  /// 현재 로그인한 사용자 정보 반환
  /// null이면 로그인되지 않은 상태
  User? get currentUser => _currentUser;
  
  /// 현재 비동기 작업(로그인, 회원가입 등) 진행 중인지 여부
  /// UI에서 로딩 인디케이터 표시용
  bool get isLoading => _isLoading;
  
  /// 앱 시작 시 초기화 작업(토큰 확인 등)이 완료되었는지 여부
  /// 스플래시 화면에서 다음 화면으로 이동 가능 여부 판단용
  bool get isInitialized => _isInitialized;
  
  /// 최근 발생한 에러 메시지
  /// UI에서 사용자에게 에러 알림 표시용
  String? get error => _error;
  
  /// 사용자가 로그인된 상태인지 여부
  /// 화면 접근 권한 제어 및 UI 분기 처리용
  bool get isAuthenticated => _currentUser != null;
  
  /// 사용자의 이메일이 인증되었는지 여부
  /// 특정 기능 접근 권한 제어용
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

  /// 이메일 인증 스킵 (개발용)
  Future<void> skipEmailVerification() async {
    try {
      _setLoading(true);
      _clearError();
      
      await _authService.skipEmailVerification();
      
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
