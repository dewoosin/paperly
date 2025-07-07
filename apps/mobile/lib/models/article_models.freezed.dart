// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'article_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Article {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  String? get subtitle => throw _privateConstructorUsedError;
  String? get excerpt => throw _privateConstructorUsedError;
  String? get summary => throw _privateConstructorUsedError;
  String? get content => throw _privateConstructorUsedError;
  String? get contentHtml => throw _privateConstructorUsedError;
  String? get featuredImageUrl => throw _privateConstructorUsedError;
  String? get featuredImageAlt => throw _privateConstructorUsedError;
  String get authorId => throw _privateConstructorUsedError;
  String? get authorName => throw _privateConstructorUsedError;
  String? get categoryId => throw _privateConstructorUsedError;
  String? get seoTitle => throw _privateConstructorUsedError;
  String? get seoDescription => throw _privateConstructorUsedError;
  ArticleStatus get status => throw _privateConstructorUsedError;
  ArticleVisibility get visibility => throw _privateConstructorUsedError;
  int get viewCount => throw _privateConstructorUsedError;
  int get likeCount => throw _privateConstructorUsedError;
  int get shareCount => throw _privateConstructorUsedError;
  int get commentCount => throw _privateConstructorUsedError;
  bool get isFeatured => throw _privateConstructorUsedError;
  bool get isTrending => throw _privateConstructorUsedError;
  int? get readingTimeMinutes => throw _privateConstructorUsedError;
  int? get estimatedReadingTime => throw _privateConstructorUsedError;
  int? get wordCount => throw _privateConstructorUsedError;
  DateTime? get scheduledAt => throw _privateConstructorUsedError;
  DateTime? get publishedAt => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  DateTime? get deletedAt => throw _privateConstructorUsedError;

  /// Create a copy of Article
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ArticleCopyWith<Article> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArticleCopyWith<$Res> {
  factory $ArticleCopyWith(Article value, $Res Function(Article) then) =
      _$ArticleCopyWithImpl<$Res, Article>;
  @useResult
  $Res call({
    String id,
    String title,
    String slug,
    String? subtitle,
    String? excerpt,
    String? summary,
    String? content,
    String? contentHtml,
    String? featuredImageUrl,
    String? featuredImageAlt,
    String authorId,
    String? authorName,
    String? categoryId,
    String? seoTitle,
    String? seoDescription,
    ArticleStatus status,
    ArticleVisibility visibility,
    int viewCount,
    int likeCount,
    int shareCount,
    int commentCount,
    bool isFeatured,
    bool isTrending,
    int? readingTimeMinutes,
    int? estimatedReadingTime,
    int? wordCount,
    DateTime? scheduledAt,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  });
}

/// @nodoc
class _$ArticleCopyWithImpl<$Res, $Val extends Article>
    implements $ArticleCopyWith<$Res> {
  _$ArticleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Article
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? slug = null,
    Object? subtitle = freezed,
    Object? excerpt = freezed,
    Object? summary = freezed,
    Object? content = freezed,
    Object? contentHtml = freezed,
    Object? featuredImageUrl = freezed,
    Object? featuredImageAlt = freezed,
    Object? authorId = null,
    Object? authorName = freezed,
    Object? categoryId = freezed,
    Object? seoTitle = freezed,
    Object? seoDescription = freezed,
    Object? status = null,
    Object? visibility = null,
    Object? viewCount = null,
    Object? likeCount = null,
    Object? shareCount = null,
    Object? commentCount = null,
    Object? isFeatured = null,
    Object? isTrending = null,
    Object? readingTimeMinutes = freezed,
    Object? estimatedReadingTime = freezed,
    Object? wordCount = freezed,
    Object? scheduledAt = freezed,
    Object? publishedAt = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? deletedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            slug: null == slug
                ? _value.slug
                : slug // ignore: cast_nullable_to_non_nullable
                      as String,
            subtitle: freezed == subtitle
                ? _value.subtitle
                : subtitle // ignore: cast_nullable_to_non_nullable
                      as String?,
            excerpt: freezed == excerpt
                ? _value.excerpt
                : excerpt // ignore: cast_nullable_to_non_nullable
                      as String?,
            summary: freezed == summary
                ? _value.summary
                : summary // ignore: cast_nullable_to_non_nullable
                      as String?,
            content: freezed == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String?,
            contentHtml: freezed == contentHtml
                ? _value.contentHtml
                : contentHtml // ignore: cast_nullable_to_non_nullable
                      as String?,
            featuredImageUrl: freezed == featuredImageUrl
                ? _value.featuredImageUrl
                : featuredImageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            featuredImageAlt: freezed == featuredImageAlt
                ? _value.featuredImageAlt
                : featuredImageAlt // ignore: cast_nullable_to_non_nullable
                      as String?,
            authorId: null == authorId
                ? _value.authorId
                : authorId // ignore: cast_nullable_to_non_nullable
                      as String,
            authorName: freezed == authorName
                ? _value.authorName
                : authorName // ignore: cast_nullable_to_non_nullable
                      as String?,
            categoryId: freezed == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
                      as String?,
            seoTitle: freezed == seoTitle
                ? _value.seoTitle
                : seoTitle // ignore: cast_nullable_to_non_nullable
                      as String?,
            seoDescription: freezed == seoDescription
                ? _value.seoDescription
                : seoDescription // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as ArticleStatus,
            visibility: null == visibility
                ? _value.visibility
                : visibility // ignore: cast_nullable_to_non_nullable
                      as ArticleVisibility,
            viewCount: null == viewCount
                ? _value.viewCount
                : viewCount // ignore: cast_nullable_to_non_nullable
                      as int,
            likeCount: null == likeCount
                ? _value.likeCount
                : likeCount // ignore: cast_nullable_to_non_nullable
                      as int,
            shareCount: null == shareCount
                ? _value.shareCount
                : shareCount // ignore: cast_nullable_to_non_nullable
                      as int,
            commentCount: null == commentCount
                ? _value.commentCount
                : commentCount // ignore: cast_nullable_to_non_nullable
                      as int,
            isFeatured: null == isFeatured
                ? _value.isFeatured
                : isFeatured // ignore: cast_nullable_to_non_nullable
                      as bool,
            isTrending: null == isTrending
                ? _value.isTrending
                : isTrending // ignore: cast_nullable_to_non_nullable
                      as bool,
            readingTimeMinutes: freezed == readingTimeMinutes
                ? _value.readingTimeMinutes
                : readingTimeMinutes // ignore: cast_nullable_to_non_nullable
                      as int?,
            estimatedReadingTime: freezed == estimatedReadingTime
                ? _value.estimatedReadingTime
                : estimatedReadingTime // ignore: cast_nullable_to_non_nullable
                      as int?,
            wordCount: freezed == wordCount
                ? _value.wordCount
                : wordCount // ignore: cast_nullable_to_non_nullable
                      as int?,
            scheduledAt: freezed == scheduledAt
                ? _value.scheduledAt
                : scheduledAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            publishedAt: freezed == publishedAt
                ? _value.publishedAt
                : publishedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            deletedAt: freezed == deletedAt
                ? _value.deletedAt
                : deletedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ArticleImplCopyWith<$Res> implements $ArticleCopyWith<$Res> {
  factory _$$ArticleImplCopyWith(
    _$ArticleImpl value,
    $Res Function(_$ArticleImpl) then,
  ) = __$$ArticleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String slug,
    String? subtitle,
    String? excerpt,
    String? summary,
    String? content,
    String? contentHtml,
    String? featuredImageUrl,
    String? featuredImageAlt,
    String authorId,
    String? authorName,
    String? categoryId,
    String? seoTitle,
    String? seoDescription,
    ArticleStatus status,
    ArticleVisibility visibility,
    int viewCount,
    int likeCount,
    int shareCount,
    int commentCount,
    bool isFeatured,
    bool isTrending,
    int? readingTimeMinutes,
    int? estimatedReadingTime,
    int? wordCount,
    DateTime? scheduledAt,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  });
}

