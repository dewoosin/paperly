/// Paperly Mobile App - 작가 관련 데이터 모델
/// 
/// 이 파일은 작가 정보와 팔로우 시스템에서 사용되는 모든 데이터 모델을 정의합니다.
/// Freezed 패키지를 사용하여 불변객체와 직렬화 기능을 제공합니다.
/// 
/// 주요 모델들:
/// - Author: 작가 기본 정보 (이름, 프로필, 전문분야 등)
/// - AuthorStats: 작가 통계 (팔로워 수, 글 수, 조회수 등)
/// - FollowRequest: 팔로우/언팔로우 요청 데이터
/// - FollowResponse: 팔로우 응답 데이터
/// - AuthorListResponse: 작가 목록 조회 응답

import 'package:freezed_annotation/freezed_annotation.dart';

// Freezed에 의해 자동 생성되는 파일들
part 'author_models.freezed.dart';
// part 'author_models.g.dart'; // Temporarily disabled due to build issues

/// 작가 정보 모델
/// 
/// 플랫폼에 등록된 작가의 기본 정보를 담는 불변객체입니다.
/// 홈 화면, 검색, 작가 상세 페이지 등에서 공통으로 사용됩니다.
@freezed
class Author with _$Author {
  const Author._();
  const factory Author({
    required String id,              // 작가 고유 ID
    required String name,            // 작가 이름
    required String displayName,     // 표시용 이름 (필명)
    String? bio,                     // 자기소개
    String? profileImageUrl,         // 프로필 이미지 URL
    @Default([]) List<String> specialties,  // 전문 분야
    int? yearsOfExperience,          // 경력 연수
    String? education,               // 학력
    @Default([]) List<String> previousPublications,  // 이전 출간작
    @Default([]) List<String> awards,         // 수상 경력
    String? websiteUrl,              // 개인 웹사이트
    String? twitterHandle,           // 트위터 핸들
    String? instagramHandle,         // 인스타그램 핸들
    String? linkedinUrl,             // 링크드인 URL
    String? contactEmail,            // 연락처 이메일
    @Default(true) bool isAvailableForCollaboration,  // 협업 가능 여부
    @Default([]) List<String> preferredTopics,        // 선호 주제
    String? writingSchedule,         // 글 작성 일정
    @Default(false) bool isVerified, // 인증 작가 여부
    DateTime? verificationDate,      // 인증 날짜
    String? verificationNotes,       // 인증 참고사항
    AuthorStats? stats,              // 작가 통계
    @Default(false) bool isFollowing, // 현재 사용자의 팔로우 여부
    DateTime? createdAt,             // 등록일
    DateTime? updatedAt,             // 최종 수정일
  }) = _Author;

  /// JSON에서 Author 객체로 변환
  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      displayName: json['displayName'] ?? json['name'] ?? '',
      bio: json['bio'],
      profileImageUrl: json['profileImageUrl'],
    );
  }

}

/// 작가 통계 정보 모델
/// 
/// 작가의 활동 지표와 성과를 나타내는 데이터를 담습니다.
/// 작가 카드나 상세 페이지에서 팔로워 수, 글 수 등을 표시할 때 사용합니다.
@freezed
class AuthorStats with _$AuthorStats {
  const factory AuthorStats({
    @Default(0) int totalArticles,   // 총 글 수
    @Default(0) int publishedArticles, // 발행된 글 수
    @Default(0) int totalViews,      // 총 조회수
    @Default(0) int totalLikes,      // 총 좋아요 수
    @Default(0) int totalShares,     // 총 공유 수
    @Default(0) int totalComments,   // 총 댓글 수
    @Default(0.0) double averageRating, // 평균 평점
    @Default(0) int followerCount,   // 팔로워 수
    @Default(0) int followingCount,  // 팔로잉 수
    DateTime? lastActiveAt,          // 마지막 활동 시간
    DateTime? updatedAt,             // 통계 업데이트 시간
  }) = _AuthorStats;

  /// JSON에서 AuthorStats 객체로 변환
  factory AuthorStats.fromJson(Map<String, dynamic> json) => _$AuthorStatsFromJson(json);
}

/// 팔로우 요청 모델
/// 
/// 작가를 팔로우하거나 언팔로우할 때 서버로 전송하는 데이터입니다.
@freezed
class FollowRequest with _$FollowRequest {
  const factory FollowRequest({
    required String authorId,        // 팔로우할 작가 ID
    @Default(true) bool follow,      // true: 팔로우, false: 언팔로우
  }) = _FollowRequest;

