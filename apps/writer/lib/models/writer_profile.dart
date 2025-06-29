/// 작가 프로필 모델
class WriterProfile {
  final String id;
  final String userId;
  final String displayName;
  final String? bio;
  final String? profileImageUrl;
  final List<String> specialties;
  final int yearsOfExperience;
  final String? education;
  final List<String> previousPublications;
  final List<String> awards;
  final String? websiteUrl;
  final String? twitterHandle;
  final String? instagramHandle;
  final String? linkedinUrl;
  final String? contactEmail;
  final bool isAvailableForCollaboration;
  final List<String> preferredTopics;
  final String? writingSchedule;
  final bool isVerified;
  final DateTime? verificationDate;
  final String? verificationNotes;
  final int totalArticles;
  final int totalViews;
  final int totalLikes;
  final int followerCount;
  final bool profileCompleted;
  final DateTime? lastActiveAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  WriterProfile({
    required this.id,
    required this.userId,
    required this.displayName,
    this.bio,
    this.profileImageUrl,
    this.specialties = const [],
    this.yearsOfExperience = 0,
    this.education,
    this.previousPublications = const [],
    this.awards = const [],
    this.websiteUrl,
    this.twitterHandle,
    this.instagramHandle,
    this.linkedinUrl,
    this.contactEmail,
    this.isAvailableForCollaboration = true,
    this.preferredTopics = const [],
    this.writingSchedule,
    this.isVerified = false,
    this.verificationDate,
    this.verificationNotes,
    this.totalArticles = 0,
    this.totalViews = 0,
    this.totalLikes = 0,
    this.followerCount = 0,
    this.profileCompleted = false,
    this.lastActiveAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WriterProfile.fromJson(Map<String, dynamic> json) {
    return WriterProfile(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      displayName: json['display_name'] ?? json['displayName'] ?? '',
      bio: json['bio'],
      profileImageUrl: json['profile_image_url'] ?? json['profileImageUrl'],
      specialties: List<String>.from(json['specialties'] ?? []),
      yearsOfExperience: json['years_of_experience'] ?? json['yearsOfExperience'] ?? 0,
      education: json['education'],
      previousPublications: List<String>.from(json['previous_publications'] ?? json['previousPublications'] ?? []),
      awards: List<String>.from(json['awards'] ?? []),
      websiteUrl: json['website_url'] ?? json['websiteUrl'],
      twitterHandle: json['twitter_handle'] ?? json['twitterHandle'],
      instagramHandle: json['instagram_handle'] ?? json['instagramHandle'],
      linkedinUrl: json['linkedin_url'] ?? json['linkedinUrl'],
      contactEmail: json['contact_email'] ?? json['contactEmail'],
      isAvailableForCollaboration: json['is_available_for_collaboration'] ?? json['isAvailableForCollaboration'] ?? true,
      preferredTopics: List<String>.from(json['preferred_topics'] ?? json['preferredTopics'] ?? []),
      writingSchedule: json['writing_schedule'] ?? json['writingSchedule'],
      isVerified: json['is_verified'] ?? json['isVerified'] ?? false,
      verificationDate: json['verification_date'] != null || json['verificationDate'] != null
          ? DateTime.parse(json['verification_date'] ?? json['verificationDate'])
          : null,
      verificationNotes: json['verification_notes'] ?? json['verificationNotes'],
      totalArticles: json['total_articles'] ?? json['totalArticles'] ?? 0,
      totalViews: json['total_views'] ?? json['totalViews'] ?? 0,
      totalLikes: json['total_likes'] ?? json['totalLikes'] ?? 0,
      followerCount: json['follower_count'] ?? json['followerCount'] ?? 0,
      profileCompleted: json['profile_completed'] ?? json['profileCompleted'] ?? false,
      lastActiveAt: json['last_active_at'] != null || json['lastActiveAt'] != null
          ? DateTime.parse(json['last_active_at'] ?? json['lastActiveAt'])
          : null,
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt']),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'display_name': displayName,
      'bio': bio,
      'profile_image_url': profileImageUrl,
      'specialties': specialties,
      'years_of_experience': yearsOfExperience,
      'education': education,
      'previous_publications': previousPublications,
      'awards': awards,
      'website_url': websiteUrl,
      'twitter_handle': twitterHandle,
      'instagram_handle': instagramHandle,
      'linkedin_url': linkedinUrl,
      'contact_email': contactEmail,
      'is_available_for_collaboration': isAvailableForCollaboration,
      'preferred_topics': preferredTopics,
      'writing_schedule': writingSchedule,
      'is_verified': isVerified,
      'verification_date': verificationDate?.toIso8601String(),
      'verification_notes': verificationNotes,
      'total_articles': totalArticles,
      'total_views': totalViews,
      'total_likes': totalLikes,
      'follower_count': followerCount,
      'profile_completed': profileCompleted,
      'last_active_at': lastActiveAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  WriterProfile copyWith({
    String? id,
    String? userId,
    String? displayName,
    String? bio,
    String? profileImageUrl,
    List<String>? specialties,
    int? yearsOfExperience,
    String? education,
    List<String>? previousPublications,
    List<String>? awards,
    String? websiteUrl,
    String? twitterHandle,
    String? instagramHandle,
    String? linkedinUrl,
    String? contactEmail,
    bool? isAvailableForCollaboration,
    List<String>? preferredTopics,
    String? writingSchedule,
    bool? isVerified,
    DateTime? verificationDate,
    String? verificationNotes,
    int? totalArticles,
    int? totalViews,
    int? totalLikes,
    int? followerCount,
    bool? profileCompleted,
    DateTime? lastActiveAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WriterProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      specialties: specialties ?? this.specialties,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      education: education ?? this.education,
      previousPublications: previousPublications ?? this.previousPublications,
      awards: awards ?? this.awards,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      twitterHandle: twitterHandle ?? this.twitterHandle,
      instagramHandle: instagramHandle ?? this.instagramHandle,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      contactEmail: contactEmail ?? this.contactEmail,
      isAvailableForCollaboration: isAvailableForCollaboration ?? this.isAvailableForCollaboration,
      preferredTopics: preferredTopics ?? this.preferredTopics,
      writingSchedule: writingSchedule ?? this.writingSchedule,
      isVerified: isVerified ?? this.isVerified,
      verificationDate: verificationDate ?? this.verificationDate,
      verificationNotes: verificationNotes ?? this.verificationNotes,
      totalArticles: totalArticles ?? this.totalArticles,
      totalViews: totalViews ?? this.totalViews,
      totalLikes: totalLikes ?? this.totalLikes,
      followerCount: followerCount ?? this.followerCount,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // 프로필 완성도 계산 (0.0 ~ 1.0)
  double get completionPercentage {
    int completedFields = 0;
    int totalFields = 8; // 필수 + 중요 필드 개수

    // 필수 필드들
    if (displayName.isNotEmpty) completedFields++;
    if (bio != null && bio!.isNotEmpty) completedFields++;
    if (specialties.isNotEmpty) completedFields++;
    
    // 중요 필드들
    if (profileImageUrl != null) completedFields++;
    if (yearsOfExperience > 0) completedFields++;
    if (education != null && education!.isNotEmpty) completedFields++;
    if (preferredTopics.isNotEmpty) completedFields++;
    if (writingSchedule != null && writingSchedule!.isNotEmpty) completedFields++;

    return completedFields / totalFields;
  }

  // 프로필 상태
  String get profileStatus {
    final percentage = completionPercentage;
    if (percentage >= 1.0) return '완료';
    if (percentage >= 0.8) return '거의 완료';
    if (percentage >= 0.5) return '진행 중';
    if (percentage >= 0.3) return '시작';
    return '미완료';
  }

  // 경력 레벨
  String get experienceLevel {
    if (yearsOfExperience >= 10) return '시니어 작가';
    if (yearsOfExperience >= 5) return '경력 작가';
    if (yearsOfExperience >= 2) return '중급 작가';
    if (yearsOfExperience >= 1) return '주니어 작가';
    return '신입 작가';
  }

  // 주요 전문 분야 (최대 3개)
  List<String> get primarySpecialties {
    return specialties.take(3).toList();
  }

  // 소셜 미디어 링크 유무
  bool get hasSocialLinks {
    return twitterHandle != null || 
           instagramHandle != null || 
           linkedinUrl != null || 
           websiteUrl != null;
  }
}

/// 작가 프로필 생성/수정 요청 모델
class CreateWriterProfileRequest {
  final String displayName;
  final String? bio;
  final String? profileImageUrl;
  final List<String> specialties;
  final int yearsOfExperience;
  final String? education;
  final List<String> previousPublications;
  final List<String> awards;
  final String? websiteUrl;
  final String? twitterHandle;
  final String? instagramHandle;
  final String? linkedinUrl;
  final String? contactEmail;
  final bool isAvailableForCollaboration;
  final List<String> preferredTopics;
  final String? writingSchedule;

  CreateWriterProfileRequest({
    required this.displayName,
    this.bio,
    this.profileImageUrl,
    this.specialties = const [],
    this.yearsOfExperience = 0,
    this.education,
    this.previousPublications = const [],
    this.awards = const [],
    this.websiteUrl,
    this.twitterHandle,
    this.instagramHandle,
    this.linkedinUrl,
    this.contactEmail,
    this.isAvailableForCollaboration = true,
    this.preferredTopics = const [],
    this.writingSchedule,
  });

  Map<String, dynamic> toJson() {
    return {
      'display_name': displayName,
      'bio': bio,
      'profile_image_url': profileImageUrl,
      'specialties': specialties,
      'years_of_experience': yearsOfExperience,
      'education': education,
      'previous_publications': previousPublications,
      'awards': awards,
      'website_url': websiteUrl,
      'twitter_handle': twitterHandle,
      'instagram_handle': instagramHandle,
      'linkedin_url': linkedinUrl,
      'contact_email': contactEmail,
      'is_available_for_collaboration': isAvailableForCollaboration,
      'preferred_topics': preferredTopics,
      'writing_schedule': writingSchedule,
    };
  }
}

/// 미리 정의된 전문 분야 목록
class WriterSpecialties {
  static const List<String> all = [
    '기술/IT',
    '문학/소설',
    '과학',
    '경제/금융',
    '정치/사회',
    '문화/예술',
    '스포츠',
    '여행',
    '음식/요리',
    '패션/뷰티',
    '건강/의학',
    '교육',
    '환경',
    '역사',
    '철학',
    '심리학',
    '자기계발',
    '비즈니스',
    '마케팅',
    '디자인',
    '영화/드라마',
    '음악',
    '게임',
    '부동산',
    '육아/교육',
    '반려동물',
    '취미/레저',
    '기타',
  ];
}

/// 글쓰기 일정 옵션
class WritingSchedules {
  static const List<String> all = [
    '평일 오전',
    '평일 오후',
    '평일 저녁',
    '주말',
    '새벽 시간',
    '심야 시간',
    '자유롭게',
    '정해진 시간 없음',
  ];
}