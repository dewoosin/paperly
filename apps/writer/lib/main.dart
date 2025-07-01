import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/auth_provider.dart';
import 'providers/article_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/writer_profile_provider.dart';
import 'theme/writer_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/writer_home_screen.dart';
import 'screens/profile/profile_setup_screen.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 세로 방향 고정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // 상태바 스타일 설정
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(const PaperlyWriterApp());
}

class PaperlyWriterApp extends StatelessWidget {
  const PaperlyWriterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            apiService: ApiService(),
            storageService: StorageService(),
          ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ArticleProvider>(
          create: (context) => ArticleProvider(
            apiService: ApiService(),
          ),
          update: (context, auth, previous) => previous ?? ArticleProvider(
            apiService: ApiService(),
          )..updateAuthToken(auth.token),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AnalyticsProvider>(
          create: (context) => AnalyticsProvider(
            apiService: ApiService(),
          ),
          update: (context, auth, previous) => previous ?? AnalyticsProvider(
            apiService: ApiService(),
          )..updateAuthToken(auth.token),
        ),
        ChangeNotifierProxyProvider<AuthProvider, DashboardProvider>(
          create: (context) => DashboardProvider(
            ApiService(),
          ),
          update: (context, auth, previous) => previous ?? DashboardProvider(
            ApiService(),
          ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, WriterProfileProvider>(
          create: (context) => WriterProfileProvider(
            apiService: ApiService(),
          ),
          update: (context, auth, previous) => previous ?? WriterProfileProvider(
            apiService: ApiService(),
          )..updateAuthToken(auth.token),
        ),
      ],
      child: MaterialApp(
        title: 'Paperly Writer',
        debugShowCheckedModeBanner: false,
        theme: WriterTheme.lightTheme,
        darkTheme: WriterTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AppWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const WriterHomeScreen(),
          '/profile-setup': (context) => const ProfileSetupScreen(),
        },
      ),
    );
  }
}

class AppWrapper extends StatelessWidget {
  const AppWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.isLoading) {
          return const SplashScreen();
        }
        
        if (auth.isLoggedIn) {
          // 프로필 완성 여부 확인
          if (auth.needsProfileSetup) {
            return const ProfileSetupScreen();
          }
          return const WriterHomeScreen();
        }
        
        return const LoginScreen();
      },
    );
  }
}