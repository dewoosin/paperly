import { DatabaseConnection } from '../database/database.connection';
import { Logger } from '../logging/Logger';
import { 
  CreateArticleDto, 
  UpdateArticleDto, 
  WriterArticleResponseDto, 
  WriterArticleListDto,
  WriterArticleStatsDto
} from '../../application/dto/writer-article.dto';
import { WriterArticleValidator } from '../../application/validation/writer-article.validation';

export class WriterArticleRepository {
  private logger = new Logger('WriterArticleRepository');
  private db: DatabaseConnection;

  constructor() {
    this.db = DatabaseConnection.getInstance();
  }

  async createArticle(authorId: string, dto: CreateArticleDto): Promise<WriterArticleResponseDto> {
    const client = await this.db.getClient();
    
    try {
      await client.query('BEGIN');

      // Calculate word count and reading time
      const wordCount = WriterArticleValidator.calculateWordCount(dto.content);
      const readingTimeMinutes = WriterArticleValidator.calculateReadingTime(wordCount);
      
      // Generate slug
      const baseSlug = WriterArticleValidator.generateSlug(dto.title);
      const slug = await this.generateUniqueSlug(baseSlug);

      const query = `
        INSERT INTO paperly.articles (
          title, subtitle, slug, content, excerpt, author_id, category_id,
          featured_image_url, featured_image_alt, status, visibility,
          word_count, reading_time_minutes, difficulty_level, content_type,
          is_premium, seo_title, seo_description, seo_keywords,
          scheduled_at, metadata, created_at, updated_at
        ) VALUES (
          $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, NOW(), NOW()
        ) RETURNING *
      `;

      const values = [
        dto.title,
        dto.subtitle || null,
        slug,
        dto.content,
        dto.excerpt || null,
        authorId,
        dto.categoryId || null,
        dto.featuredImageUrl || null,
        dto.featuredImageAlt || null,
        'draft', // Default status for new articles
        dto.visibility || 'public',
        wordCount,
        readingTimeMinutes,
        dto.difficultyLevel || 1,
        dto.contentType || 'article',
        dto.isPremium || false,
        dto.seoTitle || null,
        dto.seoDescription || null,
        dto.seoKeywords || null,
        dto.scheduledAt || null,
        JSON.stringify(dto.metadata || {})
      ];

      const result = await client.query(query, values);
      const article = result.rows[0];

      // Get author name for response
      const authorQuery = `
        SELECT first_name, last_name FROM paperly.users WHERE id = $1
      `;
      const authorResult = await client.query(authorQuery, [authorId]);
      const author = authorResult.rows[0];
      const authorName = author ? `${author.first_name} ${author.last_name}`.trim() : null;

      await client.query('COMMIT');

      this.logger.info('Article created successfully', {
        articleId: article.id,
        authorId,
        title: dto.title,
        wordCount
      });

      return this.mapToResponseDto(article, authorName);
    } catch (error) {
      await client.query('ROLLBACK');
      this.logger.error('Failed to create article', error, { authorId, title: dto.title });
      throw error;
    } finally {
      client.release();
    }
  }

