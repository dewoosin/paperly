import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/article_provider.dart';
import '../../theme/writer_theme.dart';
import '../../widgets/writer_app_bar.dart';
import '../../widgets/stats_overview_card.dart';
import '../followers/followers_screen.dart';
import '../../widgets/animated_counter.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    
    // 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analyticsProvider = Provider.of<AnalyticsProvider>(context, listen: false);
      final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
      
      analyticsProvider.loadStats();
      analyticsProvider.loadTrendingTopics();
      articleProvider.loadMyArticles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WriterTheme.backgroundLight,
      appBar: const SimpleWriterAppBar(
        title: '통계 & 분석',
        showBackButton: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 개요 통계
              const StatsOverviewCard(),
              
              const SizedBox(height: 20),
              
              // 팔로워 관리 섹션
              _buildFollowersManagementCard(),
              
              const SizedBox(height: 20),
              
              // 월별 성과 차트
              _buildMonthlyPerformanceCard(),
              
              const SizedBox(height: 20),
              
              // 카테고리별 성과
              _buildCategoryPerformanceCard(),
              
              const SizedBox(height: 20),
              
              // 트렌딩 토픽 분석
              _buildTrendingTopicsCard(),
              
              const SizedBox(height: 20),
              
              // 성과 인사이트
              _buildInsightsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyPerformanceCard() {
    return Consumer<AnalyticsProvider>(
      builder: (context, analyticsProvider, child) {
        final stats = analyticsProvider.stats;
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: WriterTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.timeline,
                    color: WriterTheme.primaryBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '월별 성과',
                    style: WriterTheme.titleStyle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              if (stats?.monthlyStats.isNotEmpty == true) ...[
                // 간단한 월별 통계 표시
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: stats!.monthlyStats.length,
                    itemBuilder: (context, index) {
                      final monthStat = stats.monthlyStats[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 16),
                        width: 120,
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: WriterTheme.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      height: (monthStat.views / 1000).clamp(20, 150).toDouble(),
                                      decoration: BoxDecoration(
                                        color: WriterTheme.primaryBlue,
                                        borderRadius: const BorderRadius.vertical(
                                          bottom: Radius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              monthStat.displayMonth,
                              style: WriterTheme.captionStyle.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              '${monthStat.views}',
                              style: WriterTheme.captionStyle.copyWith(
                                color: WriterTheme.neutralGray600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ] else
                _buildEmptyChart(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryPerformanceCard() {
    return Consumer<AnalyticsProvider>(
      builder: (context, analyticsProvider, child) {
        final stats = analyticsProvider.stats;
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: WriterTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.category,
                    color: WriterTheme.primaryBlue,
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
              
              const SizedBox(height: 20),
              
              if (stats?.categoryStats.isNotEmpty == true) ...[
                ...stats!.categoryStats.entries.map((entry) => 
                  _buildCategoryItem(entry.key, entry.value),
                ),
              ] else
                _buildEmptyCategories(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryItem(String category, int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WriterTheme.neutralGray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WriterTheme.neutralGray200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: WriterTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.folder,
              color: WriterTheme.primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: WriterTheme.subtitleStyle.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$count개의 글',
                  style: WriterTheme.captionStyle.copyWith(
                    color: WriterTheme.neutralGray600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: WriterTheme.primaryBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: WriterTheme.captionStyle.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingTopicsCard() {
    return Consumer<AnalyticsProvider>(
      builder: (context, analyticsProvider, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: WriterTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: WriterTheme.primaryBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '트렌딩 주제',
                    style: WriterTheme.titleStyle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              if (analyticsProvider.trendingTopics.isNotEmpty) ...[
                ...analyticsProvider.trendingTopics.take(3).map((topic) => 
                  _buildTrendingTopicItem(topic),
                ),
                
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      // 전체 트렌딩 주제 페이지로 이동
                    },
                    child: Text(
                      '전체 트렌딩 주제 보기',
                      style: WriterTheme.bodyStyle.copyWith(
                        color: WriterTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ] else
                _buildEmptyTrending(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendingTopicItem(TrendingTopic topic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WriterTheme.neutralGray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WriterTheme.neutralGray200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: topic.isHot 
                  ? WriterTheme.accentRed.withOpacity(0.1)
                  : WriterTheme.accentGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              topic.isHot ? Icons.local_fire_department : Icons.trending_up,
              color: topic.isHot ? WriterTheme.accentRed : WriterTheme.accentGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.name,
                  style: WriterTheme.subtitleStyle.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${topic.articleCount}개 글 · ${topic.displayGrowthRate}',
                  style: WriterTheme.captionStyle.copyWith(
                    color: WriterTheme.neutralGray600,
                  ),
                ),
              ],
            ),
          ),
          if (topic.isHot)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: WriterTheme.accentRed,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'HOT',
                style: WriterTheme.captionStyle.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard() {
    return Consumer2<AnalyticsProvider, ArticleProvider>(
      builder: (context, analyticsProvider, articleProvider, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: WriterTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb,
                    color: WriterTheme.primaryBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '인사이트',
                    style: WriterTheme.titleStyle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              _buildInsightItem(
                icon: Icons.article,
                title: '총 ${articleProvider.myArticles.length}개의 글',
                description: '지금까지 ${articleProvider.myPublishedArticles.length}개를 발행했어요',
                color: WriterTheme.primaryBlue,
              ),
              
              _buildInsightItem(
                icon: Icons.visibility,
                title: '총 ${articleProvider.totalViews}회 조회',
                description: '평균 ${articleProvider.myPublishedArticles.isNotEmpty ? (articleProvider.totalViews / articleProvider.myPublishedArticles.length).round() : 0}회 조회수를 기록했어요',
                color: WriterTheme.accentGreen,
              ),
              
              if (analyticsProvider.stats?.topCategory != null)
                _buildInsightItem(
                  icon: Icons.star,
                  title: '인기 카테고리: ${analyticsProvider.stats!.topCategory}',
                  description: '가장 많이 작성한 주제예요',
                  color: WriterTheme.accentOrange,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInsightItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: WriterTheme.subtitleStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  description,
                  style: WriterTheme.captionStyle.copyWith(
                    color: WriterTheme.neutralGray600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Container(
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 48,
            color: WriterTheme.neutralGray400,
          ),
          const SizedBox(height: 12),
          Text(
            '아직 데이터가 없어요',
            style: WriterTheme.subtitleStyle.copyWith(
              color: WriterTheme.neutralGray600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCategories() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.category,
            size: 48,
            color: WriterTheme.neutralGray400,
          ),
          const SizedBox(height: 12),
          Text(
            '카테고리별 데이터가 없어요',
            style: WriterTheme.subtitleStyle.copyWith(
              color: WriterTheme.neutralGray600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTrending() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.trending_up,
            size: 48,
            color: WriterTheme.neutralGray400,
          ),
          const SizedBox(height: 12),
          Text(
            '트렌딩 주제를 분석 중이에요',
            style: WriterTheme.subtitleStyle.copyWith(
              color: WriterTheme.neutralGray600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowersManagementCard() {
    return Consumer<AnalyticsProvider>(
      builder: (context, analyticsProvider, child) {
        final stats = analyticsProvider.stats;
        
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                WriterTheme.primaryBlue.withOpacity(0.05),
                WriterTheme.primaryBlue.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: WriterTheme.primaryBlue.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: WriterTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.people,
                      color: WriterTheme.primaryBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '구독자 관리',
                          style: WriterTheme.titleStyle.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '구독자와의 관계를 강화하세요',
                          style: WriterTheme.bodyStyle.copyWith(
                            color: WriterTheme.neutralGray600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: WriterTheme.accentGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${stats?.followersCount ?? 0}명',
                      style: WriterTheme.captionStyle.copyWith(
                        color: WriterTheme.accentGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: _buildFollowerMetric(
                      '신규 구독자',
                      '+${stats?.monthlyStats.isNotEmpty == true ? (stats!.monthlyStats.last.views / 5).round() : 0}',
                      Icons.person_add,
                      WriterTheme.accentGreen,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: WriterTheme.neutralGray200,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  Expanded(
                    child: _buildFollowerMetric(
                      '참여율',
                      '${stats?.averageLikeRate.toStringAsFixed(1) ?? "0"}%',
                      Icons.favorite,
                      WriterTheme.accentRed,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: WriterTheme.neutralGray200,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  Expanded(
                    child: _buildFollowerMetric(
                      '활성 비율',
                      '73%',
                      Icons.trending_up,
                      WriterTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      SmoothPageTransition(
                        child: const FollowersScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WriterTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    '구독자 관리하기',
                    style: WriterTheme.subtitleStyle.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFollowerMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: WriterTheme.subtitleStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: WriterTheme.captionStyle.copyWith(
            color: WriterTheme.neutralGray600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _refreshData() async {
    final analyticsProvider = Provider.of<AnalyticsProvider>(context, listen: false);
    final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
    
    await Future.wait([
      analyticsProvider.loadStats(refresh: true),
      analyticsProvider.loadTrendingTopics(refresh: true),
      articleProvider.loadMyArticles(refresh: true),
    ]);
  }
}