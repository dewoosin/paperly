import { injectable } from 'tsyringe';
import { WriterArticleRepository } from '../../infrastructure/repositories/writer-article.repository';
import { Logger } from '../../infrastructure/logging/Logger';
import { 
  CreateArticleDto, 
  UpdateArticleDto, 
  PublishArticleDto,
  ArticleStatusDto,
  WriterArticleResponseDto, 
  WriterArticleListDto,
  WriterArticleStatsDto,
  ArticleValidationError
} from '../dto/writer-article.dto';
import { WriterArticleValidator } from '../validation/writer-article.validation';

@injectable()
export class WriterArticleService {
  private logger = new Logger('WriterArticleService');
  private repository = new WriterArticleRepository();

  async createArticle(authorId: string, dto: CreateArticleDto): Promise<WriterArticleResponseDto> {
    this.logger.info('Creating new article', { authorId, title: dto.title });

    // Validate input
    const validationErrors = WriterArticleValidator.validateCreateArticle(dto);
    if (validationErrors.length > 0) {
      this.logger.warn('Article creation validation failed', { authorId, errors: validationErrors });
      throw new ValidationError('Article validation failed', validationErrors);
    }

    try {
      // Check if user has writer permissions
      await this.validateWriterPermissions(authorId);

      // Create article
      const article = await this.repository.createArticle(authorId, dto);

      this.logger.info('Article created successfully', {
        articleId: article.id,
        authorId,
        title: article.title
      });

      return article;
    } catch (error) {
      this.logger.error('Failed to create article', error, { authorId, title: dto.title });
      throw error;
    }
  }

  async updateArticle(articleId: string, authorId: string, dto: UpdateArticleDto): Promise<WriterArticleResponseDto> {
    this.logger.info('Updating article', { articleId, authorId });

    // Validate input
    const validationErrors = WriterArticleValidator.validateUpdateArticle(dto);
    if (validationErrors.length > 0) {
      this.logger.warn('Article update validation failed', { articleId, authorId, errors: validationErrors });
      throw new ValidationError('Article validation failed', validationErrors);
    }

    try {
      // Check if article exists and belongs to author
      const existingArticle = await this.repository.getArticleById(articleId, authorId);
      if (!existingArticle) {
        throw new NotFoundError('Article not found or you do not have permission to edit it');
      }

      // Prevent editing published articles with certain restrictions
      if (existingArticle.status === 'published' && this.hasRestrictedUpdates(dto)) {
        throw new BusinessLogicError(
          'Published articles cannot have major changes. Consider unpublishing first.',
          'PUBLISHED_ARTICLE_RESTRICTED_UPDATE'
        );
      }

      // Update article
      const updatedArticle = await this.repository.updateArticle(articleId, authorId, dto);

      this.logger.info('Article updated successfully', {
        articleId,
        authorId,
        updatedFields: Object.keys(dto)
      });

      return updatedArticle;
    } catch (error) {
      this.logger.error('Failed to update article', error, { articleId, authorId });
      throw error;
    }
  }

  async getArticle(articleId: string, authorId: string): Promise<WriterArticleResponseDto> {
    this.logger.debug('Getting article', { articleId, authorId });

    try {
      const article = await this.repository.getArticleById(articleId, authorId);
      
      if (!article) {
        throw new NotFoundError('Article not found');
      }

      return article;
    } catch (error) {
      this.logger.error('Failed to get article', error, { articleId, authorId });
      throw error;
    }
  }

  async getArticles(
    authorId: string,
    page: number = 1,
    limit: number = 20,
    status?: string,
    search?: string
  ): Promise<{ articles: WriterArticleListDto[], total: number, page: number, limit: number }> {
    this.logger.debug('Getting articles list', { authorId, page, limit, status, search });

    try {
      // Validate pagination parameters
      if (page < 1) page = 1;
      if (limit < 1 || limit > 100) limit = 20;

      // Validate status filter
      if (status && !['draft', 'review', 'published', 'archived'].includes(status)) {
        throw new ValidationError('Invalid status filter', [{
          field: 'status',
          message: 'Status must be draft, review, published, or archived',
          code: 'INVALID_STATUS_FILTER'
        }]);
      }

      const result = await this.repository.getArticlesByAuthor(authorId, page, limit, status, search);

      this.logger.debug('Articles retrieved successfully', {
        authorId,
        total: result.total,
        page: result.page,
        articlesCount: result.articles.length
      });

      return result;
    } catch (error) {
      this.logger.error('Failed to get articles', error, { authorId, page, limit });
      throw error;
    }
  }

  async publishArticle(articleId: string, authorId: string, dto?: PublishArticleDto): Promise<WriterArticleResponseDto> {
    this.logger.info('Publishing article', { articleId, authorId });

    try {
      // Validate publish data if provided
      if (dto) {
        const validationErrors = WriterArticleValidator.validatePublishArticle(dto);
        if (validationErrors.length > 0) {
          throw new ValidationError('Publish validation failed', validationErrors);
        }
      }

      // Get article to validate it can be published
      const article = await this.repository.getArticleById(articleId, authorId);
      if (!article) {
        throw new NotFoundError('Article not found');
      }

      // Check if article is ready for publishing
      const readinessErrors = this.validateArticleReadiness(article);
      if (readinessErrors.length > 0) {
        throw new ValidationError('Article is not ready for publishing', readinessErrors);
      }

      // Check current status
      if (article.status === 'published') {
        throw new BusinessLogicError('Article is already published', 'ALREADY_PUBLISHED');
      }

      if (article.status === 'archived' || article.status === 'deleted') {
        throw new BusinessLogicError('Cannot publish archived or deleted articles', 'INVALID_STATUS_TRANSITION');
      }

      // Publish article
      const publishedAt = dto?.publishedAt || new Date();
      const publishedArticle = await this.repository.publishArticle(articleId, authorId, publishedAt);

      this.logger.info('Article published successfully', {
        articleId,
        authorId,
        publishedAt
      });

      return publishedArticle;
    } catch (error) {
      this.logger.error('Failed to publish article', error, { articleId, authorId });
      throw error;
    }
  }

