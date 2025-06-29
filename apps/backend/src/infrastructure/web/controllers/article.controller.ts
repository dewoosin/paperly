// apps/backend/src/infrastructure/web/controllers/article.controller.ts

import { Router, Request, Response, NextFunction } from 'express';
import { injectable, inject } from 'tsyringe';
import { Logger } from '../../logging/Logger';
import { ArticleService, CreateArticleRequest, UpdateArticleRequest, ArticleSearchOptions } from '../../../application/services/article.service';
import { ArticleStatus } from '../../../domain/entities/article.entity';
import { asyncHandler } from '../middlewares/async.middleware';
import { authMiddleware } from '../middlewares/auth.middleware';

interface AuthRequest extends Request {
  user?: {
    id: string;
    email: string;
    roles?: string[];
  };
}

@injectable()
export class ArticleController {
  private readonly logger = new Logger('ArticleController');
  public readonly router = Router();

  constructor(
    @inject('ArticleService') private readonly articleService: ArticleService
  ) {
    this.initializeRoutes();
  }

  private initializeRoutes(): void {
    // 공개 라우트
    this.router.get('/', asyncHandler(this.getArticles.bind(this)));
    this.router.get('/published', asyncHandler(this.getPublishedArticles.bind(this)));
    this.router.get('/featured', asyncHandler(this.getFeaturedArticles.bind(this)));
    this.router.get('/trending', asyncHandler(this.getTrendingArticles.bind(this)));
    this.router.get('/search', asyncHandler(this.searchArticles.bind(this)));
    this.router.get('/slug/:slug', asyncHandler(this.getArticleBySlug.bind(this)));
    this.router.get('/author/:authorId', asyncHandler(this.getArticlesByAuthor.bind(this)));
    this.router.get('/category/:categoryId', asyncHandler(this.getArticlesByCategory.bind(this)));
    this.router.get('/:id', asyncHandler(this.getArticleById.bind(this)));

    // 인증이 필요한 라우트
    this.router.post('/', authMiddleware, asyncHandler(this.createArticle.bind(this)));
    this.router.put('/:id', authMiddleware, asyncHandler(this.updateArticle.bind(this)));
    this.router.patch('/:id/publish', authMiddleware, asyncHandler(this.publishArticle.bind(this)));
    this.router.patch('/:id/unpublish', authMiddleware, asyncHandler(this.unpublishArticle.bind(this)));
    this.router.patch('/:id/archive', authMiddleware, asyncHandler(this.archiveArticle.bind(this)));
    this.router.delete('/:id', authMiddleware, asyncHandler(this.deleteArticle.bind(this)));
    this.router.patch('/:id/restore', authMiddleware, asyncHandler(this.restoreArticle.bind(this)));
    this.router.patch('/:id/feature', authMiddleware, asyncHandler(this.featureArticle.bind(this)));
    this.router.patch('/:id/unfeature', authMiddleware, asyncHandler(this.unfeatureArticle.bind(this)));

    // 공개 인터랙션
    this.router.patch('/:id/like', asyncHandler(this.likeArticle.bind(this)));
    this.router.patch('/:id/share', asyncHandler(this.shareArticle.bind(this)));

    this.logger.info('Article routes initialized');
  }

  async getArticles(req: Request, res: Response): Promise<void> {
    const options: ArticleSearchOptions = {
      page: parseInt(req.query.page as string) || 1,
      limit: parseInt(req.query.limit as string) || 20,
      status: req.query.status as ArticleStatus,
      categoryId: req.query.categoryId as string,
      authorId: req.query.authorId as string,
      featured: req.query.featured === 'true',
      trending: req.query.trending === 'true',
      query: req.query.search as string,
    };

    const result = await this.articleService.getArticles(options);
    res.json(result);
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
    res.json(result);
  }

  async getFeaturedArticles(req: Request, res: Response): Promise<void> {
    const limit = req.query.limit ? parseInt(req.query.limit as string) : 5;
    const articles = await this.articleService.getFeaturedArticles(limit);
    res.json({ articles: articles.map(article => article.toResponse()) });
  }

  async getTrendingArticles(req: Request, res: Response): Promise<void> {
    const limit = req.query.limit ? parseInt(req.query.limit as string) : 10;
    const articles = await this.articleService.getTrendingArticles(limit);
    res.json({ articles: articles.map(article => article.toResponse()) });
  }

