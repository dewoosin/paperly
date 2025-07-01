import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/article_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/writer_theme.dart';
import '../../widgets/writer_app_bar.dart';
import '../../widgets/stats_overview_card.dart';
import '../../widgets/recent_articles_list.dart';
import '../../widgets/trending_topics_card.dart';
import '../../widgets/quick_actions_section.dart';
import '../articles/article_editor_screen.dart';
import '../articles/my_articles_screen.dart';
import '../analytics/analytics_screen.dart';
import '../profile/profile_screen.dart';
import '../followers/followers_screen.dart';
import '../dashboard/writer_dashboard_screen.dart';
import '../../widgets/animated_counter.dart';

class WriterHomeScreen extends StatefulWidget {
  const WriterHomeScreen({Key? key}) : super(key: key);

  @override
  State<WriterHomeScreen> createState() => _WriterHomeScreenState();
}

class _WriterHomeScreenState extends State<WriterHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    // 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
    final analyticsProvider = Provider.of<AnalyticsProvider>(context, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    
    await Future.wait([
      articleProvider.loadMyArticles(),
      analyticsProvider.loadStats(),
      analyticsProvider.loadTrendingTopics(),
      dashboardProvider.loadDashboardMetrics(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WriterTheme.neutralGray50,
      body: AnimatedBuilder(
        animation: _tabController.animation!,
        builder: (context, child) {
          return TabBarView(
            controller: _tabController,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildHomeTab(),
              _buildDashboardTab(),
              _buildArticlesTab(),
              _buildAnalyticsTab(),
              _buildProfileTab(),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController.animation!,
        builder: (context, child) {
          final showFAB = _tabController.index == 0 || _tabController.index == 2;
          return AnimatedScale(
            scale: showFAB ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              opacity: showFAB ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: FloatingActionButton(
                onPressed: showFAB ? _navigateToNewArticle : null,
                tooltip: '새 글 작성',
                child: const Icon(Icons.add),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHomeTab() {
    return CustomScrollView(
      slivers: [
        // 앱바
        const WriterAppBar(
          title: '홈',
          showBackButton: false,
        ),
        
        // 내용
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // 인사말
              _buildWelcomeSection(),
              
              const SizedBox(height: 24),
              
              // 통계 개요
              const StatsOverviewCard(),
              
              const SizedBox(height: 24),
              
              // 빠른 작업
              const QuickActionsSection(),
              
              const SizedBox(height: 24),
              
              // 최근 글
              const RecentArticlesList(),
              
              const SizedBox(height: 24),
              
              // 트렌딩 주제
              const TrendingTopicsCard(),
              
              const SizedBox(height: 100), // FAB 공간
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardTab() {
    return const WriterDashboardScreen();
  }

  Widget _buildArticlesTab() {
    return const MyArticlesScreen();
  }

  Widget _buildAnalyticsTab() {
    return const AnalyticsScreen();
  }

  Widget _buildProfileTab() {
    return const ProfileScreen();
  }

  Widget _buildWelcomeSection() {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        final user = auth.user;
        if (user == null) return const SizedBox.shrink();
        
        final greeting = _getGreeting();
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                WriterTheme.primaryBlue,
                WriterTheme.primaryBlueDark,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: WriterTheme.mediumShadow,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting,',
                      style: WriterTheme.bodyStyle.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.name,
                      style: WriterTheme.titleStyle.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '오늘도 멋진 이야기를 써보세요',
                      style: WriterTheme.bodyStyle.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              
              // 프로필 이미지
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: user.profileImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          user.profileImageUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Text(
                          user.initials,
                          style: WriterTheme.titleStyle.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: WriterTheme.neutralGray200.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        tabAlignment: TabAlignment.fill,
        labelColor: WriterTheme.primaryBlue,
        unselectedLabelColor: WriterTheme.neutralGray500,
        indicator: const BoxDecoration(),
        labelStyle: WriterTheme.captionStyle.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        unselectedLabelStyle: WriterTheme.captionStyle.copyWith(
          fontSize: 11,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.home),
            text: '홈',
          ),
          Tab(
            icon: Icon(Icons.dashboard),
            text: '대시보드',
          ),
          Tab(
            icon: Icon(Icons.article),
            text: '내 글',
          ),
          Tab(
            icon: Icon(Icons.analytics),
            text: '통계',
          ),
          Tab(
            icon: Icon(Icons.person),
            text: '프로필',
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return '좋은 아침';
    } else if (hour < 18) {
      return '안녕하세요';
    } else {
      return '좋은 저녁';
    }
  }

  void _navigateToNewArticle() {
    Navigator.of(context).push(
      ScaleFadeTransition(
        child: const ArticleEditorScreen(),
      ),
    );
  }
}