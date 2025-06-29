import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/article_provider.dart';
import '../models/article.dart';
import '../theme/writer_theme.dart';
import '../screens/articles/article_editor_screen.dart';

class RecentArticlesList extends StatelessWidget {
  const RecentArticlesList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ArticleProvider>(
      builder: (context, articleProvider, child) {
        final recentArticles = articleProvider.getRecentArticles(limit: 5);
        
        return Container(
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
                  Icon(
                    Icons.article,
                    color: WriterTheme.primaryBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '최근 작업',
                    style: WriterTheme.titleStyle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (recentArticles.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        // 전체 글 목록으로 이동
                        // Navigator.push... 
                      },
                      child: Text(
                        '전체보기',
                        style: WriterTheme.captionStyle.copyWith(
                          color: WriterTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              if (articleProvider.isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else if (recentArticles.isEmpty)
                _buildEmptyState()
              else
                Column(
                  children: recentArticles
                      .map((article) => _buildArticleItem(context, article))
                      .toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.edit_note,
            size: 48,
            color: WriterTheme.neutralGray400,
          ),
          const SizedBox(height: 12),
          Text(
            '아직 작성한 글이 없어요',
            style: WriterTheme.subtitleStyle.copyWith(
              color: WriterTheme.neutralGray600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '첫 번째 글을 작성해보세요!',
            style: WriterTheme.bodyStyle.copyWith(
              color: WriterTheme.neutralGray500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                _getCurrentContext(),
                MaterialPageRoute(
                  builder: (context) => const ArticleEditorScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('글 작성하기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: WriterTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleItem(BuildContext context, Article article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArticleEditorScreen(article: article),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: WriterTheme.neutralGray50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: WriterTheme.neutralGray200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      article.title.isEmpty ? '제목 없음' : article.title,
                      style: WriterTheme.subtitleStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: article.title.isEmpty 
                            ? WriterTheme.neutralGray500 
                            : WriterTheme.neutralGray900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(article.status),
                ],
              ),
              
              if (article.content.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  article.content,
                  style: WriterTheme.bodyStyle.copyWith(
                    color: WriterTheme.neutralGray600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
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
                      size: 14,
                      color: WriterTheme.neutralGray500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${article.viewCount}',
                      style: WriterTheme.captionStyle.copyWith(
                        color: WriterTheme.neutralGray500,
                      ),
                    ),
                  ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: WriterTheme.captionStyle.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  BuildContext _getCurrentContext() {
    // This is a workaround to get context in empty state
    // In a real app, you'd pass context through constructor
    return NavigatorState().context;
  }
}