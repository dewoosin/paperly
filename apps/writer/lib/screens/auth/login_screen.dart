import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/writer_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_button.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? '로그인에 실패했습니다.'),
          backgroundColor: WriterTheme.accentRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  
                  // 로고 섹션
                  _buildLogoSection(),
                  
                  const SizedBox(height: 60),
                  
                  // 로그인 폼
                  _buildLoginForm(),
                  
                  const SizedBox(height: 32),
                  
                  // 회원가입 링크
                  _buildSignUpLink(),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        // 로고
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                WriterTheme.primaryBlue,
                WriterTheme.primaryBlueDark,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: WriterTheme.mediumShadow,
          ),
          child: const Icon(
            Icons.edit_note,
            size: 40,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // 타이틀
        Text(
          'Paperly Writer',
          style: WriterTheme.headlineStyle.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          '당신의 이야기를 시작하세요',
          style: WriterTheme.subtitleStyle.copyWith(
            color: WriterTheme.neutralGray500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '로그인',
            style: WriterTheme.titleStyle,
          ),
          
          const SizedBox(height: 24),
          
          // 이메일 입력
          CustomTextField(
            controller: _emailController,
            label: '이메일',
            hintText: 'your@email.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '이메일을 입력해주세요';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return '올바른 이메일 형식을 입력해주세요';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // 비밀번호 입력
          CustomTextField(
            controller: _passwordController,
            label: '비밀번호',
            hintText: '8자 이상 입력해주세요',
            obscureText: _obscurePassword,
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: WriterTheme.neutralGray500,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '비밀번호를 입력해주세요';
              }
              if (value.length < 8) {
                return '비밀번호는 8자 이상이어야 합니다';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 32),
          
          // 로그인 버튼
          Consumer<AuthProvider>(
            builder: (context, auth, child) {
              return LoadingButton(
                onPressed: _handleLogin,
                isLoading: auth.isLoading,
                child: Text(
                  '로그인',
                  style: WriterTheme.subtitleStyle.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // 비밀번호 찾기
          TextButton(
            onPressed: () {
              // TODO: 비밀번호 찾기 기능 구현
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('비밀번호 찾기 기능은 준비 중입니다.'),
                ),
              );
            },
            child: Text(
              '비밀번호를 잊으셨나요?',
              style: WriterTheme.bodyStyle.copyWith(
                color: WriterTheme.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: WriterTheme.neutralGray50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WriterTheme.neutralGray200),
      ),
      child: Column(
        children: [
          Text(
            '아직 계정이 없으신가요?',
            style: WriterTheme.bodyStyle.copyWith(
              color: WriterTheme.neutralGray500,
            ),
          ),
          
          const SizedBox(height: 12),
          
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const RegisterScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      );
                    },
                  ),
                );
              },
              child: Text(
                '회원가입',
                style: WriterTheme.subtitleStyle.copyWith(
                  color: WriterTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}