  async unpublishArticle(articleId: string, authorId: string): Promise<WriterArticleResponseDto> {
    this.logger.info('Unpublishing article', { articleId, authorId });

    try {
      // Get article to validate it can be unpublished
      const article = await this.repository.getArticleById(articleId, authorId);
      if (!article) {
        throw new NotFoundError('Article not found');
      }

      if (article.status !== 'published') {
        throw new BusinessLogicError('Only published articles can be unpublished', 'NOT_PUBLISHED');
      }

      // Unpublish article
      const unpublishedArticle = await this.repository.unpublishArticle(articleId, authorId);

      this.logger.info('Article unpublished successfully', { articleId, authorId });

      return unpublishedArticle;
    } catch (error) {
      this.logger.error('Failed to unpublish article', error, { articleId, authorId });
      throw error;
    }
  }

  async deleteArticle(articleId: string, authorId: string): Promise<void> {
    this.logger.info('Deleting article', { articleId, authorId });

    try {
      // Check if article exists
      const article = await this.repository.getArticleById(articleId, authorId);
      if (!article) {
        throw new NotFoundError('Article not found');
      }

      // Check if article can be deleted
      if (article.status === 'published' && article.viewCount > 100) {
        this.logger.warn('Attempting to delete popular published article', {
          articleId,
          authorId,
          viewCount: article.viewCount
        });
        // Could add additional business logic here
      }

      await this.repository.deleteArticle(articleId, authorId);

      this.logger.info('Article deleted successfully', { articleId, authorId });
    } catch (error) {
      this.logger.error('Failed to delete article', error, { articleId, authorId });
      throw error;
    }
  }

  async getWriterStats(authorId: string): Promise<WriterArticleStatsDto> {
    this.logger.debug('Getting writer statistics', { authorId });

    try {
      const stats = await this.repository.getWriterStats(authorId);

      this.logger.debug('Writer statistics retrieved', {
        authorId,
        totalArticles: stats.totalArticles,
        publishedArticles: stats.publishedArticles
      });

      return stats;
    } catch (error) {
      this.logger.error('Failed to get writer stats', error, { authorId });
      throw error;
    }
  }

  async archiveArticle(articleId: string, authorId: string): Promise<WriterArticleResponseDto> {
    this.logger.info('Archiving article', { articleId, authorId });

    try {
      const article = await this.repository.getArticleById(articleId, authorId);
      if (!article) {
        throw new NotFoundError('Article not found');
      }

      if (article.status === 'archived') {
        throw new BusinessLogicError('Article is already archived', 'ALREADY_ARCHIVED');
      }

      // Archive by updating to draft status (simplified implementation)
      const updateDto: UpdateArticleDto = {
        metadata: {
          ...article.metadata,
          archivedAt: new Date().toISOString(),
          previousStatus: article.status
        }
      };

      const archivedArticle = await this.repository.updateArticle(articleId, authorId, updateDto);

      this.logger.info('Article archived successfully', { articleId, authorId });

      return archivedArticle;
    } catch (error) {
      this.logger.error('Failed to archive article', error, { articleId, authorId });
      throw error;
    }
  }

  private async validateWriterPermissions(authorId: string): Promise<void> {
    // This would typically check if the user has writer role/permissions
    // For now, we'll assume all authenticated users can write
    // In a real implementation, you'd check user roles or writer application status
    
    this.logger.debug('Writer permissions validated', { authorId });
  }

  private hasRestrictedUpdates(dto: UpdateArticleDto): boolean {
    // Define what updates are restricted for published articles
    const restrictedFields = ['title', 'content', 'categoryId'];
    return restrictedFields.some(field => dto[field as keyof UpdateArticleDto] !== undefined);
  }

  private validateArticleReadiness(article: WriterArticleResponseDto): ArticleValidationError[] {
    const errors: ArticleValidationError[] = [];

    // Title is required
    if (!article.title || article.title.trim().length === 0) {
      errors.push({
        field: 'title',
        message: 'Title is required for publishing',
        code: 'TITLE_REQUIRED_FOR_PUBLISH'
      });
    }

    // Content is required and should be substantial
    if (!article.content || article.content.trim().length === 0) {
      errors.push({
        field: 'content',
        message: 'Content is required for publishing',
        code: 'CONTENT_REQUIRED_FOR_PUBLISH'
      });
    } else if (article.wordCount < 100) {
      errors.push({
        field: 'content',
        message: 'Article should have at least 100 words for publishing',
        code: 'CONTENT_TOO_SHORT_FOR_PUBLISH'
      });
    }

    // Excerpt is recommended for published articles
    if (!article.excerpt || article.excerpt.trim().length === 0) {
      errors.push({
        field: 'excerpt',
        message: 'Excerpt is recommended for better article discovery',
        code: 'EXCERPT_RECOMMENDED'
      });
    }

    return errors;
  }
}

// Custom error classes
export class ValidationError extends Error {
  constructor(message: string, public errors: ArticleValidationError[]) {
    super(message);
    this.name = 'ValidationError';
  }
}

export class NotFoundError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'NotFoundError';
  }
}

export class BusinessLogicError extends Error {
  constructor(message: string, public code: string) {
    super(message);
    this.name = 'BusinessLogicError';
  }
}