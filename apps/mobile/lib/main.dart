/// Paperly Mobile App - 메인 진입점
/// 
/// 이 파일은 Flutter 앱의 시작점입니다.
/// 앱 초기화, 테마 설정, 상태 관리, 라우팅을 담당합니다.
/// 
/// 주요 구성 요소:
/// - main(): 앱 진입점, 시스템 설정 및 서비스 초기화
/// - PaperlyApp: 앱의 루트 위젯, 테마와 라우팅 설정
/// - SplashScreen: 로딩 화면, 인증 상태 확인 및 화면 전환

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';      // 시스템 UI 제어용
import 'package:flutter/cupertino.dart';     // iOS 스타일 위젯용
import 'package:provider/provider.dart';     // 상태 관리용
import 'package:dio/dio.dart';               // HTTP 클라이언트
import 'dart:ui' as ui;                      // UI 관련 유틸리티
import 'theme/muji_theme.dart';              // 앱 테마 설정

// 서비스 & 상태 관리
import 'services/auth_service.dart';         // 인증 관련 API 서비스
import 'services/secure_storage_service.dart'; // 보안 저장소 서비스
import 'services/follow_service.dart';       // 팔로우 관련 API 서비스
import 'providers/auth_provider.dart';       // 인증 상태 관리
import 'providers/follow_provider.dart';     // 팔로우 상태 관리

// 화면들
import 'screens/auth/login_screen.dart';     // 로그인 화면
import 'screens/home_screen.dart';           // 홈 화면

// 앱 설정
import 'config/api_config.dart';             // API 엔드포인트 설정

/// 앱의 메인 진입점
/// 
/// 앱 시작 시 필요한 모든 초기화 작업을 수행합니다:
/// 1. Flutter 바인딩 초기화
/// 2. 화면 방향 및 상태바 설정
/// 3. 네트워크 클라이언트 및 로컬 저장소 설정
/// 4. 의존성 주입 및 상태 관리 설정
void main() async {
  // Flutter 프레임워크가 위젯을 그리기 전에 필요한 바인딩을 초기화
  // async main을 사용할 때 반드시 필요
  WidgetsFlutterBinding.ensureInitialized();
  
  // 화면 방향을 세로 모드로만 제한
  // 대부분의 모바일 앱에서 가독성을 위해 세로 모드만 사용
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,    // 정상 세로 방향
    DeviceOrientation.portraitDown,  // 뒤집힌 세로 방향
  ]);
  
  // 상태바와 네비게이션 바의 색상 및 아이콘 스타일 설정
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,              // 상태바 투명
      statusBarIconBrightness: Brightness.dark,        // 상태바 아이콘 어둡게
      systemNavigationBarColor: Color(0xFFFCFBF7),     // 네비게이션 바 배경색
      systemNavigationBarIconBrightness: Brightness.dark, // 네비게이션 바 아이콘 어둡게
    ),
  );
  
  // 핵심 서비스들 초기화
  
  // 보안 저장소: 토큰, 사용자 정보 등 암호화 저장용
  final secureStorage = SecureStorageService();
  
  // HTTP 클라이언트: API 통신용
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,                       // API 서버 주소
    connectTimeout: const Duration(seconds: 5),       // 연결 타임아웃 5초
    receiveTimeout: const Duration(seconds: 3),       // 응답 타임아웃 3초
  ));
  
  // 인증 서비스: 로그인, 회원가입, 토큰 관리 등
  final authService = AuthService(dio: dio, secureStorage: secureStorage);
  
  // 팔로우 서비스: 작가 팔로우, 팔로우 목록 관리 등
  final followService = FollowService(dio: dio);
  
  // 앱 실행: Provider를 통한 상태 관리와 함께
  runApp(
    MultiProvider(
      providers: [
        // 인증 상태 관리자: 로그인 상태, 사용자 정보 등 관리
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService: authService)..initialize(),
        ),
        // 팔로우 상태 관리자: 작가 팔로우, 팔로우 목록 등 관리
        ChangeNotifierProvider(
          create: (_) => FollowProvider(followService: followService),
        ),
      ],
      child: const PaperlyApp(),
    ),
  );
}

/// 앱의 루트 위젯
/// 
/// MaterialApp을 래핑하여 앱 전체의 설정을 관리합니다:
/// - 앱 제목 및 테마
/// - 초기 화면 설정
/// - 라우팅 규칙 정의
class PaperlyApp extends StatelessWidget {
  const PaperlyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paperly',                          // 앱 제목 (태스크 스위처에서 보임)
      debugShowCheckedModeBanner: false,         // 디버그 배너 숨김
      theme: MujiTheme.light,                    // 앱 전체 테마 (무인양품 스타일)
      home: const SplashScreen(),                // 앱 시작 시 첫 화면
      
      // 화면 라우팅 규칙 정의
      // Navigator.pushNamed()로 이동할 수 있는 경로들
      routes: {
        '/login': (context) => const LoginScreen(),  // 로그인 화면
        '/home': (context) => const HomeScreen(),    // 홈 화면
        // 추가 화면들은 여기에 등록
      },
    );
  }
}

/// 스플래시 스크린 (앱 시작 시 보여지는 로딩 화면)
/// 
/// 주요 기능:
/// 1. 앱 로고와 로딩 애니메이션 표시
/// 2. 인증 상태 확인
/// 3. 적절한 화면으로 자동 이동 (로그인 or 홈)
/// 
/// 애니메이션:
/// - FadeTransition: 서서히 나타나는 효과
/// - ScaleTransition: 크기가 변하며 나타나는 효과
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// SplashScreen의 상태 관리 클래스
/// 
/// SingleTickerProviderStateMixin:
/// 애니메이션을 위한 TickerProvider를 제공
/// 하나의 애니메이션 컨트롤러만 사용할 때 효율적
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  
  // 애니메이션 관련 변수들
  late AnimationController _animationController;  // 애니메이션 전체 제어
  late Animation<double> _fadeAnimation;          // 투명도 애니메이션 (0.0 ~ 1.0)
  late Animation<double> _scaleAnimation;         // 크기 애니메이션 (0.8 ~ 1.0)

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.7, curve: Curves.elasticOut),
    ));
    
    _animationController.forward();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // 최소 스플래시 표시 시간
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      
      final authProvider = context.read<AuthProvider>();
      
      // 초기화 대기 (최대 10초)
      int waitCount = 0;
      while (!authProvider.isInitialized && waitCount < 100) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitCount++;
      }
      
      if (!mounted) return;
      
      // 인증 상태에 따라 화면 이동
      if (authProvider.isAuthenticated) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      // 에러 발생 시 로그인 화면으로 이동
      print('스플래시 에러: $e');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MujiTheme.bg,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 로고/아이콘
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: MujiTheme.sage,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.book_outlined,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 앱 이름
                    Text(
                      'Paperly',
                      style: MujiTheme.mobileH1.copyWith(
                        color: MujiTheme.textDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 서브 타이틀
                    Text(
                      '지식의 여정을 시작하세요',
                      style: MujiTheme.mobileBody.copyWith(
                        color: MujiTheme.textLight,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // 로딩 인디케이터
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(MujiTheme.sage),
                        strokeWidth: 2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}