  async searchArticles(req: Request, res: Response): Promise<void> {
    const options: Omit<ArticleSearchOptions, 'query'> = {
      page: parseInt(req.query.page as string) || 1,
      limit: parseInt(req.query.limit as string) || 20,
      categoryId: req.query.categoryId as string,
      authorId: req.query.authorId as string,
    };

    const result = await this.articleService.searchArticles(req.query.q as string, options);
    res.json(result);
  }

  async getArticleById(req: Request, res: Response): Promise<void> {
    const article = await this.articleService.getArticleById(req.params.id);
    res.json({ article: article.toResponse() });
  }

  async getArticleBySlug(req: Request, res: Response): Promise<void> {
    const article = await this.articleService.getArticleBySlug(req.params.slug);
    res.json({ article: article.toResponse() });
  }

  async createArticle(req: AuthRequest, res: Response): Promise<void> {
    if (!req.user) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const createArticleDto: CreateArticleRequest = req.body;
    const article = await this.articleService.createArticle(createArticleDto, req.user.id);
    res.status(201).json({ article: article.toResponse() });
  }

  async updateArticle(req: AuthRequest, res: Response): Promise<void> {
    if (!req.user) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const updateArticleDto: UpdateArticleRequest = req.body;
    const article = await this.articleService.updateArticle(req.params.id, updateArticleDto, req.user.id);
    res.json({ article: article.toResponse() });
  }

  async publishArticle(req: AuthRequest, res: Response): Promise<void> {
    if (!req.user) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const article = await this.articleService.publishArticle(req.params.id, req.user.id);
    res.json({ article: article.toResponse() });
  }

  async unpublishArticle(req: AuthRequest, res: Response): Promise<void> {
    if (!req.user) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const article = await this.articleService.unpublishArticle(req.params.id, req.user.id);
    res.json({ article: article.toResponse() });
  }

  async archiveArticle(req: AuthRequest, res: Response): Promise<void> {
    if (!req.user) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const article = await this.articleService.archiveArticle(req.params.id, req.user.id);
    res.json({ article: article.toResponse() });
  }

  async deleteArticle(req: AuthRequest, res: Response): Promise<void> {
    if (!req.user) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    await this.articleService.deleteArticle(req.params.id, req.user.id);
    res.status(204).send();
  }

  async restoreArticle(req: AuthRequest, res: Response): Promise<void> {
    if (!req.user) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const article = await this.articleService.restoreArticle(req.params.id, req.user.id);
    res.json({ article: article.toResponse() });
  }

  async featureArticle(req: AuthRequest, res: Response): Promise<void> {
    if (!req.user) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const article = await this.articleService.featureArticle(req.params.id, req.user.id);
    res.json({ article: article.toResponse() });
  }

  async unfeatureArticle(req: AuthRequest, res: Response): Promise<void> {
    if (!req.user) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const article = await this.articleService.unfeatureArticle(req.params.id, req.user.id);
    res.json({ article: article.toResponse() });
  }

  async likeArticle(req: Request, res: Response): Promise<void> {
    const article = await this.articleService.likeArticle(req.params.id);
    res.json({ article: article.toResponse() });
  }

  async shareArticle(req: Request, res: Response): Promise<void> {
    const article = await this.articleService.shareArticle(req.params.id);
    res.json({ article: article.toResponse() });
  }

  async getArticlesByAuthor(req: Request, res: Response): Promise<void> {
    const options: Omit<ArticleSearchOptions, 'authorId'> = {
      page: parseInt(req.query.page as string) || 1,
      limit: parseInt(req.query.limit as string) || 20,
      status: req.query.status as ArticleStatus,
      categoryId: req.query.categoryId as string,
      featured: req.query.featured === 'true',
      trending: req.query.trending === 'true',
      query: req.query.search as string,
    };

    const result = await this.articleService.getArticlesByAuthor(req.params.authorId, options);
    res.json(result);
  }

  async getArticlesByCategory(req: Request, res: Response): Promise<void> {
    const options: Omit<ArticleSearchOptions, 'categoryId'> = {
      page: parseInt(req.query.page as string) || 1,
      limit: parseInt(req.query.limit as string) || 20,
      status: req.query.status as ArticleStatus,
      authorId: req.query.authorId as string,
      featured: req.query.featured === 'true',
      trending: req.query.trending === 'true',
      query: req.query.search as string,
    };

    const result = await this.articleService.getArticlesByCategory(req.params.categoryId, options);
    res.json(result);
  }
}