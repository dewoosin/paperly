import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../theme/muji_theme.dart';
import '../models/article_models.dart';
import '../services/article_service.dart';
import '../providers/auth_provider.dart';
import '../utils/logger.dart';

/// 글 상세 화면
/// 무지 톤앤매너의 따뜻한 독서 경험과 좋아요 기능 제공
class ArticleDetailScreen extends StatefulWidget {
  final String articleId;
  final Article? article;

  const ArticleDetailScreen({
    Key? key,
    required this.articleId,
    this.article,
  }) : super(key: key);

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  final ScrollController _scrollController = ScrollController();
  
  // 서비스 및 데이터 관리
  late ArticleService _articleService;
  Article? _article;
  LikeData? _likeData;
  bool _isLoading = true;
  String? _errorMessage;
  
  // UI 상태 관리
  bool _showFullContent = false;
  double _scrollOffset = 0;
  bool _isBookmarked = false;
  double _readingProgress = 0.0;

  // AI 요약본 데이터
  final Map<String, String> _aiSummaries = {
    'p1': '''
• 디지털 노마드 생활의 핵심은 '장소의 자유'가 아닌 '시간의 자주권'입니다.

• 성공적인 원격근무를 위한 3가지 원칙:
  - 명확한 업무 경계 설정
  - 효율적인 커뮤니케이션 도구 활용
  - 개인 루틴 확립

• 물리적 이동보다 중요한 것은 정신적 유연성과 적응력입니다.

• 다양한 환경에서 일하며 얻는 창의적 영감이 생산성을 높입니다.

• 지속가능한 노마드 라이프를 위해서는 재정 관리와 건강 관리가 필수입니다.
''',
    'p2': '''
• 마음챙김은 현재 순간에 집중하여 스트레스를 줄이는 실용적 기법입니다.

• 일상에서 실천할 수 있는 3분 명상법:
  - 호흡에 집중하기
  - 몸의 감각 느끼기
  - 감정 관찰하기

• 디지털 기기 사용 시간을 줄이고 자연과의 접촉을 늘리는 것이 중요합니다.

• 감정을 판단하지 않고 있는 그대로 받아들이는 연습이 필요합니다.

• 정기적인 마음챙김 실천으로 집중력과 창의성이 향상됩니다.
''',
    'p3': '''
• 지속가능한 소비는 환경보호와 개인의 행복을 동시에 추구하는 생활 방식입니다.

• 미니멀 라이프의 핵심 원칙:
  - 필요한 것과 원하는 것 구분하기
  - 품질 좋은 제품을 오래 사용하기
  - 재사용과 업사이클링 실천하기

• 과도한 소비 대신 경험과 관계에 투자하는 것이 진정한 풍요로움입니다.

• 환경을 고려한 선택이 개인의 가치관과 일치할 때 더 큰 만족을 얻습니다.

• 작은 변화들이 모여 큰 사회적 변화를 만들어낼 수 있습니다.
''',
    'p4': '''
• 창의성은 타고나는 것이 아닌 훈련을 통해 기를 수 있는 능력입니다.

• 창의적 사고를 위한 일상 습관:
  - 다양한 분야의 독서
  - 새로운 경험과 도전
  - 반대 관점에서 생각해보기

• 실패를 두려워하지 않고 실험하는 자세가 중요합니다.

• 혼자만의 시간과 다른 사람과의 협업, 두 가지 모두 필요합니다.

• 아이디어를 기록하고 조합하는 습관이 혁신을 만들어냅니다.
''',
    'p5': '''
• AI 시대에는 인간 고유의 창의성과 공감 능력이 더욱 중요해집니다.

• 기술 발전과 함께 성장하는 인간의 역할:
  - 복잡한 문제 해결과 의사결정
  - 감정과 관계의 이해와 소통
  - 윤리적 판단과 가치 설정

• AI와 협업하는 방법을 배워 생산성을 높이는 것이 필요합니다.

• 평생학습과 적응력이 미래 사회의 핵심 역량이 됩니다.

• 기술을 도구로 활용하되, 인간적 가치를 잃지 않는 균형이 중요합니다.
'''
  };

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
        // 읽기 진행률 계산 (대략적)
        if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
          _readingProgress = (_scrollController.offset / _scrollController.position.maxScrollExtent).clamp(0.0, 1.0);
        }
      });
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
              
              // 글 헤더 정보
              SliverToBoxAdapter(
                child: _buildArticleHeader(),
              ),
              
              // AI 요약본
              SliverToBoxAdapter(
                child: _buildAISummary(),
              ),
              
              // 전체 글 내용
              if (_showFullContent)
                SliverToBoxAdapter(
                  child: _buildFullContent(),
                )
              else
                SliverToBoxAdapter(
                  child: _buildReadFullButton(),
                ),
              
              // 관련 글 추천
              SliverToBoxAdapter(
                child: _buildRelatedArticles(),
              ),
              
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
          
          _buildAppBar(safeTop),
          _buildReadingProgress(),
        ],
      ),
    );
  }

  Widget _buildAppBar(double safeTop) {
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
                  // 뒤로가기
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
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
                      child: const Icon(
                        CupertinoIcons.back,
                        size: 20,
                        color: MujiTheme.textBody,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // 액션 버튼들
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _isBookmarked = !_isBookmarked;
                          });
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
                          child: Icon(
                            _isBookmarked 
                                ? CupertinoIcons.bookmark_fill 
                                : CupertinoIcons.bookmark,
                            size: 20,
                            color: _isBookmarked ? MujiTheme.sage : MujiTheme.textBody,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showShareSheet();
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
                          child: const Icon(
                            CupertinoIcons.share,
                            size: 20,
                            color: MujiTheme.textBody,
                          ),
                        ),
                      ),
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

  Widget _buildReadingProgress() {
    if (_scrollOffset < 100) return const SizedBox.shrink();
    
    return Positioned(
      top: MediaQuery.of(context).padding.top + 65,
      left: 20,
      right: 20,
      child: Container(
        height: 2,
        decoration: BoxDecoration(
          color: MujiTheme.border,
          borderRadius: BorderRadius.circular(1),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: _readingProgress,
          child: Container(
            decoration: BoxDecoration(
              color: MujiTheme.sage,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArticleHeader() {
    return FadeTransition(
      opacity: _fadeController,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 카테고리와 읽기 시간
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: MujiTheme.paper,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: MujiTheme.clay.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    widget.article['category'],
                    style: MujiTheme.mobileLabel.copyWith(
                      color: MujiTheme.bark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.article['readTime']} 읽기',
                  style: MujiTheme.mobileCaption.copyWith(
                    color: MujiTheme.textLight,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 제목
            Text(
              widget.article['title'],
              style: MujiTheme.mobileH1.copyWith(
                fontWeight: FontWeight.w700,
                color: MujiTheme.textDark,
                height: 1.3,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 작가 정보
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [MujiTheme.sage, MujiTheme.moss],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.person_fill,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.article['author'],
                        style: MujiTheme.mobileBody.copyWith(
                          fontWeight: FontWeight.w600,
                          color: MujiTheme.textDark,
                        ),
                      ),
                      Text(
                        '${widget.article['category']} 전문가',
                        style: MujiTheme.mobileCaption.copyWith(
                          color: MujiTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    // TODO: 작가 팔로우 기능
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: MujiTheme.sage,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    '팔로우',
                    style: MujiTheme.mobileCaption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // 글 요약
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MujiTheme.paper.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: MujiTheme.clay.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: Text(
                widget.article['summary'],
                style: MujiTheme.mobileBody.copyWith(
                  color: MujiTheme.textBody,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAISummary() {
    final summary = _aiSummaries[widget.article['id']] ?? '요약을 준비 중입니다...';
    final sectionOpacity = (1.0 - (_scrollOffset / 500)).clamp(0.5, 1.0);
    
    return Transform.translate(
      offset: Offset(0, _scrollOffset * 0.02),
      child: Opacity(
        opacity: sectionOpacity,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.6),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _fadeController,
                  curve: Interval(0.4, 1.0, curve: Curves.easeOutCubic),
                )),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            MujiTheme.sage.withOpacity(0.15),
                            MujiTheme.moss.withOpacity(0.1),
                            MujiTheme.sage.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: MujiTheme.sage.withOpacity(0.25),
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: MujiTheme.sage.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '🤖',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'AI 요약',
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
                        '핵심 내용을 빠르게 파악하세요',
                        style: MujiTheme.mobileH3.copyWith(
                          fontWeight: FontWeight.w700,
                          color: MujiTheme.textDark,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.8),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _fadeController,
                  curve: Interval(0.5, 1.0, curve: Curves.easeOutCubic),
                )),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        MujiTheme.surface,
                        MujiTheme.card,
                        MujiTheme.surface.withOpacity(0.8),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: MujiTheme.border.withOpacity(0.3),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: MujiTheme.sage.withOpacity(0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                      // 내부 발광 효과
                      BoxShadow(
                        color: Colors.white.withOpacity(0.8),
                        blurRadius: 1,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Text(
                      summary,
                      style: MujiTheme.mobileBody.copyWith(
                        color: MujiTheme.textBody,
                        height: 1.8,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 1,
                            offset: const Offset(0, 0.5),
                          ),
                        ],
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
  }

  Widget _buildReadFullButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _fadeController,
          curve: Interval(0.6, 1.0, curve: Curves.easeOutCubic),
        )),
        child: StatefulBuilder(
          builder: (context, setState) {
            bool isPressed = false;
            
            return GestureDetector(
              onTapDown: (_) => setState(() => isPressed = true),
              onTapUp: (_) => setState(() => isPressed = false),
              onTapCancel: () => setState(() => isPressed = false),
              onTap: () {
                HapticFeedback.lightImpact();
                this.setState(() {
                  _showFullContent = true;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                transform: Matrix4.identity()
                  ..scale(isPressed ? 0.98 : 1.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        MujiTheme.sage,
                        MujiTheme.sage.withOpacity(0.9),
                        MujiTheme.moss,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: MujiTheme.sage.withOpacity(isPressed ? 0.3 : 0.25),
                        blurRadius: isPressed ? 8 : 12,
                        offset: Offset(0, isPressed ? 2 : 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: isPressed ? 4 : 8,
                        offset: Offset(0, isPressed ? 1 : 2),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          CupertinoIcons.book_circle_fill,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '전체 글 읽기',
                        style: MujiTheme.mobileBody.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 16,
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${widget.article['readTime']}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
      ),
    );
  }

  Widget _buildFullContent() {
    // 실제로는 API에서 전체 글 내용을 가져와야 함
    final fullContent = '''
${widget.article['title']}에 대한 전체 내용입니다.

이곳에는 실제 글의 본문 내용이 들어갑니다. 현재는 임시 텍스트로 구성되어 있지만, 실제 구현 시에는 서버에서 마크다운이나 HTML 형태로 받아온 글 내용을 파싱하여 표시하게 됩니다.

글의 본문은 여러 단락으로 구성되며, 이미지나 인용구, 목록 등 다양한 형태의 콘텐츠를 포함할 수 있습니다.

무지 톤앤매너에 맞게 따뜻하고 자연스러운 느낌의 타이포그래피와 레이아웃을 사용하여 편안한 독서 경험을 제공합니다.

이 부분은 스크롤이 가능하며, 사용자가 편안하게 글을 읽을 수 있도록 적절한 줄 간격과 여백을 설정했습니다.

실제 구현에서는 다음과 같은 기능들이 추가될 수 있습니다:

• 텍스트 크기 조절
• 다크/라이트 모드 전환
• 읽기 위치 저장
• 하이라이트 및 메모 기능
• 음성 읽기 기능

이러한 기능들을 통해 사용자에게 더욱 풍부한 독서 경험을 제공할 수 있습니다.

무지의 철학인 "당연한 것을 당연하게"를 바탕으로, 복잡하지 않으면서도 사용자가 진정으로 필요로 하는 기능들을 제공하는 것이 중요합니다.

글의 마지막 부분입니다. 여기까지 읽어주셔서 감사합니다.
''';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '전체 글',
            style: MujiTheme.mobileH3.copyWith(
              fontWeight: FontWeight.w700,
              color: MujiTheme.textDark,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: MujiTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: MujiTheme.border.withOpacity(0.3),
                width: 0.5,
              ),
            ),
            child: Text(
              fullContent,
              style: MujiTheme.mobileBody.copyWith(
                color: MujiTheme.textBody,
                height: 1.8,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedArticles() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '관련 글 추천',
            style: MujiTheme.mobileH3.copyWith(
              fontWeight: FontWeight.w700,
              color: MujiTheme.textDark,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 임시 관련 글들
          ...List.generate(2, (index) {
            final relatedArticles = [
              {
                'title': '미니멀 라이프의 시작',
                'author': '김단순',
                'category': '라이프스타일',
                'readTime': '7분',
              },
              {
                'title': '현대인을 위한 명상 가이드',
                'author': '박평온',
                'category': '웰빙',
                'readTime': '9분',
              },
            ];
            
            final article = relatedArticles[index];
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MujiTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: MujiTheme.border.withOpacity(0.5),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: MujiTheme.paper,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.doc_text,
                      color: MujiTheme.bark,
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article['title']!,
                          style: MujiTheme.mobileBody.copyWith(
                            fontWeight: FontWeight.w600,
                            color: MujiTheme.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              article['author']!,
                              style: MujiTheme.mobileCaption.copyWith(
                                color: MujiTheme.textLight,
                              ),
                            ),
                            Text(
                              ' · ${article['readTime']}',
                              style: MujiTheme.mobileCaption.copyWith(
                                color: MujiTheme.textHint,
                              ),
                            ),
                          ],
                        ),
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
            );
          }),
        ],
      ),
    );
  }

  void _showShareSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
              
              Text(
                '공유하기',
                style: MujiTheme.mobileH3.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              
              const SizedBox(height: 20),
              
              ListTile(
                leading: const Icon(CupertinoIcons.link, color: MujiTheme.textBody),
                title: Text('링크 복사', style: MujiTheme.mobileBody),
                onTap: () {
                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                  // TODO: 링크 복사 기능
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