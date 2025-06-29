import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';
import '../../providers/article_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/writer_theme.dart';
import '../../models/article.dart';
import '../../widgets/writer_app_bar.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_button.dart';

class ArticleEditorScreen extends StatefulWidget {
  final Article? article; // null이면 새 글 작성
  
  const ArticleEditorScreen({
    Key? key,
    this.article,
  }) : super(key: key);

  @override
  State<ArticleEditorScreen> createState() => _ArticleEditorScreenState();
}

class _ArticleEditorScreenState extends State<ArticleEditorScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _contentController;
  late TextEditingController _excerptController;
  
  late TabController _tabController;
  
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;
  bool _isAutoSaving = false;
  String? _lastSavedContent;
  ArticleStatus _currentStatus = ArticleStatus.draft;
  ArticleVisibility _currentVisibility = ArticleVisibility.public;
  
  // 이미지 관련
  final ImagePicker _imagePicker = ImagePicker();
  List<File> _selectedImages = [];
  int _featuredImageIndex = 0;
  final int _maxImages = 3;
  
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _tabController = TabController(length: 3, vsync: this);
    
    // 기존 글 편집인 경우 데이터 로드
    if (widget.article != null) {
      _titleController = TextEditingController(text: widget.article!.title);
      _subtitleController = TextEditingController(text: widget.article!.subtitle ?? '');
      _contentController = TextEditingController(text: widget.article!.content);
      _excerptController = TextEditingController(text: widget.article!.excerpt ?? '');
      _currentStatus = widget.article!.status;
      _currentVisibility = widget.article!.visibility;
      _lastSavedContent = widget.article!.content;
    } else {
      _titleController = TextEditingController();
      _subtitleController = TextEditingController();
      _contentController = TextEditingController();
      _excerptController = TextEditingController();
    }
    
    // 변경 감지 리스너
    _titleController.addListener(_onContentChanged);
    _subtitleController.addListener(_onContentChanged);
    _contentController.addListener(_onContentChanged);
    _excerptController.addListener(_onContentChanged);
    
    // 자동 저장 설정
    _startAutoSave();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _subtitleController.dispose();
    _contentController.dispose();
    _excerptController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _hasUnsavedChanges) {
      _autoSave();
    }
  }

  void _onContentChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_hasUnsavedChanges && !_isAutoSaving) {
        _autoSave();
      }
    });
  }

  Future<void> _autoSave() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      return; // 제목이나 내용이 비어있으면 저장하지 않음
    }

    setState(() {
      _isAutoSaving = true;
    });

    try {
      final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
      
      if (widget.article != null) {
        // 기존 글 업데이트
        await articleProvider.updateArticle(
          widget.article!.id,
          UpdateArticleRequest(
            title: _titleController.text.trim(),
            subtitle: _subtitleController.text.trim().isEmpty ? null : _subtitleController.text.trim(),
            content: _contentController.text,
            excerpt: _excerptController.text.trim().isEmpty ? null : _excerptController.text.trim(),
          ),
        );
      } else {
        // 새 글 생성 (초안으로)
        final newArticle = await articleProvider.createArticle(
          CreateArticleRequest(
            title: _titleController.text.trim(),
            subtitle: _subtitleController.text.trim().isEmpty ? null : _subtitleController.text.trim(),
            content: _contentController.text,
            excerpt: _excerptController.text.trim().isEmpty ? null : _excerptController.text.trim(),
            status: ArticleStatus.draft,
          ),
        );
        
        if (newArticle != null && mounted) {
          // 새 글이 생성되면 편집 모드로 전환
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ArticleEditorScreen(article: newArticle),
            ),
          );
          return;
        }
      }
      
      setState(() {
        _hasUnsavedChanges = false;
        _lastSavedContent = _contentController.text;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.cloud_done, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text('자동 저장됨'),
              ],
            ),
            backgroundColor: WriterTheme.accentGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Auto save failed: $e');
    } finally {
      setState(() {
        _isAutoSaving = false;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('저장하지 않은 변경사항이 있습니다'),
        content: Text('변경사항을 저장하지 않고 나가시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('나가기'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _autoSave();
              if (mounted) Navigator.of(context).pop(true);
            },
            child: Text('저장 후 나가기'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // 앱바
            WriterAppBar(
              title: widget.article != null ? '글 편집' : '새 글 작성',
              actions: [
                // 자동 저장 상태 표시
                if (_isAutoSaving)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(WriterTheme.primaryBlue),
                        ),
                      ),
                    ),
                  )
                else if (_hasUnsavedChanges)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: WriterTheme.accentOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                
                // 저장 버튼
                IconButton(
                  onPressed: _hasUnsavedChanges ? _autoSave : null,
                  icon: Icon(
                    Icons.save,
                    color: _hasUnsavedChanges ? WriterTheme.primaryBlue : WriterTheme.neutralGray300,
                  ),
                ),
                
                // 더보기 메뉴
                PopupMenuButton<String>(
                  onSelected: _handleMenuAction,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'preview',
                      child: Row(
                        children: [
                          Icon(Icons.preview, size: 20),
                          SizedBox(width: 12),
                          Text('미리보기'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings, size: 20),
                          SizedBox(width: 12),
                          Text('설정'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // 탭바
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: WriterTheme.neutralGray200),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: WriterTheme.primaryBlue,
                unselectedLabelColor: WriterTheme.neutralGray500,
                indicatorColor: WriterTheme.primaryBlue,
                tabs: const [
                  Tab(text: '작성'),
                  Tab(text: '설정'),
                  Tab(text: '발행'),
                ],
              ),
            ),
            
            // 탭 내용
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildWritingTab(),
                  _buildSettingsTab(),
                  _buildPublishTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWritingTab() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 제목
            CustomTextField(
              controller: _titleController,
              label: '제목',
              hintText: '글의 제목을 입력하세요',
              maxLines: 2,
              textStyle: WriterTheme.titleStyle,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '제목을 입력해주세요';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // 부제목
            CustomTextField(
              controller: _subtitleController,
              label: '부제목 (선택사항)',
              hintText: '부제목을 입력하세요',
              maxLines: 2,
            ),
            
            const SizedBox(height: 16),
            
            // 요약
            CustomTextField(
              controller: _excerptController,
              label: '요약 (선택사항)',
              hintText: '글의 간단한 요약을 입력하세요',
              maxLines: 3,
            ),
            
            const SizedBox(height: 24),
            
            // 내용
            CustomTextField(
              controller: _contentController,
              label: '내용',
              hintText: '이곳에 글을 작성하세요...',
              maxLines: null,
              minLines: 15,
              textStyle: WriterTheme.bodyStyle.copyWith(
                fontSize: 16,
                height: 1.8,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '내용을 입력해주세요';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // 이미지 업로드 섹션
            _buildImageSection(),
            
            const SizedBox(height: 24),
            
            // 글 통계
            _buildWritingStats(),
            
            const SizedBox(height: 100), // 하단 여백
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '글 설정',
            style: WriterTheme.titleStyle,
          ),
          
          const SizedBox(height: 24),
          
          // 공개 설정
          _buildVisibilitySection(),
          
          const SizedBox(height: 24),
          
          // SEO 설정
          _buildSEOSection(),
          
          const SizedBox(height: 24),
          
          // 카테고리 및 태그
          _buildCategorySection(),
        ],
      ),
    );
  }

  Widget _buildPublishTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '발행 관리',
            style: WriterTheme.titleStyle,
          ),
          
          const SizedBox(height: 24),
          
          // 현재 상태
          _buildCurrentStatus(),
          
          const SizedBox(height: 24),
          
          // 발행 액션
          _buildPublishActions(),
        ],
      ),
    );
  }

  Widget _buildWritingStats() {
    final content = _contentController.text;
    final wordCount = content.trim().split(RegExp(r'\s+')).length;
    final charCount = content.length;
    final estimatedReadTime = (wordCount / 200).ceil();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WriterTheme.neutralGray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WriterTheme.neutralGray200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem('단어', '$wordCount'),
          ),
          Container(
            width: 1,
            height: 24,
            color: WriterTheme.neutralGray200,
          ),
          Expanded(
            child: _buildStatItem('글자', '$charCount'),
          ),
          Container(
            width: 1,
            height: 24,
            color: WriterTheme.neutralGray200,
          ),
          Expanded(
            child: _buildStatItem('예상 읽기', '${estimatedReadTime}분'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: WriterTheme.subtitleStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: WriterTheme.primaryBlue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: WriterTheme.captionStyle,
        ),
      ],
    );
  }

  Widget _buildVisibilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '공개 설정',
          style: WriterTheme.subtitleStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 16),
        
        ...ArticleVisibility.values.map((visibility) {
          return RadioListTile<ArticleVisibility>(
            title: Text(visibility.displayName),
            subtitle: Text(_getVisibilityDescription(visibility)),
            value: visibility,
            groupValue: _currentVisibility,
            onChanged: (value) {
              setState(() {
                _currentVisibility = value!;
                _onContentChanged();
              });
            },
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSEOSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SEO 설정',
          style: WriterTheme.subtitleStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 16),
        
        Text(
          '검색 엔진 최적화를 위한 설정입니다.',
          style: WriterTheme.captionStyle,
        ),
        
        const SizedBox(height: 16),
        
        CustomTextField(
          label: 'SEO 제목',
          hintText: '검색 결과에 표시될 제목',
          maxLength: 60,
        ),
        
        const SizedBox(height: 16),
        
        CustomTextField(
          label: 'SEO 설명',
          hintText: '검색 결과에 표시될 설명',
          maxLines: 3,
          maxLength: 160,
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '카테고리 및 태그',
          style: WriterTheme.subtitleStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 카테고리 선택
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: WriterTheme.neutralGray200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.category, color: WriterTheme.neutralGray500),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '카테고리 선택',
                  style: WriterTheme.bodyStyle,
                ),
              ),
              Icon(Icons.chevron_right, color: WriterTheme.neutralGray500),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 태그 입력
        CustomTextField(
          label: '태그',
          hintText: '태그를 쉼표로 구분하여 입력하세요',
        ),
      ],
    );
  }

  Widget _buildCurrentStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WriterTheme.getStatusColor(_currentStatus.name).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: WriterTheme.getStatusColor(_currentStatus.name).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            WriterTheme.getStatusIcon(_currentStatus.name),
            color: WriterTheme.getStatusColor(_currentStatus.name),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '현재 상태: ${_currentStatus.displayName}',
                  style: WriterTheme.subtitleStyle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusDescription(_currentStatus),
                  style: WriterTheme.captionStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 임시 저장
        if (widget.article == null || _currentStatus == ArticleStatus.draft)
          LoadingButton(
            onPressed: _saveDraft,
            backgroundColor: WriterTheme.accentOrange,
            child: Text('임시 저장'),
          ),
        
        const SizedBox(height: 12),
        
        // 검토 요청
        if (_currentStatus == ArticleStatus.draft)
          LoadingButton(
            onPressed: _submitForReview,
            backgroundColor: WriterTheme.primaryBlue,
            child: Text('검토 요청'),
          ),
        
        // 발행
        if (_currentStatus == ArticleStatus.draft || _currentStatus == ArticleStatus.review)
          LoadingButton(
            onPressed: _publish,
            backgroundColor: WriterTheme.accentGreen,
            child: Text('발행하기'),
          ),
        
        // 발행 취소
        if (_currentStatus == ArticleStatus.published)
          LoadingButton(
            onPressed: _unpublish,
            backgroundColor: WriterTheme.accentRed,
            child: Text('발행 취소'),
          ),
      ],
    );
  }

  String _getVisibilityDescription(ArticleVisibility visibility) {
    switch (visibility) {
      case ArticleVisibility.public:
        return '모든 사용자가 볼 수 있습니다';
      case ArticleVisibility.private:
        return '나만 볼 수 있습니다';
      case ArticleVisibility.unlisted:
        return '링크를 아는 사람만 볼 수 있습니다';
    }
  }

  String _getStatusDescription(ArticleStatus status) {
    switch (status) {
      case ArticleStatus.draft:
        return '작성 중인 초안입니다';
      case ArticleStatus.review:
        return '검토 중입니다';
      case ArticleStatus.published:
        return '발행되어 공개되었습니다';
      case ArticleStatus.archived:
        return '보관되었습니다';
      case ArticleStatus.deleted:
        return '삭제되었습니다';
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'preview':
        _showPreview();
        break;
      case 'settings':
        _tabController.animateTo(1);
        break;
    }
  }

  void _showPreview() {
    // TODO: 미리보기 화면 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('미리보기 기능은 준비 중입니다.')),
    );
  }

  Future<void> _saveDraft() async {
    if (!_formKey.currentState!.validate()) return;
    await _autoSave();
  }

  Future<void> _submitForReview() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
      
      if (widget.article != null) {
        await articleProvider.updateArticleStatus(
          widget.article!.id,
          ArticleStatus.review,
        );
        
        setState(() {
          _currentStatus = ArticleStatus.review;
          _hasUnsavedChanges = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('검토 요청이 완료되었습니다.'),
            backgroundColor: WriterTheme.primaryBlue,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('검토 요청에 실패했습니다: $e'),
          backgroundColor: WriterTheme.accentRed,
        ),
      );
    }
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
      
      if (widget.article != null) {
        await articleProvider.publishArticle(widget.article!.id);
        
        setState(() {
          _currentStatus = ArticleStatus.published;
          _hasUnsavedChanges = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('글이 성공적으로 발행되었습니다.'),
            backgroundColor: WriterTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('발행에 실패했습니다: $e'),
          backgroundColor: WriterTheme.accentRed,
        ),
      );
    }
  }

  Future<void> _unpublish() async {
    try {
      final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
      
      if (widget.article != null) {
        await articleProvider.unpublishArticle(widget.article!.id);
        
        setState(() {
          _currentStatus = ArticleStatus.draft;
          _hasUnsavedChanges = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('발행이 취소되었습니다.'),
            backgroundColor: WriterTheme.accentOrange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('발행 취소에 실패했습니다: $e'),
          backgroundColor: WriterTheme.accentRed,
        ),
      );
    }
  }

  // 이미지 업로드 섹션
  Widget _buildImageSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WriterTheme.neutralGray200),
        boxShadow: WriterTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.image,
                color: WriterTheme.primaryBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '이미지 (${_selectedImages.length}/$_maxImages)',
                style: WriterTheme.titleStyle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_selectedImages.length < _maxImages)
                IconButton(
                  onPressed: _pickImage,
                  icon: Icon(
                    Icons.add_photo_alternate,
                    color: WriterTheme.primaryBlue,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: WriterTheme.primaryBlue.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (_selectedImages.isEmpty)
            _buildEmptyImageState()
          else
            _buildImageGrid(),
        ],
      ),
    );
  }

  Widget _buildEmptyImageState() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: WriterTheme.neutralGray50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: WriterTheme.neutralGray300,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 48,
              color: WriterTheme.neutralGray400,
            ),
            const SizedBox(height: 8),
            Text(
              '사진 추가하기',
              style: WriterTheme.subtitleStyle.copyWith(
                color: WriterTheme.neutralGray600,
              ),
            ),
            Text(
              '최대 3장까지 추가할 수 있어요',
              style: WriterTheme.captionStyle.copyWith(
                color: WriterTheme.neutralGray500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: _selectedImages.length + (_selectedImages.length < _maxImages ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _selectedImages.length) {
              // 이미지 추가 버튼
              return GestureDetector(
                onTap: _pickImage,
                child: Container(
                  decoration: BoxDecoration(
                    color: WriterTheme.neutralGray50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: WriterTheme.neutralGray300,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Icon(
                    Icons.add,
                    size: 32,
                    color: WriterTheme.neutralGray400,
                  ),
                ),
              );
            }
            
            // 이미지 카드
            return _buildImageCard(index);
          },
        ),
        
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildFeaturedImageSelector(),
        ],
      ],
    );
  }

  Widget _buildImageCard(int index) {
    final isFeatured = index == _featuredImageIndex;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFeatured ? WriterTheme.accentGreen : WriterTheme.neutralGray200,
          width: isFeatured ? 3 : 1,
        ),
      ),
      child: Stack(
        children: [
          // 이미지
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: FileImage(_selectedImages[index]),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // 대표 이미지 표시
          if (isFeatured)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: WriterTheme.accentGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '대표',
                  style: WriterTheme.captionStyle.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          
          // 삭제 버튼
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: WriterTheme.accentRed,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedImageSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WriterTheme.neutralGray50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '대표 이미지 선택',
            style: WriterTheme.subtitleStyle.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '썸네일로 사용될 이미지를 선택해주세요',
            style: WriterTheme.captionStyle.copyWith(
              color: WriterTheme.neutralGray600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                final isSelected = index == _featuredImageIndex;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _featuredImageIndex = index;
                      _onContentChanged();
                    });
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? WriterTheme.accentGreen : WriterTheme.neutralGray200,
                        width: isSelected ? 3 : 1,
                      ),
                      image: DecorationImage(
                        image: FileImage(_selectedImages[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: isSelected
                        ? Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: WriterTheme.accentGreen.withOpacity(0.3),
                            ),
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 24,
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 이미지 선택 메서드
  Future<void> _pickImage() async {
    if (_selectedImages.length >= _maxImages) return;
    
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
          _onContentChanged();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지가 추가되었습니다'),
            backgroundColor: WriterTheme.accentGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이미지 선택에 실패했습니다: $e'),
          backgroundColor: WriterTheme.accentRed,
        ),
      );
    }
  }

  // 이미지 제거 메서드
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      
      // 대표 이미지 인덱스 조정
      if (_featuredImageIndex >= _selectedImages.length && _selectedImages.isNotEmpty) {
        _featuredImageIndex = _selectedImages.length - 1;
      } else if (_selectedImages.isEmpty) {
        _featuredImageIndex = 0;
      }
      
      _onContentChanged();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('이미지가 제거되었습니다'),
        backgroundColor: WriterTheme.accentOrange,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}