/// Paperly Mobile App - 팔로우 상태 관리 Provider
/// 
/// 이 파일은 앱의 모든 팔로우 관련 상태를 관리합니다.
/// 작가 팔로우/언팔로우, 팔로우 목록, 작가 정보 등을 중앙에서 관리합니다.
/// 
/// 주요 기능:
/// - 팔로우/언팔로우 상태 관리
/// - 팔로우한 작가 목록 관리
/// - 작가 정보 캐싱 및 동기화
/// - UI 상태 알림 및 로딩 관리
/// - 에러 처리 및 사용자 피드백
/// 
/// 기술적 특징:
/// - ChangeNotifier를 통한 반응형 상태 관리
/// - 로컬 상태와 서버 상태 동기화
/// - 낙관적 업데이트로 빠른 UI 반응
/// - 에러 시 롤백 기능

import 'package:flutter/foundation.dart';
import '../models/author_models.dart';
import '../services/follow_service.dart';
import '../utils/logger.dart';

/// 팔로우 상태 관리 Provider
/// 
/// 작가 팔로우 관련 모든 상태와 로직을 중앙에서 관리합니다.
/// UI 컴포넌트들은 이 Provider를 통해 일관된 상태를 유지합니다.
class FollowProvider with ChangeNotifier {
  
  // ============================================================================
  // 🔧 의존성 및 설정
  // ============================================================================
  
  final FollowService _followService;
  final logger = loggerInstance;
  
  // ============================================================================
  // 📊 상태 변수들
  // ============================================================================
  
  // 팔로우한 작가 목록
  List<Author> _followingAuthors = [];
  
  // 트렌딩 작가 목록
  List<Author> _trendingAuthors = [];
  
  // 추천 작가 정보
  RecommendedAuthorsResponse? _recommendedAuthors;
  
  // 작가 상세 정보 캐시 (작가 ID -> Author)
  final Map<String, Author> _authorCache = {};
  
  // 팔로우 상태 캐시 (작가 ID -> 팔로우 여부)
  final Map<String, bool> _followStatusCache = {};
  
  // 로딩 상태들
  bool _isLoadingFollowing = false;
  bool _isLoadingTrending = false;
  bool _isLoadingRecommended = false;
  final Map<String, bool> _isFollowingInProgress = {};
  
  // 에러 상태
  String? _error;
  
  // 페이지네이션 상태
  int _currentPage = 1;
  bool _hasMoreFollowing = true;
  
  /// 생성자: FollowService 주입
  FollowProvider({required FollowService followService}) 
      : _followService = followService;

  // ============================================================================
  // 📖 Getter 메서드들 (UI에서 상태 접근용)
  // ============================================================================
  
  /// 팔로우한 작가 목록
  List<Author> get followingAuthors => List.unmodifiable(_followingAuthors);
  
  /// 트렌딩 작가 목록
  List<Author> get trendingAuthors => List.unmodifiable(_trendingAuthors);
  
  /// 추천 작가 정보
  RecommendedAuthorsResponse? get recommendedAuthors => _recommendedAuthors;
  
  /// 팔로우 목록 로딩 상태
  bool get isLoadingFollowing => _isLoadingFollowing;
  
  /// 트렌딩 작가 로딩 상태
  bool get isLoadingTrending => _isLoadingTrending;
  
  /// 추천 작가 로딩 상태
  bool get isLoadingRecommended => _isLoadingRecommended;
  
  /// 에러 메시지
  String? get error => _error;
  
  /// 더 많은 팔로우 목록이 있는지 여부
  bool get hasMoreFollowing => _hasMoreFollowing;

  // ============================================================================
  // 👥 작가 정보 관련 메서드들
  // ============================================================================

  /// 작가 상세 정보 조회
  /// 
  /// 캐시를 우선 확인하고 없으면 API에서 가져옵니다.
  /// UI에서 작가 정보가 필요할 때 사용됩니다.
  /// 
  /// 매개변수:
  /// - authorId: 조회할 작가 ID
  /// - forceRefresh: 캐시 무시하고 새로 조회할지 여부
  /// 
  /// 반환값:
  /// - Author: 작가 정보 (팔로우 상태 포함)
  Future<Author?> getAuthorDetails(String authorId, {bool forceRefresh = false}) async {
    try {
      // 캐시 확인 (강제 새로고침이 아닌 경우)
      if (!forceRefresh && _authorCache.containsKey(authorId)) {
        return _authorCache[authorId];
      }
      
      final author = await _followService.getAuthorDetails(authorId);
      
      // 캐시에 저장
      _authorCache[authorId] = author;
      _followStatusCache[authorId] = author.isFollowing;
      
      logger.i('작가 정보 조회 완료: ${author.displayName}');
      return author;
    } catch (e) {
      logger.e('작가 정보 조회 실패: $authorId', error: e);
      _setError('작가 정보를 불러올 수 없습니다');
      return null;
    }
  }