  async updateArticle(articleId: string, authorId: string, dto: UpdateArticleDto): Promise<WriterArticleResponseDto> {
    const client = await this.db.getClient();
    
    try {
      await client.query('BEGIN');

      // First verify the article exists and belongs to the author
      const existsQuery = `
        SELECT id FROM paperly.articles 
        WHERE id = $1 AND author_id = $2 AND deleted_at IS NULL
      `;
      const existsResult = await client.query(existsQuery, [articleId, authorId]);
      
      if (existsResult.rows.length === 0) {
        throw new Error('Article not found or you do not have permission to edit it');
      }

      // Build dynamic update query
      const updateFields: string[] = [];
      const values: any[] = [];
      let paramCount = 1;

      if (dto.title !== undefined) {
        updateFields.push(`title = $${paramCount++}`);
        values.push(dto.title);
        
        // Update slug if title changed
        const newSlug = await this.generateUniqueSlug(WriterArticleValidator.generateSlug(dto.title), articleId);
        updateFields.push(`slug = $${paramCount++}`);
        values.push(newSlug);
      }

      if (dto.subtitle !== undefined) {
        updateFields.push(`subtitle = $${paramCount++}`);
        values.push(dto.subtitle);
      }

      if (dto.content !== undefined) {
        updateFields.push(`content = $${paramCount++}`);
        values.push(dto.content);
        
        // Recalculate word count and reading time
        const wordCount = WriterArticleValidator.calculateWordCount(dto.content);
        const readingTimeMinutes = WriterArticleValidator.calculateReadingTime(wordCount);
        
        updateFields.push(`word_count = $${paramCount++}`);
        values.push(wordCount);
        
        updateFields.push(`reading_time_minutes = $${paramCount++}`);
        values.push(readingTimeMinutes);
      }

      if (dto.excerpt !== undefined) {
        updateFields.push(`excerpt = $${paramCount++}`);
        values.push(dto.excerpt);
      }

      if (dto.categoryId !== undefined) {
        updateFields.push(`category_id = $${paramCount++}`);
        values.push(dto.categoryId);
      }

      if (dto.featuredImageUrl !== undefined) {
        updateFields.push(`featured_image_url = $${paramCount++}`);
        values.push(dto.featuredImageUrl);
      }

      if (dto.featuredImageAlt !== undefined) {
        updateFields.push(`featured_image_alt = $${paramCount++}`);
        values.push(dto.featuredImageAlt);
      }

      if (dto.visibility !== undefined) {
        updateFields.push(`visibility = $${paramCount++}`);
        values.push(dto.visibility);
      }

      if (dto.isPremium !== undefined) {
        updateFields.push(`is_premium = $${paramCount++}`);
        values.push(dto.isPremium);
      }

      if (dto.difficultyLevel !== undefined) {
        updateFields.push(`difficulty_level = $${paramCount++}`);
        values.push(dto.difficultyLevel);
      }

      if (dto.contentType !== undefined) {
        updateFields.push(`content_type = $${paramCount++}`);
        values.push(dto.contentType);
      }

      if (dto.seoTitle !== undefined) {
        updateFields.push(`seo_title = $${paramCount++}`);
        values.push(dto.seoTitle);
      }

      if (dto.seoDescription !== undefined) {
        updateFields.push(`seo_description = $${paramCount++}`);
        values.push(dto.seoDescription);
      }

      if (dto.seoKeywords !== undefined) {
        updateFields.push(`seo_keywords = $${paramCount++}`);
        values.push(dto.seoKeywords);
      }

      if (dto.scheduledAt !== undefined) {
        updateFields.push(`scheduled_at = $${paramCount++}`);
        values.push(dto.scheduledAt);
      }

      if (dto.metadata !== undefined) {
        updateFields.push(`metadata = $${paramCount++}`);
        values.push(JSON.stringify(dto.metadata));
      }

      // Always update the updated_at timestamp
      updateFields.push(`updated_at = NOW()`);

      if (updateFields.length === 1) { // Only updated_at was added
        throw new Error('No fields to update');
      }

      // Add WHERE clause parameters
      values.push(articleId, authorId);
      
      const updateQuery = `
        UPDATE paperly.articles 
        SET ${updateFields.join(', ')}
        WHERE id = $${paramCount++} AND author_id = $${paramCount++} AND deleted_at IS NULL
        RETURNING *
      `;

      const result = await client.query(updateQuery, values);
      const article = result.rows[0];

      // Get author name for response
      const authorQuery = `
        SELECT first_name, last_name FROM paperly.users WHERE id = $1
      `;
      const authorResult = await client.query(authorQuery, [authorId]);
      const author = authorResult.rows[0];
      const authorName = author ? `${author.first_name} ${author.last_name}`.trim() : null;

      await client.query('COMMIT');

      this.logger.info('Article updated successfully', {
        articleId,
        authorId,
        updatedFields: Object.keys(dto)
      });

      return this.mapToResponseDto(article, authorName);
    } catch (error) {
      await client.query('ROLLBACK');
      this.logger.error('Failed to update article', error, { articleId, authorId });
      throw error;
    } finally {
      client.release();
    }
  }

