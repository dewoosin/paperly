import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/writer_theme.dart';
import '../../widgets/writer_app_bar.dart';
import '../../widgets/animated_counter.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WriterTheme.backgroundLight,
      appBar: const SimpleWriterAppBar(
        title: '프로필',
        showBackButton: false,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 프로필 헤더
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: WriterTheme.softShadow,
                  ),
                  child: Column(
                    children: [
                      // 프로필 이미지
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: WriterTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: WriterTheme.primaryBlue.withOpacity(0.3)),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: WriterTheme.primaryBlue,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 이름
                      Text(
                        user?.name ?? '작가님',
                        style: WriterTheme.titleStyle.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // 이메일
                      Text(
                        user?.email ?? 'writer@paperly.com',
                        style: WriterTheme.bodyStyle.copyWith(
                          color: WriterTheme.neutralGray600,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 가입일
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: WriterTheme.neutralGray100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '가입일: ${_formatDate(user?.createdAt ?? DateTime.now())}',
                          style: WriterTheme.captionStyle.copyWith(
                            color: WriterTheme.neutralGray600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // 계정 설정
                _buildSettingsSection(
                  title: '계정 설정',
                  items: [
                    _buildSettingsItem(
                      icon: Icons.edit,
                      title: '프로필 편집',
                      subtitle: '이름, 소개글 등을 수정할 수 있어요',
                      onTap: () => _showProfileEditDialog(context),
                    ),
                    _buildSettingsItem(
                      icon: Icons.lock,
                      title: '비밀번호 변경',
                      subtitle: '계정 보안을 위해 정기적으로 변경해주세요',
                      onTap: () => _showPasswordChangeDialog(context),
                    ),
                    _buildSettingsItem(
                      icon: Icons.notifications,
                      title: '알림 설정',
                      subtitle: '댓글, 좋아요 등의 알림을 설정해요',
                      onTap: () => _showNotificationSettings(context),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // 글쓰기 설정
                _buildSettingsSection(
                  title: '글쓰기 설정',
                  items: [
                    _buildSettingsItem(
                      icon: Icons.auto_awesome,
                      title: '자동 저장',
                      subtitle: '30초마다 자동으로 저장됩니다',
                      trailing: Switch(
                        value: true,
                        onChanged: (value) {
                          // 자동 저장 설정 토글
                        },
                        activeColor: WriterTheme.primaryBlue,
                      ),
                    ),
                    _buildSettingsItem(
                      icon: Icons.format_size,
                      title: '기본 폰트 크기',
                      subtitle: '글쓰기 화면의 기본 폰트 크기',
                      onTap: () => _showFontSizeSettings(context),
                    ),
                    _buildSettingsItem(
                      icon: Icons.category,
                      title: '기본 카테고리',
                      subtitle: '새 글의 기본 카테고리를 설정해요',
                      onTap: () => _showCategorySettings(context),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // 지원 및 정보
                _buildSettingsSection(
                  title: '지원 및 정보',
                  items: [
                    _buildSettingsItem(
                      icon: Icons.help,
                      title: '도움말',
                      subtitle: '사용법을 확인할 수 있어요',
                      onTap: () => _showHelp(context),
                    ),
                    _buildSettingsItem(
                      icon: Icons.feedback,
                      title: '피드백 보내기',
                      subtitle: '개선사항이나 문의사항을 보내주세요',
                      onTap: () => _showFeedbackDialog(context),
                    ),
                    _buildSettingsItem(
                      icon: Icons.info,
                      title: '앱 정보',
                      subtitle: '버전 1.0.0',
                      onTap: () => _showAppInfo(context),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // 로그아웃 버튼
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: WriterTheme.softShadow,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _showLogoutConfirmation(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: WriterTheme.accentRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            '로그아웃',
                            style: WriterTheme.subtitleStyle.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      TextButton(
                        onPressed: () => _showAccountDeleteConfirmation(context),
                        child: Text(
                          '계정 삭제',
                          style: WriterTheme.bodyStyle.copyWith(
                            color: WriterTheme.neutralGray500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: WriterTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              title,
              style: WriterTheme.titleStyle.copyWith(
                fontWeight: FontWeight.bold,
                color: WriterTheme.neutralGray900,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: WriterTheme.neutralGray100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: WriterTheme.neutralGray700,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: WriterTheme.subtitleStyle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: WriterTheme.captionStyle.copyWith(
                      color: WriterTheme.neutralGray600,
                    ),
                  ),
                ],
              ),
            ),
            trailing ?? Icon(
              Icons.chevron_right,
              color: WriterTheme.neutralGray400,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  void _showProfileEditDialog(BuildContext context) {
    Navigator.of(context).push(
      SmoothPageTransition(
        child: const ProfileEditScreen(),
      ),
    );
  }

  void _showPasswordChangeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('비밀번호 변경'),
        content: const Text('비밀번호 변경 기능은 곧 제공될 예정입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알림 설정'),
        content: const Text('알림 설정 기능은 곧 제공될 예정입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showFontSizeSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('폰트 크기 설정'),
        content: const Text('폰트 크기 설정 기능은 곧 제공될 예정입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showCategorySettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기본 카테고리 설정'),
        content: const Text('기본 카테고리 설정 기능은 곧 제공될 예정입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('도움말'),
        content: const Text('도움말 기능은 곧 제공될 예정입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('피드백 보내기'),
        content: const Text('피드백 기능은 곧 제공될 예정입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showAppInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('앱 정보'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paperly Writer'),
            Text('버전: 1.0.0'),
            Text('작가 전용 글쓰기 앱'),
            SizedBox(height: 16),
            Text('© 2024 Paperly. All rights reserved.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말로 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            child: Text(
              '로그아웃',
              style: TextStyle(color: WriterTheme.accentRed),
            ),
          ),
        ],
      ),
    );
  }

  void _showAccountDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계정 삭제'),
        content: const Text('정말로 계정을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 계정 삭제 로직 구현
            },
            child: Text(
              '삭제',
              style: TextStyle(color: WriterTheme.accentRed),
            ),
          ),
        ],
      ),
    );
  }
}