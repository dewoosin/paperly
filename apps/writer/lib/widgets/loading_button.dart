import 'package:flutter/material.dart';
import '../theme/writer_theme.dart';

class LoadingButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsets? padding;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool isOutlined;

  const LoadingButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.width,
    this.height,
    this.borderRadius,
    this.isOutlined = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;
    
    if (isOutlined) {
      return SizedBox(
        width: width,
        height: height ?? 50,
        child: OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: foregroundColor ?? WriterTheme.primaryBlue,
            side: BorderSide(
              color: foregroundColor ?? WriterTheme.primaryBlue,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(12),
            ),
            padding: padding ?? const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
          ),
          child: _buildChild(),
        ),
      );
    }
    
    return SizedBox(
      width: width,
      height: height ?? 50,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? WriterTheme.primaryBlue,
          foregroundColor: foregroundColor ?? Colors.white,
          disabledBackgroundColor: WriterTheme.neutralGray300,
          disabledForegroundColor: WriterTheme.neutralGray500,
          elevation: 2,
          shadowColor: (backgroundColor ?? WriterTheme.primaryBlue).withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(12),
          ),
          padding: padding ?? const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
        ),
        child: _buildChild(),
      ),
    );
  }

  Widget _buildChild() {
    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOutlined
                    ? (foregroundColor ?? WriterTheme.primaryBlue)
                    : (foregroundColor ?? Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          child,
        ],
      );
    }
    
    return child;
  }
}