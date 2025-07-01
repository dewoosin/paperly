// apps/mobile/lib/screens/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/muji_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/muji_text_field.dart';
import '../../widgets/muji_button.dart';
import '../../models/auth_models.dart';
import '../../services/device_info_service.dart';
import 'email_verification_screen.dart';

/// 회원가입 화면
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  
  // Step 1: 이메일, 비밀번호
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  
  // Step 2: 개인정보
  final _nameController = TextEditingController();
  DateTime? _birthDate;
  Gender? _selectedGender;
  
  int _currentStep = 0;
  bool _isPasswordVisible = false;
  bool _isPasswordConfirmVisible = false;
  bool _isLoading = false;
  bool _agreedToTerms = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
    _progressController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// 다음 단계로 이동
  void _nextStep() {
    if (_currentStep == 0) {
      // Step 1 검증
      if (!_validateStep1()) return;
      
      setState(() => _currentStep = 1);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _animationController.reset();
      _animationController.forward();
    } else if (_currentStep == 1) {
      // Step 2 검증 후 회원가입
      if (!_validateStep2()) return;
      _handleRegister();
    }
  }

  /// Step 1 검증
  bool _validateStep1() {
    if (_emailController.text.isEmpty) {
      _showError('이메일을 입력해주세요');
      return false;
    }
    
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(_emailController.text)) {
      _showError('올바른 이메일 형식이 아닙니다');
      return false;
    }
    
    if (_passwordController.text.length < 8) {
      _showError('비밀번호는 8자 이상이어야 합니다');
      return false;
    }
    
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(_passwordController.text)) {
      _showError('비밀번호는 영문과 숫자를 포함해야 합니다');
      return false;
    }
    
    if (_passwordController.text != _passwordConfirmController.text) {
      _showError('비밀번호가 일치하지 않습니다');
      return false;
    }
    
    return true;
  }

  /// Step 2 검증
  bool _validateStep2() {
    if (_nameController.text.isEmpty) {
      _showError('이름을 입력해주세요');
      return false;
    }
    
    if (_birthDate == null) {
      _showError('생년월일을 선택해주세요');
      return false;
    }
    
    if (!_agreedToTerms) {
      _showError('이용약관에 동의해주세요');
      return false;
    }
    
    return true;
  }

  /// 에러 메시지 표시
  void _showError(String message) {
    setState(() => _errorMessage = message);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _errorMessage = null);
      }
    });
  }

  /// 회원가입 처리
  Future<void> _handleRegister() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authProvider = context.read<AuthProvider>();
      
      // 디바이스 정보 생성
      final deviceInfo = await DeviceInfoService.createDeviceInfo();
      
      final response = await authProvider.register(
        RegisterRequest(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          birthDate: _birthDate!,
          gender: _selectedGender,
          deviceInfo: deviceInfo,
        ),
      );
      
      if (mounted) {
        // 이메일 인증 화면으로 이동
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(
              email: _emailController.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
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
      body: Stack(
        children: [
          // 뒤로가기 버튼
          Positioned(
            top: safeTop + 20,
            left: 20,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (_currentStep > 0) {
                  setState(() => _currentStep--);
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: MujiTheme.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.arrow_left,
                  size: 20,
                  color: MujiTheme.textBody,
                ),
              ),
            ),
          ),
          
          // 진행 표시
          Positioned(
            top: safeTop + 80,
            left: 24,
            right: 24,
            child: _buildProgressIndicator(),
          ),
          
          // 메인 콘텐츠
          Padding(
            padding: EdgeInsets.only(top: safeTop + 120),
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
              ],
            ),
          ),
        ],
      ),
    );
  }
