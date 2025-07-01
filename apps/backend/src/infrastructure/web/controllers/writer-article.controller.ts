import { Request, Response, NextFunction, Router } from 'express';
import { container } from 'tsyringe';
import { Logger } from '../../logging/Logger';
import { WriterArticleService, ValidationError, NotFoundError, BusinessLogicError } from '../../../application/services/writer-article.service';
import { 
  CreateArticleDto, 
  UpdateArticleDto, 
  PublishArticleDto,
  ArticleStatusDto
} from '../../../application/dto/writer-article.dto';
import { authMiddleware } from '../middleware/auth.middleware';
import { createApiError } from '../middleware/error-handler.middleware';

interface AuthenticatedRequest extends Request {
  user?: {
    userId: string;
    email: string;
    role?: string;
  };
}

export class WriterArticleController {
  private logger = new Logger('WriterArticleController');
  private service: WriterArticleService;
  public router: Router;

  constructor() {
    this.service = container.resolve(WriterArticleService);
    this.router = Router();
    this.setupRoutes();
  }

  private setupRoutes(): void {
    // All routes require authentication
    this.router.use(authMiddleware());

    // Article CRUD operations
    this.router.post('/', this.createArticle.bind(this));
    this.router.get('/', this.getArticles.bind(this));
    this.router.get('/stats', this.getWriterStats.bind(this));
    this.router.get('/:id', this.getArticle.bind(this));
    this.router.put('/:id', this.updateArticle.bind(this));
    this.router.delete('/:id', this.deleteArticle.bind(this));

    // Article status operations
    this.router.post('/:id/publish', this.publishArticle.bind(this));
    this.router.post('/:id/unpublish', this.unpublishArticle.bind(this));
    this.router.post('/:id/archive', this.archiveArticle.bind(this));

    this.logger.info('Writer article routes initialized');
  }

