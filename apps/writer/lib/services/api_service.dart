import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/environment.dart';

class ApiService {
  static String get baseUrl {
    final url = ApiConfig.baseUrl;
    print('🌐 API Base URL: $url');
    return url;
  }
  
  final http.Client _client = http.Client();

  // 헤더 생성
  Map<String, String> _getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Client-Type': 'writer', // Writer 클라이언트 식별 헤더
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  // 응답 처리
  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(body);
    } else {
      final error = json.decode(body);
      throw ApiException(
        statusCode: response.statusCode,
        message: error['error']?['message'] ?? error['message'] ?? 'Unknown error',
        code: error['error']?['code'] ?? error['code'],
      );
    }
  }

  // 인증 관련
  Future<Map<String, dynamic>> login(String email, String password) async {
    if (ApiConfig.enableDebugLogging) {
      print('🔐 로그인 시도: $email');
      print('🌐 서버 URL: $baseUrl/auth/login');
    }
    
    try {
      final requestBody = {
        'email': email,
        'password': password,
        'deviceInfo': {
          'deviceId': 'writer-app-${Platform.isIOS ? 'ios' : 'android'}',
          'userAgent': 'PaperlyWriter/${Platform.isIOS ? 'iOS' : 'Android'}',
          'ipAddress': Platform.isAndroid || Platform.isIOS ? null : '127.0.0.1',
        }
      };
      
      if (ApiConfig.enableDebugLogging) {
        // Only log non-sensitive parts
        print('📤 로그인 요청 전송...');
      }
      
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _getHeaders(),
        body: json.encode(requestBody),
      ).timeout(ApiConfig.requestTimeout);
      
      if (ApiConfig.enableDebugLogging) {
        print('📥 응답 상태: ${response.statusCode}');
      }
      
      final result = _handleResponse(response);
      if (ApiConfig.enableDebugLogging) {
        print('✅ 로그인 성공!');
      }
      return result;
      
    } on SocketException catch (e) {
      if (ApiConfig.enableDebugLogging) {
        print('❌ 네트워크 연결 오류: $e');
      }
      throw ApiException(
        statusCode: -1,
        message: '서버에 연결할 수 없습니다. 네트워크 연결을 확인해주세요.',
        code: 'NETWORK_ERROR',
      );
    } on HttpException catch (e) {
      if (ApiConfig.enableDebugLogging) {
        print('❌ HTTP 오류: $e');
      }
      throw ApiException(
        statusCode: -1,
        message: 'HTTP 오류가 발생했습니다.',
        code: 'HTTP_ERROR',
      );
    } catch (e) {
      if (ApiConfig.enableDebugLogging) {
        print('❌ 로그인 오류: $e');
      }
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: -1,
        message: '로그인 중 오류가 발생했습니다.',
        code: 'LOGIN_ERROR',
      );
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String username,
    String? bio,
    DateTime? birthDate,
    String userType = 'writer', // 작가 앱에서는 기본값으로 writer 타입 설정
  }) async {
    try {
      final requestBody = <String, dynamic>{
        'email': email,
        'password': password,
        'name': name,
        'username': username,
        'userType': userType, // 사용자 타입 추가
      };
      
      // null이 아닌 경우에만 추가
      if (bio != null) {
        requestBody['bio'] = bio;
      }
      if (birthDate != null) {
        requestBody['birthDate'] = birthDate.toIso8601String().split('T')[0]; // YYYY-MM-DD 형식으로 변환
      }
      
      if (ApiConfig.enableDebugLogging) {
        print('🔐 회원가입 요청 전송...');
        print('📋 Request body: ${json.encode(requestBody)}');
      }
      
      final response = await _client.post(
        Uri.parse('$baseUrl/writer/auth/register'),
        headers: _getHeaders(),
        body: json.encode(requestBody),
      );
      
      return _handleResponse(response);
    } on SocketException {
      // 개발용 mock 데이터 반환
      print('네트워크 오류 발생, mock 데이터 사용');
      return _getMockRegisterResponse(email, name, username);
    } catch (e) {
      if (e is ApiException) rethrow;
      // 개발용 mock 데이터 반환
      print('API 오류 발생, mock 데이터 사용: $e');
      return _getMockRegisterResponse(email, name, username);
    }
  }

  Future<void> logout(String token) async {
    try {
      await _client.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: _getHeaders(token: token),
      );
    } catch (e) {
      // 로그아웃 실패는 무시 (로컬에서는 정리)
      print('Logout request failed: $e');
    }
  }

  Future<Map<String, dynamic>> refreshToken(String token) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: _getHeaders(token: token),
      );
      
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: -1,
        message: '토큰 갱신에 실패했습니다.',
        code: 'TOKEN_REFRESH_FAILED',
      );
    }
  }

  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _getHeaders(token: token),
      );
      
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: -1,
        message: '사용자 정보를 가져올 수 없습니다.',
        code: 'USER_INFO_FAILED',
      );
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String token,
    String? name,
    String? bio,
    String? profileImageUrl,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (bio != null) body['bio'] = bio;
      if (profileImageUrl != null) body['profileImageUrl'] = profileImageUrl;
      
      final response = await _client.patch(
        Uri.parse('$baseUrl/auth/profile'),
        headers: _getHeaders(token: token),
        body: json.encode(body),
      );
      
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: -1,
        message: '프로필 업데이트에 실패했습니다.',
        code: 'PROFILE_UPDATE_FAILED',
      );
    }
  }

  // 기사 관련
  Future<Map<String, dynamic>> getArticles({
    String? token,
    int page = 1,
    int limit = 20,
    String? status,
    String? authorId,
    String? categoryId,
    bool? featured,
    bool? trending,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (status != null) queryParams['status'] = status;
      if (authorId != null) queryParams['authorId'] = authorId;
      if (categoryId != null) queryParams['categoryId'] = categoryId;
      if (featured != null) queryParams['featured'] = featured.toString();
      if (trending != null) queryParams['trending'] = trending.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      
      final uri = Uri.parse('$baseUrl/articles').replace(queryParameters: queryParams);
      
      final response = await _client.get(
        uri,
        headers: _getHeaders(token: token),
      );
      
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: -1,
        message: '기사 목록을 가져올 수 없습니다.',
        code: 'ARTICLES_FETCH_FAILED',
      );
    }
  }

  Future<Map<String, dynamic>> getMyArticles({
    required String token,
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (status != null) queryParams['status'] = status;
      
      final uri = Uri.parse('$baseUrl/articles/my').replace(queryParameters: queryParams);
      
      final response = await _client.get(
        uri,
        headers: _getHeaders(token: token),
      );
      
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: -1,
        message: '내 기사 목록을 가져올 수 없습니다.',
        code: 'MY_ARTICLES_FETCH_FAILED',
      );
    }
  }

  Future<Map<String, dynamic>> getArticle(String id, {String? token}) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/articles/$id'),
        headers: _getHeaders(token: token),
      );
      
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: -1,
        message: '기사를 가져올 수 없습니다.',
        code: 'ARTICLE_FETCH_FAILED',
      );
    }
  }

  Future<Map<String, dynamic>> createArticle({
    required String token,
    required Map<String, dynamic> articleData,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/articles'),
        headers: _getHeaders(token: token),
        body: json.encode(articleData),
      );
      
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: -1,
        message: '기사 생성에 실패했습니다.',
        code: 'ARTICLE_CREATE_FAILED',
      );
    }
  }

  Future<Map<String, dynamic>> updateArticle({
    required String token,
    required String id,
    required Map<String, dynamic> articleData,
  }) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/articles/$id'),
        headers: _getHeaders(token: token),
        body: json.encode(articleData),
      );
      
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: -1,
        message: '기사 수정에 실패했습니다.',
        code: 'ARTICLE_UPDATE_FAILED',
      );
    }
  }

  Future<Map<String, dynamic>> publishArticle({
    required String token,
    required String id,
  }) async {
    try {
      final response = await _client.patch(
        Uri.parse('$baseUrl/articles/$id/publish'),
        headers: _getHeaders(token: token),
      );
      
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: -1,
        message: '기사 발행에 실패했습니다.',
        code: 'ARTICLE_PUBLISH_FAILED',
      );
    }
  }

  Future<Map<String, dynamic>> unpublishArticle({
    required String token,
    required String id,
  }) async {
    try {
      final response = await _client.patch(
        Uri.parse('$baseUrl/articles/$id/unpublish'),
        headers: _getHeaders(token: token),
      );
      
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: -1,
        message: '기사 발행 취소에 실패했습니다.',
        code: 'ARTICLE_UNPUBLISH_FAILED',
      );
    }
  }

  Future<void> deleteArticle({
    required String token,
    required String id,
  }) async {
    try {
      await _client.delete(
        Uri.parse('$baseUrl/articles/$id'),
        headers: _getHeaders(token: token),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: -1,
        message: '기사 삭제에 실패했습니다.',
        code: 'ARTICLE_DELETE_FAILED',
      );
    }
  }

  // 통계 관련
  Future<Map<String, dynamic>> getWriterStats(String token) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/analytics/writer/stats'),
        headers: _getHeaders(token: token),
      );
      
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: -1,
        message: '통계 정보를 가져올 수 없습니다.',
        code: 'STATS_FETCH_FAILED',
      );
    }
  }

  Future<Map<String, dynamic>> getTrendingTopics() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/analytics/trending-topics'),
        headers: _getHeaders(),
      );
      
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: -1,
        message: '트렌딩 주제를 가져올 수 없습니다.',
        code: 'TRENDING_FETCH_FAILED',
      );
    }
  }

  // 작가 프로필 관련
  Future<Map<String, dynamic>> getWriterProfile(String token) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/writer/profile'),
        headers: _getHeaders(token: token),
      );
      
      return _handleResponse(response);
    } on SocketException {
      return _getMockWriterProfile();
    } catch (e) {
      if (e is ApiException) rethrow;
      return _getMockWriterProfile();
    }
  }

  Future<Map<String, dynamic>> createWriterProfile({
    required String token,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/writer/profile'),
        headers: _getHeaders(token: token),
        body: json.encode(profileData),
      );
      
      return _handleResponse(response);
    } on SocketException {
      return _getMockCreateWriterProfileResponse(profileData);
    } catch (e) {
      if (e is ApiException) rethrow;
      return _getMockCreateWriterProfileResponse(profileData);
    }
  }

  Future<Map<String, dynamic>> updateWriterProfile({
    required String token,
    required String profileId,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/writer/profile/$profileId'),
        headers: _getHeaders(token: token),
        body: json.encode(profileData),
      );
      
      return _handleResponse(response);
    } on SocketException {
      return _getMockUpdateWriterProfileResponse(profileData);
    } catch (e) {
      if (e is ApiException) rethrow;
      return _getMockUpdateWriterProfileResponse(profileData);
    }
  }

  Future<Map<String, dynamic>> uploadProfileImage({
    required String token,
    required String imagePath,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/writer/profile/upload-image'),
      );
      
      request.headers.addAll(_getHeaders(token: token));
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response);
    } on SocketException {
      return _getMockUploadImageResponse();
    } catch (e) {
      if (e is ApiException) rethrow;
      return _getMockUploadImageResponse();
    }
  }

  Future<Map<String, dynamic>> getWriterProfileStats({
    required String token,
    required String profileId,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/writer/profile/$profileId/stats'),
        headers: _getHeaders(token: token),
      );
      
      return _handleResponse(response);
    } on SocketException {
      return _getMockWriterProfileStats();
    } catch (e) {
      if (e is ApiException) rethrow;
      return _getMockWriterProfileStats();
    }
  }

  // 사용자명 중복 확인
  Future<Map<String, dynamic>> checkUsername(String username) async {
    try {
      final url = '$baseUrl/writer/auth/check-username';
      final headers = _getHeaders();
      final body = json.encode({'username': username});
      
      print('🔍 Username check URL: $url');
      print('📋 Headers: $headers');
      print('📦 Body: $body');
      
      final response = await _client.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );
      
      return _handleResponse(response);
    } on SocketException {
      // 네트워크 오류 시 mock 응답
      return _getMockUsernameCheckResponse(username);
    } catch (e) {
      if (e is ApiException) rethrow;
      // 기타 오류 시 mock 응답
      return _getMockUsernameCheckResponse(username);
    }
  }

  void dispose() {
    _client.close();
  }

  // Mock 데이터 함수들 (개발용)
  Map<String, dynamic> _getMockLoginResponse(String email) {
    return {
      'access_token': 'mock-jwt-token-${DateTime.now().millisecondsSinceEpoch}',
      'user': {
        'id': 'mock-user-${email.hashCode}',
        'email': email,
        'name': email.split('@')[0],
        'roles': ['writer'],
        'profileImageUrl': null,
        'bio': null,
        'profileCompleted': true,
        'emailVerified': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      }
    };
  }

  Map<String, dynamic> _getMockRegisterResponse(String email, String name, String username) {
    return {
      'access_token': 'mock-jwt-token-${DateTime.now().millisecondsSinceEpoch}',
      'user': {
        'id': 'mock-user-${email.hashCode}',
        'email': email,
        'name': name,
        'roles': ['writer'],
        'profileImageUrl': null,
        'bio': null,
        'profileCompleted': false,
        'emailVerified': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      }
    };
  }

  Map<String, dynamic> _getMockWriterProfile() {
    // 프로필이 없는 경우를 시뮬레이션
    throw ApiException(
      statusCode: 404,
      message: '작가 프로필이 존재하지 않습니다.',
      code: 'PROFILE_NOT_FOUND',
    );
  }

  Map<String, dynamic> _getMockCreateWriterProfileResponse(Map<String, dynamic> profileData) {
    final now = DateTime.now();
    return {
      'profile': {
        'id': 'mock-profile-${now.millisecondsSinceEpoch}',
        'user_id': 'mock-user-123',
        'display_name': profileData['display_name'],
        'bio': profileData['bio'],
        'profile_image_url': profileData['profile_image_url'],
        'specialties': profileData['specialties'] ?? [],
        'years_of_experience': profileData['years_of_experience'] ?? 0,
        'education': profileData['education'],
        'previous_publications': profileData['previous_publications'] ?? [],
        'awards': profileData['awards'] ?? [],
        'website_url': profileData['website_url'],
        'twitter_handle': profileData['twitter_handle'],
        'instagram_handle': profileData['instagram_handle'],
        'linkedin_url': profileData['linkedin_url'],
        'contact_email': profileData['contact_email'],
        'is_available_for_collaboration': profileData['is_available_for_collaboration'] ?? true,
        'preferred_topics': profileData['preferred_topics'] ?? [],
        'writing_schedule': profileData['writing_schedule'],
        'is_verified': false,
        'verification_date': null,
        'verification_notes': null,
        'total_articles': 0,
        'total_views': 0,
        'total_likes': 0,
        'follower_count': 0,
        'profile_completed': _checkProfileCompletion(profileData),
        'last_active_at': now.toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      }
    };
  }

  Map<String, dynamic> _getMockUpdateWriterProfileResponse(Map<String, dynamic> profileData) {
    final now = DateTime.now();
    return {
      'profile': {
        'id': 'mock-profile-123',
        'user_id': 'mock-user-123',
        'display_name': profileData['display_name'],
        'bio': profileData['bio'],
        'profile_image_url': profileData['profile_image_url'],
        'specialties': profileData['specialties'] ?? [],
        'years_of_experience': profileData['years_of_experience'] ?? 0,
        'education': profileData['education'],
        'previous_publications': profileData['previous_publications'] ?? [],
        'awards': profileData['awards'] ?? [],
        'website_url': profileData['website_url'],
        'twitter_handle': profileData['twitter_handle'],
        'instagram_handle': profileData['instagram_handle'],
        'linkedin_url': profileData['linkedin_url'],
        'contact_email': profileData['contact_email'],
        'is_available_for_collaboration': profileData['is_available_for_collaboration'] ?? true,
        'preferred_topics': profileData['preferred_topics'] ?? [],
        'writing_schedule': profileData['writing_schedule'],
        'is_verified': false,
        'verification_date': null,
        'verification_notes': null,
        'total_articles': 3,
        'total_views': 1250,
        'total_likes': 89,
        'follower_count': 12,
        'profile_completed': _checkProfileCompletion(profileData),
        'last_active_at': now.toIso8601String(),
        'created_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        'updated_at': now.toIso8601String(),
      }
    };
  }

  Map<String, dynamic> _getMockUploadImageResponse() {
    return {
      'image_url': 'https://picsum.photos/200/200?random=${DateTime.now().millisecondsSinceEpoch}',
      'success': true,
    };
  }

  Map<String, dynamic> _getMockWriterProfileStats() {
    return {
      'total_articles': 3,
      'total_views': 1250,
      'total_likes': 89,
      'follower_count': 12,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _getMockUsernameCheckResponse(String username) {
    // 개발용 mock: 특정 사용자명들은 이미 사용 중으로 시뮬레이션
    final List<String> usedUsernames = [
      'admin', 'test', 'user', 'writer', 'author', 'paperly'
    ];
    
    final bool isAvailable = !usedUsernames.contains(username.toLowerCase());
    
    return {
      'available': isAvailable,
      'message': isAvailable 
          ? '사용 가능한 아이디입니다' 
          : '이미 사용 중인 아이디입니다'
    };
  }

  bool _checkProfileCompletion(Map<String, dynamic> profileData) {
    final displayName = profileData['display_name'];
    final bio = profileData['bio'];
    final specialties = profileData['specialties'] as List?;
    
    return displayName != null && 
           displayName.toString().isNotEmpty &&
           bio != null && 
           bio.toString().isNotEmpty &&
           specialties != null && 
           specialties.isNotEmpty;
  }

  // Dashboard 관련 메서드들
  /// 대시보드 메인 메트릭 조회
  Future<Map<String, dynamic>> getDashboardMetrics({String? token}) async {
    if (ApiConfig.enableDebugLogging) {
      print('📊 대시보드 메트릭 요청');
    }
    
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/dashboard/metrics'),
        headers: _getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);
      
      if (ApiConfig.enableDebugLogging) {
        print('📥 대시보드 메트릭 응답 수신: ${response.statusCode}');
      }
      
      return _handleResponse(response);
    } catch (e) {
      if (ApiConfig.enableDebugLogging) {
        print('❌ 대시보드 메트릭 요청 실패: $e');
      }
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: -1,
        message: '대시보드 데이터를 불러오는데 실패했습니다.',
        code: 'DASHBOARD_METRICS_FAILED',
      );
    }
  }

  /// 실시간 메트릭 조회
  Future<Map<String, dynamic>> getRealtimeMetrics({String? token}) async {
    if (ApiConfig.enableDebugLogging) {
      print('⚡ 실시간 메트릭 요청');
    }
    
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/dashboard/metrics/realtime'),
        headers: _getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);
      
      return _handleResponse(response);
    } catch (e) {
      if (ApiConfig.enableDebugLogging) {
        print('⚠️ 실시간 메트릭 요청 실패: $e');
      }
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: -1,
        message: '실시간 데이터를 불러오는데 실패했습니다.',
        code: 'REALTIME_METRICS_FAILED',
      );
    }
  }

  /// 상세 메트릭 조회 (기간별)
  Future<Map<String, dynamic>> getDetailedMetrics({
    String? token,
    String? startDate,
    String? endDate,
    String granularity = 'day',
  }) async {
    try {
      final queryParams = <String, String>{
        'granularity': granularity,
      };
      
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      
      final uri = Uri.parse('$baseUrl/dashboard/metrics/detailed')
          .replace(queryParameters: queryParams);
      
      final response = await _client.get(
        uri,
        headers: _getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);
      
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: -1,
        message: '상세 메트릭을 불러오는데 실패했습니다.',
        code: 'DETAILED_METRICS_FAILED',
      );
    }
  }

  /// 기간별 메트릭 조회
  Future<Map<String, dynamic>> getPeriodMetrics(
    String period, {
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/dashboard/metrics/period')
          .replace(queryParameters: {'period': period});
      
      final response = await _client.get(
        uri,
        headers: _getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);
      
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: -1,
        message: '기간별 메트릭을 불러오는데 실패했습니다.',
        code: 'PERIOD_METRICS_FAILED',
      );
    }
  }

  /// 비교 메트릭 조회
  Future<Map<String, dynamic>> getComparisonMetrics(
    String compareWith, {
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/dashboard/metrics/comparison')
          .replace(queryParameters: {'compareWith': compareWith});
      
      final response = await _client.get(
        uri,
        headers: _getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);
      
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: -1,
        message: '비교 메트릭을 불러오는데 실패했습니다.',
        code: 'COMPARISON_METRICS_FAILED',
      );
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? code;

  ApiException({
    required this.statusCode,
    required this.message,
    this.code,
  });

  @override
  String toString() {
    return 'ApiException($statusCode): $message${code != null ? ' ($code)' : ''}';
  }
}