/// Paperly Mobile App - 팔로우 서비스
/// 
/// 이 파일은 작가 팔로우 관련 모든 API 호출을 담당합니다.
/// 작가 정보 조회, 팔로우/언팔로우, 팔로우 목록 관리 등의 기능을 제공합니다.
/// 
/// 주요 기능:
/// - 작가 팔로우/언팔로우 API 호출
/// - 팔로우한 작가 목록 조회
/// - 작가 상세 정보 및 통계 조회
/// - 작가 검색 및 추천
/// - 트렌딩 작가 조회
/// 
/// 기술적 특징:
/// - Dio 인터셉터를 통한 자동 인증 토큰 관리
/// - 에러 처리 및 사용자 친화적 메시지
/// - 캐싱을 통한 성능 최적화
/// - 네트워크 에러 시 재시도 로직

import 'package:dio/dio.dart';
import '../models/author_models.dart';
import '../utils/logger.dart';

/// 팔로우 서비스 클래스
/// 
/// 모든 작가 관련 API 호출을 담당하는 서비스 레이어입니다.
/// AuthService와 유사한 패턴으로 구현되어 일관성을 유지합니다.
class FollowService {
  
  // ============================================================================
  // 🔧 의존성 및 설정
  // ============================================================================
  
  final Dio _dio;                              // HTTP 클라이언트
  final Map<String, dynamic> _cache = {};      // 메모리 캐시
  final logger = loggerInstance;               // 로거 인스턴스
  
  /// 생성자: Dio 인스턴스 주입
  /// 
  /// AuthService에서 설정한 인터셉터가 이미 적용되어 있으므로
/// 자동으로 인증 토큰이 첨부되고 401 에러 시 토큰 갱신이 처리됩니다.
  FollowService({required Dio dio}) : _dio = dio;

  // ============================================================================
  // 👥 작가 정보 조회 API
  // ============================================================================

  /// 작가 상세 정보 조회
  /// 
  /// 특정 작가의 상세 정보와 통계를 가져옵니다.
  /// 현재 사용자의 팔로우 상태도 함께 반환됩니다.
  /// 
  /// 매개변수:
  /// - authorId: 조회할 작가의 고유 ID
  /// 
  /// 반환값:
  /// - Author: 작가 상세 정보 (팔로우 상태 포함)
  Future<Author> getAuthorDetails(String authorId) async {
    try {
      logger.i('작가 상세 정보 조회: $authorId');
      
      // 캐시 확인 (5분간 유효)
      final cacheKey = 'author_details_$authorId';
      final cachedData = _getCachedData(cacheKey, Duration(minutes: 5));
      if (cachedData != null) {
        return Author.fromJson(cachedData);
      }
      
      final response = await _dio.get('/authors/$authorId');
      final authorData = response.data['data'];
      
      // 캐시에 저장
      _setCachedData(cacheKey, authorData);
      
      logger.i('작가 상세 정보 조회 성공');
      return Author.fromJson(authorData);
    } on DioException catch (e) {
      logger.e('작가 상세 정보 조회 실패', error: e);
      throw _handleError(e);
    }
  }

  /// 작가 목록 조회 (검색)
  /// 
  /// 검색어나 필터 조건에 따라 작가 목록을 조회합니다.
  /// 페이지네이션을 지원하여 대량의 데이터를 효율적으로 처리합니다.
  /// 
  /// 매개변수:
  /// - request: 검색 조건 및 필터 (선택사항)
  /// 
  /// 반환값:
  /// - AuthorListResponse: 작가 목록과 페이지네이션 정보
  Future<AuthorListResponse> searchAuthors([AuthorSearchRequest? request]) async {
    try {
      logger.i('작가 검색: ${request?.query ?? '전체'}');
      
      final queryParams = <String, dynamic>{};
      if (request != null) {
        if (request.query?.isNotEmpty == true) queryParams['query'] = request.query;
        if (request.specialties?.isNotEmpty == true) queryParams['specialties'] = request.specialties!.join(',');
        if (request.verifiedOnly != null) queryParams['verified_only'] = request.verifiedOnly;
        if (request.sortBy?.isNotEmpty == true) queryParams['sort_by'] = request.sortBy;
        queryParams['sort_order'] = request.sortOrder;
        queryParams['page'] = request.page;
        queryParams['limit'] = request.limit;
      }
      
      final response = await _dio.get('/authors', queryParameters: queryParams);
      
      logger.i('작가 검색 성공');
      return AuthorListResponse.fromJson(response.data['data']);
    } on DioException catch (e) {
      logger.e('작가 검색 실패', error: e);
      throw _handleError(e);
    }
  }

