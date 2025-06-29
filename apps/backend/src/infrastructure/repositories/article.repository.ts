// /Users/workspace/paperly/apps/backend/src/infrastructure/repositories/article.repository.ts

import { injectable, inject } from 'tsyringe';
import { Repository, FindOptionsWhere, FindManyOptions, EntityManager } from 'typeorm';
import { Article, ArticleStatus, ArticleVisibility } from '../../domain/entities/article.entity';
import { ArticleEntity } from '../entities/article.entity';

export interface ArticleRepository {
  findById(id: string): Promise<Article | null>;
  findBySlug(slug: string): Promise<Article | null>;
  findMany(options?: FindManyOptions<ArticleEntity>): Promise<Article[]>;
  findByAuthor(authorId: string, options?: Partial<FindManyOptions<ArticleEntity>>): Promise<Article[]>;
  findByCategory(categoryId: string, options?: Partial<FindManyOptions<ArticleEntity>>): Promise<Article[]>;
  findByStatus(status: ArticleStatus, options?: Partial<FindManyOptions<ArticleEntity>>): Promise<Article[]>;
  findPublished(options?: Partial<FindManyOptions<ArticleEntity>>): Promise<Article[]>;
  findFeatured(options?: Partial<FindManyOptions<ArticleEntity>>): Promise<Article[]>;
  findTrending(options?: Partial<FindManyOptions<ArticleEntity>>): Promise<Article[]>;
  search(query: string, options?: Partial<FindManyOptions<ArticleEntity>>): Promise<Article[]>;
  save(article: Article): Promise<Article>;
  update(id: string, data: Partial<Article>): Promise<Article>;
  delete(id: string): Promise<void>;
  count(where?: FindOptionsWhere<ArticleEntity>): Promise<number>;
  findWithPagination(options: {
    page: number;
    limit: number;
    status?: string;
    categoryId?: string;
    authorId?: string;
    search?: string;
  }): Promise<{
    items: Article[];
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  }>;
  syncTags(articleId: string, tagIds: string[]): Promise<void>;
}

@injectable()
export class TypeOrmArticleRepository implements ArticleRepository {
  constructor(
    @inject('Database') private readonly db: any,
  ) {}

  private get repository(): Repository<ArticleEntity> {
    return this.db.getRepository(ArticleEntity);
  }

  private get entityManager(): EntityManager {
    return this.db.manager;
  }

  async findById(id: string): Promise<Article | null> {
    const entity = await this.repository.findOne({
      where: { id },
      relations: ['category', 'tags', 'author'],
    });

    return entity ? this.toDomain(entity) : null;
  }

  async findBySlug(slug: string): Promise<Article | null> {
    const entity = await this.repository.findOne({
      where: { slug },
      relations: ['category', 'tags', 'author'],
    });

    return entity ? this.toDomain(entity) : null;
  }

  async findMany(options: FindManyOptions<ArticleEntity> = {}): Promise<Article[]> {
    const defaultOptions: FindManyOptions<ArticleEntity> = {
      relations: ['category', 'tags', 'author'],
      order: { createdAt: 'DESC' },
      take: 20,
      ...options,
    };

    const entities = await this.repository.find(defaultOptions);
    return entities.map(entity => this.toDomain(entity));
  }

  async findByAuthor(
    authorId: string, 
    options: Partial<FindManyOptions<ArticleEntity>> = {}
  ): Promise<Article[]> {
    const findOptions: FindManyOptions<ArticleEntity> = {
      where: { authorId },
      relations: ['category', 'tags', 'author'],
      order: { createdAt: 'DESC' },
      take: 20,
      ...options,
    };

    const entities = await this.repository.find(findOptions);
    return entities.map(entity => this.toDomain(entity));
  }

  async findByCategory(
    categoryId: string, 
    options: Partial<FindManyOptions<ArticleEntity>> = {}
  ): Promise<Article[]> {
    const findOptions: FindManyOptions<ArticleEntity> = {
      where: { categoryId },
      relations: ['category', 'tags', 'author'],
      order: { createdAt: 'DESC' },
      take: 20,
      ...options,
    };

    const entities = await this.repository.find(findOptions);
    return entities.map(entity => this.toDomain(entity));
  }

