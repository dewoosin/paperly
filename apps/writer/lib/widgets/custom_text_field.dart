import 'package:flutter/material.dart';
import '../theme/writer_theme.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextStyle? textStyle;
  final EdgeInsets? contentPadding;
  final String? helperText;
  final String? errorText;

  const CustomTextField({
    Key? key,
    this.controller,
    this.label,
    this.hintText,
    this.validator,
    this.onChanged,
    this.onTap,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.textStyle,
    this.contentPadding,
    this.helperText,
    this.errorText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: WriterTheme.bodyStyle.copyWith(
              fontWeight: FontWeight.w600,
              color: WriterTheme.neutralGray700,
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        TextFormField(
          controller: controller,
          validator: validator,
          onChanged: onChanged,
          onTap: onTap,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          obscureText: obscureText,
          readOnly: readOnly,
          enabled: enabled,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          style: textStyle ?? WriterTheme.bodyStyle,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: WriterTheme.neutralGray500,
                    size: 20,
                  )
                : null,
            suffixIcon: suffixIcon,
            contentPadding: contentPadding ?? const EdgeInsets.all(16),
            helperText: helperText,
            errorText: errorText,
            
            // 기본 테마 재정의
            filled: true,
            fillColor: enabled 
                ? WriterTheme.neutralGray50 
                : WriterTheme.neutralGray100,
            
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: WriterTheme.neutralGray200),
            ),
            
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: WriterTheme.neutralGray200),
            ),
            
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: WriterTheme.primaryBlue,
                width: 2,
              ),
            ),
            
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: WriterTheme.accentRed),
            ),
            
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: WriterTheme.accentRed,
                width: 2,
              ),
            ),
            
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: WriterTheme.neutralGray200),
            ),
            
            hintStyle: WriterTheme.bodyStyle.copyWith(
              color: WriterTheme.neutralGray500,
            ),
            
            helperStyle: WriterTheme.captionStyle.copyWith(
              color: WriterTheme.neutralGray500,
            ),
            
            errorStyle: WriterTheme.captionStyle.copyWith(
              color: WriterTheme.accentRed,
            ),
            
            counterStyle: WriterTheme.captionStyle.copyWith(
              color: WriterTheme.neutralGray500,
            ),
          ),
        ),
      ],
    );
  }
}