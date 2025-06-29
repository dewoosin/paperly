import 'package:flutter/material.dart';
import '../theme/writer_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 로고
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            WriterTheme.primaryBlue,
                            WriterTheme.primaryBlueDark,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: WriterTheme.primaryBlue.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit_note,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // 앱 이름
                    Text(
                      'Paperly Writer',
                      style: WriterTheme.headlineStyle.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: WriterTheme.neutralGray900,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // 부제목
                    Text(
                      '당신의 이야기를 세상에',
                      style: WriterTheme.subtitleStyle.copyWith(
                        color: WriterTheme.neutralGray500,
                        fontSize: 16,
                      ),
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // 로딩 인디케이터
                    Container(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          WriterTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}