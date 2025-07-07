/// Paperly Mobile App - 로그인 화면
/// 
/// 이 파일은 사용자가 기존 계정으로 로그인할 수 있는 화면을 구현합니다.
/// 무인양품 디자인 철학을 바탕으로 미니멀하고 우아한 UI를 제공합니다.
/// 
/// 주요 기능:
/// - 이메일/비밀번호 로그인 폼
/// - 실시간 입력 검증 및 에러 처리
/// - 로그인 오류 메시지 표시
/// - 비밀번호 보기/숨기기 토글
/// - 소셜 로그인 옵션 (Google, Apple)
/// - 회원가입 화면으로 이동
/// 
/// 디자인 특징:
/// - 부드러운 페이드인/슬라이드 애니메이션
/// - 무인양품 색상 팔레트 사용
/// - 민감한 행틱 피드백
/// - 반응형 레이아웃

import 'package:flutter/material.dart';        // Flutter UI 컴포넌트
import 'package:flutter/services.dart';       // 행틱 피드백 등 시스템 서비스
import 'package:flutter/cupertino.dart';      // iOS 스타일 아이콘
import 'package:provider/provider.dart';      // 상태 관리
import '../../theme/muji_theme.dart';          // 무인양품 스타일 테마
import '../../providers/auth_provider.dart';   // 인증 상태 관리
import '../../widgets/muji_text_field.dart';   // 커스텀 텍스트 입력 필드
import '../../widgets/muji_button.dart';       // 커스텀 버튼 위젯
import '../../models/auth_models.dart';        // 인증 관련 데이터 모델
import '../../services/device_info_service.dart'; // 디바이스 정보 서비스
import '../../utils/error_handler.dart';       // 통합 에러 핸들링 시스템
import 'register_screen.dart';                 // 회원가입 화면

