import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/writer_profile_provider.dart';
import '../../theme/writer_theme.dart';
import '../../widgets/writer_app_bar.dart';
import '../../widgets/follower_stats_card.dart';
import '../../widgets/animated_counter.dart';

class FollowersScreen extends StatefulWidget {
  const FollowersScreen({Key? key}) : super(key: key);

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFollowerData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFollowerData() async {
    final analyticsProvider = Provider.of<AnalyticsProvider>(context, listen: false);
    final profileProvider = Provider.of<WriterProfileProvider>(context, listen: false);
    
    await Future.wait([
      analyticsProvider.loadStats(refresh: true),
      profileProvider.loadFollowers(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WriterTheme.backgroundLight,
      appBar: const SimpleWriterAppBar(
        title: '구독자 관리',
        showBackButton: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadFollowerData,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // 팔로워 통계 카드
                      const FollowerStatsCard(),
                      
                      const SizedBox(height: 24),
                      
                      // 성장 차트 요약
                      _buildGrowthSummaryCard(),
                      
                      const SizedBox(height: 24),
                      
                      // 탭 헤더
                      _buildTabHeader(),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildFollowersTab(),
              _buildGrowthTab(),
              _buildEngagementTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrowthSummaryCard() {
    return Consumer<AnalyticsProvider>(
      builder: (context, analytics, child) {
        final stats = analytics.stats;
        
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
                      Icons.trending_up,
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
                          '이번 달 성장',
                          style: WriterTheme.titleStyle.copyWith(
                            fontWeight: FontWeight.bold,
                            color: WriterTheme.neutralGray900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '새로운 구독자와 활동 지표',
                          style: WriterTheme.bodyStyle.copyWith(
                            color: WriterTheme.neutralGray600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: _buildGrowthMetric(
                      '신규 팔로워',
                      '+${stats?.monthlyStats.isNotEmpty == true ? stats!.monthlyStats.last.views : 0}',
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
                    child: _buildGrowthMetric(
                      '참여율',
                      '${stats?.averageLikeRate.toStringAsFixed(1) ?? "0"}%',
                      Icons.favorite,
                      WriterTheme.accentRed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrowthMetric(String label, String value, IconData icon, Color color) {
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
        AnimatedCounter(
          value: int.tryParse(value) ?? 0,
          style: WriterTheme.titleStyle.copyWith(
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

  Widget _buildTabHeader() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: WriterTheme.neutralGray100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: WriterTheme.neutralGray300.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: WriterTheme.primaryBlue,
        unselectedLabelColor: WriterTheme.neutralGray600,
        labelStyle: WriterTheme.subtitleStyle.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: WriterTheme.subtitleStyle.copyWith(
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: '구독자'),
          Tab(text: '성장 추이'),
          Tab(text: '참여도'),
        ],
      ),
    );
  }

  Widget _buildFollowersTab() {
    return Consumer<WriterProfileProvider>(
      builder: (context, profile, child) {
        if (profile.followers.isEmpty) {
          return _buildEmptyState(
            '아직 구독자가 없어요',
            '멋진 글을 써서 첫 구독자를 만들어보세요!',
            Icons.people_outline,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: profile.followers.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final follower = profile.followers[index];
            return _buildFollowerItem(follower);
          },
        );
      },
    );
  }

  Widget _buildFollowerItem(dynamic follower) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: WriterTheme.neutralGray200.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 프로필 이미지
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: WriterTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: WriterTheme.primaryBlue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: follower['profileImage'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.network(
                      follower['profileImage'],
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.person,
                    color: WriterTheme.primaryBlue,
                    size: 24,
                  ),
          ),
          
          const SizedBox(width: 16),
          
          // 사용자 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  follower['name'] ?? '익명',
                  style: WriterTheme.subtitleStyle.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${follower['followedAt'] ?? '최근'}에 구독',
                  style: WriterTheme.captionStyle.copyWith(
                    color: WriterTheme.neutralGray600,
                  ),
                ),
              ],
            ),
          ),
          
          // 활동 지표
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: WriterTheme.accentGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '활발',
              style: WriterTheme.captionStyle.copyWith(
                color: WriterTheme.accentGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthTab() {
    return Consumer<AnalyticsProvider>(
      builder: (context, analytics, child) {
        final monthlyStats = analytics.stats?.monthlyStats ?? [];
        
        if (monthlyStats.isEmpty) {
          return _buildEmptyState(
            '성장 데이터를 분석 중이에요',
            '더 많은 데이터가 쌓이면 성장 추이를 확인할 수 있어요',
            Icons.timeline,
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 월별 성장 차트
              _buildMonthlyGrowthChart(monthlyStats),
              
              const SizedBox(height: 24),
              
              // 성장 인사이트
              _buildGrowthInsights(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthlyGrowthChart(List<MonthlyStats> monthlyStats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: WriterTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '월별 구독자 증가',
            style: WriterTheme.titleStyle.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 20),
          
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: monthlyStats.length,
              itemBuilder: (context, index) {
                final stat = monthlyStats[index];
                final maxViews = monthlyStats.map((s) => s.views).reduce((a, b) => a > b ? a : b);
                final height = (stat.views / maxViews * 150).clamp(20, 150).toDouble();
                
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 80,
                  child: Column(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AnimatedContainer(
                              duration: Duration(milliseconds: 300 + (index * 100)),
                              height: height,
                              width: 32,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    WriterTheme.primaryBlue.withOpacity(0.8),
                                    WriterTheme.primaryBlue,
                                  ],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Text(
                        stat.displayMonth.split(' ')[1],
                        style: WriterTheme.captionStyle.copyWith(
                          fontWeight: FontWeight.w600,
                          color: WriterTheme.neutralGray700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        '${stat.views}',
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
        ],
      ),
    );
  }

  Widget _buildGrowthInsights() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: WriterTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: WriterTheme.accentOrange,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '성장 인사이트',
                style: WriterTheme.titleStyle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildInsightItem(
            '가장 활발한 시간',
            '오후 2-4시에 구독자 활동이 가장 활발해요',
            Icons.schedule,
            WriterTheme.primaryBlue,
          ),
          
          const SizedBox(height: 12),
          
          _buildInsightItem(
            '인기 콘텐츠 유형',
            '기술 관련 글에서 구독자 반응이 좋아요',
            Icons.trending_up,
            WriterTheme.accentGreen,
          ),
          
          const SizedBox(height: 12),
          
          _buildInsightItem(
            '추천 발행 시간',
            '화요일과 목요일 오후가 가장 효과적이에요',
            Icons.schedule_outlined,
            WriterTheme.accentOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          
          const SizedBox(width: 16),
          
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
                const SizedBox(height: 4),
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

  Widget _buildEngagementTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 참여도 지표
          _buildEngagementMetrics(),
          
          const SizedBox(height: 24),
          
          // 인기 콘텐츠
          _buildPopularContent(),
        ],
      ),
    );
  }

  Widget _buildEngagementMetrics() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: WriterTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '참여도 지표',
            style: WriterTheme.titleStyle.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildEngagementItem(
                  '평균 좋아요',
                  '89%',
                  Icons.favorite,
                  WriterTheme.accentRed,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: WriterTheme.neutralGray200,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: _buildEngagementItem(
                  '댓글 참여',
                  '76%',
                  Icons.comment,
                  WriterTheme.primaryBlue,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: WriterTheme.neutralGray200,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: _buildEngagementItem(
                  '공유율',
                  '45%',
                  Icons.share,
                  WriterTheme.accentGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: WriterTheme.titleStyle.copyWith(
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

  Widget _buildPopularContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: WriterTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '인기 콘텐츠',
            style: WriterTheme.titleStyle.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildPopularContentItem(
                '플러터 개발자가 알아야 할 10가지',
                '1,234',
                '89',
                index + 1,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPopularContentItem(String title, String views, String likes, int rank) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WriterTheme.neutralGray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: WriterTheme.neutralGray200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: rank <= 3 ? WriterTheme.accentOrange : WriterTheme.neutralGray300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: WriterTheme.captionStyle.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: WriterTheme.subtitleStyle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.visibility,
                      size: 14,
                      color: WriterTheme.neutralGray500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      views,
                      style: WriterTheme.captionStyle,
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.favorite,
                      size: 14,
                      color: WriterTheme.accentRed,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      likes,
                      style: WriterTheme.captionStyle,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String description, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: WriterTheme.neutralGray100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 40,
                color: WriterTheme.neutralGray400,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              title,
              style: WriterTheme.titleStyle.copyWith(
                fontWeight: FontWeight.bold,
                color: WriterTheme.neutralGray700,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            Text(
              description,
              style: WriterTheme.bodyStyle.copyWith(
                color: WriterTheme.neutralGray600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}