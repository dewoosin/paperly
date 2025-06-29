import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analytics_provider.dart';
import '../theme/writer_theme.dart';

class TrendingTopicsCard extends StatelessWidget {
  const TrendingTopicsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsProvider>(
      builder: (context, analyticsProvider, child) {
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
                    Icons.trending_up,
                    color: WriterTheme.primaryBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '트렌딩 주제',
                    style: WriterTheme.titleStyle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (analyticsProvider.isLoading)
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
              
              const SizedBox(height: 16),
              
              if (analyticsProvider.isLoading && analyticsProvider.trendingTopics.isEmpty)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else if (analyticsProvider.trendingTopics.isEmpty)
                _buildEmptyState()
              else
                Column(
                  children: analyticsProvider.trendingTopics
                      .take(5) // 최대 5개만 표시
                      .map((topic) => _buildTopicItem(topic))
                      .toList(),
                ),
              
              if (analyticsProvider.trendingTopics.isNotEmpty) ...[
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      // 전체 트렌딩 주제 페이지로 이동
                      // Navigator.push...
                    },
                    child: Text(
                      '더 많은 주제 보기',
                      style: WriterTheme.captionStyle.copyWith(
                        color: WriterTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
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
            Icons.analytics,
            size: 48,
            color: WriterTheme.neutralGray400,
          ),
          const SizedBox(height: 12),
          Text(
            '트렌딩 주제를 분석 중이에요',
            style: WriterTheme.subtitleStyle.copyWith(
              color: WriterTheme.neutralGray600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '곧 인기 주제들을 확인할 수 있어요',
            style: WriterTheme.bodyStyle.copyWith(
              color: WriterTheme.neutralGray500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTopicItem(TrendingTopic topic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                  topic.name,
                  style: WriterTheme.subtitleStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: WriterTheme.neutralGray900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildTrendIndicator(topic),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: WriterTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  topic.category,
                  style: WriterTheme.captionStyle.copyWith(
                    color: WriterTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${topic.articleCount}개 글',
                style: WriterTheme.captionStyle.copyWith(
                  color: WriterTheme.neutralGray500,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_formatViews(topic.totalViews)} 조회',
                style: WriterTheme.captionStyle.copyWith(
                  color: WriterTheme.neutralGray500,
                ),
              ),
            ],
          ),
          
          if (topic.keywords.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: topic.keywords.take(3).map((keyword) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: WriterTheme.neutralGray200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#$keyword',
                  style: WriterTheme.captionStyle.copyWith(
                    color: WriterTheme.neutralGray700,
                    fontSize: 10,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(TrendingTopic topic) {
    final isRising = topic.growthRate > 0;
    final isHot = topic.growthRate > 50;
    
    Color color;
    IconData icon;
    String text;
    
    if (isHot) {
      color = WriterTheme.accentRed;
      icon = Icons.local_fire_department;
      text = 'HOT';
    } else if (isRising) {
      color = WriterTheme.accentGreen;
      icon = Icons.trending_up;
      text = topic.displayGrowthRate;
    } else if (topic.growthRate < 0) {
      color = WriterTheme.accentOrange;
      icon = Icons.trending_down;
      text = topic.displayGrowthRate;
    } else {
      color = WriterTheme.neutralGray500;
      icon = Icons.remove;
      text = '변화없음';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: WriterTheme.captionStyle.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _formatViews(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    } else {
      return views.toString();
    }
  }
}