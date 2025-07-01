import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/writer_theme.dart';
import '../../widgets/writer_app_bar.dart';
import '../../widgets/dashboard_metric_card.dart';
import '../../widgets/top_articles_widget.dart';
import '../../widgets/animated_counter.dart';

/// 작가 대시보드 메인 화면
/// 
/// 작가의 성과 지표, 인기 아티클, 트렌드 분석 등을 
/// 직관적이고 반응형으로 표시합니다.
class WriterDashboardScreen extends StatefulWidget {
  const WriterDashboardScreen({Key? key}) : super(key: key);

  @override
  State<WriterDashboardScreen> createState() => _WriterDashboardScreenState();
}

class _WriterDashboardScreenState extends State<WriterDashboardScreen>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    // 초기 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    await dashboardProvider.loadDashboardMetrics();
    
    // 실시간 업데이트 시작
    dashboardProvider.startRealtimeUpdates();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: WriterTheme.neutralGray50,
      appBar: WriterAppBar(
        title: '대시보드',
        actions: [
          Consumer<DashboardProvider>(
            builder: (context, dashboardProvider, child) {
              return IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: dashboardProvider.isLoading 
                      ? WriterTheme.neutralGray400 
                      : WriterTheme.neutralGray700,
                ),
                onPressed: dashboardProvider.isLoading 
                    ? null 
                    : () => _handleRefresh(),
                tooltip: '새로고침',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: 대시보드 설정으로 이동
            },
            tooltip: '설정',
          ),
        ],
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, dashboardProvider, child) {
          if (dashboardProvider.error != null && !dashboardProvider.hasData) {
            return _buildErrorState(dashboardProvider);
          }
          
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: WriterTheme.primaryBlue,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 환영 메시지
                  _buildWelcomeSection(),
                  
                  const SizedBox(height: 24),
                  
                  // 빠른 요약
                  if (dashboardProvider.hasData)
                    QuickMetricsSummary(
                      totalViews: dashboardProvider.metrics!.totalViews,
                      totalLikes: dashboardProvider.metrics!.totalLikes,
                      subscribersCount: dashboardProvider.metrics!.subscribersCount,
                      isLoading: dashboardProvider.isLoading,
                    ),
                  
                  if (dashboardProvider.isLoading && !dashboardProvider.hasData)
                    QuickMetricsSummary(
                      totalViews: 0,
                      totalLikes: 0,
                      subscribersCount: 0,
                      isLoading: true,
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // 주요 메트릭 그리드
                  _buildMetricsGrid(dashboardProvider),
                  
                  const SizedBox(height: 24),
                  
                  // 실시간 활동
                  _buildRealtimeActivity(dashboardProvider),
                  
                  const SizedBox(height: 24),
                  
                  // 인기 아티클
                  _buildTopArticles(dashboardProvider),
                  
                  const SizedBox(height: 24),
                  
                  // 성과 비교
                  _buildPerformanceComparison(dashboardProvider),
                  
                  const SizedBox(height: 24),
                  
                  // 카테고리별 성과
                  _buildCategoryPerformance(dashboardProvider),
                  
                  const SizedBox(height: 80), // 하단 여백
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 환영 섹션
  Widget _buildWelcomeSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final now = DateTime.now();
        final greeting = now.hour < 12 
            ? '좋은 아침이에요' 
            : now.hour < 18 
                ? '좋은 오후에요' 
                : '좋은 저녁이에요';
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                WriterTheme.primaryBlue,
                WriterTheme.primaryBlueLight,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: WriterTheme.softShadow,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting!',
                      style: WriterTheme.titleStyle.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user?.name ?? '작가'}님의 성과를 확인해보세요',
                      style: WriterTheme.bodyStyle.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.dashboard_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 메트릭 그리드
  Widget _buildMetricsGrid(DashboardProvider dashboardProvider) {
    final metrics = dashboardProvider.metrics;
    
    if (dashboardProvider.isLoading && !dashboardProvider.hasData) {
      // 로딩 스켈레톤
      return DashboardMetricsGrid(
        metricCards: [
          DashboardMetricCard(
            title: '총 조회수',
            value: 0,
            icon: Icons.visibility_outlined,
            iconColor: WriterTheme.primaryBlue,
            isLoading: true,
          ),
          DashboardMetricCard(
            title: '총 좋아요',
            value: 0,
            icon: Icons.favorite_outline,
            iconColor: WriterTheme.accentRed,
            isLoading: true,
          ),
          DashboardMetricCard(
            title: '구독자',
            value: 0,
            icon: Icons.people_outline,
            iconColor: WriterTheme.accentGreen,
            isLoading: true,
          ),
          DashboardMetricCard(
            title: '평균 참여도',
            value: 0,
            icon: Icons.trending_up,
            iconColor: WriterTheme.accentPurple,
            isLoading: true,
          ),
        ],
      );
    }
    
    if (metrics == null) {
      return const SizedBox.shrink();
    }

    return DashboardMetricsGrid(
      metricCards: [
        DashboardMetricCard(
          title: '총 조회수',
          value: metrics.totalViews,
          previousValue: metrics.totalViews - metrics.weeklyViews,
          icon: Icons.visibility_outlined,
          iconColor: WriterTheme.primaryBlue,
          subtitle: '이번 주 +${metrics.weeklyViews}',
          onTap: () => _showDetailedMetrics('views'),
        ),
        DashboardMetricCard(
          title: '총 좋아요',
          value: metrics.totalLikes,
          previousValue: metrics.totalLikes - metrics.weeklyLikes,
          icon: Icons.favorite_outline,
          iconColor: WriterTheme.accentRed,
          subtitle: '이번 주 +${metrics.weeklyLikes}',
          onTap: () => _showDetailedMetrics('likes'),
        ),
        DashboardMetricCard(
          title: '구독자',
          value: metrics.subscribersCount,
          previousValue: metrics.subscribersCount - metrics.weeklySubscribers,
          icon: Icons.people_outline,
          iconColor: WriterTheme.accentGreen,
          subtitle: '이번 주 +${metrics.weeklySubscribers}',
          onTap: () => _showDetailedMetrics('subscribers'),
        ),
        DashboardMetricCard(
          title: '평균 참여도',
          value: metrics.averageEngagement.round(),
          icon: Icons.trending_up,
          iconColor: WriterTheme.accentPurple,
          subtitle: '${metrics.averageEngagement.toStringAsFixed(1)}%',
          showTrend: false,
          onTap: () => _showDetailedMetrics('engagement'),
        ),
      ],
    );
  }

  /// 실시간 활동
  Widget _buildRealtimeActivity(DashboardProvider dashboardProvider) {
    final realtimeMetrics = dashboardProvider.realtimeMetrics;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: WriterTheme.neutralGray200,
          width: 1,
        ),
        boxShadow: WriterTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: WriterTheme.accentGreen,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.circle,
                  size: 8,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '실시간 활동',
                style: WriterTheme.titleStyle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                realtimeMetrics?.lastUpdate != null 
                    ? '방금 업데이트' 
                    : '업데이트 대기 중',
                style: WriterTheme.captionStyle.copyWith(
                  color: WriterTheme.neutralGray500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (dashboardProvider.isLoadingRealtime)
            _buildRealtimeLoading()
          else if (realtimeMetrics != null)
            _buildRealtimeContent(realtimeMetrics)
          else
            _buildRealtimeEmpty(),
        ],
      ),
    );
  }

  Widget _buildRealtimeLoading() {
    return Row(
      children: List.generate(3, (index) => 
        Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: WriterTheme.neutralGray200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 60,
                  height: 12,
                  decoration: BoxDecoration(
                    color: WriterTheme.neutralGray100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRealtimeContent(RealtimeMetrics metrics) {
    return Column(
      children: [
        Row(
          children: [
            _buildRealtimeMetric(
              '최근 1시간 조회수',
              metrics.lastHour['views'] ?? 0,
              Icons.visibility_outlined,
              WriterTheme.primaryBlue,
            ),
            _buildRealtimeMetric(
              '최근 1시간 좋아요',
              metrics.lastHour['likes'] ?? 0,
              Icons.favorite_outline,
              WriterTheme.accentRed,
            ),
            _buildRealtimeMetric(
              '현재 온라인 독자',
              metrics.currentOnlineReaders,
              Icons.people_outline,
              WriterTheme.accentGreen,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRealtimeEmpty() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.hourglass_empty,
            size: 32,
            color: WriterTheme.neutralGray400,
          ),
          const SizedBox(height: 8),
          Text(
            '실시간 데이터를 불러오는 중...',
            style: WriterTheme.bodyStyle.copyWith(
              color: WriterTheme.neutralGray500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealtimeMetric(String title, int value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedCounter(
            value: value,
            style: WriterTheme.subtitleStyle.copyWith(
              color: WriterTheme.neutralGray900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: WriterTheme.captionStyle.copyWith(
              color: WriterTheme.neutralGray500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 인기 아티클
  Widget _buildTopArticles(DashboardProvider dashboardProvider) {
    final metrics = dashboardProvider.metrics;
    
    return TopArticlesWidget(
      articles: metrics?.topPerformingArticles ?? [],
      isLoading: dashboardProvider.isLoading && !dashboardProvider.hasData,
      title: '인기 아티클 TOP 5',
      sortBy: 'views',
      onSeeAll: () {
        // TODO: 전체 아티클 분석으로 이동
      },
    );
  }

  /// 성과 비교
  Widget _buildPerformanceComparison(DashboardProvider dashboardProvider) {
    final metrics = dashboardProvider.metrics;
    
    if (metrics == null && !dashboardProvider.isLoading) {
      return const SizedBox.shrink();
    }
    
    return PerformanceComparisonWidget(
      currentViews: metrics?.weeklyViews ?? 0,
      previousViews: (metrics?.weeklyViews ?? 0) - 200, // 임시 계산
      currentLikes: metrics?.weeklyLikes ?? 0,
      previousLikes: (metrics?.weeklyLikes ?? 0) - 15, // 임시 계산
      currentSubscribers: metrics?.weeklySubscribers ?? 0,
      previousSubscribers: (metrics?.weeklySubscribers ?? 0) - 5, // 임시 계산
      period: '이번 주',
      isLoading: dashboardProvider.isLoading && !dashboardProvider.hasData,
    );
  }

  /// 카테고리별 성과
  Widget _buildCategoryPerformance(DashboardProvider dashboardProvider) {
    final metrics = dashboardProvider.metrics;
    
    if ((metrics?.categoryPerformance.isEmpty ?? true) && !dashboardProvider.isLoading) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: WriterTheme.neutralGray200,
          width: 1,
        ),
        boxShadow: WriterTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.category_outlined,
                color: WriterTheme.accentOrange,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '카테고리별 성과',
                style: WriterTheme.titleStyle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (dashboardProvider.isLoading && !dashboardProvider.hasData)
            _buildCategoryLoading()
          else if (metrics?.categoryPerformance.isNotEmpty ?? false)
            _buildCategoryList(metrics!.categoryPerformance)
          else
            _buildCategoryEmpty(),
        ],
      ),
    );
  }

  Widget _buildCategoryLoading() {
    return Column(
      children: List.generate(3, (index) => 
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 16,
                decoration: BoxDecoration(
                  color: WriterTheme.neutralGray200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Container(
                width: 40,
                height: 16,
                decoration: BoxDecoration(
                  color: WriterTheme.neutralGray100,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(List<CategoryPerformance> categories) {
    return Column(
      children: categories.map((category) => 
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: WriterTheme.neutralGray50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.category,
                      style: WriterTheme.bodyStyle.copyWith(
                        color: WriterTheme.neutralGray900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${category.articles}개 아티클 • ${_formatNumber(category.views)} 조회수',
                      style: WriterTheme.captionStyle.copyWith(
                        color: WriterTheme.neutralGray500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: WriterTheme.accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${category.engagement.toStringAsFixed(1)}%',
                  style: WriterTheme.captionStyle.copyWith(
                    color: WriterTheme.accentGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ).toList(),
    );
  }

  Widget _buildCategoryEmpty() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.category_outlined,
            size: 32,
            color: WriterTheme.neutralGray400,
          ),
          const SizedBox(height: 8),
          Text(
            '카테고리별 데이터가 없습니다',
            style: WriterTheme.bodyStyle.copyWith(
              color: WriterTheme.neutralGray500,
            ),
          ),
        ],
      ),
    );
  }

  /// 에러 상태
  Widget _buildErrorState(DashboardProvider dashboardProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: WriterTheme.accentRed,
            ),
            const SizedBox(height: 16),
            Text(
              '데이터를 불러올 수 없습니다',
              style: WriterTheme.titleStyle.copyWith(
                color: WriterTheme.neutralGray900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              dashboardProvider.error ?? '알 수 없는 오류가 발생했습니다.',
              style: WriterTheme.bodyStyle.copyWith(
                color: WriterTheme.neutralGray600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _handleRefresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: WriterTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 새로고침 처리
  Future<void> _handleRefresh() async {
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    await dashboardProvider.refresh();
  }

  /// 상세 메트릭 표시
  void _showDetailedMetrics(String metricType) {
    // TODO: 상세 메트릭 모달 또는 화면으로 이동
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$metricType 상세 정보 (구현 예정)'),
        backgroundColor: WriterTheme.primaryBlue,
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }
}