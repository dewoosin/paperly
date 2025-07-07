/// Paperly 홈 스크린
/// 
/// 이 파일은 앱의 메인 홈 화면을 구현합니다.
/// Blinkist와 같은 지식 플랫폼 스타일로 디자인되었습니다.
/// 
/// 주요 기능:
/// - AI 기반 개인화 추천 시스템
/// - 애플 커버플로우 스타일 책 카드 UI
/// - 작가 구독 및 팔로우 시스템
/// - 관심사 기반 콘텐츠 탐색
/// - 실시간 트렌딩 콘텐츠
/// 
/// UI 특징:
/// - 패럴럭스 스크롤링 효과
/// - 부드러운 애니메이션 전환
/// - 무인양품 스타일 미니멀 디자인

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';        // 햅틱 피드백용
import 'package:flutter/cupertino.dart';       // iOS 스타일 위젯
import 'package:provider/provider.dart';       // 상태 관리
import 'dart:ui' as ui;                        // UI 효과용
import '../theme/muji_theme.dart';             // 앱 테마
import '../providers/auth_provider.dart';      // 인증 상태 관리
import '../providers/follow_provider.dart';    // 팔로우 상태 관리
import '../models/author_models.dart';         // 작가 모델
import 'search_screen.dart';                   // 검색 화면
import 'article_detail_screen.dart';           // 글 상세 화면
import 'author_detail_screen.dart';            // 작가 상세 화면
/// 홈 스크린 메인 위젯
/// 
/// StatefulWidget을 상속하여 상태 변화가 있는 동적 UI를 구현
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// 홈 스크린의 상태 관리 클래스
/// 
/// TickerProviderStateMixin:
/// 여러 개의 애니메이션 컨트롤러를 관리할 때 사용
/// 각 애니메이션마다 독립적인 Ticker를 제공
class _HomeScreenState extends State<HomeScreen> 
    with TickerProviderStateMixin {
  
  // 애니메이션 컨트롤러들
  late AnimationController _fadeController;      // 페이드 인/아웃 애니메이션
  late AnimationController _parallaxController;  // 패럴럭스 스크롤 애니메이션
  late AnimationController _floatingController;  // 플로팅 요소 애니메이션
  
  // 스크롤 컨트롤러들
  final ScrollController _scrollController = ScrollController();       // 메인 스크롤
  final ScrollController _booksScrollController = ScrollController();  // 책 카드 스크롤
  
  // UI 상태 변수들
  int _currentTab = 0;          // 현재 선택된 탭 인덱스
  double _scrollOffset = 0;     // 메인 스크롤 오프셋
  double _headerParallax = 0;   // 헤더 패럴럭스 오프셋
  double _sectionOffset = 0;    // 섹션 스크롤 오프셋
  double _booksScrollOffset = 0; // 책 카드 스크롤 오프셋

  // 개인화된 추천 글 데이터 (작은 책 모양)
  final List<Map<String, dynamic>> _personalizedArticles = [
    {
      'id': 'p1',
      'title': '디지털 노마드의 새로운 일하는 방식',
      'author': '김자유',
      'category': '라이프스타일',
      'readTime': '8분',
      'bookColor': MujiTheme.sage,
      'textColor': Colors.white,
      'summary': '원격근무가 일반화된 시대, 진정한 디지털 노마드로 살아가는 법',
      'spine': '디지털 노마드',
      'pages': 156,
    },
    {
      'id': 'p2', 
      'title': '마음챙김과 현대인의 스트레스 관리',
      'author': '정명상',
      'category': '웰빙',
      'readTime': '12분',
      'bookColor': MujiTheme.clay,
      'textColor': MujiTheme.textDark,
      'summary': '바쁜 일상 속에서도 실천할 수 있는 마음챙김 기법들',
      'spine': '마음챙김',
      'pages': 203,
    },
    {
      'id': 'p3',
      'title': '지속가능한 소비의 미학',
      'author': '이친환',
      'category': '환경',
      'readTime': '15분',
      'bookColor': MujiTheme.moss,
      'textColor': Colors.white,
      'summary': '환경을 생각하는 소비 습관이 만드는 아름다운 변화',
      'spine': '지속가능 소비',
      'pages': 184,
    },
    {
      'id': 'p4',
      'title': '창의적 사고를 기르는 방법',
      'author': '박창의',
      'category': '자기계발',
      'readTime': '10분',
      'bookColor': MujiTheme.bark,
      'textColor': Colors.white,
      'summary': '일상에서 창의성을 발휘할 수 있는 구체적인 방법론',
      'spine': '창의적 사고',
      'pages': 167,
    },
    {
      'id': 'p5',
      'title': '인공지능 시대의 인간 가치',
      'author': '최미래',
      'category': '기술',
      'readTime': '18분',
      'bookColor': MujiTheme.stone,
      'textColor': MujiTheme.textDark,
      'summary': 'AI가 발전하는 시대에 인간만이 가질 수 있는 고유한 가치',
      'spine': 'AI와 인간',
      'pages': 245,
    },
  ];

  // 임시 데이터 - 실제로는 API에서 가져올 예정
  final List<Map<String, dynamic>> _featuredArticles = [
    {
      'title': '디지털 미니멀리즘의 원칙',
      'author': '칼 뉴포트',
      'category': '자기계발',
      'readTime': '12분',
      'image': '📱',
      'color': Color(0xFF6366f1),
      'description': '현대 사회에서 디지털 기기와 건강한 관계를 맺는 방법을 탐구합니다.',
    },
    {
      'title': '창의성의 과학적 원리',
      'author': '아담 그랜트',
      'category': '창의성',
      'readTime': '15분',
      'image': '🧠',
      'color': Color(0xFF8b5cf6),
      'description': '혁신적인 아이디어가 어떻게 탄생하는지 과학적으로 분석합니다.',
    },
    {
      'title': '지속가능한 미래 설계',
      'author': '김환경',
      'category': '환경',
      'readTime': '10분',
      'image': '🌱',
      'color': Color(0xFF10b981),
      'description': '기후 변화 시대에 개인과 사회가 실천할 수 있는 구체적 방안들.',
    },
  ];

  // 트렌딩 작가 데이터는 이제 FollowProvider에서 가져옴

  final List<Map<String, dynamic>> _categories = [
    {'name': '비즈니스', 'icon': '💼', 'count': '340+', 'color': Color(0xFF3b82f6)},
    {'name': '자기계발', 'icon': '📈', 'count': '280+', 'color': Color(0xFF8b5cf6)},
    {'name': '과학기술', 'icon': '🔬', 'count': '190+', 'color': Color(0xFF06b6d4)},
    {'name': '철학', 'icon': '🤔', 'count': '120+', 'color': Color(0xFF84cc16)},
    {'name': '예술', 'icon': '🎨', 'count': '95+', 'color': Color(0xFFf59e0b)},
    {'name': '역사', 'icon': '📜', 'count': '150+', 'color': Color(0xFFef4444)},
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    _parallaxController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();
    
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
        // 패럴랙스 효과를 위한 계산
        _headerParallax = _scrollOffset * 0.3;
        _sectionOffset = _scrollOffset * 0.1;
      });
    });
    
    _booksScrollController.addListener(() {
      setState(() {
        _booksScrollOffset = _booksScrollController.offset;
      });
    });
    
    // 트렌딩 작가 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTrendingAuthors();
    });
  }
  
  /// 트렌딩 작가 데이터 로드
  Future<void> _loadTrendingAuthors() async {
    try {
      final followProvider = context.read<FollowProvider>();
      await followProvider.loadTrendingAuthors(limit: 6);
    } catch (e) {
      // 에러는 FollowProvider에서 처리됨
      print('트렌딩 작가 로드 실패: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _parallaxController.dispose();
    _floatingController.dispose();
    _scrollController.dispose();
    _booksScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: MujiTheme.bg,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: safeTop + 60),
              ),
              
              // 개인화된 인사말
              SliverToBoxAdapter(
                child: _buildPersonalizedHeader(user?.name ?? '사용자'),
              ),
              
              // 이메일 인증 알림 (필요한 경우)
              if (user != null && !user.emailVerified)
                SliverToBoxAdapter(
                  child: _buildEmailVerificationBanner(),
                ),
              
              // 개인화된 추천 글 (책 모양)
              SliverToBoxAdapter(
                child: _buildPersonalizedArticles(),
              ),
              
              // AI 추천 섹션
              SliverToBoxAdapter(
                child: _buildAIRecommendations(),
              ),
              
              // 트렌딩 작가 섹션
              SliverToBoxAdapter(
                child: _buildTrendingAuthors(),
              ),
              
              // 관심사별 탐색 섹션
              SliverToBoxAdapter(
                child: _buildCategoryExploration(),
              ),
              
              // 최근 읽은 글 (개인화)
              SliverToBoxAdapter(
                child: _buildRecentReads(),
              ),
              
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
          
          _buildBlinkistStyleAppBar(safeTop),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildBlinkistStyleAppBar(double safeTop) {
    final isScrolled = _scrollOffset > 20;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: safeTop + 60,
      decoration: BoxDecoration(
        color: isScrolled 
            ? MujiTheme.bg.withOpacity(0.95)
            : MujiTheme.bg.withOpacity(0),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: isScrolled ? 10 : 0,
            sigmaY: isScrolled ? 10 : 0,
          ),
          child: Container(
            padding: EdgeInsets.only(top: safeTop),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // 로고
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [MujiTheme.sage, MujiTheme.moss],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          CupertinoIcons.book_circle_fill,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Paperly',
                        style: MujiTheme.mobileH3.copyWith(
                          fontWeight: FontWeight.bold,
                          color: MujiTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // 검색 및 알림
                  Row(
                    children: [
                      _buildHeaderButton(
                        icon: CupertinoIcons.search,
                        onTap: () => _showSearchScreen(),
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderButton(
                        icon: CupertinoIcons.bell,
                        onTap: () => _showNotifications(),
                        hasNotification: true,
                      ),
                      const SizedBox(width: 8),
                      _buildProfileAvatar(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    bool hasNotification = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: MujiTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: MujiTheme.border.withOpacity(0.5),
            width: 0.5,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: MujiTheme.textBody,
            ),
            if (hasNotification)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return GestureDetector(
      onTap: () => _showProfileMenu(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [MujiTheme.sage, MujiTheme.moss],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          CupertinoIcons.person_fill,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildPersonalizedHeader(String userName) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? '좋은 아침이에요' : 
                    hour < 18 ? '좋은 오후예요' : '편안한 저녁이에요';
    
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_headerParallax + (_floatingController.value * 2)),
          child: Opacity(
            opacity: (1.0 - (_scrollOffset / 300)).clamp(0.0, 1.0),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    MujiTheme.bg,
                    MujiTheme.bg.withOpacity(0.8),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _fadeController,
                      curve: Curves.easeOutCubic,
                    )),
                    child: FadeTransition(
                      opacity: _fadeController,
                      child: Text(
                        '$greeting, $userName님',
                        style: MujiTheme.mobileH1.copyWith(
                          fontWeight: FontWeight.w700,
                          color: MujiTheme.textDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.5),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _fadeController,
                      curve: Interval(0.2, 1.0, curve: Curves.easeOutCubic),
                    )),
                    child: FadeTransition(
                      opacity: Tween<double>(
                        begin: 0,
                        end: 1,
                      ).animate(CurvedAnimation(
                        parent: _fadeController,
                        curve: Interval(0.2, 1.0),
                      )),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: MujiTheme.paper.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: MujiTheme.clay.withOpacity(0.15),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          '오늘도 새로운 지식과 통찰을 발견해보세요',
                          style: MujiTheme.mobileBody.copyWith(
                            color: MujiTheme.textLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPersonalizedArticles() {
    final sectionOpacity = (1.0 - (_scrollOffset / 400)).clamp(0.3, 1.0);
    final sectionTransform = (_scrollOffset * 0.05).clamp(0.0, 20.0);
    
    return Transform.translate(
      offset: Offset(0, sectionTransform),
      child: Opacity(
        opacity: sectionOpacity,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.8),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _parallaxController,
                    curve: Interval(0.3, 1.0, curve: Curves.easeOutCubic),
                  )),
                  child: Row(
                    children: [
                      AnimatedBuilder(
                        animation: _floatingController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _floatingController.value * 3),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    MujiTheme.paper,
                                    MujiTheme.paper.withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: MujiTheme.clay.withOpacity(0.3),
                                  width: 0.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 12,
                                    offset: const Offset(0, 3),
                                  ),
                                  BoxShadow(
                                    color: MujiTheme.clay.withOpacity(0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '📖',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '맞춤 추천',
                                    style: MujiTheme.mobileLabel.copyWith(
                                      color: MujiTheme.bark,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '당신을 위한 선별된 글',
                          style: MujiTheme.mobileH3.copyWith(
                            fontWeight: FontWeight.w700,
                            color: MujiTheme.textDark,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _parallaxController,
                  curve: Interval(0.4, 1.0, curve: Curves.easeOutCubic),
                )),
                child: SizedBox(
                  height: 200,
                  child: ListView.builder(
                    controller: _booksScrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _personalizedArticles.length,
                    itemBuilder: (context, index) {
                      final article = _personalizedArticles[index];
                      return TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 600 + (index * 100)),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, (1 - value) * 30),
                            child: Opacity(
                              opacity: value,
                              child: _buildModernBookCard(article, index),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernBookCard(Map<String, dynamic> article, int index) {
    // 현대적인 커버플로우 효과를 위한 계산
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = 140.0;
    final cardPosition = (index * cardWidth) - _booksScrollOffset;
    final screenCenter = screenWidth / 2;
    final distanceFromCenter = (cardPosition + cardWidth / 2 - screenCenter).abs();
    final maxDistance = screenWidth / 2;
    final normalizedDistance = (distanceFromCenter / maxDistance).clamp(0.0, 1.0);
    
    // 중앙에 가까울수록 크게, 멀수록 작게
    final scale = 1.0 - (normalizedDistance * 0.25);
    final opacity = 1.0 - (normalizedDistance * 0.3);
    final perspective = normalizedDistance * 0.3;
    
    return StatefulBuilder(
      builder: (context, setState) {
        bool isPressed = false;
        
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _navigateToArticleDetail(article);
          },
          onTapDown: (_) => setState(() => isPressed = true),
          onTapUp: (_) => setState(() => isPressed = false),
          onTapCancel: () => setState(() => isPressed = false),
          child: Container(
            width: cardWidth,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // perspective
                ..scale(scale * (isPressed ? 0.95 : 1.0))
                ..rotateY(perspective * (cardPosition > screenCenter ? -1 : 1))
                ..translate(0.0, isPressed ? 4.0 : 0.0),
              child: Opacity(
                opacity: opacity,
                child: Column(
                  children: [
                    // 현대적인 책 표지
                    Container(
                      width: cardWidth,
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10 + (5 * (1 - normalizedDistance)),
                            offset: Offset(0, 5 + (3 * (1 - normalizedDistance))),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            // 책 배경 - 더 미묘한 그라데이션
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    article['bookColor'] as Color,
                                    (article['bookColor'] as Color).withOpacity(0.9),
                                  ],
                                ),
                              ),
                            ),
                            
                            // 미묘한 노이즈 텍스처
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.1),
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.05),
                                  ],
                                ),
                              ),
                            ),
                            
                            // 책 내용
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 카테고리
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (article['textColor'] as Color).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      article['category'],
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: article['textColor'] as Color,
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  // 제목
                                  Expanded(
                                    child: Text(
                                      article['title'],
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: article['textColor'] as Color,
                                        height: 1.3,
                                      ),
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  
                                  // 작가
                                  Text(
                                    article['author'],
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: (article['textColor'] as Color).withOpacity(0.8),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  
                                  const SizedBox(height: 4),
                                  
                                  // 읽기 시간
                                  Text(
                                    article['readTime'],
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: (article['textColor'] as Color).withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // 책 제목 (하단)
                    Text(
                      article['spine'],
                      style: MujiTheme.mobileCaption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: MujiTheme.textBody.withOpacity(opacity),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookCard(Map<String, dynamic> article, int index) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
        
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _navigateToArticleDetail(article);
          },
          onTapDown: (_) => setState(() => isHovered = true),
          onTapUp: (_) => setState(() => isHovered = false),
          onTapCancel: () => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: 110,
            margin: EdgeInsets.only(right: index == _personalizedArticles.length - 1 ? 0 : 16),
            transform: Matrix4.identity()
              ..scale(isHovered ? 1.05 : 1.0)
              ..translate(0.0, isHovered ? -4.0 : 0.0),
            child: Column(
              children: [
                // 책 표지
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: 110,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isHovered ? 0.25 : 0.15),
                        blurRadius: isHovered ? 20 : 12,
                        offset: Offset(isHovered ? 4 : 2, isHovered ? 8 : 4),
                      ),
                      BoxShadow(
                        color: (article['bookColor'] as Color).withOpacity(isHovered ? 0.2 : 0.1),
                        blurRadius: isHovered ? 16 : 8,
                        offset: const Offset(0, 2),
                      ),
                      // 내부 발광 효과
                      BoxShadow(
                        color: (article['bookColor'] as Color).withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // 책 배경 - 그라데이션 추가
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              article['bookColor'] as Color,
                              (article['bookColor'] as Color).withOpacity(0.85),
                              (article['bookColor'] as Color),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      
                      // 책 척추 라인 - 더 세련되게
                      Positioned(
                        left: 10,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 1.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                (article['textColor'] as Color).withOpacity(0.2),
                                (article['textColor'] as Color).withOpacity(0.4),
                                (article['textColor'] as Color).withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                      
                      // 종이 질감 및 광택 오버레이
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(isHovered ? 0.2 : 0.15),
                              Colors.transparent,
                              Colors.black.withOpacity(isHovered ? 0.08 : 0.05),
                            ],
                            stops: const [0.0, 0.6, 1.0],
                          ),
                        ),
                      ),
                      
                      // 미묘한 내부 하이라이트
                      Positioned(
                        top: 8,
                        left: 8,
                        right: 8,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                  
                      // 책 내용
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 카테고리 - 더 세련된 디자인
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    (article['textColor'] as Color).withOpacity(0.15),
                                    (article['textColor'] as Color).withOpacity(0.08),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: (article['textColor'] as Color).withOpacity(0.1),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                article['category'],
                                style: MujiTheme.mobileLabel.copyWith(
                                  color: article['textColor'] as Color,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 10),
                            
                            // 제목 - 더 나은 타이포그래피
                            Expanded(
                              child: Text(
                                article['title'],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: article['textColor'] as Color,
                                  height: 1.25,
                                  letterSpacing: -0.3,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 2,
                                      offset: const Offset(0, 0.5),
                                    ),
                                  ],
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // 작가 & 페이지 정보 - 더 정교한 스타일링
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: (article['textColor'] as Color).withOpacity(0.15),
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    article['author'],
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: (article['textColor'] as Color).withOpacity(0.85),
                                      letterSpacing: 0.1,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        '${article['pages']}p',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w500,
                                          color: (article['textColor'] as Color).withOpacity(0.7),
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        width: 1,
                                        height: 8,
                                        color: (article['textColor'] as Color).withOpacity(0.3),
                                      ),
                                      Text(
                                        article['readTime'],
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w500,
                                          color: (article['textColor'] as Color).withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // 책 제목 (하단) - 더 세련되게
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: MujiTheme.mobileCaption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isHovered ? MujiTheme.sage : MujiTheme.textBody,
                    fontSize: 11,
                    letterSpacing: 0.2,
                    shadows: isHovered ? [
                      Shadow(
                        color: MujiTheme.sage.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ] : [],
                  ),
                  child: Text(
                    article['spine'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToArticleDetail(Map<String, dynamic> article) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => ArticleDetailScreen(
          articleId: article['id']?.toString() ?? '',
          article: null, // We'll load the article in the detail screen
        ),
      ),
    );
  }

  Widget _buildEmailVerificationBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFf59e0b).withOpacity(0.1),
            const Color(0xFFf59e0b).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFf59e0b).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFf59e0b).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              CupertinoIcons.mail_solid,
              color: Color(0xFFf59e0b),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이메일 인증을 완료해주세요',
                  style: MujiTheme.mobileBody.copyWith(
                    fontWeight: FontWeight.w600,
                    color: MujiTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI 추천과 개인화 기능을 이용하려면 인증이 필요해요',
                  style: MujiTheme.mobileCaption.copyWith(
                    color: MujiTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _resendVerificationEmail(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFf59e0b),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              '재발송',
              style: MujiTheme.mobileCaption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIRecommendations() {
    return Transform.translate(
      offset: Offset(0, _scrollOffset * 0.02),
      child: Opacity(
        opacity: (1.0 - (_scrollOffset / 600)).clamp(0.4, 1.0),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.6),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _parallaxController,
                    curve: Interval(0.6, 1.0, curve: Curves.easeOutCubic),
                  )),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              MujiTheme.sage.withOpacity(0.15),
                              MujiTheme.moss.withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: MujiTheme.sage.withOpacity(0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [MujiTheme.sage, MujiTheme.moss],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.sparkles,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'AI가 엄선한',
                              style: MujiTheme.mobileLabel.copyWith(
                                color: MujiTheme.sage,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '깊이 있는 통찰',
                          style: MujiTheme.mobileH3.copyWith(
                            fontWeight: FontWeight.w700,
                            color: MujiTheme.textDark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: MujiTheme.paper.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '전체보기',
                          style: MujiTheme.mobileLabel.copyWith(
                            color: MujiTheme.bark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.8),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _parallaxController,
                  curve: Interval(0.7, 1.0, curve: Curves.easeOutCubic),
                )),
                child: SizedBox(
                  height: 320,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _featuredArticles.length,
                    itemBuilder: (context, index) {
                      return TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 800 + (index * 150)),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, (1 - value) * 40),
                            child: Opacity(
                              opacity: value,
                              child: _buildModernFeaturedCard(_featuredArticles[index], index),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernFeaturedCard(Map<String, dynamic> article, int index) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
        
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            // TODO: 글 상세 페이지로 이동
          },
          onTapDown: (_) => setState(() => isHovered = true),
          onTapUp: (_) => setState(() => isHovered = false),
          onTapCancel: () => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: 280,
            margin: EdgeInsets.only(
              right: index == _featuredArticles.length - 1 ? 0 : 20,
            ),
            transform: Matrix4.identity()
              ..scale(isHovered ? 1.02 : 1.0)
              ..translate(0.0, isHovered ? -6.0 : 0.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (article['color'] as Color).withOpacity(isHovered ? 0.15 : 0.08),
                    blurRadius: isHovered ? 24 : 16,
                    offset: Offset(0, isHovered ? 12 : 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topLeft,
                      radius: 1.5,
                      colors: [
                        article['color'] as Color,
                        (article['color'] as Color).withOpacity(0.8),
                        (article['color'] as Color).withOpacity(0.9),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // 배경 패턴
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _ModernPatternPainter(
                            color: Colors.white.withOpacity(0.03),
                          ),
                        ),
                      ),
                      
                      // 컨텐츠
                      Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    article['category'],
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Text(
                                      article['image'],
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            Text(
                              article['title'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.3,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            const SizedBox(height: 12),
                            
                            Text(
                              article['description'],
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.85),
                                height: 1.5,
                                letterSpacing: 0.1,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            const Spacer(),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    article['author'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    article['readTime'],
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeaturedArticleCard(Map<String, dynamic> article, int index) {
    return Container(
      width: 280,
      margin: EdgeInsets.only(right: index == _featuredArticles.length - 1 ? 0 : 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (article['color'] as Color).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                article['color'] as Color,
                (article['color'] as Color).withOpacity(0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              // 패턴 오버레이
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              // 컨텐츠
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            article['category'],
                            style: MujiTheme.mobileLabel.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          article['image'],
                          style: const TextStyle(fontSize: 24),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      article['title'],
                      style: MujiTheme.mobileH3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article['description'],
                      style: MujiTheme.mobileCaption.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          article['author'],
                          style: MujiTheme.mobileCaption.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            article['readTime'],
                            style: MujiTheme.mobileLabel.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingAuthors() {
    return Consumer<FollowProvider>(
      builder: (context, followProvider, child) {
        final trendingAuthors = followProvider.trendingAuthors;
        final isLoading = followProvider.isLoadingTrending;
        final error = followProvider.error;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [MujiTheme.sage.withOpacity(0.1), MujiTheme.moss.withOpacity(0.05)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: MujiTheme.sage.withOpacity(0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '🔥',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '트렌딩',
                            style: MujiTheme.mobileLabel.copyWith(
                              color: MujiTheme.sage,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '주목받는 작가들',
                        style: MujiTheme.mobileH3.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!isLoading && trendingAuthors.isNotEmpty)
                      TextButton(
                        onPressed: () => _showAllAuthors(),
                        child: Text(
                          '전체보기',
                          style: MujiTheme.mobileCaption.copyWith(
                            color: MujiTheme.sage,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (isLoading)
                _buildTrendingAuthorsLoading()
              else if (error != null)
                _buildTrendingAuthorsError(error)
              else if (trendingAuthors.isEmpty)
                _buildTrendingAuthorsEmpty()
              else
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: trendingAuthors.length,
                    itemBuilder: (context, index) {
                      final author = trendingAuthors[index];
                      return _buildAuthorCard(author, index);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAuthorCard(Author author, int index) {
    return Consumer<FollowProvider>(
      builder: (context, followProvider, child) {
        final isFollowing = followProvider.isFollowing(author.id);
        final isLoading = followProvider.isFollowingInProgress(author.id);
        final followerCount = author.stats?.followerCount ?? 0;
        
        return GestureDetector(
          onTap: () => _navigateToAuthorDetail(author),
          child: Container(
            width: 220,
            margin: EdgeInsets.only(right: index == followProvider.trendingAuthors.length - 1 ? 0 : 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MujiTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: MujiTheme.border,
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // 프로필 이미지 또는 기본 아바타
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [MujiTheme.sage, MujiTheme.moss],
                        ),
                      ),
                      child: author.profileImageUrl?.isNotEmpty == true
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                author.profileImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
                              ),
                            )
                          : _buildDefaultAvatar(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            author.displayName,
                            style: MujiTheme.mobileBody.copyWith(
                              fontWeight: FontWeight.w600,
                              color: MujiTheme.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          if (author.specialties.isNotEmpty)
                            Text(
                              author.specialties.first,
                              style: MujiTheme.mobileCaption.copyWith(
                                color: MujiTheme.textLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // 작가 정보
                if (author.bio?.isNotEmpty == true)
                  Text(
                    author.bio!,
                    style: MujiTheme.mobileCaption.copyWith(
                      color: MujiTheme.textBody,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                
                const SizedBox(height: 12),
                
                // 팔로워 수와 팔로우 버튼
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatFollowerCount(followerCount),
                            style: MujiTheme.mobileBody.copyWith(
                              fontWeight: FontWeight.w700,
                              color: MujiTheme.textDark,
                            ),
                          ),
                          Text(
                            '팔로워',
                            style: MujiTheme.mobileLabel.copyWith(
                              color: MujiTheme.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // 팔로우 버튼
                    GestureDetector(
                      onTap: isLoading ? null : () => _toggleFollow(author.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isFollowing ? MujiTheme.textLight : MujiTheme.sage,
                          borderRadius: BorderRadius.circular(20),
                          border: isFollowing ? Border.all(
                            color: MujiTheme.border,
                            width: 0.5,
                          ) : null,
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    isFollowing ? MujiTheme.textBody : Colors.white,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isFollowing ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                                    size: 14,
                                    color: isFollowing ? MujiTheme.textBody : Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isFollowing ? '팔로잉' : '팔로우',
                                    style: MujiTheme.mobileLabel.copyWith(
                                      color: isFollowing ? MujiTheme.textBody : Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// 기본 아바타 위젯
  Widget _buildDefaultAvatar() {
    return const Icon(
      CupertinoIcons.person_fill,
      color: Colors.white,
      size: 20,
    );
  }
  
  /// 팔로워 수 포맷팅
  String _formatFollowerCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

  Widget _buildCategoryExploration() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '관심사별 탐색',
              style: MujiTheme.mobileH3.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return _buildCategoryCard(category);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _exploreCategoryPage(category['name']);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (category['color'] as Color).withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (category['color'] as Color).withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  category['icon'],
                  style: const TextStyle(fontSize: 24),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (category['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    category['count'],
                    style: MujiTheme.mobileLabel.copyWith(
                      color: category['color'] as Color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              category['name'],
              style: MujiTheme.mobileBody.copyWith(
                fontWeight: FontWeight.w600,
                color: MujiTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReads() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '최근 읽은 글',
            style: MujiTheme.mobileH3.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: MujiTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: MujiTheme.border,
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: MujiTheme.sage.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    CupertinoIcons.book_circle,
                    size: 32,
                    color: MujiTheme.sage,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '아직 읽은 글이 없어요',
                  style: MujiTheme.mobileBody.copyWith(
                    fontWeight: FontWeight.w600,
                    color: MujiTheme.textBody,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '첫 번째 글을 읽고 지식의 여정을 시작해보세요',
                  style: MujiTheme.mobileCaption.copyWith(
                    color: MujiTheme.textLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: MujiTheme.bg.withOpacity(0.95),
          border: Border(
            top: BorderSide(
              color: MujiTheme.border.withOpacity(0.3),
              width: 0.5,
            ),
          ),
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: SafeArea(
              top: false,
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNavItem(0, CupertinoIcons.house_fill, '홈'),
                    _buildNavItem(1, CupertinoIcons.compass_fill, '탐색'),
                    _buildNavItem(2, CupertinoIcons.bookmark_fill, '보관함'),
                    _buildNavItem(3, CupertinoIcons.person_fill, '프로필'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentTab == index;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _currentTab = index);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? MujiTheme.sage : MujiTheme.textLight,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: MujiTheme.mobileLabel.copyWith(
                color: isSelected ? MujiTheme.sage : MujiTheme.textLight,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 액션 메서드들
  void _showSearchScreen() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const SearchScreen(),
      ),
    );
  }

  void _showNotifications() {
    // TODO: 알림 화면 구현
    HapticFeedback.lightImpact();
  }

  void _showAllRecommendations() {
    // TODO: 전체 AI 추천 화면 구현
    HapticFeedback.lightImpact();
  }

  void _showAllAuthors() {
    // TODO: 전체 작가 목록 화면 구현
    HapticFeedback.lightImpact();
  }
  
  /// 작가 상세 화면으로 이동
  void _navigateToAuthorDetail(Author author) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => AuthorDetailScreen(
          authorId: author.id,
          initialAuthor: author,
        ),
      ),
    );
  }
  
  /// 팔로우 토글
  Future<void> _toggleFollow(String authorId) async {
    HapticFeedback.mediumImpact();
    
    try {
      final followProvider = context.read<FollowProvider>();
      final success = await followProvider.toggleFollow(authorId);
      
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(followProvider.error ?? '처리 중 오류가 발생했습니다'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('팔로우 처리 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
  
  /// 트렌딩 작가 로딩 상태
  Widget _buildTrendingAuthorsLoading() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 220,
            margin: EdgeInsets.only(right: index == 2 ? 0 : 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MujiTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: MujiTheme.border,
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: MujiTheme.sage.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 16,
                            decoration: BoxDecoration(
                              color: MujiTheme.sage.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 80,
                            height: 12,
                            decoration: BoxDecoration(
                              color: MujiTheme.sage.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: MujiTheme.sage.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 120,
                  height: 12,
                  decoration: BoxDecoration(
                    color: MujiTheme.sage.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 16,
                            decoration: BoxDecoration(
                              color: MujiTheme.sage.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 30,
                            height: 12,
                            decoration: BoxDecoration(
                              color: MujiTheme.sage.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 32,
                      decoration: BoxDecoration(
                        color: MujiTheme.sage.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  /// 트렌딩 작가 에러 상태
  Widget _buildTrendingAuthorsError(String error) {
    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MujiTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: MujiTheme.border,
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 32,
            color: MujiTheme.textLight,
          ),
          const SizedBox(height: 8),
          Text(
            '작가 정보를 불러올 수 없습니다',
            style: MujiTheme.mobileCaption.copyWith(
              color: MujiTheme.textBody,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            error,
            style: MujiTheme.mobileLabel.copyWith(
              color: MujiTheme.textLight,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadTrendingAuthors,
            child: Text(
              '다시 시도',
              style: MujiTheme.mobileCaption.copyWith(
                color: MujiTheme.sage,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 트렌딩 작가 빈 상태
  Widget _buildTrendingAuthorsEmpty() {
    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MujiTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: MujiTheme.border,
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.person_3,
            size: 32,
            color: MujiTheme.textLight,
          ),
          const SizedBox(height: 8),
          Text(
            '아직 트렌딩 작가가 없습니다',
            style: MujiTheme.mobileCaption.copyWith(
              color: MujiTheme.textBody,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '곧 멋진 작가들을 만나보실 수 있어요',
            style: MujiTheme.mobileLabel.copyWith(
              color: MujiTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  void _exploreCategoryPage(String categoryName) {
    // TODO: 카테고리별 탐색 화면 구현
    HapticFeedback.lightImpact();
  }

  void _resendVerificationEmail() async {
    HapticFeedback.lightImpact();
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.resendVerificationEmail();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('인증 메일을 다시 발송했습니다'),
            backgroundColor: MujiTheme.sage,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('메일 발송 실패: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: MujiTheme.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: MujiTheme.textHint.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(CupertinoIcons.person_circle, color: MujiTheme.textBody),
                title: Text('프로필 설정', style: MujiTheme.mobileBody),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: 프로필 화면
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.heart, color: MujiTheme.textBody),
                title: Text('관심사 설정', style: MujiTheme.mobileBody),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: 관심사 설정 화면
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.gear, color: MujiTheme.textBody),
                title: Text('앱 설정', style: MujiTheme.mobileBody),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: 설정 화면
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(CupertinoIcons.square_arrow_right, color: Colors.red),
                title: Text('로그아웃', style: MujiTheme.mobileBody.copyWith(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  final authProvider = context.read<AuthProvider>();
                  await authProvider.logout();
                  if (mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// 현대적인 패턴을 그리는 커스텀 페인터
class _ModernPatternPainter extends CustomPainter {
  final Color color;
  
  _ModernPatternPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    
    // 미묘한 기하학적 패턴
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 12; j++) {
        final x = (size.width / 8) * i;
        final y = (size.height / 12) * j;
        
        // 작은 원들
        canvas.drawCircle(
          Offset(x, y),
          1.0,
          paint,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}