/// 로그인 화면 위젯
/// 
/// StatefulWidget을 사용하여 폼 입력, 로딩 상태, 
/// 애니메이션 등의 동적 상태를 관리합니다.
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// 로그인 화면의 상태 관리 클래스
/// 
/// SingleTickerProviderStateMixin:
/// 하나의 애니메이션 컨트롤러를 사용할 때 효율적인 Ticker 제공
class _LoginScreenState extends State<LoginScreen> 
    with SingleTickerProviderStateMixin, ErrorHandlerMixin {
  
  // ============================================================================
  // 🎨 애니메이션 컨트롤러들
  // ============================================================================
  
  late AnimationController _animationController; // 전체 애니메이션 제어
  late Animation<double> _fadeAnimation;         // 페이드인 애니메이션 (0.0 ~ 1.0)
  late Animation<Offset> _slideAnimation;        // 슬라이드 애니메이션 (아래에서 위로)
  
  // ============================================================================
  // 📝 폼 관련 컨트롤러들
  // ============================================================================
  
  final _formKey = GlobalKey<FormState>();       // 폼 전체 유효성 검사용
  final _emailController = TextEditingController();    // 이메일 입력 컨트롤러
  final _passwordController = TextEditingController(); // 비밀번호 입력 컨트롤러
  
  // ============================================================================
  // 🔐 UI 상태 변수들
  // ============================================================================
  
  bool _isPasswordVisible = false;  // 비밀번호 표시/숨김 상태

  /// 위젯 초기화
  /// 
  /// 화면이 첫 로드될 때 애니메이션을 설정하고 실행합니다.
  /// 두 가지 애니메이션을 조합하여 우아한 등장 효과를 만듭니다.
  @override
  void initState() {
    super.initState();
    
    // 전체 애니메이션 지속시간 800ms 설정
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,  // SingleTickerProviderStateMixin에서 제공
    );
    
    // 페이드인 애니메이션: 0~60% 구간에서 투명도 0에서 1로
    _fadeAnimation = Tween<double>(
      begin: 0.0,    // 완전 투명
      end: 1.0,      // 완전 불투명
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut), // 밀리기 시작
    ));
    
    // 슬라이드 애니메이션: 20~100% 구간에서 아래에서 위로 이동
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),  // 아래쪽에서 시작 (20% 오프셋)
      end: Offset.zero,             // 원래 위치로
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic), // 자연스러운 반동
    ));
    
    // 애니메이션 시작
    _animationController.forward();
  }

  /// 위젯 소멸 시 리소스 정리
  /// 
  /// 메모리 누수를 방지하기 위해 모든 컨트롤러를 해제합니다.
  @override
  void dispose() {
    _animationController.dispose();  // 애니메이션 컨트롤러 해제
    _emailController.dispose();      // 이메일 입력 컨트롤러 해제
    _passwordController.dispose();   // 비밀번호 입력 컨트롤러 해제
    super.dispose();
  }

  /// 로그인 요청 처리 함수
  /// 
  /// 폼 검증 → AuthProvider 통한 API 호출 → 결과 처리 순으로 진행
  /// 
  /// 플로우:
  /// 1. 클라이언트 측 입력 유효성 검사
  /// 2. 로딩 상태 시작 및 에러 메시지 초기화
  /// 3. AuthProvider를 통한 로그인 API 호출
  /// 4. 성공 시: 환영 메시지 표시 및 홈 화면으로 이동
  /// 5. 실패 시: 에러 메시지 표시
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    // 에러 상태 초기화 및 로딩 시작
    clearError();
    toggleLoading(true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      
      // 디바이스 정보 생성
      final deviceInfo = await DeviceInfoService.createDeviceInfo();
      
      await authProvider.login(
        LoginRequest(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          deviceInfo: deviceInfo,
        ),
      );
      
      // 로그인 성공 시 환영 메시지 표시 후 메인 화면으로 이동
      if (mounted) {
        // AuthProvider 상태 업데이트 대기
        await Future.delayed(const Duration(milliseconds: 100));
        
        // 성공 메시지 표시 (통합 에러 핸들러 사용)
        showSuccessMessage('환영합니다! ${authProvider.currentUser?.name ?? '사용자'}님');
        
        // 메인 화면으로 이동
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      // 통합 에러 핸들링 사용
      final errorState = convertExceptionToErrorState(
        e,
        retry: _handleLogin,
        context: {
          'action': 'login',
          'email': _emailController.text.trim(),
        },
      );
      
      showError(
        errorState.message!,
        type: errorState.type,
        retry: errorState.retry,
        context: errorState.context,
      );
    } finally {
      toggleLoading(false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      backgroundColor: MujiTheme.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    
                    // 로고
                    Center(child: _buildLogo()),
                    
                    const SizedBox(height: 32),
                    
                    // 제목
                    Text(
                      '로그인',
                      style: MujiTheme.mobileH1.copyWith(
                        color: MujiTheme.textDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // 부제목
                    Text(
                      '지식의 여정을 계속하세요',
                      style: MujiTheme.mobileBody.copyWith(
                        color: MujiTheme.textLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // 에러 메시지 (ErrorHandlerMixin 사용)
                    
                    // 이메일 입력
                    MujiTextField(
                      controller: _emailController,
                      label: '이메일',
                      hint: 'your@email.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: CupertinoIcons.mail,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return '이메일을 입력해주세요';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                          return '올바른 이메일 형식이 아닙니다';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 비밀번호 입력
                    MujiTextField(
                      controller: _passwordController,
                      label: '비밀번호',
                      hint: '비밀번호를 입력하세요',
                      obscureText: !_isPasswordVisible,
                      prefixIcon: CupertinoIcons.lock,
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                        child: Icon(
                          _isPasswordVisible 
                              ? CupertinoIcons.eye_slash 
                              : CupertinoIcons.eye,
                          color: MujiTheme.textLight,
                          size: 20,
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return '비밀번호를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // 에러 메시지 표시
                    // 에러 메시지 (통합 에러 핸들링 사용)
                    InlineErrorWidget(errorState: errorState),
                    if (errorState.hasError) const SizedBox(height: 16),
                    
                    // 비밀번호 찾기
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          // TODO: 비밀번호 찾기
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('비밀번호 찾기 기능은 곧 출시됩니다!')),
                          );
                        },
                        child: Text(
                          '비밀번호를 잊으셨나요?',
                          style: MujiTheme.mobileCaption.copyWith(
                            color: MujiTheme.sage,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // 로그인 버튼
                    MujiButton(
                      text: '로그인',
                      onPressed: errorState.isLoading ? null : _handleLogin,
                      isLoading: errorState.isLoading,
                      style: MujiButtonStyle.primary,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 또는 구분선
                    _buildDivider(),
                    
                    const SizedBox(height: 24),
                    
                    // 소셜 로그인 버튼들
                    _buildSocialLoginButtons(),
                    
                    const Spacer(),
                    
                    // 회원가입 안내
                    _buildRegisterPrompt(),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 앱 로고 위젯 빌더
  /// 
  /// Paperly 앱의 대표 로고를 만듭니다.
  /// 원형 배경에 'P' 문자를 중앙에 배치하여 단순하면서도 상징적인 로고를 만듭니다.
  Widget _buildLogo() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: MujiTheme.sage.withOpacity(0.1), // 담은 세이지 그린 배경
        shape: BoxShape.circle,                  // 원형 모양
      ),
      child: Center(
        child: Text(
          'P',                                   // Paperly의 첫 글자
          style: MujiTheme.mobileH2.copyWith(
            color: MujiTheme.sage,               // 진한 세이지 그린 글자
            fontWeight: FontWeight.w600,         // 세미볼드 글꼴
          ),
        ),
      ),
    );
  }

  /// 에러 메시지 영역 빌더
  /// 
  /// 로그인 실패 시 표시되는 에러 메시지 영역입니다.
  /// AnimatedContainer를 사용하여 부드러운 등장 애니메이션을 제공합니다.
  /// 
  /// 디자인 특징:
  /// - 빨간색 계열의 부드러운 배경
  /// - 경고 아이콘과 함께 메시지 표시
  /// - 모서리가 둥근 카드 형태

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 0.5,
            color: MujiTheme.textHint.withOpacity(0.3),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '또는',
            style: MujiTheme.mobileCaption.copyWith(
              color: MujiTheme.textLight,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 0.5,
            color: MujiTheme.textHint.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLoginButtons() {
    return Column(
      children: [
        _SocialLoginButton(
          icon: Icons.g_mobiledata, // Google 아이콘 대신 임시
          text: 'Google로 계속하기',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Google 로그인 기능은 곧 출시됩니다!')),
            );
          },
        ),
        const SizedBox(height: 12),
        _SocialLoginButton(
          icon: Icons.apple, // Apple 아이콘
          text: 'Apple로 계속하기',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Apple 로그인 기능은 곧 출시됩니다!')),
            );
          },
          isDark: true,
        ),
      ],
    );
  }

  Widget _buildRegisterPrompt() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '아직 계정이 없으신가요? ',
            style: MujiTheme.mobileCaption,
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RegisterScreen(),
                ),
              );
            },
            child: Text(
              '회원가입',
              style: MujiTheme.mobileCaption.copyWith(
                color: MujiTheme.sage,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 소셜 로그인 버튼 위젯
/// 
/// Google, Apple 등의 소셜 로그인 버튼을 만드는 재사용 가능한 위젯입니다.
/// 각 소셜 플랫폼의 디자인 가이드라인에 맞춰 스타일링됩니다.
class _SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPressed;
  final bool isDark;

  /// 소셜 로그인 버튼 생성자
  /// 
  /// 매개변수:
  /// - icon: 표시할 아이콘 (예: Google, Apple 로고)
  /// - text: 버튼에 표시할 텍스트
  /// - onPressed: 버튼 클릭 시 실행할 콜백 함수
  /// - isDark: 다크 테마 사용 여부 (기본: false)
  const _SocialLoginButton({
    Key? key,
    required this.icon,
    required this.text,
    required this.onPressed,
    this.isDark = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isDark ? MujiTheme.textDark : MujiTheme.surface,
          borderRadius: BorderRadius.circular(MujiTheme.radiusM),
          border: Border.all(
            color: MujiTheme.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isDark ? Colors.white : MujiTheme.textDark,
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: MujiTheme.mobileBody.copyWith(
                color: isDark ? Colors.white : MujiTheme.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}