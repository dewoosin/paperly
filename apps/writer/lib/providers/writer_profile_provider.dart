import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/writer_profile.dart';

class WriterProfileProvider with ChangeNotifier {
  final ApiService _apiService;

  WriterProfile? _profile;
  bool _isLoading = false;
  String? _error;
  String? _authToken;
  List<dynamic> _followers = [];
  bool _followersLoading = false;

  WriterProfileProvider({required ApiService apiService}) : _apiService = apiService;

  // Getters
  WriterProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasProfile => _profile != null;
  bool get isProfileComplete => _profile?.profileCompleted ?? false;
  List<dynamic> get followers => _followers;
  bool get followersLoading => _followersLoading;

  void updateAuthToken(String? token) {
    _authToken = token;
  }

  // 프로필 로드
  Future<void> loadProfile({bool refresh = false}) async {
    if (_authToken == null) return;

    try {
      if (refresh || _profile == null) {
        _isLoading = true;
        _error = null;
        notifyListeners();
      }

      final response = await _apiService.getWriterProfile(_authToken!);
      _profile = WriterProfile.fromJson(response);
      
      _error = null;
    } catch (e) {
      _error = '프로필을 불러오는데 실패했습니다: $e';
      print('Load profile error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 프로필 생성
  Future<WriterProfile?> createProfile(CreateWriterProfileRequest request) async {
    if (_authToken == null) return null;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.createWriterProfile(
        token: _authToken!,
        profileData: request.toJson(),
      );

      _profile = WriterProfile.fromJson(response['profile']);
      
      _error = null;
      notifyListeners();
      
      return _profile;
    } catch (e) {
      _error = '프로필 생성에 실패했습니다: $e';
      print('Create profile error: $e');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 프로필 수정
  Future<WriterProfile?> updateProfile(CreateWriterProfileRequest request) async {
    if (_authToken == null || _profile == null) return null;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.updateWriterProfile(
        token: _authToken!,
        profileId: _profile!.id,
        profileData: request.toJson(),
      );

      _profile = WriterProfile.fromJson(response['profile']);
      
      _error = null;
      notifyListeners();
      
      return _profile;
    } catch (e) {
      _error = '프로필 수정에 실패했습니다: $e';
      print('Update profile error: $e');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 프로필 이미지 업로드
  Future<String?> uploadProfileImage(String imagePath) async {
    if (_authToken == null) return null;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.uploadProfileImage(
        token: _authToken!,
        imagePath: imagePath,
      );

      final imageUrl = response['imageUrl'] ?? response['image_url'];
      
      // 프로필이 있으면 이미지 URL 업데이트
      if (_profile != null) {
        _profile = _profile!.copyWith(profileImageUrl: imageUrl);
      }
      
      _error = null;
      notifyListeners();
      
      return imageUrl;
    } catch (e) {
      _error = '프로필 이미지 업로드에 실패했습니다: $e';
      print('Upload profile image error: $e');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 프로필 완성도 확인
  double getCompletionPercentage() {
    return _profile?.completionPercentage ?? 0.0;
  }

  // 필수 필드 체크
  Map<String, bool> getRequiredFieldsStatus() {
    if (_profile == null) {
      return {
        'displayName': false,
        'bio': false,
        'specialties': false,
        'profileImage': false,
      };
    }

    return {
      'displayName': _profile!.displayName.isNotEmpty,
      'bio': _profile!.bio != null && _profile!.bio!.isNotEmpty,
      'specialties': _profile!.specialties.isNotEmpty,
      'profileImage': _profile!.profileImageUrl != null,
    };
  }

  // 프로필에서 누락된 필수 필드 목록
  List<String> getMissingRequiredFields() {
    final status = getRequiredFieldsStatus();
    final missing = <String>[];

    if (!status['displayName']!) missing.add('작가명');
    if (!status['bio']!) missing.add('자기소개');
    if (!status['specialties']!) missing.add('전문 분야');
    if (!status['profileImage']!) missing.add('프로필 사진');

    return missing;
  }

  // 에러 클리어
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // 팔로워 목록 로드
  Future<void> loadFollowers({bool refresh = false}) async {
    if (_authToken == null) return;

    try {
      if (refresh || _followers.isEmpty) {
        _followersLoading = true;
        notifyListeners();
      }

      // Mock 데이터 (실제 구현시 API 호출로 교체)
      await Future.delayed(const Duration(milliseconds: 800));
      
      _followers = [
        {
          'id': '1',
          'name': '김개발자',
          'profileImage': null,
          'followedAt': '2024-01-15',
          'lastActivity': '2024-01-20',
          'engagement': 'high'
        },
        {
          'id': '2', 
          'name': '박디자이너',
          'profileImage': null,
          'followedAt': '2024-01-18',
          'lastActivity': '2024-01-19',
          'engagement': 'medium'
        },
        {
          'id': '3',
          'name': '이기획자',
          'profileImage': null,
          'followedAt': '2024-01-20',
          'lastActivity': '2024-01-21',
          'engagement': 'high'
        },
      ];
      
      _error = null;
    } catch (e) {
      _error = '팔로워 목록을 불러오는데 실패했습니다: $e';
      print('Load followers error: $e');
    } finally {
      _followersLoading = false;
      notifyListeners();
    }
  }

  // 팔로워 통계 조회
  Map<String, dynamic> getFollowerStats() {
    final total = _followers.length;
    final activeFollowers = _followers.where((f) => 
      f['engagement'] == 'high' || f['engagement'] == 'medium'
    ).length;
    
    return {
      'total': total,
      'active': activeFollowers,
      'growth': total > 0 ? '+12%' : '0%',
      'engagement': total > 0 ? (activeFollowers / total * 100).round() : 0,
    };
  }

  // 데이터 클리어
  void clearData() {
    _profile = null;
    _followers.clear();
    _error = null;
    notifyListeners();
  }

  // 임시 프로필 생성 (빠른 시작용)
  WriterProfile createTemporaryProfile({
    required String displayName,
    String? bio,
    List<String>? specialties,
  }) {
    return WriterProfile(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      userId: 'temp-user',
      displayName: displayName,
      bio: bio,
      specialties: specialties ?? [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // 프로필 설정 단계별 검증
  bool validateStep1(String displayName, String? bio) {
    return displayName.trim().isNotEmpty && 
           displayName.trim().length >= 2 &&
           bio != null && 
           bio.trim().isNotEmpty && 
           bio.trim().length >= 10;
  }

  bool validateStep2(List<String> specialties, int yearsOfExperience) {
    return specialties.isNotEmpty && specialties.length <= 5;
  }

  bool validateStep3() {
    // 선택 사항이므로 항상 true
    return true;
  }

  // 프로필 통계 새로고침
  Future<void> refreshProfileStats() async {
    if (_authToken == null || _profile == null) return;

    try {
      final response = await _apiService.getWriterProfileStats(
        token: _authToken!,
        profileId: _profile!.id,
      );
      
      _profile = _profile!.copyWith(
        totalArticles: response['total_articles'] ?? response['totalArticles'] ?? 0,
        totalViews: response['total_views'] ?? response['totalViews'] ?? 0,
        totalLikes: response['total_likes'] ?? response['totalLikes'] ?? 0,
        followerCount: response['follower_count'] ?? response['followerCount'] ?? 0,
      );
      
      notifyListeners();
    } catch (e) {
      print('Refresh profile stats error: $e');
      // 통계 새로고침 실패는 사용자에게 알리지 않음 (중요하지 않은 작업)
    }
  }
}