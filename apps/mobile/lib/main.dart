import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:async';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFFCFBF7),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const PaperlyApp());
}

class PaperlyApp extends StatelessWidget {
  const PaperlyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paperly',
      theme: MujiTheme.light,
      home: const MobileHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// MUJI 테마
class MujiTheme {
  static const bg = Color(0xFFFCFBF7);
  static const surface = Color(0xFFF9F7F3);
  static const card = Color(0xFFFEFDFC);
  
  static const textDark = Color(0xFF2C2C2C);
  static const textBody = Color(0xFF4A4A4A);
  static const textLight = Color(0xFF7A7A7A);
  static const textHint = Color(0xFFB0B0B0);
  
  static const sage = Color(0xFF90A990);
  static const sand = Color(0xFFD4A09A);
  static const moss = Color(0xFFA8B8A0);
  static const clay = Color(0xFFCBB5A0);
  static const ocean = Color(0xFF9ABFD4);
  static const lavender = Color(0xFFB5A0CB);
  
  static ThemeData get light => ThemeData(
    fontFamily: '.SF Pro Text',
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.light(
      primary: sage,
      secondary: sand,
      surface: surface,
      background: bg,
    ),
  );
  
  static const mobileH1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.2,
    color: textDark,
  );
  
  static const mobileH2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
    color: textDark,
  );
  
  static const mobileH3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.2,
    height: 1.4,
    color: textDark,
  );
  
  static const mobileBody = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.6,
    color: textBody,
  );
  
  static const mobileCaption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.4,
    color: textLight,
  );
  
  static const mobileLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: textLight,
  );
}

// 메인 홈
class MobileHome extends StatefulWidget {
  const MobileHome({Key? key}) : super(key: key);

  @override
  State<MobileHome> createState() => _MobileHomeState();
}