  async getArticleById(articleId: string, authorId: string): Promise<WriterArticleResponseDto | null> {
    const client = await this.db.getClient();
    
    try {
      const query = `
        SELECT a.*, u.first_name, u.last_name
        FROM paperly.articles a
        LEFT JOIN paperly.users u ON a.author_id = u.id
        WHERE a.id = $1 AND a.author_id = $2 AND a.deleted_at IS NULL
      `;

      const result = await client.query(query, [articleId, authorId]);
      
      if (result.rows.length === 0) {
        return null;
      }

      const article = result.rows[0];
      const authorName = article.first_name && article.last_name 
        ? `${article.first_name} ${article.last_name}`.trim() 
        : null;

      return this.mapToResponseDto(article, authorName);
    } catch (error) {
      this.logger.error('Failed to get article by ID', error, { articleId, authorId });
      throw error;
    } finally {
      client.release();
    }
  }

  async getArticlesByAuthor(
    authorId: string, 
    page: number = 1, 
    limit: number = 20,
    status?: string,
    search?: string
  ): Promise<{ articles: WriterArticleListDto[], total: number, page: number, limit: number }> {
    const client = await this.db.getClient();
    
    try {
      const offset = (page - 1) * limit;
      
      let whereClause = 'WHERE a.author_id = $1 AND a.deleted_at IS NULL';
      const queryParams: any[] = [authorId];
      let paramCount = 2;

      if (status) {
        whereClause += ` AND a.status = $${paramCount++}`;
        queryParams.push(status);
      }

      if (search) {
        whereClause += ` AND (a.title ILIKE $${paramCount++} OR a.content ILIKE $${paramCount++})`;
        queryParams.push(`%${search}%`, `%${search}%`);
      }

      // Count query
      const countQuery = `
        SELECT COUNT(*) FROM paperly.articles a ${whereClause}
      `;
      const countResult = await client.query(countQuery, queryParams);
      const total = parseInt(countResult.rows[0].count);

      // Data query
      queryParams.push(limit, offset);
      const dataQuery = `
        SELECT 
          a.id, a.title, a.subtitle, a.slug, a.excerpt, a.status, a.visibility,
          a.word_count, a.reading_time_minutes, a.is_premium, a.is_featured,
          a.view_count, a.like_count, a.share_count, a.comment_count,
          a.created_at, a.updated_at, a.published_at, a.scheduled_at
        FROM paperly.articles a 
        ${whereClause}
        ORDER BY a.updated_at DESC
        LIMIT $${paramCount++} OFFSET $${paramCount++}
      `;

      const result = await client.query(dataQuery, queryParams);
      const articles = result.rows.map(this.mapToListDto);

      return {
        articles,
        total,
        page,
        limit
      };
    } catch (error) {
      this.logger.error('Failed to get articles by author', error, { authorId, page, limit });
      throw error;
    } finally {
      client.release();
    }
  }

  async publishArticle(articleId: string, authorId: string, publishedAt?: Date): Promise<WriterArticleResponseDto> {
    const client = await this.db.getClient();
    
    try {
      await client.query('BEGIN');

      const publishTime = publishedAt || new Date();
      
      const query = `
        UPDATE paperly.articles 
        SET 
          status = 'published',
          published_at = $1,
          updated_at = NOW()
        WHERE id = $2 AND author_id = $3 AND deleted_at IS NULL AND status IN ('draft', 'review')
        RETURNING *
      `;

      const result = await client.query(query, [publishTime, articleId, authorId]);
      
      if (result.rows.length === 0) {
        throw new Error('Article not found or cannot be published');
      }

      const article = result.rows[0];

      // Get author name
      const authorQuery = `
        SELECT first_name, last_name FROM paperly.users WHERE id = $1
      `;
      const authorResult = await client.query(authorQuery, [authorId]);
      const author = authorResult.rows[0];
      const authorName = author ? `${author.first_name} ${author.last_name}`.trim() : null;

      await client.query('COMMIT');

      this.logger.info('Article published successfully', {
        articleId,
        authorId,
        publishedAt: publishTime
      });

      return this.mapToResponseDto(article, authorName);
    } catch (error) {
      await client.query('ROLLBACK');
      this.logger.error('Failed to publish article', error, { articleId, authorId });
      throw error;
    } finally {
      client.release();
    }
  }

