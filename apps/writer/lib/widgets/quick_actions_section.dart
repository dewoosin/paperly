import 'package:flutter/material.dart';
import '../theme/writer_theme.dart';
import '../screens/articles/article_editor_screen.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                Icons.flash_on,
                color: WriterTheme.primaryBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '빠른 작업',
                style: WriterTheme.titleStyle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  icon: Icons.add,
                  title: '새 글 작성',
                  subtitle: '빈 문서로 시작',
                  color: WriterTheme.primaryBlue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ArticleEditorScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  context,
                  icon: Icons.edit_document,
                  title: '임시글 계속',
                  subtitle: '저장된 초안',
                  color: WriterTheme.accentOrange,
                  onTap: () {
                    // 초안 목록으로 이동하거나 최근 초안 열기
                    _showDraftOptions(context);
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  icon: Icons.analytics,
                  title: '통계 보기',
                  subtitle: '성과 분석',
                  color: WriterTheme.accentGreen,
                  onTap: () {
                    // 통계 페이지로 이동
                    // Navigator.push...
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  context,
                  icon: Icons.trending_up,
                  title: '트렌드 분석',
                  subtitle: '인기 주제',
                  color: WriterTheme.accentPurple,
                  onTap: () {
                    // 트렌드 분석 페이지로 이동
                    // Navigator.push...
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: WriterTheme.subtitleStyle.copyWith(
                fontWeight: FontWeight.bold,
                color: WriterTheme.neutralGray900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: WriterTheme.captionStyle.copyWith(
                color: WriterTheme.neutralGray600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDraftOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.edit_document,
                  color: WriterTheme.accentOrange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '임시 저장된 글',
                  style: WriterTheme.titleStyle.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 여기에 초안 목록이 들어갈 수 있습니다
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: WriterTheme.neutralGray50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.description,
                    size: 48,
                    color: WriterTheme.neutralGray400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '임시 저장된 글이 없어요',
                    style: WriterTheme.subtitleStyle.copyWith(
                      color: WriterTheme.neutralGray600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '글을 작성하면 자동으로 임시 저장됩니다',
                    style: WriterTheme.bodyStyle.copyWith(
                      color: WriterTheme.neutralGray500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ArticleEditorScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: WriterTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '새 글 작성하기',
                  style: WriterTheme.subtitleStyle.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}