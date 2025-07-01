import { Router, Request, Response, NextFunction } from 'express';
import { inject, injectable } from 'tsyringe';
import { Logger } from '../../logging/Logger';
import { authMiddleware } from '../middleware/auth.middleware';

/**
 * 작가 대시보드 성능 지표 인터페이스
 */
interface WriterDashboardMetrics {
  totalViews: number;
  totalLikes: number;
  subscribersCount: number;
  totalArticles: number;
  publishedArticles: number;
  draftArticles: number;
  averageEngagement: number;
  weeklyViews: number;
  weeklyLikes: number;
  weeklySubscribers: number;
  topPerformingArticles: Array<{
    id: string;
    title: string;
    views: number;
    likes: number;
    publishedAt: string;
  }>;
  recentActivity: Array<{
    type: 'view' | 'like' | 'subscribe' | 'article_published';
    count: number;
    date: string;
  }>;
  categoryPerformance: Array<{
    category: string;
    articles: number;
    views: number;
    engagement: number;
  }>;
}

/**
 * 작가 대시보드 메트릭 컨트롤러
 * 작가의 성능 지표를 실시간으로 제공합니다.
 */
@injectable()
export class WriterDashboardController {
  public readonly router: Router;
  private readonly logger = new Logger('WriterDashboardController');

  constructor() {
    this.router = Router();
    this.setupRoutes();
  }

  private setupRoutes() {
    // 대시보드 메인 메트릭
    this.router.get('/metrics', authMiddleware(), this.getDashboardMetrics.bind(this));
    
    // 상세 통계
    this.router.get('/metrics/detailed', authMiddleware(), this.getDetailedMetrics.bind(this));
    
    // 실시간 통계 (웹소켓 대안으로 폴링용)
    this.router.get('/metrics/realtime', authMiddleware(), this.getRealtimeMetrics.bind(this));
    
    // 기간별 통계
    this.router.get('/metrics/period', authMiddleware(), this.getPeriodMetrics.bind(this));
    
    // 비교 통계 (이전 기간 대비)
    this.router.get('/metrics/comparison', authMiddleware(), this.getComparisonMetrics.bind(this));
  }