  async createArticle(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const authorId = req.user?.userId;
      if (!authorId) {
        throw createApiError('Authentication required')
          .withStatusCode(401)
          .withCode('AUTHENTICATION_REQUIRED')
          .build();
      }

      const dto: CreateArticleDto = req.body;

      this.logger.info('Creating article request', {
        authorId,
        title: dto.title,
        contentLength: dto.content?.length || 0
      });

      const article = await this.service.createArticle(authorId, dto);

      res.status(201).json({
        success: true,
        data: article,
        message: 'Article created successfully'
      });

      this.logger.info('Article created successfully', {
        articleId: article.id,
        authorId,
        title: article.title
      });
    } catch (error) {
      this.handleError(error, req, res, next);
    }
  }

  async updateArticle(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const authorId = req.user?.userId;
      const articleId = req.params.id;

      if (!authorId) {
        throw createApiError('Authentication required')
          .withStatusCode(401)
          .withCode('AUTHENTICATION_REQUIRED')
          .build();
      }

      if (!articleId) {
        throw createApiError('Article ID is required')
          .withStatusCode(400)
          .withCode('ARTICLE_ID_REQUIRED')
          .build();
      }

      const dto: UpdateArticleDto = req.body;

      this.logger.info('Updating article request', {
        articleId,
        authorId,
        updatedFields: Object.keys(dto)
      });

      const article = await this.service.updateArticle(articleId, authorId, dto);

      res.json({
        success: true,
        data: article,
        message: 'Article updated successfully'
      });

      this.logger.info('Article updated successfully', {
        articleId,
        authorId
      });
    } catch (error) {
      this.handleError(error, req, res, next);
    }
  }

  async getArticle(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const authorId = req.user?.userId;
      const articleId = req.params.id;

      if (!authorId) {
        throw createApiError('Authentication required')
          .withStatusCode(401)
          .withCode('AUTHENTICATION_REQUIRED')
          .build();
      }

      if (!articleId) {
        throw createApiError('Article ID is required')
          .withStatusCode(400)
          .withCode('ARTICLE_ID_REQUIRED')
          .build();
      }

      const article = await this.service.getArticle(articleId, authorId);

      res.json({
        success: true,
        data: article,
        message: 'Article retrieved successfully'
      });
    } catch (error) {
      this.handleError(error, req, res, next);
    }
  }

  async getArticles(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const authorId = req.user?.userId;

      if (!authorId) {
        throw createApiError('Authentication required')
          .withStatusCode(401)
          .withCode('AUTHENTICATION_REQUIRED')
          .build();
      }

      // Parse query parameters
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 20;
      const status = req.query.status as string;
      const search = req.query.search as string;

      this.logger.debug('Getting articles request', {
        authorId,
        page,
        limit,
        status,
        search
      });

      const result = await this.service.getArticles(authorId, page, limit, status, search);

      res.json({
        success: true,
        data: result.articles,
        pagination: {
          page: result.page,
          limit: result.limit,
          total: result.total,
          totalPages: Math.ceil(result.total / result.limit)
        },
        message: 'Articles retrieved successfully'
      });
    } catch (error) {
      this.handleError(error, req, res, next);
    }
  }

  async publishArticle(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const authorId = req.user?.userId;
      const articleId = req.params.id;

      if (!authorId) {
        throw createApiError('Authentication required')
          .withStatusCode(401)
          .withCode('AUTHENTICATION_REQUIRED')
          .build();
      }

      if (!articleId) {
        throw createApiError('Article ID is required')
          .withStatusCode(400)
          .withCode('ARTICLE_ID_REQUIRED')
          .build();
      }

      const dto: PublishArticleDto = req.body;

      this.logger.info('Publishing article request', {
        articleId,
        authorId,
        publishedAt: dto.publishedAt
      });

      const article = await this.service.publishArticle(articleId, authorId, dto);

      res.json({
        success: true,
        data: article,
        message: 'Article published successfully'
      });

      this.logger.info('Article published successfully', {
        articleId,
        authorId,
        publishedAt: article.publishedAt
      });
    } catch (error) {
      this.handleError(error, req, res, next);
    }
  }

  async unpublishArticle(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const authorId = req.user?.userId;
      const articleId = req.params.id;

      if (!authorId) {
        throw createApiError('Authentication required')
          .withStatusCode(401)
          .withCode('AUTHENTICATION_REQUIRED')
          .build();
      }

      if (!articleId) {
        throw createApiError('Article ID is required')
          .withStatusCode(400)
          .withCode('ARTICLE_ID_REQUIRED')
          .build();
      }

      this.logger.info('Unpublishing article request', {
        articleId,
        authorId
      });

      const article = await this.service.unpublishArticle(articleId, authorId);

      res.json({
        success: true,
        data: article,
        message: 'Article unpublished successfully'
      });

      this.logger.info('Article unpublished successfully', {
        articleId,
        authorId
      });
    } catch (error) {
      this.handleError(error, req, res, next);
    }
  }

  async deleteArticle(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const authorId = req.user?.userId;
      const articleId = req.params.id;

      if (!authorId) {
        throw createApiError('Authentication required')
          .withStatusCode(401)
          .withCode('AUTHENTICATION_REQUIRED')
          .build();
      }

      if (!articleId) {
        throw createApiError('Article ID is required')
          .withStatusCode(400)
          .withCode('ARTICLE_ID_REQUIRED')
          .build();
      }

      this.logger.info('Deleting article request', {
        articleId,
        authorId
      });

      await this.service.deleteArticle(articleId, authorId);

      res.json({
        success: true,
        message: 'Article deleted successfully'
      });

      this.logger.info('Article deleted successfully', {
        articleId,
        authorId
      });
    } catch (error) {
      this.handleError(error, req, res, next);
    }
  }

  async archiveArticle(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const authorId = req.user?.userId;
      const articleId = req.params.id;

      if (!authorId) {
        throw createApiError('Authentication required')
          .withStatusCode(401)
          .withCode('AUTHENTICATION_REQUIRED')
          .build();
      }

      if (!articleId) {
        throw createApiError('Article ID is required')
          .withStatusCode(400)
          .withCode('ARTICLE_ID_REQUIRED')
          .build();
      }

      this.logger.info('Archiving article request', {
        articleId,
        authorId
      });

      const article = await this.service.archiveArticle(articleId, authorId);

      res.json({
        success: true,
        data: article,
        message: 'Article archived successfully'
      });

      this.logger.info('Article archived successfully', {
        articleId,
        authorId
      });
    } catch (error) {
      this.handleError(error, req, res, next);
    }
  }

  async getWriterStats(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const authorId = req.user?.userId;

      if (!authorId) {
        throw createApiError('Authentication required')
          .withStatusCode(401)
          .withCode('AUTHENTICATION_REQUIRED')
          .build();
      }

      this.logger.debug('Getting writer stats request', { authorId });

      const stats = await this.service.getWriterStats(authorId);

      res.json({
        success: true,
        data: stats,
        message: 'Writer statistics retrieved successfully'
      });
    } catch (error) {
      this.handleError(error, req, res, next);
    }
  }

  private handleError(error: any, req: AuthenticatedRequest, res: Response, next: NextFunction): void {
    if (error instanceof ValidationError) {
      const apiError = createApiError('Validation failed')
        .withStatusCode(400)
        .withCode('VALIDATION_ERROR')
        .withDetails({
          validationErrors: error.errors
        })
        .build();

      this.logger.warn('Validation error in writer article controller', {
        authorId: req.user?.userId,
        path: req.path,
        method: req.method,
        errors: error.errors
      });

      return next(apiError);
    }

    if (error instanceof NotFoundError) {
      const apiError = createApiError(error.message)
        .withStatusCode(404)
        .withCode('NOT_FOUND')
        .build();

      this.logger.warn('Not found error in writer article controller', {
        authorId: req.user?.userId,
        path: req.path,
        method: req.method,
        message: error.message
      });

      return next(apiError);
    }

    if (error instanceof BusinessLogicError) {
      const apiError = createApiError(error.message)
        .withStatusCode(409)
        .withCode(error.code)
        .build();

      this.logger.warn('Business logic error in writer article controller', {
        authorId: req.user?.userId,
        path: req.path,
        method: req.method,
        message: error.message,
        code: error.code
      });

      return next(apiError);
    }

    // Handle database errors
    if (error.code === '23505') { // Unique constraint violation
      const apiError = createApiError('Article with this title already exists')
        .withStatusCode(409)
        .withCode('DUPLICATE_ARTICLE')
        .build();

      this.logger.warn('Duplicate article error', {
        authorId: req.user?.userId,
        path: req.path,
        method: req.method,
        error: error.message
      });

      return next(apiError);
    }

    if (error.code === '23503') { // Foreign key constraint violation
      const apiError = createApiError('Referenced resource does not exist')
        .withStatusCode(400)
        .withCode('INVALID_REFERENCE')
        .build();

      this.logger.warn('Foreign key constraint error', {
        authorId: req.user?.userId,
        path: req.path,
        method: req.method,
        error: error.message
      });

      return next(apiError);
    }

    // Handle unexpected errors
    const apiError = createApiError('An unexpected error occurred')
      .withStatusCode(500)
      .withCode('INTERNAL_SERVER_ERROR')
      .withDetails(process.env.NODE_ENV === 'development' ? { originalError: error.message } : undefined)
      .build();

    this.logger.error('Unexpected error in writer article controller', error, {
      authorId: req.user?.userId,
      path: req.path,
      method: req.method
    });

    next(apiError);
  }
}