  /// 트렌딩 작가 목록 로드
  /// 
  /// 현재 인기 있는 작가들을 가져와서 상태에 저장합니다.
  /// 홈 화면의 트렌딩 섹션에서 사용됩니다.
  /// 
  /// 매개변수:
  /// - limit: 가져올 작가 수 (기본값: 10)
  /// - forceRefresh: 캐시 무시하고 새로 조회할지 여부
  Future<void> loadTrendingAuthors({int limit = 10, bool forceRefresh = false}) async {
    if (_isLoadingTrending) return;
    
    try {
      _isLoadingTrending = true;
      _clearError();
      notifyListeners();
      
      final authors = await _followService.getTrendingAuthors(limit: limit);
      
      _trendingAuthors = authors;
      
      // 캐시 업데이트
      for (final author in authors) {
        _authorCache[author.id] = author;
        _followStatusCache[author.id] = author.isFollowing;
      }
      
      logger.i('트렌딩 작가 ${authors.length}명 로드 완료');
    } catch (e) {
      logger.e('트렌딩 작가 로드 실패', error: e);
      _setError('인기 작가 정보를 불러올 수 없습니다');
    } finally {
      _isLoadingTrending = false;
      notifyListeners();
    }
  }

  /// AI 추천 작가 로드
  /// 
  /// 사용자 맞춤형 추천 작가를 가져와서 상태에 저장합니다.
  /// 
  /// 매개변수:
  /// - limit: 추천받을 작가 수 (기본값: 5)
  Future<void> loadRecommendedAuthors({int limit = 5}) async {
    if (_isLoadingRecommended) return;
    
    try {
      _isLoadingRecommended = true;
      _clearError();
      notifyListeners();
      
      final recommendedResponse = await _followService.getRecommendedAuthors(limit: limit);
      
      _recommendedAuthors = recommendedResponse;
      
      // 캐시 업데이트
      for (final author in recommendedResponse.authors) {
        _authorCache[author.id] = author;
        _followStatusCache[author.id] = author.isFollowing;
      }
      
      logger.i('추천 작가 ${recommendedResponse.authors.length}명 로드 완료');
    } catch (e) {
      logger.e('추천 작가 로드 실패', error: e);
      _setError('추천 작가 정보를 불러올 수 없습니다');
    } finally {
      _isLoadingRecommended = false;
      notifyListeners();
    }
  }

  // ============================================================================
  // ❤️ 팔로우 관련 메서드들
  // ============================================================================

  /// 작가 팔로우
  /// 
  /// 특정 작가를 팔로우하고 상태를 업데이트합니다.
  /// 낙관적 업데이트로 UI가 즉시 반응하고, 실패 시 롤백됩니다.
  /// 
  /// 매개변수:
  /// - authorId: 팔로우할 작가 ID
  /// 
  /// 반환값:
  /// - bool: 성공 여부
  Future<bool> followAuthor(String authorId) async {
    if (_isFollowingInProgress[authorId] == true) return false;
    
    try {
      _isFollowingInProgress[authorId] = true;
      _clearError();
      
      // 낙관적 업데이트: UI를 먼저 업데이트
      _updateFollowStatusOptimistically(authorId, true);
      notifyListeners();
      
      final response = await _followService.followAuthor(authorId);
      
      // 서버 응답으로 정확한 상태 업데이트
      _updateFollowStatusFromResponse(authorId, response);
      
      logger.i('작가 팔로우 성공: $authorId');
      return true;
    } catch (e) {
      logger.e('작가 팔로우 실패: $authorId', error: e);
      
      // 롤백: 원래 상태로 되돌림
      _updateFollowStatusOptimistically(authorId, false);
      _setError('팔로우에 실패했습니다. 다시 시도해주세요.');
      
      return false;
    } finally {
      _isFollowingInProgress[authorId] = false;
      notifyListeners();
    }
  }

