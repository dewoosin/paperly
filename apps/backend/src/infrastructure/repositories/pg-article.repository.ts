// /Users/workspace/paperly/apps/backend/src/infrastructure/repositories/pg-article.repository.ts

import { injectable, inject } from 'tsyringe';
import { Pool } from 'pg';
import { Article, ArticleStatus, ArticleVisibility } from '../../domain/entities/article.entity';
import { ArticleRecord } from '../entities/simple-article.entity';
import { Logger } from '../logging/Logger';

const logger = new Logger('PgArticleRepository');

export interface ArticleRepository {
  findById(id: string): Promise<Article | null>;
  findBySlug(slug: string): Promise<Article | null>;
  findMany(options?: any): Promise<Article[]>;
  findByAuthor(authorId: string, options?: any): Promise<Article[]>;
  findByCategory(categoryId: string, options?: any): Promise<Article[]>;
  findByStatus(status: ArticleStatus, options?: any): Promise<Article[]>;
  findPublished(options?: any): Promise<Article[]>;
  findFeatured(options?: any): Promise<Article[]>;
  findTrending(options?: any): Promise<Article[]>;
  search(query: string, options?: any): Promise<Article[]>;
  save(article: Article): Promise<Article>;
  update(id: string, data: Partial<Article>): Promise<Article>;
  delete(id: string): Promise<void>;
  count(where?: any): Promise<number>;
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
export class PgArticleRepository implements ArticleRepository {
  constructor(
    @inject('DatabasePool') private readonly pool: Pool,
  ) {}

  async findById(id: string): Promise<Article | null> {
    try {
      const query = `
        SELECT * FROM paperly.articles 
        WHERE id = $1 AND deleted_at IS NULL
      `;
      const result = await this.pool.query(query, [id]);
      
      if (result.rows.length === 0) {
        return null;
      }

      return this.toDomain(result.rows[0]);
    } catch (error) {
      logger.error('Error finding article by id:', error);
      throw error;
    }
  }

  async findBySlug(slug: string): Promise<Article | null> {
    try {
      const query = `
        SELECT * FROM paperly.articles 
        WHERE slug = $1 AND deleted_at IS NULL
      `;
      const result = await this.pool.query(query, [slug]);
      
      if (result.rows.length === 0) {
        return null;
      }

      // Increment view count for published articles
      const article = this.toDomain(result.rows[0]);
      if (article.isPublished()) {
        await this.pool.query(
          'UPDATE paperly.articles SET view_count = view_count + 1 WHERE id = $1',
          [article.id]
        );
      }

      return article;
    } catch (error) {
      logger.error('Error finding article by slug:', error);
      throw error;
    }
  }

  async findMany(options: any = {}): Promise<Article[]> {
    try {
      const limit = options.take || 20;
      const offset = options.skip || 0;
      
      const query = `
        SELECT * FROM paperly.articles 
        WHERE deleted_at IS NULL
        ORDER BY created_at DESC
        LIMIT $1 OFFSET $2
      `;
      
      const result = await this.pool.query(query, [limit, offset]);
      return result.rows.map(row => this.toDomain(row));
    } catch (error) {
      logger.error('Error finding articles:', error);
      throw error;
    }
  }

  async findByAuthor(authorId: string, options: any = {}): Promise<Article[]> {
    try {
      const limit = options.take || 20;
      const offset = options.skip || 0;
      
      const query = `
        SELECT * FROM paperly.articles 
        WHERE author_id = $1 AND deleted_at IS NULL
        ORDER BY created_at DESC
        LIMIT $2 OFFSET $3
      `;
      
      const result = await this.pool.query(query, [authorId, limit, offset]);
      return result.rows.map(row => this.toDomain(row));
    } catch (error) {
      logger.error('Error finding articles by author:', error);
      throw error;
    }
  }

  async findByCategory(categoryId: string, options: any = {}): Promise<Article[]> {
    try {
      const limit = options.take || 20;
      const offset = options.skip || 0;
      
      const query = `
        SELECT * FROM paperly.articles 
        WHERE category_id = $1 AND deleted_at IS NULL
        ORDER BY created_at DESC
        LIMIT $2 OFFSET $3
      `;
      
      const result = await this.pool.query(query, [categoryId, limit, offset]);
      return result.rows.map(row => this.toDomain(row));
    } catch (error) {
      logger.error('Error finding articles by category:', error);
      throw error;
    }
  }

