import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analytics_provider.dart';
import '../theme/writer_theme.dart';
import 'animated_counter.dart';

class FollowerStatsCard extends StatelessWidget {
  const FollowerStatsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsProvider>(
      builder: (context, analytics, child) {
        final stats = analytics.stats;
        
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                WriterTheme.primaryBlue,
                WriterTheme.primaryBlueDark,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: WriterTheme.primaryBlue.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // 메인 팔로워 수
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people,
                    color: Colors.white.withOpacity(0.9),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      AnimatedCounter(
                        value: stats?.followersCount ?? 0,
                        style: WriterTheme.headingStyle.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 48,
                        ),
                        formatter: (value) => _formatFollowerCount(value),
                      ),
                      Text(
                        '구독자',
                        style: WriterTheme.subtitleStyle.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // 성장률 표시
              if (stats != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getGrowthIcon(stats.viewGrowthRate),
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '지난 달 대비 ${stats.viewGrowthRate > 0 ? '+' : ''}${stats.viewGrowthRate.toStringAsFixed(1)}%',
                        style: WriterTheme.bodyStyle.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
              
              // 상세 통계
              Row(
                children: [
                  Expanded(
                    child: _buildDetailStat(
                      '이번 주',
                      '+${stats?.monthlyStats.isNotEmpty == true ? (stats!.monthlyStats.last.views / 4).round() : 0}',
                      Icons.calendar_today,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.2),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  Expanded(
                    child: _buildDetailStat(
                      '평균 참여',
                      '${stats?.averageLikeRate.toStringAsFixed(1) ?? "0"}%',
                      Icons.favorite_border,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.2),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  Expanded(
                    child: _buildDetailStat(
                      '활성 팔로워',
                      '${((stats?.followersCount ?? 0) * 0.73).round()}',
                      Icons.bolt,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.8),
          size: 20,
        ),
        const SizedBox(height: 8),
        AnimatedCounter(
          value: int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
          style: WriterTheme.subtitleStyle.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: WriterTheme.captionStyle.copyWith(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatFollowerCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

  IconData _getGrowthIcon(double growthRate) {
    if (growthRate > 0) {
      return Icons.trending_up;
    } else if (growthRate < 0) {
      return Icons.trending_down;
    } else {
      return Icons.trending_flat;
    }
  }
}