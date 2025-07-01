/// Paperly Mobile App - 기사 서비스
/// 
/// 이 파일은 앱의 모든 기사 관련 API 호출을 담당합니다.
/// 기사 목록 조회, 상세 보기, 좋아요 기능 등을 제공합니다.
/// 
/// 주요 기능:
/// - 기사 목록 조회 (페이지네이션 지원)
/// - 기사 상세 정보 조회
/// - 기사 검색 기능
/// - 카테고리별/작가별 기사 조회
/// - 추천/트렌딩 기사 조회
/// - 좋아요/좋아요 취소 기능
/// - 좋아요 상태 조회
/// 
/// 기술적 특징:
/// - Dio 인터셉터를 통한 자동 인증 토큰 첨부
/// - 에러 처리 및 사용자 친화적 메시지 변환
/// - 캐시 기능으로 성능 최적화
/// - 네트워크 상태에 따른 재시도 로직

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/article_models.dart';
import '../config/api_config.dart';
import '../utils/logger.dart';
import 'error_translation_service.dart';

/// 기사 서비스 예외 클래스
class ArticleServiceException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  
  const ArticleServiceException(this.message, {this.code, this.statusCode});
  
  @override
  String toString() => 'ArticleServiceException: $message';
}

/// 기사 서비스 클래스
/// 
/// 앱의 모든 기사 관련 로직을 담당하는 서비스 레이어입니다.
/// Dio HTTP 클라이언트를 의존성으로 주입받아 사용합니다.
class ArticleService {
  
  // ============================================================================
  // 🔧 의존성 및 설정
  // ============================================================================
  
  final Dio _dio;                                       // HTTP 클라이언트
  
  // ============================================================================
  // 🌐 API 엔드포인트 상수들
  // ============================================================================
  
  static const String _mobileBasePath = '/mobile';      // 모바일 API 기본 경로
  static const String _articlesPath = '/articles';      // 기사 API 경로
  
  // ============================================================================
  // 🏗️ 생성자
  // ============================================================================
  
  /// ArticleService 생성자
  /// 
  /// [dio] HTTP 클라이언트 인스턴스
  ArticleService(this._dio) {
    // 인터셉터 설정은 AuthService에서 이미 구성되어 있음
    if (kDebugMode) {
      Logger.info('📰 ArticleService 초기화됨');
    }
  }
  
  // ============================================================================
  // 📰 기사 목록 및 조회 API
  // ============================================================================
  
