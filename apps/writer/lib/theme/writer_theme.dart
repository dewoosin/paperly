import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// 작가 앱 전용 테마
/// 깔끔하고 집중할 수 있는 디자인을 중심으로 구성
class WriterTheme {
  // 컬러 팔레트 - Blinkist 스타일의 미니멀한 색상
  static const Color primaryBlue = Color(0xFF1B4DFF);      // Blinkist 파랑 (메인 액션)
  static const Color primaryBlueLight = Color(0xFF4F7CFF); // 밝은 파랑
  static const Color primaryBlueDark = Color(0xFF0A2FCC);  // 어두운 파랑
  
  static const Color accentGreen = Color(0xFF00D4AA);      // 성공/완료 상태
  static const Color accentOrange = Color(0xFFFF9F0A);     // 진행중 상태
  static const Color accentRed = Color(0xFFFF4757);        // 삭제/경고
  static const Color accentPurple = Color(0xFF7B68EE);     // 트렌드/분석
  
  static const Color backgroundLight = Color(0xFFFBFCFE); // 메인 배경 (더 밝고 깔끔)
  static const Color neutralGray50 = Color(0xFFFBFCFE);   // 배경
  static const Color neutralGray100 = Color(0xFFF7F8FA);  // 카드 배경
  static const Color neutralGray200 = Color(0xFFEAECF0);  // 경계선
  static const Color neutralGray300 = Color(0xFFD1D5DB);  // 비활성
  static const Color neutralGray400 = Color(0xFF9CA3AF);  // 아이콘/보조
  static const Color neutralGray500 = Color(0xFF6B7280);  // 보조 텍스트
  static const Color neutralGray600 = Color(0xFF475467);  // 설명 텍스트
  static const Color neutralGray700 = Color(0xFF344054);  // 주 텍스트
  static const Color neutralGray800 = Color(0xFF1D2939);  // 진한 텍스트
  static const Color neutralGray900 = Color(0xFF101828);  // 제목 텍스트

  // 텍스트 스타일 - Blinkist 스타일의 향상된 타이포그래피
  static TextStyle get headingStyle => GoogleFonts.inter(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: neutralGray900,
    height: 1.25,
    letterSpacing: -0.5,
  );

  static TextStyle get headlineStyle => GoogleFonts.inter(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: neutralGray900,
    height: 1.3,
    letterSpacing: -0.3,
  );
  
  static TextStyle get titleStyle => GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: neutralGray900,
    height: 1.4,
    letterSpacing: -0.2,
  );
  
  static TextStyle get subtitleStyle => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: neutralGray700,
    height: 1.5,
    letterSpacing: -0.1,
  );
  
  static TextStyle get bodyStyle => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: neutralGray700,
    height: 1.6,
    letterSpacing: 0,
  );
  
  static TextStyle get captionStyle => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: neutralGray500,
    height: 1.5,
    letterSpacing: 0,
  );

  // 라이트 테마
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // 컬러 스킴
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: accentGreen,
        surface: Colors.white,
        background: neutralGray50,
        error: accentRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: neutralGray900,
        onBackground: neutralGray900,
        onError: Colors.white,
      ),
      
      // 앱바 테마
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: neutralGray900,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: titleStyle,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      
      // 카드 테마 - Blinkist 스타일의 큰 라운드 모서리
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      
      // 입력 필드 테마 - 더 큰 라운드와 부드러운 스타일
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: neutralGray100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: captionStyle.copyWith(color: neutralGray500),
        labelStyle: bodyStyle,
      ),
      
      // 버튼 테마 - Blinkist 스타일의 큰 라운드와 부드러운 그림자
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          textStyle: subtitleStyle.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: subtitleStyle.copyWith(
            color: primaryBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          textStyle: subtitleStyle.copyWith(
            color: primaryBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // FAB 테마
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      
      // 바텀 네비게이션 테마
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryBlue,
        unselectedItemColor: neutralGray500,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // 텍스트 테마
      textTheme: TextTheme(
        headlineLarge: headlineStyle,
        headlineMedium: headlineStyle.copyWith(fontSize: 24),
        headlineSmall: titleStyle,
        titleLarge: titleStyle,
        titleMedium: titleStyle.copyWith(fontSize: 18),
        titleSmall: subtitleStyle,
        bodyLarge: bodyStyle.copyWith(fontSize: 16),
        bodyMedium: bodyStyle,
        bodySmall: captionStyle.copyWith(fontSize: 13),
        labelLarge: subtitleStyle.copyWith(fontWeight: FontWeight.w600),
        labelMedium: bodyStyle.copyWith(fontWeight: FontWeight.w600),
        labelSmall: captionStyle.copyWith(fontWeight: FontWeight.w600),
      ),
      
      // 기타
      dividerColor: neutralGray200,
      scaffoldBackgroundColor: neutralGray50,
      
      // 아이콘 테마
      iconTheme: const IconThemeData(
        color: neutralGray700,
        size: 24,
      ),
    );
  }

  // 다크 테마 (추후 구현)
  static ThemeData get darkTheme {
    return lightTheme.copyWith(
      brightness: Brightness.dark,
      // 다크 테마 구현은 필요시 추가
    );
  }

  // 상태별 색상
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return accentGreen;
      case 'draft':
        return accentOrange;
      case 'review':
        return primaryBlue;
      case 'archived':
        return neutralGray500;
      case 'deleted':
        return accentRed;
      default:
        return neutralGray500;
    }
  }

  // 상태별 아이콘
  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return Icons.check_circle;
      case 'draft':
        return Icons.edit;
      case 'review':
        return Icons.rate_review;
      case 'archived':
        return Icons.archive;
      case 'deleted':
        return Icons.delete;
      default:
        return Icons.help_outline;
    }
  }

  // 그림자 스타일 - Blinkist 스타일의 부드러운 그림자
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: neutralGray900.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: neutralGray900.withOpacity(0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: neutralGray900.withOpacity(0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: neutralGray900.withOpacity(0.06),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get largeShadow => [
    BoxShadow(
      color: neutralGray900.withOpacity(0.16),
      blurRadius: 32,
      offset: const Offset(0, 12),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: neutralGray900.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];
}