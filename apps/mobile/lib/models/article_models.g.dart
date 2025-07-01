// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ArticleListResponseImpl _$$ArticleListResponseImplFromJson(
  Map<String, dynamic> json,
) => _$ArticleListResponseImpl(
  success: json['success'] as bool,
  data: ArticleListData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$ArticleListResponseImplToJson(
  _$ArticleListResponseImpl instance,
) => <String, dynamic>{'success': instance.success, 'data': instance.data};

_$ArticleListDataImpl _$$ArticleListDataImplFromJson(
  Map<String, dynamic> json,
) => _$ArticleListDataImpl(
  articles: (json['articles'] as List<dynamic>)
      .map((e) => Article.fromJson(e as Map<String, dynamic>))
      .toList(),
  pagination: Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
  query: json['query'] as String?,
  categoryId: json['categoryId'] as String?,
  authorId: json['authorId'] as String?,
);

Map<String, dynamic> _$$ArticleListDataImplToJson(
  _$ArticleListDataImpl instance,
) => <String, dynamic>{
  'articles': instance.articles,
  'pagination': instance.pagination,
  'query': instance.query,
  'categoryId': instance.categoryId,
  'authorId': instance.authorId,
};

_$PaginationImpl _$$PaginationImplFromJson(Map<String, dynamic> json) =>
    _$PaginationImpl(
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      totalPages: (json['totalPages'] as num).toInt(),
    );

Map<String, dynamic> _$$PaginationImplToJson(_$PaginationImpl instance) =>
    <String, dynamic>{
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
      'totalPages': instance.totalPages,
    };

_$ArticleDetailResponseImpl _$$ArticleDetailResponseImplFromJson(
  Map<String, dynamic> json,
) => _$ArticleDetailResponseImpl(
  success: json['success'] as bool,
  data: ArticleDetailData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$ArticleDetailResponseImplToJson(
  _$ArticleDetailResponseImpl instance,
) => <String, dynamic>{'success': instance.success, 'data': instance.data};

_$ArticleDetailDataImpl _$$ArticleDetailDataImplFromJson(
  Map<String, dynamic> json,
) => _$ArticleDetailDataImpl(
  article: Article.fromJson(json['article'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$ArticleDetailDataImplToJson(
  _$ArticleDetailDataImpl instance,
) => <String, dynamic>{'article': instance.article};

_$LikeResponseImpl _$$LikeResponseImplFromJson(Map<String, dynamic> json) =>
    _$LikeResponseImpl(
      success: json['success'] as bool,
      data: LikeData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$LikeResponseImplToJson(_$LikeResponseImpl instance) =>
    <String, dynamic>{'success': instance.success, 'data': instance.data};

_$LikeDataImpl _$$LikeDataImplFromJson(Map<String, dynamic> json) =>
    _$LikeDataImpl(
      liked: json['liked'] as bool,
      likeCount: (json['likeCount'] as num).toInt(),
      message: json['message'] as String?,
    );

Map<String, dynamic> _$$LikeDataImplToJson(_$LikeDataImpl instance) =>
    <String, dynamic>{
      'liked': instance.liked,
      'likeCount': instance.likeCount,
      'message': instance.message,
    };

_$CategoryImpl _$$CategoryImplFromJson(Map<String, dynamic> json) =>
    _$CategoryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      iconName: json['iconName'] as String?,
      colorCode: json['colorCode'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isFeatured: json['isFeatured'] as bool? ?? false,
      articleCount: (json['articleCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$CategoryImplToJson(_$CategoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'description': instance.description,
      'iconName': instance.iconName,
      'colorCode': instance.colorCode,
      'coverImageUrl': instance.coverImageUrl,
      'isActive': instance.isActive,
      'isFeatured': instance.isFeatured,
      'articleCount': instance.articleCount,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$ApiErrorImpl _$$ApiErrorImplFromJson(Map<String, dynamic> json) =>
    _$ApiErrorImpl(
      success: json['success'] as bool,
      error: ErrorInfo.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ApiErrorImplToJson(_$ApiErrorImpl instance) =>
    <String, dynamic>{'success': instance.success, 'error': instance.error};

_$ErrorInfoImpl _$$ErrorInfoImplFromJson(Map<String, dynamic> json) =>
    _$ErrorInfoImpl(
      code: json['code'] as String,
      message: json['message'] as String,
      details: json['details'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$ErrorInfoImplToJson(_$ErrorInfoImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'details': instance.details,
    };
