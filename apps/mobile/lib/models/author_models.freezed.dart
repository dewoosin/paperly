// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'author_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Author {
  String get id => throw _privateConstructorUsedError; // 작가 고유 ID
  String get name => throw _privateConstructorUsedError; // 작가 이름
  String get displayName => throw _privateConstructorUsedError; // 표시용 이름 (필명)
  String? get bio => throw _privateConstructorUsedError; // 자기소개
  String? get profileImageUrl =>
      throw _privateConstructorUsedError; // 프로필 이미지 URL
  List<String> get specialties => throw _privateConstructorUsedError; // 전문 분야
  int? get yearsOfExperience => throw _privateConstructorUsedError; // 경력 연수
  String? get education => throw _privateConstructorUsedError; // 학력
  List<String> get previousPublications =>
      throw _privateConstructorUsedError; // 이전 출간작
  List<String> get awards => throw _privateConstructorUsedError; // 수상 경력
  String? get websiteUrl => throw _privateConstructorUsedError; // 개인 웹사이트
  String? get twitterHandle => throw _privateConstructorUsedError; // 트위터 핸들
  String? get instagramHandle => throw _privateConstructorUsedError; // 인스타그램 핸들
  String? get linkedinUrl => throw _privateConstructorUsedError; // 링크드인 URL
  String? get contactEmail => throw _privateConstructorUsedError; // 연락처 이메일
  bool get isAvailableForCollaboration =>
      throw _privateConstructorUsedError; // 협업 가능 여부
  List<String> get preferredTopics =>
      throw _privateConstructorUsedError; // 선호 주제
  String? get writingSchedule => throw _privateConstructorUsedError; // 글 작성 일정
  bool get isVerified => throw _privateConstructorUsedError; // 인증 작가 여부
  DateTime? get verificationDate => throw _privateConstructorUsedError; // 인증 날짜
  String? get verificationNotes =>
      throw _privateConstructorUsedError; // 인증 참고사항
  AuthorStats? get stats => throw _privateConstructorUsedError; // 작가 통계
  bool get isFollowing => throw _privateConstructorUsedError; // 현재 사용자의 팔로우 여부
  DateTime? get createdAt => throw _privateConstructorUsedError; // 등록일
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Create a copy of Author
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuthorCopyWith<Author> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthorCopyWith<$Res> {
  factory $AuthorCopyWith(Author value, $Res Function(Author) then) =
      _$AuthorCopyWithImpl<$Res, Author>;
  @useResult
  $Res call({
    String id,
    String name,
    String displayName,
    String? bio,
    String? profileImageUrl,
    List<String> specialties,
    int? yearsOfExperience,
    String? education,
    List<String> previousPublications,
    List<String> awards,
    String? websiteUrl,
    String? twitterHandle,
    String? instagramHandle,
    String? linkedinUrl,
    String? contactEmail,
    bool isAvailableForCollaboration,
    List<String> preferredTopics,
    String? writingSchedule,
    bool isVerified,
    DateTime? verificationDate,
    String? verificationNotes,
    AuthorStats? stats,
    bool isFollowing,
    DateTime? createdAt,
    DateTime? updatedAt,
  });

  $AuthorStatsCopyWith<$Res>? get stats;
}

