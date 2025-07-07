/// Paperly Mobile App - 인증 서비스
/// 
/// 이 파일은 앱의 모든 인증 관련 API 호출을 담당합니다.
/// 로그인, 회원가입, 토큰 관리, 자동 갱신 등의 기능을 제공합니다.
/// 
/// 주요 기능:
/// - 회원가입 및 로그인 API 호출
/// - JWT 토큰 자동 갱신 및 관리
/// - 로컬 저장소를 통한 인증 상태 유지
/// - 디바이스 식별 및 보안 관리
/// - 네트워크 에러 처리 및 재시도 로직
/// 
/// 기술적 특징:
/// - Dio 인터셉터를 통한 자동 토큰 첨부
/// - 401 에러 시 자동 토큰 갱신
/// - SharedPreferences를 통한 영구 저장
/// - 플랫폼별 디바이스 ID 생성

import 'dart:convert';                                    // JSON 인코딩/디코딩
import 'package:dio/dio.dart';                           // HTTP 클라이언트
import 'package:flutter/foundation.dart';                // 플랫폼 감지
import 'package:device_info_plus/device_info_plus.dart'; // 디바이스 정보
import '../models/auth_models.dart';                     // 인증 관련 모델
import '../config/api_config.dart';                      // API 설정
import '../utils/logger.dart';                           // 로깅 유틸리티
import 'error_translation_service.dart';                 // 에러 번역 서비스
import 'secure_storage_service.dart';                    // 보안 저장소 서비스

/// 인증 서비스 클래스
/// 
/// 앱의 모든 인증 관련 로직을 담당하는 서비스 레이어입니다.
/// Dio HTTP 클라이언트와 SharedPreferences를 의존성으로 주입받아 사용합니다.
class AuthService {
  
  // ============================================================================
  // 🔧 의존성 및 설정
  // ============================================================================
  
  final Dio _dio;                                       // HTTP 클라이언트
  final SecureStorageService _secureStorage;             // 보안 저장소
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin(); // 디바이스 정보 플러그인
  final logger = loggerInstance;                        // 로거 인스턴스
  
  // 토큰 갱신 동시성 제어를 위한 변수들
  Future<void>? _refreshTokenFuture;                    // 진행 중인 토큰 갱신 작업
  bool _isRefreshing = false;                           // 토큰 갱신 진행 상태
  
  // ============================================================================
  // 🔑 저장소 키 상수들
  // ============================================================================
  
  static const String _accessTokenKey = 'access_token';   // Access Token 저장 키
  static const String _refreshTokenKey = 'refresh_token'; // Refresh Token 저장 키
  static const String _userKey = 'user_data';             // 사용자 정보 저장 키
  static const String _deviceIdKey = 'device_id';         // 디바이스 ID 저장 키
  
  /// 생성자: 의존성 주입 및 초기화
  /// 
  /// 매개변수:
  /// - dio: HTTP 요청을 위한 Dio 인스턴스
  /// - secureStorage: 보안 데이터 저장을 위한 SecureStorageService 인스턴스
  /// 
  /// 생성과 동시에 Dio 인터셉터를 설정하여 자동 토큰 관리를 시작합니다.
  AuthService({
    required Dio dio,
    required SecureStorageService secureStorage,
  }) : _dio = dio, _secureStorage = secureStorage {
    _setupInterceptors();
  }

  /// Dio 인터셉터 설정
  /// 
  /// 모든 HTTP 요청에 대해 자동으로 다음 작업을 수행합니다:
  /// 1. Access Token을 Authorization 헤더에 자동 첨부
  /// 2. Device ID를 X-Device-Id 헤더에 첨부
  /// 3. 401 에러 시 자동 토큰 갱신 및 요청 재시도
  /// 4. 토큰 갱신 실패 시 자동 로그아웃 처리
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 모든 요청에 Access Token 자동 첨부
          // JWT Bearer 토큰 방식으로 인증 헤더 설정
          final accessToken = await getAccessToken();
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          
          // 디바이스 식별을 위한 고유 ID 헤더 추가
          // 서버에서 세션 관리 및 보안 목적으로 사용
          final deviceId = await _getDeviceId();
          options.headers['x-device-id'] = deviceId;
          
