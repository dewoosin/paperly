// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:ui' as ui;
import 'theme/muji_theme.dart';

// 서비스 & 프로바이더
import 'services/auth_service.dart';
import 'providers/auth_provider.dart';

// 스크린
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';

// 설정
import 'config/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 화면 방향 고정
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // 상태바 스타일
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFFCFBF7),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // 서비스 초기화
  final prefs = await SharedPreferences.getInstance();
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));
  
  final authService = AuthService(dio: dio, prefs: prefs);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService: authService)..initialize(),
        ),
      ],
      child: const PaperlyApp(),
    ),
  );
}

class PaperlyApp extends StatelessWidget {
  const PaperlyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paperly',
      debugShowCheckedModeBanner: false,
      theme: MujiTheme.light,
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

// 스플래시 스크린 (로딩 & 인증 확인)
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

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