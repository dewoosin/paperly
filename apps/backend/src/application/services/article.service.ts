// /Users/workspace/paperly/apps/backend/src/application/services/article.service.ts

import { injectable, inject } from 'tsyringe';
import { Article, CreateArticleProps, UpdateArticleProps, ArticleStatus, ArticleVisibility } from '../../domain/entities/article.entity';
import { ArticleRepository } from '../../infrastructure/repositories/article.repository';

export interface CreateArticleRequest {
  title: string;
  slug?: string;
  subtitle?: string;
  excerpt?: string;
  content: string;
  contentHtml?: string;
  featuredImageUrl?: string;
  featuredImageAlt?: string;
  categoryId?: string;
  tagIds?: string[];
  status?: ArticleStatus;
  visibility?: ArticleVisibility;
  seoTitle?: string;
  seoDescription?: string;
  scheduledAt?: Date;
  metadata?: any;
}

export interface UpdateArticleRequest {
  title?: string;
  slug?: string;
  subtitle?: string;
  excerpt?: string;
  content?: string;
  contentHtml?: string;
  featuredImageUrl?: string;
  featuredImageAlt?: string;
  categoryId?: string;
  tagIds?: string[];
  status?: ArticleStatus;
  visibility?: ArticleVisibility;
  seoTitle?: string;
  seoDescription?: string;
  scheduledAt?: Date;
  metadata?: any;
}

export interface ArticleSearchOptions {
  page?: number;
  limit?: number;
  status?: ArticleStatus;
  categoryId?: string;
  authorId?: string;
  featured?: boolean;
  trending?: boolean;
  query?: string;
}

export class NotFoundException extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'NotFoundException';
  }
}

export class ForbiddenException extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ForbiddenException';
  }
}

@injectable()
export class ArticleService {
  constructor(
    @inject('ArticleRepository') private readonly articleRepository: ArticleRepository,
  ) {}

  async createArticle(request: CreateArticleRequest, authorId: string): Promise<Article> {
    const props: CreateArticleProps = {
      ...request,
      authorId,
    };

    const article = Article.create(props);
    return this.articleRepository.save(article);
  }

  async updateArticle(
    id: string, 
    request: UpdateArticleRequest, 
    userId: string
  ): Promise<Article> {
    const article = await this.articleRepository.findById(id);
    if (!article) {
      throw new NotFoundException('기사를 찾을 수 없습니다.');
    }

    if (!article.canBeEditedBy(userId)) {
      throw new ForbiddenException('이 기사를 편집할 권한이 없습니다.');
    }

    const props: UpdateArticleProps = {
      ...request,
      editorId: userId,
    };

    article.update(props);
    return this.articleRepository.save(article);
  }

  async publishArticle(id: string, userId: string): Promise<Article> {
    const article = await this.articleRepository.findById(id);
    if (!article) {
      throw new NotFoundException('기사를 찾을 수 없습니다.');
    }

    if (!article.canBeEditedBy(userId)) {
      throw new ForbiddenException('이 기사를 발행할 권한이 없습니다.');
    }

    if (!article.canBePublished()) {
      throw new ForbiddenException('이 기사는 발행할 수 없는 상태입니다.');
    }

    article.publish();
    return this.articleRepository.save(article);
  }

  async unpublishArticle(id: string, userId: string): Promise<Article> {
    const article = await this.articleRepository.findById(id);
    if (!article) {
      throw new NotFoundException('기사를 찾을 수 없습니다.');
    }

    if (!article.canBeEditedBy(userId)) {
      throw new ForbiddenException('이 기사의 발행을 취소할 권한이 없습니다.');
    }

    article.unpublish();
    return this.articleRepository.save(article);
  }

  async archiveArticle(id: string, userId: string): Promise<Article> {
    const article = await this.articleRepository.findById(id);
    if (!article) {
      throw new NotFoundException('기사를 찾을 수 없습니다.');
    }

    if (!article.canBeEditedBy(userId)) {
      throw new ForbiddenException('이 기사를 보관할 권한이 없습니다.');
    }

    article.archive();
    return this.articleRepository.save(article);
  }

  async deleteArticle(id: string, userId: string): Promise<void> {
    const article = await this.articleRepository.findById(id);
    if (!article) {
      throw new NotFoundException('기사를 찾을 수 없습니다.');
    }

    if (!article.canBeEditedBy(userId)) {
      throw new ForbiddenException('이 기사를 삭제할 권한이 없습니다.');
    }

    article.softDelete();
    await this.articleRepository.save(article);
  }

  async restoreArticle(id: string, userId: string): Promise<Article> {
    const article = await this.articleRepository.findById(id);
    if (!article) {
      throw new NotFoundException('기사를 찾을 수 없습니다.');
    }

    if (!article.canBeEditedBy(userId)) {
      throw new ForbiddenException('이 기사를 복원할 권한이 없습니다.');
    }

    article.restore();
    return this.articleRepository.save(article);
  }

