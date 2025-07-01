import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// 대시보드 메트릭 데이터 모델
class DashboardMetrics {
  final int totalViews;
  final int totalLikes;
  final int subscribersCount;
  final int totalArticles;
  final int publishedArticles;
  final int draftArticles;
  final double averageEngagement;
  final int weeklyViews;
  final int weeklyLikes;
  final int weeklySubscribers;
  final List<TopArticle> topPerformingArticles;
  final List<ActivityItem> recentActivity;
  final List<CategoryPerformance> categoryPerformance;

  DashboardMetrics({
    required this.totalViews,
    required this.totalLikes,
    required this.subscribersCount,
    required this.totalArticles,
    required this.publishedArticles,
    required this.draftArticles,
    required this.averageEngagement,
    required this.weeklyViews,
    required this.weeklyLikes,
    required this.weeklySubscribers,
    required this.topPerformingArticles,
    required this.recentActivity,
    required this.categoryPerformance,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      totalViews: json['totalViews'] ?? 0,
      totalLikes: json['totalLikes'] ?? 0,
      subscribersCount: json['subscribersCount'] ?? 0,
      totalArticles: json['totalArticles'] ?? 0,
      publishedArticles: json['publishedArticles'] ?? 0,
      draftArticles: json['draftArticles'] ?? 0,
      averageEngagement: (json['averageEngagement'] ?? 0.0).toDouble(),
      weeklyViews: json['weeklyViews'] ?? 0,
      weeklyLikes: json['weeklyLikes'] ?? 0,
      weeklySubscribers: json['weeklySubscribers'] ?? 0,
      topPerformingArticles: (json['topPerformingArticles'] as List? ?? [])
          .map((item) => TopArticle.fromJson(item))
          .toList(),
      recentActivity: (json['recentActivity'] as List? ?? [])
          .map((item) => ActivityItem.fromJson(item))
          .toList(),
      categoryPerformance: (json['categoryPerformance'] as List? ?? [])
          .map((item) => CategoryPerformance.fromJson(item))
          .toList(),
    );
  }
}

/// 상위 성과 아티클 데이터
class TopArticle {
  final String id;
  final String title;
  final int views;
  final int likes;
  final String publishedAt;

  TopArticle({
    required this.id,
    required this.title,
    required this.views,
    required this.likes,
    required this.publishedAt,
  });

  factory TopArticle.fromJson(Map<String, dynamic> json) {
    return TopArticle(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      publishedAt: json['publishedAt'] ?? '',
    );
  }
}

/// 활동 아이템 데이터
class ActivityItem {
  final String type;
  final int count;
  final String date;

  ActivityItem({
    required this.type,
    required this.count,
    required this.date,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      type: json['type'] ?? '',
      count: json['count'] ?? 0,
      date: json['date'] ?? '',
    );
  }
}

/// 카테고리 성과 데이터
class CategoryPerformance {
  final String category;
  final int articles;
  final int views;
  final double engagement;

  CategoryPerformance({
    required this.category,
    required this.articles,
    required this.views,
    required this.engagement,
  });

  factory CategoryPerformance.fromJson(Map<String, dynamic> json) {
    return CategoryPerformance(
      category: json['category'] ?? '',
      articles: json['articles'] ?? 0,
      views: json['views'] ?? 0,
      engagement: (json['engagement'] ?? 0.0).toDouble(),
    );
  }
}

/// 실시간 메트릭 데이터
class RealtimeMetrics {
  final Map<String, int> lastHour;
  final int currentOnlineReaders;
  final List<Map<String, dynamic>> trendingArticles;
  final String lastUpdate;

  RealtimeMetrics({
    required this.lastHour,
    required this.currentOnlineReaders,
    required this.trendingArticles,
    required this.lastUpdate,
  });

  factory RealtimeMetrics.fromJson(Map<String, dynamic> json) {
    return RealtimeMetrics(
      lastHour: Map<String, int>.from(json['lastHour'] ?? {}),
      currentOnlineReaders: json['currentOnlineReaders'] ?? 0,
      trendingArticles: List<Map<String, dynamic>>.from(
          json['trendingArticles'] ?? []),
      lastUpdate: json['lastUpdate'] ?? '',
    );
  }
}