  /// 트렌딩 작가 조회
  /// 
  /// 현재 인기 있는 작가들을 조회합니다.
  /// 팔로워 증가율, 글 조회수 등을 종합하여 선정됩니다.
  /// 
  /// 매개변수:
  /// - limit: 조회할 작가 수 (기본값: 10)
  /// 
  /// 반환값:
  /// - List<Author>: 트렌딩 작가 목록
  Future<List<Author>> getTrendingAuthors({int limit = 10}) async {
    try {
      logger.i('트렌딩 작가 조회: $limit명');
      
      // 캐시 확인 (10분간 유효)
      const cacheKey = 'trending_authors';
      final cachedData = _getCachedData(cacheKey, Duration(minutes: 10));
      if (cachedData != null) {
        return (cachedData as List).map((json) => Author.fromJson(json)).toList();
      }
      
      final response = await _dio.get('/authors/trending', queryParameters: {'limit': limit});
      final authorsData = response.data['data'] as List;
      
      // 캐시에 저장
      _setCachedData(cacheKey, authorsData);
      
      logger.i('트렌딩 작가 조회 성공');
      return authorsData.map((json) => Author.fromJson(json)).toList();
    } on DioException catch (e) {
      logger.e('트렌딩 작가 조회 실패', error: e);
      throw _handleError(e);
    }
  }

  /// AI 추천 작가 조회
  /// 
  /// 사용자의 읽기 패턴과 관심사를 분석하여 맞춤형 작가를 추천합니다.
  /// 
  /// 매개변수:
  /// - limit: 추천받을 작가 수 (기본값: 5)
  /// 
  /// 반환값:
  /// - RecommendedAuthorsResponse: 추천 작가 목록과 추천 이유
  Future<RecommendedAuthorsResponse> getRecommendedAuthors({int limit = 5}) async {
    try {
      logger.i('AI 추천 작가 조회: $limit명');
      
      final response = await _dio.get('/authors/recommended', queryParameters: {'limit': limit});
      
      logger.i('AI 추천 작가 조회 성공');
      return RecommendedAuthorsResponse.fromJson(response.data['data']);
    } on DioException catch (e) {
      logger.e('AI 추천 작가 조회 실패', error: e);
      throw _handleError(e);
    }
  }

  // ============================================================================
  // ❤️ 팔로우 관리 API
  // ============================================================================

  /// 작가 팔로우
  /// 
  /// 특정 작가를 팔로우하여 새 글 알림을 받고 피드에서 우선 표시합니다.
  /// 
  /// 매개변수:
  /// - authorId: 팔로우할 작가 ID
  /// 
  /// 반환값:
  /// - FollowResponse: 팔로우 결과와 변경된 팔로워 수
  Future<FollowResponse> followAuthor(String authorId) async {
    try {
      logger.i('작가 팔로우: $authorId');
      
      final response = await _dio.post('/authors/$authorId/follow');
      
      // 캐시 무효화
      _invalidateAuthorCache(authorId);
      
      logger.i('작가 팔로우 성공');
      return FollowResponse.fromJson(response.data['data']);
    } on DioException catch (e) {
      logger.e('작가 팔로우 실패', error: e);
      throw _handleError(e);
    }
  }

  /// 작가 언팔로우
  /// 
  /// 특정 작가를 언팔로우하여 팔로우 목록에서 제거합니다.
  /// 
  /// 매개변수:
  /// - authorId: 언팔로우할 작가 ID
  /// 
  /// 반환값:
  /// - FollowResponse: 언팔로우 결과와 변경된 팔로워 수
  Future<FollowResponse> unfollowAuthor(String authorId) async {
    try {
      logger.i('작가 언팔로우: $authorId');
      
      final response = await _dio.delete('/authors/$authorId/follow');
      
      // 캐시 무효화
      _invalidateAuthorCache(authorId);
      
      logger.i('작가 언팔로우 성공');
      return FollowResponse.fromJson(response.data['data']);
    } on DioException catch (e) {
      logger.e('작가 언팔로우 실패', error: e);
      throw _handleError(e);
    }
  }

  /// 팔로우한 작가 목록 조회
  /// 
  /// 현재 사용자가 팔로우하고 있는 모든 작가의 목록을 가져옵니다.
  /// 각 작가의 최신 글 정보도 함께 포함됩니다.
  /// 
  /// 매개변수:
  /// - page: 페이지 번호 (기본값: 1)
  /// - limit: 페이지당 항목 수 (기본값: 20)
  /// 
  /// 반환값:
  /// - AuthorListResponse: 팔로우한 작가 목록과 페이지네이션 정보
  Future<AuthorListResponse> getFollowingAuthors({int page = 1, int limit = 20}) async {
    try {
      logger.i('팔로우한 작가 목록 조회: 페이지 $page');
      
      final response = await _dio.get('/user/following', queryParameters: {
        'page': page,
        'limit': limit,
      });
      
      logger.i('팔로우한 작가 목록 조회 성공');
      return AuthorListResponse.fromJson(response.data['data']);
    } on DioException catch (e) {
      logger.e('팔로우한 작가 목록 조회 실패', error: e);
      throw _handleError(e);
    }
  }