/// @nodoc
class __$$ArticleImplCopyWithImpl<$Res>
    extends _$ArticleCopyWithImpl<$Res, _$ArticleImpl>
    implements _$$ArticleImplCopyWith<$Res> {
  __$$ArticleImplCopyWithImpl(
    _$ArticleImpl _value,
    $Res Function(_$ArticleImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Article
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? slug = null,
    Object? subtitle = freezed,
    Object? excerpt = freezed,
    Object? summary = freezed,
    Object? content = freezed,
    Object? contentHtml = freezed,
    Object? featuredImageUrl = freezed,
    Object? featuredImageAlt = freezed,
    Object? authorId = null,
    Object? authorName = freezed,
    Object? categoryId = freezed,
    Object? seoTitle = freezed,
    Object? seoDescription = freezed,
    Object? status = null,
    Object? visibility = null,
    Object? viewCount = null,
    Object? likeCount = null,
    Object? shareCount = null,
    Object? commentCount = null,
    Object? isFeatured = null,
    Object? isTrending = null,
    Object? readingTimeMinutes = freezed,
    Object? estimatedReadingTime = freezed,
    Object? wordCount = freezed,
    Object? scheduledAt = freezed,
    Object? publishedAt = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? deletedAt = freezed,
  }) {
    return _then(
      _$ArticleImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        slug: null == slug
            ? _value.slug
            : slug // ignore: cast_nullable_to_non_nullable
                  as String,
        subtitle: freezed == subtitle
            ? _value.subtitle
            : subtitle // ignore: cast_nullable_to_non_nullable
                  as String?,
        excerpt: freezed == excerpt
            ? _value.excerpt
            : excerpt // ignore: cast_nullable_to_non_nullable
                  as String?,
        summary: freezed == summary
            ? _value.summary
            : summary // ignore: cast_nullable_to_non_nullable
                  as String?,
        content: freezed == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String?,
        contentHtml: freezed == contentHtml
            ? _value.contentHtml
            : contentHtml // ignore: cast_nullable_to_non_nullable
                  as String?,
        featuredImageUrl: freezed == featuredImageUrl
            ? _value.featuredImageUrl
            : featuredImageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        featuredImageAlt: freezed == featuredImageAlt
            ? _value.featuredImageAlt
            : featuredImageAlt // ignore: cast_nullable_to_non_nullable
                  as String?,
        authorId: null == authorId
            ? _value.authorId
            : authorId // ignore: cast_nullable_to_non_nullable
                  as String,
        authorName: freezed == authorName
            ? _value.authorName
            : authorName // ignore: cast_nullable_to_non_nullable
                  as String?,
        categoryId: freezed == categoryId
            ? _value.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String?,
        seoTitle: freezed == seoTitle
            ? _value.seoTitle
            : seoTitle // ignore: cast_nullable_to_non_nullable
                  as String?,
        seoDescription: freezed == seoDescription
            ? _value.seoDescription
            : seoDescription // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as ArticleStatus,
        visibility: null == visibility
            ? _value.visibility
            : visibility // ignore: cast_nullable_to_non_nullable
                  as ArticleVisibility,
        viewCount: null == viewCount
            ? _value.viewCount
            : viewCount // ignore: cast_nullable_to_non_nullable
                  as int,
        likeCount: null == likeCount
            ? _value.likeCount
            : likeCount // ignore: cast_nullable_to_non_nullable
                  as int,
        shareCount: null == shareCount
            ? _value.shareCount
            : shareCount // ignore: cast_nullable_to_non_nullable
                  as int,
        commentCount: null == commentCount
            ? _value.commentCount
            : commentCount // ignore: cast_nullable_to_non_nullable
                  as int,
        isFeatured: null == isFeatured
            ? _value.isFeatured
            : isFeatured // ignore: cast_nullable_to_non_nullable
                  as bool,
        isTrending: null == isTrending
            ? _value.isTrending
            : isTrending // ignore: cast_nullable_to_non_nullable
                  as bool,
        readingTimeMinutes: freezed == readingTimeMinutes
            ? _value.readingTimeMinutes
            : readingTimeMinutes // ignore: cast_nullable_to_non_nullable
                  as int?,
        estimatedReadingTime: freezed == estimatedReadingTime
            ? _value.estimatedReadingTime
            : estimatedReadingTime // ignore: cast_nullable_to_non_nullable
                  as int?,
        wordCount: freezed == wordCount
            ? _value.wordCount
            : wordCount // ignore: cast_nullable_to_non_nullable
                  as int?,
        scheduledAt: freezed == scheduledAt
            ? _value.scheduledAt
            : scheduledAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        publishedAt: freezed == publishedAt
            ? _value.publishedAt
            : publishedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        deletedAt: freezed == deletedAt
            ? _value.deletedAt
            : deletedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc

class _$ArticleImpl extends _Article {
  const _$ArticleImpl({
    required this.id,
    required this.title,
    required this.slug,
    this.subtitle,
    this.excerpt,
    this.summary,
    this.content,
    this.contentHtml,
    this.featuredImageUrl,
    this.featuredImageAlt,
    required this.authorId,
    this.authorName,
    this.categoryId,
    this.seoTitle,
    this.seoDescription,
    this.status = ArticleStatus.published,
    this.visibility = ArticleVisibility.public,
    this.viewCount = 0,
    this.likeCount = 0,
    this.shareCount = 0,
    this.commentCount = 0,
    this.isFeatured = false,
    this.isTrending = false,
    this.readingTimeMinutes,
    this.estimatedReadingTime,
    this.wordCount,
    this.scheduledAt,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  }) : super._();

  @override
  final String id;
  @override
  final String title;
  @override
  final String slug;
  @override
  final String? subtitle;
  @override
  final String? excerpt;
  @override
  final String? summary;
  @override
  final String? content;
  @override
  final String? contentHtml;
  @override
  final String? featuredImageUrl;
  @override
  final String? featuredImageAlt;
  @override
  final String authorId;
  @override
  final String? authorName;
  @override
  final String? categoryId;
  @override
  final String? seoTitle;
  @override
  final String? seoDescription;
  @override
  @JsonKey()
  final ArticleStatus status;
  @override
  @JsonKey()
  final ArticleVisibility visibility;
  @override
  @JsonKey()
  final int viewCount;
  @override
  @JsonKey()
  final int likeCount;
  @override
  @JsonKey()
  final int shareCount;
  @override
  @JsonKey()
  final int commentCount;
  @override
  @JsonKey()
  final bool isFeatured;
  @override
  @JsonKey()
  final bool isTrending;
  @override
  final int? readingTimeMinutes;
  @override
  final int? estimatedReadingTime;
  @override
  final int? wordCount;
  @override
  final DateTime? scheduledAt;
  @override
  final DateTime? publishedAt;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final DateTime? deletedAt;

  @override
  String toString() {
    return 'Article(id: $id, title: $title, slug: $slug, subtitle: $subtitle, excerpt: $excerpt, summary: $summary, content: $content, contentHtml: $contentHtml, featuredImageUrl: $featuredImageUrl, featuredImageAlt: $featuredImageAlt, authorId: $authorId, authorName: $authorName, categoryId: $categoryId, seoTitle: $seoTitle, seoDescription: $seoDescription, status: $status, visibility: $visibility, viewCount: $viewCount, likeCount: $likeCount, shareCount: $shareCount, commentCount: $commentCount, isFeatured: $isFeatured, isTrending: $isTrending, readingTimeMinutes: $readingTimeMinutes, estimatedReadingTime: $estimatedReadingTime, wordCount: $wordCount, scheduledAt: $scheduledAt, publishedAt: $publishedAt, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArticleImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.subtitle, subtitle) ||
                other.subtitle == subtitle) &&
            (identical(other.excerpt, excerpt) || other.excerpt == excerpt) &&
            (identical(other.summary, summary) || other.summary == summary) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.contentHtml, contentHtml) ||
                other.contentHtml == contentHtml) &&
            (identical(other.featuredImageUrl, featuredImageUrl) ||
                other.featuredImageUrl == featuredImageUrl) &&
            (identical(other.featuredImageAlt, featuredImageAlt) ||
                other.featuredImageAlt == featuredImageAlt) &&
            (identical(other.authorId, authorId) ||
                other.authorId == authorId) &&
            (identical(other.authorName, authorName) ||
                other.authorName == authorName) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.seoTitle, seoTitle) ||
                other.seoTitle == seoTitle) &&
            (identical(other.seoDescription, seoDescription) ||
                other.seoDescription == seoDescription) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.visibility, visibility) ||
                other.visibility == visibility) &&
            (identical(other.viewCount, viewCount) ||
                other.viewCount == viewCount) &&
            (identical(other.likeCount, likeCount) ||
                other.likeCount == likeCount) &&
            (identical(other.shareCount, shareCount) ||
                other.shareCount == shareCount) &&
            (identical(other.commentCount, commentCount) ||
                other.commentCount == commentCount) &&
            (identical(other.isFeatured, isFeatured) ||
                other.isFeatured == isFeatured) &&
            (identical(other.isTrending, isTrending) ||
                other.isTrending == isTrending) &&
            (identical(other.readingTimeMinutes, readingTimeMinutes) ||
                other.readingTimeMinutes == readingTimeMinutes) &&
            (identical(other.estimatedReadingTime, estimatedReadingTime) ||
                other.estimatedReadingTime == estimatedReadingTime) &&
            (identical(other.wordCount, wordCount) ||
                other.wordCount == wordCount) &&
            (identical(other.scheduledAt, scheduledAt) ||
                other.scheduledAt == scheduledAt) &&
            (identical(other.publishedAt, publishedAt) ||
                other.publishedAt == publishedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt));
  }

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    title,
    slug,
    subtitle,
    excerpt,
    summary,
    content,
    contentHtml,
    featuredImageUrl,
    featuredImageAlt,
    authorId,
    authorName,
    categoryId,
    seoTitle,
    seoDescription,
    status,
    visibility,
    viewCount,
    likeCount,
    shareCount,
    commentCount,
    isFeatured,
    isTrending,
    readingTimeMinutes,
    estimatedReadingTime,
    wordCount,
    scheduledAt,
    publishedAt,
    createdAt,
    updatedAt,
    deletedAt,
  ]);

  /// Create a copy of Article
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ArticleImplCopyWith<_$ArticleImpl> get copyWith =>
      __$$ArticleImplCopyWithImpl<_$ArticleImpl>(this, _$identity);
}