  async findByStatus(status: ArticleStatus, options: any = {}): Promise<Article[]> {
    try {
      const limit = options.take || 20;
      const offset = options.skip || 0;
      
      const query = `
        SELECT * FROM paperly.articles 
        WHERE status = $1 AND deleted_at IS NULL
        ORDER BY created_at DESC
        LIMIT $2 OFFSET $3
      `;
      
      const result = await this.pool.query(query, [status, limit, offset]);
      return result.rows.map(row => this.toDomain(row));
    } catch (error) {
      logger.error('Error finding articles by status:', error);
      throw error;
    }
  }

  async findPublished(options: any = {}): Promise<Article[]> {
    try {
      const limit = options.take || 20;
      const offset = options.skip || 0;
      
      const query = `
        SELECT * FROM paperly.articles 
        WHERE status = 'published' 
          AND visibility = 'public' 
          AND deleted_at IS NULL
        ORDER BY published_at DESC
        LIMIT $1 OFFSET $2
      `;
      
      const result = await this.pool.query(query, [limit, offset]);
      return result.rows.map(row => this.toDomain(row));
    } catch (error) {
      logger.error('Error finding published articles:', error);
      throw error;
    }
  }

  async findFeatured(options: any = {}): Promise<Article[]> {
    try {
      const limit = options.take || 10;
      const offset = options.skip || 0;
      
      const query = `
        SELECT * FROM paperly.articles 
        WHERE is_featured = true 
          AND status = 'published' 
          AND deleted_at IS NULL
        ORDER BY created_at DESC
        LIMIT $1 OFFSET $2
      `;
      
      const result = await this.pool.query(query, [limit, offset]);
      return result.rows.map(row => this.toDomain(row));
    } catch (error) {
      logger.error('Error finding featured articles:', error);
      throw error;
    }
  }

  async findTrending(options: any = {}): Promise<Article[]> {
    try {
      const limit = options.take || 10;
      const offset = options.skip || 0;
      
      const query = `
        SELECT * FROM paperly.articles 
        WHERE is_trending = true 
          AND status = 'published' 
          AND deleted_at IS NULL
        ORDER BY view_count DESC
        LIMIT $1 OFFSET $2
      `;
      
      const result = await this.pool.query(query, [limit, offset]);
      return result.rows.map(row => this.toDomain(row));
    } catch (error) {
      logger.error('Error finding trending articles:', error);
      throw error;
    }
  }

  async search(query: string, options: any = {}): Promise<Article[]> {
    try {
      const limit = options.take || 20;
      const offset = options.skip || 0;
      
      const searchQuery = `
        SELECT * FROM paperly.articles 
        WHERE (title ILIKE $1 OR excerpt ILIKE $1 OR content ILIKE $1)
          AND status = 'published' 
          AND deleted_at IS NULL
        ORDER BY published_at DESC
        LIMIT $2 OFFSET $3
      `;
      
      const result = await this.pool.query(searchQuery, [`%${query}%`, limit, offset]);
      return result.rows.map(row => this.toDomain(row));
    } catch (error) {
      logger.error('Error searching articles:', error);
      throw error;
    }
  }

