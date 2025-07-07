/// Paperly Mobile App - 기사 관련 데이터 모델
/// 
/// 이 파일은 기사 및 좋아요 시스템에서 사용되는 모든 데이터 모델을 정의합니다.
/// Freezed 패키지를 사용하여 불변객체와 직렬화 기능을 제공합니다.
/// 
/// 주요 모델들:
/// - Article: 기사 정보 (제목, 내용, 작가 정보 등)
/// - ArticleListResponse: 기사 목록 API 응답
/// - ArticleLike: 좋아요 상태 및 개수
/// - Category: 기사 카테고리 정보
/// 
/// 기술적 특징:
/// - Freezed로 생성된 불변객체 (immutable)
/// - JSON 직렬화/역직렬화 자동 생성
/// - copyWith 메서드로 부분 업데이트 가능
/// - 패턴 매칭과 동등성 비교 자동 지원

import 'package:freezed_annotation/freezed_annotation.dart';

// Freezed에 의해 자동 생성되는 파일들
part 'article_models.freezed.dart';  // 클래스 구현과 유틸리티 메서드들
// part 'article_models.g.dart';        // JSON 직렬화 메서드들 - Temporarily disabled

/// 기사 상태 열거형
/// 
/// 서버에서 오는 기사 상태를 정의합니다.
enum ArticleStatus {
  @JsonValue('draft')
  draft,
  @JsonValue('review')
  review,
  @JsonValue('published')
  published,
  @JsonValue('archived')
  archived,
  @JsonValue('deleted')
  deleted,
}

/// 기사 가시성 열거형
/// 
/// 기사의 공개 범위를 정의합니다.
enum ArticleVisibility {
  @JsonValue('public')
  public,
  @JsonValue('private')
  private,
  @JsonValue('unlisted')
  unlisted,
}

/// 기사 정보 모델
/// 
/// 서버에서 받은 기사 데이터를 클라이언트에서 사용하기 위한 형태로 변환합니다.
/// 기사 목록과 상세 화면에서 공통으로 사용됩니다.
/// 
/// 필드 설명:
/// - id: 기사 고유 식별자
/// - title: 기사 제목
/// - slug: URL에서 사용되는 기사 식별자
/// - summary: 기사 요약 (목록에서 표시)
/// - content: 기사 전체 내용 (상세에서만 사용)
/// - featuredImageUrl: 기사 대표 이미지 URL
/// - authorId: 작가 고유 식별자
/// - authorName: 작가 이름
/// - categoryId: 카테고리 고유 식별자
/// - status: 기사 상태
/// - visibility: 기사 공개 범위
/// - viewCount: 조회수
/// - likeCount: 좋아요 수
/// - shareCount: 공유 수
/// - commentCount: 댓글 수
/// - isFeatured: 추천 기사 여부
/// - isTrending: 트렌딩 기사 여부
/// - estimatedReadingTime: 예상 읽기 시간 (분)
/// - publishedAt: 발행 일시
/// - createdAt: 생성 일시
/// - updatedAt: 수정 일시
@freezed
class Article with _$Article {
  const Article._();
  const factory Article({
    required String id,
    required String title,
    required String slug,
    String? subtitle,
    String? excerpt,
    String? summary,
    String? content,
    String? contentHtml,
    String? featuredImageUrl,
    String? featuredImageAlt,
    required String authorId,
    String? authorName,
    String? categoryId,
    String? seoTitle,
    String? seoDescription,
    @Default(ArticleStatus.published) ArticleStatus status,
    @Default(ArticleVisibility.public) ArticleVisibility visibility,
    @Default(0) int viewCount,
    @Default(0) int likeCount,
    @Default(0) int shareCount,
    @Default(0) int commentCount,
    @Default(false) bool isFeatured,
    @Default(false) bool isTrending,
    int? readingTimeMinutes,
    int? estimatedReadingTime,
    int? wordCount,
    DateTime? scheduledAt,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _Article;

  /// JSON에서 Article 객체로 변환
  /// 
  /// 서버에서 오는 데이터를 모바일 앱에서 사용할 수 있도록 변환합니다.
  /// 일부 필드명이 서버와 다를 수 있어 매핑 처리를 합니다.
  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      excerpt: json['excerpt']?.toString(),
      summary: json['summary']?.toString() ?? json['excerpt']?.toString(),
      content: json['content']?.toString(),
      contentHtml: json['contentHtml']?.toString() ?? json['content_html']?.toString(),
      featuredImageUrl: json['featuredImageUrl']?.toString() ?? json['featured_image_url']?.toString(),
      featuredImageAlt: json['featuredImageAlt']?.toString() ?? json['featured_image_alt']?.toString(),
      authorId: json['authorId']?.toString() ?? json['author_id']?.toString() ?? '',
      authorName: json['authorName']?.toString() ?? json['author_name']?.toString(),
      categoryId: json['categoryId']?.toString() ?? json['category_id']?.toString(),
      seoTitle: json['seoTitle']?.toString() ?? json['seo_title']?.toString(),
      seoDescription: json['seoDescription']?.toString() ?? json['seo_description']?.toString(),
      status: _parseArticleStatus(json['status']?.toString()),
      visibility: _parseArticleVisibility(json['visibility']?.toString()),
      viewCount: _parseInt(json['viewCount'] ?? json['view_count']) ?? 0,
      likeCount: _parseInt(json['likeCount'] ?? json['like_count']) ?? 0,
      shareCount: _parseInt(json['shareCount'] ?? json['share_count']) ?? 0,
      commentCount: _parseInt(json['commentCount'] ?? json['comment_count']) ?? 0,
      isFeatured: json['isFeatured'] ?? json['is_featured'] ?? false,
      isTrending: json['isTrending'] ?? json['is_trending'] ?? false,
      readingTimeMinutes: _parseInt(json['readingTimeMinutes'] ?? json['reading_time_minutes']),
      estimatedReadingTime: _parseInt(json['estimatedReadingTime'] ?? json['estimated_reading_time']),
      wordCount: _parseInt(json['wordCount'] ?? json['word_count']),
      scheduledAt: _parseDateTime(json['scheduledAt'] ?? json['scheduled_at']),
      publishedAt: _parseDateTime(json['publishedAt'] ?? json['published_at']),
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
      deletedAt: _parseDateTime(json['deletedAt'] ?? json['deleted_at']),
    );
  }

}

