import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class AnalyticsProvider with ChangeNotifier {
  final ApiService _apiService;

  WriterStats? _stats;
  List<TrendingTopic> _trendingTopics = [];
  bool _isLoading = false;
  String? _error;
  String? _authToken;

  AnalyticsProvider({required ApiService apiService}) : _apiService = apiService;

  // Getters
  WriterStats? get stats => _stats;
  List<TrendingTopic> get trendingTopics => _trendingTopics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void updateAuthToken(String? token) {
    _authToken = token;
  }

  // 통계 로드
  Future<void> loadStats({bool refresh = false}) async {
    if (_authToken == null) return;

    try {
      if (refresh || _stats == null) {
        _isLoading = true;
        _error = null;
        notifyListeners();
      }

      final response = await _apiService.getWriterStats(_authToken!);
      _stats = WriterStats.fromJson(response);
      
      _error = null;
    } catch (e) {
      _error = '통계를 불러오는데 실패했습니다: $e';
      print('Load stats error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 트렌딩 주제 로드
  Future<void> loadTrendingTopics({bool refresh = false}) async {
    try {
      if (refresh || _trendingTopics.isEmpty) {
        _isLoading = true;
        _error = null;
        notifyListeners();
      }

      final response = await _apiService.getTrendingTopics();
      final List<dynamic> topicsJson = response['topics'] ?? [];
      _trendingTopics = topicsJson.map((json) => TrendingTopic.fromJson(json)).toList();
      
      _error = null;
    } catch (e) {
      _error = '트렌딩 주제를 불러오는데 실패했습니다: $e';
      print('Load trending topics error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 에러 클리어
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // 데이터 클리어
  void clearData() {
    _stats = null;
    _trendingTopics.clear();
    _error = null;
    notifyListeners();
  }
}

/// 작가 통계
class WriterStats {
  final int totalArticles;
  final int publishedArticles;
  final int draftArticles;
  final int totalViews;
  final int totalLikes;
  final int totalShares;
  final int totalComments;
  final double averageRating;
  final int followersCount;
  final List<MonthlyStats> monthlyStats;
  final Map<String, int> categoryStats;

  WriterStats({
    required this.totalArticles,
    required this.publishedArticles,
    required this.draftArticles,
    required this.totalViews,
    required this.totalLikes,
    required this.totalShares,
    required this.totalComments,
    required this.averageRating,
    required this.followersCount,
    required this.monthlyStats,
    required this.categoryStats,
  });

  factory WriterStats.fromJson(Map<String, dynamic> json) {
    return WriterStats(
      totalArticles: json['totalArticles'] ?? 0,
      publishedArticles: json['publishedArticles'] ?? 0,
      draftArticles: json['draftArticles'] ?? 0,
      totalViews: json['totalViews'] ?? 0,
      totalLikes: json['totalLikes'] ?? 0,
      totalShares: json['totalShares'] ?? 0,
      totalComments: json['totalComments'] ?? 0,
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      followersCount: json['followersCount'] ?? 0,
      monthlyStats: (json['monthlyStats'] as List? ?? [])
          .map((stat) => MonthlyStats.fromJson(stat))
          .toList(),
      categoryStats: Map<String, int>.from(json['categoryStats'] ?? {}),
    );
  }

  // 이번 달 조회수
  int get thisMonthViews {
    if (monthlyStats.isEmpty) return 0;
    return monthlyStats.last.views;
  }

  // 지난 달 대비 증가율
  double get viewGrowthRate {
    if (monthlyStats.length < 2) return 0.0;
    final thisMonth = monthlyStats.last.views;
    final lastMonth = monthlyStats[monthlyStats.length - 2].views;
    if (lastMonth == 0) return thisMonth > 0 ? 100.0 : 0.0;
    return ((thisMonth - lastMonth) / lastMonth) * 100;
  }

  // 평균 좋아요율
  double get averageLikeRate {
    if (totalViews == 0) return 0.0;
    return (totalLikes / totalViews) * 100;
  }

  // 가장 인기 있는 카테고리
  String? get topCategory {
    if (categoryStats.isEmpty) return null;
    return categoryStats.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}

/// 월별 통계
class MonthlyStats {
  final String month; // YYYY-MM 형식
  final int views;
  final int likes;
  final int shares;
  final int comments;
  final int articlesPublished;

  MonthlyStats({
    required this.month,
    required this.views,
    required this.likes,
    required this.shares,
    required this.comments,
    required this.articlesPublished,
  });

  factory MonthlyStats.fromJson(Map<String, dynamic> json) {
    return MonthlyStats(
      month: json['month'] ?? '',
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      shares: json['shares'] ?? 0,
      comments: json['comments'] ?? 0,
      articlesPublished: json['articlesPublished'] ?? 0,
    );
  }

  String get displayMonth {
    try {
      final parts = month.split('-');
      if (parts.length == 2) {
        final year = parts[0];
        final monthNum = int.parse(parts[1]);
        const monthNames = [
          '', '1월', '2월', '3월', '4월', '5월', '6월',
          '7월', '8월', '9월', '10월', '11월', '12월'
        ];
        return '${year}년 ${monthNames[monthNum]}';
      }
    } catch (e) {
      // 파싱 실패시 원본 반환
    }
    return month;
  }
}

/// 트렌딩 주제
class TrendingTopic {
  final String name;
  final String category;
  final int articleCount;
  final int totalViews;
  final double growthRate;
  final List<String> keywords;

  TrendingTopic({
    required this.name,
    required this.category,
    required this.articleCount,
    required this.totalViews,
    required this.growthRate,
    required this.keywords,
  });

  factory TrendingTopic.fromJson(Map<String, dynamic> json) {
    return TrendingTopic(
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      articleCount: json['articleCount'] ?? 0,
      totalViews: json['totalViews'] ?? 0,
      growthRate: (json['growthRate'] ?? 0).toDouble(),
      keywords: List<String>.from(json['keywords'] ?? []),
    );
  }

  String get displayGrowthRate {
    if (growthRate == 0) return '변화 없음';
    final sign = growthRate > 0 ? '+' : '';
    return '$sign${growthRate.toStringAsFixed(1)}%';
  }

  bool get isRising => growthRate > 0;
  bool get isHot => growthRate > 50;
}

/// 인기 키워드
class PopularKeyword {
  final String keyword;
  final int mentions;
  final double trendScore;

  PopularKeyword({
    required this.keyword,
    required this.mentions,
    required this.trendScore,
  });

  factory PopularKeyword.fromJson(Map<String, dynamic> json) {
    return PopularKeyword(
      keyword: json['keyword'] ?? '',
      mentions: json['mentions'] ?? 0,
      trendScore: (json['trendScore'] ?? 0).toDouble(),
    );
  }
}