  /// 작가 언팔로우
  /// 
  /// 특정 작가를 언팔로우하고 상태를 업데이트합니다.
  /// 
  /// 매개변수:
  /// - authorId: 언팔로우할 작가 ID
  /// 
  /// 반환값:
  /// - bool: 성공 여부
  Future<bool> unfollowAuthor(String authorId) async {
    if (_isFollowingInProgress[authorId] == true) return false;
    
    try {
      _isFollowingInProgress[authorId] = true;
      _clearError();
      
      // 낙관적 업데이트
      _updateFollowStatusOptimistically(authorId, false);
      notifyListeners();
      
      final response = await _followService.unfollowAuthor(authorId);
      
      // 서버 응답으로 정확한 상태 업데이트
      _updateFollowStatusFromResponse(authorId, response);
      
      // 팔로우 목록에서 제거
      _followingAuthors.removeWhere((author) => author.id == authorId);
      
      logger.i('작가 언팔로우 성공: $authorId');
      return true;
    } catch (e) {
      logger.e('작가 언팔로우 실패: $authorId', error: e);
      
      // 롤백
      _updateFollowStatusOptimistically(authorId, true);
      _setError('언팔로우에 실패했습니다. 다시 시도해주세요.');
      
      return false;
    } finally {
      _isFollowingInProgress[authorId] = false;
      notifyListeners();
    }
  }

  /// 팔로우 상태 토글
  /// 
  /// 현재 팔로우 상태에 따라 팔로우/언팔로우를 수행합니다.
  /// UI에서 토글 버튼을 누를 때 사용됩니다.
  /// 
  /// 매개변수:
  /// - authorId: 대상 작가 ID
  /// 
  /// 반환값:
  /// - bool: 성공 여부
  Future<bool> toggleFollow(String authorId) async {
    final isCurrentlyFollowing = isFollowing(authorId);
    
    if (isCurrentlyFollowing) {
      return await unfollowAuthor(authorId);
    } else {
      return await followAuthor(authorId);
    }
  }

  /// 팔로우 상태 확인
  /// 
  /// 특정 작가에 대한 현재 팔로우 상태를 반환합니다.
  /// 캐시된 상태를 우선 확인하고 없으면 기본값을 반환합니다.
  /// 
  /// 매개변수:
  /// - authorId: 확인할 작가 ID
  /// 
  /// 반환값:
  /// - bool: 팔로우 중이면 true
  bool isFollowing(String authorId) {
    // 캐시된 상태 확인
    if (_followStatusCache.containsKey(authorId)) {
      return _followStatusCache[authorId]!;
    }
    
    // 작가 캐시에서 확인
    if (_authorCache.containsKey(authorId)) {
      return _authorCache[authorId]!.isFollowing;
    }
    
    // 팔로우 목록에서 확인
    return _followingAuthors.any((author) => author.id == authorId);
  }

  /// 팔로우 진행 중 상태 확인
  /// 
  /// 특정 작가에 대한 팔로우/언팔로우 작업이 진행 중인지 확인합니다.
  /// UI에서 로딩 상태를 표시할 때 사용됩니다.
  /// 
  /// 매개변수:
  /// - authorId: 확인할 작가 ID
  /// 
  /// 반환값:
  /// - bool: 진행 중이면 true
  bool isFollowingInProgress(String authorId) {
    return _isFollowingInProgress[authorId] ?? false;
  }

  // ============================================================================
  // 📋 팔로우 목록 관련 메서드들
  // ============================================================================

  /// 팔로우한 작가 목록 로드
  /// 
  /// 현재 사용자가 팔로우한 모든 작가를 가져옵니다.
  /// 페이지네이션을 지원하여 효율적으로 로드합니다.
  /// 
  /// 매개변수:
  /// - refresh: 목록을 새로고침할지 여부 (기본값: false)
  Future<void> loadFollowingAuthors({bool refresh = false}) async {
    if (_isLoadingFollowing) return;
    
    try {
      _isLoadingFollowing = true;
      _clearError();
      
      if (refresh) {
        _currentPage = 1;
        _hasMoreFollowing = true;
        _followingAuthors.clear();
      }
      
      notifyListeners();
      
      final response = await _followService.getFollowingAuthors(
        page: _currentPage,
        limit: 20,
      );
      
      if (refresh) {
        _followingAuthors = response.authors;
      } else {
        _followingAuthors.addAll(response.authors);
      }
      
      _hasMoreFollowing = response.hasNext;
      if (_hasMoreFollowing) {
        _currentPage++;
      }
      
      // 캐시 업데이트
      for (final author in response.authors) {
        _authorCache[author.id] = author;
        _followStatusCache[author.id] = true; // 팔로우 목록이므로 모두 true
      }
      
      logger.i('팔로우 목록 ${response.authors.length}명 로드 완료 (페이지: ${_currentPage - 1})');
    } catch (e) {
      logger.e('팔로우 목록 로드 실패', error: e);
      _setError('팔로우 목록을 불러올 수 없습니다');
    } finally {
      _isLoadingFollowing = false;
      notifyListeners();
    }
  }