/// 기사 목록 API 응답 모델
/// 
/// 서버에서 기사 목록을 조회할 때 받는 응답 데이터 구조입니다.
/// 페이지네이션 정보와 함께 기사 목록을 포함합니다.
@freezed
class ArticleListResponse with _$ArticleListResponse {
  const factory ArticleListResponse({
    required bool success,
    required ArticleListData data,
  }) = _ArticleListResponse;

  factory ArticleListResponse.fromJson(Map<String, dynamic> json) =>
      _$ArticleListResponseFromJson(json);
}

/// 기사 목록 데이터 모델
@freezed
class ArticleListData with _$ArticleListData {
  const factory ArticleListData({
    required List<Article> articles,
    required Pagination pagination,
    String? query,
    String? categoryId,
    String? authorId,
  }) = _ArticleListData;

  factory ArticleListData.fromJson(Map<String, dynamic> json) =>
      _$ArticleListDataFromJson(json);
}

/// 페이지네이션 정보 모델
@freezed
class Pagination with _$Pagination {
  const factory Pagination({
    required int total,
    required int page,
    required int limit,
    required int totalPages,
  }) = _Pagination;

  factory Pagination.fromJson(Map<String, dynamic> json) =>
      _$PaginationFromJson(json);
}

/// 기사 상세 API 응답 모델
@freezed
class ArticleDetailResponse with _$ArticleDetailResponse {
  const factory ArticleDetailResponse({
    required bool success,
    required ArticleDetailData data,
  }) = _ArticleDetailResponse;

  factory ArticleDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$ArticleDetailResponseFromJson(json);
}

/// 기사 상세 데이터 모델
@freezed
class ArticleDetailData with _$ArticleDetailData {
  const factory ArticleDetailData({
    required Article article,
  }) = _ArticleDetailData;

  factory ArticleDetailData.fromJson(Map<String, dynamic> json) =>
      _$ArticleDetailDataFromJson(json);
}

/// 좋아요 응답 모델
/// 
/// 좋아요/좋아요 취소 API 호출 시 받는 응답 데이터입니다.
/// 현재 좋아요 상태와 총 좋아요 수를 포함합니다.
@freezed
class LikeResponse with _$LikeResponse {
  const factory LikeResponse({
    required bool success,
    required LikeData data,
  }) = _LikeResponse;

  factory LikeResponse.fromJson(Map<String, dynamic> json) =>
      _$LikeResponseFromJson(json);
}

/// 좋아요 데이터 모델
@freezed
class LikeData with _$LikeData {
  const factory LikeData({
    required bool liked,
    required int likeCount,
    String? message,
  }) = _LikeData;

  factory LikeData.fromJson(Map<String, dynamic> json) =>
      _$LikeDataFromJson(json);
}

/// 카테고리 정보 모델
/// 
/// 기사를 분류하는 카테고리 정보를 담습니다.
@freezed
class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    required String slug,
    String? description,
    String? iconName,
    String? colorCode,
    String? coverImageUrl,
    @Default(true) bool isActive,
    @Default(false) bool isFeatured,
    @Default(0) int articleCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}

/// API 오류 응답 모델
@freezed
class ApiError with _$ApiError {
  const factory ApiError({
    required bool success,
    required ErrorInfo error,
  }) = _ApiError;

  factory ApiError.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorFromJson(json);
}

/// 오류 정보 모델
@freezed
class ErrorInfo with _$ErrorInfo {
  const factory ErrorInfo({
    required String code,
    required String message,
    Map<String, dynamic>? details,
  }) = _ErrorInfo;

  factory ErrorInfo.fromJson(Map<String, dynamic> json) =>
      _$ErrorInfoFromJson(json);
}

// 헬퍼 함수들

/// 문자열을 ArticleStatus로 변환
ArticleStatus _parseArticleStatus(String? status) {
  switch (status?.toLowerCase()) {
    case 'draft':
      return ArticleStatus.draft;
    case 'review':
      return ArticleStatus.review;
    case 'published':
      return ArticleStatus.published;
    case 'archived':
      return ArticleStatus.archived;
    case 'deleted':
      return ArticleStatus.deleted;
    default:
      return ArticleStatus.published;
  }
}

/// 문자열을 ArticleVisibility로 변환
ArticleVisibility _parseArticleVisibility(String? visibility) {
  switch (visibility?.toLowerCase()) {
    case 'public':
      return ArticleVisibility.public;
    case 'private':
      return ArticleVisibility.private;
    case 'unlisted':
      return ArticleVisibility.unlisted;
    default:
      return ArticleVisibility.public;
  }
}

/// 동적 타입을 int로 안전하게 변환
int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) {
    return int.tryParse(value);
  }
  if (value is double) {
    return value.toInt();
  }
  return null;
}

/// 동적 타입을 DateTime으로 안전하게 변환
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}