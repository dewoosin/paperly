import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/article.dart';

class ArticleProvider with ChangeNotifier {
  final ApiService _apiService;

  List<Article> _myArticles = [];
  List<Article> _publishedArticles = [];
  bool _isLoading = false;
  String? _error;
  String? _authToken;

  ArticleProvider({required ApiService apiService}) : _apiService = apiService;

  // Getters
  List<Article> get myArticles => _myArticles;
  List<Article> get publishedArticles => _publishedArticles;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 초안 글들
  List<Article> get draftArticles => _myArticles
      .where((article) => article.status == ArticleStatus.draft)
      .toList();

  // 발행된 내 글들
  List<Article> get myPublishedArticles => _myArticles
      .where((article) => article.status == ArticleStatus.published)
      .toList();

  // 검토 중인 글들
  List<Article> get reviewArticles => _myArticles
      .where((article) => article.status == ArticleStatus.review)
      .toList();

  // 통계
  Map<String, int> get articleStats => {
    'total': _myArticles.length,
    'published': myPublishedArticles.length,
    'draft': draftArticles.length,
    'review': reviewArticles.length,
  };

  int get totalViews => _myArticles.fold(0, (sum, article) => sum + article.viewCount);
  int get totalLikes => _myArticles.fold(0, (sum, article) => sum + article.likeCount);
  int get totalShares => _myArticles.fold(0, (sum, article) => sum + article.shareCount);

  void updateAuthToken(String? token) {
    _authToken = token;
  }

  // 내 기사 목록 로드
  Future<void> loadMyArticles({bool refresh = false}) async {
    if (_authToken == null) return;

    try {
      if (refresh || _myArticles.isEmpty) {
        _isLoading = true;
        _error = null;
        notifyListeners();
      }

      final response = await _apiService.getMyArticles(token: _authToken!);
      
      final List<dynamic> articlesJson = response['articles'] ?? [];
      _myArticles = articlesJson.map((json) => Article.fromJson(json)).toList();
      
      _error = null;
    } catch (e) {
      _error = '내 기사를 불러오는데 실패했습니다: $e';
      print('Load my articles error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 발행된 기사 목록 로드
  Future<void> loadPublishedArticles({bool refresh = false}) async {
    try {
      if (refresh || _publishedArticles.isEmpty) {
        _isLoading = true;
        _error = null;
        notifyListeners();
      }

      final response = await _apiService.getArticles(
        token: _authToken,
        status: 'published',
      );
      
      final List<dynamic> articlesJson = response['articles'] ?? [];
      _publishedArticles = articlesJson.map((json) => Article.fromJson(json)).toList();
      
      _error = null;
    } catch (e) {
      _error = '발행된 기사를 불러오는데 실패했습니다: $e';
      print('Load published articles error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 새 기사 생성
  Future<Article?> createArticle(CreateArticleRequest request) async {
    if (_authToken == null) return null;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.createArticle(
        token: _authToken!,
        articleData: request.toJson(),
      );

      final newArticle = Article.fromJson(response['article']);
      _myArticles.insert(0, newArticle);
      
      _error = null;
      notifyListeners();
      
      return newArticle;
    } catch (e) {
      _error = '기사 생성에 실패했습니다: $e';
      print('Create article error: $e');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 기사 수정
  Future<Article?> updateArticle(String id, UpdateArticleRequest request) async {
    if (_authToken == null) return null;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.updateArticle(
        token: _authToken!,
        id: id,
        articleData: request.toJson(),
      );

      final updatedArticle = Article.fromJson(response['article']);
      
      // 로컬 목록에서 업데이트
      final index = _myArticles.indexWhere((article) => article.id == id);
      if (index != -1) {
        _myArticles[index] = updatedArticle;
      }
      
      _error = null;
      notifyListeners();
      
      return updatedArticle;
    } catch (e) {
      _error = '기사 수정에 실패했습니다: $e';
      print('Update article error: $e');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 기사 상태 변경
  Future<bool> updateArticleStatus(String id, ArticleStatus status) async {
    if (_authToken == null) return false;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final request = UpdateArticleRequest(status: status);
      final response = await _apiService.updateArticle(
        token: _authToken!,
        id: id,
        articleData: request.toJson(),
      );

      final updatedArticle = Article.fromJson(response['article']);
      
      // 로컬 목록에서 업데이트
      final index = _myArticles.indexWhere((article) => article.id == id);
      if (index != -1) {
        _myArticles[index] = updatedArticle;
      }
      
      _error = null;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = '기사 상태 변경에 실패했습니다: $e';
      print('Update article status error: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 기사 발행
  Future<bool> publishArticle(String id) async {
    if (_authToken == null) return false;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.publishArticle(
        token: _authToken!,
        id: id,
      );

      final updatedArticle = Article.fromJson(response['article']);
      
      // 로컬 목록에서 업데이트
      final index = _myArticles.indexWhere((article) => article.id == id);
      if (index != -1) {
        _myArticles[index] = updatedArticle;
      }
      
      _error = null;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = '기사 발행에 실패했습니다: $e';
      print('Publish article error: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 기사 발행 취소
  Future<bool> unpublishArticle(String id) async {
    if (_authToken == null) return false;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.unpublishArticle(
        token: _authToken!,
        id: id,
      );

      final updatedArticle = Article.fromJson(response['article']);
      
      // 로컬 목록에서 업데이트
      final index = _myArticles.indexWhere((article) => article.id == id);
      if (index != -1) {
        _myArticles[index] = updatedArticle;
      }
      
      _error = null;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = '기사 발행 취소에 실패했습니다: $e';
      print('Unpublish article error: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 기사 삭제
  Future<bool> deleteArticle(String id) async {
    if (_authToken == null) return false;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _apiService.deleteArticle(
        token: _authToken!,
        id: id,
      );

      // 로컬 목록에서 제거
      _myArticles.removeWhere((article) => article.id == id);
      
      _error = null;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = '기사 삭제에 실패했습니다: $e';
      print('Delete article error: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 기사 검색
  Future<List<Article>> searchArticles(String query) async {
    if (_authToken == null) return [];

    try {
      final response = await _apiService.getArticles(
        token: _authToken,
        search: query,
      );
      
      final List<dynamic> articlesJson = response['articles'] ?? [];
      return articlesJson.map((json) => Article.fromJson(json)).toList();
    } catch (e) {
      print('Search articles error: $e');
      return [];
    }
  }

  // 최근 기사들 (홈화면용)
  List<Article> getRecentArticles({int limit = 5}) {
    final sortedArticles = List<Article>.from(_myArticles);
    sortedArticles.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sortedArticles.take(limit).toList();
  }

  // 특정 기사 찾기
  Article? getArticleById(String id) {
    try {
      return _myArticles.firstWhere((article) => article.id == id);
    } catch (e) {
      return null;
    }
  }

  // 에러 클리어
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // 로컬 데이터 클리어
  void clearData() {
    _myArticles.clear();
    _publishedArticles.clear();
    _error = null;
    notifyListeners();
  }
}