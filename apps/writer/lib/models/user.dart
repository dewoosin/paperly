/// 사용자 모델
class User {
  final String id;
  final String email;
  final String name;
  final String? bio;
  final String? profileImageUrl;
  final bool emailVerified;
  final bool profileCompleted;
  final List<String> roles;
  final UserStats? stats;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.bio,
    this.profileImageUrl,
    this.emailVerified = false,
    this.profileCompleted = false,
    this.roles = const [],
    this.stats,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      bio: json['bio'],
      profileImageUrl: json['profileImageUrl'],
      emailVerified: json['emailVerified'] ?? false,
      profileCompleted: json['profileCompleted'] ?? false,
      roles: List<String>.from(json['roles'] ?? []),
      stats: json['stats'] != null ? UserStats.fromJson(json['stats']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'emailVerified': emailVerified,
      'profileCompleted': profileCompleted,
      'roles': roles,
      'stats': stats?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? bio,
    String? profileImageUrl,
    bool? emailVerified,
    bool? profileCompleted,
    List<String>? roles,
    UserStats? stats,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      roles: roles ?? this.roles,
      stats: stats ?? this.stats,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isAuthor => roles.contains('author');
  bool get isEditor => roles.contains('editor');
  bool get isAdmin => roles.contains('admin');
  
  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return 'U';
  }
}

/// 사용자 통계
class UserStats {
  final int totalArticles;
  final int publishedArticles;
  final int draftArticles;
  final int totalViews;
  final int totalLikes;
  final int totalShares;
  final int totalComments;
  final double averageRating;
  final int followersCount;
  final int followingCount;

  UserStats({
    this.totalArticles = 0,
    this.publishedArticles = 0,
    this.draftArticles = 0,
    this.totalViews = 0,
    this.totalLikes = 0,
    this.totalShares = 0,
    this.totalComments = 0,
    this.averageRating = 0.0,
    this.followersCount = 0,
    this.followingCount = 0,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalArticles: json['totalArticles'] ?? 0,
      publishedArticles: json['publishedArticles'] ?? 0,
      draftArticles: json['draftArticles'] ?? 0,
      totalViews: json['totalViews'] ?? 0,
      totalLikes: json['totalLikes'] ?? 0,
      totalShares: json['totalShares'] ?? 0,
      totalComments: json['totalComments'] ?? 0,
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalArticles': totalArticles,
      'publishedArticles': publishedArticles,
      'draftArticles': draftArticles,
      'totalViews': totalViews,
      'totalLikes': totalLikes,
      'totalShares': totalShares,
      'totalComments': totalComments,
      'averageRating': averageRating,
      'followersCount': followersCount,
      'followingCount': followingCount,
    };
  }

  UserStats copyWith({
    int? totalArticles,
    int? publishedArticles,
    int? draftArticles,
    int? totalViews,
    int? totalLikes,
    int? totalShares,
    int? totalComments,
    double? averageRating,
    int? followersCount,
    int? followingCount,
  }) {
    return UserStats(
      totalArticles: totalArticles ?? this.totalArticles,
      publishedArticles: publishedArticles ?? this.publishedArticles,
      draftArticles: draftArticles ?? this.draftArticles,
      totalViews: totalViews ?? this.totalViews,
      totalLikes: totalLikes ?? this.totalLikes,
      totalShares: totalShares ?? this.totalShares,
      totalComments: totalComments ?? this.totalComments,
      averageRating: averageRating ?? this.averageRating,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
    );
  }
}