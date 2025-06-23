import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../theme/muji_theme.dart';

/// Muji 스타일 버튼 스타일 정의
enum MujiButtonStyle {
  primary,    // 주요 액션 버튼 (채워진 스타일)
  secondary,  // 보조 액션 버튼 (외곽선 스타일)
  text,       // 텍스트만 있는 버튼
}

/// Muji 스타일 버튼 크기 정의
enum MujiButtonSize {
  large,      // 높이 52px
  medium,     // 높이 44px
  small,      // 높이 36px
}

/// Muji 디자인 시스템의 버튼 위젯
/// 
/// 무지의 미니멀한 디자인 철학을 반영한 버튼으로,
/// 다양한 스타일과 크기를 지원합니다.
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

class _MujiButtonState extends State<MujiButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 버튼 높이 계산
  double get _buttonHeight {
    switch (widget.size) {
      case MujiButtonSize.large:
        return 52;
      case MujiButtonSize.medium:
        return 44;
      case MujiButtonSize.small:
        return 36;
    }
  }

  /// 텍스트 스타일 계산
  TextStyle get _textStyle {
    final baseStyle = widget.size == MujiButtonSize.small
        ? MujiTheme.bodySmall
        : MujiTheme.label;
    
    return baseStyle.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );
  }

  /// 버튼 색상 계산
  Color get _backgroundColor {
    if (widget.onPressed == null || widget.isLoading) {
      return MujiTheme.textHint.withOpacity(0.2);
    }
    
    switch (widget.style) {
      case MujiButtonStyle.primary:
        return MujiTheme.primary;
      case MujiButtonStyle.secondary:
      case MujiButtonStyle.text:
        return Colors.transparent;
    }
  }

  /// 텍스트 색상 계산
  Color get _textColor {
    if (widget.onPressed == null || widget.isLoading) {
      return MujiTheme.textDisabled;
    }
    
    switch (widget.style) {
      case MujiButtonStyle.primary:
        return MujiTheme.white;
      case MujiButtonStyle.secondary:
      case MujiButtonStyle.text:
        return MujiTheme.primary;
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

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _animationController.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _animationController.reverse();
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

  Widget _buildContent() {
    if (widget.isLoading) {
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(_textColor),
          ),
        ),
      );
    }

    final text = Text(
      widget.text,
      style: _textStyle.copyWith(color: _textColor),
    );

    if (widget.icon == null) {
      return Center(child: text);
    }

    final icon = Icon(
      widget.icon,
      size: widget.size == MujiButtonSize.small ? 16 : 18,
      color: _textColor,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.iconOnLeft) ...[
          icon,
          const SizedBox(width: 8),
        ],
        text,
        if (!widget.iconOnLeft) ...[
          const SizedBox(width: 8),
          icon,
        ],
      ],
    );
  }
}