  /// 팔로우 상태 확인
  /// 
  /// 특정 작가에 대한 현재 사용자의 팔로우 상태를 확인합니다.
  /// 
  /// 매개변수:
  /// - authorId: 확인할 작가 ID
  /// 
  /// 반환값:
  /// - bool: 팔로우 중이면 true, 아니면 false
  Future<bool> isFollowing(String authorId) async {
    try {
      logger.i('팔로우 상태 확인: $authorId');
      
      final response = await _dio.get('/authors/$authorId/follow-status');
      
      return response.data['data']['isFollowing'] as bool;
    } on DioException catch (e) {
      logger.e('팔로우 상태 확인 실패', error: e);
      // 에러 시 false 반환 (팔로우하지 않은 것으로 간주)
      return false;
    }
  }

  /// 팔로우 상태 일괄 확인
  /// 
  /// 여러 작가에 대한 팔로우 상태를 한 번에 확인합니다.
  /// 목록 화면에서 효율적인 상태 표시를 위해 사용됩니다.
  /// 
  /// 매개변수:
  /// - authorIds: 확인할 작가 ID 목록
  /// 
  /// 반환값:
  /// - Map<String, bool>: 작가 ID와 팔로우 상태의 매핑
  Future<Map<String, bool>> checkFollowStatus(List<String> authorIds) async {
    try {
      logger.i('팔로우 상태 일괄 확인: ${authorIds.length}명');
      
      if (authorIds.isEmpty) return {};
      
      final response = await _dio.post('/authors/follow-status', data: {
        'authorIds': authorIds,
      });
      
      final statusData = response.data['data'] as Map<String, dynamic>;
      return statusData.map((key, value) => MapEntry(key, value as bool));
    } on DioException catch (e) {
      logger.e('팔로우 상태 일괄 확인 실패', error: e);
      // 에러 시 모든 작가를 팔로우하지 않은 것으로 간주
      return {for (String id in authorIds) id: false};
    }
  }

  // ============================================================================
  // 📊 작가 통계 API
  // ============================================================================

  /// 작가 통계 정보 조회
  /// 
  /// 특정 작가의 상세 통계 정보를 가져옵니다.
  /// (팔로워 수, 글 수, 평균 평점 등)
  /// 
  /// 매개변수:
  /// - authorId: 통계를 조회할 작가 ID
  /// 
  /// 반환값:
  /// - AuthorStats: 작가 통계 정보
  Future<AuthorStats> getAuthorStats(String authorId) async {
    try {
      logger.i('작가 통계 조회: $authorId');
      
      // 캐시 확인 (1분간 유효)
      final cacheKey = 'author_stats_$authorId';
      final cachedData = _getCachedData(cacheKey, Duration(minutes: 1));
      if (cachedData != null) {
        return AuthorStats.fromJson(cachedData);
      }
      
      final response = await _dio.get('/authors/$authorId/stats');
      final statsData = response.data['data'];
      
      // 캐시에 저장
      _setCachedData(cacheKey, statsData);
      
      logger.i('작가 통계 조회 성공');
      return AuthorStats.fromJson(statsData);
    } on DioException catch (e) {
      logger.e('작가 통계 조회 실패', error: e);
      throw _handleError(e);
    }
  }

  // ============================================================================
  // 🗃️ 캐시 관리
  // ============================================================================

  /// 캐시된 데이터 조회
  /// 
  /// 키와 유효기간을 확인하여 캐시된 데이터를 반환합니다.
  dynamic _getCachedData(String key, Duration validDuration) {
    final cached = _cache[key];
    if (cached == null) return null;
    
    final cacheTime = cached['timestamp'] as DateTime;
    final data = cached['data'];
    
    if (DateTime.now().difference(cacheTime) < validDuration) {
      return data;
    } else {
      _cache.remove(key);
      return null;
    }
  }

  /// 데이터 캐시 저장
  void _setCachedData(String key, dynamic data) {
    _cache[key] = {
      'data': data,
      'timestamp': DateTime.now(),
    };
  }

  /// 특정 작가 관련 캐시 무효화
  void _invalidateAuthorCache(String authorId) {
    final keysToRemove = _cache.keys
        .where((key) => key.contains(authorId))
        .toList();
    
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }

  /// 전체 캐시 초기화
  void clearCache() {
    _cache.clear();
    logger.i('팔로우 서비스 캐시 초기화');
  }

  // ============================================================================
  // 🚨 에러 처리
  // ============================================================================

  /// Dio HTTP 에러를 사용자 친화적인 에러로 변환
  /// 
  /// AuthService와 동일한 패턴으로 에러를 처리합니다.
  Exception _handleError(DioException error) {
    if (error.response != null) {
      String message = '요청 처리 중 오류가 발생했습니다';
      
      final data = error.response!.data;
      if (data is Map<String, dynamic>) {
        // 새로운 에러 응답 구조: { "error": { "message": "..." } }
        if (data['error'] != null && data['error']['message'] != null) {
          message = data['error']['message'];
        }
        // 기존 구조도 지원: { "message": "..." }
        else if (data['message'] != null) {
          message = data['message'];
        }
      }
      
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