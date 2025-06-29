// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'author_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AuthorImpl _$AuthorFromJson(Map<String, dynamic> json) => _$AuthorImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: json['displayName'] as String,
      bio: json['bio'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      specialties: (json['specialties'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      yearsOfExperience: (json['yearsOfExperience'] as num?)?.toInt(),
      education: json['education'] as String?,
      previousPublications: (json['previousPublications'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      awards: (json['awards'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      websiteUrl: json['websiteUrl'] as String?,
      twitterHandle: json['twitterHandle'] as String?,
      instagramHandle: json['instagramHandle'] as String?,
      linkedinUrl: json['linkedinUrl'] as String?,
      contactEmail: json['contactEmail'] as String?,
      isAvailableForCollaboration:
          json['isAvailableForCollaboration'] as bool? ?? true,
      preferredTopics: (json['preferredTopics'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      writingSchedule: json['writingSchedule'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      verificationDate: json['verificationDate'] == null
          ? null
          : DateTime.parse(json['verificationDate'] as String),
      verificationNotes: json['verificationNotes'] as String?,
      stats: json['stats'] == null
          ? null
          : AuthorStats.fromJson(json['stats'] as Map<String, dynamic>),
      isFollowing: json['isFollowing'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$AuthorImplToJson(_$AuthorImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'displayName': instance.displayName,
      'bio': instance.bio,
      'profileImageUrl': instance.profileImageUrl,
      'specialties': instance.specialties,
      'yearsOfExperience': instance.yearsOfExperience,
      'education': instance.education,
      'previousPublications': instance.previousPublications,
      'awards': instance.awards,
      'websiteUrl': instance.websiteUrl,
      'twitterHandle': instance.twitterHandle,
      'instagramHandle': instance.instagramHandle,
      'linkedinUrl': instance.linkedinUrl,
      'contactEmail': instance.contactEmail,
      'isAvailableForCollaboration': instance.isAvailableForCollaboration,
      'preferredTopics': instance.preferredTopics,
      'writingSchedule': instance.writingSchedule,
      'isVerified': instance.isVerified,
      'verificationDate': instance.verificationDate?.toIso8601String(),
      'verificationNotes': instance.verificationNotes,
      'stats': instance.stats,
      'isFollowing': instance.isFollowing,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$AuthorStatsImpl _$$AuthorStatsImplFromJson(Map<String, dynamic> json) =>
    _$AuthorStatsImpl(
      totalArticles: (json['totalArticles'] as num?)?.toInt() ?? 0,
      publishedArticles: (json['publishedArticles'] as num?)?.toInt() ?? 0,
      totalViews: (json['totalViews'] as num?)?.toInt() ?? 0,
      totalLikes: (json['totalLikes'] as num?)?.toInt() ?? 0,
      totalShares: (json['totalShares'] as num?)?.toInt() ?? 0,
      totalComments: (json['totalComments'] as num?)?.toInt() ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
      lastActiveAt: json['lastActiveAt'] == null
          ? null
          : DateTime.parse(json['lastActiveAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$AuthorStatsImplToJson(_$AuthorStatsImpl instance) =>
    <String, dynamic>{
      'totalArticles': instance.totalArticles,
      'publishedArticles': instance.publishedArticles,
      'totalViews': instance.totalViews,
      'totalLikes': instance.totalLikes,
      'totalShares': instance.totalShares,
      'totalComments': instance.totalComments,
      'averageRating': instance.averageRating,
      'followerCount': instance.followerCount,
      'followingCount': instance.followingCount,
      'lastActiveAt': instance.lastActiveAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$FollowRequestImpl _$$FollowRequestImplFromJson(Map<String, dynamic> json) =>
    _$FollowRequestImpl(
      authorId: json['authorId'] as String,
      follow: json['follow'] as bool? ?? true,
    );

Map<String, dynamic> _$$FollowRequestImplToJson(_$FollowRequestImpl instance) =>
    <String, dynamic>{
      'authorId': instance.authorId,
      'follow': instance.follow,
    };

_$FollowResponseImpl _$$FollowResponseImplFromJson(Map<String, dynamic> json) =>
    _$FollowResponseImpl(
      authorId: json['authorId'] as String,
      isFollowing: json['isFollowing'] as bool,
      followerCount: (json['followerCount'] as num).toInt(),
      message: json['message'] as String?,
    );

Map<String, dynamic> _$$FollowResponseImplToJson(
        _$FollowResponseImpl instance) =>
    <String, dynamic>{
      'authorId': instance.authorId,
      'isFollowing': instance.isFollowing,
      'followerCount': instance.followerCount,
      'message': instance.message,
    };

_$AuthorListResponseImpl _$$AuthorListResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$AuthorListResponseImpl(
      authors: (json['authors'] as List<dynamic>)
          .map((e) => Author.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      hasNext: json['hasNext'] as bool,
      hasPrevious: json['hasPrevious'] as bool,
    );

Map<String, dynamic> _$$AuthorListResponseImplToJson(
        _$AuthorListResponseImpl instance) =>
    <String, dynamic>{
      'authors': instance.authors,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
      'hasNext': instance.hasNext,
      'hasPrevious': instance.hasPrevious,
    };

_$AuthorSearchRequestImpl _$$AuthorSearchRequestImplFromJson(
        Map<String, dynamic> json) =>
    _$AuthorSearchRequestImpl(
      query: json['query'] as String?,
      specialties: (json['specialties'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      verifiedOnly: json['verifiedOnly'] as bool?,
      sortBy: json['sortBy'] as String?,
      sortOrder: json['sortOrder'] as String? ?? 'desc',
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
    );

Map<String, dynamic> _$$AuthorSearchRequestImplToJson(
        _$AuthorSearchRequestImpl instance) =>
    <String, dynamic>{
      'query': instance.query,
      'specialties': instance.specialties,
      'verifiedOnly': instance.verifiedOnly,
      'sortBy': instance.sortBy,
      'sortOrder': instance.sortOrder,
      'page': instance.page,
      'limit': instance.limit,
    };

_$FollowStatusChangeEventImpl _$$FollowStatusChangeEventImplFromJson(
        Map<String, dynamic> json) =>
    _$FollowStatusChangeEventImpl(
      authorId: json['authorId'] as String,
      isFollowing: json['isFollowing'] as bool,
      followerCount: (json['followerCount'] as num).toInt(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$$FollowStatusChangeEventImplToJson(
        _$FollowStatusChangeEventImpl instance) =>
    <String, dynamic>{
      'authorId': instance.authorId,
      'isFollowing': instance.isFollowing,
      'followerCount': instance.followerCount,
      'timestamp': instance.timestamp.toIso8601String(),
    };

_$RecommendedAuthorsResponseImpl _$$RecommendedAuthorsResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$RecommendedAuthorsResponseImpl(
      authors: (json['authors'] as List<dynamic>)
          .map((e) => Author.fromJson(e as Map<String, dynamic>))
          .toList(),
      reason: json['reason'] as String,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      algorithmVersion: json['algorithmVersion'] as String?,
    );

Map<String, dynamic> _$$RecommendedAuthorsResponseImplToJson(
        _$RecommendedAuthorsResponseImpl instance) =>
    <String, dynamic>{
      'authors': instance.authors,
      'reason': instance.reason,
      'confidence': instance.confidence,
      'algorithmVersion': instance.algorithmVersion,
    };