  async unpublishArticle(articleId: string, authorId: string): Promise<WriterArticleResponseDto> {
    const client = await this.db.getClient();
    
    try {
      const query = `
        UPDATE paperly.articles 
        SET 
          status = 'draft',
          published_at = NULL,
          updated_at = NOW()
        WHERE id = $1 AND author_id = $2 AND deleted_at IS NULL AND status = 'published'
        RETURNING *
      `;

      const result = await client.query(query, [articleId, authorId]);
      
      if (result.rows.length === 0) {
        throw new Error('Article not found or cannot be unpublished');
      }

      const article = result.rows[0];

      // Get author name
      const authorQuery = `
        SELECT first_name, last_name FROM paperly.users WHERE id = $1
      `;
      const authorResult = await client.query(authorQuery, [authorId]);
      const author = authorResult.rows[0];
      const authorName = author ? `${author.first_name} ${author.last_name}`.trim() : null;

      this.logger.info('Article unpublished successfully', { articleId, authorId });

      return this.mapToResponseDto(article, authorName);
    } catch (error) {
      this.logger.error('Failed to unpublish article', error, { articleId, authorId });
      throw error;
    } finally {
      client.release();
    }
  }

  async deleteArticle(articleId: string, authorId: string): Promise<void> {
    const client = await this.db.getClient();
    
    try {
      const query = `
        UPDATE paperly.articles 
        SET 
          status = 'deleted',
          deleted_at = NOW(),
          updated_at = NOW()
        WHERE id = $1 AND author_id = $2 AND deleted_at IS NULL
      `;

      const result = await client.query(query, [articleId, authorId]);
      
      if (result.rowCount === 0) {
        throw new Error('Article not found or already deleted');
      }

      this.logger.info('Article deleted successfully', { articleId, authorId });
    } catch (error) {
      this.logger.error('Failed to delete article', error, { articleId, authorId });
      throw error;
    } finally {
      client.release();
    }
  }

  async getWriterStats(authorId: string): Promise<WriterArticleStatsDto> {
    const client = await this.db.getClient();
    
    try {
      // Get article counts by status
      const statsQuery = `
        SELECT 
          COUNT(*) as total_articles,
          COUNT(*) FILTER (WHERE status = 'published') as published_articles,
          COUNT(*) FILTER (WHERE status = 'draft') as draft_articles,
          COUNT(*) FILTER (WHERE status = 'archived') as archived_articles,
          COALESCE(SUM(view_count), 0) as total_views,
          COALESCE(SUM(like_count), 0) as total_likes,
          COALESCE(SUM(share_count), 0) as total_shares,
          COALESCE(SUM(comment_count), 0) as total_comments,
          COALESCE(AVG(reading_time_minutes), 0) as average_reading_time
        FROM paperly.articles 
        WHERE author_id = $1 AND deleted_at IS NULL
      `;

      const statsResult = await client.query(statsQuery, [authorId]);
      const stats = statsResult.rows[0];

      // Get top performing articles
      const topArticlesQuery = `
        SELECT 
          id, title, subtitle, slug, excerpt, status, visibility,
          word_count, reading_time_minutes, is_premium, is_featured,
          view_count, like_count, share_count, comment_count,
          created_at, updated_at, published_at, scheduled_at
        FROM paperly.articles 
        WHERE author_id = $1 AND deleted_at IS NULL AND status = 'published'
        ORDER BY view_count DESC, like_count DESC
        LIMIT 5
      `;

      const topResult = await client.query(topArticlesQuery, [authorId]);
      const topPerformingArticles = topResult.rows.map(this.mapToListDto);

      // Get recent articles
      const recentArticlesQuery = `
        SELECT 
          id, title, subtitle, slug, excerpt, status, visibility,
          word_count, reading_time_minutes, is_premium, is_featured,
          view_count, like_count, share_count, comment_count,
          created_at, updated_at, published_at, scheduled_at
        FROM paperly.articles 
        WHERE author_id = $1 AND deleted_at IS NULL
        ORDER BY created_at DESC
        LIMIT 10
      `;

      const recentResult = await client.query(recentArticlesQuery, [authorId]);
      const recentArticles = recentResult.rows.map(this.mapToListDto);

      return {
        totalArticles: parseInt(stats.total_articles),
        publishedArticles: parseInt(stats.published_articles),
        draftArticles: parseInt(stats.draft_articles),
        archivedArticles: parseInt(stats.archived_articles),
        totalViews: parseInt(stats.total_views),
        totalLikes: parseInt(stats.total_likes),
        totalShares: parseInt(stats.total_shares),
        totalComments: parseInt(stats.total_comments),
        averageReadingTime: parseFloat(stats.average_reading_time),
        topPerformingArticles,
        recentArticles
      };
    } catch (error) {
      this.logger.error('Failed to get writer stats', error, { authorId });
      throw error;
    } finally {
      client.release();
    }
  }