/// 진행 표시기
  Widget _buildProgressIndicator() {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        return Row(
          children: [
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: MujiTheme.sage.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _currentStep == 0 ? 0.5 : 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: MujiTheme.sage,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Step 1: 계정 정보
  Widget _buildStep1() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '계정 만들기',
                style: MujiTheme.mobileH1,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                '지식의 여정을 시작해보세요',
                style: MujiTheme.mobileCaption,
              ),
              
              const SizedBox(height: 40),
              
              if (_errorMessage != null) ...[
                _buildErrorMessage(),
                const SizedBox(height: 20),
              ],
              
              MujiTextField(
                controller: _emailController,
                label: '이메일',
                hint: 'example@email.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                prefixIcon: CupertinoIcons.mail,
              ),
              
              const SizedBox(height: 20),
              
              MujiTextField(
                controller: _passwordController,
                label: '비밀번호',
                hint: '8자 이상, 영문+숫자',
                obscureText: !_isPasswordVisible,
                textInputAction: TextInputAction.next,
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
              ),
              
              const SizedBox(height: 8),
              
              _buildPasswordStrength(),
              
              const SizedBox(height: 20),
              
              MujiTextField(
                controller: _passwordConfirmController,
                label: '비밀번호 확인',
                hint: '비밀번호를 다시 입력하세요',
                obscureText: !_isPasswordConfirmVisible,
                textInputAction: TextInputAction.done,
                prefixIcon: CupertinoIcons.lock_fill,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordConfirmVisible
                        ? CupertinoIcons.eye_slash
                        : CupertinoIcons.eye,
                    color: MujiTheme.textLight,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordConfirmVisible = !_isPasswordConfirmVisible;
                    });
                  },
                ),
              ),
              
              const SizedBox(height: 40),
              
              MujiButton(
                text: '다음',
                onPressed: _nextStep,
                style: MujiButtonStyle.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 비밀번호 강도 표시
  Widget _buildPasswordStrength() {
    final password = _passwordController.text;
    int strength = 0;
    
    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#\$%\^&\*]').hasMatch(password)) strength++;
    
    Color strengthColor;
    String strengthText;
    
    switch (strength) {
      case 0:
      case 1:
        strengthColor = Colors.red;
        strengthText = '약함';
        break;
      case 2:
      case 3:
        strengthColor = Colors.orange;
        strengthText = '보통';
        break;
      default:
        strengthColor = MujiTheme.sage;
        strengthText = '강함';
    }
    
    if (password.isEmpty) return const SizedBox.shrink();
    
    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(
              3,
              (index) => Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: index < (strength > 0 ? (strength - 1) ~/ 2 + 1 : 0)
                        ? strengthColor
                        : MujiTheme.textHint.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          strengthText,
          style: MujiTheme.mobileLabel.copyWith(
            color: strengthColor,
          ),
        ),
      ],
    );
  }

  /// Step 2: 개인 정보
  Widget _buildStep2() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '기본 정보',
                style: MujiTheme.mobileH1,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                '맞춤형 콘텐츠를 위해 필요해요',
                style: MujiTheme.mobileCaption,
              ),
              
              const SizedBox(height: 40),
              
              if (_errorMessage != null) ...[
                _buildErrorMessage(),
                const SizedBox(height: 20),
              ],
              
              MujiTextField(
                controller: _nameController,
                label: '이름',
                hint: '실명을 입력하세요',
                textInputAction: TextInputAction.done,
                prefixIcon: CupertinoIcons.person,
              ),
              
              const SizedBox(height: 20),
              
              _buildBirthDatePicker(),
              
              const SizedBox(height: 20),
              
              _buildGenderSelector(),
              
              const SizedBox(height: 32),
              
              _buildTermsAgreement(),
              
              const SizedBox(height: 40),
              
              MujiButton(
                text: '시작하기',
                onPressed: _isLoading ? null : _nextStep,
                isLoading: _isLoading,
                style: MujiButtonStyle.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 생년월일 선택
  Widget _buildBirthDatePicker() {
    return GestureDetector(
      onTap: () => _selectBirthDate(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: MujiTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: MujiTheme.textHint.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.calendar,
              size: 20,
              color: MujiTheme.textLight,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '생년월일',
                    style: MujiTheme.mobileLabel.copyWith(
                      color: MujiTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _birthDate != null
                        ? DateFormat('yyyy년 MM월 dd일').format(_birthDate!)
                        : '생년월일을 선택하세요',
                    style: MujiTheme.mobileBody.copyWith(
                      color: _birthDate != null
                          ? MujiTheme.textDark
                          : MujiTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_down,
              size: 16,
              color: MujiTheme.textLight,
            ),
          ],
        ),
      ),
    );
  }

  /// 생년월일 선택 다이얼로그
  void _selectBirthDate() {
    HapticFeedback.selectionClick();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 300,
        decoration: const BoxDecoration(
          color: MujiTheme.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      '취소',
                      style: MujiTheme.mobileBody.copyWith(
                        color: MujiTheme.textLight,
                      ),
                    ),
                  ),
                  Text(
                    '생년월일',
                    style: MujiTheme.mobileH3,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      '완료',
                      style: MujiTheme.mobileBody.copyWith(
                        color: MujiTheme.sage,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
                maximumDate: DateTime.now(),
                minimumDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
                onDateTimeChanged: (date) {
                  setState(() => _birthDate = date);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 성별 선택
  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '성별 (선택)',
          style: MujiTheme.mobileLabel.copyWith(
            color: MujiTheme.textLight,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _GenderOption(
              label: '남성',
              gender: Gender.male,
              isSelected: _selectedGender == Gender.male,
              onTap: () => setState(() => _selectedGender = Gender.male),
            ),
            const SizedBox(width: 12),
            _GenderOption(
              label: '여성',
              gender: Gender.female,
              isSelected: _selectedGender == Gender.female,
              onTap: () => setState(() => _selectedGender = Gender.female),
            ),
            const SizedBox(width: 12),
            _GenderOption(
              label: '기타',
              gender: Gender.other,
              isSelected: _selectedGender == Gender.other,
              onTap: () => setState(() => _selectedGender = Gender.other),
            ),
          ],
        ),
      ],
    );
  }

  /// 약관 동의
  Widget _buildTermsAgreement() {
    return GestureDetector(
      onTap: () {
        setState(() => _agreedToTerms = !_agreedToTerms);
      },
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _agreedToTerms ? MujiTheme.sage : MujiTheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _agreedToTerms 
                    ? MujiTheme.sage 
                    : MujiTheme.textHint.withOpacity(0.3),
                width: _agreedToTerms ? 0 : 1,
              ),
            ),
            child: _agreedToTerms
                ? const Icon(
                    CupertinoIcons.checkmark,
                    size: 16,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: MujiTheme.mobileCaption,
                children: [
                  const TextSpan(text: ''),
                  TextSpan(
                    text: '이용약관',
                    style: TextStyle(
                      color: MujiTheme.sage,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: ' 및 '),
                  TextSpan(
                    text: '개인정보처리방침',
                    style: TextStyle(
                      color: MujiTheme.sage,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: '에 동의합니다'),
                ],
              ),
            ),
          ),
        ],
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
}

/// 성별 선택 옵션
class _GenderOption extends StatelessWidget {
  final String label;
  final Gender gender;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderOption({
    Key? key,
    required this.label,
    required this.gender,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? MujiTheme.sage.withOpacity(0.1) : MujiTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected 
                  ? MujiTheme.sage 
                  : MujiTheme.textHint.withOpacity(0.2),
              width: isSelected ? 1.5 : 0.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: MujiTheme.mobileBody.copyWith(
                color: isSelected ? MujiTheme.sage : MujiTheme.textBody,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
