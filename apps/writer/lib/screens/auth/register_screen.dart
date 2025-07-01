/// Paperly Writer App - 작가 회원가입 화면
/// 
/// 이 파일은 작가 전용 앱의 회원가입 화면을 구현합니다.
/// 작가가 계정을 생성하고 플랫폼에 가입할 수 있도록 합니다.
/// 
/// 주요 기능:
/// - 작가명, 이메일, 비밀번호 입력 폼
/// - 실시간 입력 검증 (클라이언트 단순 체크)
/// - 이용약관 동의 체크박스
/// - 회원가입 API 호출 및 상태 관리
/// - 회원가입 후 프로필 설정 화면으로 자동 이동
/// 
/// 디자인 특징:
/// - 깔끔한 카드 형태의 폼 레이아웃
/// - 입력 필드별 아이콘과 명확한 라벨
/// - 비밀번호 가시성 토글 기능
/// - 로딩 상태 시각적 피드백

import 'package:flutter/material.dart';     // Flutter UI 컴포넌트
import 'package:flutter/services.dart';      // 입력 필터링을 위해 추가
import 'package:provider/provider.dart';     // 상태 관리
import 'dart:async';                          // Timer 사용을 위해 추가
import '../../providers/auth_provider.dart';  // 인증 상태 관리
import '../../theme/writer_theme.dart';       // 작가 앱 테마
import '../../widgets/writer_app_bar.dart';   // 작가 앱 공통 앱바

/// 작가 회원가입 화면 위젯
/// 
/// StatefulWidget을 사용하여 폼 입력 상태와
/// 로딩 상태를 관리합니다.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

/// 회원가입 화면의 상태 관리 클래스
/// 
/// 폼 입력, 유효성 검사, API 호출 등의 상태를 관리합니다.
class _RegisterScreenState extends State<RegisterScreen> {
  
  // ============================================================================
  // 📝 폼 관련 컨트롤러 및 키
  // ============================================================================
  
  final _formKey = GlobalKey<FormState>();              // 폼 전체 유효성 검사용
  final _nameController = TextEditingController();      // 실명 입력 컨트롤러
  final _usernameController = TextEditingController();  // 사용자명(아이디) 입력 컨트롤러
  final _emailController = TextEditingController();     // 이메일 입력 컨트롤러
  final _passwordController = TextEditingController();  // 비밀번호 입력 컨트롤러
  final _confirmPasswordController = TextEditingController(); // 비밀번호 확인 컨트롤러
  
  // ============================================================================
  // 🔐 UI 상태 변수들
  // ============================================================================
  
  bool _isPasswordVisible = false;        // 비밀번호 표시/숨김 상태
  bool _isConfirmPasswordVisible = false; // 비밀번호 확인 표시/숨김 상태
  bool _isLoading = false;                // 회원가입 진행 중 여부
  bool _agreeToTerms = false;             // 이용약관 동의 여부
  DateTime? _selectedBirthDate;           // 선택된 생년월일
  
  // 사용자명 중복 확인 관련 상태
  bool _isCheckingUsername = false;       // 사용자명 중복 확인 중 여부
  String? _usernameCheckMessage;          // 사용자명 중복 확인 메시지
  bool? _isUsernameAvailable;             // 사용자명 사용 가능 여부
  Timer? _usernameCheckTimer;             // 사용자명 중복 확인 디바운스 타이머
  
  // 필드별 에러 메시지
  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _nameError;