abstract class _Article extends Article {
  const factory _Article({
    required final String id,
    required final String title,
    required final String slug,
    final String? subtitle,
    final String? excerpt,
    final String? summary,
    final String? content,
    final String? contentHtml,
    final String? featuredImageUrl,
    final String? featuredImageAlt,
    required final String authorId,
    final String? authorName,
    final String? categoryId,
    final String? seoTitle,
    final String? seoDescription,
    final ArticleStatus status,
    final ArticleVisibility visibility,
    final int viewCount,
    final int likeCount,
    final int shareCount,
    final int commentCount,
    final bool isFeatured,
    final bool isTrending,
    final int? readingTimeMinutes,
    final int? estimatedReadingTime,
    final int? wordCount,
    final DateTime? scheduledAt,
    final DateTime? publishedAt,
    final DateTime? createdAt,
    final DateTime? updatedAt,
    final DateTime? deletedAt,
  }) = _$ArticleImpl;
  const _Article._() : super._();

  @override
  String get id;
  @override
  String get title;
  @override
  String get slug;
  @override
  String? get subtitle;
  @override
  String? get excerpt;
  @override
  String? get summary;
  @override
  String? get content;
  @override
  String? get contentHtml;
  @override
  String? get featuredImageUrl;
  @override
  String? get featuredImageAlt;
  @override
  String get authorId;
  @override
  String? get authorName;
  @override
  String? get categoryId;
  @override
  String? get seoTitle;
  @override
  String? get seoDescription;
  @override
  ArticleStatus get status;
  @override
  ArticleVisibility get visibility;
  @override
  int get viewCount;
  @override
  int get likeCount;
  @override
  int get shareCount;
  @override
  int get commentCount;
  @override
  bool get isFeatured;
  @override
  bool get isTrending;
  @override
  int? get readingTimeMinutes;
  @override
  int? get estimatedReadingTime;
  @override
  int? get wordCount;
  @override
  DateTime? get scheduledAt;
  @override
  DateTime? get publishedAt;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  DateTime? get deletedAt;

