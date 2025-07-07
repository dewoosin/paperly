/// Paperly Mobile App - 작가 상세 화면
/// 
/// 이 화면은 특정 작가의 상세 정보를 표시합니다.
/// 무지 스타일의 미니멀한 디자인으로 작가 프로필, 통계, 글 목록을 보여줍니다.
/// 
/// 주요 기능:
/// - 작가 프로필 정보 (이름, 소개, 전문분야)
/// - 팔로우/언팔로우 버튼 및 상태 관리
/// - 작가 통계 (팔로워 수, 글 수, 평점 등)
/// - 작가가 작성한 글 목록
/// - 소셜 링크 및 연락처 정보
/// 
/// UI 특징:
/// - 패럴럭스 스크롤 효과
/// - 부드러운 애니메이션 전환
/// - 햅틱 피드백
/// - 무인양품 스타일 컬러 팔레트

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

import '../theme/muji_theme.dart';
import '../models/author_models.dart';
import '../providers/follow_provider.dart';
import '../utils/logger.dart';

/// 작가 상세 화면 위젯
/// 
/// 작가 ID를 받아서 해당 작가의 상세 정보를 표시합니다.
class AuthorDetailScreen extends StatefulWidget {
  final String authorId;
  final Author? initialAuthor; // 이미 가지고 있는 작가 정보 (선택사항)

  const AuthorDetailScreen({
    Key? key,
    required this.authorId,
    this.initialAuthor,
  }) : super(key: key);

  @override
  State<AuthorDetailScreen> createState() => _AuthorDetailScreenState();
}

