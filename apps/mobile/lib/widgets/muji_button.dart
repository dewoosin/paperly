/// Paperly Mobile App - 무지 스타일 버튼 위젯
/// 
/// 이 파일은 무인양품의 미니멀한 디자인 철학을 반영한
/// 재사용 가능한 버튼 컴포넌트를 구현합니다.
/// 
/// 주요 기능:
/// - 3가지 스타일: Primary(채워진), Secondary(외곽선), Text(텍스트만)
/// - 3가지 크기: Large(52px), Medium(44px), Small(36px)
/// - 로딩 상태 표시 및 비활성화 상태 처리
/// - 부드러운 터치 애니메이션과 햅틱 피드백
/// - 아이콘 지원 (좌측/우측 배치 가능)
/// - 전체 너비 또는 콘텐츠 너비 선택 가능
/// 
/// 디자인 특징:
/// - 자연스러운 색상과 부드러운 그림자
/// - 터치 시 0.95배 스케일 애니메이션
/// - 일관된 패딩과 타이포그래피
/// - 접근성을 고려한 색상 대비

import 'package:flutter/material.dart';   // Flutter UI 컴포넌트
import 'package:flutter/cupertino.dart';  // iOS 스타일 아이콘
import 'package:flutter/services.dart';   // 햅틱 피드백
import '../theme/muji_theme.dart';         // 무지 테마 시스템

/// 무지 스타일 버튼의 시각적 스타일 열거형
/// 
/// 각 스타일은 서로 다른 시각적 위계와 용도를 가집니다:
/// - primary: 가장 중요한 액션용 (CTA 버튼 등)
/// - secondary: 보조 액션용 (취소, 뒤로가기 등)
/// - text: 최소한의 강조가 필요한 액션용
enum MujiButtonStyle {
  primary,    // 주요 액션 버튼 (세이지 그린 배경)
  secondary,  // 보조 액션 버튼 (투명 배경 + 세이지 테두리)
  text,       // 텍스트만 있는 버튼 (투명 배경 + 세이지 텍스트)
}

/// 무지 스타일 버튼의 크기 옵션 열거형
/// 
/// 사용 컨텍스트에 따라 적절한 크기를 선택할 수 있습니다:
/// - large: 메인 액션 버튼용 (로그인, 회원가입 등)
/// - medium: 일반적인 폼 액션용
/// - small: 인라인 액션이나 제한된 공간용
enum MujiButtonSize {
  large,      // 높이 52px (주요 액션)
  medium,     // 높이 44px (일반 액션)
  small,      // 높이 36px (보조 액션)
}

/// 무지 디자인 시스템의 버튼 위젯
/// 
/// 무인양품의 미니멀한 디자인 철학을 반영한 버튼 컴포넌트입니다.
/// 일관된 사용자 경험을 위해 앱 전체에서 사용되는 표준 버튼입니다.
/// 
/// 특징:
/// - 무지 브랜드 색상 (세이지 그린) 사용
/// - 부드러운 터치 애니메이션 (0.95배 스케일)
/// - 햅틱 피드백으로 촉각적 반응
/// - 로딩 상태 시 스피너 표시
/// - 비활성화 상태 시 회색톤 처리
/// - 접근성 고려한 충분한 터치 영역
class MujiButton extends StatefulWidget {
  /// 버튼에 표시될 텍스트
  final String text;
  
  /// 버튼 클릭 시 실행될 콜백
  /// null인 경우 버튼이 비활성화됨
  final VoidCallback? onPressed;
  
  /// 버튼 스타일
  final MujiButtonStyle style;
  
  /// 버튼 크기
  final MujiButtonSize size;
  
  /// 로딩 상태
  final bool isLoading;
  
  /// 전체 너비 사용 여부
  final bool fullWidth;
  
  /// 버튼 아이콘 (선택사항)
  final IconData? icon;
  
  /// 아이콘 위치 (true: 왼쪽, false: 오른쪽)
  final bool iconOnLeft;

  const MujiButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.style = MujiButtonStyle.primary,
    this.size = MujiButtonSize.large,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
    this.iconOnLeft = true,
  }) : super(key: key);

  @override
  State<MujiButton> createState() => _MujiButtonState();
}

