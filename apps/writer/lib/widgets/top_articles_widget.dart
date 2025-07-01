import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/writer_theme.dart';
import '../providers/dashboard_provider.dart';

/// 상위 성과 아티클 위젯
/// 
/// 가장 성과가 좋은 아티클들을 순위와 함께 표시합니다.
class TopArticlesWidget extends StatelessWidget {
  final List<TopArticle> articles;
  final bool isLoading;
  final String title;
  final String sortBy; // 'views', 'likes', 'engagement'
  final VoidCallback? onSeeAll;

  const TopArticlesWidget({
    Key? key,
    required this.articles,
    this.isLoading = false,
    this.title = '인기 아티클',
    this.sortBy = 'views',
    this.onSeeAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: WriterTheme.neutralGray200,
          width: 1,
        ),
        boxShadow: WriterTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Icon(
                _getSortIcon(sortBy),
                color: WriterTheme.primaryBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: WriterTheme.titleStyle.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    foregroundColor: WriterTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '전체보기',
                        style: WriterTheme.bodyStyle.copyWith(
                          color: WriterTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: WriterTheme.primaryBlue,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 아티클 리스트
          if (isLoading)
            _buildLoadingList()
          else if (articles.isEmpty)
            _buildEmptyState()
          else
            _buildArticleList(),
        ],
      ),
    );
  }

  /// 로딩 상태 리스트
  Widget _buildLoadingList() {
    return Column(
      children: List.generate(3, (index) => _buildLoadingItem()),
    );
  }

  /// 빈 상태
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.article_outlined,
            size: 48,
            color: WriterTheme.neutralGray400,
          ),
          const SizedBox(height: 12),
          Text(
            '아직 발행된 아티클이 없습니다',
            style: WriterTheme.bodyStyle.copyWith(
              color: WriterTheme.neutralGray500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '첫 번째 아티클을 작성해보세요!',
            style: WriterTheme.captionStyle.copyWith(
              color: WriterTheme.neutralGray400,
            ),
          ),
        ],
      ),
    );
  }

  /// 아티클 리스트
  Widget _buildArticleList() {
    // 최대 5개까지만 표시
    final displayArticles = articles.take(5).toList();
    
    return Column(
      children: displayArticles.asMap().entries.map((entry) {
        final index = entry.key;
        final article = entry.value;
        final isLast = index == displayArticles.length - 1;
        
        return _buildArticleItem(article, index + 1, isLast);
      }).toList(),
    );
  }

  /// 아티클 아이템
  Widget _buildArticleItem(TopArticle article, int rank, bool isLast) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // TODO: 아티클 상세로 이동
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: isLast ? null : Border(
            bottom: BorderSide(
              color: WriterTheme.neutralGray100,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // 순위 뱃지
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _getRankColor(rank),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  rank.toString(),
                  style: WriterTheme.captionStyle.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // 아티클 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: WriterTheme.bodyStyle.copyWith(
                      color: WriterTheme.neutralGray900,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildMetricBadge(
                        Icons.visibility_outlined,
                        article.views,
                        WriterTheme.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      _buildMetricBadge(
                        Icons.favorite_outline,
                        article.likes,
                        WriterTheme.accentRed,
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(article.publishedAt),
                        style: WriterTheme.captionStyle.copyWith(
                          color: WriterTheme.neutralGray400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 8),
            
            // 화살표 아이콘
            Icon(
              Icons.chevron_right,
              size: 16,
              color: WriterTheme.neutralGray400,
            ),
          ],
        ),
      ),
    );
  }

  /// 로딩 아이템
  Widget _buildLoadingItem() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // 순위 스켈레톤
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: WriterTheme.neutralGray200,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 콘텐츠 스켈레톤
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: WriterTheme.neutralGray200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 12,
                      decoration: BoxDecoration(
                        color: WriterTheme.neutralGray100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 50,
                      height: 12,
                      decoration: BoxDecoration(
                        color: WriterTheme.neutralGray100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 메트릭 뱃지
  Widget _buildMetricBadge(IconData icon, int value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 2),
        Text(
          _formatNumber(value),
          style: WriterTheme.captionStyle.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// 순위별 색상
  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return WriterTheme.accentOrange; // 금메달
      case 2:
        return WriterTheme.neutralGray500; // 은메달
      case 3:
        return WriterTheme.accentPurple; // 동메달
      default:
        return WriterTheme.primaryBlue;
    }
  }

  /// 정렬 기준별 아이콘
  IconData _getSortIcon(String sortBy) {
    switch (sortBy) {
      case 'views':
        return Icons.visibility_outlined;
      case 'likes':
        return Icons.favorite_outline;
      case 'engagement':
        return Icons.trending_up;
      default:
        return Icons.analytics_outlined;
    }
  }

  /// 숫자 포맷팅
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  /// 날짜 포맷팅
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()}개월 전';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}일 전';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}시간 전';
      } else {
        return '방금 전';
      }
    } catch (e) {
      return '';
    }
  }
}