  async featureArticle(id: string, userId: string): Promise<Article> {
    const article = await this.articleRepository.findById(id);
    if (!article) {
      throw new NotFoundException('기사를 찾을 수 없습니다.');
    }

    article.feature();
    return this.articleRepository.save(article);
  }

  async unfeatureArticle(id: string, userId: string): Promise<Article> {
    const article = await this.articleRepository.findById(id);
    if (!article) {
      throw new NotFoundException('기사를 찾을 수 없습니다.');
    }

    article.unfeature();
    return this.articleRepository.save(article);
  }

  async getArticleById(id: string): Promise<Article> {
    const article = await this.articleRepository.findById(id);
    if (!article) {
      throw new NotFoundException('기사를 찾을 수 없습니다.');
    }
    return article;
  }

  async getArticleBySlug(slug: string): Promise<Article> {
    const article = await this.articleRepository.findBySlug(slug);
    if (!article) {
      throw new NotFoundException('기사를 찾을 수 없습니다.');
    }

    // Increment view count for published articles
    if (article.isPublished()) {
      article.incrementViewCount();
      await this.articleRepository.save(article);
    }

    return article;
  }

  async getArticles(options: ArticleSearchOptions = {}): Promise<{
    articles: Article[];
    total: number;
    page: number;
    limit: number;
  }> {
    const page = options.page || 1;
    const limit = options.limit || 20;
    const skip = (page - 1) * limit;

    let articles: Article[];
    let total: number;

    if (options.query) {
      articles = await this.articleRepository.search(options.query, { 
        take: limit, 
        skip 
      });
      total = await this.articleRepository.count();
    } else if (options.featured) {
      articles = await this.articleRepository.findFeatured({ 
        take: limit, 
        skip 
      });
      total = await this.articleRepository.count({ isFeatured: true });
    } else if (options.trending) {
      articles = await this.articleRepository.findTrending({ 
        take: limit, 
        skip 
      });
      total = await this.articleRepository.count({ isTrending: true });
    } else if (options.status) {
      articles = await this.articleRepository.findByStatus(options.status, { 
        take: limit, 
        skip 
      });
      total = await this.articleRepository.count({ status: options.status });
    } else if (options.authorId) {
      articles = await this.articleRepository.findByAuthor(options.authorId, { 
        take: limit, 
        skip 
      });
      total = await this.articleRepository.count({ authorId: options.authorId });
    } else if (options.categoryId) {
      articles = await this.articleRepository.findByCategory(options.categoryId, { 
        take: limit, 
        skip 
      });
      total = await this.articleRepository.count({ categoryId: options.categoryId });
    } else {
      articles = await this.articleRepository.findMany({ 
        take: limit, 
        skip 
      });
      total = await this.articleRepository.count();
    }

    return {
      articles,
      total,
      page,
      limit,
    };
  }

  async getPublishedArticles(options: Omit<ArticleSearchOptions, 'status'> = {}): Promise<{
    articles: Article[];
    total: number;
    page: number;
    limit: number;
  }> {
    return this.getArticles({ ...options, status: ArticleStatus.PUBLISHED });
  }

  async getFeaturedArticles(limit: number = 5): Promise<Article[]> {
    return this.articleRepository.findFeatured({ take: limit });
  }

  async getTrendingArticles(limit: number = 10): Promise<Article[]> {
    return this.articleRepository.findTrending({ take: limit });
  }

  async getArticlesByAuthor(authorId: string, options: Omit<ArticleSearchOptions, 'authorId'> = {}): Promise<{
    articles: Article[];
    total: number;
    page: number;
    limit: number;
  }> {
    return this.getArticles({ ...options, authorId });
  }

  async getArticlesByCategory(categoryId: string, options: Omit<ArticleSearchOptions, 'categoryId'> = {}): Promise<{
    articles: Article[];
    total: number;
    page: number;
    limit: number;
  }> {
    return this.getArticles({ ...options, categoryId });
  }

  async searchArticles(query: string, options: Omit<ArticleSearchOptions, 'query'> = {}): Promise<{
    articles: Article[];
    total: number;
    page: number;
    limit: number;
  }> {
    return this.getArticles({ ...options, query });
  }

  async likeArticle(id: string): Promise<Article> {
    const article = await this.articleRepository.findById(id);
    if (!article) {
      throw new NotFoundException('기사를 찾을 수 없습니다.');
    }

    article.incrementLikeCount();
    return this.articleRepository.save(article);
  }

  async shareArticle(id: string): Promise<Article> {
    const article = await this.articleRepository.findById(id);
    if (!article) {
      throw new NotFoundException('기사를 찾을 수 없습니다.');
    }

    article.incrementShareCount();
    return this.articleRepository.save(article);
  }
}