/// 무지 버튼의 상태 관리 클래스
/// 
/// SingleTickerProviderStateMixin:
/// 터치 애니메이션을 위한 단일 애니메이션 컨트롤러 사용
class _MujiButtonState extends State<MujiButton> 
    with SingleTickerProviderStateMixin {
  
  // ============================================================================
  // 🎨 애니메이션 관련 변수들
  // ============================================================================
  
  late AnimationController _animationController; // 터치 애니메이션 제어
  late Animation<double> _scaleAnimation;        // 스케일 변화 애니메이션 (1.0 → 0.95)
  
  /// 위젯 초기화
  /// 
  /// 터치 시 버튼이 살짝 작아지는 애니메이션을 설정합니다.
  /// 150ms의 빠른 애니메이션으로 즉각적인 피드백을 제공합니다.
  @override
  void initState() {
    super.initState();
    
    // 터치 애니메이션 컨트롤러 초기화
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150), // 빠른 반응을 위한 짧은 지속시간
      vsync: this,
    );
    
    // 스케일 애니메이션: 터치 시 5% 축소 효과
    _scaleAnimation = Tween<double>(
      begin: 1.0,    // 원래 크기
      end: 0.95,     // 5% 축소
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,  // 부드러운 가속/감속
    ));
  }

  /// 위젯 소멸 시 리소스 정리
  /// 
  /// 애니메이션 컨트롤러를 해제하여 메모리 누수를 방지합니다.
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 크기별 버튼 높이 계산
  /// 
  /// 디자인 시스템에 정의된 표준 높이값을 반환합니다.
  /// 충분한 터치 영역을 보장하여 사용성을 높입니다.
  double get _buttonHeight {
    switch (widget.size) {
      case MujiButtonSize.large:
        return 52;  // 메인 액션용 - 44px 최소 터치 영역 + 여백
      case MujiButtonSize.medium:
        return 44;  // 일반 액션용 - Apple/Material 가이드라인 준수
      case MujiButtonSize.small:
        return 36;  // 제한된 공간용 - 최소 터치 영역 확보
    }
  }

  /// 크기별 텍스트 스타일 계산
  /// 
  /// 버튼 크기에 적절한 텍스트 스타일을 선택하고
  /// 버튼에 최적화된 폰트 두께와 자간을 적용합니다.
  TextStyle get _textStyle {
    // 작은 버튼은 작은 텍스트, 나머지는 라벨 크기 사용
    final baseStyle = widget.size == MujiButtonSize.small
        ? MujiTheme.bodySmall   // 12px - 작은 버튼용
        : MujiTheme.label;      // 14px - 일반/큰 버튼용
    
    return baseStyle.copyWith(
      fontWeight: FontWeight.w600,  // 세미볼드로 가독성 향상
      letterSpacing: 0.5,           // 약간의 자간으로 고급스러운 느낌
    );
  }

  /// 스타일과 상태별 배경색 계산
  /// 
  /// 버튼 스타일과 활성화 상태에 따라 적절한 배경색을 반환합니다.
  /// 비활성화 상태에서는 시각적으로 구분되도록 회색톤을 사용합니다.
  Color get _backgroundColor {
    // 비활성화 또는 로딩 상태: 연한 회색
    if (widget.onPressed == null || widget.isLoading) {
      return MujiTheme.textHint.withOpacity(0.2);
    }
    
    switch (widget.style) {
      case MujiButtonStyle.primary:
        return MujiTheme.primary;      // 세이지 그린 배경
      case MujiButtonStyle.secondary:
      case MujiButtonStyle.text:
        return Colors.transparent;     // 투명 배경
    }
  }

  /// 스타일과 상태별 텍스트 색상 계산
  /// 
  /// 배경색과 대비되어 가독성을 보장하는 텍스트 색상을 반환합니다.
  /// WCAG 접근성 가이드라인을 준수하여 충분한 대비를 제공합니다.
  Color get _textColor {
    // 비활성화 또는 로딩 상태: 회색 텍스트
    if (widget.onPressed == null || widget.isLoading) {
      return MujiTheme.textDisabled;
    }
    
    switch (widget.style) {
      case MujiButtonStyle.primary:
        return MujiTheme.white;        // 어두운 배경에 흰색 텍스트
      case MujiButtonStyle.secondary:
      case MujiButtonStyle.text:
        return MujiTheme.primary;      // 밝은 배경에 세이지 그린 텍스트
    }
  }

  /// 테두리 계산
  Border? get _border {
    if (widget.style == MujiButtonStyle.secondary) {
      return Border.all(
        color: widget.onPressed == null || widget.isLoading
            ? MujiTheme.textHint.withOpacity(0.3)
            : MujiTheme.primary,
        width: 1.5,
      );
    }
    return null;
  }

  /// 패딩 계산
  EdgeInsetsGeometry get _padding {
    final horizontal = widget.size == MujiButtonSize.small ? 16.0 : 24.0;
    return EdgeInsets.symmetric(horizontal: horizontal);
  }

  /// 터치 시작 시 처리
  /// 
  /// 버튼을 누르는 순간 스케일 애니메이션을 시작하고
  /// 햅틱 피드백을 제공하여 사용자에게 즉각적인 반응을 줍니다.
  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _animationController.forward();   // 버튼 축소 애니메이션 시작
      HapticFeedback.lightImpact();     // 가벼운 햅틱 피드백
    }
  }

  /// 터치 완료 시 처리
  /// 
  /// 손가락을 떼는 순간 버튼을 원래 크기로 복원합니다.
  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _animationController.reverse();   // 버튼 원래 크기로 복원
    }
  }

  /// 터치 취소 시 처리
  /// 
  /// 터치가 버튼 영역을 벗어나 취소된 경우에도
  /// 버튼을 원래 크기로 복원합니다.
  void _handleTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _animationController.reverse();   // 버튼 원래 크기로 복원
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isLoading ? null : widget.onPressed,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: _buttonHeight,
              width: widget.fullWidth ? double.infinity : null,
              padding: _padding,
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(MujiTheme.radiusM),
                border: _border,
                boxShadow: widget.style == MujiButtonStyle.primary &&
                        widget.onPressed != null &&
                        !widget.isLoading
                    ? MujiTheme.shadowS
                    : null,
              ),
              child: _buildContent(),
            ),
          );
        },
      ),
    );
  }

  /// 버튼 내용(텍스트/아이콘/로딩 인디케이터) 구성
  /// 
  /// 버튼의 상태와 설정에 따라 적절한 내용을 표시합니다:
  /// - 로딩 중: 스피너 표시
  /// - 아이콘 없음: 텍스트만 중앙 배치
  /// - 아이콘 있음: 아이콘과 텍스트를 지정된 순서로 배치
  Widget _buildContent() {
    // 로딩 상태: 스피너 표시
    if (widget.isLoading) {
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,                      // 얇은 스피너
            valueColor: AlwaysStoppedAnimation(_textColor), // 텍스트 색상과 동일
          ),
        ),
      );
    }

    // 버튼 텍스트 생성
    final text = Text(
      widget.text,
      style: _textStyle.copyWith(color: _textColor),
    );

    // 아이콘이 없는 경우: 텍스트만 중앙 배치
    if (widget.icon == null) {
      return Center(child: text);
    }

    // 아이콘 생성 (크기별 다른 아이콘 크기)
    final icon = Icon(
      widget.icon,
      size: widget.size == MujiButtonSize.small ? 16 : 18,
      color: _textColor,
    );

    // 아이콘과 텍스트를 수평으로 배치
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 아이콘이 왼쪽에 있는 경우
        if (widget.iconOnLeft) ...[
          icon,
          const SizedBox(width: 8),   // 아이콘과 텍스트 사이 간격
        ],
        text,
        // 아이콘이 오른쪽에 있는 경우
        if (!widget.iconOnLeft) ...[
          const SizedBox(width: 8),   // 텍스트와 아이콘 사이 간격
          icon,
        ],
      ],
    );
  }
}