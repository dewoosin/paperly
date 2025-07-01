/// Paperly 기사 목록 스크린
/// 
/// 이 파일은 앱의 기사 목록 화면을 구현합니다.
/// 사용자가 로그인한 상태에서 기사를 볼 수 있고 좋아요 기능을 사용할 수 있습니다.
/// 
/// 주요 기능:
/// - 무한 스크롤 기사 목록
/// - 실시간 좋아요 기능
/// - 카테고리 필터링
/// - 검색 기능
/// - 추천/트렌딩 기사 섹션
/// - 풀 투 리프레시
/// 
/// UI 특징:
/// - 무인양품 스타일 미니멀 디자인
/// - 부드러운 애니메이션 전환
/// - 직관적인 터치 인터페이션

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../theme/muji_theme.dart';
import '../providers/auth_provider.dart';
import '../services/article_service.dart';
import '../models/article_models.dart';
import '../widgets/muji_button.dart';
import '../utils/logger.dart';
import 'article_detail_screen.dart';

/// 기사 목록 스크린 메인 위젯
class ArticleListScreen extends StatefulWidget {
  final String? categoryId;
  final String? authorId;
  final String? searchQuery;
  final bool showOnlyFeatured;
  final bool showOnlyTrending;

  const ArticleListScreen({
    Key? key,
    this.categoryId,
    this.authorId,
    this.searchQuery,
    this.showOnlyFeatured = false,
    this.showOnlyTrending = false,
  }) : super(key: key);

  @override
  State<ArticleListScreen> createState() => _ArticleListScreenState();
}