  /**
   * 대시보드 메인 메트릭 조회
   * GET /api/writer/dashboard/metrics
   */
  private async getDashboardMetrics(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId;
      
      if (!userId) {
        return res.status(401).json({
          success: false,
          error: { code: 'UNAUTHORIZED', message: '로그인이 필요합니다.' }
        });
      }

      this.logger.info('대시보드 메트릭 요청', { userId });

      // TODO: 실제 데이터베이스 쿼리로 교체
      // 현재는 시뮬레이션 데이터 제공
      const metrics: WriterDashboardMetrics = await this.simulateWriterMetrics(userId);

      res.json({
        success: true,
        data: metrics,
        timestamp: new Date().toISOString()
      });
      
    } catch (error) {
      this.logger.error('대시보드 메트릭 조회 실패', { error, userId: (req as any).user?.userId });
      next(error);
    }
  }

  /**
   * 상세 통계 조회
   * GET /api/writer/dashboard/metrics/detailed
   */
  private async getDetailedMetrics(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId;
      const { startDate, endDate, granularity = 'day' } = req.query;

      if (!userId) {
        return res.status(401).json({
          success: false,
          error: { code: 'UNAUTHORIZED', message: '로그인이 필요합니다.' }
        });
      }

      this.logger.info('상세 메트릭 요청', { userId, startDate, endDate, granularity });

      // TODO: 실제 구현 시 날짜 범위와 세분화 수준에 따른 데이터 쿼리
      const detailedMetrics = {
        period: {
          start: startDate || new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
          end: endDate || new Date().toISOString(),
          granularity
        },
        viewsOverTime: this.generateTimeSeriesData('views', 30),
        likesOverTime: this.generateTimeSeriesData('likes', 30),
        subscribersOverTime: this.generateTimeSeriesData('subscribers', 30),
        engagementOverTime: this.generateTimeSeriesData('engagement', 30),
        topArticlesByViews: [
          { id: '1', title: 'React 최적화 기법', views: 1250, likes: 89, publishedAt: '2025-06-15T09:00:00Z' },
          { id: '2', title: 'TypeScript 고급 패턴', views: 980, likes: 76, publishedAt: '2025-06-20T14:30:00Z' },
          { id: '3', title: 'Node.js 성능 튜닝', views: 856, likes: 62, publishedAt: '2025-06-25T11:15:00Z' }
        ],
        topArticlesByLikes: [
          { id: '2', title: 'TypeScript 고급 패턴', views: 980, likes: 76, publishedAt: '2025-06-20T14:30:00Z' },
          { id: '1', title: 'React 최적화 기법', views: 1250, likes: 89, publishedAt: '2025-06-15T09:00:00Z' },
          { id: '3', title: 'Node.js 성능 튜닝', views: 856, likes: 62, publishedAt: '2025-06-25T11:15:00Z' }
        ]
      };

      res.json({
        success: true,
        data: detailedMetrics,
        timestamp: new Date().toISOString()
      });
      
    } catch (error) {
      this.logger.error('상세 메트릭 조회 실패', { error, userId: (req as any).user?.userId });
      next(error);
    }
  }

  /**
   * 실시간 메트릭 조회 (폴링용)
   * GET /api/writer/dashboard/metrics/realtime
   */
  private async getRealtimeMetrics(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId;
      
      if (!userId) {
        return res.status(401).json({
          success: false,
          error: { code: 'UNAUTHORIZED', message: '로그인이 필요합니다.' }
        });
      }

      // 실시간 지표 (최근 1시간)
      const realtimeMetrics = {
        lastHour: {
          views: Math.floor(Math.random() * 50) + 10,
          likes: Math.floor(Math.random() * 15) + 2,
          subscribers: Math.floor(Math.random() * 5),
          comments: Math.floor(Math.random() * 8) + 1
        },
        currentOnlineReaders: Math.floor(Math.random() * 25) + 5,
        trendingArticles: [
          { id: '1', title: 'React 최적화 기법', currentReaders: 12 },
          { id: '2', title: 'TypeScript 고급 패턴', currentReaders: 8 }
        ],
        lastUpdate: new Date().toISOString()
      };

      res.json({
        success: true,
        data: realtimeMetrics,
        timestamp: new Date().toISOString()
      });
      
    } catch (error) {
      this.logger.error('실시간 메트릭 조회 실패', { error, userId: (req as any).user?.userId });
      next(error);
    }
  }

  /**
   * 기간별 메트릭 조회
   * GET /api/writer/dashboard/metrics/period
   */
  private async getPeriodMetrics(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId;
      const { period = 'week' } = req.query; // week, month, quarter, year
      
      if (!userId) {
        return res.status(401).json({
          success: false,
          error: { code: 'UNAUTHORIZED', message: '로그인이 필요합니다.' }
        });
      }

      const periodMetrics = {
        period,
        current: {
          views: period === 'week' ? 2340 : period === 'month' ? 9870 : 42350,
          likes: period === 'week' ? 187 : period === 'month' ? 756 : 3240,
          subscribers: period === 'week' ? 23 : period === 'month' ? 89 : 345,
          engagement: period === 'week' ? 8.2 : period === 'month' ? 7.9 : 8.5
        },
        growth: {
          views: period === 'week' ? 15.4 : period === 'month' ? 23.1 : 18.7,
          likes: period === 'week' ? 12.8 : period === 'month' ? 19.5 : 22.3,
          subscribers: period === 'week' ? 35.3 : period === 'month' ? 28.9 : 31.2,
          engagement: period === 'week' ? 5.7 : period === 'month' ? 8.2 : 6.8
        },
        topPerformers: [
          { metric: 'views', article: 'React 최적화 기법', value: 1250 },
          { metric: 'likes', article: 'TypeScript 고급 패턴', value: 89 },
          { metric: 'engagement', article: 'Node.js 성능 튜닝', value: 15.7 }
        ]
      };

      res.json({
        success: true,
        data: periodMetrics,
        timestamp: new Date().toISOString()
      });
      
    } catch (error) {
      this.logger.error('기간별 메트릭 조회 실패', { error, userId: (req as any).user?.userId });
      next(error);
    }
  }

  /**
   * 비교 메트릭 조회 (이전 기간 대비)
   * GET /api/writer/dashboard/metrics/comparison
   */
  private async getComparisonMetrics(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId;
      const { compareWith = 'previous_period' } = req.query;
      
      if (!userId) {
        return res.status(401).json({
          success: false,
          error: { code: 'UNAUTHORIZED', message: '로그인이 필요합니다.' }
        });
      }

      const comparisonMetrics = {
        current: {
          period: 'current_week',
          views: 2340,
          likes: 187,
          subscribers: 23,
          articles: 3
        },
        previous: {
          period: 'previous_week',
          views: 2035,
          likes: 162,
          subscribers: 17,
          articles: 2
        },
        changes: {
          views: { absolute: 305, percentage: 15.0, trend: 'up' },
          likes: { absolute: 25, percentage: 15.4, trend: 'up' },
          subscribers: { absolute: 6, percentage: 35.3, trend: 'up' },
          articles: { absolute: 1, percentage: 50.0, trend: 'up' }
        },
        insights: [
          { type: 'positive', message: '이번 주 구독자 증가율이 35% 상승했습니다!' },
          { type: 'positive', message: '글 조회수가 지난주 대비 15% 증가했습니다.' },
          { type: 'suggestion', message: 'TypeScript 관련 글의 인기가 높습니다. 더 많은 관련 콘텐츠를 작성해보세요.' }
        ]
      };

      res.json({
        success: true,
        data: comparisonMetrics,
        timestamp: new Date().toISOString()
      });
      
    } catch (error) {
      this.logger.error('비교 메트릭 조회 실패', { error, userId: (req as any).user?.userId });
      next(error);
    }
  }

  /**
   * 작가 메트릭 시뮬레이션 (실제 구현 시 데이터베이스 쿼리로 교체)
   */
  private async simulateWriterMetrics(userId: string): Promise<WriterDashboardMetrics> {
    // 실제 구현에서는 다음과 같은 쿼리들이 필요:
    // 1. 총 조회수: SELECT SUM(view_count) FROM articles WHERE author_id = userId
    // 2. 총 좋아요: SELECT SUM(like_count) FROM articles WHERE author_id = userId  
    // 3. 구독자 수: SELECT COUNT(*) FROM follows WHERE writer_id = userId
    // 4. 글 통계: SELECT COUNT(*), SUM(CASE WHEN status='published' THEN 1 ELSE 0 END) FROM articles WHERE author_id = userId
    
    return {
      totalViews: Math.floor(Math.random() * 50000) + 10000, // 10K-60K
      totalLikes: Math.floor(Math.random() * 3000) + 500,    // 500-3.5K
      subscribersCount: Math.floor(Math.random() * 500) + 50, // 50-550
      totalArticles: Math.floor(Math.random() * 25) + 5,     // 5-30
      publishedArticles: Math.floor(Math.random() * 20) + 4, // 4-24
      draftArticles: Math.floor(Math.random() * 5) + 1,      // 1-6
      averageEngagement: Math.round((Math.random() * 10 + 5) * 10) / 10, // 5.0-15.0%
      weeklyViews: Math.floor(Math.random() * 2000) + 300,   // 300-2.3K
      weeklyLikes: Math.floor(Math.random() * 150) + 20,     // 20-170
      weeklySubscribers: Math.floor(Math.random() * 30) + 5, // 5-35
      topPerformingArticles: [
        {
          id: '1',
          title: 'React 최적화 완벽 가이드: 성능 개선의 모든 것',
          views: 1250,
          likes: 89,
          publishedAt: '2025-06-15T09:00:00Z'
        },
        {
          id: '2', 
          title: 'TypeScript 고급 패턴으로 코드 품질 향상하기',
          views: 980,
          likes: 76,
          publishedAt: '2025-06-20T14:30:00Z'
        },
        {
          id: '3',
          title: 'Node.js 성능 튜닝: 프로덕션 환경 최적화 전략',
          views: 856,
          likes: 62,
          publishedAt: '2025-06-25T11:15:00Z'
        }
      ],
      recentActivity: [
        { type: 'view', count: 125, date: '2025-07-01' },
        { type: 'like', count: 12, date: '2025-07-01' },
        { type: 'subscribe', count: 3, date: '2025-07-01' },
        { type: 'view', count: 98, date: '2025-06-30' },
        { type: 'like', count: 8, date: '2025-06-30' },
        { type: 'article_published', count: 1, date: '2025-06-30' }
      ],
      categoryPerformance: [
        { category: 'Frontend', articles: 8, views: 4250, engagement: 8.5 },
        { category: 'Backend', articles: 5, views: 2890, engagement: 7.2 },
        { category: 'DevOps', articles: 3, views: 1560, engagement: 9.1 },
        { category: 'Tutorial', articles: 6, views: 3420, engagement: 8.8 }
      ]
    };
  }

  /**
   * 시계열 데이터 생성 (시뮬레이션용)
   */
  private generateTimeSeriesData(metric: string, days: number) {
    const data = [];
    const baseValue = metric === 'views' ? 100 : metric === 'likes' ? 8 : metric === 'subscribers' ? 2 : 10;
    
    for (let i = days; i >= 0; i--) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      
      const value = Math.floor(Math.random() * baseValue * 2) + baseValue;
      data.push({
        date: date.toISOString().split('T')[0],
        value
      });
    }
    
    return data;
  }
}