  /// JSON에서 FollowRequest 객체로 변환
  factory FollowRequest.fromJson(Map<String, dynamic> json) => _$FollowRequestFromJson(json);
}

/// 팔로우 응답 모델
/// 
/// 팔로우/언팔로우 API 호출 후 서버에서 반환하는 응답 데이터입니다.
@freezed
class FollowResponse with _$FollowResponse {
  const factory FollowResponse({
    required String authorId,        // 작가 ID
    required bool isFollowing,       // 현재 팔로우 상태
    required int followerCount,      // 변경된 팔로워 수
    String? message,                 // 응답 메시지
  }) = _FollowResponse;

  /// JSON에서 FollowResponse 객체로 변환
  factory FollowResponse.fromJson(Map<String, dynamic> json) => _$FollowResponseFromJson(json);
}

/// 작가 목록 조회 응답 모델
/// 
/// 작가 검색이나 추천 작가 목록 API에서 반환하는 페이지네이션된 데이터입니다.
@freezed
class AuthorListResponse with _$AuthorListResponse {
  const factory AuthorListResponse({
    required List<Author> authors,   // 작가 목록
    required int total,              // 전체 작가 수
    required int page,               // 현재 페이지
    required int limit,              // 페이지당 항목 수
    required bool hasNext,           // 다음 페이지 존재 여부
    required bool hasPrevious,       // 이전 페이지 존재 여부
  }) = _AuthorListResponse;

  /// JSON에서 AuthorListResponse 객체로 변환
  factory AuthorListResponse.fromJson(Map<String, dynamic> json) => _$AuthorListResponseFromJson(json);
}

/// 작가 검색 요청 모델
/// 
/// 작가 검색 시 서버로 전송하는 필터 조건들을 담습니다.
@freezed
class AuthorSearchRequest with _$AuthorSearchRequest {
  const factory AuthorSearchRequest({
    String? query,                   // 검색어 (작가명, 전문분야 등)
    List<String>? specialties,       // 전문분야 필터
    bool? verifiedOnly,              // 인증 작가만 검색
    String? sortBy,                  // 정렬 기준 (follower_count, total_articles 등)
    @Default('desc') String sortOrder, // 정렬 순서 (asc, desc)
    @Default(1) int page,            // 페이지 번호
    @Default(20) int limit,          // 페이지당 항목 수
  }) = _AuthorSearchRequest;

  /// JSON에서 AuthorSearchRequest 객체로 변환
  factory AuthorSearchRequest.fromJson(Map<String, dynamic> json) => _$AuthorSearchRequestFromJson(json);
}

/// 팔로우 상태 변경 이벤트
/// 
/// Provider에서 팔로우 상태 변경을 알리기 위한 이벤트 모델입니다.
@freezed
class FollowStatusChangeEvent with _$FollowStatusChangeEvent {
  const factory FollowStatusChangeEvent({
    required String authorId,        // 변경된 작가 ID
    required bool isFollowing,       // 새로운 팔로우 상태
    required int followerCount,      // 변경된 팔로워 수
    required DateTime timestamp,     // 변경 시각
  }) = _FollowStatusChangeEvent;

  /// JSON에서 FollowStatusChangeEvent 객체로 변환
  factory FollowStatusChangeEvent.fromJson(Map<String, dynamic> json) => _$FollowStatusChangeEventFromJson(json);
}

/// 추천 작가 응답 모델
/// 
/// AI 추천 시스템에서 사용자에게 추천할 작가 목록을 반환합니다.
@freezed
class RecommendedAuthorsResponse with _$RecommendedAuthorsResponse {
  const factory RecommendedAuthorsResponse({
    required List<Author> authors,   // 추천 작가 목록
    required String reason,          // 추천 이유
    @Default(0.0) double confidence, // 추천 신뢰도 (0.0 ~ 1.0)
    String? algorithmVersion,        // 사용된 알고리즘 버전
  }) = _RecommendedAuthorsResponse;

  /// JSON에서 RecommendedAuthorsResponse 객체로 변환
  factory RecommendedAuthorsResponse.fromJson(Map<String, dynamic> json) => _$RecommendedAuthorsResponseFromJson(json);
}