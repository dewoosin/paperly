// lib/services/auth_service.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';
import '../config/api_config.dart';
import '../utils/logger.dart';

/// 인증 서비스
class AuthService {
  final Dio _dio;
  final SharedPreferences _prefs;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  static const String _deviceIdKey = 'device_id';
  
  AuthService({
    required Dio dio,
    required SharedPreferences prefs,
  }) : _dio = dio, _prefs = prefs {
    _setupInterceptors();
  }

  /// 인터셉터 설정 (토큰 자동 갱신 등)
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Access Token 자동 추가
          final accessToken = await getAccessToken();
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          
          // Device ID 추가
          final deviceId = await _getDeviceId();
          options.headers['X-Device-Id'] = deviceId;
          
          handler.next(options);
        },
        onError: (error, handler) async {
          // 401 에러 시 토큰 갱신 시도
          if (error.response?.statusCode == 401) {
            // 토큰 갱신 요청이 아닌 경우에만 갱신 시도
            if (!error.requestOptions.path.contains('/auth/refresh')) {
              try {
                // Refresh token으로 새 토큰 발급 시도
                await refreshTokens();
                
                // 원래 요청 재시도
                final clonedRequest = await _retryRequest(error.requestOptions);
                return handler.resolve(clonedRequest);
              } catch (refreshError) {
                // 토큰 갱신 실패 시 로그아웃
                logger.e('토큰 갱신 실패, 로그아웃 처리', error: refreshError);
                await logout();
                return handler.reject(error);
              }
            } else {
              // Refresh token도 만료된 경우 로그아웃
              await logout();
              return handler.reject(error);
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  /// 회원가입
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      logger.i('회원가입 시도: ${request.email}');
      
      final response = await _dio.post(
        '/auth/register',
        data: {
          'email': request.email,
          'password': request.password,
          'name': request.name,
          'birthDate': request.birthDate.toIso8601String(),
          'gender': request.gender?.name,
        },
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

  /// 로그인
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

  /// 토큰 갱신
  Future<void> refreshTokens() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        throw Exception('Refresh token not found');
      }

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
    }
  }

  /// 로그아웃
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

  /// 이메일 인증
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

  /// 현재 로그인한 사용자 정보
  Future<User?> getCurrentUser() async {
    final userData = _prefs.getString(_userKey);
    if (userData == null) return null;
    
    try {
      return User.fromJson(json.decode(userData));
    } catch (e) {
      logger.e('사용자 정보 파싱 실패', error: e);
      return null;
    }
  }

  /// Access Token 가져오기
  Future<String?> getAccessToken() async {
    return _prefs.getString(_accessTokenKey);
  }

  /// Refresh Token 가져오기
  Future<String?> getRefreshToken() async {
    return _prefs.getString(_refreshTokenKey);
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
    await _prefs.setString(_accessTokenKey, tokens.accessToken);
    await _prefs.setString(_refreshTokenKey, tokens.refreshToken);
  }

  /// 사용자 정보 저장
  Future<void> _saveUser(User user) async {
    await _prefs.setString(_userKey, json.encode(user.toJson()));
  }

  /// 인증 데이터 삭제
  Future<void> _clearAuthData() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
    await _prefs.remove(_userKey);
  }

  /// 디바이스 ID 가져오기
  Future<String> _getDeviceId() async {
    // 저장된 디바이스 ID 확인
    String? storedDeviceId = _prefs.getString(_deviceIdKey);
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
    await _prefs.setString(_deviceIdKey, deviceId);
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

  /// 에러 처리
  Exception _handleError(DioException error) {
    if (error.response != null) {
      final message = error.response!.data['message'] ?? '요청 처리 중 오류가 발생했습니다';
      return Exception(message);
    }
    
    if (error.type == DioExceptionType.connectionTimeout) {
      return Exception('연결 시간이 초과되었습니다');
    }
    
    if (error.type == DioExceptionType.connectionError) {
      return Exception('네트워크 연결을 확인해주세요');
    }
    
    return Exception('알 수 없는 오류가 발생했습니다');
  }
}