// lib/theme/muji_theme.dart

import 'package:flutter/material.dart';

/// 무지(MUJI) 스타일 테마 정의
/// 
/// 무지의 미니멀리즘 디자인 철학을 반영한 테마입니다.
class MujiTheme {
  // 색상 팔레트
  static const bg = Color(0xFFFCFBF7);
  static const surface = Color(0xFFF9F7F3);
  static const card = Color(0xFFFEFDFC);
  
  static const textDark = Color(0xFF2C2C2C);
  static const textBody = Color(0xFF4A4A4A);
  static const textLight = Color(0xFF7A7A7A);
  static const textHint = Color(0xFFB0B0B0);
  
  static const sage = Color(0xFF90A990);
  static const sand = Color(0xFFD4A09A);
  static const moss = Color(0xFFA8B8A0);
  static const clay = Color(0xFFCBB5A0);
  static const ocean = Color(0xFF9ABFD4);
  static const lavender = Color(0xFFB5A0CB);
  
  // 추가 색상 (위젯에서 필요한 것들)
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF1C1C1C);
  static const primary = sage; // 주 색상은 sage로 설정
  static const primaryLight = Color(0xFFA8C0A8);
  static const primaryDark = Color(0xFF728972);
  static const error = Color(0xFFB22222);
  static const success = Color(0xFF228B22);
  static const warning = Color(0xFFDAA520);
  static const info = Color(0xFF4682B4);
  static const border = Color(0xFFE0E0E0);
  static const divider = Color(0xFFEEEEEE);
  static const bgSecondary = Color(0xFFEDEAE8);
  static const textPrimary = textDark;
  static const textSecondary = textBody;
  static const textTertiary = textLight;
  static const textDisabled = Color(0xFFBCBCBC);
  
  // 간격 및 여백
  static const double spacingXxs = 4.0;
  static const double spacingXs = 8.0;
  static const double spacingS = 12.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;
  
  // 테두리 반경
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusRound = 999.0;
  
  // 그림자
  static final List<BoxShadow> shadowS = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static final List<BoxShadow> shadowM = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  static final List<BoxShadow> shadowL = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
  
  // Material Theme
  static ThemeData get light => ThemeData(
    fontFamily: '.SF Pro Text',
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.light(
      primary: sage,
      secondary: sand,
      surface: surface,
      background: bg,
    ),
  );
  
  // 텍스트 스타일
  static const mobileH1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.2,
    color: textDark,
  );
  
  static const mobileH2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
    color: textDark,
  );
  
  static const mobileH3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.2,
    height: 1.4,
    color: textDark,
  );
  
  static const mobileH4 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
    height: 1.4,
    color: textDark,
  );
  
  static const mobileBody = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.6,
    color: textBody,
  );
  
  static const mobileCaption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.4,
    color: textLight,
  );
  
  static const mobileLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: textLight,
  );
  
  // 추가 텍스트 스타일 (위젯에서 필요한 것들)
  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.6,
    color: textPrimary,
  );
  
  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    color: textPrimary,
  );
  
  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.5,
    color: textSecondary,
  );
  
  static const label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
    color: textPrimary,
  );
  
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.4,
    color: textTertiary,
  );
}