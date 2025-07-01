import { Router, Request, Response } from 'express';
import { injectable, inject } from 'tsyringe';
import { Logger } from '../../logging/Logger';
import { ArticleService, ArticleSearchOptions } from '../../../application/services/article.service';
import { LikeService } from '../../../application/services/like.service';
import { ArticleStatus } from '../../../domain/entities/article.entity';
import { asyncHandler } from '../middlewares/async.middleware';
import { authMiddleware } from '../middleware/auth.middleware';

interface AuthRequest extends Request {
  user?: {
    id: string;
    email: string;
    roles?: string[];
  };
}

@injectable()
export class MobileArticleController {
  private readonly logger = new Logger('MobileArticleController');
  public readonly router = Router();

  constructor(
    @inject('ArticleService') private readonly articleService: ArticleService,
    @inject('LikeService') private readonly likeService: LikeService
  ) {
    this.initializeRoutes();
  }

  private initializeRoutes(): void {
    this.router.get('/', asyncHandler(this.getPublishedArticles.bind(this)));
    this.router.get('/featured', asyncHandler(this.getFeaturedArticles.bind(this)));
    this.router.get('/trending', asyncHandler(this.getTrendingArticles.bind(this)));
    this.router.get('/search', asyncHandler(this.searchArticles.bind(this)));
    this.router.get('/author/:authorId', asyncHandler(this.getArticlesByAuthor.bind(this)));
    this.router.get('/category/:categoryId', asyncHandler(this.getArticlesByCategory.bind(this)));
    this.router.get('/:id', asyncHandler(this.getArticleById.bind(this)));

    this.router.post('/:id/like', authMiddleware(), asyncHandler(this.likeArticle.bind(this)));
    this.router.delete('/:id/like', authMiddleware(), asyncHandler(this.unlikeArticle.bind(this)));
    this.router.post('/:id/toggle-like', authMiddleware(), asyncHandler(this.toggleLike.bind(this)));
    this.router.get('/:id/like-status', authMiddleware(), asyncHandler(this.getLikeStatus.bind(this)));

    this.logger.info('Mobile article routes initialized');
  }

  async getPublishedArticles(req: Request, res: Response): Promise<void> {
    const options: Omit<ArticleSearchOptions, 'status'> = {
      page: parseInt(req.query.page as string) || 1,
      limit: parseInt(req.query.limit as string) || 20,
      categoryId: req.query.categoryId as string,
      authorId: req.query.authorId as string,
      featured: req.query.featured === 'true',
      trending: req.query.trending === 'true',
      query: req.query.search as string,
    };

    const result = await this.articleService.getPublishedArticles(options);
    res.json({
      success: true,
      data: {
        articles: result.articles.map(article => ({
          ...article.toResponse(),
          summary: article.excerpt || article.content.substring(0, 200) + '...'
        })),
        pagination: {
          total: result.total,
          page: result.page,
          limit: result.limit,
          totalPages: Math.ceil(result.total / result.limit)
        }
      }
    });
  }

  async getFeaturedArticles(req: Request, res: Response): Promise<void> {
    const limit = req.query.limit ? parseInt(req.query.limit as string) : 5;
    const articles = await this.articleService.getFeaturedArticles(limit);
    
    res.json({
      success: true,
      data: {
        articles: articles.map(article => ({
          ...article.toResponse(),
          summary: article.excerpt || article.content.substring(0, 200) + '...'
        }))
      }
    });
  }

  async getTrendingArticles(req: Request, res: Response): Promise<void> {
    const limit = req.query.limit ? parseInt(req.query.limit as string) : 10;
    const articles = await this.articleService.getTrendingArticles(limit);
    
    res.json({
      success: true,
      data: {
        articles: articles.map(article => ({
          ...article.toResponse(),
          summary: article.excerpt || article.content.substring(0, 200) + '...'
        }))
      }
    });
  }

  async searchArticles(req: Request, res: Response): Promise<void> {
    const query = req.query.q as string;
    if (!query) {
      res.status(400).json({
        success: false,
        error: {
          code: 'MISSING_QUERY',
          message: 'Search query is required'
        }
      });
      return;
    }

    const options: Omit<ArticleSearchOptions, 'query'> = {
      page: parseInt(req.query.page as string) || 1,
      limit: parseInt(req.query.limit as string) || 20,
      categoryId: req.query.categoryId as string,
      authorId: req.query.authorId as string,
    };

    const result = await this.articleService.searchArticles(query, options);
    res.json({
      success: true,
      data: {
        articles: result.articles.map(article => ({
          ...article.toResponse(),
          summary: article.excerpt || article.content.substring(0, 200) + '...'
        })),
        query,
        pagination: {
          total: result.total,
          page: result.page,
          limit: result.limit,
          totalPages: Math.ceil(result.total / result.limit)
        }
      }
    });
  }

  async getArticleById(req: Request, res: Response): Promise<void> {
    const article = await this.articleService.getArticleById(req.params.id);
    
    res.json({
      success: true,
      data: {
        article: article.toResponse()
      }
    });
  }

