import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../theme/muji_theme.dart';
import '../providers/auth_provider.dart';

/// 검색 및 필터 화면
/// Blinkist 스타일의 검색 기능을 제공
class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _fadeController;
  
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String _selectedSortBy = 'relevance';
  bool _isSearching = false;

  // 임시 검색 결과 데이터
  final List<Map<String, dynamic>> _allArticles = [
    {
      'title': '디지털 미니멀리즘의 원칙',
      'author': '칼 뉴포트',
      'category': '자기계발',
      'readTime': '12분',
      'image': '📱',
      'color': Color(0xFF6366f1),
      'description': '현대 사회에서 디지털 기기와 건강한 관계를 맺는 방법을 탐구합니다.',
      'tags': ['디지털', '미니멀리즘', '자기계발', '생산성'],
    },
    {
      'title': '창의성의 과학적 원리',
      'author': '아담 그랜트',
      'category': '창의성',
      'readTime': '15분',
      'image': '🧠',
      'color': Color(0xFF8b5cf6),
      'description': '혁신적인 아이디어가 어떻게 탄생하는지 과학적으로 분석합니다.',
      'tags': ['창의성', '과학', '혁신', '아이디어'],
    },
    {
      'title': '지속가능한 미래 설계',
      'author': '김환경',
      'category': '환경',
      'readTime': '10분',
      'image': '🌱',
      'color': Color(0xFF10b981),
      'description': '기후 변화 시대에 개인과 사회가 실천할 수 있는 구체적 방안들.',
      'tags': ['환경', '지속가능성', '기후변화', '미래'],
    },
    {
      'title': '인공지능과 인간의 미래',
      'author': '김AI',
      'category': '과학기술',
      'readTime': '18분',
      'image': '🤖',
      'color': Color(0xFF06b6d4),
      'description': 'AI 시대에 인간이 가져야 할 역량과 준비해야 할 것들.',
      'tags': ['AI', '인공지능', '미래', '기술'],
    },
    {
      'title': '마음의 철학',
      'author': '철학자',
      'category': '철학',
      'readTime': '20분',
      'image': '🤔',
      'color': Color(0xFF84cc16),
      'description': '마음과 의식에 대한 철학적 탐구와 현대적 해석.',
      'tags': ['철학', '의식', '마음', '사고'],
    },
  ];

  final List<Map<String, dynamic>> _categories = [
    {'name': 'all', 'label': '전체', 'count': '850+'},
    {'name': '비즈니스', 'label': '비즈니스', 'count': '340+'},
    {'name': '자기계발', 'label': '자기계발', 'count': '280+'},
    {'name': '과학기술', 'label': '과학기술', 'count': '190+'},
    {'name': '철학', 'label': '철학', 'count': '120+'},
    {'name': '예술', 'label': '예술', 'count': '95+'},
    {'name': '역사', 'label': '역사', 'count': '150+'},
  ];

  final List<Map<String, String>> _sortOptions = [
    {'value': 'relevance', 'label': '관련도순'},
    {'value': 'newest', 'label': '최신순'},
    {'value': 'popular', 'label': '인기순'},
    {'value': 'shortest', 'label': '짧은 읽기 시간순'},
    {'value': 'longest', 'label': '긴 읽기 시간순'},
  ];

  final List<String> _recentSearches = [
    '디지털 미니멀리즘',
    '창의성',
    'AI 미래',
    '환경',
    '철학',
  ];

  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
      _performSearch();
    });

    // 초기 검색 결과는 전체 글 목록
    _searchResults = List.from(_allArticles);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch() {
    setState(() {
      _isSearching = true;
    });

    // 검색 로직 구현 (임시)
    Future.delayed(const Duration(milliseconds: 300), () {
      List<Map<String, dynamic>> results = List.from(_allArticles);

      // 텍스트 검색
      if (_searchQuery.isNotEmpty) {
        results = results.where((article) {
          final searchLower = _searchQuery.toLowerCase();
          return article['title'].toLowerCase().contains(searchLower) ||
                 article['author'].toLowerCase().contains(searchLower) ||
                 article['description'].toLowerCase().contains(searchLower) ||
                 (article['tags'] as List).any((tag) => 
                   tag.toLowerCase().contains(searchLower));
        }).toList();
      }

      // 카테고리 필터
      if (_selectedCategory != 'all') {
        results = results.where((article) => 
          article['category'] == _selectedCategory).toList();
      }

      // 정렬
      switch (_selectedSortBy) {
        case 'newest':
          // 실제로는 날짜 기준 정렬
          results.shuffle();
          break;
        case 'popular':
          // 실제로는 조회수 기준 정렬
          results.shuffle();
          break;
        case 'shortest':
          results.sort((a, b) => 
            int.parse(a['readTime'].replaceAll('분', ''))
                .compareTo(int.parse(b['readTime'].replaceAll('분', ''))));
          break;
        case 'longest':
          results.sort((a, b) => 
            int.parse(b['readTime'].replaceAll('분', ''))
                .compareTo(int.parse(a['readTime'].replaceAll('분', ''))));
          break;
        default:
          // relevance - 기본 순서 유지
          break;
      }

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: MujiTheme.bg,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: safeTop + 120),
              ),
              
              // 검색 결과가 없고 검색어도 없을 때: 최근 검색어 표시
              if (_searchQuery.isEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildRecentSearches(),
                ),
                SliverToBoxAdapter(
                  child: _buildTrendingTopics(),
                ),
              ]
              // 검색 결과 표시
              else ...[
                SliverToBoxAdapter(
                  child: _buildSearchResultsHeader(),
                ),
                if (_isSearching)
                  SliverToBoxAdapter(
                    child: _buildLoadingIndicator(),
                  )
                else if (_searchResults.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildNoResults(),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final article = _searchResults[index];
                        return _buildSearchResultItem(article, index);
                      },
                      childCount: _searchResults.length,
                    ),
                  ),
              ],
              
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
          
          _buildSearchAppBar(safeTop),
        ],
      ),
    );
  }

  Widget _buildSearchAppBar(double safeTop) {
    return Container(
      height: safeTop + 120,
      decoration: BoxDecoration(
        color: MujiTheme.bg.withOpacity(0.95),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.only(top: safeTop + 16),
            child: Column(
              children: [
                // 헤더
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: MujiTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: MujiTheme.border.withOpacity(0.5),
                              width: 0.5,
                            ),
                          ),
                          child: const Icon(
                            CupertinoIcons.back,
                            size: 20,
                            color: MujiTheme.textBody,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: MujiTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: MujiTheme.border.withOpacity(0.5),
                              width: 0.5,
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: '글, 작가, 주제를 검색해보세요',
                              hintStyle: MujiTheme.mobileBody.copyWith(
                                color: MujiTheme.textHint,
                              ),
                              prefixIcon: const Icon(
                                CupertinoIcons.search,
                                size: 18,
                                color: MujiTheme.textHint,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        _searchController.clear();
                                        _searchFocusNode.requestFocus();
                                      },
                                      child: const Icon(
                                        CupertinoIcons.xmark_circle_fill,
                                        size: 18,
                                        color: MujiTheme.textHint,
                                      ),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            style: MujiTheme.mobileBody,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 필터 탭
                if (_searchQuery.isNotEmpty)
                  _buildFilterTabs(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // 카테고리 필터
          Expanded(
            child: GestureDetector(
              onTap: () => _showCategoryFilter(),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: _selectedCategory != 'all' 
                      ? MujiTheme.sage.withOpacity(0.1)
                      : MujiTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _selectedCategory != 'all'
                        ? MujiTheme.sage.withOpacity(0.3)
                        : MujiTheme.border.withOpacity(0.5),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.tag,
                      size: 14,
                      color: _selectedCategory != 'all' 
                          ? MujiTheme.sage 
                          : MujiTheme.textHint,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _selectedCategory == 'all' 
                            ? '카테고리' 
                            : _selectedCategory,
                        style: MujiTheme.mobileLabel.copyWith(
                          color: _selectedCategory != 'all' 
                              ? MujiTheme.sage 
                              : MujiTheme.textBody,
                          fontWeight: _selectedCategory != 'all' 
                              ? FontWeight.w600 
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    Icon(
                      CupertinoIcons.chevron_down,
                      size: 12,
                      color: _selectedCategory != 'all' 
                          ? MujiTheme.sage 
                          : MujiTheme.textHint,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 정렬 필터
          Expanded(
            child: GestureDetector(
              onTap: () => _showSortFilter(),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: MujiTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: MujiTheme.border.withOpacity(0.5),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.sort_down,
                      size: 14,
                      color: MujiTheme.textHint,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _sortOptions.firstWhere(
                          (option) => option['value'] == _selectedSortBy
                        )['label']!,
                        style: MujiTheme.mobileLabel.copyWith(
                          color: MujiTheme.textBody,
                        ),
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.chevron_down,
                      size: 12,
                      color: MujiTheme.textHint,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    return FadeTransition(
      opacity: _fadeController,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '최근 검색',
              style: MujiTheme.mobileH3.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((search) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = search;
                    _searchFocusNode.unfocus();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: MujiTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: MujiTheme.border.withOpacity(0.5),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.clock,
                          size: 14,
                          color: MujiTheme.textHint,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          search,
                          style: MujiTheme.mobileCaption.copyWith(
                            color: MujiTheme.textBody,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingTopics() {
    final trendingTopics = [
      '디지털 미니멀리즘',
      'AI와 미래',
      '지속가능성',
      '창의성 개발',
      '마음챙김',
      '리더십',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '인기 주제',
            style: MujiTheme.mobileH3.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: trendingTopics.map((topic) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = topic;
                  _searchFocusNode.unfocus();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        MujiTheme.sage.withOpacity(0.1),
                        MujiTheme.moss.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: MujiTheme.sage.withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.flame,
                        size: 14,
                        color: MujiTheme.sage,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        topic,
                        style: MujiTheme.mobileCaption.copyWith(
                          color: MujiTheme.sage,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        children: [
          Text(
            '검색 결과',
            style: MujiTheme.mobileH3.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_searchResults.length}개',
            style: MujiTheme.mobileBody.copyWith(
              color: MujiTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(MujiTheme.sage),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: MujiTheme.sage.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              CupertinoIcons.search,
              size: 40,
              color: MujiTheme.sage,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '검색 결과가 없어요',
            style: MujiTheme.mobileH3.copyWith(
              fontWeight: FontWeight.w600,
              color: MujiTheme.textBody,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '다른 키워드로 검색해보거나\n필터를 조정해보세요',
            style: MujiTheme.mobileBody.copyWith(
              color: MujiTheme.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(Map<String, dynamic> article, int index) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        color: MujiTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: MujiTheme.border.withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            // TODO: 글 상세 화면으로 이동
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 글 아이콘
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        article['color'] as Color,
                        (article['color'] as Color).withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      article['image'],
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // 글 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 카테고리 + 읽기 시간
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: (article['color'] as Color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              article['category'],
                              style: MujiTheme.mobileLabel.copyWith(
                                color: article['color'] as Color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            article['readTime'],
                            style: MujiTheme.mobileLabel.copyWith(
                              color: MujiTheme.textHint,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // 제목
                      Text(
                        article['title'],
                        style: MujiTheme.mobileBody.copyWith(
                          fontWeight: FontWeight.w600,
                          color: MujiTheme.textDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // 작가
                      Text(
                        article['author'],
                        style: MujiTheme.mobileCaption.copyWith(
                          color: MujiTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: MujiTheme.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: MujiTheme.textHint.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                '카테고리 선택',
                style: MujiTheme.mobileH3.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              
              const SizedBox(height: 16),
              
              ..._categories.map((category) {
                final isSelected = _selectedCategory == category['name'];
                return ListTile(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category['name'];
                    });
                    _performSearch();
                    Navigator.pop(context);
                  },
                  leading: isSelected
                      ? const Icon(CupertinoIcons.checkmark_circle_fill, 
                          color: MujiTheme.sage)
                      : const Icon(CupertinoIcons.circle, 
                          color: MujiTheme.textHint),
                  title: Text(
                    category['label'],
                    style: MujiTheme.mobileBody.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? MujiTheme.sage : MujiTheme.textDark,
                    ),
                  ),
                  trailing: Text(
                    category['count'],
                    style: MujiTheme.mobileCaption.copyWith(
                      color: MujiTheme.textHint,
                    ),
                  ),
                );
              }).toList(),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: MujiTheme.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: MujiTheme.textHint.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                '정렬 방법',
                style: MujiTheme.mobileH3.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              
              const SizedBox(height: 16),
              
              ..._sortOptions.map((option) {
                final isSelected = _selectedSortBy == option['value'];
                return ListTile(
                  onTap: () {
                    setState(() {
                      _selectedSortBy = option['value']!;
                    });
                    _performSearch();
                    Navigator.pop(context);
                  },
                  leading: isSelected
                      ? const Icon(CupertinoIcons.checkmark_circle_fill, 
                          color: MujiTheme.sage)
                      : const Icon(CupertinoIcons.circle, 
                          color: MujiTheme.textHint),
                  title: Text(
                    option['label']!,
                    style: MujiTheme.mobileBody.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? MujiTheme.sage : MujiTheme.textDark,
                    ),
                  ),
                );
              }).toList(),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}