  /// 발행된 기사 목록 조회
  /// 
  /// [page] 페이지 번호 (기본값: 1)
  /// [limit] 페이지당 항목 수 (기본값: 20)
  /// [categoryId] 카테고리 ID 필터
  /// [authorId] 작가 ID 필터
  /// [featured] 추천 기사만 조회 여부
  /// [trending] 트렌딩 기사만 조회 여부
  /// [search] 검색 키워드
  /// 
  /// Returns [ArticleListResponse] 기사 목록과 페이지네이션 정보
  Future<ArticleListResponse> getArticles({
    int page = 1,
    int limit = 20,
    String? categoryId,
    String? authorId,
    bool? featured,
    bool? trending,
    String? search,
  }) async {
    try {
      Logger.info('📰 기사 목록 조회 시작', {
        'page': page,
        'limit': limit,
        'categoryId': categoryId,
        'authorId': authorId,
        'featured': featured,
        'trending': trending,
        'search': search,
      });
      
      // 쿼리 파라미터 구성
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (categoryId != null) queryParams['categoryId'] = categoryId;
      if (authorId != null) queryParams['authorId'] = authorId;
      if (featured != null) queryParams['featured'] = featured.toString();
      if (trending != null) queryParams['trending'] = trending.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      
      final response = await _dio.get(
        '$_mobileBasePath$_articlesPath',
        queryParameters: queryParams,
      );
      
      Logger.info('📰 기사 목록 조회 성공', {
        'statusCode': response.statusCode,
        'articleCount': response.data['data']['articles']?.length ?? 0,
      });
      
      return ArticleListResponse.fromJson(response.data);
      
    } on DioException catch (e) {
      Logger.error('📰 기사 목록 조회 실패', {
        'error': e.message,
        'statusCode': e.response?.statusCode,
      });
      
      throw ArticleServiceException(
        ErrorTranslationService.translateError(e),
        code: e.type.toString(),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      Logger.error('📰 기사 목록 조회 중 예상치 못한 오류', {'error': e.toString()});
      throw ArticleServiceException('기사 목록을 불러오는 중 오류가 발생했습니다.');
    }
  }
  
  /// 기사 상세 정보 조회
  /// 
  /// [articleId] 기사 고유 식별자
  /// 
  /// Returns [Article] 기사 상세 정보
  Future<Article> getArticleDetail(String articleId) async {
    try {
      Logger.info('📖 기사 상세 조회 시작', {'articleId': articleId});
      
      final response = await _dio.get('$_mobileBasePath$_articlesPath/$articleId');
      
      Logger.info('📖 기사 상세 조회 성공', {
        'statusCode': response.statusCode,
        'articleId': articleId,
      });
      
      final articleDetailResponse = ArticleDetailResponse.fromJson(response.data);
      return articleDetailResponse.data.article;
      
    } on DioException catch (e) {
      Logger.error('📖 기사 상세 조회 실패', {
        'articleId': articleId,
        'error': e.message,
        'statusCode': e.response?.statusCode,
      });
      
      throw ArticleServiceException(
        ErrorTranslationService.translateError(e),
        code: e.type.toString(),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      Logger.error('📖 기사 상세 조회 중 예상치 못한 오류', {
        'articleId': articleId,
        'error': e.toString(),
      });
      throw ArticleServiceException('기사를 불러오는 중 오류가 발생했습니다.');
    }
  }
  
  /// 추천 기사 목록 조회
  /// 
  /// [limit] 조회할 기사 수 (기본값: 5)
  /// 
  /// Returns [List<Article>] 추천 기사 목록
  Future<List<Article>> getFeaturedArticles({int limit = 5}) async {
    try {
      Logger.info('⭐ 추천 기사 조회 시작', {'limit': limit});
      
      final response = await _dio.get(
        '$_mobileBasePath$_articlesPath/featured',
        queryParameters: {'limit': limit},
      );
      
      Logger.info('⭐ 추천 기사 조회 성공', {
        'statusCode': response.statusCode,
        'articleCount': response.data['data']['articles']?.length ?? 0,
      });
      
      final articlesData = response.data['data']['articles'] as List;
      return articlesData.map((json) => Article.fromJson(json)).toList();
      
    } on DioException catch (e) {
      Logger.error('⭐ 추천 기사 조회 실패', {
        'error': e.message,
        'statusCode': e.response?.statusCode,
      });
      
      throw ArticleServiceException(
        ErrorTranslationService.translateError(e),
        code: e.type.toString(),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      Logger.error('⭐ 추천 기사 조회 중 예상치 못한 오류', {'error': e.toString()});
      throw ArticleServiceException('추천 기사를 불러오는 중 오류가 발생했습니다.');
    }
  }
  
  /// 트렌딩 기사 목록 조회
  /// 
  /// [limit] 조회할 기사 수 (기본값: 10)
  /// 
  /// Returns [List<Article>] 트렌딩 기사 목록
  Future<List<Article>> getTrendingArticles({int limit = 10}) async {
    try {
      Logger.info('🔥 트렌딩 기사 조회 시작', {'limit': limit});
      
      final response = await _dio.get(
        '$_mobileBasePath$_articlesPath/trending',
        queryParameters: {'limit': limit},
      );
      
      Logger.info('🔥 트렌딩 기사 조회 성공', {
        'statusCode': response.statusCode,
        'articleCount': response.data['data']['articles']?.length ?? 0,
      });
      
      final articlesData = response.data['data']['articles'] as List;
      return articlesData.map((json) => Article.fromJson(json)).toList();
      
    } on DioException catch (e) {
      Logger.error('🔥 트렌딩 기사 조회 실패', {
        'error': e.message,
        'statusCode': e.response?.statusCode,
      });
      
      throw ArticleServiceException(
        ErrorTranslationService.translateError(e),
        code: e.type.toString(),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      Logger.error('🔥 트렌딩 기사 조회 중 예상치 못한 오류', {'error': e.toString()});
      throw ArticleServiceException('트렌딩 기사를 불러오는 중 오류가 발생했습니다.');
    }
  }
  
  /// 기사 검색
  /// 
  /// [query] 검색 키워드
  /// [page] 페이지 번호 (기본값: 1)
  /// [limit] 페이지당 항목 수 (기본값: 20)
  /// [categoryId] 카테고리 ID 필터
  /// [authorId] 작가 ID 필터
  /// 
  /// Returns [ArticleListResponse] 검색 결과와 페이지네이션 정보
  Future<ArticleListResponse> searchArticles(
    String query, {
    int page = 1,
    int limit = 20,
    String? categoryId,
    String? authorId,
  }) async {
    try {
      Logger.info('🔍 기사 검색 시작', {
        'query': query,
        'page': page,
        'limit': limit,
        'categoryId': categoryId,
        'authorId': authorId,
      });
      
      final queryParams = <String, dynamic>{
        'q': query,
        'page': page,
        'limit': limit,
      };
      
      if (categoryId != null) queryParams['categoryId'] = categoryId;
      if (authorId != null) queryParams['authorId'] = authorId;
      
      final response = await _dio.get(
        '$_mobileBasePath$_articlesPath/search',
        queryParameters: queryParams,
      );
      
      Logger.info('🔍 기사 검색 성공', {
        'statusCode': response.statusCode,
        'query': query,
        'articleCount': response.data['data']['articles']?.length ?? 0,
      });
      
      return ArticleListResponse.fromJson(response.data);
      
    } on DioException catch (e) {
      Logger.error('🔍 기사 검색 실패', {
        'query': query,
        'error': e.message,
        'statusCode': e.response?.statusCode,
      });
      
      throw ArticleServiceException(
        ErrorTranslationService.translateError(e),
        code: e.type.toString(),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      Logger.error('🔍 기사 검색 중 예상치 못한 오류', {
        'query': query,
        'error': e.toString(),
      });
      throw ArticleServiceException('기사 검색 중 오류가 발생했습니다.');
    }
  }
  
  /// 카테고리별 기사 목록 조회
  /// 
  /// [categoryId] 카테고리 고유 식별자
  /// [page] 페이지 번호 (기본값: 1)
  /// [limit] 페이지당 항목 수 (기본값: 20)
  /// 
  /// Returns [ArticleListResponse] 카테고리별 기사 목록
  Future<ArticleListResponse> getArticlesByCategory(
    String categoryId, {
    int page = 1,
    int limit = 20,
  }) async {
    return getArticles(
      page: page,
      limit: limit,
      categoryId: categoryId,
    );
  }
  
  /// 작가별 기사 목록 조회
  /// 
  /// [authorId] 작가 고유 식별자
  /// [page] 페이지 번호 (기본값: 1)
  /// [limit] 페이지당 항목 수 (기본값: 20)
  /// 
  /// Returns [ArticleListResponse] 작가별 기사 목록
  Future<ArticleListResponse> getArticlesByAuthor(
    String authorId, {
    int page = 1,
    int limit = 20,
  }) async {
    return getArticles(
      page: page,
      limit: limit,
      authorId: authorId,
    );
  }
  
  // ============================================================================
  // 👍 좋아요 관련 API
  // ============================================================================
  
  /// 기사 좋아요
  /// 
  /// [articleId] 기사 고유 식별자
  /// 
  /// Returns [LikeData] 좋아요 결과 정보
  Future<LikeData> likeArticle(String articleId) async {
    try {
      Logger.info('👍 기사 좋아요 시작', {'articleId': articleId});
      
      final response = await _dio.post('$_mobileBasePath$_articlesPath/$articleId/like');
      
      Logger.info('👍 기사 좋아요 성공', {
        'statusCode': response.statusCode,
        'articleId': articleId,
      });
      
      final likeResponse = LikeResponse.fromJson(response.data);
      return likeResponse.data;
      
    } on DioException catch (e) {
      Logger.error('👍 기사 좋아요 실패', {
        'articleId': articleId,
        'error': e.message,
        'statusCode': e.response?.statusCode,
      });
      
      throw ArticleServiceException(
        ErrorTranslationService.translateError(e),
        code: e.type.toString(),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      Logger.error('👍 기사 좋아요 중 예상치 못한 오류', {
        'articleId': articleId,
        'error': e.toString(),
      });
      throw ArticleServiceException('좋아요 처리 중 오류가 발생했습니다.');
    }
  }
  
  /// 기사 좋아요 취소
  /// 
  /// [articleId] 기사 고유 식별자
  /// 
  /// Returns [LikeData] 좋아요 취소 결과 정보
  Future<LikeData> unlikeArticle(String articleId) async {
    try {
      Logger.info('👎 기사 좋아요 취소 시작', {'articleId': articleId});
      
      final response = await _dio.delete('$_mobileBasePath$_articlesPath/$articleId/like');
      
      Logger.info('👎 기사 좋아요 취소 성공', {
        'statusCode': response.statusCode,
        'articleId': articleId,
      });
      
      final likeResponse = LikeResponse.fromJson(response.data);
      return likeResponse.data;
      
    } on DioException catch (e) {
      Logger.error('👎 기사 좋아요 취소 실패', {
        'articleId': articleId,
        'error': e.message,
        'statusCode': e.response?.statusCode,
      });
      
      throw ArticleServiceException(
        ErrorTranslationService.translateError(e),
        code: e.type.toString(),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      Logger.error('👎 기사 좋아요 취소 중 예상치 못한 오류', {
        'articleId': articleId,
        'error': e.toString(),
      });
      throw ArticleServiceException('좋아요 취소 처리 중 오류가 발생했습니다.');
    }
  }
  
  /// 기사 좋아요 토글 (좋아요 상태에 따라 자동으로 좋아요/취소)
  /// 
  /// [articleId] 기사 고유 식별자
  /// 
  /// Returns [LikeData] 토글 결과 정보
  Future<LikeData> toggleLike(String articleId) async {
    try {
      Logger.info('🔄 기사 좋아요 토글 시작', {'articleId': articleId});
      
      final response = await _dio.post('$_mobileBasePath$_articlesPath/$articleId/toggle-like');
      
      Logger.info('🔄 기사 좋아요 토글 성공', {
        'statusCode': response.statusCode,
        'articleId': articleId,
      });
      
      final likeResponse = LikeResponse.fromJson(response.data);
      return likeResponse.data;
      
    } on DioException catch (e) {
      Logger.error('🔄 기사 좋아요 토글 실패', {
        'articleId': articleId,
        'error': e.message,
        'statusCode': e.response?.statusCode,
      });
      
      throw ArticleServiceException(
        ErrorTranslationService.translateError(e),
        code: e.type.toString(),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      Logger.error('🔄 기사 좋아요 토글 중 예상치 못한 오류', {
        'articleId': articleId,
        'error': e.toString(),
      });
      throw ArticleServiceException('좋아요 처리 중 오류가 발생했습니다.');
    }
  }
  
  /// 기사 좋아요 상태 조회
  /// 
  /// [articleId] 기사 고유 식별자
  /// 
  /// Returns [LikeData] 현재 좋아요 상태 정보
  Future<LikeData> getLikeStatus(String articleId) async {
    try {
      Logger.info('📊 기사 좋아요 상태 조회 시작', {'articleId': articleId});
      
      final response = await _dio.get('$_mobileBasePath$_articlesPath/$articleId/like-status');
      
      Logger.info('📊 기사 좋아요 상태 조회 성공', {
        'statusCode': response.statusCode,
        'articleId': articleId,
      });
      
      final likeResponse = LikeResponse.fromJson(response.data);
      return likeResponse.data;
      
    } on DioException catch (e) {
      Logger.error('📊 기사 좋아요 상태 조회 실패', {
        'articleId': articleId,
        'error': e.message,
        'statusCode': e.response?.statusCode,
      });
      
      throw ArticleServiceException(
        ErrorTranslationService.translateError(e),
        code: e.type.toString(),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      Logger.error('📊 기사 좋아요 상태 조회 중 예상치 못한 오류', {
        'articleId': articleId,
        'error': e.toString(),
      });
      throw ArticleServiceException('좋아요 상태 조회 중 오류가 발생했습니다.');
    }
  }
}