  async save(article: Article): Promise<Article> {
    try {
      const persistence = article.toPersistence();
      
      // Check if article exists
      const existingQuery = 'SELECT id FROM paperly.articles WHERE id = $1';
      const existing = await this.pool.query(existingQuery, [persistence.id]);
      
      if (existing.rows.length > 0) {
        // Update existing article
        const updateQuery = `
          UPDATE paperly.articles SET
            title = $2,
            slug = $3,
            subtitle = $4,
            excerpt = $5,
            content = $6,
            content_html = $7,
            featured_image_url = $8,
            featured_image_alt = $9,
            reading_time_minutes = $10,
            word_count = $11,
            status = $12,
            visibility = $13,
            editor_id = $14,
            category_id = $15,
            seo_title = $16,
            seo_description = $17,
            view_count = $18,
            like_count = $19,
            share_count = $20,
            comment_count = $21,
            is_featured = $22,
            featured_at = $23,
            is_trending = $24,
            trending_score = $25,
            ai_summary = $26,
            ai_tags = $27,
            ai_reading_level = $28,
            ai_sentiment = $29,
            scheduled_at = $30,
            published_at = $31,
            metadata = $32,
            updated_at = NOW(),
            deleted_at = $33
          WHERE id = $1
          RETURNING *
        `;
        
        const values = [
          persistence.id, persistence.title, persistence.slug, persistence.subtitle,
          persistence.excerpt, persistence.content, persistence.content_html,
          persistence.featured_image_url, persistence.featured_image_alt,
          persistence.reading_time_minutes, persistence.word_count,
          persistence.status, persistence.visibility, persistence.editor_id,
          persistence.category_id, persistence.seo_title, persistence.seo_description,
          persistence.view_count, persistence.like_count, persistence.share_count,
          persistence.comment_count, persistence.is_featured, persistence.featured_at,
          persistence.is_trending, persistence.trending_score, persistence.ai_summary,
          persistence.ai_tags, persistence.ai_reading_level, persistence.ai_sentiment,
          persistence.scheduled_at, persistence.published_at, persistence.metadata,
          persistence.deleted_at
        ];
        
        const result = await this.pool.query(updateQuery, values);
        return this.toDomain(result.rows[0]);
      } else {
        // Insert new article
        const insertQuery = `
          INSERT INTO paperly.articles (
            id, title, slug, subtitle, excerpt, content, content_html,
            featured_image_url, featured_image_alt, reading_time_minutes, word_count,
            status, visibility, author_id, editor_id, category_id,
            seo_title, seo_description, view_count, like_count, share_count,
            comment_count, is_featured, featured_at, is_trending, trending_score,
            ai_summary, ai_tags, ai_reading_level, ai_sentiment,
            scheduled_at, published_at, metadata, created_at, updated_at, deleted_at
          ) VALUES (
            $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16,
            $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30,
            $31, $32, $33, NOW(), NOW(), $34
          ) RETURNING *
        `;
        
        const values = [
          persistence.id, persistence.title, persistence.slug, persistence.subtitle,
          persistence.excerpt, persistence.content, persistence.content_html,
          persistence.featured_image_url, persistence.featured_image_alt,
          persistence.reading_time_minutes, persistence.word_count,
          persistence.status, persistence.visibility, persistence.author_id,
          persistence.editor_id, persistence.category_id, persistence.seo_title,
          persistence.seo_description, persistence.view_count, persistence.like_count,
          persistence.share_count, persistence.comment_count, persistence.is_featured,
          persistence.featured_at, persistence.is_trending, persistence.trending_score,
          persistence.ai_summary, persistence.ai_tags, persistence.ai_reading_level,
          persistence.ai_sentiment, persistence.scheduled_at, persistence.published_at,
          persistence.metadata, persistence.deleted_at
        ];
        
        const result = await this.pool.query(insertQuery, values);
        return this.toDomain(result.rows[0]);
      }
    } catch (error) {
      logger.error('Error saving article:', error);
      throw error;
    }
  }

  async delete(id: string): Promise<void> {
    try {
      await this.pool.query('DELETE FROM paperly.articles WHERE id = $1', [id]);
    } catch (error) {
      logger.error('Error deleting article:', error);
      throw error;
    }
  }

  async count(where: any = {}): Promise<number> {
    try {
      const query = 'SELECT COUNT(*) FROM paperly.articles WHERE deleted_at IS NULL';
      const result = await this.pool.query(query);
      return parseInt(result.rows[0].count);
    } catch (error) {
      logger.error('Error counting articles:', error);
      throw error;
    }
  }

  private safeJsonParse(jsonString: string | null, defaultValue: any): any {
    if (!jsonString) return defaultValue;
    try {
      return JSON.parse(jsonString);
    } catch (error) {
      logger.warn('JSON 파싱 실패:', { jsonString, error: error.message });
      return defaultValue;
    }
  }

  private toDomain(record: any): Article {
    return Article.fromPersistence({
      id: record.id,
      title: record.title,
      slug: record.slug,
      subtitle: record.subtitle,
      excerpt: record.excerpt,
      content: record.content,
      content_html: record.content_html,
      featured_image_url: record.featured_image_url,
      featured_image_alt: null,
      reading_time_minutes: record.estimated_reading_time,
      word_count: record.word_count,
      status: record.status || 'draft',
      visibility: record.visibility || 'public',
      author_id: record.author_id,
      editor_id: record.editor_id,
      category_id: record.category_id,
      seo_title: record.seo_title,
      seo_description: record.seo_description,
      view_count: record.view_count || 0,
      like_count: record.like_count || 0,
      share_count: record.share_count || 0,
      comment_count: record.comment_count || 0,
      is_featured: record.is_featured || false,
      featured_at: record.created_at,
      is_trending: record.is_trending || false,
      trending_score: record.trending_score || 0,
      ai_summary: record.ai_summary,
      ai_tags: this.safeJsonParse(record.ai_tags, []),
      ai_reading_level: record.ai_reading_level,
      ai_sentiment: record.ai_sentiment,
      scheduled_at: record.scheduled_at,
      published_at: record.published_at,
      metadata: this.safeJsonParse(record.metadata, {}),
      created_at: record.created_at,
      updated_at: record.updated_at,
      deleted_at: record.deleted_at,
    });
  }

