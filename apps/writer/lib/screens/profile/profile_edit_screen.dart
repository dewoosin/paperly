import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/writer_profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/writer_theme.dart';
import '../../widgets/writer_app_bar.dart';
import '../../widgets/animated_counter.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({Key? key}) : super(key: key);

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _emailController;
  
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  String? _currentImageUrl;
  
  late TabController _tabController;
  bool _isLoading = false;
  
  // Settings
  bool _autoSave = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _weeklyDigest = false;
  
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    _nameController = TextEditingController(text: user?.name ?? '');
    _bioController = TextEditingController(text: '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _currentImageUrl = user?.profileImageUrl;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WriterTheme.backgroundLight,
      appBar: SimpleWriterAppBar(
        title: '프로필 편집',
        showBackButton: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(WriterTheme.primaryBlue),
                    ),
                  )
                : Text(
                    '저장',
                    style: WriterTheme.subtitleStyle.copyWith(
                      color: WriterTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 탭 헤더
          Container(
            margin: const EdgeInsets.all(20),
            height: 48,
            decoration: BoxDecoration(
              color: WriterTheme.neutralGray100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: WriterTheme.softShadow,
              ),
              labelColor: WriterTheme.primaryBlue,
              unselectedLabelColor: WriterTheme.neutralGray600,
              labelStyle: WriterTheme.subtitleStyle.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: WriterTheme.subtitleStyle.copyWith(
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: '기본 정보'),
                Tab(text: '설정'),
                Tab(text: '고급'),
              ],
            ),
          ),
          
          // 탭 내용
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildBasicInfoTab(),
                _buildSettingsTab(),
                _buildAdvancedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 이미지 섹션
            _buildProfileImageSection(),
            
            const SizedBox(height: 32),
            
            // 이름 입력
            _buildInputSection(
              '작가명',
              '독자들에게 보여질 이름을 입력하세요',
              _nameController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '작가명을 입력해주세요';
                }
                if (value.trim().length < 2) {
                  return '작가명은 2글자 이상이어야 합니다';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // 이메일 입력
            _buildInputSection(
              '이메일',
              '알림을 받을 이메일 주소입니다',
              _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '이메일을 입력해주세요';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return '유효한 이메일 주소를 입력해주세요';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // 자기소개 입력
            _buildBioSection(),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: WriterTheme.softShadow,
      ),
      child: Column(
        children: [
          Text(
            '프로필 사진',
            style: WriterTheme.titleStyle.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 프로필 이미지
          GestureDetector(
            onTap: _pickProfileImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: WriterTheme.neutralGray100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: WriterTheme.primaryBlue.withOpacity(0.2),
                  width: 2,
                ),
                boxShadow: WriterTheme.softShadow,
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : _currentImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.network(
                            _currentImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildImagePlaceholder();
                            },
                          ),
                        )
                      : _buildImagePlaceholder(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          TextButton.icon(
            onPressed: _pickProfileImage,
            icon: Icon(
              Icons.camera_alt,
              color: WriterTheme.primaryBlue,
            ),
            label: Text(
              '사진 변경',
              style: WriterTheme.subtitleStyle.copyWith(
                color: WriterTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.person,
          size: 48,
          color: WriterTheme.neutralGray400,
        ),
        const SizedBox(height: 8),
        Text(
          '사진 추가',
          style: WriterTheme.captionStyle.copyWith(
            color: WriterTheme.neutralGray500,
          ),
        ),
      ],
    );
  }

  Widget _buildInputSection(
    String label,
    String hint,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: WriterTheme.subtitleStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: WriterTheme.neutralGray900,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: WriterTheme.bodyStyle,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: WriterTheme.neutralGray100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: WriterTheme.primaryBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: WriterTheme.accentRed, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildBioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '자기소개',
              style: WriterTheme.subtitleStyle.copyWith(
                fontWeight: FontWeight.bold,
                color: WriterTheme.neutralGray900,
              ),
            ),
            const Spacer(),
            Text(
              '${_bioController.text.length}/300',
              style: WriterTheme.captionStyle.copyWith(
                color: _bioController.text.length > 300
                    ? WriterTheme.accentRed
                    : WriterTheme.neutralGray500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _bioController,
          maxLines: 6,
          maxLength: 300,
          style: WriterTheme.bodyStyle,
          decoration: InputDecoration(
            hintText: '독자들에게 자신을 소개해보세요.\n어떤 주제에 관심이 있고, 어떤 경험을 가지고 있는지 알려주세요.',
            filled: true,
            fillColor: WriterTheme.neutralGray100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: WriterTheme.primaryBlue, width: 2),
            ),
            contentPadding: const EdgeInsets.all(20),
            counterText: '',
          ),
          onChanged: (value) {
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingsGroup(
            '글쓰기 설정',
            [
              _buildSettingsItem(
                '자동 저장',
                '30초마다 자동으로 저장됩니다',
                Icons.auto_awesome,
                Switch(
                  value: _autoSave,
                  onChanged: (value) {
                    setState(() {
                      _autoSave = value;
                    });
                  },
                  activeColor: WriterTheme.primaryBlue,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildSettingsGroup(
            '알림 설정',
            [
              _buildSettingsItem(
                '이메일 알림',
                '댓글, 좋아요 등의 알림을 이메일로 받습니다',
                Icons.email,
                Switch(
                  value: _emailNotifications,
                  onChanged: (value) {
                    setState(() {
                      _emailNotifications = value;
                    });
                  },
                  activeColor: WriterTheme.primaryBlue,
                ),
              ),
              _buildSettingsItem(
                '푸시 알림',
                '즉시 알림을 받습니다',
                Icons.notifications,
                Switch(
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() {
                      _pushNotifications = value;
                    });
                  },
                  activeColor: WriterTheme.primaryBlue,
                ),
              ),
              _buildSettingsItem(
                '주간 요약',
                '매주 성과 요약을 받습니다',
                Icons.bar_chart,
                Switch(
                  value: _weeklyDigest,
                  onChanged: (value) {
                    setState(() {
                      _weeklyDigest = value;
                    });
                  },
                  activeColor: WriterTheme.primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingsGroup(
            '계정 관리',
            [
              _buildActionItem(
                '비밀번호 변경',
                '보안을 위해 정기적으로 변경해주세요',
                Icons.lock,
                () => _showPasswordChangeDialog(),
              ),
              _buildActionItem(
                '계정 연동',
                '소셜 계정과 연동하여 간편하게 로그인하세요',
                Icons.link,
                () => _showAccountLinkDialog(),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildSettingsGroup(
            '데이터 관리',
            [
              _buildActionItem(
                '데이터 내보내기',
                '내 글과 통계 데이터를 다운로드합니다',
                Icons.download,
                () => _showExportDialog(),
              ),
              _buildActionItem(
                '캐시 삭제',
                '앱 성능 향상을 위해 캐시를 삭제합니다',
                Icons.cleaning_services,
                () => _showCacheClearDialog(),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildDangerZone(),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: WriterTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Text(
              title,
              style: WriterTheme.titleStyle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsItem(String title, String subtitle, IconData icon, Widget trailing) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: WriterTheme.neutralGray100,
              borderRadius: BorderRadius.circular(12),
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
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: WriterTheme.captionStyle.copyWith(
                    color: WriterTheme.neutralGray600,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildActionItem(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: WriterTheme.neutralGray100,
                borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: WriterTheme.captionStyle.copyWith(
                      color: WriterTheme.neutralGray600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: WriterTheme.neutralGray400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: WriterTheme.accentRed.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: WriterTheme.accentRed.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning,
                color: WriterTheme.accentRed,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                '위험 구역',
                style: WriterTheme.titleStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: WriterTheme.accentRed,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showAccountDeleteDialog(),
              style: OutlinedButton.styleFrom(
                foregroundColor: WriterTheme.accentRed,
                side: BorderSide(color: WriterTheme.accentRed),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                '계정 삭제',
                style: WriterTheme.subtitleStyle.copyWith(
                  color: WriterTheme.accentRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('이미지를 선택할 수 없습니다: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 실제 구현시 API 호출
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        _showSuccessSnackBar('프로필이 성공적으로 저장되었습니다');
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErrorSnackBar('프로필 저장에 실패했습니다: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPasswordChangeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('비밀번호 변경'),
        content: const Text('보안을 위해 새로운 비밀번호로 변경해주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 비밀번호 변경 화면으로 이동
            },
            child: const Text('변경하기'),
          ),
        ],
      ),
    );
  }

  void _showAccountLinkDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계정 연동'),
        content: const Text('Google, Apple, Facebook 계정과 연동할 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('데이터 내보내기'),
        content: const Text('내 글과 통계 데이터를 JSON 형태로 다운로드합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessSnackBar('데이터 내보내기가 시작되었습니다');
            },
            child: const Text('다운로드'),
          ),
        ],
      ),
    );
  }

  void _showCacheClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('캐시 삭제'),
        content: const Text('앱의 캐시 데이터를 삭제하면 성능이 향상될 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessSnackBar('캐시가 삭제되었습니다');
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showAccountDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '계정 삭제',
          style: TextStyle(color: WriterTheme.accentRed),
        ),
        content: const Text('정말로 계정을 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없으며, 모든 글과 데이터가 영구적으로 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 계정 삭제 로직
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: WriterTheme.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: WriterTheme.accentRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}