  /// Create a copy of Article
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ArticleImplCopyWith<_$ArticleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ArticleListResponse _$ArticleListResponseFromJson(Map<String, dynamic> json) {
  return _ArticleListResponse.fromJson(json);
}

/// @nodoc
mixin _$ArticleListResponse {
  bool get success => throw _privateConstructorUsedError;
  ArticleListData get data => throw _privateConstructorUsedError;

  /// Serializes this ArticleListResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ArticleListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ArticleListResponseCopyWith<ArticleListResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArticleListResponseCopyWith<$Res> {
  factory $ArticleListResponseCopyWith(
    ArticleListResponse value,
    $Res Function(ArticleListResponse) then,
  ) = _$ArticleListResponseCopyWithImpl<$Res, ArticleListResponse>;
  @useResult
  $Res call({bool success, ArticleListData data});

  $ArticleListDataCopyWith<$Res> get data;
}

/// @nodoc
class _$ArticleListResponseCopyWithImpl<$Res, $Val extends ArticleListResponse>
    implements $ArticleListResponseCopyWith<$Res> {
  _$ArticleListResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ArticleListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? success = null, Object? data = null}) {
    return _then(
      _value.copyWith(
            success: null == success
                ? _value.success
                : success // ignore: cast_nullable_to_non_nullable
                      as bool,
            data: null == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as ArticleListData,
          )
          as $Val,
    );
  }

  /// Create a copy of ArticleListResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ArticleListDataCopyWith<$Res> get data {
    return $ArticleListDataCopyWith<$Res>(_value.data, (value) {
      return _then(_value.copyWith(data: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ArticleListResponseImplCopyWith<$Res>
    implements $ArticleListResponseCopyWith<$Res> {
  factory _$$ArticleListResponseImplCopyWith(
    _$ArticleListResponseImpl value,
    $Res Function(_$ArticleListResponseImpl) then,
  ) = __$$ArticleListResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool success, ArticleListData data});

  @override
  $ArticleListDataCopyWith<$Res> get data;
}

/// @nodoc
class __$$ArticleListResponseImplCopyWithImpl<$Res>
    extends _$ArticleListResponseCopyWithImpl<$Res, _$ArticleListResponseImpl>
    implements _$$ArticleListResponseImplCopyWith<$Res> {
  __$$ArticleListResponseImplCopyWithImpl(
    _$ArticleListResponseImpl _value,
    $Res Function(_$ArticleListResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ArticleListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? success = null, Object? data = null}) {
    return _then(
      _$ArticleListResponseImpl(
        success: null == success
            ? _value.success
            : success // ignore: cast_nullable_to_non_nullable
                  as bool,
        data: null == data
            ? _value.data
            : data // ignore: cast_nullable_to_non_nullable
                  as ArticleListData,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ArticleListResponseImpl implements _ArticleListResponse {
  const _$ArticleListResponseImpl({required this.success, required this.data});

  factory _$ArticleListResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArticleListResponseImplFromJson(json);

  @override
  final bool success;
  @override
  final ArticleListData data;

  @override
  String toString() {
    return 'ArticleListResponse(success: $success, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArticleListResponseImpl &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.data, data) || other.data == data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, success, data);

  /// Create a copy of ArticleListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ArticleListResponseImplCopyWith<_$ArticleListResponseImpl> get copyWith =>
      __$$ArticleListResponseImplCopyWithImpl<_$ArticleListResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ArticleListResponseImplToJson(this);
  }
}

abstract class _ArticleListResponse implements ArticleListResponse {
  const factory _ArticleListResponse({
    required final bool success,
    required final ArticleListData data,
  }) = _$ArticleListResponseImpl;

  factory _ArticleListResponse.fromJson(Map<String, dynamic> json) =
      _$ArticleListResponseImpl.fromJson;

  @override
  bool get success;
  @override
  ArticleListData get data;

  /// Create a copy of ArticleListResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ArticleListResponseImplCopyWith<_$ArticleListResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ArticleListData _$ArticleListDataFromJson(Map<String, dynamic> json) {
  return _ArticleListData.fromJson(json);
}

/// @nodoc
mixin _$ArticleListData {
  List<Article> get articles => throw _privateConstructorUsedError;
  Pagination get pagination => throw _privateConstructorUsedError;
  String? get query => throw _privateConstructorUsedError;
  String? get categoryId => throw _privateConstructorUsedError;
  String? get authorId => throw _privateConstructorUsedError;

  /// Serializes this ArticleListData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ArticleListData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ArticleListDataCopyWith<ArticleListData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArticleListDataCopyWith<$Res> {
  factory $ArticleListDataCopyWith(
    ArticleListData value,
    $Res Function(ArticleListData) then,
  ) = _$ArticleListDataCopyWithImpl<$Res, ArticleListData>;
  @useResult
  $Res call({
    List<Article> articles,
    Pagination pagination,
    String? query,
    String? categoryId,
    String? authorId,
  });

  $PaginationCopyWith<$Res> get pagination;
}

/// @nodoc
class _$ArticleListDataCopyWithImpl<$Res, $Val extends ArticleListData>
    implements $ArticleListDataCopyWith<$Res> {
  _$ArticleListDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ArticleListData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? articles = null,
    Object? pagination = null,
    Object? query = freezed,
    Object? categoryId = freezed,
    Object? authorId = freezed,
  }) {
    return _then(
      _value.copyWith(
            articles: null == articles
                ? _value.articles
                : articles // ignore: cast_nullable_to_non_nullable
                      as List<Article>,
            pagination: null == pagination
                ? _value.pagination
                : pagination // ignore: cast_nullable_to_non_nullable
                      as Pagination,
            query: freezed == query
                ? _value.query
                : query // ignore: cast_nullable_to_non_nullable
                      as String?,
            categoryId: freezed == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
                      as String?,
            authorId: freezed == authorId
                ? _value.authorId
                : authorId // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of ArticleListData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PaginationCopyWith<$Res> get pagination {
    return $PaginationCopyWith<$Res>(_value.pagination, (value) {
      return _then(_value.copyWith(pagination: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ArticleListDataImplCopyWith<$Res>
    implements $ArticleListDataCopyWith<$Res> {
  factory _$$ArticleListDataImplCopyWith(
    _$ArticleListDataImpl value,
    $Res Function(_$ArticleListDataImpl) then,
  ) = __$$ArticleListDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<Article> articles,
    Pagination pagination,
    String? query,
    String? categoryId,
    String? authorId,
  });

  @override
  $PaginationCopyWith<$Res> get pagination;
}

/// @nodoc
class __$$ArticleListDataImplCopyWithImpl<$Res>
    extends _$ArticleListDataCopyWithImpl<$Res, _$ArticleListDataImpl>
    implements _$$ArticleListDataImplCopyWith<$Res> {
  __$$ArticleListDataImplCopyWithImpl(
    _$ArticleListDataImpl _value,
    $Res Function(_$ArticleListDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ArticleListData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? articles = null,
    Object? pagination = null,
    Object? query = freezed,
    Object? categoryId = freezed,
    Object? authorId = freezed,
  }) {
    return _then(
      _$ArticleListDataImpl(
        articles: null == articles
            ? _value._articles
            : articles // ignore: cast_nullable_to_non_nullable
                  as List<Article>,
        pagination: null == pagination
            ? _value.pagination
            : pagination // ignore: cast_nullable_to_non_nullable
                  as Pagination,
        query: freezed == query
            ? _value.query
            : query // ignore: cast_nullable_to_non_nullable
                  as String?,
        categoryId: freezed == categoryId
            ? _value.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String?,
        authorId: freezed == authorId
            ? _value.authorId
            : authorId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ArticleListDataImpl implements _ArticleListData {
  const _$ArticleListDataImpl({
    required final List<Article> articles,
    required this.pagination,
    this.query,
    this.categoryId,
    this.authorId,
  }) : _articles = articles;

  factory _$ArticleListDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArticleListDataImplFromJson(json);

  final List<Article> _articles;
  @override
  List<Article> get articles {
    if (_articles is EqualUnmodifiableListView) return _articles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_articles);
  }

  @override
  final Pagination pagination;
  @override
  final String? query;
  @override
  final String? categoryId;
  @override
  final String? authorId;

  @override
  String toString() {
    return 'ArticleListData(articles: $articles, pagination: $pagination, query: $query, categoryId: $categoryId, authorId: $authorId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArticleListDataImpl &&
            const DeepCollectionEquality().equals(other._articles, _articles) &&
            (identical(other.pagination, pagination) ||
                other.pagination == pagination) &&
            (identical(other.query, query) || other.query == query) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.authorId, authorId) ||
                other.authorId == authorId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_articles),
    pagination,
    query,
    categoryId,
    authorId,
  );

  /// Create a copy of ArticleListData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ArticleListDataImplCopyWith<_$ArticleListDataImpl> get copyWith =>
      __$$ArticleListDataImplCopyWithImpl<_$ArticleListDataImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ArticleListDataImplToJson(this);
  }
}

abstract class _ArticleListData implements ArticleListData {
  const factory _ArticleListData({
    required final List<Article> articles,
    required final Pagination pagination,
    final String? query,
    final String? categoryId,
    final String? authorId,
  }) = _$ArticleListDataImpl;

  factory _ArticleListData.fromJson(Map<String, dynamic> json) =
      _$ArticleListDataImpl.fromJson;

  @override
  List<Article> get articles;
  @override
  Pagination get pagination;
  @override
  String? get query;
  @override
  String? get categoryId;
  @override
  String? get authorId;

  /// Create a copy of ArticleListData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ArticleListDataImplCopyWith<_$ArticleListDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Pagination _$PaginationFromJson(Map<String, dynamic> json) {
  return _Pagination.fromJson(json);
}

/// @nodoc
mixin _$Pagination {
  int get total => throw _privateConstructorUsedError;
  int get page => throw _privateConstructorUsedError;
  int get limit => throw _privateConstructorUsedError;
  int get totalPages => throw _privateConstructorUsedError;

  /// Serializes this Pagination to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Pagination
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaginationCopyWith<Pagination> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaginationCopyWith<$Res> {
  factory $PaginationCopyWith(
    Pagination value,
    $Res Function(Pagination) then,
  ) = _$PaginationCopyWithImpl<$Res, Pagination>;
  @useResult
  $Res call({int total, int page, int limit, int totalPages});
}

/// @nodoc
class _$PaginationCopyWithImpl<$Res, $Val extends Pagination>
    implements $PaginationCopyWith<$Res> {
  _$PaginationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Pagination
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? page = null,
    Object? limit = null,
    Object? totalPages = null,
  }) {
    return _then(
      _value.copyWith(
            total: null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                      as int,
            page: null == page
                ? _value.page
                : page // ignore: cast_nullable_to_non_nullable
                      as int,
            limit: null == limit
                ? _value.limit
                : limit // ignore: cast_nullable_to_non_nullable
                      as int,
            totalPages: null == totalPages
                ? _value.totalPages
                : totalPages // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PaginationImplCopyWith<$Res>
    implements $PaginationCopyWith<$Res> {
  factory _$$PaginationImplCopyWith(
    _$PaginationImpl value,
    $Res Function(_$PaginationImpl) then,
  ) = __$$PaginationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int total, int page, int limit, int totalPages});
}

/// @nodoc
class __$$PaginationImplCopyWithImpl<$Res>
    extends _$PaginationCopyWithImpl<$Res, _$PaginationImpl>
    implements _$$PaginationImplCopyWith<$Res> {
  __$$PaginationImplCopyWithImpl(
    _$PaginationImpl _value,
    $Res Function(_$PaginationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Pagination
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? page = null,
    Object? limit = null,
    Object? totalPages = null,
  }) {
    return _then(
      _$PaginationImpl(
        total: null == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as int,
        page: null == page
            ? _value.page
            : page // ignore: cast_nullable_to_non_nullable
                  as int,
        limit: null == limit
            ? _value.limit
            : limit // ignore: cast_nullable_to_non_nullable
                  as int,
        totalPages: null == totalPages
            ? _value.totalPages
            : totalPages // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PaginationImpl implements _Pagination {
  const _$PaginationImpl({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory _$PaginationImpl.fromJson(Map<String, dynamic> json) =>
      _$$PaginationImplFromJson(json);

  @override
  final int total;
  @override
  final int page;
  @override
  final int limit;
  @override
  final int totalPages;

  @override
  String toString() {
    return 'Pagination(total: $total, page: $page, limit: $limit, totalPages: $totalPages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaginationImpl &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.limit, limit) || other.limit == limit) &&
            (identical(other.totalPages, totalPages) ||
                other.totalPages == totalPages));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, total, page, limit, totalPages);

  /// Create a copy of Pagination
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaginationImplCopyWith<_$PaginationImpl> get copyWith =>
      __$$PaginationImplCopyWithImpl<_$PaginationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PaginationImplToJson(this);
  }
}

abstract class _Pagination implements Pagination {
  const factory _Pagination({
    required final int total,
    required final int page,
    required final int limit,
    required final int totalPages,
  }) = _$PaginationImpl;

  factory _Pagination.fromJson(Map<String, dynamic> json) =
      _$PaginationImpl.fromJson;

  @override
  int get total;
  @override
  int get page;
  @override
  int get limit;
  @override
  int get totalPages;

  /// Create a copy of Pagination
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaginationImplCopyWith<_$PaginationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ArticleDetailResponse _$ArticleDetailResponseFromJson(
  Map<String, dynamic> json,
) {
  return _ArticleDetailResponse.fromJson(json);
}

/// @nodoc
mixin _$ArticleDetailResponse {
  bool get success => throw _privateConstructorUsedError;
  ArticleDetailData get data => throw _privateConstructorUsedError;

  /// Serializes this ArticleDetailResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ArticleDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ArticleDetailResponseCopyWith<ArticleDetailResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArticleDetailResponseCopyWith<$Res> {
  factory $ArticleDetailResponseCopyWith(
    ArticleDetailResponse value,
    $Res Function(ArticleDetailResponse) then,
  ) = _$ArticleDetailResponseCopyWithImpl<$Res, ArticleDetailResponse>;
  @useResult
  $Res call({bool success, ArticleDetailData data});

  $ArticleDetailDataCopyWith<$Res> get data;
}

/// @nodoc
class _$ArticleDetailResponseCopyWithImpl<
  $Res,
  $Val extends ArticleDetailResponse
>
    implements $ArticleDetailResponseCopyWith<$Res> {
  _$ArticleDetailResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ArticleDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? success = null, Object? data = null}) {
    return _then(
      _value.copyWith(
            success: null == success
                ? _value.success
                : success // ignore: cast_nullable_to_non_nullable
                      as bool,
            data: null == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as ArticleDetailData,
          )
          as $Val,
    );
  }

  /// Create a copy of ArticleDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ArticleDetailDataCopyWith<$Res> get data {
    return $ArticleDetailDataCopyWith<$Res>(_value.data, (value) {
      return _then(_value.copyWith(data: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ArticleDetailResponseImplCopyWith<$Res>
    implements $ArticleDetailResponseCopyWith<$Res> {
  factory _$$ArticleDetailResponseImplCopyWith(
    _$ArticleDetailResponseImpl value,
    $Res Function(_$ArticleDetailResponseImpl) then,
  ) = __$$ArticleDetailResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool success, ArticleDetailData data});

  @override
  $ArticleDetailDataCopyWith<$Res> get data;
}

/// @nodoc
class __$$ArticleDetailResponseImplCopyWithImpl<$Res>
    extends
        _$ArticleDetailResponseCopyWithImpl<$Res, _$ArticleDetailResponseImpl>
    implements _$$ArticleDetailResponseImplCopyWith<$Res> {
  __$$ArticleDetailResponseImplCopyWithImpl(
    _$ArticleDetailResponseImpl _value,
    $Res Function(_$ArticleDetailResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ArticleDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? success = null, Object? data = null}) {
    return _then(
      _$ArticleDetailResponseImpl(
        success: null == success
            ? _value.success
            : success // ignore: cast_nullable_to_non_nullable
                  as bool,
        data: null == data
            ? _value.data
            : data // ignore: cast_nullable_to_non_nullable
                  as ArticleDetailData,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ArticleDetailResponseImpl implements _ArticleDetailResponse {
  const _$ArticleDetailResponseImpl({
    required this.success,
    required this.data,
  });

  factory _$ArticleDetailResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArticleDetailResponseImplFromJson(json);

  @override
  final bool success;
  @override
  final ArticleDetailData data;

  @override
  String toString() {
    return 'ArticleDetailResponse(success: $success, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArticleDetailResponseImpl &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.data, data) || other.data == data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, success, data);

  /// Create a copy of ArticleDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ArticleDetailResponseImplCopyWith<_$ArticleDetailResponseImpl>
  get copyWith =>
      __$$ArticleDetailResponseImplCopyWithImpl<_$ArticleDetailResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ArticleDetailResponseImplToJson(this);
  }
}

abstract class _ArticleDetailResponse implements ArticleDetailResponse {
  const factory _ArticleDetailResponse({
    required final bool success,
    required final ArticleDetailData data,
  }) = _$ArticleDetailResponseImpl;

  factory _ArticleDetailResponse.fromJson(Map<String, dynamic> json) =
      _$ArticleDetailResponseImpl.fromJson;

  @override
  bool get success;
  @override
  ArticleDetailData get data;

  /// Create a copy of ArticleDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ArticleDetailResponseImplCopyWith<_$ArticleDetailResponseImpl>
  get copyWith => throw _privateConstructorUsedError;
}

ArticleDetailData _$ArticleDetailDataFromJson(Map<String, dynamic> json) {
  return _ArticleDetailData.fromJson(json);
}

/// @nodoc
mixin _$ArticleDetailData {
  Article get article => throw _privateConstructorUsedError;

  /// Serializes this ArticleDetailData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ArticleDetailData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ArticleDetailDataCopyWith<ArticleDetailData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArticleDetailDataCopyWith<$Res> {
  factory $ArticleDetailDataCopyWith(
    ArticleDetailData value,
    $Res Function(ArticleDetailData) then,
  ) = _$ArticleDetailDataCopyWithImpl<$Res, ArticleDetailData>;
  @useResult
  $Res call({Article article});

  $ArticleCopyWith<$Res> get article;
}

/// @nodoc
class _$ArticleDetailDataCopyWithImpl<$Res, $Val extends ArticleDetailData>
    implements $ArticleDetailDataCopyWith<$Res> {
  _$ArticleDetailDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ArticleDetailData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? article = null}) {
    return _then(
      _value.copyWith(
            article: null == article
                ? _value.article
                : article // ignore: cast_nullable_to_non_nullable
                      as Article,
          )
          as $Val,
    );
  }

  /// Create a copy of ArticleDetailData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ArticleCopyWith<$Res> get article {
    return $ArticleCopyWith<$Res>(_value.article, (value) {
      return _then(_value.copyWith(article: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ArticleDetailDataImplCopyWith<$Res>
    implements $ArticleDetailDataCopyWith<$Res> {
  factory _$$ArticleDetailDataImplCopyWith(
    _$ArticleDetailDataImpl value,
    $Res Function(_$ArticleDetailDataImpl) then,
  ) = __$$ArticleDetailDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Article article});

  @override
  $ArticleCopyWith<$Res> get article;
}

/// @nodoc
class __$$ArticleDetailDataImplCopyWithImpl<$Res>
    extends _$ArticleDetailDataCopyWithImpl<$Res, _$ArticleDetailDataImpl>
    implements _$$ArticleDetailDataImplCopyWith<$Res> {
  __$$ArticleDetailDataImplCopyWithImpl(
    _$ArticleDetailDataImpl _value,
    $Res Function(_$ArticleDetailDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ArticleDetailData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? article = null}) {
    return _then(
      _$ArticleDetailDataImpl(
        article: null == article
            ? _value.article
            : article // ignore: cast_nullable_to_non_nullable
                  as Article,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ArticleDetailDataImpl implements _ArticleDetailData {
  const _$ArticleDetailDataImpl({required this.article});

  factory _$ArticleDetailDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArticleDetailDataImplFromJson(json);

  @override
  final Article article;

  @override
  String toString() {
    return 'ArticleDetailData(article: $article)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArticleDetailDataImpl &&
            (identical(other.article, article) || other.article == article));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, article);

  /// Create a copy of ArticleDetailData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ArticleDetailDataImplCopyWith<_$ArticleDetailDataImpl> get copyWith =>
      __$$ArticleDetailDataImplCopyWithImpl<_$ArticleDetailDataImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ArticleDetailDataImplToJson(this);
  }
}

abstract class _ArticleDetailData implements ArticleDetailData {
  const factory _ArticleDetailData({required final Article article}) =
      _$ArticleDetailDataImpl;

  factory _ArticleDetailData.fromJson(Map<String, dynamic> json) =
      _$ArticleDetailDataImpl.fromJson;

  @override
  Article get article;

  /// Create a copy of ArticleDetailData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ArticleDetailDataImplCopyWith<_$ArticleDetailDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LikeResponse _$LikeResponseFromJson(Map<String, dynamic> json) {
  return _LikeResponse.fromJson(json);
}

/// @nodoc
mixin _$LikeResponse {
  bool get success => throw _privateConstructorUsedError;
  LikeData get data => throw _privateConstructorUsedError;

  /// Serializes this LikeResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LikeResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LikeResponseCopyWith<LikeResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LikeResponseCopyWith<$Res> {
  factory $LikeResponseCopyWith(
    LikeResponse value,
    $Res Function(LikeResponse) then,
  ) = _$LikeResponseCopyWithImpl<$Res, LikeResponse>;
  @useResult
  $Res call({bool success, LikeData data});

  $LikeDataCopyWith<$Res> get data;
}

/// @nodoc
class _$LikeResponseCopyWithImpl<$Res, $Val extends LikeResponse>
    implements $LikeResponseCopyWith<$Res> {
  _$LikeResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LikeResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? success = null, Object? data = null}) {
    return _then(
      _value.copyWith(
            success: null == success
                ? _value.success
                : success // ignore: cast_nullable_to_non_nullable
                      as bool,
            data: null == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as LikeData,
          )
          as $Val,
    );
  }

  /// Create a copy of LikeResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LikeDataCopyWith<$Res> get data {
    return $LikeDataCopyWith<$Res>(_value.data, (value) {
      return _then(_value.copyWith(data: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$LikeResponseImplCopyWith<$Res>
    implements $LikeResponseCopyWith<$Res> {
  factory _$$LikeResponseImplCopyWith(
    _$LikeResponseImpl value,
    $Res Function(_$LikeResponseImpl) then,
  ) = __$$LikeResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool success, LikeData data});

  @override
  $LikeDataCopyWith<$Res> get data;
}

/// @nodoc
class __$$LikeResponseImplCopyWithImpl<$Res>
    extends _$LikeResponseCopyWithImpl<$Res, _$LikeResponseImpl>
    implements _$$LikeResponseImplCopyWith<$Res> {
  __$$LikeResponseImplCopyWithImpl(
    _$LikeResponseImpl _value,
    $Res Function(_$LikeResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LikeResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? success = null, Object? data = null}) {
    return _then(
      _$LikeResponseImpl(
        success: null == success
            ? _value.success
            : success // ignore: cast_nullable_to_non_nullable
                  as bool,
        data: null == data
            ? _value.data
            : data // ignore: cast_nullable_to_non_nullable
                  as LikeData,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LikeResponseImpl implements _LikeResponse {
  const _$LikeResponseImpl({required this.success, required this.data});

  factory _$LikeResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$LikeResponseImplFromJson(json);

  @override
  final bool success;
  @override
  final LikeData data;

  @override
  String toString() {
    return 'LikeResponse(success: $success, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LikeResponseImpl &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.data, data) || other.data == data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, success, data);

  /// Create a copy of LikeResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LikeResponseImplCopyWith<_$LikeResponseImpl> get copyWith =>
      __$$LikeResponseImplCopyWithImpl<_$LikeResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LikeResponseImplToJson(this);
  }
}

abstract class _LikeResponse implements LikeResponse {
  const factory _LikeResponse({
    required final bool success,
    required final LikeData data,
  }) = _$LikeResponseImpl;

  factory _LikeResponse.fromJson(Map<String, dynamic> json) =
      _$LikeResponseImpl.fromJson;

  @override
  bool get success;
  @override
  LikeData get data;

  /// Create a copy of LikeResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LikeResponseImplCopyWith<_$LikeResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LikeData _$LikeDataFromJson(Map<String, dynamic> json) {
  return _LikeData.fromJson(json);
}

/// @nodoc
mixin _$LikeData {
  bool get liked => throw _privateConstructorUsedError;
  int get likeCount => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;

  /// Serializes this LikeData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LikeData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LikeDataCopyWith<LikeData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LikeDataCopyWith<$Res> {
  factory $LikeDataCopyWith(LikeData value, $Res Function(LikeData) then) =
      _$LikeDataCopyWithImpl<$Res, LikeData>;
  @useResult
  $Res call({bool liked, int likeCount, String? message});
}

/// @nodoc
class _$LikeDataCopyWithImpl<$Res, $Val extends LikeData>
    implements $LikeDataCopyWith<$Res> {
  _$LikeDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LikeData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? liked = null,
    Object? likeCount = null,
    Object? message = freezed,
  }) {
    return _then(
      _value.copyWith(
            liked: null == liked
                ? _value.liked
                : liked // ignore: cast_nullable_to_non_nullable
                      as bool,
            likeCount: null == likeCount
                ? _value.likeCount
                : likeCount // ignore: cast_nullable_to_non_nullable
                      as int,
            message: freezed == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LikeDataImplCopyWith<$Res>
    implements $LikeDataCopyWith<$Res> {
  factory _$$LikeDataImplCopyWith(
    _$LikeDataImpl value,
    $Res Function(_$LikeDataImpl) then,
  ) = __$$LikeDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool liked, int likeCount, String? message});
}

/// @nodoc
class __$$LikeDataImplCopyWithImpl<$Res>
    extends _$LikeDataCopyWithImpl<$Res, _$LikeDataImpl>
    implements _$$LikeDataImplCopyWith<$Res> {
  __$$LikeDataImplCopyWithImpl(
    _$LikeDataImpl _value,
    $Res Function(_$LikeDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LikeData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? liked = null,
    Object? likeCount = null,
    Object? message = freezed,
  }) {
    return _then(
      _$LikeDataImpl(
        liked: null == liked
            ? _value.liked
            : liked // ignore: cast_nullable_to_non_nullable
                  as bool,
        likeCount: null == likeCount
            ? _value.likeCount
            : likeCount // ignore: cast_nullable_to_non_nullable
                  as int,
        message: freezed == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LikeDataImpl implements _LikeData {
  const _$LikeDataImpl({
    required this.liked,
    required this.likeCount,
    this.message,
  });

  factory _$LikeDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$LikeDataImplFromJson(json);

  @override
  final bool liked;
  @override
  final int likeCount;
  @override
  final String? message;

  @override
  String toString() {
    return 'LikeData(liked: $liked, likeCount: $likeCount, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LikeDataImpl &&
            (identical(other.liked, liked) || other.liked == liked) &&
            (identical(other.likeCount, likeCount) ||
                other.likeCount == likeCount) &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, liked, likeCount, message);

  /// Create a copy of LikeData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LikeDataImplCopyWith<_$LikeDataImpl> get copyWith =>
      __$$LikeDataImplCopyWithImpl<_$LikeDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LikeDataImplToJson(this);
  }
}

abstract class _LikeData implements LikeData {
  const factory _LikeData({
    required final bool liked,
    required final int likeCount,
    final String? message,
  }) = _$LikeDataImpl;

  factory _LikeData.fromJson(Map<String, dynamic> json) =
      _$LikeDataImpl.fromJson;

  @override
  bool get liked;
  @override
  int get likeCount;
  @override
  String? get message;

  /// Create a copy of LikeData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LikeDataImplCopyWith<_$LikeDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Category _$CategoryFromJson(Map<String, dynamic> json) {
  return _Category.fromJson(json);
}

/// @nodoc
mixin _$Category {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get iconName => throw _privateConstructorUsedError;
  String? get colorCode => throw _privateConstructorUsedError;
  String? get coverImageUrl => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  bool get isFeatured => throw _privateConstructorUsedError;
  int get articleCount => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Category to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CategoryCopyWith<Category> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CategoryCopyWith<$Res> {
  factory $CategoryCopyWith(Category value, $Res Function(Category) then) =
      _$CategoryCopyWithImpl<$Res, Category>;
  @useResult
  $Res call({
    String id,
    String name,
    String slug,
    String? description,
    String? iconName,
    String? colorCode,
    String? coverImageUrl,
    bool isActive,
    bool isFeatured,
    int articleCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$CategoryCopyWithImpl<$Res, $Val extends Category>
    implements $CategoryCopyWith<$Res> {
  _$CategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? slug = null,
    Object? description = freezed,
    Object? iconName = freezed,
    Object? colorCode = freezed,
    Object? coverImageUrl = freezed,
    Object? isActive = null,
    Object? isFeatured = null,
    Object? articleCount = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            slug: null == slug
                ? _value.slug
                : slug // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            iconName: freezed == iconName
                ? _value.iconName
                : iconName // ignore: cast_nullable_to_non_nullable
                      as String?,
            colorCode: freezed == colorCode
                ? _value.colorCode
                : colorCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            coverImageUrl: freezed == coverImageUrl
                ? _value.coverImageUrl
                : coverImageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            isFeatured: null == isFeatured
                ? _value.isFeatured
                : isFeatured // ignore: cast_nullable_to_non_nullable
                      as bool,
            articleCount: null == articleCount
                ? _value.articleCount
                : articleCount // ignore: cast_nullable_to_non_nullable
                      as int,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CategoryImplCopyWith<$Res>
    implements $CategoryCopyWith<$Res> {
  factory _$$CategoryImplCopyWith(
    _$CategoryImpl value,
    $Res Function(_$CategoryImpl) then,
  ) = __$$CategoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String slug,
    String? description,
    String? iconName,
    String? colorCode,
    String? coverImageUrl,
    bool isActive,
    bool isFeatured,
    int articleCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$CategoryImplCopyWithImpl<$Res>
    extends _$CategoryCopyWithImpl<$Res, _$CategoryImpl>
    implements _$$CategoryImplCopyWith<$Res> {
  __$$CategoryImplCopyWithImpl(
    _$CategoryImpl _value,
    $Res Function(_$CategoryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? slug = null,
    Object? description = freezed,
    Object? iconName = freezed,
    Object? colorCode = freezed,
    Object? coverImageUrl = freezed,
    Object? isActive = null,
    Object? isFeatured = null,
    Object? articleCount = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$CategoryImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        slug: null == slug
            ? _value.slug
            : slug // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        iconName: freezed == iconName
            ? _value.iconName
            : iconName // ignore: cast_nullable_to_non_nullable
                  as String?,
        colorCode: freezed == colorCode
            ? _value.colorCode
            : colorCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        coverImageUrl: freezed == coverImageUrl
            ? _value.coverImageUrl
            : coverImageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        isFeatured: null == isFeatured
            ? _value.isFeatured
            : isFeatured // ignore: cast_nullable_to_non_nullable
                  as bool,
        articleCount: null == articleCount
            ? _value.articleCount
            : articleCount // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CategoryImpl implements _Category {
  const _$CategoryImpl({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.iconName,
    this.colorCode,
    this.coverImageUrl,
    this.isActive = true,
    this.isFeatured = false,
    this.articleCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory _$CategoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$CategoryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String slug;
  @override
  final String? description;
  @override
  final String? iconName;
  @override
  final String? colorCode;
  @override
  final String? coverImageUrl;
  @override
  @JsonKey()
  final bool isActive;
  @override
  @JsonKey()
  final bool isFeatured;
  @override
  @JsonKey()
  final int articleCount;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Category(id: $id, name: $name, slug: $slug, description: $description, iconName: $iconName, colorCode: $colorCode, coverImageUrl: $coverImageUrl, isActive: $isActive, isFeatured: $isFeatured, articleCount: $articleCount, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CategoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.iconName, iconName) ||
                other.iconName == iconName) &&
            (identical(other.colorCode, colorCode) ||
                other.colorCode == colorCode) &&
            (identical(other.coverImageUrl, coverImageUrl) ||
                other.coverImageUrl == coverImageUrl) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.isFeatured, isFeatured) ||
                other.isFeatured == isFeatured) &&
            (identical(other.articleCount, articleCount) ||
                other.articleCount == articleCount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    slug,
    description,
    iconName,
    colorCode,
    coverImageUrl,
    isActive,
    isFeatured,
    articleCount,
    createdAt,
    updatedAt,
  );

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CategoryImplCopyWith<_$CategoryImpl> get copyWith =>
      __$$CategoryImplCopyWithImpl<_$CategoryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CategoryImplToJson(this);
  }
}

abstract class _Category implements Category {
  const factory _Category({
    required final String id,
    required final String name,
    required final String slug,
    final String? description,
    final String? iconName,
    final String? colorCode,
    final String? coverImageUrl,
    final bool isActive,
    final bool isFeatured,
    final int articleCount,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _$CategoryImpl;

  factory _Category.fromJson(Map<String, dynamic> json) =
      _$CategoryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get slug;
  @override
  String? get description;
  @override
  String? get iconName;
  @override
  String? get colorCode;
  @override
  String? get coverImageUrl;
  @override
  bool get isActive;
  @override
  bool get isFeatured;
  @override
  int get articleCount;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CategoryImplCopyWith<_$CategoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ApiError _$ApiErrorFromJson(Map<String, dynamic> json) {
  return _ApiError.fromJson(json);
}

/// @nodoc
mixin _$ApiError {
  bool get success => throw _privateConstructorUsedError;
  ErrorInfo get error => throw _privateConstructorUsedError;

  /// Serializes this ApiError to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ApiError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ApiErrorCopyWith<ApiError> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApiErrorCopyWith<$Res> {
  factory $ApiErrorCopyWith(ApiError value, $Res Function(ApiError) then) =
      _$ApiErrorCopyWithImpl<$Res, ApiError>;
  @useResult
  $Res call({bool success, ErrorInfo error});

  $ErrorInfoCopyWith<$Res> get error;
}

/// @nodoc
class _$ApiErrorCopyWithImpl<$Res, $Val extends ApiError>
    implements $ApiErrorCopyWith<$Res> {
  _$ApiErrorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ApiError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? success = null, Object? error = null}) {
    return _then(
      _value.copyWith(
            success: null == success
                ? _value.success
                : success // ignore: cast_nullable_to_non_nullable
                      as bool,
            error: null == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as ErrorInfo,
          )
          as $Val,
    );
  }

  /// Create a copy of ApiError
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ErrorInfoCopyWith<$Res> get error {
    return $ErrorInfoCopyWith<$Res>(_value.error, (value) {
      return _then(_value.copyWith(error: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ApiErrorImplCopyWith<$Res>
    implements $ApiErrorCopyWith<$Res> {
  factory _$$ApiErrorImplCopyWith(
    _$ApiErrorImpl value,
    $Res Function(_$ApiErrorImpl) then,
  ) = __$$ApiErrorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool success, ErrorInfo error});

  @override
  $ErrorInfoCopyWith<$Res> get error;
}

/// @nodoc
class __$$ApiErrorImplCopyWithImpl<$Res>
    extends _$ApiErrorCopyWithImpl<$Res, _$ApiErrorImpl>
    implements _$$ApiErrorImplCopyWith<$Res> {
  __$$ApiErrorImplCopyWithImpl(
    _$ApiErrorImpl _value,
    $Res Function(_$ApiErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ApiError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? success = null, Object? error = null}) {
    return _then(
      _$ApiErrorImpl(
        success: null == success
            ? _value.success
            : success // ignore: cast_nullable_to_non_nullable
                  as bool,
        error: null == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as ErrorInfo,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ApiErrorImpl implements _ApiError {
  const _$ApiErrorImpl({required this.success, required this.error});

  factory _$ApiErrorImpl.fromJson(Map<String, dynamic> json) =>
      _$$ApiErrorImplFromJson(json);

  @override
  final bool success;
  @override
  final ErrorInfo error;

  @override
  String toString() {
    return 'ApiError(success: $success, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApiErrorImpl &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, success, error);

  /// Create a copy of ApiError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApiErrorImplCopyWith<_$ApiErrorImpl> get copyWith =>
      __$$ApiErrorImplCopyWithImpl<_$ApiErrorImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ApiErrorImplToJson(this);
  }
}

abstract class _ApiError implements ApiError {
  const factory _ApiError({
    required final bool success,
    required final ErrorInfo error,
  }) = _$ApiErrorImpl;

  factory _ApiError.fromJson(Map<String, dynamic> json) =
      _$ApiErrorImpl.fromJson;

  @override
  bool get success;
  @override
  ErrorInfo get error;

  /// Create a copy of ApiError
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApiErrorImplCopyWith<_$ApiErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ErrorInfo _$ErrorInfoFromJson(Map<String, dynamic> json) {
  return _ErrorInfo.fromJson(json);
}

/// @nodoc
mixin _$ErrorInfo {
  String get code => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  Map<String, dynamic>? get details => throw _privateConstructorUsedError;

  /// Serializes this ErrorInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ErrorInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ErrorInfoCopyWith<ErrorInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ErrorInfoCopyWith<$Res> {
  factory $ErrorInfoCopyWith(ErrorInfo value, $Res Function(ErrorInfo) then) =
      _$ErrorInfoCopyWithImpl<$Res, ErrorInfo>;
  @useResult
  $Res call({String code, String message, Map<String, dynamic>? details});
}

/// @nodoc
class _$ErrorInfoCopyWithImpl<$Res, $Val extends ErrorInfo>
    implements $ErrorInfoCopyWith<$Res> {
  _$ErrorInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ErrorInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? message = null,
    Object? details = freezed,
  }) {
    return _then(
      _value.copyWith(
            code: null == code
                ? _value.code
                : code // ignore: cast_nullable_to_non_nullable
                      as String,
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            details: freezed == details
                ? _value.details
                : details // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ErrorInfoImplCopyWith<$Res>
    implements $ErrorInfoCopyWith<$Res> {
  factory _$$ErrorInfoImplCopyWith(
    _$ErrorInfoImpl value,
    $Res Function(_$ErrorInfoImpl) then,
  ) = __$$ErrorInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String code, String message, Map<String, dynamic>? details});
}

/// @nodoc
class __$$ErrorInfoImplCopyWithImpl<$Res>
    extends _$ErrorInfoCopyWithImpl<$Res, _$ErrorInfoImpl>
    implements _$$ErrorInfoImplCopyWith<$Res> {
  __$$ErrorInfoImplCopyWithImpl(
    _$ErrorInfoImpl _value,
    $Res Function(_$ErrorInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ErrorInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? message = null,
    Object? details = freezed,
  }) {
    return _then(
      _$ErrorInfoImpl(
        code: null == code
            ? _value.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String,
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        details: freezed == details
            ? _value._details
            : details // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ErrorInfoImpl implements _ErrorInfo {
  const _$ErrorInfoImpl({
    required this.code,
    required this.message,
    final Map<String, dynamic>? details,
  }) : _details = details;

  factory _$ErrorInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ErrorInfoImplFromJson(json);

  @override
  final String code;
  @override
  final String message;
  final Map<String, dynamic>? _details;
  @override
  Map<String, dynamic>? get details {
    final value = _details;
    if (value == null) return null;
    if (_details is EqualUnmodifiableMapView) return _details;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'ErrorInfo(code: $code, message: $message, details: $details)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ErrorInfoImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.message, message) || other.message == message) &&
            const DeepCollectionEquality().equals(other._details, _details));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    code,
    message,
    const DeepCollectionEquality().hash(_details),
  );

  /// Create a copy of ErrorInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ErrorInfoImplCopyWith<_$ErrorInfoImpl> get copyWith =>
      __$$ErrorInfoImplCopyWithImpl<_$ErrorInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ErrorInfoImplToJson(this);
  }
}

abstract class _ErrorInfo implements ErrorInfo {
  const factory _ErrorInfo({
    required final String code,
    required final String message,
    final Map<String, dynamic>? details,
  }) = _$ErrorInfoImpl;

  factory _ErrorInfo.fromJson(Map<String, dynamic> json) =
      _$ErrorInfoImpl.fromJson;

  @override
  String get code;
  @override
  String get message;
  @override
  Map<String, dynamic>? get details;

  /// Create a copy of ErrorInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ErrorInfoImplCopyWith<_$ErrorInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