  async getArticlesByAuthor(req: Request, res: Response): Promise<void> {
    const options: Omit<ArticleSearchOptions, 'authorId'> = {
      page: parseInt(req.query.page as string) || 1,
      limit: parseInt(req.query.limit as string) || 20,
      categoryId: req.query.categoryId as string,
      featured: req.query.featured === 'true',
      trending: req.query.trending === 'true',
      query: req.query.search as string,
    };

    const result = await this.articleService.getArticlesByAuthor(req.params.authorId, options);
    res.json({
      success: true,
      data: {
        articles: result.articles.map(article => ({
          ...article.toResponse(),
          summary: article.excerpt || article.content.substring(0, 200) + '...'
        })),
        authorId: req.params.authorId,
        pagination: {
          total: result.total,
          page: result.page,
          limit: result.limit,
          totalPages: Math.ceil(result.total / result.limit)
        }
      }
    });
  }

  async getArticlesByCategory(req: Request, res: Response): Promise<void> {
    const options: Omit<ArticleSearchOptions, 'categoryId'> = {
      page: parseInt(req.query.page as string) || 1,
      limit: parseInt(req.query.limit as string) || 20,
      authorId: req.query.authorId as string,
      featured: req.query.featured === 'true',
      trending: req.query.trending === 'true',
      query: req.query.search as string,
    };

    const result = await this.articleService.getArticlesByCategory(req.params.categoryId, options);
    res.json({
      success: true,
      data: {
        articles: result.articles.map(article => ({
          ...article.toResponse(),
          summary: article.excerpt || article.content.substring(0, 200) + '...'
        })),
        categoryId: req.params.categoryId,
        pagination: {
          total: result.total,
          page: result.page,
          limit: result.limit,
          totalPages: Math.ceil(result.total / result.limit)
        }
      }
    });
  }

  async likeArticle(req: AuthRequest, res: Response): Promise<void> {
    if (!req.user) {
      res.status(401).json({
        success: false,
        error: {
          code: 'UNAUTHORIZED',
          message: 'Authentication required'
        }
      });
      return;
    }

    try {
      const result = await this.likeService.likeArticle(req.user.id, req.params.id);
      
      res.json({
        success: true,
        data: {
          liked: result.liked,
          likeCount: result.likeCount,
          message: result.liked ? 'Article liked successfully' : 'Article already liked'
        }
      });
    } catch (error) {
      this.logger.error('Failed to like article', { 
        userId: req.user.id, 
        articleId: req.params.id, 
        error 
      });
      
      res.status(500).json({
        success: false,
        error: {
          code: 'LIKE_FAILED',
          message: 'Failed to like article'
        }
      });
    }
  }

  async unlikeArticle(req: AuthRequest, res: Response): Promise<void> {
    if (!req.user) {
      res.status(401).json({
        success: false,
        error: {
          code: 'UNAUTHORIZED',
          message: 'Authentication required'
        }
      });
      return;
    }

    try {
      const result = await this.likeService.unlikeArticle(req.user.id, req.params.id);
      
      res.json({
        success: true,
        data: {
          liked: result.liked,
          likeCount: result.likeCount,
          message: !result.liked ? 'Article unliked successfully' : 'Article was not liked'
        }
      });
    } catch (error) {
      this.logger.error('Failed to unlike article', { 
        userId: req.user.id, 
        articleId: req.params.id, 
        error 
      });
      
      res.status(500).json({
        success: false,
        error: {
          code: 'UNLIKE_FAILED',
          message: 'Failed to unlike article'
        }
      });
    }
  }

  async toggleLike(req: AuthRequest, res: Response): Promise<void> {
    if (!req.user) {
      res.status(401).json({
        success: false,
        error: {
          code: 'UNAUTHORIZED',
          message: 'Authentication required'
        }
      });
      return;
    }

    try {
      const result = await this.likeService.toggleLike(req.user.id, req.params.id);
      
      res.json({
        success: true,
        data: {
          liked: result.liked,
          likeCount: result.likeCount,
          message: result.liked ? 'Article liked' : 'Article unliked'
        }
      });
    } catch (error) {
      this.logger.error('Failed to toggle like', { 
        userId: req.user.id, 
        articleId: req.params.id, 
        error 
      });
      
      res.status(500).json({
        success: false,
        error: {
          code: 'TOGGLE_LIKE_FAILED',
          message: 'Failed to toggle like'
        }
      });
    }
  }

  async getLikeStatus(req: AuthRequest, res: Response): Promise<void> {
    if (!req.user) {
      res.status(401).json({
        success: false,
        error: {
          code: 'UNAUTHORIZED',
          message: 'Authentication required'
        }
      });
      return;
    }

    try {
      const result = await this.likeService.getUserLikeStatus(req.user.id, req.params.id);
      
      res.json({
        success: true,
        data: {
          liked: result.liked,
          likeCount: result.likeCount
        }
      });
    } catch (error) {
      this.logger.error('Failed to get like status', { 
        userId: req.user.id, 
        articleId: req.params.id, 
        error 
      });
      
      res.status(500).json({
        success: false,
        error: {
          code: 'GET_LIKE_STATUS_FAILED',
          message: 'Failed to get like status'
        }
      });
    }
  }
}