  /// 위젯 소멸 시 리소스 정리
  /// 
  /// TextEditingController들을 해제하여 메모리 누수를 방지합니다.
  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WriterTheme.backgroundLight,
      appBar: const SimpleWriterAppBar(
        title: '작가 등록',
        showBackButton: true,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // 제목 및 설명
                Text(
                  'Paperly 작가가 되어보세요',
                  style: WriterTheme.headingStyle.copyWith(
                    color: WriterTheme.neutralGray900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '글을 쓰고, 독자와 소통하며, 창작 활동을 시작해보세요',
                  style: WriterTheme.bodyStyle.copyWith(
                    color: WriterTheme.neutralGray600,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // 회원가입 폼
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: WriterTheme.softShadow,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 사용자명(아이디) 입력 필드 (실시간 중복 확인 포함)
                        // 로그인에 사용될 고유 아이디를 입력받습니다.
                        _buildUsernameField(),
                        
                        const SizedBox(height: 20),
                        
                        // 실명 입력 필드
                        // 가입자의 실제 이름을 입력받습니다.
                        _buildInputField(
                          controller: _nameController,
                          label: '실명',
                          hint: '본명을 입력해주세요',
                          icon: Icons.person_outline,
                          validator: _validateName,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // 이메일 입력 필드
                        // 로그인과 계정 인증에 사용될 이메일을 입력받습니다.
                        _buildInputField(
                          controller: _emailController,
                          label: '이메일',
                          hint: 'example@email.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress, // 이메일 키보드 표시
                          validator: _validateEmail,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // 생년월일 선택 필드
                        // 서버에서 필수로 요구하는 생년월일을 선택받습니다.
                        _buildBirthDateField(),
                        
                        const SizedBox(height: 20),
                        
                        // 비밀번호 입력 필드
                        // 계정 보안을 위한 비밀번호를 입력받습니다.
                        _buildInputField(
                          controller: _passwordController,
                          label: '비밀번호',
                          hint: '영문, 숫자, 특수문자 중 2가지 이상 포함',
                          icon: Icons.lock_outline,
                          isPassword: true,                    // 비밀번호 필드임을 표시
                          isPasswordVisible: _isPasswordVisible, // 비밀번호 표시 상태
                          onTogglePasswordVisibility: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                          validator: _validatePassword,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // 비밀번호 확인 입력 필드
                        // 비밀번호 입력 오류를 방지하기 위한 재입력 확인
                        _buildInputField(
                          controller: _confirmPasswordController,
                          label: '비밀번호 확인',
                          hint: '비밀번호를 다시 입력해주세요',
                          icon: Icons.lock_outline,
                          isPassword: true,                           // 비밀번호 필드임을 표시
                          isPasswordVisible: _isConfirmPasswordVisible, // 비밀번호 표시 상태
                          onTogglePasswordVisibility: () {
                            setState(() {
                              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                            });
                          },
                          validator: (value) {
                            // 비밀번호 일치 여부 검증
                            if (value == null || value.isEmpty) {
                              return '비밀번호 확인을 입력해주세요';
                            }
                            if (value != _passwordController.text) {
                              return '비밀번호가 일치하지 않습니다';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // 이용약관 및 개인정보처리방침 동의
                        // 법적 요구사항에 따른 필수 동의 항목
                        Row(
                          children: [
                            Checkbox(
                              value: _agreeToTerms,
                              onChanged: (value) {
                                setState(() {
                                  _agreeToTerms = value ?? false;
                                });
                              },
                              activeColor: WriterTheme.primaryBlue,
                            ),
                            Expanded(
                              child: GestureDetector(
                                // 텍스트를 탭해도 체크박스가 토글되도록 함
                                onTap: () {
                                  setState(() {
                                    _agreeToTerms = !_agreeToTerms;
                                  });
                                },
                                child: Text(
                                  '이용약관 및 개인정보처리방침에 동의합니다',
                                  style: WriterTheme.bodyStyle.copyWith(
                                    color: WriterTheme.neutralGray700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // 회원가입 실행 버튼
                        // 로딩 중이거나 약관 미동의, 생년월일 미선택, 사용자명 중복 시 비활성화
                        _buildRegisterButton(),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 로그인 링크
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '이미 계정이 있나요? ',
                      style: WriterTheme.bodyStyle.copyWith(
                        color: WriterTheme.neutralGray600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        '로그인',
                        style: WriterTheme.bodyStyle.copyWith(
                          color: WriterTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 통일된 입력 필드 위젯 빌더
  /// 
  /// 앱 전체에서 일관된 디자인의 입력 필드를 생성합니다.
  /// 
  /// 매개변수:
  /// - controller: 텍스트 입력 컨트롤러
  /// - label: 필드 상단 라벨 텍스트
  /// - hint: 플레이스홀더 텍스트
  /// - icon: 좌측 아이콘
  /// - isPassword: 비밀번호 필드 여부
  /// - isPasswordVisible: 비밀번호 표시 상태
  /// - onTogglePasswordVisibility: 비밀번호 표시 토글 콜백
  /// - keyboardType: 키보드 타입
  /// - validator: 유효성 검사 함수
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePasswordVisibility,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: WriterTheme.subtitleStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: WriterTheme.neutralGray800,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !isPasswordVisible,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: WriterTheme.bodyStyle.copyWith(
              color: WriterTheme.neutralGray500,
            ),
            prefixIcon: Icon(
              icon,
              color: WriterTheme.neutralGray500,
              size: 20,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: WriterTheme.neutralGray500,
                      size: 20,
                    ),
                    onPressed: onTogglePasswordVisibility,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: WriterTheme.neutralGray300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: WriterTheme.neutralGray300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: WriterTheme.primaryBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: WriterTheme.accentRed),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: WriterTheme.accentRed, width: 2),
            ),
            filled: true,
            fillColor: WriterTheme.neutralGray50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  /// 회원가입 처리 함수
  /// 
  /// 폼 유효성 검사 → API 호출 → 결과 처리 → 화면 이동 순으로 진행
  /// 
  /// 플로우:
  /// 1. 클라이언트 측 폼 검증
  /// 2. AuthProvider를 통한 서버 API 호출
  /// 3. 성공 시: 프로필 설정 or 홈 화면으로 이동
  /// 4. 실패 시: 구체적인 에러 메시지 표시
  Future<void> _register() async {
    // 1단계: 폼 유효성 및 필수 조건 검사
    if (!_formKey.currentState!.validate()) {
      _showErrorMessage('입력 정보를 다시 확인해주세요');
      return;
    }
    
    if (_selectedBirthDate == null) {
      _showErrorMessage('생년월일을 선택해주세요');
      return;
    }
    
    if (!_agreeToTerms) {
      _showErrorMessage('이용약관에 동의해주세요');
      return;
    }
    
    if (_isUsernameAvailable != true) {
      _showErrorMessage('사용자명 중복 확인을 완료해주세요');
      return;
    }

    // 2단계: 로딩 상태 시작
    setState(() {
      _isLoading = true;
    });

    try {
      // 3단계: AuthProvider를 통한 회원가입 API 호출
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.register(
        name: _nameController.text.trim(),      // 실명 (공백 제거)
        username: _usernameController.text.trim(), // 사용자명 (공백 제거)
        email: _emailController.text.trim(),    // 이메일 (공백 제거)
        password: _passwordController.text,     // 비밀번호 (원본 유지)
        birthDate: _selectedBirthDate,          // 생년월일 (YYYY-MM-DD 형식으로 전송)
      );

      // 4단계: 회원가입 성공 처리
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('환영합니다! 작가 등록이 완료되었습니다.'),
            backgroundColor: WriterTheme.accentGreen,
          ),
        );
        
        // 프로필 완성 여부에 따라 화면 이동 결정
        if (authProvider.needsProfileSetup) {
          // 프로필 미완성 → 프로필 설정 화면으로
          Navigator.pushReplacementNamed(context, '/profile-setup');
        } else {
          // 프로필 완성 → 홈 화면으로
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else if (mounted) {
        // 5단계: 회원가입 실패 처리 - 구체적인 에러 메시지 표시
        final errorMessage = authProvider.error ?? '회원가입에 실패했습니다.';
        _showErrorMessage(_getSpecificErrorMessage(errorMessage));
      }
    } catch (e) {
      // 6단계: 예외 상황 처리 (네트워크 오류 등)
      if (mounted) {
        _showErrorMessage('네트워크 오류가 발생했습니다. 다시 시도해주세요.');
      }
    } finally {
      // 7단계: 로딩 상태 종료 (성공/실패 무관)
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 구체적인 에러 메시지 반환
  String _getSpecificErrorMessage(String originalError) {
    if (originalError.contains('이메일')) {
      if (originalError.contains('이미')) {
        return '이미 사용 중인 이메일입니다. 다른 이메일을 사용해주세요.';
      } else if (originalError.contains('형식')) {
        return '올바른 이메일 형식을 입력해주세요.';
      }
    } else if (originalError.contains('비밀번호')) {
      return '비밀번호는 8자 이상, 영문/숫자/특수문자 중 2가지 이상 포함해야 합니다.';
    } else if (originalError.contains('아이디') || originalError.contains('사용자명')) {
      return '이미 사용 중인 아이디입니다. 다른 아이디를 사용해주세요.';
    } else if (originalError.contains('나이') || originalError.contains('14세')) {
      return '14세 이상만 가입할 수 있습니다.';
    } else if (originalError.contains('네트워크')) {
      return '네트워크 연결을 확인하고 다시 시도해주세요.';
    }
    
    return originalError.isEmpty ? '회원가입 중 오류가 발생했습니다.' : originalError;
  }

  /// 에러 메시지 표시 헬퍼 메서드
  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: WriterTheme.accentRed,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// 생년월일 선택 필드 위젯 빌더
  /// 
  /// DatePicker를 이용하여 생년월일을 선택할 수 있는 필드를 생성합니다.
  /// 서버에서 YYYY-MM-DD 형식으로 요구하므로 해당 형식으로 변환하여 전송합니다.
  Widget _buildBirthDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '생년월일',
          style: WriterTheme.subtitleStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: WriterTheme.neutralGray800,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)), // 20세 기본값
              firstDate: DateTime.now().subtract(const Duration(days: 365 * 120)), // 120년 전까지
              lastDate: DateTime.now().subtract(const Duration(days: 365 * 14)), // 14세 제한
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: WriterTheme.primaryBlue,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: WriterTheme.neutralGray800,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            
            if (picked != null) {
              setState(() {
                _selectedBirthDate = picked;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: WriterTheme.neutralGray50,
              border: Border.all(color: WriterTheme.neutralGray300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: WriterTheme.neutralGray500,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedBirthDate != null
                        ? '${_selectedBirthDate!.year}년 ${_selectedBirthDate!.month}월 ${_selectedBirthDate!.day}일'
                        : '생년월일을 선택해주세요',
                    style: WriterTheme.bodyStyle.copyWith(
                      color: _selectedBirthDate != null 
                          ? WriterTheme.neutralGray800 
                          : WriterTheme.neutralGray500,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: WriterTheme.neutralGray500,
                ),
              ],
            ),
          ),
        ),
        if (_selectedBirthDate != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '만 ${_calculateAge(_selectedBirthDate!)}세',
              style: WriterTheme.captionStyle.copyWith(
                color: WriterTheme.neutralGray600,
              ),
            ),
          ),
      ],
    );
  }

  /// 사용자명 입력 필드 (버튼 클릭 중복 확인)
  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '아이디(사용자명)',
          style: WriterTheme.subtitleStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: WriterTheme.neutralGray800,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _usernameController,
                validator: _validateUsername,
                keyboardType: TextInputType.text,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                ],
                onChanged: (value) {
                  // 입력이 변경되면 이전 확인 결과 초기화
                  if (_isUsernameAvailable != null) {
                    setState(() {
                      _isUsernameAvailable = null;
                      _usernameCheckMessage = null;
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: '영문, 숫자, 언더스코어(_)만 사용',
                  hintStyle: WriterTheme.bodyStyle.copyWith(
                    color: WriterTheme.neutralGray500,
                  ),
                  prefixIcon: Icon(
                    Icons.alternate_email,
                    color: WriterTheme.neutralGray500,
                    size: 20,
                  ),
                  suffixIcon: _isUsernameAvailable != null
                      ? Icon(
                          _isUsernameAvailable! ? Icons.check_circle : Icons.error,
                          color: _isUsernameAvailable! 
                              ? WriterTheme.accentGreen 
                              : WriterTheme.accentRed,
                          size: 20,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: WriterTheme.neutralGray300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _isUsernameAvailable == false 
                          ? WriterTheme.accentRed 
                          : _isUsernameAvailable == true
                              ? WriterTheme.accentGreen
                              : WriterTheme.neutralGray300
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _isUsernameAvailable == false 
                          ? WriterTheme.accentRed 
                          : WriterTheme.primaryBlue, 
                      width: 2
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: WriterTheme.accentRed),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: WriterTheme.accentRed, width: 2),
                  ),
                  filled: true,
                  fillColor: WriterTheme.neutralGray50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: ListenableBuilder(
                listenable: _usernameController,
                builder: (context, child) {
                  final canCheck = !_isCheckingUsername && _usernameController.text.trim().isNotEmpty;
                  return ElevatedButton(
                    onPressed: canCheck ? _checkUsernameAvailability : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WriterTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isCheckingUsername
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('중복확인', style: TextStyle(fontSize: 12)),
                  );
                },
              ),
            ),
          ],
        ),
        if (_usernameCheckMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _usernameCheckMessage!,
              style: WriterTheme.captionStyle.copyWith(
                color: _isUsernameAvailable == true 
                    ? WriterTheme.accentGreen 
                    : WriterTheme.accentRed,
              ),
            ),
          ),
      ],
    );
  }

  /// 향상된 회원가입 버튼
  Widget _buildRegisterButton() {
    final bool canRegister = !_isLoading && 
                            _agreeToTerms && 
                            _selectedBirthDate != null &&
                            _isUsernameAvailable == true;
    
    return Column(
      children: [
        if (_isLoading)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                LinearProgressIndicator(
                  backgroundColor: WriterTheme.neutralGray200,
                  valueColor: AlwaysStoppedAnimation(WriterTheme.primaryBlue),
                ),
                const SizedBox(height: 8),
                Text(
                  '계정을 생성하고 있습니다...',
                  style: WriterTheme.captionStyle.copyWith(
                    color: WriterTheme.neutralGray600,
                  ),
                ),
              ],
            ),
          ),
        ElevatedButton(
          onPressed: canRegister ? _register : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: WriterTheme.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            disabledBackgroundColor: WriterTheme.neutralGray300,
            elevation: 0,
          ),
          child: _isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '등록 중...',
                      style: WriterTheme.subtitleStyle.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : Text(
                  '작가 등록하기',
                  style: WriterTheme.subtitleStyle.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        if (!canRegister && !_isLoading)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _selectedBirthDate == null 
                  ? '생년월일을 선택해주세요'
                  : !_agreeToTerms 
                      ? '이용약관에 동의해주세요'
                      : _isUsernameAvailable != true
                          ? '사용자명 중복 확인을 완료해주세요'
                          : '모든 필수 항목을 입력해주세요',
              style: WriterTheme.captionStyle.copyWith(
                color: WriterTheme.accentRed,
              ),
            ),
          ),
      ],
    );
  }