class _AuthorDetailScreenState extends State<AuthorDetailScreen>
    with TickerProviderStateMixin {
  
  // 애니메이션 컨트롤러들
  late AnimationController _scrollController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  
  // 로거 인스턴스
  final logger = loggerInstance;
  
  // 스크롤 관련 변수들
  final ScrollController _mainScrollController = ScrollController();
  double _scrollOffset = 0;
  double _headerOpacity = 1.0;
  
  // 상태 변수들
  Author? _author;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    
    // 초기 작가 정보가 있으면 사용
    if (widget.initialAuthor != null) {
      _author = widget.initialAuthor;
      _isLoading = false;
    }
    
    // 애니메이션 컨트롤러 초기화
    _scrollController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    // 스크롤 리스너 설정
    _mainScrollController.addListener(_onScroll);
    
    // 애니메이션 시작
    _fadeController.forward();
    _scaleController.forward();
    
    // 작가 정보 로드
    _loadAuthorDetails();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  /// 스크롤 이벤트 처리
  void _onScroll() {
    setState(() {
      _scrollOffset = _mainScrollController.offset;
      // 헤더 이미지 투명도 계산 (0~200 픽셀 구간에서 변화)
      _headerOpacity = (1.0 - (_scrollOffset / 200)).clamp(0.0, 1.0);
    });
  }

  /// 작가 상세 정보 로드
  Future<void> _loadAuthorDetails() async {
    try {
      final followProvider = context.read<FollowProvider>();
      final author = await followProvider.getAuthorDetails(
        widget.authorId,
        forceRefresh: widget.initialAuthor == null,
      );
      
      if (mounted) {
        setState(() {
          _author = author;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      logger.e('작가 정보 로드 실패', error: e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = '작가 정보를 불러올 수 없습니다';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      backgroundColor: MujiTheme.bg,
      body: Stack(
        children: [
          // 메인 콘텐츠
          if (_isLoading)
            _buildLoadingState()
          else if (_error != null)
            _buildErrorState()
          else if (_author != null)
            _buildAuthorContent()
          else
            _buildNotFoundState(),
          
          // 상단 앱바
          _buildCustomAppBar(safeTop),
        ],
      ),
    );
  }

  /// 로딩 상태 위젯
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(MujiTheme.sage),
          ),
          SizedBox(height: 16),
          Text(
            '작가 정보를 불러오고 있습니다...',
            style: MujiTheme.mobileBody,
          ),
        ],
      ),
    );
  }

  /// 에러 상태 위젯
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 64,
              color: MujiTheme.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? '알 수 없는 오류가 발생했습니다',
              style: MujiTheme.mobileBody,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadAuthorDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: MujiTheme.sage,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  /// 작가를 찾을 수 없는 상태 위젯
  Widget _buildNotFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.person_crop_circle,
              size: 64,
              color: MujiTheme.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              '작가를 찾을 수 없습니다',
              style: MujiTheme.mobileH3.copyWith(
                color: MujiTheme.textBody,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '요청하신 작가 정보가 존재하지 않거나\n삭제되었을 수 있습니다.',
              style: MujiTheme.mobileBody.copyWith(
                color: MujiTheme.textLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 작가 콘텐츠 빌드
  Widget _buildAuthorContent() {
    return CustomScrollView(
      controller: _mainScrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 헤더 영역
        SliverToBoxAdapter(
          child: _buildHeader(),
        ),
        
        // 프로필 정보
        SliverToBoxAdapter(
          child: _buildProfileSection(),
        ),
        
        // 통계 섹션
        SliverToBoxAdapter(
          child: _buildStatsSection(),
        ),
        
        // 전문분야 섹션
        SliverToBoxAdapter(
          child: _buildSpecialtiesSection(),
        ),
        
        // 소셜 링크 섹션
        SliverToBoxAdapter(
          child: _buildSocialLinksSection(),
        ),
        
        // 작가의 글 목록
        SliverToBoxAdapter(
          child: _buildArticlesSection(),
        ),
        
        // 하단 여백
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  /// 헤더 영역 (프로필 이미지 및 기본 정보)
  Widget _buildHeader() {
    return Container(
      height: 320,
      child: Stack(
        children: [
          // 배경 그라데이션
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    MujiTheme.sage.withOpacity(0.1),
                    MujiTheme.bg,
                  ],
                ),
              ),
            ),
          ),
          
          // 프로필 정보
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: FadeTransition(
              opacity: _fadeController,
              child: ScaleTransition(
                scale: _scaleController,
                child: Column(
                  children: [
                    // 프로필 이미지
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: _author!.profileImageUrl?.isNotEmpty == true
                            ? Image.network(
                                _author!.profileImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildDefaultAvatar(),
                              )
                            : _buildDefaultAvatar(),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 작가명
                    Text(
                      _author!.displayName,
                      style: MujiTheme.mobileH1.copyWith(
                        fontWeight: FontWeight.bold,
                        color: MujiTheme.textDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    if (_author!.bio?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text(
                        _author!.bio!,
                        style: MujiTheme.mobileBody.copyWith(
                          color: MujiTheme.textLight,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 기본 아바타 (프로필 이미지가 없을 때)
  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [MujiTheme.sage, MujiTheme.moss],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        CupertinoIcons.person_fill,
        color: Colors.white,
        size: 60,
      ),
    );
  }

  /// 프로필 섹션 (팔로우 버튼)
  Widget _buildProfileSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Consumer<FollowProvider>(
        builder: (context, followProvider, child) {
          final isFollowing = followProvider.isFollowing(_author!.id);
          final isLoading = followProvider.isFollowingInProgress(_author!.id);
          
          return Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : () => _toggleFollow(followProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing ? MujiTheme.textLight : MujiTheme.sage,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isFollowing 
                              ? CupertinoIcons.heart_fill 
                              : CupertinoIcons.heart,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isFollowing ? '팔로잉' : '팔로우',
                          style: MujiTheme.mobileBody.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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

  /// 통계 섹션
  Widget _buildStatsSection() {
    if (_author?.stats == null) return const SizedBox.shrink();
    
    final stats = _author!.stats!;
    
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MujiTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: MujiTheme.border,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '작가 통계',
            style: MujiTheme.mobileH3.copyWith(
              fontWeight: FontWeight.bold,
              color: MujiTheme.textDark,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 통계 그리드
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '팔로워',
                  _formatNumber(stats.followerCount),
                  CupertinoIcons.heart_fill,
                  MujiTheme.sage,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '글 수',
                  _formatNumber(stats.publishedArticles),
                  CupertinoIcons.doc_text_fill,
                  MujiTheme.bark,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '총 조회수',
                  _formatNumber(stats.totalViews),
                  CupertinoIcons.eye_fill,
                  MujiTheme.moss,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '평균 평점',
                  stats.averageRating.toStringAsFixed(1),
                  CupertinoIcons.star_fill,
                  MujiTheme.clay,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 통계 항목 위젯
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: MujiTheme.mobileH3.copyWith(
              fontWeight: FontWeight.bold,
              color: MujiTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: MujiTheme.mobileCaption.copyWith(
              color: MujiTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  /// 전문분야 섹션
  Widget _buildSpecialtiesSection() {
    if (_author?.specialties.isEmpty != false) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '전문 분야',
            style: MujiTheme.mobileH3.copyWith(
              fontWeight: FontWeight.bold,
              color: MujiTheme.textDark,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _author!.specialties.map((specialty) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: MujiTheme.sage.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: MujiTheme.sage.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  specialty,
                  style: MujiTheme.mobileCaption.copyWith(
                    color: MujiTheme.sage,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 소셜 링크 섹션
  Widget _buildSocialLinksSection() {
    final hasLinks = _author?.websiteUrl?.isNotEmpty == true ||
                     _author?.twitterHandle?.isNotEmpty == true ||
                     _author?.instagramHandle?.isNotEmpty == true ||
                     _author?.linkedinUrl?.isNotEmpty == true;
    
    if (!hasLinks) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '소셜 링크',
            style: MujiTheme.mobileH3.copyWith(
              fontWeight: FontWeight.bold,
              color: MujiTheme.textDark,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 소셜 링크 버튼들
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (_author?.websiteUrl?.isNotEmpty == true)
                _buildSocialButton(
                  '웹사이트',
                  CupertinoIcons.globe,
                  () => _openUrl(_author!.websiteUrl!),
                ),
              if (_author?.twitterHandle?.isNotEmpty == true)
                _buildSocialButton(
                  '트위터',
                  CupertinoIcons.chat_bubble_text,
                  () => _openUrl('https://twitter.com/${_author!.twitterHandle}'),
                ),
              if (_author?.instagramHandle?.isNotEmpty == true)
                _buildSocialButton(
                  '인스타그램',
                  CupertinoIcons.camera,
                  () => _openUrl('https://instagram.com/${_author!.instagramHandle}'),
                ),
              if (_author?.linkedinUrl?.isNotEmpty == true)
                _buildSocialButton(
                  '링크드인',
                  CupertinoIcons.briefcase,
                  () => _openUrl(_author!.linkedinUrl!),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 소셜 링크 버튼
  Widget _buildSocialButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: MujiTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: MujiTheme.border,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: MujiTheme.textBody,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: MujiTheme.mobileCaption.copyWith(
                color: MujiTheme.textBody,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 작가의 글 섹션
  Widget _buildArticlesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '작가의 글',
            style: MujiTheme.mobileH3.copyWith(
              fontWeight: FontWeight.bold,
              color: MujiTheme.textDark,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // TODO: 실제 글 목록 구현
          Container(
            width: double.infinity,
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
                Icon(
                  CupertinoIcons.doc_text,
                  size: 48,
                  color: MujiTheme.textLight,
                ),
                const SizedBox(height: 12),
                Text(
                  '작가의 글 목록',
                  style: MujiTheme.mobileBody.copyWith(
                    color: MujiTheme.textBody,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '곧 구현될 예정입니다',
                  style: MujiTheme.mobileCaption.copyWith(
                    color: MujiTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 커스텀 앱바
  Widget _buildCustomAppBar(double safeTop) {
    final isScrolled = _scrollOffset > 100;
    
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: safeTop + 60,
        decoration: BoxDecoration(
          color: isScrolled 
              ? MujiTheme.bg.withOpacity(0.95)
              : Colors.transparent,
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
                    // 뒤로가기 버튼
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isScrolled 
                              ? MujiTheme.surface 
                              : Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: MujiTheme.border.withOpacity(0.5),
                            width: 0.5,
                          ),
                        ),
                        child: Icon(
                          CupertinoIcons.back,
                          size: 20,
                          color: MujiTheme.textBody,
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // 작가명 (스크롤 시 표시)
                    if (isScrolled && _author != null)
                      AnimatedOpacity(
                        opacity: isScrolled ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          _author!.displayName,
                          style: MujiTheme.mobileBody.copyWith(
                            fontWeight: FontWeight.w600,
                            color: MujiTheme.textDark,
                          ),
                        ),
                      ),
                    
                    const Spacer(),
                    
                    // 더보기 버튼
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showMoreOptions();
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isScrolled 
                              ? MujiTheme.surface 
                              : Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: MujiTheme.border.withOpacity(0.5),
                            width: 0.5,
                          ),
                        ),
                        child: Icon(
                          CupertinoIcons.ellipsis,
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
      ),
    );
  }

  /// 팔로우 토글
  Future<void> _toggleFollow(FollowProvider followProvider) async {
    HapticFeedback.mediumImpact();
    
    final success = await followProvider.toggleFollow(_author!.id);
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(followProvider.error ?? '처리 중 오류가 발생했습니다'),
          backgroundColor: MujiTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  /// 더보기 옵션 표시
  void _showMoreOptions() {
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
              ListTile(
                leading: const Icon(CupertinoIcons.share, color: MujiTheme.textBody),
                title: Text('공유하기', style: MujiTheme.mobileBody),
                onTap: () {
                  Navigator.pop(context);
                  _shareAuthor();
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.flag, color: MujiTheme.textBody),
                title: Text('신고하기', style: MujiTheme.mobileBody),
                onTap: () {
                  Navigator.pop(context);
                  _reportAuthor();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// 숫자 포맷팅 (1000 -> 1K)
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  /// URL 열기
  void _openUrl(String url) {
    // TODO: url_launcher 패키지 사용하여 구현
    logger.i('URL 열기: $url');
  }

  /// 작가 공유
  void _shareAuthor() {
    // TODO: share_plus 패키지 사용하여 구현
    logger.i('작가 공유: ${_author?.displayName}');
  }

  /// 작가 신고
  void _reportAuthor() {
    // TODO: 신고 기능 구현
    logger.i('작가 신고: ${_author?.displayName}');
  }
}