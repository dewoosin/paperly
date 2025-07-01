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
import '../widgets/muji_button.dart';

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
  late AnimationController _likeController;
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
  
  // 애니메이션
  late Animation<double> _fadeAnimation;
  late Animation<double> _likeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeServices();
    _setupScrollListener();
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _likeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 애니메이션 초기화
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _likeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _likeAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _likeController,
      curve: Curves.elasticOut,
    ));
    
    _fadeController.forward();
  }

  /// 서비스 초기화
  void _initializeServices() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _articleService = ArticleService(authProvider.dio);
  }

  /// 스크롤 리스너 설정
  void _setupScrollListener() {
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
        _readingProgress = (_scrollController.offset / 
            (_scrollController.position.maxScrollExtent)).clamp(0.0, 1.0);
      });
    });
  }

  /// 데이터 로드
  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // 전달받은 article이 있으면 사용, 없으면 API에서 로드
      if (widget.article != null) {
        _article = widget.article;
      } else {
        _article = await _articleService.getArticleDetail(widget.articleId);
      }

      // 로그인된 사용자의 경우 좋아요 상태 로드
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        _likeData = await _articleService.getLikeStatus(widget.articleId);
      }

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      Logger.error('기사 상세 정보 로드 실패', {
        'articleId': widget.articleId,
        'error': e.toString(),
      });

      setState(() {
        _isLoading = false;
        _errorMessage = '기사를 불러오는 중 오류가 발생했습니다.';
      });
    }
  }

  /// 좋아요 토글
  Future<void> _toggleLike() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그인이 필요합니다.'),
          backgroundColor: MujiTheme.warningColor,
        ),
      );
      return;
    }

    if (_article == null) return;

    HapticFeedback.lightImpact();
    _likeController.forward().then((_) => _likeController.reverse());

    try {
      final newLikeData = await _articleService.toggleLike(_article!.id);
      
      setState(() {
        _likeData = newLikeData;
        _article = _article!.copyWith(likeCount: newLikeData.likeCount);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newLikeData.liked ? '좋아요를 눌렀습니다.' : '좋아요를 취소했습니다.'),
          backgroundColor: newLikeData.liked ? MujiTheme.primaryColor : MujiTheme.secondaryTextColor,
          duration: Duration(milliseconds: 1500),
        ),
      );

    } catch (e) {
      Logger.error('좋아요 토글 실패', {
        'articleId': _article!.id,
        'error': e.toString(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('좋아요 처리 중 오류가 발생했습니다.'),
          backgroundColor: MujiTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MujiTheme.backgroundColor,
      body: _buildBody(),
    );
  }

  /// 메인 바디 구성
  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingIndicator();
    }

    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    if (_article == null) {
      return _buildErrorWidget();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  /// 로딩 인디케이터
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: MujiTheme.primaryColor,
            strokeWidth: 2,
          ),
          SizedBox(height: 16),
          Text(
            '기사를 불러오는 중...',
            style: MujiTheme.bodyMedium.copyWith(
              color: MujiTheme.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 에러 위젯
  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: MujiTheme.errorColor,
            ),
            SizedBox(height: 16),
            Text(
              _errorMessage ?? '기사를 찾을 수 없습니다.',
              style: MujiTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            MujiButton(
              text: '다시 시도',
              onPressed: _loadData,
              variant: MujiButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }

  /// Sliver 앱바 구성
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: MujiTheme.backgroundColor,
      leading: Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: MujiTheme.primaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.share, color: MujiTheme.primaryTextColor),
            onPressed: () {
              // TODO: 공유 기능 구현
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeroImage(),
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(4),
        child: Container(
          height: 4,
          child: LinearProgressIndicator(
            value: _readingProgress,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(MujiTheme.primaryColor),
          ),
        ),
      ),
    );
  }

  /// 히어로 이미지
  Widget _buildHeroImage() {
    if (_article?.featuredImageUrl != null) {
      return Image.network(
        _article!.featuredImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultHeroImage(),
      );
    } else {
      return _buildDefaultHeroImage();
    }
  }

  /// 기본 히어로 이미지
  Widget _buildDefaultHeroImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MujiTheme.primaryColor.withOpacity(0.3),
            MujiTheme.primaryColor.withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.article_outlined,
          size: 64,
          color: MujiTheme.primaryColor,
        ),
      ),
    );
  }

  /// 콘텐츠 구성
  Widget _buildContent() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildArticleHeader(),
          SizedBox(height: 24),
          _buildArticleTitle(),
          SizedBox(height: 16),
          _buildArticleMeta(),
          SizedBox(height: 24),
          _buildLikeSection(),
          SizedBox(height: 32),
          _buildArticleContent(),
          SizedBox(height: 48),
          _buildArticleFooter(),
        ],
      ),
    );
  }

  /// 기사 헤더
  Widget _buildArticleHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_article!.authorName != null) ...[
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: MujiTheme.primaryColor.withOpacity(0.1),
                child: Text(
                  _article!.authorName![0].toUpperCase(),
                  style: MujiTheme.bodyMedium.copyWith(
                    color: MujiTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _article!.authorName!,
                    style: MujiTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_article!.publishedAt != null)
                    Text(
                      _formatDate(_article!.publishedAt!),
                      style: MujiTheme.bodySmall.copyWith(
                        color: MujiTheme.secondaryTextColor,
                      ),
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
        ],
      ],
    );
  }

  /// 기사 제목
  Widget _buildArticleTitle() {
    return Text(
      _article!.title,
      style: MujiTheme.headlineLarge.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );
  }

  /// 기사 메타 정보
  Widget _buildArticleMeta() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        if (_article!.estimatedReadingTime != null)
          _buildMetaChip(
            icon: Icons.access_time,
            text: '${_article!.estimatedReadingTime}분',
          ),
        _buildMetaChip(
          icon: Icons.visibility_outlined,
          text: '${_article!.viewCount}',
        ),
        if (_likeData != null)
          _buildMetaChip(
            icon: Icons.favorite_outline,
            text: '${_likeData!.likeCount}',
          ),
      ],
    );
  }

  /// 메타 칩 위젯
  Widget _buildMetaChip({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: MujiTheme.secondaryTextColor,
        ),
        SizedBox(width: 4),
        Text(
          text,
          style: MujiTheme.bodySmall.copyWith(
            color: MujiTheme.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  /// 좋아요 섹션
  Widget _buildLikeSection() {
    final authProvider = Provider.of<AuthProvider>(context);
    if (!authProvider.isAuthenticated) return SizedBox.shrink();

    final isLiked = _likeData?.liked ?? false;

    return Center(
      child: ScaleTransition(
        scale: _likeAnimation,
        child: InkWell(
          onTap: _toggleLike,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: isLiked ? MujiTheme.errorColor : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isLiked ? MujiTheme.errorColor : MujiTheme.borderColor,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.white : MujiTheme.errorColor,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  isLiked ? '좋아요 취소' : '좋아요',
                  style: MujiTheme.bodyMedium.copyWith(
                    color: isLiked ? Colors.white : MujiTheme.errorColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 기사 콘텐츠
  Widget _buildArticleContent() {
    String content = _article!.content ?? _article!.excerpt ?? '';
    
    if (content.isEmpty) {
      return Text(
        '콘텐츠를 불러올 수 없습니다.',
        style: MujiTheme.bodyMedium.copyWith(
          color: MujiTheme.secondaryTextColor,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_article!.excerpt != null && _article!.excerpt!.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MujiTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: MujiTheme.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Text(
              _article!.excerpt!,
              style: MujiTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
          SizedBox(height: 24),
        ],
        Text(
          content,
          style: MujiTheme.bodyLarge.copyWith(
            height: 1.6,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  /// 기사 푸터
  Widget _buildArticleFooter() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MujiTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이 기사가 도움이 되셨나요?',
            style: MujiTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              if (_likeData != null) ...[
                Text(
                  '${_likeData!.likeCount}명이 좋아요를 눌렀습니다.',
                  style: MujiTheme.bodySmall.copyWith(
                    color: MujiTheme.secondaryTextColor,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// 날짜 포맷팅
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}분 전';
      } else {
        return '${difference.inHours}시간 전';
      }
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.year}년 ${date.month}월 ${date.day}일';
    }
  }
}