  /// 만 나이 계산 함수
  /// 
  /// 생년월일을 기준으로 만 나이를 계산합니다.
  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }

  /// 사용자명 중복 확인 (버튼 클릭 시)
  Future<void> _checkUsernameAvailability() async {
    final username = _usernameController.text.trim();
    
    // 사용자명이 비어있거나 3자 미만이면 확인하지 않음
    if (username.isEmpty || username.length < 3) {
      setState(() {
        _usernameCheckMessage = '아이디는 3자 이상 입력해주세요';
        _isUsernameAvailable = false;
      });
      return;
    }
    
    // 기본 형식 검증 먼저 수행
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      setState(() {
        _usernameCheckMessage = '영문, 숫자, 언더스코어(_)만 사용 가능합니다';
        _isUsernameAvailable = false;
      });
      return;
    }
    
    setState(() {
      _isCheckingUsername = true;
      _usernameCheckMessage = null;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.checkUsernameAvailability(username);
      
      if (result != null && mounted) {
        final data = result['data'] ?? result;
        final available = data['available'] ?? false;
        final message = result['message'] ?? data['message'] ?? 
            (available ? '사용 가능한 아이디입니다' : '이미 사용 중인 아이디입니다');
        
        setState(() {
          _isUsernameAvailable = available;
          _usernameCheckMessage = message;
          _isCheckingUsername = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _usernameCheckMessage = '중복 확인 중 오류가 발생했습니다. 다시 시도해주세요.';
            _isUsernameAvailable = null;
            _isCheckingUsername = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _usernameCheckMessage = '중복 확인 중 오류가 발생했습니다. 다시 시도해주세요.';
          _isUsernameAvailable = null;
          _isCheckingUsername = false;
        });
      }
    }
  }

  /// 강화된 이메일 검증
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '이메일을 입력해주세요';
    }
    
    // 더 강력한 이메일 정규식
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    
    if (!emailRegex.hasMatch(value.trim())) {
      return '올바른 이메일 형식을 입력해주세요';
    }
    
    return null;
  }

  /// 강화된 비밀번호 검증
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요';
    }
    
    if (value.length < 8) {
      return '비밀번호는 최소 8자 이상이어야 합니다';
    }
    
    if (value.length > 128) {
      return '비밀번호가 너무 깁니다 (최대 128자)';
    }
    
    // 영문, 숫자, 특수문자 중 2가지 이상 포함 확인
    bool hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
    bool hasNumber = RegExp(r'[0-9]').hasMatch(value);
    bool hasSpecial = RegExp(r'[!@#$%^&*(),.?\":{}|<>]').hasMatch(value);
    
    int complexity = 0;
    if (hasLetter) complexity++;
    if (hasNumber) complexity++;
    if (hasSpecial) complexity++;
    
    if (complexity < 2) {
      return '영문, 숫자, 특수문자 중 2가지 이상 포함해야 합니다';
    }
    
    return null;
  }

  /// 강화된 사용자명 검증
  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '아이디를 입력해주세요';
    }
    
    final trimmed = value.trim();
    
    if (trimmed.length < 3) {
      return '아이디는 3자 이상이어야 합니다';
    }
    
    if (trimmed.length > 20) {
      return '아이디는 20자 이하여야 합니다';
    }
    
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmed)) {
      return '영문, 숫자, 언더스코어(_)만 사용 가능합니다';
    }
    
    // 연속된 언더스코어 금지
    if (trimmed.contains('__')) {
      return '연속된 언더스코어는 사용할 수 없습니다';
    }
    
    // 처음이나 마지막에 언더스코어 금지
    if (trimmed.startsWith('_') || trimmed.endsWith('_')) {
      return '아이디는 언더스코어로 시작하거나 끝날 수 없습니다';
    }
    
    // 예약어 확인
    final reserved = ['admin', 'root', 'system', 'paperly', 'writer', 'author'];
    if (reserved.contains(trimmed.toLowerCase())) {
      return '사용할 수 없는 아이디입니다';
    }
    
    return null;
  }

  /// 이름 검증
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '실명을 입력해주세요';
    }
    
    final trimmed = value.trim();
    
    if (trimmed.length < 2) {
      return '실명은 2자 이상이어야 합니다';
    }
    
    if (trimmed.length > 50) {
      return '실명이 너무 깁니다 (최대 50자)';
    }
    
    return null;
  }
}