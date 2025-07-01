import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/writer_theme.dart';
import 'animated_counter.dart';

/// 대시보드 메트릭 카드 위젯
/// 
/// 각 메트릭(조회수, 좋아요, 구독자 등)을 표시하는 반응형 카드입니다.
/// 애니메이션과 트렌드 인디케이터를 포함합니다.
class DashboardMetricCard extends StatelessWidget {
  final String title;
  final int value;
  final int? previousValue;
  final IconData icon;
  final Color iconColor;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool showTrend;
  final String? trendLabel;

  const DashboardMetricCard({
    Key? key,
    required this.title,
    required this.value,
    this.previousValue,
    required this.icon,
    required this.iconColor,
    this.subtitle,
    this.onTap,
    this.isLoading = false,
    this.showTrend = true,
    this.trendLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    
    // 트렌드 계산
    final trendPercentage = _calculateTrendPercentage();
    final isPositiveTrend = trendPercentage >= 0;
    final trendColor = isPositiveTrend 
        ? WriterTheme.accentGreen 
        : WriterTheme.accentRed;

    return GestureDetector(
      onTap: onTap != null ? () {
        HapticFeedback.lightImpact();
        onTap!();
      } : null,
      child: Container(
        padding: EdgeInsets.all(isCompact ? 16 : 20),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더: 아이콘과 제목
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: isCompact ? 20 : 24,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: (isCompact 
                        ? WriterTheme.bodyStyle 
                        : WriterTheme.subtitleStyle).copyWith(
                      color: WriterTheme.neutralGray600,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: WriterTheme.neutralGray400,
                  ),
              ],
            ),
            
            SizedBox(height: isCompact ? 12 : 16),
            
            // 메인 값
            if (isLoading)
              _buildLoadingSkeleton(isCompact)
            else ...[
              AnimatedCounter(
                value: value,
                style: (isCompact 
                    ? WriterTheme.titleStyle 
                    : WriterTheme.headlineStyle).copyWith(
                  color: WriterTheme.neutralGray900,
                  fontWeight: FontWeight.w700,
                ),
                formatter: _formatNumber,
              ),
              
              SizedBox(height: isCompact ? 6 : 8),
              
              // 서브타이틀과 트렌드
              Row(
                children: [
                  if (subtitle != null)
                    Expanded(
                      child: Text(
                        subtitle!,
                        style: WriterTheme.captionStyle.copyWith(
                          color: WriterTheme.neutralGray500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  
                  if (showTrend && previousValue != null && !isLoading)
                    _buildTrendIndicator(
                      trendPercentage, 
                      trendColor, 
                      isCompact
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 로딩 스켈레톤 위젯
  Widget _buildLoadingSkeleton(bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isCompact ? 80 : 120,
          height: isCompact ? 28 : 36,
          decoration: BoxDecoration(
            color: WriterTheme.neutralGray200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(height: isCompact ? 6 : 8),
        Container(
          width: isCompact ? 60 : 80,
          height: 12,
          decoration: BoxDecoration(
            color: WriterTheme.neutralGray100,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  /// 트렌드 인디케이터 위젯
  Widget _buildTrendIndicator(double percentage, Color color, bool isCompact) {
    final isPositive = percentage >= 0;
    final formattedPercentage = percentage.abs().toStringAsFixed(1);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: isCompact ? 10 : 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            trendLabel ?? '${formattedPercentage}%',
            style: WriterTheme.captionStyle.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }

  /// 트렌드 백분율 계산
  double _calculateTrendPercentage() {
    if (previousValue == null || previousValue == 0) return 0.0;
    return ((value - previousValue!) / previousValue!) * 100;
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
}

/// 메트릭 그리드 위젯
/// 
/// 여러 메트릭 카드를 반응형 그리드로 배치합니다.
class DashboardMetricsGrid extends StatelessWidget {
  final List<DashboardMetricCard> metricCards;
  final int? crossAxisCount;

  const DashboardMetricsGrid({
    Key? key,
    required this.metricCards,
    this.crossAxisCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // 반응형 컬럼 개수 결정
    int columns = crossAxisCount ?? _getOptimalColumnCount(screenWidth);
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: _getChildAspectRatio(screenWidth, columns),
      ),
      itemCount: metricCards.length,
      itemBuilder: (context, index) => metricCards[index],
    );
  }

  /// 최적 컬럼 개수 계산
  int _getOptimalColumnCount(double screenWidth) {
    if (screenWidth >= 1200) return 4;      // 대형 데스크톱
    if (screenWidth >= 900) return 3;       // 태블릿 가로
    if (screenWidth >= 600) return 2;       // 태블릿 세로
    return 2;                               // 모바일
  }

  /// 카드 비율 계산
  double _getChildAspectRatio(double screenWidth, int columns) {
    if (screenWidth < 600) {
      return columns == 1 ? 2.5 : 1.3;     // 모바일
    } else if (screenWidth < 900) {
      return 1.4;                           // 태블릿
    } else {
      return 1.5;                           // 데스크톱
    }
  }
}

/// 빠른 메트릭 요약 위젯
/// 
/// 주요 지표들을 한 줄로 간단히 표시합니다.
class QuickMetricsSummary extends StatelessWidget {
  final int totalViews;
  final int totalLikes;
  final int subscribersCount;
  final bool isLoading;

  const QuickMetricsSummary({
    Key? key,
    required this.totalViews,
    required this.totalLikes,
    required this.subscribersCount,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            WriterTheme.primaryBlue.withOpacity(0.05),
            WriterTheme.primaryBlue.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: WriterTheme.primaryBlue.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickMetric(
              '조회수',
              totalViews,
              Icons.visibility_outlined,
              WriterTheme.primaryBlue,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: WriterTheme.neutralGray200,
          ),
          Expanded(
            child: _buildQuickMetric(
              '좋아요',
              totalLikes,
              Icons.favorite_outline,
              WriterTheme.accentRed,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: WriterTheme.neutralGray200,
          ),
          Expanded(
            child: _buildQuickMetric(
              '구독자',
              subscribersCount,
              Icons.people_outline,
              WriterTheme.accentGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMetric(String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        const SizedBox(height: 4),
        if (isLoading)
          Container(
            width: 40,
            height: 16,
            decoration: BoxDecoration(
              color: WriterTheme.neutralGray200,
              borderRadius: BorderRadius.circular(4),
            ),
          )
        else
          AnimatedCounter(
            value: value,
            style: WriterTheme.subtitleStyle.copyWith(
              color: WriterTheme.neutralGray900,
              fontWeight: FontWeight.w700,
            ),
            formatter: (number) {
              if (number >= 1000) {
                return '${(number / 1000).toStringAsFixed(1)}K';
              }
              return number.toString();
            },
          ),
        const SizedBox(height: 2),
        Text(
          label,
          style: WriterTheme.captionStyle.copyWith(
            color: WriterTheme.neutralGray500,
          ),
        ),
      ],
    );
  }
}