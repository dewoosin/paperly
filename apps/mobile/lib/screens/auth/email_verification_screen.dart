// apps/mobile/lib/screens/auth/email_verification_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../theme/muji_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/muji_button.dart';

/// 이메일 인증 대기 화면
class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  
  Timer? _resendTimer;
  int _resendCountdown = 0;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
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
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
    _startResendTimer();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  /// 재전송 타이머 시작
  void _startResendTimer() {
    setState(() => _resendCountdown = 60);
    
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  /// 인증 메일 재전송
  Future<void> _resendVerificationEmail() async {
    if (_resendCountdown > 0 || _isResending) return;
    
    setState(() => _isResending = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.resendVerificationEmail();
      
      if (mounted) {
        _startResendTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '인증 메일을 다시 보냈습니다',
              style: MujiTheme.mobileCaption.copyWith(color: Colors.white),
            ),
            backgroundColor: MujiTheme.sage,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '메일 발송에 실패했습니다',
              style: MujiTheme.mobileCaption.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MujiTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                const Spacer(),
                
                // 메일 아이콘
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: MujiTheme.sage.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.mail,
                                size: 48,
                                color: MujiTheme.sage,
                              ),
                              Positioned(
                                right: 25,
                                top: 25,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: MujiTheme.sand,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.checkmark,
                                    size: 14,
                                    color: Colors.white,
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
                
                const SizedBox(height: 40),
                
                // 안내 메시지
                Text(
                  '이메일을 확인해주세요',
                  style: MujiTheme.mobileH2,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  '${widget.email}로\n인증 메일을 보냈습니다',
                  style: MujiTheme.mobileBody,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  '메일함에서 인증 링크를 클릭해주세요',
                  style: MujiTheme.mobileCaption,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // 재전송 버튼
                if (_resendCountdown > 0)
                  Text(
                    '${_resendCountdown}초 후에 다시 보낼 수 있습니다',
                    style: MujiTheme.mobileCaption,
                  )
                else
                  TextButton(
                    onPressed: _isResending ? null : _resendVerificationEmail,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isResending)
                          Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(right: 8),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(MujiTheme.sage),
                            ),
                          ),
                        Text(
                          '인증 메일 다시 보내기',
                          style: MujiTheme.mobileBody.copyWith(
                            color: MujiTheme.sage,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const Spacer(),
                
                // 추가 안내
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: MujiTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: MujiTheme.textHint.withOpacity(0.1),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        CupertinoIcons.info_circle,
                        size: 16,
                        color: MujiTheme.textLight,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '메일이 오지 않나요?',
                              style: MujiTheme.mobileCaption.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '스팸 메일함을 확인해보세요.\n그래도 없다면 다시 보내기를 눌러주세요.',
                              style: MujiTheme.mobileLabel,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 홈으로 가기 버튼
                MujiButton(
                  text: '나중에 인증하기',
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/home');
                  },
                  style: MujiButtonStyle.secondary,
                ),
                
                // 개발용 인증 스킵 버튼
                if (const bool.fromEnvironment('dart.vm.product') == false) ...[
                  const SizedBox(height: 12),
                  MujiButton(
                    text: '🚀 개발용: 인증 스킵하기',
                    onPressed: () async {
                      try {
                        final authProvider = context.read<AuthProvider>();
                        await authProvider.skipEmailVerification();
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '이메일 인증을 스킵했습니다',
                                style: MujiTheme.mobileCaption.copyWith(color: Colors.white),
                              ),
                              backgroundColor: MujiTheme.sage,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                          Navigator.of(context).pushReplacementNamed('/home');
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '인증 스킵 실패: ${e.toString()}',
                                style: MujiTheme.mobileCaption.copyWith(color: Colors.white),
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        }
                      }
                    },
                    style: MujiButtonStyle.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