  async update(id: string, data: Partial<Article>): Promise<Article> {
    try {
      const persistence = data.toPersistence ? data.toPersistence() : data;
      const now = new Date();
      
      // Build dynamic update query
      const updateFields = [];
      const values = [id];
      let paramIndex = 2;
      
      for (const [key, value] of Object.entries(persistence)) {
        if (key !== 'id' && value !== undefined) {
          updateFields.push(`${key} = $${paramIndex}`);
          values.push(value);
          paramIndex++;
        }
      }
      
      updateFields.push(`updated_at = $${paramIndex}`);
      values.push(now);
      
      const query = `
        UPDATE paperly.articles 
        SET ${updateFields.join(', ')}
        WHERE id = $1
        RETURNING *
      `;
      
      const result = await this.pool.query(query, values);
      
      if (result.rows.length === 0) {
        throw new Error(`Article with id ${id} not found`);
      }
      
      return this.toDomain(result.rows[0]);
    } catch (error) {
      logger.error('Error updating article:', error);
      throw error;
    }
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
    try {
      const { page = 1, limit = 20, status, categoryId, authorId, search } = options;
      const offset = (page - 1) * limit;
      
      const whereConditions = ['deleted_at IS NULL'];
      const queryParams = [];
      let paramIndex = 1;
      
      if (status) {
        whereConditions.push(`status = $${paramIndex}`);
        queryParams.push(status);
        paramIndex++;
      }
      
      if (categoryId) {
        whereConditions.push(`category_id = $${paramIndex}`);
        queryParams.push(categoryId);
        paramIndex++;
      }
      
      if (authorId) {
        whereConditions.push(`author_id = $${paramIndex}`);
        queryParams.push(authorId);
        paramIndex++;
      }
      
      if (search) {
        whereConditions.push(`(title ILIKE $${paramIndex} OR summary ILIKE $${paramIndex} OR content ILIKE $${paramIndex})`);
        queryParams.push(`%${search}%`);
        paramIndex++;
      }
      
      const whereClause = whereConditions.join(' AND ');
      
      // Get total count
      const countQuery = `SELECT COUNT(*) FROM paperly.articles WHERE ${whereClause}`;
      const countResult = await this.pool.query(countQuery, queryParams);
      const total = parseInt(countResult.rows[0].count);
      
      // Get paginated articles
      const articlesQuery = `
        SELECT * FROM paperly.articles 
        WHERE ${whereClause}
        ORDER BY created_at DESC
        LIMIT $${paramIndex} OFFSET $${paramIndex + 1}
      `;
      
      const articlesResult = await this.pool.query(articlesQuery, [...queryParams, limit, offset]);
      
      return {
        items: articlesResult.rows.map(row => this.toDomain(row)),
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit)
      };
    } catch (error) {
      logger.error('Error finding articles with pagination:', error);
      throw error;
    }
  }

  async syncTags(articleId: string, tagIds: string[]): Promise<void> {
    try {
      // Start transaction
      const client = await this.pool.connect();
      
      try {
        await client.query('BEGIN');
        
        // Delete existing tag relationships
        await client.query('DELETE FROM paperly.article_tags WHERE article_id = $1', [articleId]);
        
        // Insert new tag relationships
        for (const tagId of tagIds) {
          await client.query(
            'INSERT INTO paperly.article_tags (article_id, tag_id, relevance_score) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING',
            [articleId, tagId, 1.0]
          );
        }
        
        await client.query('COMMIT');
      } catch (error) {
        await client.query('ROLLBACK');
        throw error;
      } finally {
        client.release();
      }
    } catch (error) {
      logger.error('Error syncing tags:', error);
      throw error;
    }
  }
}