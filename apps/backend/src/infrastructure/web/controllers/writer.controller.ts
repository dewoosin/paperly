import { Router, Request, Response, NextFunction } from 'express';
import { inject, injectable } from 'tsyringe';
import { Logger } from '../../logging/Logger';

/**
 * 작가 관리 컨트롤러
 * 작가 등록, 프로필 관리, 작가 승인 등의 기능을 제공합니다.
 */
@injectable()
export class WriterController {
  public readonly router: Router;
  private readonly logger = new Logger('WriterController');

  constructor() {
    this.router = Router();
    this.setupRoutes();
  }

  private setupRoutes() {
    // 작가 등록 및 프로필 관리
    this.router.post('/apply', this.applyWriter.bind(this));
    this.router.get('/profile/:userId', this.getWriterProfile.bind(this));
    this.router.put('/profile', this.updateWriterProfile.bind(this));
    
    // 작가 목록 및 검색
    this.router.get('/list', this.getWriterList.bind(this));
    this.router.get('/search', this.searchWriters.bind(this));
    
    // 관리자 전용 - 작가 승인 관리
    this.router.put('/approve/:userId', this.approveWriter.bind(this));
    this.router.put('/reject/:userId', this.rejectWriter.bind(this));
    this.router.get('/pending', this.getPendingWriters.bind(this));
  }

  /**
   * 작가 신청
   * POST /api/writers/apply
   */
  private async applyWriter(req: Request, res: Response, next: NextFunction) {
    try {
      // 인증된 사용자 ID 가져오기
      const userId = (req as any).user?.userId;
      
      if (!userId) {
        return res.status(401).json({
          success: false,
          error: { code: 'UNAUTHORIZED', message: '로그인이 필요합니다.' }
        });
      }

      const {
        penName,
        bio,
        expertiseAreas,
        writingStyle,
        socialLinks,
        websiteUrl
      } = req.body;

      // TODO: WriterService 구현 후 실제 로직 연결
      // const result = await this.writerService.applyWriter({
      //   userId,
      //   penName,
      //   bio,
      //   expertiseAreas,
      //   writingStyle,
      //   socialLinks,
      //   websiteUrl
      // });

      // 임시 응답
      const result = {
        success: true,
        writerId: 'temp-writer-id',
        status: 'pending'
      };

      this.logger.info('작가 신청 완료', { userId, penName });

      res.status(201).json({
        success: true,
        data: result,
        message: '작가 신청이 완료되었습니다. 검토 후 결과를 알려드리겠습니다.'
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * 작가 프로필 조회
   * GET /api/writers/profile/:userId
   */
  private async getWriterProfile(req: Request, res: Response, next: NextFunction) {
    try {
      const { userId } = req.params;

      // TODO: WriterService 구현 후 실제 로직 연결
      // const profile = await this.writerService.getWriterProfile(userId);

      // 임시 응답
      const profile = {
        id: userId,
        penName: '테스트 작가',
        bio: '테스트 작가입니다.',
        expertiseAreas: ['기술', '프로그래밍'],
        writingStyle: 'casual',
        isVerified: false,
        writerLevel: 'new',
        applicationStatus: 'pending',
        totalArticles: 0,
        totalViews: 0,
        followerCount: 0
      };

      res.json({
        success: true,
        data: profile
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * 작가 프로필 수정
   * PUT /api/writers/profile
   */
  private async updateWriterProfile(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId;
      
      if (!userId) {
        return res.status(401).json({
          success: false,
          error: { code: 'UNAUTHORIZED', message: '로그인이 필요합니다.' }
        });
      }

      // TODO: WriterService 구현 후 실제 로직 연결
      // const result = await this.writerService.updateProfile(userId, req.body);

      res.json({
        success: true,
        message: '프로필이 수정되었습니다.'
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * 작가 목록 조회
   * GET /api/writers/list
   */
  private async getWriterList(req: Request, res: Response, next: NextFunction) {
    try {
      const { page = 1, limit = 20, level, verified } = req.query;

      // TODO: WriterService 구현 후 실제 로직 연결
      // const result = await this.writerService.getWriterList({
      //   page: Number(page),
      //   limit: Number(limit),
      //   level: level as string,
      //   verified: verified === 'true'
      // });

      // 임시 응답
      const result = {
        writers: [],
        pagination: {
          page: Number(page),
          limit: Number(limit),
          total: 0,
          totalPages: 0
        }
      };

      res.json({
        success: true,
        data: result
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * 작가 검색
   * GET /api/writers/search
   */
  private async searchWriters(req: Request, res: Response, next: NextFunction) {
    try {
      const { q: query, expertise, level } = req.query;

      if (!query) {
        return res.status(400).json({
          success: false,
          error: { code: 'BAD_REQUEST', message: '검색어가 필요합니다.' }
        });
      }

      // TODO: WriterService 구현 후 실제 로직 연결
      // const result = await this.writerService.searchWriters({
      //   query: query as string,
      //   expertise: expertise as string,
      //   level: level as string
      // });

      // 임시 응답
      const result = {
        writers: [],
        total: 0
      };

      res.json({
        success: true,
        data: result
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * 작가 승인 (관리자 전용)
   * PUT /api/writers/approve/:userId
   */
  private async approveWriter(req: Request, res: Response, next: NextFunction) {
    try {
      const { userId } = req.params;
      const adminUserId = (req as any).user?.userId;

      // TODO: 관리자 권한 확인
      // TODO: WriterService 구현 후 실제 로직 연결
      // const result = await this.writerService.approveWriter(userId, adminUserId);

      this.logger.info('작가 승인 완료', { userId, approvedBy: adminUserId });

      res.json({
        success: true,
        message: '작가가 승인되었습니다.'
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * 작가 거부 (관리자 전용)
   * PUT /api/writers/reject/:userId
   */
  private async rejectWriter(req: Request, res: Response, next: NextFunction) {
    try {
      const { userId } = req.params;
      const { reason } = req.body;
      const adminUserId = (req as any).user?.userId;

      // TODO: WriterService 구현 후 실제 로직 연결
      // const result = await this.writerService.rejectWriter(userId, reason, adminUserId);

      this.logger.info('작가 거부 완료', { userId, rejectedBy: adminUserId, reason });

      res.json({
        success: true,
        message: '작가 신청이 거부되었습니다.'
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * 대기 중인 작가 신청 목록 (관리자 전용)
   * GET /api/writers/pending
   */
  private async getPendingWriters(req: Request, res: Response, next: NextFunction) {
    try {
      const { page = 1, limit = 20 } = req.query;

      // TODO: WriterService 구현 후 실제 로직 연결
      // const result = await this.writerService.getPendingWriters({
      //   page: Number(page),
      //   limit: Number(limit)
      // });

      // 임시 응답
      const result = {
        writers: [],
        pagination: {
          page: Number(page),
          limit: Number(limit),
          total: 0,
          totalPages: 0
        }
      };

      res.json({
        success: true,
        data: result
      });
    } catch (error) {
      next(error);
    }
  }
}