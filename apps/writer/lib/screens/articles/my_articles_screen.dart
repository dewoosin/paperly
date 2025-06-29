import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/article_provider.dart';
import '../../models/article.dart';
import '../../theme/writer_theme.dart';
import '../../widgets/writer_app_bar.dart';
import 'article_editor_screen.dart';

class MyArticlesScreen extends StatefulWidget {
  const MyArticlesScreen({Key? key}) : super(key: key);

  @override
  State<MyArticlesScreen> createState() => _MyArticlesScreenState();
}

class _MyArticlesScreenState extends State<MyArticlesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ArticleProvider>(context, listen: false).loadMyArticles();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WriterTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(
              '내 글 관리',
              style: WriterTheme.titleStyle.copyWith(
                color: WriterTheme.neutralGray900,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.white,
            foregroundColor: WriterTheme.neutralGray900,
            elevation: 0,
            scrolledUnderElevation: 1,
            floating: true,
            snap: true,
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ArticleEditorScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: WriterTheme.primaryBlue,
                  unselectedLabelColor: WriterTheme.neutralGray600,
                  indicatorColor: WriterTheme.primaryBlue,
                  labelStyle: WriterTheme.bodyStyle.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: WriterTheme.bodyStyle,
                  tabs: const [
                    Tab(text: '전체'),
                    Tab(text: '초안'),
                    Tab(text: '발행됨'),
                    Tab(text: '검토중'),
                  ],
                ),
              ),
            ),
          ),
          
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildArticleList(ArticleFilter.all),
                _buildArticleList(ArticleFilter.draft),
                _buildArticleList(ArticleFilter.published),
                _buildArticleList(ArticleFilter.review),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleList(ArticleFilter filter) {
    return Consumer<ArticleProvider>(
      builder: (context, articleProvider, child) {
        List<Article> articles;
        
        switch (filter) {
          case ArticleFilter.all:
            articles = articleProvider.myArticles;
            break;
          case ArticleFilter.draft:
            articles = articleProvider.draftArticles;
            break;
          case ArticleFilter.published:
            articles = articleProvider.myPublishedArticles;
            break;
          case ArticleFilter.review:
            articles = articleProvider.reviewArticles;
            break;
        }

        if (articleProvider.isLoading && articles.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (articles.isEmpty) {
          return _buildEmptyState(filter);
        }

        return RefreshIndicator(
          onRefresh: () => articleProvider.loadMyArticles(refresh: true),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              return _buildArticleCard(article);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ArticleFilter filter) {
    String title;
    String subtitle;
    IconData icon;

    switch (filter) {
      case ArticleFilter.all:
        title = '아직 작성한 글이 없어요';
        subtitle = '첫 번째 글을 작성해보세요!';
        icon = Icons.article;
        break;
      case ArticleFilter.draft:
        title = '임시 저장된 글이 없어요';
        subtitle = '글을 작성하면 자동으로 임시 저장됩니다';
        icon = Icons.edit_document;
        break;
      case ArticleFilter.published:
        title = '발행된 글이 없어요';
        subtitle = '초안을 완성하고 발행해보세요';
        icon = Icons.publish;
        break;
      case ArticleFilter.review:
        title = '검토 중인 글이 없어요';
        subtitle = '글을 제출하면 검토 상태가 됩니다';
        icon = Icons.rate_review;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: WriterTheme.neutralGray400,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: WriterTheme.titleStyle.copyWith(
              color: WriterTheme.neutralGray600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: WriterTheme.bodyStyle.copyWith(
              color: WriterTheme.neutralGray500,
            ),
            textAlign: TextAlign.center,
          ),
          if (filter == ArticleFilter.all || filter == ArticleFilter.draft) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ArticleEditorScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('글 작성하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: WriterTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildArticleCard(Article article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArticleEditorScreen(article: article),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: WriterTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      article.title.isEmpty ? '제목 없음' : article.title,
                      style: WriterTheme.titleStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: article.title.isEmpty 
                            ? WriterTheme.neutralGray500 
                            : WriterTheme.neutralGray900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildStatusChip(article.status),
                ],
              ),
              
              if (article.content.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  article.content,
                  style: WriterTheme.bodyStyle.copyWith(
                    color: WriterTheme.neutralGray600,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: WriterTheme.neutralGray500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(article.updatedAt),
                    style: WriterTheme.captionStyle.copyWith(
                      color: WriterTheme.neutralGray500,
                    ),
                  ),
                  const Spacer(),
                  if (article.status == ArticleStatus.published) ...[
                    Icon(
                      Icons.visibility,
                      size: 16,
                      color: WriterTheme.neutralGray500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${article.viewCount}',
                      style: WriterTheme.captionStyle.copyWith(
                        color: WriterTheme.neutralGray500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.favorite,
                      size: 16,
                      color: WriterTheme.neutralGray500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${article.likeCount}',
                      style: WriterTheme.captionStyle.copyWith(
                        color: WriterTheme.neutralGray500,
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleArticleAction(value, article),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16, color: WriterTheme.neutralGray700),
                            const SizedBox(width: 8),
                            const Text('편집'),
                          ],
                        ),
                      ),
                      if (article.status == ArticleStatus.draft)
                        PopupMenuItem(
                          value: 'publish',
                          child: Row(
                            children: [
                              Icon(Icons.publish, size: 16, color: WriterTheme.accentGreen),
                              const SizedBox(width: 8),
                              const Text('발행'),
                            ],
                          ),
                        ),
                      if (article.status == ArticleStatus.published)
                        PopupMenuItem(
                          value: 'unpublish',
                          child: Row(
                            children: [
                              Icon(Icons.unpublished, size: 16, color: WriterTheme.accentOrange),
                              const SizedBox(width: 8),
                              const Text('발행 취소'),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: WriterTheme.accentRed),
                            const SizedBox(width: 8),
                            const Text('삭제'),
                          ],
                        ),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      color: WriterTheme.neutralGray500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(ArticleStatus status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case ArticleStatus.draft:
        backgroundColor = WriterTheme.neutralGray200;
        textColor = WriterTheme.neutralGray700;
        text = '초안';
        break;
      case ArticleStatus.review:
        backgroundColor = WriterTheme.accentOrange.withOpacity(0.2);
        textColor = WriterTheme.accentOrange;
        text = '검토중';
        break;
      case ArticleStatus.published:
        backgroundColor = WriterTheme.accentGreen.withOpacity(0.2);
        textColor = WriterTheme.accentGreen;
        text = '발행됨';
        break;
      case ArticleStatus.archived:
        backgroundColor = WriterTheme.neutralGray300;
        textColor = WriterTheme.neutralGray600;
        text = '보관됨';
        break;
      default:
        backgroundColor = WriterTheme.neutralGray200;
        textColor = WriterTheme.neutralGray700;
        text = '알 수 없음';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: WriterTheme.captionStyle.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  void _handleArticleAction(String action, Article article) async {
    final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
    
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleEditorScreen(article: article),
          ),
        );
        break;
        
      case 'publish':
        final success = await articleProvider.publishArticle(article.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('글이 성공적으로 발행되었습니다.'),
              backgroundColor: WriterTheme.accentGreen,
            ),
          );
        }
        break;
        
      case 'unpublish':
        final success = await articleProvider.unpublishArticle(article.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('글 발행이 취소되었습니다.'),
              backgroundColor: WriterTheme.accentOrange,
            ),
          );
        }
        break;
        
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('글 삭제'),
            content: const Text('정말로 이 글을 삭제하시겠습니까? 삭제된 글은 복구할 수 없습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  '삭제',
                  style: TextStyle(color: WriterTheme.accentRed),
                ),
              ),
            ],
          ),
        );
        
        if (confirmed == true) {
          final success = await articleProvider.deleteArticle(article.id);
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('글이 삭제되었습니다.'),
                backgroundColor: WriterTheme.accentRed,
              ),
            );
          }
        }
        break;
    }
  }
}

enum ArticleFilter {
  all,
  draft,
  published,
  review,
}