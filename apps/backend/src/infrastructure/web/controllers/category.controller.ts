import { Router, Request, Response, NextFunction } from 'express';
import { inject, injectable } from 'tsyringe';
import { Logger } from '../../logging/Logger';

/**
 * 카테고리 관리 컨트롤러
 * 계층적 카테고리 구조 관리 및 구독 기능을 제공합니다.
 */
@injectable()
export class CategoryController {
  public readonly router: Router;
  private readonly logger = new Logger('CategoryController');

  constructor() {
    this.router = Router();
    this.setupRoutes();
  }

  private setupRoutes() {
    // 카테고리 조회
    this.router.get('/', this.getCategoryList.bind(this));
    this.router.get('/tree', this.getCategoryTree.bind(this));
    this.router.get('/featured', this.getFeaturedCategories.bind(this));
    this.router.get('/:id', this.getCategory.bind(this));
    this.router.get('/:id/subcategories', this.getSubcategories.bind(this));
    this.router.get('/:id/articles', this.getCategoryArticles.bind(this));
    
    // 카테고리 구독 (인증 필요)
    this.router.post('/:id/subscribe', this.subscribeCategory.bind(this));
    this.router.delete('/:id/subscribe', this.unsubscribeCategory.bind(this));
    this.router.get('/subscriptions/my', this.getMySubscriptions.bind(this));
    
    // 관리자 전용 - 카테고리 관리
    this.router.post('/', this.createCategory.bind(this));
    this.router.put('/:id', this.updateCategory.bind(this));
    this.router.delete('/:id', this.deleteCategory.bind(this));
    this.router.put('/:id/reorder', this.reorderCategories.bind(this));
  }

