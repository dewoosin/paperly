/// Paperly 앱 테마 정의 (무지 스타일)
/// 
/// 이 파일은 앱 전체의 색상, 폰트, 컴포넌트 스타일을 정의합니다.
/// 무지(MUJI) 브랜드의 미니멀하고 자연스러운 디자인 철학을 반영합니다.
/// 
/// 디자인 철학:
/// - 자연 소재에서 영감을 받은 색상 (종이, 나무, 돌, 식물)
/// - 불필요한 장식 없는 깔끔한 디자인
/// - 눈에 편안한 낮은 대비와 따뜻한 톤
/// - 가독성과 사용성을 최우선으로 하는 UI
/// 
/// 사용법:
/// - 색상: MujiTheme.sage, MujiTheme.textDark 등
/// - 텍스트 스타일: MujiTheme.h1, MujiTheme.body 등
/// - 테마: MaterialApp의 theme 속성에 MujiTheme.light 사용

import 'package:flutter/material.dart';
/// 무지 스타일 테마 클래스
/// 
/// 모든 색상과 스타일을 static constant로 정의하여
/// 앱 전체에서 일관된 디자인을 유지합니다.
class MujiTheme {
  
  // ============================================================================
  // 📱 기본 배경 색상 (자연 소재 기반)
  // ============================================================================
  
  static const bg = Color(0xFFFAF9F6);           // 메인 배경: 따뜻한 오프화이트 (종이 느낌)
  static const surface = Color(0xFFF6F5F2);      // 표면: 살짝 베이지가 감도는 화이트
  static const card = Color(0xFFFCFCFA);         // 카드 배경: 순수한 종이 느낌
  
  // ============================================================================
  // 📝 텍스트 색상 (먹색 계열)
  // ============================================================================
  
  static const textDark = Color(0xFF2B2A28);     // 제목, 중요 텍스트: 깊은 먹색
  static const textBody = Color(0xFF565450);     // 본문 텍스트: 회갈색
  static const textLight = Color(0xFF8B8A85);    // 보조 텍스트: 연한 회갈색
  static const textHint = Color(0xFFB8B6B0);     // 힌트, 플레이스홀더: 매우 연한 회갈색
  
  // ============================================================================
  // 🌿 자연 색상 팔레트 (브랜드 컬러)
  // ============================================================================
  
  static const sage = Color(0xFF8FA68F);         // 세이지 그린: 메인 브랜드 컬러
  static const bark = Color(0xFF9B8B7A);         // 나무껍질 브라운: 따뜻한 갈색
  static const moss = Color(0xFFA3B5A3);         // 이끼 그린: 부드러운 녹색
  static const clay = Color(0xFFD4C4B0);         // 점토 베이지: 자연스러운 베이지
  static const stone = Color(0xFFC7C0B8);        // 돌 그레이: 중성적인 회색
  static const paper = Color(0xFFF2EFE8);        // 종이 베이지: 따뜻한 배경색
  
  // ============================================================================
  // 🔄 기존 호환성을 위한 색상 별칭
  // ============================================================================
  
  static const sand = bark;                      // 모래색 = 나무껍질색
  static const ocean = Color(0xFF9BB5C7);        // 바다색: 차분한 블루
  static const lavender = Color(0xFFB8A8C7);     // 라벤더: 부드러운 퍼플
  
  // ============================================================================
  // ⚙️ 시스템 컬러 (상태, 알림 등)
  // ============================================================================
  
  static const white = Color(0xFFFFFFFF);        // 순수 화이트
  static const black = Color(0xFF1C1C1C);        // 거의 검정 (완전한 검정보다 부드러움)
  static const primary = sage;                   // 주 색상: 세이지 그린
  static const primaryLight = Color(0xFFA8C0A8); // 밝은 주 색상
  static const primaryDark = Color(0xFF728972);  // 어두운 주 색상
  static const error = Color(0xFFB22222);        // 에러: 자연스러운 빨강
  static const success = Color(0xFF228B22);      // 성공: 숲 녹색
  static const warning = Color(0xFFDAA520);      // 경고: 골든로드 노랑
  static const info = Color(0xFF4682B4);         // 정보: 강철 블루
  static const border = Color(0xFFE0E0E0);       // 테두리: 연한 회색
  static const divider = Color(0xFFEEEEEE);      // 구분선: 매우 연한 회색
  static const bgSecondary = Color(0xFFEDEAE8);  // 보조 배경: 따뜻한 회색
  
  // ============================================================================
  // 📄 텍스트 색상 별칭 (명확한 용도 구분)
  // ============================================================================
  
  static const textPrimary = textDark;           // 주요 텍스트
  static const textSecondary = textBody;         // 보조 텍스트
  static const textTertiary = textLight;         // 3차 텍스트
  static const textDisabled = Color(0xFFBCBCBC); // 비활성화된 텍스트
  
  // ============================================================================
  // 🔄 ArticleDetailScreen 호환성을 위한 색상 별칭
  // ============================================================================
  
  static const primaryColor = primary;           // 주요 색상
  static const secondaryTextColor = textSecondary; // 보조 텍스트 색상
  static const errorColor = error;               // 에러 색상
  static const borderColor = border;             // 테두리 색상
  
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