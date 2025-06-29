/// 기사 모델
class Article {
  final String id;
  final String title;
  final String slug;
  final String? subtitle;
  final String? excerpt;
  final String content;
  final String? contentHtml;
  final String? featuredImageUrl;
  final String? featuredImageAlt;
  final int? readingTimeMinutes;
  final int? wordCount;
  final ArticleStatus status;
  final ArticleVisibility visibility;
  final String authorId;
  final String? editorId;
  final String? categoryId;
  final String? seoTitle;
  final String? seoDescription;
  final int viewCount;
  final int likeCount;
  final int shareCount;
  final int commentCount;
  final bool isFeatured;
  final DateTime? featuredAt;
  final bool isTrending;
  final double trendingScore;
  final String? aiSummary;
  final List<String> aiTags;
  final String? aiReadingLevel;
  final String? aiSentiment;
  final DateTime? scheduledAt;
  final DateTime? publishedAt;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Article({
    required this.id,
    required this.title,
    required this.slug,
    this.subtitle,
    this.excerpt,
    required this.content,
    this.contentHtml,
    this.featuredImageUrl,
    this.featuredImageAlt,
    this.readingTimeMinutes,
    this.wordCount,
    this.status = ArticleStatus.draft,
    this.visibility = ArticleVisibility.public,
    required this.authorId,
    this.editorId,
    this.categoryId,
    this.seoTitle,
    this.seoDescription,
    this.viewCount = 0,
    this.likeCount = 0,
    this.shareCount = 0,
    this.commentCount = 0,
    this.isFeatured = false,
    this.featuredAt,
    this.isTrending = false,
    this.trendingScore = 0,
    this.aiSummary,
    this.aiTags = const [],
    this.aiReadingLevel,
    this.aiSentiment,
    this.scheduledAt,
    this.publishedAt,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      subtitle: json['subtitle'],
      excerpt: json['excerpt'],
      content: json['content'] ?? '',
      contentHtml: json['contentHtml'],
      featuredImageUrl: json['featuredImageUrl'],
      featuredImageAlt: json['featuredImageAlt'],
      readingTimeMinutes: json['readingTimeMinutes'],
      wordCount: json['wordCount'],
      status: ArticleStatus.fromString(json['status'] ?? 'draft'),
      visibility: ArticleVisibility.fromString(json['visibility'] ?? 'public'),
      authorId: json['authorId'] ?? '',
      editorId: json['editorId'],
      categoryId: json['categoryId'],
      seoTitle: json['seoTitle'],
      seoDescription: json['seoDescription'],
      viewCount: json['viewCount'] ?? 0,
      likeCount: json['likeCount'] ?? 0,
      shareCount: json['shareCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      isFeatured: json['isFeatured'] ?? false,
      featuredAt: json['featuredAt'] != null ? DateTime.parse(json['featuredAt']) : null,
      isTrending: json['isTrending'] ?? false,
      trendingScore: (json['trendingScore'] ?? 0).toDouble(),
      aiSummary: json['aiSummary'],
      aiTags: List<String>.from(json['aiTags'] ?? []),
      aiReadingLevel: json['aiReadingLevel'],
      aiSentiment: json['aiSentiment'],
      scheduledAt: json['scheduledAt'] != null ? DateTime.parse(json['scheduledAt']) : null,
      publishedAt: json['publishedAt'] != null ? DateTime.parse(json['publishedAt']) : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'subtitle': subtitle,
      'excerpt': excerpt,
      'content': content,
      'contentHtml': contentHtml,
      'featuredImageUrl': featuredImageUrl,
      'featuredImageAlt': featuredImageAlt,
      'readingTimeMinutes': readingTimeMinutes,
      'wordCount': wordCount,
      'status': status.name,
      'visibility': visibility.name,
      'authorId': authorId,
      'editorId': editorId,
      'categoryId': categoryId,
      'seoTitle': seoTitle,
      'seoDescription': seoDescription,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'shareCount': shareCount,
      'commentCount': commentCount,
      'isFeatured': isFeatured,
      'featuredAt': featuredAt?.toIso8601String(),
      'isTrending': isTrending,
      'trendingScore': trendingScore,
      'aiSummary': aiSummary,
      'aiTags': aiTags,
      'aiReadingLevel': aiReadingLevel,
      'aiSentiment': aiSentiment,
      'scheduledAt': scheduledAt?.toIso8601String(),
      'publishedAt': publishedAt?.toIso8601String(),
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  Article copyWith({
    String? id,
    String? title,
    String? slug,
    String? subtitle,
    String? excerpt,
    String? content,
    String? contentHtml,
    String? featuredImageUrl,
    String? featuredImageAlt,
    int? readingTimeMinutes,
    int? wordCount,
    ArticleStatus? status,
    ArticleVisibility? visibility,
    String? authorId,
    String? editorId,
    String? categoryId,
    String? seoTitle,
    String? seoDescription,
    int? viewCount,
    int? likeCount,
    int? shareCount,
    int? commentCount,
    bool? isFeatured,
    DateTime? featuredAt,
    bool? isTrending,
    double? trendingScore,
    String? aiSummary,
    List<String>? aiTags,
    String? aiReadingLevel,
    String? aiSentiment,
    DateTime? scheduledAt,
    DateTime? publishedAt,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Article(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      subtitle: subtitle ?? this.subtitle,
      excerpt: excerpt ?? this.excerpt,
      content: content ?? this.content,
      contentHtml: contentHtml ?? this.contentHtml,
      featuredImageUrl: featuredImageUrl ?? this.featuredImageUrl,
      featuredImageAlt: featuredImageAlt ?? this.featuredImageAlt,
      readingTimeMinutes: readingTimeMinutes ?? this.readingTimeMinutes,
      wordCount: wordCount ?? this.wordCount,
      status: status ?? this.status,
      visibility: visibility ?? this.visibility,
      authorId: authorId ?? this.authorId,
      editorId: editorId ?? this.editorId,
      categoryId: categoryId ?? this.categoryId,
      seoTitle: seoTitle ?? this.seoTitle,
      seoDescription: seoDescription ?? this.seoDescription,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      shareCount: shareCount ?? this.shareCount,
      commentCount: commentCount ?? this.commentCount,
      isFeatured: isFeatured ?? this.isFeatured,
      featuredAt: featuredAt ?? this.featuredAt,
      isTrending: isTrending ?? this.isTrending,
      trendingScore: trendingScore ?? this.trendingScore,
      aiSummary: aiSummary ?? this.aiSummary,
      aiTags: aiTags ?? this.aiTags,
      aiReadingLevel: aiReadingLevel ?? this.aiReadingLevel,
      aiSentiment: aiSentiment ?? this.aiSentiment,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      publishedAt: publishedAt ?? this.publishedAt,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  bool get isPublished => status == ArticleStatus.published;
  bool get isDraft => status == ArticleStatus.draft;
  bool get isInReview => status == ArticleStatus.review;
  bool get isArchived => status == ArticleStatus.archived;
  bool get isDeleted => status == ArticleStatus.deleted;

  String get statusDisplayName => status.displayName;
  String get visibilityDisplayName => visibility.displayName;

  int get estimatedReadingTime {
    if (readingTimeMinutes != null) return readingTimeMinutes!;
    if (wordCount != null) return (wordCount! / 200).ceil();
    return (content.split(' ').length / 200).ceil();
  }

  int get currentWordCount {
    if (wordCount != null) return wordCount!;
    return content.split(' ').length;
  }
}

/// 기사 상태
enum ArticleStatus {
  draft('draft', '초안'),
  review('review', '검토중'),
  published('published', '발행됨'),
  archived('archived', '보관됨'),
  deleted('deleted', '삭제됨');

  const ArticleStatus(this.name, this.displayName);
  
  final String name;
  final String displayName;

  static ArticleStatus fromString(String status) {
    return ArticleStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => ArticleStatus.draft,
    );
  }
}

/// 기사 공개 설정
enum ArticleVisibility {
  public('public', '공개'),
  private('private', '비공개'),
  unlisted('unlisted', '목록에서 숨김');

  const ArticleVisibility(this.name, this.displayName);
  
  final String name;
  final String displayName;

  static ArticleVisibility fromString(String visibility) {
    return ArticleVisibility.values.firstWhere(
      (e) => e.name == visibility,
      orElse: () => ArticleVisibility.public,
    );
  }
}

/// 기사 생성 요청
class CreateArticleRequest {
  final String title;
  final String content;
  final String? subtitle;
  final String? excerpt;
  final String? featuredImageUrl;
  final String? categoryId;
  final List<String>? tagIds;
  final ArticleStatus status;
  final ArticleVisibility visibility;
  final String? seoTitle;
  final String? seoDescription;
  final DateTime? scheduledAt;
  final Map<String, dynamic>? metadata;

  CreateArticleRequest({
    required this.title,
    required this.content,
    this.subtitle,
    this.excerpt,
    this.featuredImageUrl,
    this.categoryId,
    this.tagIds,
    this.status = ArticleStatus.draft,
    this.visibility = ArticleVisibility.public,
    this.seoTitle,
    this.seoDescription,
    this.scheduledAt,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'subtitle': subtitle,
      'excerpt': excerpt,
      'featuredImageUrl': featuredImageUrl,
      'categoryId': categoryId,
      'tagIds': tagIds,
      'status': status.name,
      'visibility': visibility.name,
      'seoTitle': seoTitle,
      'seoDescription': seoDescription,
      'scheduledAt': scheduledAt?.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// 기사 수정 요청
class UpdateArticleRequest {
  final String? title;
  final String? content;
  final String? subtitle;
  final String? excerpt;
  final String? featuredImageUrl;
  final String? categoryId;
  final List<String>? tagIds;
  final ArticleStatus? status;
  final ArticleVisibility? visibility;
  final String? seoTitle;
  final String? seoDescription;
  final DateTime? scheduledAt;
  final Map<String, dynamic>? metadata;

  UpdateArticleRequest({
    this.title,
    this.content,
    this.subtitle,
    this.excerpt,
    this.featuredImageUrl,
    this.categoryId,
    this.tagIds,
    this.status,
    this.visibility,
    this.seoTitle,
    this.seoDescription,
    this.scheduledAt,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    
    if (title != null) json['title'] = title;
    if (content != null) json['content'] = content;
    if (subtitle != null) json['subtitle'] = subtitle;
    if (excerpt != null) json['excerpt'] = excerpt;
    if (featuredImageUrl != null) json['featuredImageUrl'] = featuredImageUrl;
    if (categoryId != null) json['categoryId'] = categoryId;
    if (tagIds != null) json['tagIds'] = tagIds;
    if (status != null) json['status'] = status!.name;
    if (visibility != null) json['visibility'] = visibility!.name;
    if (seoTitle != null) json['seoTitle'] = seoTitle;
    if (seoDescription != null) json['seoDescription'] = seoDescription;
    if (scheduledAt != null) json['scheduledAt'] = scheduledAt!.toIso8601String();
    if (metadata != null) json['metadata'] = metadata;
    
    return json;
  }
}