import 'package:freezed_annotation/freezed_annotation.dart';

part 'article_models.freezed.dart';
part 'article_models.g.dart';

@freezed
class CreateArticleRequest with _$CreateArticleRequest {
  const factory CreateArticleRequest({
    required String title,
    required String content,
    String? subtitle,
    String? excerpt,
    String? categoryId,
    String? featuredImageUrl,
    String? featuredImageAlt,
    String? seoTitle,
    String? seoDescription,
    String? seoKeywords,
    String? visibility,
    bool? isPremium,
    int? difficultyLevel,
    String? contentType,
    DateTime? scheduledAt,
    Map<String, dynamic>? metadata,
  }) = _CreateArticleRequest;

  factory CreateArticleRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateArticleRequestFromJson(json);
}

@freezed
class UpdateArticleRequest with _$UpdateArticleRequest {
  const factory UpdateArticleRequest({
    String? title,
    String? content,
    String? subtitle,
    String? excerpt,
    String? categoryId,
    String? featuredImageUrl,
    String? featuredImageAlt,
    String? seoTitle,
    String? seoDescription,
    String? seoKeywords,
    String? visibility,
    bool? isPremium,
    int? difficultyLevel,
    String? contentType,
    DateTime? scheduledAt,
    Map<String, dynamic>? metadata,
  }) = _UpdateArticleRequest;

  factory UpdateArticleRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateArticleRequestFromJson(json);
}

@freezed
class ArticleResponse with _$ArticleResponse {
  const factory ArticleResponse({
    required String id,
    required String title,
    required String slug,
    required String content,
    required String authorId,
    required String status,
    required String visibility,
    required int wordCount,
    required int difficultyLevel,
    required String contentType,
    required bool isPremium,
    required bool isFeatured,
    required int viewCount,
    required int likeCount,
    required int shareCount,
    required int commentCount,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? subtitle,
    String? excerpt,
    String? authorName,
    String? categoryId,
    String? featuredImageUrl,
    String? featuredImageAlt,
    int? readingTimeMinutes,
    String? seoTitle,
    String? seoDescription,
    String? seoKeywords,
    DateTime? publishedAt,
    DateTime? scheduledAt,
    Map<String, dynamic>? metadata,
  }) = _ArticleResponse;

  factory ArticleResponse.fromJson(Map<String, dynamic> json) =>
      _$ArticleResponseFromJson(json);
}

@freezed
class ArticleListItem with _$ArticleListItem {
  const factory ArticleListItem({
    required String id,
    required String title,
    required String slug,
    required String status,
    required String visibility,
    required int wordCount,
    required bool isPremium,
    required bool isFeatured,
    required int viewCount,
    required int likeCount,
    required int shareCount,
    required int commentCount,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? subtitle,
    String? excerpt,
    int? readingTimeMinutes,
    DateTime? publishedAt,
    DateTime? scheduledAt,
  }) = _ArticleListItem;

  factory ArticleListItem.fromJson(Map<String, dynamic> json) =>
      _$ArticleListItemFromJson(json);
}

@freezed
class ArticleListResponse with _$ArticleListResponse {
  const factory ArticleListResponse({
    required List<ArticleListItem> articles,
    required PaginationInfo pagination,
  }) = _ArticleListResponse;

  factory ArticleListResponse.fromJson(Map<String, dynamic> json) =>
      _$ArticleListResponseFromJson(json);
}

@freezed
class PaginationInfo with _$PaginationInfo {
  const factory PaginationInfo({
    required int page,
    required int limit,
    required int total,
    required int totalPages,
  }) = _PaginationInfo;

  factory PaginationInfo.fromJson(Map<String, dynamic> json) =>
      _$PaginationInfoFromJson(json);
}

@freezed
class WriterStatsResponse with _$WriterStatsResponse {
  const factory WriterStatsResponse({
    required int totalArticles,
    required int publishedArticles,
    required int draftArticles,
    required int archivedArticles,
    required int totalViews,
    required int totalLikes,
    required int totalShares,
    required int totalComments,
    required double averageReadingTime,
    required List<ArticleListItem> topPerformingArticles,
    required List<ArticleListItem> recentArticles,
  }) = _WriterStatsResponse;

  factory WriterStatsResponse.fromJson(Map<String, dynamic> json) =>
      _$WriterStatsResponseFromJson(json);
}

@freezed
class ValidationError with _$ValidationError {
  const factory ValidationError({
    required String field,
    required String message,
    required String code,
  }) = _ValidationError;

  factory ValidationError.fromJson(Map<String, dynamic> json) =>
      _$ValidationErrorFromJson(json);
}

// Enums for article status and visibility
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

enum ArticleVisibility {
  @JsonValue('public')
  public,
  @JsonValue('private')
  private,
  @JsonValue('unlisted')
  unlisted,
}

enum DifficultyLevel {
  @JsonValue(1)
  beginner,
  @JsonValue(2)
  easy,
  @JsonValue(3)
  intermediate,
  @JsonValue(4)
  advanced,
  @JsonValue(5)
  expert,
}

// Extensions for enum display names
extension ArticleStatusExtension on ArticleStatus {
  String get displayName {
    switch (this) {
      case ArticleStatus.draft:
        return 'Draft';
      case ArticleStatus.review:
        return 'Under Review';
      case ArticleStatus.published:
        return 'Published';
      case ArticleStatus.archived:
        return 'Archived';
      case ArticleStatus.deleted:
        return 'Deleted';
    }
  }

  String get value {
    switch (this) {
      case ArticleStatus.draft:
        return 'draft';
      case ArticleStatus.review:
        return 'review';
      case ArticleStatus.published:
        return 'published';
      case ArticleStatus.archived:
        return 'archived';
      case ArticleStatus.deleted:
        return 'deleted';
    }
  }
}

extension ArticleVisibilityExtension on ArticleVisibility {
  String get displayName {
    switch (this) {
      case ArticleVisibility.public:
        return 'Public';
      case ArticleVisibility.private:
        return 'Private';
      case ArticleVisibility.unlisted:
        return 'Unlisted';
    }
  }

  String get value {
    switch (this) {
      case ArticleVisibility.public:
        return 'public';
      case ArticleVisibility.private:
        return 'private';
      case ArticleVisibility.unlisted:
        return 'unlisted';
    }
  }
}

extension DifficultyLevelExtension on DifficultyLevel {
  String get displayName {
    switch (this) {
      case DifficultyLevel.beginner:
        return 'Beginner';
      case DifficultyLevel.easy:
        return 'Easy';
      case DifficultyLevel.intermediate:
        return 'Intermediate';
      case DifficultyLevel.advanced:
        return 'Advanced';
      case DifficultyLevel.expert:
        return 'Expert';
    }
  }

  int get value {
    switch (this) {
      case DifficultyLevel.beginner:
        return 1;
      case DifficultyLevel.easy:
        return 2;
      case DifficultyLevel.intermediate:
        return 3;
      case DifficultyLevel.advanced:
        return 4;
      case DifficultyLevel.expert:
        return 5;
    }
  }
}

// Helper methods for creating requests
extension CreateArticleRequestExtension on CreateArticleRequest {
  Map<String, dynamic> toJson() => _$CreateArticleRequestToJson(this);
}

extension UpdateArticleRequestExtension on UpdateArticleRequest {
  Map<String, dynamic> toJson() => _$UpdateArticleRequestToJson(this);
}