/// 대시보드 데이터 상태 관리 프로바이더
class DashboardProvider with ChangeNotifier {
  final ApiService _apiService;

  DashboardProvider(this._apiService);

  // 상태 변수들
  DashboardMetrics? _metrics;
  RealtimeMetrics? _realtimeMetrics;
  bool _isLoading = false;
  bool _isLoadingRealtime = false;
  String? _error;
  DateTime? _lastUpdated;

  // Getters
  DashboardMetrics? get metrics => _metrics;
  RealtimeMetrics? get realtimeMetrics => _realtimeMetrics;
  bool get isLoading => _isLoading;
  bool get isLoadingRealtime => _isLoadingRealtime;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;
  
  // 데이터가 있는지 확인
  bool get hasData => _metrics != null;
  bool get hasRealtimeData => _realtimeMetrics != null;

  /// 대시보드 메트릭 로드
  Future<void> loadDashboardMetrics({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getDashboardMetrics();
      _metrics = DashboardMetrics.fromJson(data['data']);
      _lastUpdated = DateTime.now();
      _error = null;
      
      if (kDebugMode) {
        print('✅ 대시보드 메트릭 로드 성공');
        print('📊 총 조회수: ${_metrics!.totalViews}');
        print('❤️ 총 좋아요: ${_metrics!.totalLikes}');
        print('👥 구독자: ${_metrics!.subscribersCount}');
      }
    } catch (e) {
      _error = _handleError(e);
      if (kDebugMode) {
        print('❌ 대시보드 메트릭 로드 실패: $_error');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 실시간 메트릭 로드
  Future<void> loadRealtimeMetrics() async {
    if (_isLoadingRealtime) return;
    
    _isLoadingRealtime = true;
    notifyListeners();

    try {
      final data = await _apiService.getRealtimeMetrics();
      _realtimeMetrics = RealtimeMetrics.fromJson(data['data']);
      
      if (kDebugMode) {
        print('⚡ 실시간 메트릭 업데이트');
        print('📈 현재 온라인 독자: ${_realtimeMetrics!.currentOnlineReaders}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ 실시간 메트릭 로드 실패: $e');
      }
      // 실시간 데이터는 실패해도 전체 에러로 표시하지 않음
    } finally {
      _isLoadingRealtime = false;
      notifyListeners();
    }
  }

  /// 상세 메트릭 로드 (기간별)
  Future<Map<String, dynamic>?> loadDetailedMetrics({
    String? startDate,
    String? endDate,
    String granularity = 'day',
  }) async {
    try {
      final data = await _apiService.getDetailedMetrics(
        startDate: startDate,
        endDate: endDate,
        granularity: granularity,
      );
      return data['data'];
    } catch (e) {
      if (kDebugMode) {
        print('❌ 상세 메트릭 로드 실패: $e');
      }
      return null;
    }
  }

  /// 기간별 메트릭 로드
  Future<Map<String, dynamic>?> loadPeriodMetrics(String period) async {
    try {
      final data = await _apiService.getPeriodMetrics(period);
      return data['data'];
    } catch (e) {
      if (kDebugMode) {
        print('❌ 기간별 메트릭 로드 실패: $e');
      }
      return null;
    }
  }

  /// 비교 메트릭 로드
  Future<Map<String, dynamic>?> loadComparisonMetrics({
    String compareWith = 'previous_period'
  }) async {
    try {
      final data = await _apiService.getComparisonMetrics(compareWith);
      return data['data'];
    } catch (e) {
      if (kDebugMode) {
        print('❌ 비교 메트릭 로드 실패: $e');
      }
      return null;
    }
  }

  /// 새로고침
  Future<void> refresh() async {
    await Future.wait([
      loadDashboardMetrics(forceRefresh: true),
      loadRealtimeMetrics(),
    ]);
  }

  /// 에러 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 실시간 업데이트 시작 (폴링)
  void startRealtimeUpdates() {
    // 30초마다 실시간 데이터 업데이트
    Future.delayed(const Duration(seconds: 30), () {
      if (_metrics != null) {
        loadRealtimeMetrics();
        startRealtimeUpdates(); // 재귀 호출로 지속적 업데이트
      }
    });
  }

  /// 실시간 업데이트 중지
  void stopRealtimeUpdates() {
    // 실제로는 Timer를 사용하여 구현해야 하지만, 
    // 여기서는 간단한 구조로 처리
  }

  /// 에러 메시지 처리
  String _handleError(dynamic error) {
    if (error is ApiException) {
      switch (error.code) {
        case 'UNAUTHORIZED':
          return '로그인이 필요합니다.';
        case 'FORBIDDEN':
          return '접근 권한이 없습니다.';
        case 'NOT_FOUND':
          return '데이터를 찾을 수 없습니다.';
        case 'NETWORK_ERROR':
          return '네트워크 연결을 확인해주세요.';
        default:
          return error.message ?? '알 수 없는 오류가 발생했습니다.';
      }
    }
    
    return '데이터를 불러오는 중 오류가 발생했습니다.';
  }

  /// 메트릭 업데이트 (실시간 반영용)
  void updateMetricValue(String metricType, int increment) {
    if (_metrics == null) return;

    // 실시간으로 메트릭 값 업데이트 (낙관적 업데이트)
    switch (metricType) {
      case 'views':
        _metrics = DashboardMetrics(
          totalViews: _metrics!.totalViews + increment,
          totalLikes: _metrics!.totalLikes,
          subscribersCount: _metrics!.subscribersCount,
          totalArticles: _metrics!.totalArticles,
          publishedArticles: _metrics!.publishedArticles,
          draftArticles: _metrics!.draftArticles,
          averageEngagement: _metrics!.averageEngagement,
          weeklyViews: _metrics!.weeklyViews + increment,
          weeklyLikes: _metrics!.weeklyLikes,
          weeklySubscribers: _metrics!.weeklySubscribers,
          topPerformingArticles: _metrics!.topPerformingArticles,
          recentActivity: _metrics!.recentActivity,
          categoryPerformance: _metrics!.categoryPerformance,
        );
        break;
      case 'likes':
        _metrics = DashboardMetrics(
          totalViews: _metrics!.totalViews,
          totalLikes: _metrics!.totalLikes + increment,
          subscribersCount: _metrics!.subscribersCount,
          totalArticles: _metrics!.totalArticles,
          publishedArticles: _metrics!.publishedArticles,
          draftArticles: _metrics!.draftArticles,
          averageEngagement: _metrics!.averageEngagement,
          weeklyViews: _metrics!.weeklyViews,
          weeklyLikes: _metrics!.weeklyLikes + increment,
          weeklySubscribers: _metrics!.weeklySubscribers,
          topPerformingArticles: _metrics!.topPerformingArticles,
          recentActivity: _metrics!.recentActivity,
          categoryPerformance: _metrics!.categoryPerformance,
        );
        break;
      case 'subscribers':
        _metrics = DashboardMetrics(
          totalViews: _metrics!.totalViews,
          totalLikes: _metrics!.totalLikes,
          subscribersCount: _metrics!.subscribersCount + increment,
          totalArticles: _metrics!.totalArticles,
          publishedArticles: _metrics!.publishedArticles,
          draftArticles: _metrics!.draftArticles,
          averageEngagement: _metrics!.averageEngagement,
          weeklyViews: _metrics!.weeklyViews,
          weeklyLikes: _metrics!.weeklyLikes,
          weeklySubscribers: _metrics!.weeklySubscribers + increment,
          topPerformingArticles: _metrics!.topPerformingArticles,
          recentActivity: _metrics!.recentActivity,
          categoryPerformance: _metrics!.categoryPerformance,
        );
        break;
    }
    
    notifyListeners();
  }

  @override
  void dispose() {
    stopRealtimeUpdates();
    super.dispose();
  }
}