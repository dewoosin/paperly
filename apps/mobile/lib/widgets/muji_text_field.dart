import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../theme/muji_theme.dart';

/// Muji 디자인 시스템의 텍스트 필드 위젯
/// 
/// 무지의 미니멀한 디자인 철학을 반영한 입력 필드로,
/// 깔끔하고 직관적인 사용자 경험을 제공합니다.
class MujiTextField extends StatefulWidget {
  /// 텍스트 컨트롤러
  final TextEditingController? controller;
  
  /// 라벨 텍스트
  final String? label;
  
  /// 힌트 텍스트
  final String? hint;
  
  /// 도움말 텍스트
  final String? helperText;
  
  /// 에러 텍스트
  final String? errorText;
  
  /// 비밀번호 입력 여부
  final bool obscureText;
  
  /// 읽기 전용 여부
  final bool readOnly;
  
  /// 활성화 여부
  final bool enabled;
  
  /// 자동 포커스 여부
  final bool autofocus;
  
  /// 최대 줄 수
  final int maxLines;
  
  /// 최소 줄 수
  final int? minLines;
  
  /// 최대 글자 수
  final int? maxLength;
  
  /// 키보드 타입
  final TextInputType? keyboardType;
  
  /// 텍스트 입력 액션
  final TextInputAction? textInputAction;
  
  /// 텍스트 대문자 설정
  final TextCapitalization textCapitalization;
  
  /// 입력 포맷터
  final List<TextInputFormatter>? inputFormatters;
  
  /// 값 변경 콜백
  final ValueChanged<String>? onChanged;
  
  /// 제출 콜백
  final ValueChanged<String>? onFieldSubmitted;
  
  /// 유효성 검사 함수
  final String? Function(String?)? validator;
  
  /// 탭 콜백
  final VoidCallback? onTap;
  
  /// 접두사 아이콘
  final IconData? prefixIcon;
  
  /// 접미사 아이콘 위젯
  final Widget? suffixIcon;
  
  /// 필드 채워짐 여부
  final bool filled;
  
  /// 채우기 색상
  final Color? fillColor;

  const MujiTextField({
    Key? key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.onChanged,
    this.onFieldSubmitted,
    this.validator,
    this.onTap,
    this.prefixIcon,
    this.suffixIcon,
    this.filled = true,
    this.fillColor,
  }) : super(key: key);

  @override
  State<MujiTextField> createState() => _MujiTextFieldState();
}

class _MujiTextFieldState extends State<MujiTextField> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _borderColorAnimation;
  
  late FocusNode _focusNode;
  late TextEditingController _controller;
  
  bool _isFocused = false;
  bool _hasError = false;
  
  @override
  void initState() {
    super.initState();
    
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _borderColorAnimation = ColorTween(
      begin: MujiTheme.border,
      end: MujiTheme.primary,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _focusNode.addListener(_handleFocusChange);
  }
  
  @override
  void didUpdateWidget(MujiTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 에러 상태 업데이트
    if (widget.errorText != oldWidget.errorText) {
      setState(() {
        _hasError = widget.errorText != null;
      });
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }
  
  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    
    if (_isFocused) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
  
  /// 테두리 색상 계산
  Color get _borderColor {
    if (_hasError || widget.errorText != null) {
      return MujiTheme.error;
    }
    
    if (!widget.enabled) {
      return MujiTheme.border.withOpacity(0.5);
    }
    
    return _isFocused ? MujiTheme.primary : MujiTheme.border;
  }
  
  /// 채우기 색상 계산
  Color get _fillColor {
    if (widget.fillColor != null) {
      return widget.fillColor!;
    }
    
    if (!widget.enabled) {
      return MujiTheme.bgSecondary;
    }
    
    return MujiTheme.white;
  }
  
  /// 라벨 스타일 계산
  TextStyle get _labelStyle {
    return MujiTheme.label.copyWith(
      color: _hasError || widget.errorText != null
          ? MujiTheme.error
          : _isFocused
              ? MujiTheme.primary
              : MujiTheme.textSecondary,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 라벨
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: _labelStyle,
          ),
          const SizedBox(height: 8),
        ],
        
        // 텍스트 필드
        AnimatedBuilder(
          animation: _borderColorAnimation,
          builder: (context, child) {
            return TextFormField(
              controller: _controller,
              focusNode: _focusNode,
              obscureText: widget.obscureText,
              readOnly: widget.readOnly,
              enabled: widget.enabled,
              autofocus: widget.autofocus,
              maxLines: widget.obscureText ? 1 : widget.maxLines,
              minLines: widget.minLines,
              maxLength: widget.maxLength,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              textCapitalization: widget.textCapitalization,
              inputFormatters: widget.inputFormatters,
              onChanged: widget.onChanged,
              onFieldSubmitted: widget.onFieldSubmitted,
              validator: widget.validator,
              onTap: widget.onTap,
              style: MujiTheme.bodyMedium.copyWith(
                color: widget.enabled ? MujiTheme.textPrimary : MujiTheme.textDisabled,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: MujiTheme.bodyMedium.copyWith(
                  color: MujiTheme.textTertiary,
                ),
                filled: widget.filled,
                fillColor: _fillColor,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: widget.prefixIcon != null ? 12 : 16,
                  vertical: 14,
                ),
                prefixIcon: widget.prefixIcon != null
                    ? Icon(
                        widget.prefixIcon,
                        size: 20,
                        color: _isFocused ? MujiTheme.primary : MujiTheme.textTertiary,
                      )
                    : null,
                suffixIcon: widget.suffixIcon,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MujiTheme.radiusM),
                  borderSide: BorderSide(
                    color: _borderColor,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MujiTheme.radiusM),
                  borderSide: BorderSide(
                    color: _borderColor,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MujiTheme.radiusM),
                  borderSide: BorderSide(
                    color: _borderColorAnimation.value ?? _borderColor,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MujiTheme.radiusM),
                  borderSide: BorderSide(
                    color: MujiTheme.error,
                    width: 1,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MujiTheme.radiusM),
                  borderSide: BorderSide(
                    color: MujiTheme.error,
                    width: 2,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MujiTheme.radiusM),
                  borderSide: BorderSide(
                    color: MujiTheme.border.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                counterText: '', // 글자 수 카운터 숨김
                isDense: false,
              ),
            );
          },
        ),
        
        // 도움말 또는 에러 텍스트
        if (widget.errorText != null || widget.helperText != null) ...[
          const SizedBox(height: 6),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: MujiTheme.caption.copyWith(
              color: widget.errorText != null
                  ? MujiTheme.error
                  : MujiTheme.textTertiary,
            ),
            child: Row(
              children: [
                if (widget.errorText != null)
                  Icon(
                    CupertinoIcons.exclamationmark_circle_fill,
                    size: 14,
                    color: MujiTheme.error,
                  ),
                if (widget.errorText != null)
                  const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.errorText ?? widget.helperText ?? '',
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}