  /// 다음 페이지 팔로우 목록 로드
  /// 
  /// 무한 스크롤이나 "더보기" 버튼을 위한 메서드입니다.
  Future<void> loadMoreFollowingAuthors() async {
    if (!_hasMoreFollowing || _isLoadingFollowing) return;
    
    await loadFollowingAuthors(refresh: false);
  }

  // ============================================================================
  // 🔄 상태 업데이트 헬퍼 메서드들
  // ============================================================================

  /// 낙관적 팔로우 상태 업데이트
  /// 
  /// API 호출 전에 UI를 먼저 업데이트하여 즉각적인 피드백을 제공합니다.
  void _updateFollowStatusOptimistically(String authorId, bool isFollowing) {
    _followStatusCache[authorId] = isFollowing;
    
    // 작가 캐시 업데이트
    if (_authorCache.containsKey(authorId)) {
      final author = _authorCache[authorId]!;
      final updatedStats = author.stats?.copyWith(
        followerCount: isFollowing 
            ? (author.stats?.followerCount ?? 0) + 1
            : (author.stats?.followerCount ?? 1) - 1,
      );
      
      _authorCache[authorId] = author.copyWith(
        isFollowing: isFollowing,
        stats: updatedStats,
      );
    }
    
    // 트렌딩 목록 업데이트
    _updateAuthorInList(_trendingAuthors, authorId, isFollowing);
    
    // 추천 목록 업데이트
    if (_recommendedAuthors != null) {
      _updateAuthorInList(_recommendedAuthors!.authors, authorId, isFollowing);
    }
  }

  /// 서버 응답으로 정확한 상태 업데이트
  void _updateFollowStatusFromResponse(String authorId, FollowResponse response) {
    _followStatusCache[authorId] = response.isFollowing;
    
    if (_authorCache.containsKey(authorId)) {
      final author = _authorCache[authorId]!;
      final updatedStats = author.stats?.copyWith(
        followerCount: response.followerCount,
      );
      
      _authorCache[authorId] = author.copyWith(
        isFollowing: response.isFollowing,
        stats: updatedStats,
      );
    }
    
    // 모든 목록 업데이트
    _updateAuthorInList(_trendingAuthors, authorId, response.isFollowing);
    if (_recommendedAuthors != null) {
      _updateAuthorInList(_recommendedAuthors!.authors, authorId, response.isFollowing);
    }
  }

  /// 목록 내 작가 정보 업데이트
  void _updateAuthorInList(List<Author> authorList, String authorId, bool isFollowing) {
    final index = authorList.indexWhere((author) => author.id == authorId);
    if (index != -1) {
      final author = authorList[index];
      final updatedAuthor = author.copyWith(isFollowing: isFollowing);
      authorList[index] = updatedAuthor;
    }
  }

  // ============================================================================
  // 🚨 에러 처리 관련 메서드들
  // ============================================================================

  /// 에러 상태 설정
  void _setError(String message) {
    _error = message;
    logger.e('FollowProvider 에러: $message');
  }

  /// 에러 상태 초기화
  void _clearError() {
    _error = null;
  }

  /// 에러 상태 수동 초기화 (UI에서 호출)
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // ============================================================================
  // 🗃️ 캐시 및 초기화 관련 메서드들
  // ============================================================================

  /// 모든 상태 초기화
  /// 
  /// 로그아웃이나 계정 변경 시 호출됩니다.
  void reset() {
    _followingAuthors.clear();
    _trendingAuthors.clear();
    _recommendedAuthors = null;
    _authorCache.clear();
    _followStatusCache.clear();
    _isFollowingInProgress.clear();
    _isLoadingFollowing = false;
    _isLoadingTrending = false;
    _isLoadingRecommended = false;
    _error = null;
    _currentPage = 1;
    _hasMoreFollowing = true;
    
    _followService.clearCache();
    
    notifyListeners();
    logger.i('FollowProvider 상태 초기화 완료');
  }

  /// 캐시 새로고침
  /// 
  /// 데이터가 오래되었을 때 강제로 새로고침합니다.
  Future<void> refreshAll() async {
    _followService.clearCache();
    
    await Future.wait([
      loadFollowingAuthors(refresh: true),
      loadTrendingAuthors(forceRefresh: true),
      loadRecommendedAuthors(),
    ]);
  }

  @override
  void dispose() {
    _followService.clearCache();
    super.dispose();
  }
}