  /**
   * 카테고리 목록 조회
   * GET /api/categories
   */
  private async getCategoryList(req: Request, res: Response, next: NextFunction) {
    try {
      const { 
        parentId = null, 
        includeInactive = 'false', 
        sortBy = 'sort_order' 
      } = req.query;

      // TODO: CategoryService 구현 후 실제 로직 연결
      // const categories = await this.categoryService.getCategoryList({
      //   parentId: parentId as string,
      //   includeInactive: includeInactive === 'true',
      //   sortBy: sortBy as string
      // });

      // 임시 응답 - 기초 데이터 스크립트의 카테고리 구조
      const categories = [
        {
          id: 'tech-id',
          name: '기술',
          slug: 'technology',
          description: 'IT, 프로그래밍, 소프트웨어 개발 관련 글',
          iconName: '💻',
          colorCode: '#2563EB',
          isFeatured: true,
          sortOrder: 1,
          articleCount: 5,
          subscriberCount: 120
        },
        {
          id: 'business-id',
          name: '비즈니스',
          slug: 'business',
          description: '경영, 창업, 마케팅, 투자 관련 글',
          iconName: '💼',
          colorCode: '#059669',
          isFeatured: true,
          sortOrder: 2,
          articleCount: 3,
          subscriberCount: 85
        },
        {
          id: 'lifestyle-id',
          name: '라이프스타일',
          slug: 'lifestyle',
          description: '건강, 여행, 취미, 일상 관련 글',
          iconName: '🌟',
          colorCode: '#DC2626',
          isFeatured: true,
          sortOrder: 3,
          articleCount: 2,
          subscriberCount: 95
        }
      ];

      res.json({
        success: true,
        data: categories
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * 계층적 카테고리 트리 조회
   * GET /api/categories/tree
   */
  private async getCategoryTree(req: Request, res: Response, next: NextFunction) {
    try {
      const { includeInactive = 'false' } = req.query;

      // TODO: CategoryService 구현 후 실제 로직 연결
      // const categoryTree = await this.categoryService.getCategoryTree({
      //   includeInactive: includeInactive === 'true'
      // });

      // 임시 응답 - 계층 구조
      const categoryTree = [
        {
          id: 'tech-id',
          name: '기술',
          slug: 'technology',
          iconName: '💻',
          colorCode: '#2563EB',
          children: [
            { id: 'programming-id', name: '프로그래밍', slug: 'programming', iconName: '⌨️' },
            { id: 'web-dev-id', name: '웹 개발', slug: 'web-development', iconName: '🌐' },
            { id: 'mobile-dev-id', name: '모바일 개발', slug: 'mobile-development', iconName: '📱' },
            { id: 'ai-ml-id', name: 'AI/ML', slug: 'ai-ml', iconName: '🤖' }
          ]
        },
        {
          id: 'business-id',
          name: '비즈니스',
          slug: 'business',
          iconName: '💼',
          colorCode: '#059669',
          children: [
            { id: 'startup-id', name: '창업', slug: 'startup', iconName: '🚀' },
            { id: 'marketing-id', name: '마케팅', slug: 'marketing', iconName: '📢' },
            { id: 'investment-id', name: '투자', slug: 'investment', iconName: '💰' },
            { id: 'management-id', name: '경영', slug: 'management', iconName: '👔' }
          ]
        }
      ];

      res.json({
        success: true,
        data: categoryTree
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * 추천 카테고리 조회
   * GET /api/categories/featured
   */
  private async getFeaturedCategories(req: Request, res: Response, next: NextFunction) {
    try {
      // TODO: CategoryService 구현 후 실제 로직 연결
      // const featuredCategories = await this.categoryService.getFeaturedCategories();

      // 임시 응답
      const featuredCategories = [
        {
          id: 'tech-id',
          name: '기술',
          slug: 'technology',
          description: 'IT, 프로그래밍, 소프트웨어 개발 관련 글',
          iconName: '💻',
          colorCode: '#2563EB',
          articleCount: 5,
          subscriberCount: 120
        },
        {
          id: 'business-id',
          name: '비즈니스',
          slug: 'business',
          description: '경영, 창업, 마케팅, 투자 관련 글',
          iconName: '💼',
          colorCode: '#059669',
          articleCount: 3,
          subscriberCount: 85
        }
      ];

      res.json({
        success: true,
        data: featuredCategories
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * 카테고리 상세 조회
   * GET /api/categories/:id
   */
  private async getCategory(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const userId = (req as any).user?.userId; // 로그인 사용자 (선택적)

      // TODO: CategoryService 구현 후 실제 로직 연결
      // const category = await this.categoryService.getCategoryById(id, userId);

      // 임시 응답
      const category = {
        id,
        name: '기술',
        slug: 'technology',
        description: 'IT, 프로그래밍, 소프트웨어 개발 관련 글',
        iconName: '💻',
        colorCode: '#2563EB',
        isFeatured: true,
        sortOrder: 1,
        articleCount: 5,
        subscriberCount: 120,
        isSubscribed: false, // 로그인 사용자의 구독 여부
        parent: null,
        children: [
          { id: 'programming-id', name: '프로그래밍', articleCount: 2 },
          { id: 'web-dev-id', name: '웹 개발', articleCount: 3 }
        ],
        recentArticles: [
          { id: 'article-1', title: '최신 기술 글 1', publishedAt: '2024-01-01' },
          { id: 'article-2', title: '최신 기술 글 2', publishedAt: '2024-01-02' }
        ]
      };

      res.json({
        success: true,
        data: category
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * 하위 카테고리 조회
   * GET /api/categories/:id/subcategories
   */
  private async getSubcategories(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;

      // TODO: CategoryService 구현 후 실제 로직 연결
      // const subcategories = await this.categoryService.getSubcategories(id);

      // 임시 응답
      const subcategories = [
        {
          id: 'programming-id',
          name: '프로그래밍',
          slug: 'programming',
          description: 'Python, JavaScript, Java 등 프로그래밍 언어',
          iconName: '⌨️',
          colorCode: '#1E40AF',
          articleCount: 2,
          subscriberCount: 45
        },
        {
          id: 'web-dev-id',
          name: '웹 개발',
          slug: 'web-development',
          description: 'Frontend, Backend, Full Stack 개발',
          iconName: '🌐',
          colorCode: '#3B82F6',
          articleCount: 3,
          subscriberCount: 38
        }
      ];

      res.json({
        success: true,
        data: subcategories
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * 카테고리별 게시글 조회
   * GET /api/categories/:id/articles
   */
  private async getCategoryArticles(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const { page = 1, limit = 20, sortBy = 'publishedAt', includeSubcategories = 'true' } = req.query;

      // TODO: CategoryService 구현 후 실제 로직 연결
      // const result = await this.categoryService.getCategoryArticles({
      //   categoryId: id,
      //   page: Number(page),
      //   limit: Number(limit),
      //   sortBy: sortBy as string,
      //   includeSubcategories: includeSubcategories === 'true'
      // });

      // 임시 응답
      const result = {
        articles: [],
        category: {
          id,
          name: '기술',
          slug: 'technology'
        },
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
   * 카테고리 구독
   * POST /api/categories/:id/subscribe
   */
  private async subscribeCategory(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const userId = (req as any).user?.userId;
      const { notificationEnabled = true, priorityLevel = 5 } = req.body;

      if (!userId) {
        return res.status(401).json({
          success: false,
          error: { code: 'UNAUTHORIZED', message: '로그인이 필요합니다.' }
        });
      }

      // TODO: CategoryService 구현 후 실제 로직 연결
      // const result = await this.categoryService.subscribeCategory({
      //   categoryId: id,
      //   userId,
      //   notificationEnabled,
      //   priorityLevel
      // });

      this.logger.info('카테고리 구독 완료', { userId, categoryId: id });

      res.status(201).json({
        success: true,
        message: '카테고리 구독이 완료되었습니다.'
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * 카테고리 구독 해제
   * DELETE /api/categories/:id/subscribe
   */
  private async unsubscribeCategory(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const userId = (req as any).user?.userId;

      if (!userId) {
        return res.status(401).json({
          success: false,
          error: { code: 'UNAUTHORIZED', message: '로그인이 필요합니다.' }
        });
      }

      // TODO: CategoryService 구현 후 실제 로직 연결
      // await this.categoryService.unsubscribeCategory(id, userId);

      this.logger.info('카테고리 구독 해제 완료', { userId, categoryId: id });

      res.json({
        success: true,
        message: '카테고리 구독이 해제되었습니다.'
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * 내 카테고리 구독 목록 조회
   * GET /api/categories/subscriptions/my
   */
  private async getMySubscriptions(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId;

      if (!userId) {
        return res.status(401).json({
          success: false,
          error: { code: 'UNAUTHORIZED', message: '로그인이 필요합니다.' }
        });
      }

      // TODO: CategoryService 구현 후 실제 로직 연결
      // const subscriptions = await this.categoryService.getUserSubscriptions(userId);

      // 임시 응답
      const subscriptions = [
        {
          id: 'sub-1',
          category: {
            id: 'tech-id',
            name: '기술',
            slug: 'technology',
            iconName: '💻',
            colorCode: '#2563EB'
          },
          notificationEnabled: true,
          priorityLevel: 8,
          subscribedAt: '2024-01-01T00:00:00Z'
        }
      ];

      res.json({
        success: true,
        data: subscriptions
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * 새 카테고리 생성 (관리자 전용)
   * POST /api/categories
   */
  private async createCategory(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId;

      // TODO: 관리자 권한 확인
      if (!userId) {
        return res.status(401).json({
          success: false,
          error: { code: 'UNAUTHORIZED', message: '로그인이 필요합니다.' }
        });
      }

      const {
        name,
        slug,
        description,
        parentId,
        iconName,
        colorCode,
        isFeatured,
        sortOrder,
        aiKeywords
      } = req.body;

      // TODO: CategoryService 구현 후 실제 로직 연결
      // const result = await this.categoryService.createCategory({
      //   name,
      //   slug,
      //   description,
      //   parentId,
      //   iconName,
      //   colorCode,
      //   isFeatured,
      //   sortOrder,
      //   aiKeywords,
      //   createdBy: userId
      // });

      // 임시 응답
      const result = {
        id: 'new-category-id',
        name,
        slug,
        createdAt: new Date().toISOString()
      };

      this.logger.info('새 카테고리 생성 완료', { userId, categoryId: result.id, name });

      res.status(201).json({
        success: true,
        data: result,
        message: '새 카테고리가 생성되었습니다.'
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * 카테고리 수정 (관리자 전용)
   * PUT /api/categories/:id
   */
  private async updateCategory(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const userId = (req as any).user?.userId;

      // TODO: 관리자 권한 확인
      if (!userId) {
        return res.status(401).json({
          success: false,
          error: { code: 'UNAUTHORIZED', message: '로그인이 필요합니다.' }
        });
      }

      // TODO: CategoryService 구현 후 실제 로직 연결
      // const result = await this.categoryService.updateCategory(id, req.body, userId);

      this.logger.info('카테고리 수정 완료', { userId, categoryId: id });

      res.json({
        success: true,
        message: '카테고리가 수정되었습니다.'
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * 카테고리 삭제 (관리자 전용)
   * DELETE /api/categories/:id
   */
  private async deleteCategory(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const userId = (req as any).user?.userId;

      // TODO: 관리자 권한 확인
      if (!userId) {
        return res.status(401).json({
          success: false,
          error: { code: 'UNAUTHORIZED', message: '로그인이 필요합니다.' }
        });
      }

      // TODO: CategoryService 구현 후 실제 로직 연결
      // await this.categoryService.deleteCategory(id, userId);

      this.logger.info('카테고리 삭제 완료', { userId, categoryId: id });

      res.json({
        success: true,
        message: '카테고리가 삭제되었습니다.'
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * 카테고리 순서 변경 (관리자 전용)
   * PUT /api/categories/:id/reorder
   */
  private async reorderCategories(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId;
      const { categoryOrders } = req.body; // [{ id: string, sortOrder: number }]

      // TODO: 관리자 권한 확인
      if (!userId) {
        return res.status(401).json({
          success: false,
          error: { code: 'UNAUTHORIZED', message: '로그인이 필요합니다.' }
        });
      }

      // TODO: CategoryService 구현 후 실제 로직 연결
      // await this.categoryService.reorderCategories(categoryOrders, userId);

      this.logger.info('카테고리 순서 변경 완료', { userId, orderCount: categoryOrders?.length });

      res.json({
        success: true,
        message: '카테고리 순서가 변경되었습니다.'
      });
    } catch (error) {
      next(error);
    }
  }
}