          handler.next(options);
        },
        onError: (error, handler) async {
          // 401 Unauthorized 에러 처리 (토큰 만료 등)
          if (error.response?.statusCode == 401) {
            // 토큰 갱신 요청이 아닌 경우에만 갱신 시도
            // 무한 루프 방지를 위한 조건 체크
            if (!error.requestOptions.path.contains('/auth/refresh')) {
              try {
                // 동시성 제어: 이미 진행 중인 토큰 갱신이 있으면 그 결과를 기다림
                if (_isRefreshing && _refreshTokenFuture != null) {
                  logger.i('토큰 갱신 대기 중...');
                  await _refreshTokenFuture;
                } else {
                  // 새로운 토큰 갱신 시작
                  _refreshTokenFuture = _performTokenRefresh();
                  await _refreshTokenFuture;
                }
                
                // 새 토큰으로 원래 요청 재시도
                final clonedRequest = await _retryRequest(error.requestOptions);
                return handler.resolve(clonedRequest);
              } catch (refreshError) {
                // 토큰 갱신 실패 시 완전한 로그아웃 처리
                logger.e('토큰 갱신 실패, 로그아웃 처리', error: refreshError);
                await logout();
                return handler.reject(error);
              }
            } else {
              // Refresh Token도 만료된 경우 (토큰 갱신 API 자체가 401)
              // 사용자를 로그인 화면으로 리디렉션
              await logout();
              return handler.reject(error);
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  /// 회원가입 API 호출
  /// 
  /// 새로운 사용자 계정을 생성하고 인증 토큰을 발급받습니다.
  /// 
  /// 매개변수:
  /// - request: 회원가입에 필요한 사용자 정보 (이메일, 비밀번호, 이름 등)
  /// 
  /// 반환값:
  /// - AuthResponse: 사용자 정보와 인증 토큰을 포함한 응답
  /// 
  /// 예외:
  /// - Exception: 회원가입 실패 시 (이메일 중복, 유효하지 않은 정보 등)
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      logger.i('회원가입 시도: ${request.email}');
      
      final response = await _dio.post(
        '/auth/register',
        data: request.toJson(),
      );

      final authResponse = AuthResponse.fromJson(response.data['data']);
      
      // 토큰 및 사용자 정보 저장
      await _saveAuthData(authResponse);
      
      logger.i('회원가입 성공');
      return authResponse;
    } on DioException catch (e) {
      logger.e('회원가입 실패', error: e);
      throw _handleError(e);
    }
  }

  /// 로그인 API 호출
  /// 
  /// 기존 사용자의 이메일과 비밀번호로 인증하여 토큰을 발급받습니다.
  /// 
  /// 매개변수:
  /// - request: 로그인 정보 (이메일, 비밀번호)
  /// 
  /// 반환값:
  /// - AuthResponse: 사용자 정보와 인증 토큰을 포함한 응답
  /// 
  /// 예외:
  /// - Exception: 로그인 실패 시 (잘못된 자격증명, 계정 비활성화 등)
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      logger.i('로그인 시도: ${request.email}');
      
      final response = await _dio.post(
        '/auth/login',
        data: request.toJson(),
      );

      final authResponse = AuthResponse.fromJson(response.data['data']);
      
      // 토큰 및 사용자 정보 저장
      await _saveAuthData(authResponse);
      
      logger.i('로그인 성공');
      return authResponse;
    } on DioException catch (e) {
      logger.e('로그인 실패', error: e);
      throw _handleError(e);
    }
  }

  /// JWT 토큰 갱신 (공개 메서드)
  /// 
  /// Refresh Token을 사용하여 새로운 Access Token을 발급받습니다.
  /// 동시성 제어가 적용되어 여러 요청이 동시에 들어와도 안전합니다.
  /// 
  /// 과정:
  /// 1. 진행 중인 토큰 갱신 작업이 있는지 확인
  /// 2. 있으면 대기, 없으면 새로 시작
  /// 3. 토큰 갱신 완료 후 상태 초기화
  Future<void> refreshTokens() async {
    if (_isRefreshing && _refreshTokenFuture != null) {
      // 이미 진행 중인 토큰 갱신이 있으면 그 결과를 기다림
      logger.i('토큰 갱신 대기 중...');
      await _refreshTokenFuture;
      return;
    }
    
    // 새로운 토큰 갱신 시작
    _refreshTokenFuture = _performTokenRefresh();
    await _refreshTokenFuture;
  }
  
  /// 실제 토큰 갱신 작업 수행 (내부 메서드)
  /// 
  /// 동시성 제어 플래그를 관리하며 실제 토큰 갱신을 수행합니다.
  /// 
  /// 과정:
  /// 1. 저장된 Refresh Token 확인
  /// 2. 서버에 토큰 갱신 요청
  /// 3. 새로운 토큰들을 로컬 저장소에 저장
  /// 4. 갱신 상태 플래그 정리
  /// 
  /// 예외:
  /// - Exception: Refresh Token이 없거나 만료된 경우
  Future<void> _performTokenRefresh() async {
    _isRefreshing = true;
    
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        throw Exception('Refresh token not found');
      }

      logger.i('토큰 갱신 시작');
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final tokens = AuthTokens.fromJson(response.data['data']['tokens']);
      await _saveTokens(tokens);
      
      logger.i('토큰 갱신 성공');
    } on DioException catch (e) {
      logger.e('토큰 갱신 실패', error: e);
      throw _handleError(e);
    } finally {
      // 갱신 상태 정리
      _isRefreshing = false;
      _refreshTokenFuture = null;
    }
  }

  /// 로그아웃 처리
  /// 
  /// 서버에 로그아웃을 알리고 로컬 저장된 모든 인증 정보를 삭제합니다.
  /// 
  /// 매개변수:
  /// - allDevices: true면 모든 기기에서 로그아웃, false면 현재 기기만
  /// 
  /// 과정:
  /// 1. 서버에 로그아웃 API 호출 (Refresh Token 무효화)
  /// 2. 로컬 저장소의 모든 인증 정보 삭제
  /// 3. API 호출 실패해도 로컬 정보는 반드시 삭제
  Future<void> logout({bool allDevices = false}) async {
    try {
      final refreshToken = await getRefreshToken();
      
      await _dio.post(
        '/auth/logout',
        data: {
          'refreshToken': refreshToken,
          'allDevices': allDevices,
        },
      );
    } catch (e) {
      // 로그아웃 API 실패해도 로컬 데이터는 삭제
      logger.e('로그아웃 API 호출 실패', error: e);
    } finally {
      // 로컬 저장된 인증 정보 삭제
      await _clearAuthData();
      logger.i('로그아웃 완료');
    }
  }

  /// 이메일 인증 처리
  /// 
  /// 사용자가 이메일로 받은 인증 토큰을 서버에 전송하여 이메일을 인증합니다.
  /// 
  /// 매개변수:
  /// - token: 이메일로 받은 인증 토큰 문자열
  /// 
  /// 과정:
  /// 1. 서버에 인증 토큰 전송
  /// 2. 성공 시 로컬 사용자 정보의 emailVerified를 true로 업데이트
  Future<void> verifyEmail(String token) async {
    try {
      await _dio.get('/auth/verify-email', queryParameters: {'token': token});
      
      // 사용자 정보 업데이트
      final user = await getCurrentUser();
      if (user != null) {
        final updatedUser = user.copyWith(emailVerified: true);
        await _saveUser(updatedUser);
      }
      
      logger.i('이메일 인증 성공');
    } on DioException catch (e) {
      logger.e('이메일 인증 실패', error: e);
      throw _handleError(e);
    }
  }

  /// 인증 메일 재발송
  Future<void> resendVerificationEmail() async {
    try {
      await _dio.post('/auth/resend-verification');
      logger.i('인증 메일 재발송 성공');
    } on DioException catch (e) {
      logger.e('인증 메일 재발송 실패', error: e);
      throw _handleError(e);
    }
  }

  /// 이메일 인증 스킵 (개발용)
  Future<void> skipEmailVerification() async {
    try {
      // 현재 사용자 정보에서 이메일 가져오기
      final user = await getCurrentUser();
      if (user == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다');
      }

      await _dio.post('/auth/skip-verification', data: {
        'email': user.email
      });
      
      // 사용자 정보 업데이트
      final updatedUser = user.copyWith(emailVerified: true);
      await _saveUser(updatedUser);
      
      logger.i('이메일 인증 스킵 성공');
    } on DioException catch (e) {
      logger.e('이메일 인증 스킵 실패', error: e);
      throw _handleError(e);
    }
  }

  /// 현재 로그인한 사용자 정보
  Future<User?> getCurrentUser() async {
    final userData = await _secureStorage.getUserData();
    if (userData == null) return null;
    
    try {
      return User.fromJson(userData);
    } catch (e) {
      logger.e('사용자 정보 파싱 실패', error: e);
      return null;
    }
  }

  /// Access Token 가져오기
  Future<String?> getAccessToken() async {
    return await _secureStorage.getAccessToken();
  }

  /// Refresh Token 가져오기
  Future<String?> getRefreshToken() async {
    return await _secureStorage.getRefreshToken();
  }

  /// 로그인 상태 확인
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    final user = await getCurrentUser();
    return token != null && user != null;
  }

  /// 인증 데이터 저장
  Future<void> _saveAuthData(AuthResponse authResponse) async {
    await _saveTokens(authResponse.tokens);
    await _saveUser(authResponse.user);
  }

  /// 토큰 저장
  Future<void> _saveTokens(AuthTokens tokens) async {
    await _secureStorage.saveTokens(tokens.accessToken, tokens.refreshToken);
  }

  /// 사용자 정보 저장
  Future<void> _saveUser(User user) async {
    // 사용자 정보를 JSON으로 직렬화하여 저장
    final userJson = {
      'id': user.id,
      'email': user.email,
      'name': user.name,
      'emailVerified': user.emailVerified,
      'birthDate': user.birthDate?.toIso8601String(),
      'gender': user.gender?.toString().split('.').last,
    };
    await _secureStorage.saveUserData(userJson);
  }

  /// 인증 데이터 삭제
  Future<void> _clearAuthData() async {
    await _secureStorage.clearAuthData();
  }

  /// 디바이스 고유 ID 생성 및 관리
  /// 
  /// 각 기기마다 고유한 식별자를 생성하여 서버에서 세션을 구분할 수 있게 합니다.
  /// 한 번 생성된 ID는 로컬에 저장되어 앱 재설치 전까지 유지됩니다.
  /// 
  /// 플랫폼별 ID 생성 방식:
  /// - Android: 기기의 ANDROID_ID 사용
  /// - iOS: identifierForVendor 사용
  /// - Web: 브라우저 정보 조합으로 고유 ID 생성
  /// - 실패 시: 타임스탬프 기반 폴백 ID 생성
  /// 
  /// 반환값:
  /// - String: 기기 고유 식별자
  Future<String> _getDeviceId() async {
    // 저장된 디바이스 ID 확인
    String? storedDeviceId = await _secureStorage.getDeviceId();
    if (storedDeviceId != null && storedDeviceId.isNotEmpty) {
      return storedDeviceId;
    }
    
    // 새로운 디바이스 ID 생성
    String deviceId;
    
    try {
      if (kIsWeb) {
        // 웹에서는 브라우저 정보를 기반으로 고유 ID 생성
        final webInfo = await _deviceInfo.webBrowserInfo;
        final userAgent = webInfo.userAgent ?? '';
        final vendor = webInfo.vendor ?? '';
        final platform = webInfo.platform ?? '';
        final language = webInfo.language ?? '';
        
        // 브라우저 정보와 타임스탬프를 조합하여 고유한 ID 생성
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final combined = '${vendor}_${platform}_${language}_${userAgent.hashCode}_$timestamp';
        deviceId = 'web_${combined.hashCode.toRadixString(16)}';
      } else {
        // 모바일 플랫폼
        if (defaultTargetPlatform == TargetPlatform.android) {
          final androidInfo = await _deviceInfo.androidInfo;
          deviceId = androidInfo.id;
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          final iosInfo = await _deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor ?? _generateFallbackId();
        } else {
          deviceId = _generateFallbackId();
        }
      }
    } catch (e) {
      logger.e('디바이스 ID 가져오기 실패', error: e);
      deviceId = _generateFallbackId();
    }
    
    // 생성된 디바이스 ID 저장
    await _secureStorage.saveDeviceId(deviceId);
    logger.i('새 디바이스 ID 생성 및 저장: $deviceId');
    
    return deviceId;
  }
  
  /// 대체 디바이스 ID 생성
  String _generateFallbackId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.hashCode;
    return 'fallback_${timestamp}_${random.toRadixString(16)}';
  }

  /// 요청 재시도
  Future<Response> _retryRequest(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    
    // 새로운 access token 추가
    final accessToken = await getAccessToken();
    if (accessToken != null) {
      options.headers?['Authorization'] = 'Bearer $accessToken';
    }
    
    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  /// Dio HTTP 에러를 사용자 친화적인 에러로 변환
  /// 
  /// 서버에서 받은 에러 응답을 분석하여 적절한 에러 메시지를 추출합니다.
  /// 네트워크 상태나 서버 응답 구조에 따라 다른 메시지를 반환합니다.
  /// 
  /// 처리하는 에러 유형:
  /// - 서버 에러 응답 (400, 401, 500 등): 서버 메시지 추출
  /// - 연결 타임아웃: "연결 시간이 초과되었습니다"
  /// - 네트워크 오류: "네트워크 연결을 확인해주세요"
  /// - 기타: "알 수 없는 오류가 발생했습니다"
  /// 
  /// 매개변수:
  /// - error: Dio에서 발생한 HTTP 에러
  /// 
  /// 반환값:
  /// - Exception: 사용자에게 표시할 수 있는 에러 메시지를 포함한 예외
  Exception _handleError(DioException error) {
    if (error.response != null) {
      // 에러 번역 서비스를 사용하여 사용자 친화적인 메시지 생성
      final data = error.response!.data;
      if (data is Map<String, dynamic>) {
        final translatedMessage = ErrorTranslationService.translateFromResponse(data);
        return Exception(translatedMessage);
      }
      
      // 응답 데이터가 없는 경우 HTTP 상태 코드 기반 메시지
      final statusCode = error.response!.statusCode ?? 0;
      final httpMessage = ErrorTranslationService.getHttpErrorMessage(statusCode);
      return Exception(httpMessage);
    }
    
    // 네트워크 에러인 경우
    if (error.type == DioExceptionType.connectionTimeout) {
      return Exception(ErrorTranslationService.translate('NETWORK.TIMEOUT'));
    }
    
    if (error.type == DioExceptionType.connectionError) {
      return Exception(ErrorTranslationService.translate('NETWORK.CONNECTION_ERROR'));
    }
    
    // 기타 에러
    return Exception(ErrorTranslationService.translate('UNKNOWN_ERROR'));
  }
}