/// @nodoc
class _$AuthorCopyWithImpl<$Res, $Val extends Author>
    implements $AuthorCopyWith<$Res> {
  _$AuthorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Author
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? displayName = null,
    Object? bio = freezed,
    Object? profileImageUrl = freezed,
    Object? specialties = null,
    Object? yearsOfExperience = freezed,
    Object? education = freezed,
    Object? previousPublications = null,
    Object? awards = null,
    Object? websiteUrl = freezed,
    Object? twitterHandle = freezed,
    Object? instagramHandle = freezed,
    Object? linkedinUrl = freezed,
    Object? contactEmail = freezed,
    Object? isAvailableForCollaboration = null,
    Object? preferredTopics = null,
    Object? writingSchedule = freezed,
    Object? isVerified = null,
    Object? verificationDate = freezed,
    Object? verificationNotes = freezed,
    Object? stats = freezed,
    Object? isFollowing = null,
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
            displayName: null == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String,
            bio: freezed == bio
                ? _value.bio
                : bio // ignore: cast_nullable_to_non_nullable
                      as String?,
            profileImageUrl: freezed == profileImageUrl
                ? _value.profileImageUrl
                : profileImageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            specialties: null == specialties
                ? _value.specialties
                : specialties // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            yearsOfExperience: freezed == yearsOfExperience
                ? _value.yearsOfExperience
                : yearsOfExperience // ignore: cast_nullable_to_non_nullable
                      as int?,
            education: freezed == education
                ? _value.education
                : education // ignore: cast_nullable_to_non_nullable
                      as String?,
            previousPublications: null == previousPublications
                ? _value.previousPublications
                : previousPublications // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            awards: null == awards
                ? _value.awards
                : awards // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            websiteUrl: freezed == websiteUrl
                ? _value.websiteUrl
                : websiteUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            twitterHandle: freezed == twitterHandle
                ? _value.twitterHandle
                : twitterHandle // ignore: cast_nullable_to_non_nullable
                      as String?,
            instagramHandle: freezed == instagramHandle
                ? _value.instagramHandle
                : instagramHandle // ignore: cast_nullable_to_non_nullable
                      as String?,
            linkedinUrl: freezed == linkedinUrl
                ? _value.linkedinUrl
                : linkedinUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            contactEmail: freezed == contactEmail
                ? _value.contactEmail
                : contactEmail // ignore: cast_nullable_to_non_nullable
                      as String?,
            isAvailableForCollaboration: null == isAvailableForCollaboration
                ? _value.isAvailableForCollaboration
                : isAvailableForCollaboration // ignore: cast_nullable_to_non_nullable
                      as bool,
            preferredTopics: null == preferredTopics
                ? _value.preferredTopics
                : preferredTopics // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            writingSchedule: freezed == writingSchedule
                ? _value.writingSchedule
                : writingSchedule // ignore: cast_nullable_to_non_nullable
                      as String?,
            isVerified: null == isVerified
                ? _value.isVerified
                : isVerified // ignore: cast_nullable_to_non_nullable
                      as bool,
            verificationDate: freezed == verificationDate
                ? _value.verificationDate
                : verificationDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            verificationNotes: freezed == verificationNotes
                ? _value.verificationNotes
                : verificationNotes // ignore: cast_nullable_to_non_nullable
                      as String?,
            stats: freezed == stats
                ? _value.stats
                : stats // ignore: cast_nullable_to_non_nullable
                      as AuthorStats?,
            isFollowing: null == isFollowing
                ? _value.isFollowing
                : isFollowing // ignore: cast_nullable_to_non_nullable
                      as bool,
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

  /// Create a copy of Author
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AuthorStatsCopyWith<$Res>? get stats {
    if (_value.stats == null) {
      return null;
    }

    return $AuthorStatsCopyWith<$Res>(_value.stats!, (value) {
      return _then(_value.copyWith(stats: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AuthorImplCopyWith<$Res> implements $AuthorCopyWith<$Res> {
  factory _$$AuthorImplCopyWith(
    _$AuthorImpl value,
    $Res Function(_$AuthorImpl) then,
  ) = __$$AuthorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String displayName,
    String? bio,
    String? profileImageUrl,
    List<String> specialties,
    int? yearsOfExperience,
    String? education,
    List<String> previousPublications,
    List<String> awards,
    String? websiteUrl,
    String? twitterHandle,
    String? instagramHandle,
    String? linkedinUrl,
    String? contactEmail,
    bool isAvailableForCollaboration,
    List<String> preferredTopics,
    String? writingSchedule,
    bool isVerified,
    DateTime? verificationDate,
    String? verificationNotes,
    AuthorStats? stats,
    bool isFollowing,
    DateTime? createdAt,
    DateTime? updatedAt,
  });

  @override
  $AuthorStatsCopyWith<$Res>? get stats;
}

/// @nodoc
class __$$AuthorImplCopyWithImpl<$Res>
    extends _$AuthorCopyWithImpl<$Res, _$AuthorImpl>
    implements _$$AuthorImplCopyWith<$Res> {
  __$$AuthorImplCopyWithImpl(
    _$AuthorImpl _value,
    $Res Function(_$AuthorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Author
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? displayName = null,
    Object? bio = freezed,
    Object? profileImageUrl = freezed,
    Object? specialties = null,
    Object? yearsOfExperience = freezed,
    Object? education = freezed,
    Object? previousPublications = null,
    Object? awards = null,
    Object? websiteUrl = freezed,
    Object? twitterHandle = freezed,
    Object? instagramHandle = freezed,
    Object? linkedinUrl = freezed,
    Object? contactEmail = freezed,
    Object? isAvailableForCollaboration = null,
    Object? preferredTopics = null,
    Object? writingSchedule = freezed,
    Object? isVerified = null,
    Object? verificationDate = freezed,
    Object? verificationNotes = freezed,
    Object? stats = freezed,
    Object? isFollowing = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$AuthorImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: null == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        bio: freezed == bio
            ? _value.bio
            : bio // ignore: cast_nullable_to_non_nullable
                  as String?,
        profileImageUrl: freezed == profileImageUrl
            ? _value.profileImageUrl
            : profileImageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        specialties: null == specialties
            ? _value._specialties
            : specialties // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        yearsOfExperience: freezed == yearsOfExperience
            ? _value.yearsOfExperience
            : yearsOfExperience // ignore: cast_nullable_to_non_nullable
                  as int?,
        education: freezed == education
            ? _value.education
            : education // ignore: cast_nullable_to_non_nullable
                  as String?,
        previousPublications: null == previousPublications
            ? _value._previousPublications
            : previousPublications // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        awards: null == awards
            ? _value._awards
            : awards // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        websiteUrl: freezed == websiteUrl
            ? _value.websiteUrl
            : websiteUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        twitterHandle: freezed == twitterHandle
            ? _value.twitterHandle
            : twitterHandle // ignore: cast_nullable_to_non_nullable
                  as String?,
        instagramHandle: freezed == instagramHandle
            ? _value.instagramHandle
            : instagramHandle // ignore: cast_nullable_to_non_nullable
                  as String?,
        linkedinUrl: freezed == linkedinUrl
            ? _value.linkedinUrl
            : linkedinUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        contactEmail: freezed == contactEmail
            ? _value.contactEmail
            : contactEmail // ignore: cast_nullable_to_non_nullable
                  as String?,
        isAvailableForCollaboration: null == isAvailableForCollaboration
            ? _value.isAvailableForCollaboration
            : isAvailableForCollaboration // ignore: cast_nullable_to_non_nullable
                  as bool,
        preferredTopics: null == preferredTopics
            ? _value._preferredTopics
            : preferredTopics // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        writingSchedule: freezed == writingSchedule
            ? _value.writingSchedule
            : writingSchedule // ignore: cast_nullable_to_non_nullable
                  as String?,
        isVerified: null == isVerified
            ? _value.isVerified
            : isVerified // ignore: cast_nullable_to_non_nullable
                  as bool,
        verificationDate: freezed == verificationDate
            ? _value.verificationDate
            : verificationDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        verificationNotes: freezed == verificationNotes
            ? _value.verificationNotes
            : verificationNotes // ignore: cast_nullable_to_non_nullable
                  as String?,
        stats: freezed == stats
            ? _value.stats
            : stats // ignore: cast_nullable_to_non_nullable
                  as AuthorStats?,
        isFollowing: null == isFollowing
            ? _value.isFollowing
            : isFollowing // ignore: cast_nullable_to_non_nullable
                  as bool,
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

class _$AuthorImpl extends _Author {
  const _$AuthorImpl({
    required this.id,
    required this.name,
    required this.displayName,
    this.bio,
    this.profileImageUrl,
    final List<String> specialties = const [],
    this.yearsOfExperience,
    this.education,
    final List<String> previousPublications = const [],
    final List<String> awards = const [],
    this.websiteUrl,
    this.twitterHandle,
    this.instagramHandle,
    this.linkedinUrl,
    this.contactEmail,
    this.isAvailableForCollaboration = true,
    final List<String> preferredTopics = const [],
    this.writingSchedule,
    this.isVerified = false,
    this.verificationDate,
    this.verificationNotes,
    this.stats,
    this.isFollowing = false,
    this.createdAt,
    this.updatedAt,
  }) : _specialties = specialties,
       _previousPublications = previousPublications,
       _awards = awards,
       _preferredTopics = preferredTopics,
       super._();

  @override
  final String id;
  // 작가 고유 ID
  @override
  final String name;
  // 작가 이름
  @override
  final String displayName;
  // 표시용 이름 (필명)
  @override
  final String? bio;
  // 자기소개
  @override
  final String? profileImageUrl;
  // 프로필 이미지 URL
  final List<String> _specialties;
  // 프로필 이미지 URL
  @override
  @JsonKey()
  List<String> get specialties {
    if (_specialties is EqualUnmodifiableListView) return _specialties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_specialties);
  }

  // 전문 분야
  @override
  final int? yearsOfExperience;
  // 경력 연수
  @override
  final String? education;
  // 학력
  final List<String> _previousPublications;
  // 학력
  @override
  @JsonKey()
  List<String> get previousPublications {
    if (_previousPublications is EqualUnmodifiableListView)
      return _previousPublications;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_previousPublications);
  }

  // 이전 출간작
  final List<String> _awards;
  // 이전 출간작
  @override
  @JsonKey()
  List<String> get awards {
    if (_awards is EqualUnmodifiableListView) return _awards;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_awards);
  }

  // 수상 경력
  @override
  final String? websiteUrl;
  // 개인 웹사이트
  @override
  final String? twitterHandle;
  // 트위터 핸들
  @override
  final String? instagramHandle;
  // 인스타그램 핸들
  @override
  final String? linkedinUrl;
  // 링크드인 URL
  @override
  final String? contactEmail;
  // 연락처 이메일
  @override
  @JsonKey()
  final bool isAvailableForCollaboration;
  // 협업 가능 여부
  final List<String> _preferredTopics;
  // 협업 가능 여부
  @override
  @JsonKey()
  List<String> get preferredTopics {
    if (_preferredTopics is EqualUnmodifiableListView) return _preferredTopics;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_preferredTopics);
  }

  // 선호 주제
  @override
  final String? writingSchedule;
  // 글 작성 일정
  @override
  @JsonKey()
  final bool isVerified;
  // 인증 작가 여부
  @override
  final DateTime? verificationDate;
  // 인증 날짜
  @override
  final String? verificationNotes;
  // 인증 참고사항
  @override
  final AuthorStats? stats;
  // 작가 통계
  @override
  @JsonKey()
  final bool isFollowing;
  // 현재 사용자의 팔로우 여부
  @override
  final DateTime? createdAt;
  // 등록일
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Author(id: $id, name: $name, displayName: $displayName, bio: $bio, profileImageUrl: $profileImageUrl, specialties: $specialties, yearsOfExperience: $yearsOfExperience, education: $education, previousPublications: $previousPublications, awards: $awards, websiteUrl: $websiteUrl, twitterHandle: $twitterHandle, instagramHandle: $instagramHandle, linkedinUrl: $linkedinUrl, contactEmail: $contactEmail, isAvailableForCollaboration: $isAvailableForCollaboration, preferredTopics: $preferredTopics, writingSchedule: $writingSchedule, isVerified: $isVerified, verificationDate: $verificationDate, verificationNotes: $verificationNotes, stats: $stats, isFollowing: $isFollowing, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthorImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            (identical(other.profileImageUrl, profileImageUrl) ||
                other.profileImageUrl == profileImageUrl) &&
            const DeepCollectionEquality().equals(
              other._specialties,
              _specialties,
            ) &&
            (identical(other.yearsOfExperience, yearsOfExperience) ||
                other.yearsOfExperience == yearsOfExperience) &&
            (identical(other.education, education) ||
                other.education == education) &&
            const DeepCollectionEquality().equals(
              other._previousPublications,
              _previousPublications,
            ) &&
            const DeepCollectionEquality().equals(other._awards, _awards) &&
            (identical(other.websiteUrl, websiteUrl) ||
                other.websiteUrl == websiteUrl) &&
            (identical(other.twitterHandle, twitterHandle) ||
                other.twitterHandle == twitterHandle) &&
            (identical(other.instagramHandle, instagramHandle) ||
                other.instagramHandle == instagramHandle) &&
            (identical(other.linkedinUrl, linkedinUrl) ||
                other.linkedinUrl == linkedinUrl) &&
            (identical(other.contactEmail, contactEmail) ||
                other.contactEmail == contactEmail) &&
            (identical(
                  other.isAvailableForCollaboration,
                  isAvailableForCollaboration,
                ) ||
                other.isAvailableForCollaboration ==
                    isAvailableForCollaboration) &&
            const DeepCollectionEquality().equals(
              other._preferredTopics,
              _preferredTopics,
            ) &&
            (identical(other.writingSchedule, writingSchedule) ||
                other.writingSchedule == writingSchedule) &&
            (identical(other.isVerified, isVerified) ||
                other.isVerified == isVerified) &&
            (identical(other.verificationDate, verificationDate) ||
                other.verificationDate == verificationDate) &&
            (identical(other.verificationNotes, verificationNotes) ||
                other.verificationNotes == verificationNotes) &&
            (identical(other.stats, stats) || other.stats == stats) &&
            (identical(other.isFollowing, isFollowing) ||
                other.isFollowing == isFollowing) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    name,
    displayName,
    bio,
    profileImageUrl,
    const DeepCollectionEquality().hash(_specialties),
    yearsOfExperience,
    education,
    const DeepCollectionEquality().hash(_previousPublications),
    const DeepCollectionEquality().hash(_awards),
    websiteUrl,
    twitterHandle,
    instagramHandle,
    linkedinUrl,
    contactEmail,
    isAvailableForCollaboration,
    const DeepCollectionEquality().hash(_preferredTopics),
    writingSchedule,
    isVerified,
    verificationDate,
    verificationNotes,
    stats,
    isFollowing,
    createdAt,
    updatedAt,
  ]);

  /// Create a copy of Author
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthorImplCopyWith<_$AuthorImpl> get copyWith =>
      __$$AuthorImplCopyWithImpl<_$AuthorImpl>(this, _$identity);
}

abstract class _Author extends Author {
  const factory _Author({
    required final String id,
    required final String name,
    required final String displayName,
    final String? bio,
    final String? profileImageUrl,
    final List<String> specialties,
    final int? yearsOfExperience,
    final String? education,
    final List<String> previousPublications,
    final List<String> awards,
    final String? websiteUrl,
    final String? twitterHandle,
    final String? instagramHandle,
    final String? linkedinUrl,
    final String? contactEmail,
    final bool isAvailableForCollaboration,
    final List<String> preferredTopics,
    final String? writingSchedule,
    final bool isVerified,
    final DateTime? verificationDate,
    final String? verificationNotes,
    final AuthorStats? stats,
    final bool isFollowing,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _$AuthorImpl;
  const _Author._() : super._();

  @override
  String get id; // 작가 고유 ID
  @override
  String get name; // 작가 이름
  @override
  String get displayName; // 표시용 이름 (필명)
  @override
  String? get bio; // 자기소개
  @override
  String? get profileImageUrl; // 프로필 이미지 URL
  @override
  List<String> get specialties; // 전문 분야
  @override
  int? get yearsOfExperience; // 경력 연수
  @override
  String? get education; // 학력
  @override
  List<String> get previousPublications; // 이전 출간작
  @override
  List<String> get awards; // 수상 경력
  @override
  String? get websiteUrl; // 개인 웹사이트
  @override
  String? get twitterHandle; // 트위터 핸들
  @override
  String? get instagramHandle; // 인스타그램 핸들
  @override
  String? get linkedinUrl; // 링크드인 URL
  @override
  String? get contactEmail; // 연락처 이메일
  @override
  bool get isAvailableForCollaboration; // 협업 가능 여부
  @override
  List<String> get preferredTopics; // 선호 주제
  @override
  String? get writingSchedule; // 글 작성 일정
  @override
  bool get isVerified; // 인증 작가 여부
  @override
  DateTime? get verificationDate; // 인증 날짜
  @override
  String? get verificationNotes; // 인증 참고사항
  @override
  AuthorStats? get stats; // 작가 통계
  @override
  bool get isFollowing; // 현재 사용자의 팔로우 여부
  @override
  DateTime? get createdAt; // 등록일
  @override
  DateTime? get updatedAt;

  /// Create a copy of Author
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthorImplCopyWith<_$AuthorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AuthorStats _$AuthorStatsFromJson(Map<String, dynamic> json) {
  return _AuthorStats.fromJson(json);
}

/// @nodoc
mixin _$AuthorStats {
  int get totalArticles => throw _privateConstructorUsedError; // 총 글 수
  int get publishedArticles => throw _privateConstructorUsedError; // 발행된 글 수
  int get totalViews => throw _privateConstructorUsedError; // 총 조회수
  int get totalLikes => throw _privateConstructorUsedError; // 총 좋아요 수
  int get totalShares => throw _privateConstructorUsedError; // 총 공유 수
  int get totalComments => throw _privateConstructorUsedError; // 총 댓글 수
  double get averageRating => throw _privateConstructorUsedError; // 평균 평점
  int get followerCount => throw _privateConstructorUsedError; // 팔로워 수
  int get followingCount => throw _privateConstructorUsedError; // 팔로잉 수
  DateTime? get lastActiveAt => throw _privateConstructorUsedError; // 마지막 활동 시간
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this AuthorStats to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AuthorStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuthorStatsCopyWith<AuthorStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthorStatsCopyWith<$Res> {
  factory $AuthorStatsCopyWith(
    AuthorStats value,
    $Res Function(AuthorStats) then,
  ) = _$AuthorStatsCopyWithImpl<$Res, AuthorStats>;
  @useResult
  $Res call({
    int totalArticles,
    int publishedArticles,
    int totalViews,
    int totalLikes,
    int totalShares,
    int totalComments,
    double averageRating,
    int followerCount,
    int followingCount,
    DateTime? lastActiveAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$AuthorStatsCopyWithImpl<$Res, $Val extends AuthorStats>
    implements $AuthorStatsCopyWith<$Res> {
  _$AuthorStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthorStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalArticles = null,
    Object? publishedArticles = null,
    Object? totalViews = null,
    Object? totalLikes = null,
    Object? totalShares = null,
    Object? totalComments = null,
    Object? averageRating = null,
    Object? followerCount = null,
    Object? followingCount = null,
    Object? lastActiveAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            totalArticles: null == totalArticles
                ? _value.totalArticles
                : totalArticles // ignore: cast_nullable_to_non_nullable
                      as int,
            publishedArticles: null == publishedArticles
                ? _value.publishedArticles
                : publishedArticles // ignore: cast_nullable_to_non_nullable
                      as int,
            totalViews: null == totalViews
                ? _value.totalViews
                : totalViews // ignore: cast_nullable_to_non_nullable
                      as int,
            totalLikes: null == totalLikes
                ? _value.totalLikes
                : totalLikes // ignore: cast_nullable_to_non_nullable
                      as int,
            totalShares: null == totalShares
                ? _value.totalShares
                : totalShares // ignore: cast_nullable_to_non_nullable
                      as int,
            totalComments: null == totalComments
                ? _value.totalComments
                : totalComments // ignore: cast_nullable_to_non_nullable
                      as int,
            averageRating: null == averageRating
                ? _value.averageRating
                : averageRating // ignore: cast_nullable_to_non_nullable
                      as double,
            followerCount: null == followerCount
                ? _value.followerCount
                : followerCount // ignore: cast_nullable_to_non_nullable
                      as int,
            followingCount: null == followingCount
                ? _value.followingCount
                : followingCount // ignore: cast_nullable_to_non_nullable
                      as int,
            lastActiveAt: freezed == lastActiveAt
                ? _value.lastActiveAt
                : lastActiveAt // ignore: cast_nullable_to_non_nullable
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
abstract class _$$AuthorStatsImplCopyWith<$Res>
    implements $AuthorStatsCopyWith<$Res> {
  factory _$$AuthorStatsImplCopyWith(
    _$AuthorStatsImpl value,
    $Res Function(_$AuthorStatsImpl) then,
  ) = __$$AuthorStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int totalArticles,
    int publishedArticles,
    int totalViews,
    int totalLikes,
    int totalShares,
    int totalComments,
    double averageRating,
    int followerCount,
    int followingCount,
    DateTime? lastActiveAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$AuthorStatsImplCopyWithImpl<$Res>
    extends _$AuthorStatsCopyWithImpl<$Res, _$AuthorStatsImpl>
    implements _$$AuthorStatsImplCopyWith<$Res> {
  __$$AuthorStatsImplCopyWithImpl(
    _$AuthorStatsImpl _value,
    $Res Function(_$AuthorStatsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthorStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalArticles = null,
    Object? publishedArticles = null,
    Object? totalViews = null,
    Object? totalLikes = null,
    Object? totalShares = null,
    Object? totalComments = null,
    Object? averageRating = null,
    Object? followerCount = null,
    Object? followingCount = null,
    Object? lastActiveAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$AuthorStatsImpl(
        totalArticles: null == totalArticles
            ? _value.totalArticles
            : totalArticles // ignore: cast_nullable_to_non_nullable
                  as int,
        publishedArticles: null == publishedArticles
            ? _value.publishedArticles
            : publishedArticles // ignore: cast_nullable_to_non_nullable
                  as int,
        totalViews: null == totalViews
            ? _value.totalViews
            : totalViews // ignore: cast_nullable_to_non_nullable
                  as int,
        totalLikes: null == totalLikes
            ? _value.totalLikes
            : totalLikes // ignore: cast_nullable_to_non_nullable
                  as int,
        totalShares: null == totalShares
            ? _value.totalShares
            : totalShares // ignore: cast_nullable_to_non_nullable
                  as int,
        totalComments: null == totalComments
            ? _value.totalComments
            : totalComments // ignore: cast_nullable_to_non_nullable
                  as int,
        averageRating: null == averageRating
            ? _value.averageRating
            : averageRating // ignore: cast_nullable_to_non_nullable
                  as double,
        followerCount: null == followerCount
            ? _value.followerCount
            : followerCount // ignore: cast_nullable_to_non_nullable
                  as int,
        followingCount: null == followingCount
            ? _value.followingCount
            : followingCount // ignore: cast_nullable_to_non_nullable
                  as int,
        lastActiveAt: freezed == lastActiveAt
            ? _value.lastActiveAt
            : lastActiveAt // ignore: cast_nullable_to_non_nullable
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
class _$AuthorStatsImpl implements _AuthorStats {
  const _$AuthorStatsImpl({
    this.totalArticles = 0,
    this.publishedArticles = 0,
    this.totalViews = 0,
    this.totalLikes = 0,
    this.totalShares = 0,
    this.totalComments = 0,
    this.averageRating = 0.0,
    this.followerCount = 0,
    this.followingCount = 0,
    this.lastActiveAt,
    this.updatedAt,
  });

  factory _$AuthorStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuthorStatsImplFromJson(json);

  @override
  @JsonKey()
  final int totalArticles;
  // 총 글 수
  @override
  @JsonKey()
  final int publishedArticles;
  // 발행된 글 수
  @override
  @JsonKey()
  final int totalViews;
  // 총 조회수
  @override
  @JsonKey()
  final int totalLikes;
  // 총 좋아요 수
  @override
  @JsonKey()
  final int totalShares;
  // 총 공유 수
  @override
  @JsonKey()
  final int totalComments;
  // 총 댓글 수
  @override
  @JsonKey()
  final double averageRating;
  // 평균 평점
  @override
  @JsonKey()
  final int followerCount;
  // 팔로워 수
  @override
  @JsonKey()
  final int followingCount;
  // 팔로잉 수
  @override
  final DateTime? lastActiveAt;
  // 마지막 활동 시간
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'AuthorStats(totalArticles: $totalArticles, publishedArticles: $publishedArticles, totalViews: $totalViews, totalLikes: $totalLikes, totalShares: $totalShares, totalComments: $totalComments, averageRating: $averageRating, followerCount: $followerCount, followingCount: $followingCount, lastActiveAt: $lastActiveAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthorStatsImpl &&
            (identical(other.totalArticles, totalArticles) ||
                other.totalArticles == totalArticles) &&
            (identical(other.publishedArticles, publishedArticles) ||
                other.publishedArticles == publishedArticles) &&
            (identical(other.totalViews, totalViews) ||
                other.totalViews == totalViews) &&
            (identical(other.totalLikes, totalLikes) ||
                other.totalLikes == totalLikes) &&
            (identical(other.totalShares, totalShares) ||
                other.totalShares == totalShares) &&
            (identical(other.totalComments, totalComments) ||
                other.totalComments == totalComments) &&
            (identical(other.averageRating, averageRating) ||
                other.averageRating == averageRating) &&
            (identical(other.followerCount, followerCount) ||
                other.followerCount == followerCount) &&
            (identical(other.followingCount, followingCount) ||
                other.followingCount == followingCount) &&
            (identical(other.lastActiveAt, lastActiveAt) ||
                other.lastActiveAt == lastActiveAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    totalArticles,
    publishedArticles,
    totalViews,
    totalLikes,
    totalShares,
    totalComments,
    averageRating,
    followerCount,
    followingCount,
    lastActiveAt,
    updatedAt,
  );

  /// Create a copy of AuthorStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthorStatsImplCopyWith<_$AuthorStatsImpl> get copyWith =>
      __$$AuthorStatsImplCopyWithImpl<_$AuthorStatsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AuthorStatsImplToJson(this);
  }
}

abstract class _AuthorStats implements AuthorStats {
  const factory _AuthorStats({
    final int totalArticles,
    final int publishedArticles,
    final int totalViews,
    final int totalLikes,
    final int totalShares,
    final int totalComments,
    final double averageRating,
    final int followerCount,
    final int followingCount,
    final DateTime? lastActiveAt,
    final DateTime? updatedAt,
  }) = _$AuthorStatsImpl;

  factory _AuthorStats.fromJson(Map<String, dynamic> json) =
      _$AuthorStatsImpl.fromJson;

  @override
  int get totalArticles; // 총 글 수
  @override
  int get publishedArticles; // 발행된 글 수
  @override
  int get totalViews; // 총 조회수
  @override
  int get totalLikes; // 총 좋아요 수
  @override
  int get totalShares; // 총 공유 수
  @override
  int get totalComments; // 총 댓글 수
  @override
  double get averageRating; // 평균 평점
  @override
  int get followerCount; // 팔로워 수
  @override
  int get followingCount; // 팔로잉 수
  @override
  DateTime? get lastActiveAt; // 마지막 활동 시간
  @override
  DateTime? get updatedAt;

  /// Create a copy of AuthorStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthorStatsImplCopyWith<_$AuthorStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FollowRequest _$FollowRequestFromJson(Map<String, dynamic> json) {
  return _FollowRequest.fromJson(json);
}

/// @nodoc
mixin _$FollowRequest {
  String get authorId => throw _privateConstructorUsedError; // 팔로우할 작가 ID
  bool get follow => throw _privateConstructorUsedError;

  /// Serializes this FollowRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FollowRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FollowRequestCopyWith<FollowRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FollowRequestCopyWith<$Res> {
  factory $FollowRequestCopyWith(
    FollowRequest value,
    $Res Function(FollowRequest) then,
  ) = _$FollowRequestCopyWithImpl<$Res, FollowRequest>;
  @useResult
  $Res call({String authorId, bool follow});
}

/// @nodoc
class _$FollowRequestCopyWithImpl<$Res, $Val extends FollowRequest>
    implements $FollowRequestCopyWith<$Res> {
  _$FollowRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FollowRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? authorId = null, Object? follow = null}) {
    return _then(
      _value.copyWith(
            authorId: null == authorId
                ? _value.authorId
                : authorId // ignore: cast_nullable_to_non_nullable
                      as String,
            follow: null == follow
                ? _value.follow
                : follow // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FollowRequestImplCopyWith<$Res>
    implements $FollowRequestCopyWith<$Res> {
  factory _$$FollowRequestImplCopyWith(
    _$FollowRequestImpl value,
    $Res Function(_$FollowRequestImpl) then,
  ) = __$$FollowRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String authorId, bool follow});
}

/// @nodoc
class __$$FollowRequestImplCopyWithImpl<$Res>
    extends _$FollowRequestCopyWithImpl<$Res, _$FollowRequestImpl>
    implements _$$FollowRequestImplCopyWith<$Res> {
  __$$FollowRequestImplCopyWithImpl(
    _$FollowRequestImpl _value,
    $Res Function(_$FollowRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FollowRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? authorId = null, Object? follow = null}) {
    return _then(
      _$FollowRequestImpl(
        authorId: null == authorId
            ? _value.authorId
            : authorId // ignore: cast_nullable_to_non_nullable
                  as String,
        follow: null == follow
            ? _value.follow
            : follow // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FollowRequestImpl implements _FollowRequest {
  const _$FollowRequestImpl({required this.authorId, this.follow = true});

  factory _$FollowRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$FollowRequestImplFromJson(json);

  @override
  final String authorId;
  // 팔로우할 작가 ID
  @override
  @JsonKey()
  final bool follow;

  @override
  String toString() {
    return 'FollowRequest(authorId: $authorId, follow: $follow)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FollowRequestImpl &&
            (identical(other.authorId, authorId) ||
                other.authorId == authorId) &&
            (identical(other.follow, follow) || other.follow == follow));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, authorId, follow);

  /// Create a copy of FollowRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FollowRequestImplCopyWith<_$FollowRequestImpl> get copyWith =>
      __$$FollowRequestImplCopyWithImpl<_$FollowRequestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FollowRequestImplToJson(this);
  }
}

abstract class _FollowRequest implements FollowRequest {
  const factory _FollowRequest({
    required final String authorId,
    final bool follow,
  }) = _$FollowRequestImpl;

  factory _FollowRequest.fromJson(Map<String, dynamic> json) =
      _$FollowRequestImpl.fromJson;

  @override
  String get authorId; // 팔로우할 작가 ID
  @override
  bool get follow;

  /// Create a copy of FollowRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FollowRequestImplCopyWith<_$FollowRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FollowResponse _$FollowResponseFromJson(Map<String, dynamic> json) {
  return _FollowResponse.fromJson(json);
}

/// @nodoc
mixin _$FollowResponse {
  String get authorId => throw _privateConstructorUsedError; // 작가 ID
  bool get isFollowing => throw _privateConstructorUsedError; // 현재 팔로우 상태
  int get followerCount => throw _privateConstructorUsedError; // 변경된 팔로워 수
  String? get message => throw _privateConstructorUsedError;

  /// Serializes this FollowResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FollowResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FollowResponseCopyWith<FollowResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FollowResponseCopyWith<$Res> {
  factory $FollowResponseCopyWith(
    FollowResponse value,
    $Res Function(FollowResponse) then,
  ) = _$FollowResponseCopyWithImpl<$Res, FollowResponse>;
  @useResult
  $Res call({
    String authorId,
    bool isFollowing,
    int followerCount,
    String? message,
  });
}

/// @nodoc
class _$FollowResponseCopyWithImpl<$Res, $Val extends FollowResponse>
    implements $FollowResponseCopyWith<$Res> {
  _$FollowResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FollowResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? authorId = null,
    Object? isFollowing = null,
    Object? followerCount = null,
    Object? message = freezed,
  }) {
    return _then(
      _value.copyWith(
            authorId: null == authorId
                ? _value.authorId
                : authorId // ignore: cast_nullable_to_non_nullable
                      as String,
            isFollowing: null == isFollowing
                ? _value.isFollowing
                : isFollowing // ignore: cast_nullable_to_non_nullable
                      as bool,
            followerCount: null == followerCount
                ? _value.followerCount
                : followerCount // ignore: cast_nullable_to_non_nullable
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
abstract class _$$FollowResponseImplCopyWith<$Res>
    implements $FollowResponseCopyWith<$Res> {
  factory _$$FollowResponseImplCopyWith(
    _$FollowResponseImpl value,
    $Res Function(_$FollowResponseImpl) then,
  ) = __$$FollowResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String authorId,
    bool isFollowing,
    int followerCount,
    String? message,
  });
}

/// @nodoc
class __$$FollowResponseImplCopyWithImpl<$Res>
    extends _$FollowResponseCopyWithImpl<$Res, _$FollowResponseImpl>
    implements _$$FollowResponseImplCopyWith<$Res> {
  __$$FollowResponseImplCopyWithImpl(
    _$FollowResponseImpl _value,
    $Res Function(_$FollowResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FollowResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? authorId = null,
    Object? isFollowing = null,
    Object? followerCount = null,
    Object? message = freezed,
  }) {
    return _then(
      _$FollowResponseImpl(
        authorId: null == authorId
            ? _value.authorId
            : authorId // ignore: cast_nullable_to_non_nullable
                  as String,
        isFollowing: null == isFollowing
            ? _value.isFollowing
            : isFollowing // ignore: cast_nullable_to_non_nullable
                  as bool,
        followerCount: null == followerCount
            ? _value.followerCount
            : followerCount // ignore: cast_nullable_to_non_nullable
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
class _$FollowResponseImpl implements _FollowResponse {
  const _$FollowResponseImpl({
    required this.authorId,
    required this.isFollowing,
    required this.followerCount,
    this.message,
  });

  factory _$FollowResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$FollowResponseImplFromJson(json);

  @override
  final String authorId;
  // 작가 ID
  @override
  final bool isFollowing;
  // 현재 팔로우 상태
  @override
  final int followerCount;
  // 변경된 팔로워 수
  @override
  final String? message;

  @override
  String toString() {
    return 'FollowResponse(authorId: $authorId, isFollowing: $isFollowing, followerCount: $followerCount, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FollowResponseImpl &&
            (identical(other.authorId, authorId) ||
                other.authorId == authorId) &&
            (identical(other.isFollowing, isFollowing) ||
                other.isFollowing == isFollowing) &&
            (identical(other.followerCount, followerCount) ||
                other.followerCount == followerCount) &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, authorId, isFollowing, followerCount, message);

  /// Create a copy of FollowResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FollowResponseImplCopyWith<_$FollowResponseImpl> get copyWith =>
      __$$FollowResponseImplCopyWithImpl<_$FollowResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$FollowResponseImplToJson(this);
  }
}

abstract class _FollowResponse implements FollowResponse {
  const factory _FollowResponse({
    required final String authorId,
    required final bool isFollowing,
    required final int followerCount,
    final String? message,
  }) = _$FollowResponseImpl;

  factory _FollowResponse.fromJson(Map<String, dynamic> json) =
      _$FollowResponseImpl.fromJson;

  @override
  String get authorId; // 작가 ID
  @override
  bool get isFollowing; // 현재 팔로우 상태
  @override
  int get followerCount; // 변경된 팔로워 수
  @override
  String? get message;

  /// Create a copy of FollowResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FollowResponseImplCopyWith<_$FollowResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AuthorListResponse _$AuthorListResponseFromJson(Map<String, dynamic> json) {
  return _AuthorListResponse.fromJson(json);
}

/// @nodoc
mixin _$AuthorListResponse {
  List<Author> get authors => throw _privateConstructorUsedError; // 작가 목록
  int get total => throw _privateConstructorUsedError; // 전체 작가 수
  int get page => throw _privateConstructorUsedError; // 현재 페이지
  int get limit => throw _privateConstructorUsedError; // 페이지당 항목 수
  bool get hasNext => throw _privateConstructorUsedError; // 다음 페이지 존재 여부
  bool get hasPrevious => throw _privateConstructorUsedError;

  /// Serializes this AuthorListResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AuthorListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuthorListResponseCopyWith<AuthorListResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthorListResponseCopyWith<$Res> {
  factory $AuthorListResponseCopyWith(
    AuthorListResponse value,
    $Res Function(AuthorListResponse) then,
  ) = _$AuthorListResponseCopyWithImpl<$Res, AuthorListResponse>;
  @useResult
  $Res call({
    List<Author> authors,
    int total,
    int page,
    int limit,
    bool hasNext,
    bool hasPrevious,
  });
}

/// @nodoc
class _$AuthorListResponseCopyWithImpl<$Res, $Val extends AuthorListResponse>
    implements $AuthorListResponseCopyWith<$Res> {
  _$AuthorListResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthorListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? authors = null,
    Object? total = null,
    Object? page = null,
    Object? limit = null,
    Object? hasNext = null,
    Object? hasPrevious = null,
  }) {
    return _then(
      _value.copyWith(
            authors: null == authors
                ? _value.authors
                : authors // ignore: cast_nullable_to_non_nullable
                      as List<Author>,
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
            hasNext: null == hasNext
                ? _value.hasNext
                : hasNext // ignore: cast_nullable_to_non_nullable
                      as bool,
            hasPrevious: null == hasPrevious
                ? _value.hasPrevious
                : hasPrevious // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AuthorListResponseImplCopyWith<$Res>
    implements $AuthorListResponseCopyWith<$Res> {
  factory _$$AuthorListResponseImplCopyWith(
    _$AuthorListResponseImpl value,
    $Res Function(_$AuthorListResponseImpl) then,
  ) = __$$AuthorListResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<Author> authors,
    int total,
    int page,
    int limit,
    bool hasNext,
    bool hasPrevious,
  });
}

/// @nodoc
class __$$AuthorListResponseImplCopyWithImpl<$Res>
    extends _$AuthorListResponseCopyWithImpl<$Res, _$AuthorListResponseImpl>
    implements _$$AuthorListResponseImplCopyWith<$Res> {
  __$$AuthorListResponseImplCopyWithImpl(
    _$AuthorListResponseImpl _value,
    $Res Function(_$AuthorListResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthorListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? authors = null,
    Object? total = null,
    Object? page = null,
    Object? limit = null,
    Object? hasNext = null,
    Object? hasPrevious = null,
  }) {
    return _then(
      _$AuthorListResponseImpl(
        authors: null == authors
            ? _value._authors
            : authors // ignore: cast_nullable_to_non_nullable
                  as List<Author>,
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
        hasNext: null == hasNext
            ? _value.hasNext
            : hasNext // ignore: cast_nullable_to_non_nullable
                  as bool,
        hasPrevious: null == hasPrevious
            ? _value.hasPrevious
            : hasPrevious // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AuthorListResponseImpl implements _AuthorListResponse {
  const _$AuthorListResponseImpl({
    required final List<Author> authors,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasNext,
    required this.hasPrevious,
  }) : _authors = authors;

  factory _$AuthorListResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuthorListResponseImplFromJson(json);

  final List<Author> _authors;
  @override
  List<Author> get authors {
    if (_authors is EqualUnmodifiableListView) return _authors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_authors);
  }

  // 작가 목록
  @override
  final int total;
  // 전체 작가 수
  @override
  final int page;
  // 현재 페이지
  @override
  final int limit;
  // 페이지당 항목 수
  @override
  final bool hasNext;
  // 다음 페이지 존재 여부
  @override
  final bool hasPrevious;

  @override
  String toString() {
    return 'AuthorListResponse(authors: $authors, total: $total, page: $page, limit: $limit, hasNext: $hasNext, hasPrevious: $hasPrevious)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthorListResponseImpl &&
            const DeepCollectionEquality().equals(other._authors, _authors) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.limit, limit) || other.limit == limit) &&
            (identical(other.hasNext, hasNext) || other.hasNext == hasNext) &&
            (identical(other.hasPrevious, hasPrevious) ||
                other.hasPrevious == hasPrevious));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_authors),
    total,
    page,
    limit,
    hasNext,
    hasPrevious,
  );

  /// Create a copy of AuthorListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthorListResponseImplCopyWith<_$AuthorListResponseImpl> get copyWith =>
      __$$AuthorListResponseImplCopyWithImpl<_$AuthorListResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AuthorListResponseImplToJson(this);
  }
}

abstract class _AuthorListResponse implements AuthorListResponse {
  const factory _AuthorListResponse({
    required final List<Author> authors,
    required final int total,
    required final int page,
    required final int limit,
    required final bool hasNext,
    required final bool hasPrevious,
  }) = _$AuthorListResponseImpl;

  factory _AuthorListResponse.fromJson(Map<String, dynamic> json) =
      _$AuthorListResponseImpl.fromJson;

  @override
  List<Author> get authors; // 작가 목록
  @override
  int get total; // 전체 작가 수
  @override
  int get page; // 현재 페이지
  @override
  int get limit; // 페이지당 항목 수
  @override
  bool get hasNext; // 다음 페이지 존재 여부
  @override
  bool get hasPrevious;

  /// Create a copy of AuthorListResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthorListResponseImplCopyWith<_$AuthorListResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AuthorSearchRequest _$AuthorSearchRequestFromJson(Map<String, dynamic> json) {
  return _AuthorSearchRequest.fromJson(json);
}

/// @nodoc
mixin _$AuthorSearchRequest {
  String? get query => throw _privateConstructorUsedError; // 검색어 (작가명, 전문분야 등)
  List<String>? get specialties =>
      throw _privateConstructorUsedError; // 전문분야 필터
  bool? get verifiedOnly => throw _privateConstructorUsedError; // 인증 작가만 검색
  String? get sortBy =>
      throw _privateConstructorUsedError; // 정렬 기준 (follower_count, total_articles 등)
  String get sortOrder =>
      throw _privateConstructorUsedError; // 정렬 순서 (asc, desc)
  int get page => throw _privateConstructorUsedError; // 페이지 번호
  int get limit => throw _privateConstructorUsedError;

  /// Serializes this AuthorSearchRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AuthorSearchRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuthorSearchRequestCopyWith<AuthorSearchRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthorSearchRequestCopyWith<$Res> {
  factory $AuthorSearchRequestCopyWith(
    AuthorSearchRequest value,
    $Res Function(AuthorSearchRequest) then,
  ) = _$AuthorSearchRequestCopyWithImpl<$Res, AuthorSearchRequest>;
  @useResult
  $Res call({
    String? query,
    List<String>? specialties,
    bool? verifiedOnly,
    String? sortBy,
    String sortOrder,
    int page,
    int limit,
  });
}

/// @nodoc
class _$AuthorSearchRequestCopyWithImpl<$Res, $Val extends AuthorSearchRequest>
    implements $AuthorSearchRequestCopyWith<$Res> {
  _$AuthorSearchRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthorSearchRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? query = freezed,
    Object? specialties = freezed,
    Object? verifiedOnly = freezed,
    Object? sortBy = freezed,
    Object? sortOrder = null,
    Object? page = null,
    Object? limit = null,
  }) {
    return _then(
      _value.copyWith(
            query: freezed == query
                ? _value.query
                : query // ignore: cast_nullable_to_non_nullable
                      as String?,
            specialties: freezed == specialties
                ? _value.specialties
                : specialties // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            verifiedOnly: freezed == verifiedOnly
                ? _value.verifiedOnly
                : verifiedOnly // ignore: cast_nullable_to_non_nullable
                      as bool?,
            sortBy: freezed == sortBy
                ? _value.sortBy
                : sortBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            sortOrder: null == sortOrder
                ? _value.sortOrder
                : sortOrder // ignore: cast_nullable_to_non_nullable
                      as String,
            page: null == page
                ? _value.page
                : page // ignore: cast_nullable_to_non_nullable
                      as int,
            limit: null == limit
                ? _value.limit
                : limit // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AuthorSearchRequestImplCopyWith<$Res>
    implements $AuthorSearchRequestCopyWith<$Res> {
  factory _$$AuthorSearchRequestImplCopyWith(
    _$AuthorSearchRequestImpl value,
    $Res Function(_$AuthorSearchRequestImpl) then,
  ) = __$$AuthorSearchRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? query,
    List<String>? specialties,
    bool? verifiedOnly,
    String? sortBy,
    String sortOrder,
    int page,
    int limit,
  });
}

/// @nodoc
class __$$AuthorSearchRequestImplCopyWithImpl<$Res>
    extends _$AuthorSearchRequestCopyWithImpl<$Res, _$AuthorSearchRequestImpl>
    implements _$$AuthorSearchRequestImplCopyWith<$Res> {
  __$$AuthorSearchRequestImplCopyWithImpl(
    _$AuthorSearchRequestImpl _value,
    $Res Function(_$AuthorSearchRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthorSearchRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? query = freezed,
    Object? specialties = freezed,
    Object? verifiedOnly = freezed,
    Object? sortBy = freezed,
    Object? sortOrder = null,
    Object? page = null,
    Object? limit = null,
  }) {
    return _then(
      _$AuthorSearchRequestImpl(
        query: freezed == query
            ? _value.query
            : query // ignore: cast_nullable_to_non_nullable
                  as String?,
        specialties: freezed == specialties
            ? _value._specialties
            : specialties // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        verifiedOnly: freezed == verifiedOnly
            ? _value.verifiedOnly
            : verifiedOnly // ignore: cast_nullable_to_non_nullable
                  as bool?,
        sortBy: freezed == sortBy
            ? _value.sortBy
            : sortBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        sortOrder: null == sortOrder
            ? _value.sortOrder
            : sortOrder // ignore: cast_nullable_to_non_nullable
                  as String,
        page: null == page
            ? _value.page
            : page // ignore: cast_nullable_to_non_nullable
                  as int,
        limit: null == limit
            ? _value.limit
            : limit // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AuthorSearchRequestImpl implements _AuthorSearchRequest {
  const _$AuthorSearchRequestImpl({
    this.query,
    final List<String>? specialties,
    this.verifiedOnly,
    this.sortBy,
    this.sortOrder = 'desc',
    this.page = 1,
    this.limit = 20,
  }) : _specialties = specialties;

  factory _$AuthorSearchRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuthorSearchRequestImplFromJson(json);

  @override
  final String? query;
  // 검색어 (작가명, 전문분야 등)
  final List<String>? _specialties;
  // 검색어 (작가명, 전문분야 등)
  @override
  List<String>? get specialties {
    final value = _specialties;
    if (value == null) return null;
    if (_specialties is EqualUnmodifiableListView) return _specialties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  // 전문분야 필터
  @override
  final bool? verifiedOnly;
  // 인증 작가만 검색
  @override
  final String? sortBy;
  // 정렬 기준 (follower_count, total_articles 등)
  @override
  @JsonKey()
  final String sortOrder;
  // 정렬 순서 (asc, desc)
  @override
  @JsonKey()
  final int page;
  // 페이지 번호
  @override
  @JsonKey()
  final int limit;

  @override
  String toString() {
    return 'AuthorSearchRequest(query: $query, specialties: $specialties, verifiedOnly: $verifiedOnly, sortBy: $sortBy, sortOrder: $sortOrder, page: $page, limit: $limit)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthorSearchRequestImpl &&
            (identical(other.query, query) || other.query == query) &&
            const DeepCollectionEquality().equals(
              other._specialties,
              _specialties,
            ) &&
            (identical(other.verifiedOnly, verifiedOnly) ||
                other.verifiedOnly == verifiedOnly) &&
            (identical(other.sortBy, sortBy) || other.sortBy == sortBy) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.limit, limit) || other.limit == limit));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    query,
    const DeepCollectionEquality().hash(_specialties),
    verifiedOnly,
    sortBy,
    sortOrder,
    page,
    limit,
  );

  /// Create a copy of AuthorSearchRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthorSearchRequestImplCopyWith<_$AuthorSearchRequestImpl> get copyWith =>
      __$$AuthorSearchRequestImplCopyWithImpl<_$AuthorSearchRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AuthorSearchRequestImplToJson(this);
  }
}

abstract class _AuthorSearchRequest implements AuthorSearchRequest {
  const factory _AuthorSearchRequest({
    final String? query,
    final List<String>? specialties,
    final bool? verifiedOnly,
    final String? sortBy,
    final String sortOrder,
    final int page,
    final int limit,
  }) = _$AuthorSearchRequestImpl;

  factory _AuthorSearchRequest.fromJson(Map<String, dynamic> json) =
      _$AuthorSearchRequestImpl.fromJson;

  @override
  String? get query; // 검색어 (작가명, 전문분야 등)
  @override
  List<String>? get specialties; // 전문분야 필터
  @override
  bool? get verifiedOnly; // 인증 작가만 검색
  @override
  String? get sortBy; // 정렬 기준 (follower_count, total_articles 등)
  @override
  String get sortOrder; // 정렬 순서 (asc, desc)
  @override
  int get page; // 페이지 번호
  @override
  int get limit;

  /// Create a copy of AuthorSearchRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthorSearchRequestImplCopyWith<_$AuthorSearchRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FollowStatusChangeEvent _$FollowStatusChangeEventFromJson(
  Map<String, dynamic> json,
) {
  return _FollowStatusChangeEvent.fromJson(json);
}

/// @nodoc
mixin _$FollowStatusChangeEvent {
  String get authorId => throw _privateConstructorUsedError; // 변경된 작가 ID
  bool get isFollowing => throw _privateConstructorUsedError; // 새로운 팔로우 상태
  int get followerCount => throw _privateConstructorUsedError; // 변경된 팔로워 수
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Serializes this FollowStatusChangeEvent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FollowStatusChangeEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FollowStatusChangeEventCopyWith<FollowStatusChangeEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FollowStatusChangeEventCopyWith<$Res> {
  factory $FollowStatusChangeEventCopyWith(
    FollowStatusChangeEvent value,
    $Res Function(FollowStatusChangeEvent) then,
  ) = _$FollowStatusChangeEventCopyWithImpl<$Res, FollowStatusChangeEvent>;
  @useResult
  $Res call({
    String authorId,
    bool isFollowing,
    int followerCount,
    DateTime timestamp,
  });
}

/// @nodoc
class _$FollowStatusChangeEventCopyWithImpl<
  $Res,
  $Val extends FollowStatusChangeEvent
>
    implements $FollowStatusChangeEventCopyWith<$Res> {
  _$FollowStatusChangeEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FollowStatusChangeEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? authorId = null,
    Object? isFollowing = null,
    Object? followerCount = null,
    Object? timestamp = null,
  }) {
    return _then(
      _value.copyWith(
            authorId: null == authorId
                ? _value.authorId
                : authorId // ignore: cast_nullable_to_non_nullable
                      as String,
            isFollowing: null == isFollowing
                ? _value.isFollowing
                : isFollowing // ignore: cast_nullable_to_non_nullable
                      as bool,
            followerCount: null == followerCount
                ? _value.followerCount
                : followerCount // ignore: cast_nullable_to_non_nullable
                      as int,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FollowStatusChangeEventImplCopyWith<$Res>
    implements $FollowStatusChangeEventCopyWith<$Res> {
  factory _$$FollowStatusChangeEventImplCopyWith(
    _$FollowStatusChangeEventImpl value,
    $Res Function(_$FollowStatusChangeEventImpl) then,
  ) = __$$FollowStatusChangeEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String authorId,
    bool isFollowing,
    int followerCount,
    DateTime timestamp,
  });
}

/// @nodoc
class __$$FollowStatusChangeEventImplCopyWithImpl<$Res>
    extends
        _$FollowStatusChangeEventCopyWithImpl<
          $Res,
          _$FollowStatusChangeEventImpl
        >
    implements _$$FollowStatusChangeEventImplCopyWith<$Res> {
  __$$FollowStatusChangeEventImplCopyWithImpl(
    _$FollowStatusChangeEventImpl _value,
    $Res Function(_$FollowStatusChangeEventImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FollowStatusChangeEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? authorId = null,
    Object? isFollowing = null,
    Object? followerCount = null,
    Object? timestamp = null,
  }) {
    return _then(
      _$FollowStatusChangeEventImpl(
        authorId: null == authorId
            ? _value.authorId
            : authorId // ignore: cast_nullable_to_non_nullable
                  as String,
        isFollowing: null == isFollowing
            ? _value.isFollowing
            : isFollowing // ignore: cast_nullable_to_non_nullable
                  as bool,
        followerCount: null == followerCount
            ? _value.followerCount
            : followerCount // ignore: cast_nullable_to_non_nullable
                  as int,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FollowStatusChangeEventImpl implements _FollowStatusChangeEvent {
  const _$FollowStatusChangeEventImpl({
    required this.authorId,
    required this.isFollowing,
    required this.followerCount,
    required this.timestamp,
  });

  factory _$FollowStatusChangeEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$FollowStatusChangeEventImplFromJson(json);

  @override
  final String authorId;
  // 변경된 작가 ID
  @override
  final bool isFollowing;
  // 새로운 팔로우 상태
  @override
  final int followerCount;
  // 변경된 팔로워 수
  @override
  final DateTime timestamp;

  @override
  String toString() {
    return 'FollowStatusChangeEvent(authorId: $authorId, isFollowing: $isFollowing, followerCount: $followerCount, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FollowStatusChangeEventImpl &&
            (identical(other.authorId, authorId) ||
                other.authorId == authorId) &&
            (identical(other.isFollowing, isFollowing) ||
                other.isFollowing == isFollowing) &&
            (identical(other.followerCount, followerCount) ||
                other.followerCount == followerCount) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, authorId, isFollowing, followerCount, timestamp);

  /// Create a copy of FollowStatusChangeEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FollowStatusChangeEventImplCopyWith<_$FollowStatusChangeEventImpl>
  get copyWith =>
      __$$FollowStatusChangeEventImplCopyWithImpl<
        _$FollowStatusChangeEventImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FollowStatusChangeEventImplToJson(this);
  }
}

abstract class _FollowStatusChangeEvent implements FollowStatusChangeEvent {
  const factory _FollowStatusChangeEvent({
    required final String authorId,
    required final bool isFollowing,
    required final int followerCount,
    required final DateTime timestamp,
  }) = _$FollowStatusChangeEventImpl;

  factory _FollowStatusChangeEvent.fromJson(Map<String, dynamic> json) =
      _$FollowStatusChangeEventImpl.fromJson;

  @override
  String get authorId; // 변경된 작가 ID
  @override
  bool get isFollowing; // 새로운 팔로우 상태
  @override
  int get followerCount; // 변경된 팔로워 수
  @override
  DateTime get timestamp;

  /// Create a copy of FollowStatusChangeEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FollowStatusChangeEventImplCopyWith<_$FollowStatusChangeEventImpl>
  get copyWith => throw _privateConstructorUsedError;
}

RecommendedAuthorsResponse _$RecommendedAuthorsResponseFromJson(
  Map<String, dynamic> json,
) {
  return _RecommendedAuthorsResponse.fromJson(json);
}

/// @nodoc
mixin _$RecommendedAuthorsResponse {
  List<Author> get authors => throw _privateConstructorUsedError; // 추천 작가 목록
  String get reason => throw _privateConstructorUsedError; // 추천 이유
  double get confidence =>
      throw _privateConstructorUsedError; // 추천 신뢰도 (0.0 ~ 1.0)
  String? get algorithmVersion => throw _privateConstructorUsedError;

  /// Serializes this RecommendedAuthorsResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RecommendedAuthorsResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecommendedAuthorsResponseCopyWith<RecommendedAuthorsResponse>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecommendedAuthorsResponseCopyWith<$Res> {
  factory $RecommendedAuthorsResponseCopyWith(
    RecommendedAuthorsResponse value,
    $Res Function(RecommendedAuthorsResponse) then,
  ) =
      _$RecommendedAuthorsResponseCopyWithImpl<
        $Res,
        RecommendedAuthorsResponse
      >;
  @useResult
  $Res call({
    List<Author> authors,
    String reason,
    double confidence,
    String? algorithmVersion,
  });
}

/// @nodoc
class _$RecommendedAuthorsResponseCopyWithImpl<
  $Res,
  $Val extends RecommendedAuthorsResponse
>
    implements $RecommendedAuthorsResponseCopyWith<$Res> {
  _$RecommendedAuthorsResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RecommendedAuthorsResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? authors = null,
    Object? reason = null,
    Object? confidence = null,
    Object? algorithmVersion = freezed,
  }) {
    return _then(
      _value.copyWith(
            authors: null == authors
                ? _value.authors
                : authors // ignore: cast_nullable_to_non_nullable
                      as List<Author>,
            reason: null == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as String,
            confidence: null == confidence
                ? _value.confidence
                : confidence // ignore: cast_nullable_to_non_nullable
                      as double,
            algorithmVersion: freezed == algorithmVersion
                ? _value.algorithmVersion
                : algorithmVersion // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RecommendedAuthorsResponseImplCopyWith<$Res>
    implements $RecommendedAuthorsResponseCopyWith<$Res> {
  factory _$$RecommendedAuthorsResponseImplCopyWith(
    _$RecommendedAuthorsResponseImpl value,
    $Res Function(_$RecommendedAuthorsResponseImpl) then,
  ) = __$$RecommendedAuthorsResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<Author> authors,
    String reason,
    double confidence,
    String? algorithmVersion,
  });
}

/// @nodoc
class __$$RecommendedAuthorsResponseImplCopyWithImpl<$Res>
    extends
        _$RecommendedAuthorsResponseCopyWithImpl<
          $Res,
          _$RecommendedAuthorsResponseImpl
        >
    implements _$$RecommendedAuthorsResponseImplCopyWith<$Res> {
  __$$RecommendedAuthorsResponseImplCopyWithImpl(
    _$RecommendedAuthorsResponseImpl _value,
    $Res Function(_$RecommendedAuthorsResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RecommendedAuthorsResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? authors = null,
    Object? reason = null,
    Object? confidence = null,
    Object? algorithmVersion = freezed,
  }) {
    return _then(
      _$RecommendedAuthorsResponseImpl(
        authors: null == authors
            ? _value._authors
            : authors // ignore: cast_nullable_to_non_nullable
                  as List<Author>,
        reason: null == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String,
        confidence: null == confidence
            ? _value.confidence
            : confidence // ignore: cast_nullable_to_non_nullable
                  as double,
        algorithmVersion: freezed == algorithmVersion
            ? _value.algorithmVersion
            : algorithmVersion // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RecommendedAuthorsResponseImpl implements _RecommendedAuthorsResponse {
  const _$RecommendedAuthorsResponseImpl({
    required final List<Author> authors,
    required this.reason,
    this.confidence = 0.0,
    this.algorithmVersion,
  }) : _authors = authors;

  factory _$RecommendedAuthorsResponseImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$RecommendedAuthorsResponseImplFromJson(json);

  final List<Author> _authors;
  @override
  List<Author> get authors {
    if (_authors is EqualUnmodifiableListView) return _authors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_authors);
  }

  // 추천 작가 목록
  @override
  final String reason;
  // 추천 이유
  @override
  @JsonKey()
  final double confidence;
  // 추천 신뢰도 (0.0 ~ 1.0)
  @override
  final String? algorithmVersion;

  @override
  String toString() {
    return 'RecommendedAuthorsResponse(authors: $authors, reason: $reason, confidence: $confidence, algorithmVersion: $algorithmVersion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecommendedAuthorsResponseImpl &&
            const DeepCollectionEquality().equals(other._authors, _authors) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.algorithmVersion, algorithmVersion) ||
                other.algorithmVersion == algorithmVersion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_authors),
    reason,
    confidence,
    algorithmVersion,
  );

  /// Create a copy of RecommendedAuthorsResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecommendedAuthorsResponseImplCopyWith<_$RecommendedAuthorsResponseImpl>
  get copyWith =>
      __$$RecommendedAuthorsResponseImplCopyWithImpl<
        _$RecommendedAuthorsResponseImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecommendedAuthorsResponseImplToJson(this);
  }
}

abstract class _RecommendedAuthorsResponse
    implements RecommendedAuthorsResponse {
  const factory _RecommendedAuthorsResponse({
    required final List<Author> authors,
    required final String reason,
    final double confidence,
    final String? algorithmVersion,
  }) = _$RecommendedAuthorsResponseImpl;

  factory _RecommendedAuthorsResponse.fromJson(Map<String, dynamic> json) =
      _$RecommendedAuthorsResponseImpl.fromJson;

  @override
  List<Author> get authors; // 추천 작가 목록
  @override
  String get reason; // 추천 이유
  @override
  double get confidence; // 추천 신뢰도 (0.0 ~ 1.0)
  @override
  String? get algorithmVersion;

  /// Create a copy of RecommendedAuthorsResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecommendedAuthorsResponseImplCopyWith<_$RecommendedAuthorsResponseImpl>
  get copyWith => throw _privateConstructorUsedError;
}