class _MobileHomeState extends State<MobileHome> 
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  final ScrollController _scrollController = ScrollController();
  
  int _currentTab = 0;
  double _scrollOffset = 0;
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;
    final width = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: MujiTheme.bg,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: safeTop + 56),
              ),
              
              SliverToBoxAdapter(
                child: _buildGreeting(),
              ),
              
              SliverToBoxAdapter(
                child: _buildTodaysPicks(width),
              ),
              
              SliverToBoxAdapter(
                child: _buildCategories(),
              ),
              
              SliverToBoxAdapter(
                child: _buildRecentReads(),
              ),
              
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
          
          _buildAppBar(safeTop),
          _buildBottomNav(),
        ],
      ),
    );
  }
  
  Widget _buildAppBar(double safeTop) {
    final isScrolled = _scrollOffset > 20;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: safeTop + 56,
      decoration: BoxDecoration(
        color: isScrolled 
            ? MujiTheme.bg.withOpacity(0.9)
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
                  Text(
                    'Paperly',
                    style: MujiTheme.mobileH3.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => HapticFeedback.lightImpact(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: MujiTheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.search,
                        size: 20,
                        color: MujiTheme.textBody,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? '좋은 아침이에요' : 
                    hour < 18 ? '좋은 오후예요' : '편안한 저녁이에요';
    
    return FadeTransition(
      opacity: _fadeController,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: MujiTheme.mobileH1,
            ),
            const SizedBox(height: 4),
            Text(
              '오늘의 지식을 만나보세요',
              style: MujiTheme.mobileCaption,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTodaysPicks(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: MujiTheme.sage.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.sparkles,
                      size: 14,
                      color: MujiTheme.sage,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '오늘의 추천',
                      style: MujiTheme.mobileLabel.copyWith(
                        color: MujiTheme.sage,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: screenWidth * 0.9,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.85),
            itemCount: todaysPapers.length,
            itemBuilder: (context, index) {
              return _buildPaperCard(todaysPapers[index], index);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildPaperCard(Paper paper, int index) {
    return GestureDetector(
      onTap: () => _openFloatingReader(paper),
      child: AnimatedBuilder(
        animation: _fadeController,
        builder: (context, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: _fadeController,
              curve: Interval(
                index * 0.1,
                0.5 + index * 0.1,
                curve: Curves.easeOut,
              ),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: MujiTheme.card,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            paper.color.withOpacity(0.7),
                            paper.color.withOpacity(0.3),
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          CustomPaint(
                            painter: MobilePatternPainter(
                              color: Colors.white.withOpacity(0.1),
                            ),
                            size: Size.infinite,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    paper.category.toUpperCase(),
                                    style: MujiTheme.mobileLabel.copyWith(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  paper.title,
                                  style: MujiTheme.mobileH2.copyWith(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            paper.summary,
                            style: MujiTheme.mobileCaption,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: MujiTheme.surface,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    paper.author[0],
                                    style: MujiTheme.mobileCaption.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      paper.author,
                                      style: MujiTheme.mobileCaption.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: MujiTheme.textDark,
                                      ),
                                    ),
                                    Text(
                                      '${paper.readTime}분',
                                      style: MujiTheme.mobileLabel,
                                    ),
                                  ],
                                ),
                              ),
                              if (paper.progress > 0)
                                CircularProgressIndicator(
                                  value: paper.progress,
                                  strokeWidth: 2,
                                  backgroundColor: MujiTheme.textHint.withOpacity(0.2),
                                  valueColor: AlwaysStoppedAnimation(paper.color),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildCategories() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '카테고리',
            style: MujiTheme.mobileH3,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return GestureDetector(
                  onTap: () => HapticFeedback.lightImpact(),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          category.icon,
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category.name,
                          style: MujiTheme.mobileLabel,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecentReads() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '최근 읽은 글',
                style: MujiTheme.mobileH3,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: MujiTheme.sand.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${recentPapers.length}',
                  style: MujiTheme.mobileLabel.copyWith(
                    color: MujiTheme.sand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recentPapers.map((paper) => _buildRecentItem(paper)),
        ],
      ),
    );
  }
  
  Widget _buildRecentItem(Paper paper) {
    return GestureDetector(
      onTap: () => _openFloatingReader(paper),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MujiTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: MujiTheme.textHint.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    paper.color.withOpacity(0.3),
                    paper.color.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  paper.category[0],
                  style: MujiTheme.mobileBody.copyWith(
                    color: paper.color,
                    fontWeight: FontWeight.w600,
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
                    paper.title,
                    style: MujiTheme.mobileBody.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        paper.author,
                        style: MujiTheme.mobileLabel,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '·',
                        style: MujiTheme.mobileLabel,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${paper.readTime}분',
                        style: MujiTheme.mobileLabel,
                      ),
                    ],
                  ),
                  if (paper.progress > 0) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: paper.progress,
                        minHeight: 3,
                        backgroundColor: MujiTheme.textHint.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation(paper.color),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: MujiTheme.textHint,
            ),
          ],
        ),
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
          color: MujiTheme.bg,
          border: Border(
            top: BorderSide(
              color: MujiTheme.textHint.withOpacity(0.1),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Container(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, CupertinoIcons.house_fill, '홈'),
                _buildNavItem(1, CupertinoIcons.compass, '발견'),
                _buildNavItem(2, Icons.hub_outlined, 'Brain', isSpecial: true),
                _buildNavItem(3, CupertinoIcons.bookmark, '보관'),
                _buildNavItem(4, CupertinoIcons.person, '나'),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildNavItem(int index, IconData icon, String label, {bool isSpecial = false}) {
    final isSelected = _currentTab == index;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (index == 2) {
          _openBrainView();
        } else {
          setState(() => _currentTab = index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isSpecial ? 36 : 24,
              height: isSpecial ? 36 : 24,
              decoration: isSpecial ? BoxDecoration(
                gradient: LinearGradient(
                  colors: [MujiTheme.lavender, MujiTheme.ocean],
                ),
                shape: BoxShape.circle,
              ) : null,
              child: Icon(
                icon,
                size: isSpecial ? 20 : 24,
                color: isSpecial 
                    ? Colors.white 
                    : (isSelected ? MujiTheme.sage : MujiTheme.textLight),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: MujiTheme.mobileLabel.copyWith(
                color: isSpecial 
                    ? MujiTheme.lavender 
                    : (isSelected ? MujiTheme.sage : MujiTheme.textLight),
                fontWeight: isSelected || isSpecial ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _openFloatingReader(Paper paper) {
    HapticFeedback.mediumImpact();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => FloatingReader(paper: paper),
    );
  }
  
  void _openBrainView() {
    HapticFeedback.mediumImpact();
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BrainView(),
      ),
    );
  }
}

// Brain View - 옵시디언 스타일 지식 그래프
class BrainView extends StatefulWidget {
  const BrainView({Key? key}) : super(key: key);

  @override
  State<BrainView> createState() => _BrainViewState();
}

class _BrainViewState extends State<BrainView> 
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _nodeAnimationController;
  
  final TransformationController _transformationController = TransformationController();
  Offset _centerOffset = Offset.zero;
  
  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _nodeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }
  
  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _nodeAnimationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // 배경 그라디언트
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  MujiTheme.lavender.withOpacity(0.05),
                  const Color(0xFF0A0A0A),
                ],
              ),
            ),
          ),
          
          // 지식 그래프
          InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(100),
            minScale: 0.5,
            maxScale: 3,
            child: Container(
              width: MediaQuery.of(context).size.width * 3,
              height: MediaQuery.of(context).size.height * 3,
              child: CustomPaint(
                painter: KnowledgeGraphPainter(
                  rotationAnimation: _rotationController,
                  pulseAnimation: _pulseController,
                  nodeAnimation: _nodeAnimationController,
                ),
              ),
            ),
          ),
          
          // 상단 UI
          SafeArea(
            child: Column(
              children: [
                // 헤더
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            CupertinoIcons.back,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'My Knowledge Brain',
                        style: MujiTheme.mobileH3.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 통계
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('활성 노드', '12', MujiTheme.sage),
                      _buildStat('연결', '28', MujiTheme.ocean),
                      _buildStat('성장률', '+15%', MujiTheme.lavender),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: MujiTheme.mobileH2.copyWith(
            color: color,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: MujiTheme.mobileCaption.copyWith(
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

// 지식 그래프 페인터
class KnowledgeGraphPainter extends CustomPainter {
  final Animation<double> rotationAnimation;
  final Animation<double> pulseAnimation;
  final Animation<double> nodeAnimation;
  
  KnowledgeGraphPainter({
    required this.rotationAnimation,
    required this.pulseAnimation,
    required this.nodeAnimation,
  }) : super(
    repaint: Listenable.merge([
      rotationAnimation,
      pulseAnimation,
      nodeAnimation,
    ]),
  );
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;
    
    // 노드 데이터
    final nodes = [
      KnowledgeNode('미니멀리즘', MujiTheme.sage, 0.9, 0),
      KnowledgeNode('지속가능성', MujiTheme.moss, 0.8, 1),
      KnowledgeNode('디지털 디톡스', MujiTheme.ocean, 0.7, 2),
      KnowledgeNode('웰빙', MujiTheme.sand, 0.6, 3),
      KnowledgeNode('창의성', MujiTheme.lavender, 0.5, 4),
      KnowledgeNode('철학', MujiTheme.clay, 0.7, 5),
      KnowledgeNode('환경', MujiTheme.moss, 0.9, 6),
      KnowledgeNode('예술', MujiTheme.lavender, 0.4, 7),
      KnowledgeNode('건강', MujiTheme.sage, 0.6, 8),
      KnowledgeNode('기술', MujiTheme.ocean, 0.3, 9),
      KnowledgeNode('문학', MujiTheme.sand, 0.5, 10),
      KnowledgeNode('과학', MujiTheme.ocean, 0.4, 11),
    ];
    
    // 연결선 그리기
    final connectionPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(0.1);
    
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        if ((i + j) % 3 == 0) { // 일부 노드만 연결
          final node1 = nodes[i];
          final node2 = nodes[j];
          
          final angle1 = (node1.position / nodes.length) * 2 * math.pi + 
                        rotationAnimation.value * 2 * math.pi * 0.1;
          final angle2 = (node2.position / nodes.length) * 2 * math.pi + 
                        rotationAnimation.value * 2 * math.pi * 0.1;
          
          final radius1 = 100 + node1.position * 15;
          final radius2 = 100 + node2.position * 15;
          
          final pos1 = center + Offset(
            math.cos(angle1) * radius1,
            math.sin(angle1) * radius1,
          );
          
          final pos2 = center + Offset(
            math.cos(angle2) * radius2,
            math.sin(angle2) * radius2,
          );
          
          canvas.drawLine(pos1, pos2, connectionPaint);
        }
      }
    }
    
    // 노드 그리기
    for (final node in nodes) {
      final angle = (node.position / nodes.length) * 2 * math.pi + 
                   rotationAnimation.value * 2 * math.pi * 0.1;
      final radius = 100 + node.position * 15;
      
      final nodePos = center + Offset(
        math.cos(angle) * radius,
        math.sin(angle) * radius,
      );
      
      // 활성 노드 광선 효과
      if (node.activity > 0.7) {
        final glowPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              node.color.withOpacity(0.3 * pulseAnimation.value),
              node.color.withOpacity(0),
            ],
          ).createShader(Rect.fromCircle(
            center: nodePos,
            radius: 40 + pulseAnimation.value * 10,
          ));
        
        canvas.drawCircle(
          nodePos,
          40 + pulseAnimation.value * 10,
          glowPaint,
        );
      }
      
      // 노드 원
      final nodeSize = 8 + node.activity * 12;
      paint.color = node.color;
      canvas.drawCircle(nodePos, nodeSize * nodeAnimation.value, paint);
      
      // 노드 테두리
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = node.color.withOpacity(0.3);
      canvas.drawCircle(nodePos, nodeSize * nodeAnimation.value + 5, borderPaint);
      
      // 레이블
      final textPainter = TextPainter(
        text: TextSpan(
          text: node.name,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        nodePos + Offset(-textPainter.width / 2, nodeSize + 10),
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 플로팅 리더
class FloatingReader extends StatefulWidget {
  final Paper paper;
  
  const FloatingReader({Key? key, required this.paper}) : super(key: key);
  
  @override
  State<FloatingReader> createState() => _FloatingReaderState();
}

class _FloatingReaderState extends State<FloatingReader> 
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _typewriterController;
  
  double _dragOffset = 0;
  double _dragVelocity = 0;
  String _displayedText = '';
  Timer? _typewriterTimer;
  int _currentIndex = 0;
  
  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..forward();
    
    _typewriterController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _startTypewriter();
  }
  
  void _startTypewriter() {
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_currentIndex < widget.paper.content.length) {
        setState(() {
          _displayedText = widget.paper.content.substring(0, _currentIndex + 1);
          _currentIndex++;
        });
      } else {
        timer.cancel();
        _typewriterController.forward();
      }
    });
  }
  
  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dy;
      _dragVelocity = details.delta.dy;
    });
  }
  
  void _handleDragEnd(DragEndDetails details) {
    // 빠르게 위로 던지면 닫기
    if (_dragOffset > 100 || details.velocity.pixelsPerSecond.dy > 800) {
      HapticFeedback.lightImpact();
      _slideController.reverse().then((_) {
        Navigator.of(context).pop();
      });
    } else {
      // 원위치로 스프링 애니메이션
      setState(() {
        _dragOffset = 0;
      });
    }
  }
  
  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _slideController.dispose();
    _typewriterController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return GestureDetector(
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      child: AnimatedBuilder(
        animation: _slideController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _dragOffset),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _slideController,
                curve: Curves.easeOutCubic,
              )),
              child: Container(
                height: screenHeight * 0.9,
                margin: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                ),
                decoration: BoxDecoration(
                  color: MujiTheme.card,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 드래그 핸들
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: MujiTheme.textHint.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    // 콘텐츠
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 헤더
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.paper.color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    widget.paper.category,
                                    style: MujiTheme.mobileLabel.copyWith(
                                      color: widget.paper.color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  CupertinoIcons.clock,
                                  size: 14,
                                  color: MujiTheme.textLight,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.paper.readTime}분',
                                  style: MujiTheme.mobileCaption,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // 제목
                            Text(
                              widget.paper.title,
                              style: MujiTheme.mobileH1,
                            ),
                            const SizedBox(height: 16),
                            
                            // 요약
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: MujiTheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: MujiTheme.textHint.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                widget.paper.summary,
                                style: MujiTheme.mobileCaption.copyWith(
                                  fontStyle: FontStyle.italic,
                                  height: 1.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // 작가 정보
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: widget.paper.color.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      widget.paper.author[0],
                                      style: MujiTheme.mobileBody.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: widget.paper.color,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  widget.paper.author,
                                  style: MujiTheme.mobileBody.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            
                            // 타이핑 애니메이션 본문
                            Stack(
                              children: [
                                Text(
                                  _displayedText,
                                  style: MujiTheme.mobileBody.copyWith(
                                    fontSize: 16,
                                    height: 1.8,
                                  ),
                                ),
                                // 커서
                                if (_currentIndex < widget.paper.content.length)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 2,
                                      height: 20,
                                      color: MujiTheme.textDark,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            
                            // 액션 버튼
                            FadeTransition(
                              opacity: _typewriterController,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildActionButton(
                                      '재생지에 출력',
                                      CupertinoIcons.printer,
                                      MujiTheme.sage,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildActionButton(
                                      '보관하기',
                                      CupertinoIcons.bookmark,
                                      MujiTheme.sand,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildActionButton(String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => HapticFeedback.mediumImpact(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: MujiTheme.mobileBody.copyWith(
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 페인터
class MobilePatternPainter extends CustomPainter {
  final Color color;
  
  MobilePatternPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    const spacing = 20.0;
    
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + 10, size.height),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 데이터 모델
class Paper {
  final String title;
  final String summary;
  final String content;
  final String category;
  final String author;
  final int readTime;
  final double progress;
  final Color color;
  
  Paper({
    required this.title,
    required this.summary,
    required this.content,
    required this.category,
    required this.author,
    required this.readTime,
    this.progress = 0,
    required this.color,
  });
}

class Category {
  final String name;
  final String icon;
  final Color color;
  
  Category({
    required this.name,
    required this.icon,
    required this.color,
  });
}

class KnowledgeNode {
  final String name;
  final Color color;
  final double activity;
  final int position;
  
  KnowledgeNode(this.name, this.color, this.activity, this.position);
}

// 샘플 데이터
final todaysPapers = [
  Paper(
    title: '미니멀 라이프의 시작',
    summary: '소유보다 경험을, 양보다 질을 추구하는 삶의 방식',
    content: '''미니멀리즘은 단순히 물건을 줄이는 것이 아닙니다. 그것은 삶의 본질을 찾아가는 여정입니다.

우리가 소유한 물건들은 때로 우리를 소유합니다. 관리하고, 정리하고, 걱정하는 시간들. 이 모든 것들이 정작 중요한 것들로부터 우리를 멀어지게 만듭니다.

미니멀 라이프의 핵심은 '의도적인 선택'입니다. 무엇을 가질 것인가보다 무엇을 갖지 않을 것인가를 결정하는 것. 이 과정에서 우리는 진정으로 가치 있는 것들을 발견하게 됩니다.''',
    category: '라이프',
    author: '김민수',
    readTime: 5,
    progress: 0.3,
    color: MujiTheme.sage,
  ),
  Paper(
    title: '종이의 온도',
    summary: '디지털 시대에 아날로그가 주는 특별한 가치',
    content: '''펜을 잡고 종이 위에 글을 쓸 때, 우리의 뇌에서는 특별한 일이 일어납니다.

디지털 기기의 차가운 화면과 달리, 종이는 따뜻함을 전합니다. 손끝으로 전해지는 질감, 펜이 지나간 자리에 남는 잉크의 흔적. 이 모든 것이 우리의 감각을 깨웁니다.

연구에 따르면 손글씨는 타이핑보다 기억력을 40% 이상 향상시킨다고 합니다. 느리지만 깊이 있는 사고가 가능해지는 것이죠.''',
    category: '에세이',
    author: '이서연',
    readTime: 8,
    progress: 0,
    color: MujiTheme.sand,
  ),
  Paper(
    title: '도시 속 자연',
    summary: '일상에서 만나는 작은 녹색 공간들',
    content: '''바쁜 도시 생활 속에서도 우리는 자연을 찾을 수 있습니다.

창가의 작은 화분, 출근길에 만나는 가로수, 점심시간에 들르는 공원. 이런 작은 자연들이 우리의 일상을 풍요롭게 만듭니다.

녹색을 보는 것만으로도 스트레스가 줄어들고 창의성이 향상된다는 연구 결과가 있습니다. 도시 속 자연은 우리에게 쉼표를 선물합니다.''',
    category: '환경',
    author: '박지원',
    readTime: 6,
    progress: 0,
    color: MujiTheme.moss,
  ),
];

final categories = [
  Category(name: '라이프', icon: '🌿', color: MujiTheme.sage),
  Category(name: '에세이', icon: '✍️', color: MujiTheme.sand),
  Category(name: '환경', icon: '🌍', color: MujiTheme.moss),
  Category(name: '웰빙', icon: '🧘', color: MujiTheme.clay),
  Category(name: '문화', icon: '🎨', color: MujiTheme.lavender),
];

final recentPapers = [
  Paper(
    title: '느린 삶의 미학',
    summary: '',
    content: '',
    category: '철학',
    author: '최현우',
    readTime: 10,
    progress: 0.7,
    color: MujiTheme.clay,
  ),
  Paper(
    title: '작은 습관의 힘',
    summary: '',
    content: '',
    category: '자기계발',
    author: '정유진',
    readTime: 7,
    progress: 0.2,
    color: MujiTheme.sand,
  ),
];