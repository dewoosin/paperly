import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../theme/muji_theme.dart';
import '../providers/auth_provider.dart';

/// 홈 화면 (Day 3 테스트용 임시 화면)
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> 
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
                child: SizedBox(height: safeTop + 56),
              ),
              
              // 환영 메시지
              SliverToBoxAdapter(
                child: _buildGreeting(user?.name ?? '사용자'),
              ),
              
              // 이메일 인증 안내 (필요한 경우)
              if (user != null && !user.emailVerified)
                SliverToBoxAdapter(
                  child: _buildEmailVerificationBanner(),
                ),
              
              // 오늘의 콘텐츠 (임시)
              SliverToBoxAdapter(
                child: _buildTodayContent(),
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
                  // 프로필 버튼
                  GestureDetector(
                    onTap: () => _showProfileMenu(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: MujiTheme.sage.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.person,
                        size: 20,
                        color: MujiTheme.sage,
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

  Widget _buildGreeting(String userName) {
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
            Row(
              children: [
                Text(
                  '$userName님, 오늘의 지식을 만나보세요',
                  style: MujiTheme.mobileCaption,
                ),
                const SizedBox(width: 8),
                Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  size: 16,
                  color: MujiTheme.sage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailVerificationBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MujiTheme.sand.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: MujiTheme.sand.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.mail,
            size: 20,
            color: MujiTheme.sand,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이메일 인증이 필요합니다',
                  style: MujiTheme.mobileCaption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: MujiTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '모든 기능을 사용하려면 이메일을 인증해주세요',
                  style: MujiTheme.mobileLabel,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              HapticFeedback.lightImpact();
              try {
                final authProvider = context.read<AuthProvider>();
                await authProvider.resendVerificationEmail();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('인증 메일을 다시 발송했습니다'),
                      backgroundColor: MujiTheme.sage,
                      behavior: SnackBarBehavior.floating,
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
                    ),
                  );
                }
              }
            },
            child: Text(
              '재발송',
              style: MujiTheme.mobileCaption.copyWith(
                color: MujiTheme.sand,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayContent() {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final isEmailVerified = user?.emailVerified ?? false;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '오늘의 콘텐츠',
                style: MujiTheme.mobileH3,
              ),
              const Spacer(),
              if (isEmailVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: MujiTheme.sage.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '인증 완료',
                    style: MujiTheme.mobileLabel.copyWith(
                      color: MujiTheme.sage,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 이메일 인증된 사용자를 위한 콘텐츠
          if (isEmailVerified) ...[
            _buildWelcomeCard(),
            const SizedBox(height: 16),
            _buildQuickActions(),
            const SizedBox(height: 16),
            _buildRecentActivity(),
          ] else ...[
            // 이메일 미인증 사용자를 위한 제한된 콘텐츠
            _buildLimitedAccessCard(),
          ],
        ],
      ),
    );
  }
  
  Widget _buildWelcomeCard() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MujiTheme.sage.withOpacity(0.8),
            MujiTheme.moss.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '모든 기능 이용 가능',
                  style: MujiTheme.mobileCaption.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '지식의 여정을\n시작해보세요',
              style: MujiTheme.mobileH2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '인증이 완료되어 모든 기능을 자유롭게 사용할 수 있습니다',
              style: MujiTheme.mobileCaption.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLimitedAccessCard() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MujiTheme.sand.withOpacity(0.7),
            MujiTheme.sand.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  CupertinoIcons.info_circle_fill,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '제한된 액세스',
                  style: MujiTheme.mobileCaption.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '이메일 인증 후\n모든 기능을 이용하세요',
              style: MujiTheme.mobileH2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '인증 메일을 확인하시고 계정을 활성화해주세요',
              style: MujiTheme.mobileCaption.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '빠른 액션',
          style: MujiTheme.mobileH4,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: CupertinoIcons.add_circled,
                title: '새 노트',
                subtitle: '아이디어 기록하기',
                onTap: () {
                  // TODO: 새 노트 작성
                  HapticFeedback.lightImpact();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: CupertinoIcons.search,
                title: '검색',
                subtitle: '지식 찾아보기',
                onTap: () {
                  // TODO: 검색 화면
                  HapticFeedback.lightImpact();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MujiTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: MujiTheme.border,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 24,
              color: MujiTheme.sage,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: MujiTheme.mobileBody.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: MujiTheme.mobileLabel.copyWith(
                color: MujiTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '최근 활동',
          style: MujiTheme.mobileH4,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: MujiTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: MujiTheme.border,
              width: 0.5,
            ),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(
                  CupertinoIcons.time,
                  size: 32,
                  color: MujiTheme.textLight,
                ),
                const SizedBox(height: 8),
                Text(
                  '아직 활동이 없습니다',
                  style: MujiTheme.mobileBody.copyWith(
                    color: MujiTheme.textLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '첫 번째 노트를 작성해보세요',
                  style: MujiTheme.mobileCaption.copyWith(
                    color: MujiTheme.textHint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
                _buildNavItem(2, CupertinoIcons.bookmark, '보관'),
                _buildNavItem(3, CupertinoIcons.person, '나'),
              ],
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
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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

  void _showProfileMenu() {
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
                leading: const Icon(CupertinoIcons.person_circle, color: MujiTheme.textBody),
                title: Text('프로필', style: MujiTheme.mobileBody),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: 프로필 화면
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.gear, color: MujiTheme.textBody),
                title: Text('설정', style: MujiTheme.mobileBody),
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