  async findByStatus(
    status: ArticleStatus, 
    options: Partial<FindManyOptions<ArticleEntity>> = {}
  ): Promise<Article[]> {
    const findOptions: FindManyOptions<ArticleEntity> = {
      where: { status },
      relations: ['category', 'tags', 'author'],
      order: { createdAt: 'DESC' },
      take: 20,
      ...options,
    };

    const entities = await this.repository.find(findOptions);
    return entities.map(entity => this.toDomain(entity));
  }

  async findPublished(options: Partial<FindManyOptions<ArticleEntity>> = {}): Promise<Article[]> {
    const findOptions: FindManyOptions<ArticleEntity> = {
      where: { 
        status: ArticleStatus.PUBLISHED,
        visibility: ArticleVisibility.PUBLIC,
      },
      relations: ['category', 'tags', 'author'],
      order: { publishedAt: 'DESC' },
      take: 20,
      ...options,
    };

    const entities = await this.repository.find(findOptions);
    return entities.map(entity => this.toDomain(entity));
  }

  async findFeatured(options: Partial<FindManyOptions<ArticleEntity>> = {}): Promise<Article[]> {
    const findOptions: FindManyOptions<ArticleEntity> = {
      where: { 
        isFeatured: true,
        status: ArticleStatus.PUBLISHED,
      },
      relations: ['category', 'tags', 'author'],
      order: { featuredAt: 'DESC' },
      take: 10,
      ...options,
    };

    const entities = await this.repository.find(findOptions);
    return entities.map(entity => this.toDomain(entity));
  }

  async findTrending(options: Partial<FindManyOptions<ArticleEntity>> = {}): Promise<Article[]> {
    const findOptions: FindManyOptions<ArticleEntity> = {
      where: { 
        isTrending: true,
        status: ArticleStatus.PUBLISHED,
      },
      relations: ['category', 'tags', 'author'],
      order: { trendingScore: 'DESC' },
      take: 10,
      ...options,
    };

    const entities = await this.repository.find(findOptions);
    return entities.map(entity => this.toDomain(entity));
  }

  async search(
    query: string, 
    options: Partial<FindManyOptions<ArticleEntity>> = {}
  ): Promise<Article[]> {
    const qb = this.repository.createQueryBuilder('article')
      .leftJoinAndSelect('article.category', 'category')
      .leftJoinAndSelect('article.tags', 'tags')
      .leftJoinAndSelect('article.author', 'author')
      .where(
        '(article.title ILIKE :query OR article.excerpt ILIKE :query OR article.content ILIKE :query)',
        { query: `%${query}%` }
      )
      .andWhere('article.status = :status', { status: ArticleStatus.PUBLISHED })
      .orderBy('article.publishedAt', 'DESC')
      .take(options.take || 20)
      .skip(options.skip || 0);

    const entities = await qb.getMany();
    return entities.map(entity => this.toDomain(entity));
  }

  async save(article: Article): Promise<Article> {
    const persistence = article.toPersistence();
    
    // Handle tags separately if they exist
    if (persistence.tagIds && persistence.tagIds.length > 0) {
      await this.entityManager.transaction(async (manager) => {
        const articleRepo = manager.getRepository(ArticleEntity);
        
        // Save article
        const savedEntity = await articleRepo.save(persistence);
        
        // Handle tag relationships
        if (persistence.tagIds && persistence.tagIds.length > 0) {
          // Clear existing tag relationships
          await manager.query(
            'DELETE FROM paperly.article_tags WHERE article_id = $1',
            [savedEntity.id]
          );
          
          // Insert new tag relationships
          for (const tagId of persistence.tagIds) {
            await manager.query(
              'INSERT INTO paperly.article_tags (article_id, tag_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
              [savedEntity.id, tagId]
            );
          }
        }
      });
    } else {
      await this.repository.save(persistence);
    }

    // Return the saved article
    return this.findById(article.id) as Promise<Article>;
  }

  async delete(id: string): Promise<void> {
    await this.repository.delete(id);
  }

