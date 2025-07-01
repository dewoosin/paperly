import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analytics_provider.dart';
import '../providers/article_provider.dart';
import '../theme/writer_theme.dart';
import 'animated_counter.dart';

class StatsOverviewCard extends StatelessWidget {
  const StatsOverviewCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<AnalyticsProvider, ArticleProvider>(
      builder: (context, analytics, articles, child) {
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
                    Icons.analytics,
                    color: WriterTheme.primaryBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '통계 개요',
                    style: WriterTheme.titleStyle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (analytics.isLoading)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(WriterTheme.primaryBlue),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // 주요 통계
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      '총 글',
                      '${articles.articleStats['total'] ?? 0}',
                      Icons.article,
                      WriterTheme.primaryBlue,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: WriterTheme.neutralGray200,
                  ),
                  Expanded(
                    child: _buildStatItem(
                      '발행됨',
                      '${articles.articleStats['published'] ?? 0}',
                      Icons.check_circle,
                      WriterTheme.accentGreen,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: WriterTheme.neutralGray200,
                  ),
                  Expanded(
                    child: _buildStatItem(
                      '조회수',
                      _formatNumber(articles.totalViews),
                      Icons.visibility,
                      WriterTheme.accentOrange,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 상세 통계
              Row(
                children: [
                  Expanded(
                    child: _buildDetailStatItem(
                      '좋아요',
                      _formatNumber(articles.totalLikes),
                      Icons.favorite,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailStatItem(
                      '공유',
                      _formatNumber(articles.totalShares),
                      Icons.share,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailStatItem(
                      '초안',
                      '${articles.articleStats['draft'] ?? 0}',
                      Icons.edit,
                    ),
                  ),
                ],
              ),
              
              // 성장률 표시 (통계가 있는 경우)
              if (analytics.stats != null) ...[
                const SizedBox(height: 16),
                _buildGrowthIndicator(analytics.stats!),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedCounter(
          value: int.tryParse(value) ?? 0,
          style: WriterTheme.titleStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: WriterTheme.captionStyle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDetailStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WriterTheme.neutralGray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WriterTheme.neutralGray200),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: WriterTheme.neutralGray500,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedCounter(
                  value: int.tryParse(value) ?? 0,
                  style: WriterTheme.subtitleStyle.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: WriterTheme.captionStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthIndicator(WriterStats stats) {
    final growthRate = stats.viewGrowthRate;
    final isPositive = growthRate > 0;
    final isNegative = growthRate < 0;
    
    Color growthColor = WriterTheme.neutralGray500;
    IconData growthIcon = Icons.remove;
    
    if (isPositive) {
      growthColor = WriterTheme.accentGreen;
      growthIcon = Icons.trending_up;
    } else if (isNegative) {
      growthColor = WriterTheme.accentRed;
      growthIcon = Icons.trending_down;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: growthColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            growthIcon,
            color: growthColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '지난 달 대비 ',
            style: WriterTheme.captionStyle,
          ),
          Text(
            '${growthRate.abs().toStringAsFixed(1)}%',
            style: WriterTheme.captionStyle.copyWith(
              fontWeight: FontWeight.bold,
              color: growthColor,
            ),
          ),
          Text(
            isPositive ? ' 증가' : isNegative ? ' 감소' : ' 변화 없음',
            style: WriterTheme.captionStyle,
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