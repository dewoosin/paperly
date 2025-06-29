import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/writer_profile_provider.dart';
import '../../models/writer_profile.dart';
import '../../theme/writer_theme.dart';
import '../../widgets/writer_app_bar.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Form controllers
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _educationController = TextEditingController();
  final _websiteController = TextEditingController();
  final _twitterController = TextEditingController();
  final _instagramController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _contactEmailController = TextEditingController();
  
  // Form state
  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];
  
  List<String> _selectedSpecialties = [];
  int _yearsOfExperience = 0;
  List<String> _previousPublications = [];
  List<String> _awards = [];
  List<String> _preferredTopics = [];
  String? _writingSchedule;
  bool _isAvailableForCollaboration = true;
  String? _profileImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    _educationController.dispose();
    _websiteController.dispose();
    _twitterController.dispose();
    _instagramController.dispose();
    _linkedinController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WriterTheme.backgroundLight,
      appBar: const SimpleWriterAppBar(
        title: '작가 프로필 설정',
        showBackButton: true,
      ),
      body: Column(
        children: [
          // 진행도 표시
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: WriterTheme.softShadow,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '프로필을 완성하여 더 많은 독자에게 어필하세요',
                        style: WriterTheme.subtitleStyle.copyWith(
                          color: WriterTheme.neutralGray700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 단계 인디케이터
                Row(
                  children: [
                    for (int i = 0; i < 3; i++) ...[
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: i <= _tabController.index
                                ? WriterTheme.primaryBlue
                                : WriterTheme.neutralGray200,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      if (i < 2) const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1. 기본 정보', style: WriterTheme.captionStyle),
                    Text('2. 전문 분야', style: WriterTheme.captionStyle),
                    Text('3. 추가 정보', style: WriterTheme.captionStyle),
                  ],
                ),
              ],
            ),
          ),
          
          // 탭 콘텐츠
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
              ],
            ),
          ),
          
          // 하단 버튼
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: WriterTheme.neutralGray200.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_tabController.index > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      child: const Text('이전'),
                    ),
                  ),
                if (_tabController.index > 0) const SizedBox(width: 16),
                Expanded(
                  flex: _tabController.index == 0 ? 1 : 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _nextStep,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(_tabController.index == 2 ? '완료' : '다음'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKeys[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '기본 정보를 입력해주세요',
              style: WriterTheme.titleStyle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '독자들이 처음 보게 될 정보입니다',
              style: WriterTheme.bodyStyle.copyWith(
                color: WriterTheme.neutralGray600,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 프로필 사진
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickProfileImage,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: WriterTheme.neutralGray100,
                        borderRadius: BorderRadius.circular(60),
                        border: Border.all(
                          color: WriterTheme.neutralGray300,
                          width: 2,
                        ),
                      ),
                      child: _profileImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(58),
                              child: Image.network(
                                _profileImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person,
                                    size: 60,
                                    color: WriterTheme.neutralGray500,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: WriterTheme.neutralGray500,
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _pickProfileImage,
                    child: Text(
                      _profileImageUrl != null ? '사진 변경' : '프로필 사진 추가',
                      style: WriterTheme.bodyStyle.copyWith(
                        color: WriterTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 필명/활동명
            _buildInputField(
              controller: _displayNameController,
              label: '필명 (활동명)',
              hint: '독자에게 보여질 활동명을 입력하세요',
              isRequired: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '필명을 입력해주세요';
                }
                if (value.trim().length < 2) {
                  return '필명은 2글자 이상이어야 합니다';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // 자기소개
            _buildInputField(
              controller: _bioController,
              label: '자기소개',
              hint: '당신의 글쓰기 철학이나 관심 분야를 소개해주세요',
              maxLines: 4,
              isRequired: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '자기소개를 입력해주세요';
                }
                if (value.trim().length < 10) {
                  return '자기소개는 10글자 이상 작성해주세요';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKeys[1],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '전문 분야와 경력을 알려주세요',
              style: WriterTheme.titleStyle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '관심 있는 독자들이 쉽게 찾을 수 있도록 도와줍니다',
              style: WriterTheme.bodyStyle.copyWith(
                color: WriterTheme.neutralGray600,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 전문 분야 선택
            Text(
              '전문 분야 *',
              style: WriterTheme.subtitleStyle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '최대 5개까지 선택 가능합니다',
              style: WriterTheme.captionStyle.copyWith(
                color: WriterTheme.neutralGray600,
              ),
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: WriterSpecialties.all.map((specialty) {
                final isSelected = _selectedSpecialties.contains(specialty);
                return FilterChip(
                  label: Text(specialty),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected && _selectedSpecialties.length < 5) {
                        _selectedSpecialties.add(specialty);
                      } else if (!selected) {
                        _selectedSpecialties.remove(specialty);
                      }
                    });
                  },
                  selectedColor: WriterTheme.primaryBlue.withOpacity(0.2),
                  checkmarkColor: WriterTheme.primaryBlue,
                  labelStyle: TextStyle(
                    color: isSelected ? WriterTheme.primaryBlue : WriterTheme.neutralGray700,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            
            if (_selectedSpecialties.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '최소 1개 이상의 전문 분야를 선택해주세요',
                  style: WriterTheme.captionStyle.copyWith(
                    color: WriterTheme.accentRed,
                  ),
                ),
              ),
            
            const SizedBox(height: 32),
            
            // 글쓰기 경력
            Text(
              '글쓰기 경력',
              style: WriterTheme.subtitleStyle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: WriterTheme.neutralGray300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$_yearsOfExperience년',
                      style: WriterTheme.titleStyle,
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            if (_yearsOfExperience < 50) _yearsOfExperience++;
                          });
                        },
                        icon: const Icon(Icons.add),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            if (_yearsOfExperience > 0) _yearsOfExperience--;
                          });
                        },
                        icon: const Icon(Icons.remove),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 학력/교육
            _buildInputField(
              controller: _educationController,
              label: '학력 또는 관련 교육',
              hint: '예: 서울대학교 국어국문학과 졸업',
              isRequired: false,
            ),
            
            const SizedBox(height: 20),
            
            // 글쓰기 일정
            Text(
              '주로 언제 글을 쓰시나요?',
              style: WriterTheme.subtitleStyle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            DropdownButtonFormField<String>(
              value: _writingSchedule,
              decoration: InputDecoration(
                hintText: '글쓰기 시간대를 선택하세요',
                filled: true,
                fillColor: WriterTheme.neutralGray50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: WriterTheme.neutralGray300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: WriterTheme.neutralGray300),
                ),
              ),
              items: WritingSchedules.all.map((schedule) {
                return DropdownMenuItem(
                  value: schedule,
                  child: Text(schedule),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _writingSchedule = value;
                });
              },
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKeys[2],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '추가 정보를 입력해주세요',
              style: WriterTheme.titleStyle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '선택사항이지만 더 완성도 높은 프로필을 만들 수 있습니다',
              style: WriterTheme.bodyStyle.copyWith(
                color: WriterTheme.neutralGray600,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 웹사이트
            _buildInputField(
              controller: _websiteController,
              label: '웹사이트',
              hint: 'https://your-website.com',
              isRequired: false,
            ),
            
            const SizedBox(height: 20),
            
            // 소셜 미디어
            Text(
              '소셜 미디어',
              style: WriterTheme.subtitleStyle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildInputField(
              controller: _twitterController,
              label: '트위터',
              hint: '@username',
              isRequired: false,
              prefixText: '@',
            ),
            
            const SizedBox(height: 16),
            
            _buildInputField(
              controller: _instagramController,
              label: '인스타그램',
              hint: '@username',
              isRequired: false,
              prefixText: '@',
            ),
            
            const SizedBox(height: 16),
            
            _buildInputField(
              controller: _linkedinController,
              label: '링크드인',
              hint: 'https://linkedin.com/in/your-profile',
              isRequired: false,
            ),
            
            const SizedBox(height: 20),
            
            // 연락처 이메일
            _buildInputField(
              controller: _contactEmailController,
              label: '연락처 이메일',
              hint: 'contact@email.com',
              isRequired: false,
              keyboardType: TextInputType.emailAddress,
            ),
            
            const SizedBox(height: 32),
            
            // 협업 가능 여부
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: WriterTheme.neutralGray50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: WriterTheme.neutralGray200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.handshake,
                    color: WriterTheme.primaryBlue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '협업 가능',
                          style: WriterTheme.subtitleStyle.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '다른 작가나 매체와의 협업을 고려하시나요?',
                          style: WriterTheme.captionStyle.copyWith(
                            color: WriterTheme.neutralGray600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isAvailableForCollaboration,
                    onChanged: (value) {
                      setState(() {
                        _isAvailableForCollaboration = value;
                      });
                    },
                    activeColor: WriterTheme.primaryBlue,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? prefixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: label,
                style: WriterTheme.subtitleStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: WriterTheme.neutralGray800,
                ),
              ),
              if (isRequired)
                TextSpan(
                  text: ' *',
                  style: WriterTheme.subtitleStyle.copyWith(
                    color: WriterTheme.accentRed,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            hintStyle: WriterTheme.bodyStyle.copyWith(
              color: WriterTheme.neutralGray500,
            ),
            filled: true,
            fillColor: WriterTheme.neutralGray50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: WriterTheme.neutralGray300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: WriterTheme.neutralGray300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: WriterTheme.primaryBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: WriterTheme.accentRed),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 16 : 12,
            ),
          ),
        ),
      ],
    );
  }

  void _pickProfileImage() async {
    try {
      final picker = ImagePicker();
      
      // 사용자에게 선택 옵션 제공
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '프로필 사진 선택',
                  style: WriterTheme.titleStyle,
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('카메라로 촬영'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('갤러리에서 선택'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.cancel),
                  title: const Text('취소'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        },
      );
      
      if (source == null) return;
      
      final image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _isLoading = true;
        });
        
        try {
          final profileProvider = Provider.of<WriterProfileProvider>(context, listen: false);
          final imageUrl = await profileProvider.uploadProfileImage(image.path);
          
          if (imageUrl != null) {
            setState(() {
              _profileImageUrl = imageUrl;
            });
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('프로필 사진이 성공적으로 업로드되었습니다!'),
                  backgroundColor: WriterTheme.accentGreen,
                ),
              );
            }
          } else {
            throw Exception('이미지 URL을 받지 못했습니다');
          }
        } catch (e) {
          print('Image upload error: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('이미지 업로드에 실패했습니다: $e'),
                backgroundColor: WriterTheme.accentRed,
              ),
            );
          }
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Pick image error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('사진 선택 중 오류가 발생했습니다: $e'),
            backgroundColor: WriterTheme.accentRed,
          ),
        );
      }
    }
  }

  void _previousStep() {
    if (_tabController.index > 0) {
      _tabController.animateTo(_tabController.index - 1);
    }
  }

  void _nextStep() async {
    final currentIndex = _tabController.index;
    
    // 현재 단계 검증
    if (!_validateCurrentStep(currentIndex)) {
      return;
    }
    
    if (currentIndex < 2) {
      // 다음 단계로
      _tabController.animateTo(currentIndex + 1);
    } else {
      // 마지막 단계 - 프로필 생성
      await _createProfile();
    }
  }

  bool _validateCurrentStep(int step) {
    switch (step) {
      case 0:
        if (!_formKeys[0].currentState!.validate()) {
          return false;
        }
        return true;
        
      case 1:
        if (_selectedSpecialties.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('최소 1개 이상의 전문 분야를 선택해주세요'),
              backgroundColor: WriterTheme.accentRed,
            ),
          );
          return false;
        }
        return true;
        
      case 2:
        return _formKeys[2].currentState!.validate();
        
      default:
        return true;
    }
  }

  Future<void> _createProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profileProvider = Provider.of<WriterProfileProvider>(context, listen: false);
      
      final request = CreateWriterProfileRequest(
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim(),
        profileImageUrl: _profileImageUrl,
        specialties: _selectedSpecialties,
        yearsOfExperience: _yearsOfExperience,
        education: _educationController.text.trim().isEmpty 
            ? null 
            : _educationController.text.trim(),
        websiteUrl: _websiteController.text.trim().isEmpty 
            ? null 
            : _websiteController.text.trim(),
        twitterHandle: _twitterController.text.trim().isEmpty 
            ? null 
            : _twitterController.text.trim(),
        instagramHandle: _instagramController.text.trim().isEmpty 
            ? null 
            : _instagramController.text.trim(),
        linkedinUrl: _linkedinController.text.trim().isEmpty 
            ? null 
            : _linkedinController.text.trim(),
        contactEmail: _contactEmailController.text.trim().isEmpty 
            ? null 
            : _contactEmailController.text.trim(),
        isAvailableForCollaboration: _isAvailableForCollaboration,
        writingSchedule: _writingSchedule,
      );

      final profile = await profileProvider.createProfile(request);
      
      if (profile != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('프로필이 성공적으로 생성되었습니다!'),
            backgroundColor: WriterTheme.accentGreen,
          ),
        );
        
        // 홈 화면으로 이동
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 생성에 실패했습니다: $e'),
            backgroundColor: WriterTheme.accentRed,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}