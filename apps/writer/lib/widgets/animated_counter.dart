import 'package:flutter/material.dart';

class AnimatedCounter extends StatefulWidget {
  final String value;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCounter({
    Key? key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String? _previousValue;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // 숫자인 경우 카운팅 애니메이션
        if (_isNumeric(widget.value)) {
          final targetValue = _extractNumber(widget.value);
          final previousValue = _previousValue != null ? _extractNumber(_previousValue!) : 0;
          final currentValue = previousValue + (targetValue - previousValue) * _animation.value;
          
          final suffix = _extractSuffix(widget.value);
          final displayValue = _formatAnimatedNumber(currentValue) + suffix;
          
          return _buildAnimatedText(displayValue);
        }
        
        // 텍스트인 경우 페이드 애니메이션
        return AnimatedOpacity(
          opacity: _animation.value,
          duration: const Duration(milliseconds: 300),
          child: _buildAnimatedText(widget.value),
        );
      },
    );
  }

  Widget _buildAnimatedText(String text) {
    return Transform.translate(
      offset: Offset(0, 20 * (1 - _animation.value)),
      child: Text(
        text,
        style: widget.style,
      ),
    );
  }

  bool _isNumeric(String value) {
    // 숫자와 K, M 같은 단위가 포함된 문자열인지 확인
    final numericRegex = RegExp(r'^[+\-]?\d+\.?\d*[KMB%]*$');
    return numericRegex.hasMatch(value.replaceAll(',', ''));
  }

  double _extractNumber(String value) {
    // 문자열에서 숫자 부분만 추출
    final cleanValue = value.replaceAll(RegExp(r'[^\d\.\+\-]'), '');
    final number = double.tryParse(cleanValue) ?? 0;
    
    // K, M, B 단위 처리
    if (value.contains('K')) {
      return number * 1000;
    } else if (value.contains('M')) {
      return number * 1000000;
    } else if (value.contains('B')) {
      return number * 1000000000;
    }
    
    return number;
  }

  String _extractSuffix(String value) {
    // K, M, %, + 등의 접미사 추출
    final suffixRegex = RegExp(r'[KMB%]+$');
    final match = suffixRegex.firstMatch(value);
    return match?.group(0) ?? '';
  }

  String _formatAnimatedNumber(double number) {
    if (number < 1) {
      return number.toStringAsFixed(1);
    } else if (number < 10) {
      return number.toStringAsFixed(1);
    } else {
      return number.round().toString();
    }
  }
}

/// 페이지 전환용 부드러운 애니메이션 위젯
class SmoothPageTransition extends PageRouteBuilder {
  final Widget child;
  final Duration duration;

  SmoothPageTransition({
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            var offsetAnimation = animation.drive(tween);
            var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: curve),
            );

            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
        );
}

/// 스케일 페이드 전환
class ScaleFadeTransition extends PageRouteBuilder {
  final Widget child;
  final Duration duration;

  ScaleFadeTransition({
    required this.child,
    this.duration = const Duration(milliseconds: 400),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeInOutCubic;
            
            var scaleAnimation = Tween(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: curve),
            );
            
            var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: curve),
            );

            return ScaleTransition(
              scale: scaleAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
        );
}