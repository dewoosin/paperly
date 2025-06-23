// apps/mobile/lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../theme/muji_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/muji_text_field.dart';
import '../../widgets/muji_button.dart';
import '../../models/auth_models.dart';
import 'register_screen.dart';

/// 로그인 화면
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
    // 애니메이션 설정
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 로그인 처리
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.login(
        LoginRequest(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
      
      // 로그인 성공 시 메인 화면으로 이동
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      backgroundColor: MujiTheme.bg,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, safeTop + 60, 24, 40),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 로고
                        _buildLogo(),
                        
                        const SizedBox(height: 48),
                        
                        // 타이틀
                        Text(
                          '다시 만나서\n반가워요',
                          style: MujiTheme.mobileH1.copyWith(
                            height: 1.2,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        Text(
                          '계속해서 지식의 여정을 이어가세요',
                          style: MujiTheme.mobileCaption,
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // 에러 메시지
                        if (_errorMessage != null) ...[
                          _buildErrorMessage(),
                          const SizedBox(height: 20),
                        ],
                        
                        // 이메일 입력
                        MujiTextField(
                          controller: _emailController,
                          label: '이메일',
                          hint: 'example@email.com',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          prefixIcon: CupertinoIcons.mail,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '이메일을 입력해주세요';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return '올바른 이메일 형식이 아닙니다';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // 비밀번호 입력
                        MujiTextField(
                          controller: _passwordController,
                          label: '비밀번호',
                          hint: '비밀번호를 입력하세요',
                          obscureText: !_isPasswordVisible,
                          textInputAction: TextInputAction.done,
                          prefixIcon: CupertinoIcons.lock,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? CupertinoIcons.eye_slash
                                  : CupertinoIcons.eye,
                              color: MujiTheme.textLight,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          onFieldSubmitted: (_) => _handleLogin(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '비밀번호를 입력해주세요';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // 비밀번호 찾기
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // TODO: 비밀번호 찾기 화면
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
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
                          onPressed: _isLoading ? null : _handleLogin,
                          isLoading: _isLoading,
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: MujiTheme.sage.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'P',
          style: MujiTheme.mobileH2.copyWith(
            color: MujiTheme.sage,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.shade200,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.exclamationmark_circle,
            size: 16,
            color: Colors.red.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: MujiTheme.mobileCaption.copyWith(
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          icon: 'assets/icons/google.svg',
          text: 'Google로 계속하기',
          onPressed: () {
            // TODO: Google 로그인
          },
        ),
        const SizedBox(height: 12),
        _SocialLoginButton(
          icon: 'assets/icons/apple.svg',
          text: 'Apple로 계속하기',
          onPressed: () {
            // TODO: Apple 로그인
          },
          isDark: Theme.of(context).brightness == Brightness.dark,
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

/// 소셜 로그인 버튼
class _SocialLoginButton extends StatelessWidget {
  final String icon;
  final String text;
  final VoidCallback onPressed;
  final bool isDark;

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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: MujiTheme.textHint.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 아이콘은 실제로는 SVG를 사용
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: MujiTheme.textLight.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
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