/// 기사 목록 스크린의 상태 관리 클래스
class _ArticleListScreenState extends State<ArticleListScreen>
    with TickerProviderStateMixin {
  
  // 애니메이션 컨트롤러들
  late AnimationController _fadeController;
  late AnimationController _listController;
  
  // 애니메이션들
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // 스크롤 및 상태 관리
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();
  
  // 데이터 관리
  late ArticleService _articleService;
  List<Article> _articles = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  String? _errorMessage;
  
  // 좋아요 상태 캐시 (articleId -> LikeData)
  Map<String, LikeData> _likeStatusCache = {};
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeServices();
    _loadInitialData();
    _setupScrollListener();
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _listController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  /// 애니메이션 초기화
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _listController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _listController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    _listController.forward();
  }
  
  /// 서비스 초기화
  void _initializeServices() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _articleService = ArticleService(authProvider.dio);
  }
  
  /// 초기 데이터 로드
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      await _loadArticles(refresh: true);
    } catch (e) {
      Logger.error('초기 데이터 로드 실패', {'error': e.toString()});
      setState(() {
        _errorMessage = '기사를 불러오는 중 오류가 발생했습니다.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  /// 기사 목록 로드
  Future<void> _loadArticles({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreData = true;
      _articles.clear();
      _likeStatusCache.clear();
    }
    
    if (!_hasMoreData) return;
    
    try {
      ArticleListResponse response;
      
      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        response = await _articleService.searchArticles(
          widget.searchQuery!,
          page: _currentPage,
          categoryId: widget.categoryId,
          authorId: widget.authorId,
        );
      } else {
        response = await _articleService.getArticles(
          page: _currentPage,
          categoryId: widget.categoryId,
          authorId: widget.authorId,
          featured: widget.showOnlyFeatured ? true : null,
          trending: widget.showOnlyTrending ? true : null,
        );
      }
      
      setState(() {
        _articles.addAll(response.data.articles);
        _hasMoreData = response.data.articles.length >= 20;
        _currentPage++;
      });
      
      // 각 기사의 좋아요 상태 로드
      _loadLikeStatusForArticles(response.data.articles);
      
    } catch (e) {
      Logger.error('기사 로드 실패', {'error': e.toString()});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('기사를 불러오는 중 오류가 발생했습니다.'),
            backgroundColor: MujiTheme.errorColor,
          ),
        );
      }
    }
  }
  
  /// 기사들의 좋아요 상태 로드
  Future<void> _loadLikeStatusForArticles(List<Article> articles) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) return;
    
    for (final article in articles) {
      if (!_likeStatusCache.containsKey(article.id)) {
        try {
          final likeStatus = await _articleService.getLikeStatus(article.id);
          if (mounted) {
            setState(() {
              _likeStatusCache[article.id] = likeStatus;
            });
          }
        } catch (e) {
          Logger.error('좋아요 상태 로드 실패', {
            'articleId': article.id,
            'error': e.toString(),
          });
        }
      }
    }
  }
  
  /// 스크롤 리스너 설정
  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoadingMore && _hasMoreData) {
          _loadMoreArticles();
        }
      }
    });
  }
  
  /// 더 많은 기사 로드
  Future<void> _loadMoreArticles() async {
    setState(() {
      _isLoadingMore = true;
    });
    
    await _loadArticles();
    
    setState(() {
      _isLoadingMore = false;
    });
  }
  
  /// 새로고침
  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    await _loadArticles(refresh: true);
  }
  
  /// 기사 좋아요 토글
  Future<void> _toggleLike(Article article) async {
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
    
    HapticFeedback.lightImpact();
    
    try {
      final likeData = await _articleService.toggleLike(article.id);
      
      setState(() {
        _likeStatusCache[article.id] = likeData;
        
        // 기사 목록에서도 좋아요 수 업데이트
        final index = _articles.indexWhere((a) => a.id == article.id);
        if (index != -1) {
          _articles[index] = _articles[index].copyWith(
            likeCount: likeData.likeCount,
          );
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(likeData.liked ? '좋아요를 눌렀습니다.' : '좋아요를 취소했습니다.'),
          backgroundColor: likeData.liked ? MujiTheme.primaryColor : MujiTheme.secondaryTextColor,
          duration: Duration(milliseconds: 1500),
        ),
      );
      
    } catch (e) {
      Logger.error('좋아요 토글 실패', {
        'articleId': article.id,
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
  
  /// 기사 상세 화면으로 이동
  void _navigateToArticleDetail(Article article) {
    HapticFeedback.selectionClick();
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ArticleDetailScreen(articleId: article.id),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 300),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MujiTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }
  
  /// 앱바 구성
  PreferredSizeWidget _buildAppBar() {
    String title = '기사';
    
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      title = '검색: ${widget.searchQuery}';
    } else if (widget.showOnlyFeatured) {
      title = '추천 기사';
    } else if (widget.showOnlyTrending) {
      title = '인기 기사';
    }
    
    return AppBar(
      title: Text(
        title,
        style: MujiTheme.headlineSmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: MujiTheme.backgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: MujiTheme.primaryTextColor),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: MujiTheme.primaryTextColor),
          onPressed: _onRefresh,
        ),
      ],
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
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: RefreshIndicator(
          key: _refreshKey,
          onRefresh: _onRefresh,
          color: MujiTheme.primaryColor,
          child: _articles.isEmpty ? _buildEmptyWidget() : _buildArticleList(),
        ),
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
              _errorMessage!,
              style: MujiTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            MujiButton(
              text: '다시 시도',
              onPressed: _loadInitialData,
              variant: MujiButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }
  
  /// 빈 목록 위젯
  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: MujiTheme.secondaryTextColor,
            ),
            SizedBox(height: 16),
            Text(
              '기사가 없습니다.',
              style: MujiTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              '나중에 다시 확인해 주세요.',
              style: MujiTheme.bodyMedium.copyWith(
                color: MujiTheme.secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  /// 기사 목록 위젯
  Widget _buildArticleList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _articles.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _articles.length) {
          return _buildLoadMoreIndicator();
        }
        
        return _buildArticleCard(_articles[index], index);
      },
    );
  }
  
  /// 더 로드 인디케이터
  Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: CircularProgressIndicator(
          color: MujiTheme.primaryColor,
          strokeWidth: 2,
        ),
      ),
    );
  }
  
  /// 기사 카드 위젯
  Widget _buildArticleCard(Article article, int index) {
    final likeData = _likeStatusCache[article.id];
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: () => _navigateToArticleDetail(article),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildArticleHeader(article),
                SizedBox(height: 12),
                _buildArticleTitle(article),
                if (article.summary != null) ...[
                  SizedBox(height: 8),
                  _buildArticleSummary(article),
                ],
                SizedBox(height: 12),
                _buildArticleFooter(article, likeData),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// 기사 헤더 (작가명, 발행일)
  Widget _buildArticleHeader(Article article) {
    return Row(
      children: [
        if (article.authorName != null) ...[
          Text(
            article.authorName!,
            style: MujiTheme.bodySmall.copyWith(
              color: MujiTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 8),
          Container(
            width: 2,
            height: 2,
            decoration: BoxDecoration(
              color: MujiTheme.secondaryTextColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
        ],
        if (article.publishedAt != null)
          Text(
            _formatDate(article.publishedAt!),
            style: MujiTheme.bodySmall.copyWith(
              color: MujiTheme.secondaryTextColor,
            ),
          ),
        Spacer(),
        if (article.estimatedReadingTime != null)
          Text(
            '${article.estimatedReadingTime}분',
            style: MujiTheme.bodySmall.copyWith(
              color: MujiTheme.secondaryTextColor,
            ),
          ),
      ],
    );
  }
  
  /// 기사 제목
  Widget _buildArticleTitle(Article article) {
    return Text(
      article.title,
      style: MujiTheme.headlineSmall.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
  
  /// 기사 요약
  Widget _buildArticleSummary(Article article) {
    return Text(
      article.summary!,
      style: MujiTheme.bodyMedium.copyWith(
        color: MujiTheme.secondaryTextColor,
        height: 1.4,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
  
  /// 기사 푸터 (좋아요, 조회수 등)
  Widget _buildArticleFooter(Article article, LikeData? likeData) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLiked = likeData?.liked ?? false;
    final likeCount = likeData?.likeCount ?? article.likeCount;
    
    return Row(
      children: [
        // 좋아요 버튼
        if (authProvider.isAuthenticated)
          InkWell(
            onTap: () => _toggleLike(article),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: isLiked ? MujiTheme.errorColor : MujiTheme.secondaryTextColor,
                  ),
                  SizedBox(width: 4),
                  Text(
                    likeCount.toString(),
                    style: MujiTheme.bodySmall.copyWith(
                      color: isLiked ? MujiTheme.errorColor : MujiTheme.secondaryTextColor,
                      fontWeight: isLiked ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite_border,
                size: 16,
                color: MujiTheme.secondaryTextColor,
              ),
              SizedBox(width: 4),
              Text(
                likeCount.toString(),
                style: MujiTheme.bodySmall.copyWith(
                  color: MujiTheme.secondaryTextColor,
                ),
              ),
            ],
          ),
        
        SizedBox(width: 16),
        
        // 조회수
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.visibility_outlined,
              size: 16,
              color: MujiTheme.secondaryTextColor,
            ),
            SizedBox(width: 4),
            Text(
              article.viewCount.toString(),
              style: MujiTheme.bodySmall.copyWith(
                color: MujiTheme.secondaryTextColor,
              ),
            ),
          ],
        ),
      ],
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
      return '${date.month}월 ${date.day}일';
    }
  }
}