  private async generateUniqueSlug(baseSlug: string, excludeId?: string): Promise<string> {
    const client = await this.db.getClient();
    let slug = baseSlug;
    let counter = 1;

    while (true) {
      let checkQuery = 'SELECT id FROM paperly.articles WHERE slug = $1';
      const queryParams = [slug];

      if (excludeId) {
        checkQuery += ' AND id != $2';
        queryParams.push(excludeId);
      }

      const result = await client.query(checkQuery, queryParams);
      
      if (result.rows.length === 0) {
        return slug;
      }

      slug = `${baseSlug}-${counter}`;
      counter++;

      // Prevent infinite loop
      if (counter > 1000) {
        slug = `${baseSlug}-${Date.now()}`;
        break;
      }
    }

    return slug;
  }

  private mapToResponseDto(article: any, authorName?: string): WriterArticleResponseDto {
    return {
      id: article.id,
      title: article.title,
      subtitle: article.subtitle,
      slug: article.slug,
      content: article.content,
      excerpt: article.excerpt,
      authorId: article.author_id,
      authorName: authorName || article.author_name,
      categoryId: article.category_id,
      featuredImageUrl: article.featured_image_url,
      featuredImageAlt: article.featured_image_alt,
      status: article.status,
      visibility: article.visibility,
      wordCount: article.word_count || 0,
      readingTimeMinutes: article.reading_time_minutes,
      difficultyLevel: article.difficulty_level || 1,
      contentType: article.content_type || 'article',
      isPremium: article.is_premium || false,
      isFeatured: article.is_featured || false,
      seoTitle: article.seo_title,
      seoDescription: article.seo_description,
      seoKeywords: article.seo_keywords,
      viewCount: article.view_count || 0,
      likeCount: article.like_count || 0,
      shareCount: article.share_count || 0,
      commentCount: article.comment_count || 0,
      createdAt: new Date(article.created_at),
      updatedAt: new Date(article.updated_at),
      publishedAt: article.published_at ? new Date(article.published_at) : undefined,
      scheduledAt: article.scheduled_at ? new Date(article.scheduled_at) : undefined,
      metadata: article.metadata ? JSON.parse(article.metadata) : {}
    };
  }

  private mapToListDto(article: any): WriterArticleListDto {
    return {
      id: article.id,
      title: article.title,
      subtitle: article.subtitle,
      slug: article.slug,
      excerpt: article.excerpt,
      status: article.status,
      visibility: article.visibility,
      wordCount: article.word_count || 0,
      readingTimeMinutes: article.reading_time_minutes,
      isPremium: article.is_premium || false,
      isFeatured: article.is_featured || false,
      viewCount: article.view_count || 0,
      likeCount: article.like_count || 0,
      shareCount: article.share_count || 0,
      commentCount: article.comment_count || 0,
      createdAt: new Date(article.created_at),
      updatedAt: new Date(article.updated_at),
      publishedAt: article.published_at ? new Date(article.published_at) : undefined,
      scheduledAt: article.scheduled_at ? new Date(article.scheduled_at) : undefined
    };
  }
}