  async count(where?: FindOptionsWhere<ArticleEntity>): Promise<number> {
    return this.repository.count({ where });
  }

  async update(id: string, data: Partial<Article>): Promise<Article> {
    await this.repository.update(id, data.toPersistence ? data.toPersistence() : data);
    const updated = await this.findById(id);
    if (!updated) {
      throw new Error(`Article with id ${id} not found`);
    }
    return updated;
  }

  async findWithPagination(options: {
    page: number;
    limit: number;
    status?: string;
    categoryId?: string;
    authorId?: string;
    search?: string;
  }): Promise<{
    items: Article[];
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  }> {
    const { page = 1, limit = 20, status, categoryId, authorId, search } = options;
    const skip = (page - 1) * limit;

    const qb = this.repository.createQueryBuilder('article')
      .leftJoinAndSelect('article.category', 'category')
      .leftJoinAndSelect('article.tags', 'tags')
      .leftJoinAndSelect('article.author', 'author');

    if (status) {
      qb.andWhere('article.status = :status', { status });
    }

    if (categoryId) {
      qb.andWhere('article.categoryId = :categoryId', { categoryId });
    }

    if (authorId) {
      qb.andWhere('article.authorId = :authorId', { authorId });
    }

    if (search) {
      qb.andWhere(
        '(article.title ILIKE :search OR article.excerpt ILIKE :search OR article.content ILIKE :search)',
        { search: `%${search}%` }
      );
    }

    const [entities, total] = await qb
      .orderBy('article.createdAt', 'DESC')
      .skip(skip)
      .take(limit)
      .getManyAndCount();

    return {
      items: entities.map(entity => this.toDomain(entity)),
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit)
    };
  }

  async syncTags(articleId: string, tagIds: string[]): Promise<void> {
    await this.entityManager.transaction(async (manager) => {
      // Clear existing tag relationships
      await manager.query(
        'DELETE FROM paperly.article_tags WHERE article_id = $1',
        [articleId]
      );
      
      // Insert new tag relationships
      for (const tagId of tagIds) {
        await manager.query(
          'INSERT INTO paperly.article_tags (article_id, tag_id, relevance_score) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING',
          [articleId, tagId, 1.0]
        );
      }
    });
  }

  private toDomain(entity: ArticleEntity): Article {
    return Article.fromPersistence({
      id: entity.id,
      title: entity.title,
      slug: entity.slug,
      subtitle: entity.subtitle,
      excerpt: entity.excerpt,
      content: entity.content,
      content_html: entity.contentHtml,
      featured_image_url: entity.featuredImageUrl,
      featured_image_alt: entity.featuredImageAlt,
      reading_time_minutes: entity.readingTimeMinutes,
      word_count: entity.wordCount,
      status: entity.status,
      visibility: entity.visibility,
      author_id: entity.authorId,
      author_name: entity.authorName,
      editor_id: entity.editorId,
      category_id: entity.categoryId,
      seo_title: entity.seoTitle,
      seo_description: entity.seoDescription,
      seo_keywords: entity.seoKeywords,
      difficulty_level: entity.difficultyLevel,
      content_type: entity.contentType,
      is_premium: entity.isPremium,
      estimated_reading_time: entity.estimatedReadingTime,
      view_count: entity.viewCount,
      like_count: entity.likeCount,
      share_count: entity.shareCount,
      comment_count: entity.commentCount,
      is_featured: entity.isFeatured,
      featured_at: entity.featuredAt,
      is_trending: entity.isTrending,
      trending_score: entity.trendingScore,
      ai_summary: entity.aiSummary,
      ai_tags: entity.aiTags ? JSON.parse(entity.aiTags) : [],
      ai_reading_level: entity.aiReadingLevel,
      ai_sentiment: entity.aiSentiment,
      scheduled_at: entity.scheduledAt,
      published_at: entity.publishedAt,
      metadata: entity.metadata ? JSON.parse(entity.metadata) : {},
      created_at: entity.createdAt,
      updated_at: entity.updatedAt,
      deleted_at: entity.deletedAt,
    });
  }
}