/// 성과 비교 위젯
/// 
/// 이전 기간 대비 성과 변화를 시각적으로 표시합니다.
class PerformanceComparisonWidget extends StatelessWidget {
  final int currentViews;
  final int previousViews;
  final int currentLikes;
  final int previousLikes;
  final int currentSubscribers;
  final int previousSubscribers;
  final String period;
  final bool isLoading;

  const PerformanceComparisonWidget({
    Key? key,
    required this.currentViews,
    required this.previousViews,
    required this.currentLikes,
    required this.previousLikes,
    required this.currentSubscribers,
    required this.previousSubscribers,
    this.period = '이번 주',
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: WriterTheme.neutralGray200,
          width: 1,
        ),
        boxShadow: WriterTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Icon(
                Icons.compare_arrows,
                color: WriterTheme.accentPurple,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '$period vs 지난 주',
                style: WriterTheme.titleStyle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (isLoading)
            _buildLoadingComparison()
          else
            _buildComparisonList(),
        ],
      ),
    );
  }

  Widget _buildLoadingComparison() {
    return Column(
      children: List.generate(3, (index) => 
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: WriterTheme.neutralGray200,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 16,
                      decoration: BoxDecoration(
                        color: WriterTheme.neutralGray200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: WriterTheme.neutralGray100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonList() {
    final comparisons = [
      _ComparisonData(
        title: '조회수',
        icon: Icons.visibility_outlined,
        color: WriterTheme.primaryBlue,
        current: currentViews,
        previous: previousViews,
      ),
      _ComparisonData(
        title: '좋아요',
        icon: Icons.favorite_outline,
        color: WriterTheme.accentRed,
        current: currentLikes,
        previous: previousLikes,
      ),
      _ComparisonData(
        title: '구독자',
        icon: Icons.people_outline,
        color: WriterTheme.accentGreen,
        current: currentSubscribers,
        previous: previousSubscribers,
      ),
    ];

    return Column(
      children: comparisons.map((data) => _buildComparisonItem(data)).toList(),
    );
  }

  Widget _buildComparisonItem(_ComparisonData data) {
    final changePercentage = data.previous > 0 
        ? ((data.current - data.previous) / data.previous) * 100 
        : 0.0;
    
    final isPositive = changePercentage >= 0;
    final trendColor = isPositive ? WriterTheme.accentGreen : WriterTheme.accentRed;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              data.icon,
              size: 20,
              color: data.color,
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: WriterTheme.bodyStyle.copyWith(
                    color: WriterTheme.neutralGray900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _formatNumber(data.current),
                      style: WriterTheme.subtitleStyle.copyWith(
                        color: WriterTheme.neutralGray700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: trendColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive ? Icons.trending_up : Icons.trending_down,
                            size: 10,
                            color: trendColor,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${changePercentage.abs().toStringAsFixed(1)}%',
                            style: WriterTheme.captionStyle.copyWith(
                              color: trendColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }
}

class _ComparisonData {
  final String title;
  final IconData icon;
  final Color color;
  final int current;
  final int previous;

  _ComparisonData({
    required this.title,
    required this.icon,
    required this.color,
    required this.current,
    required this.previous,
  });
}