import { injectable } from 'tsyringe';
import { Pool, PoolClient } from 'pg';
import { v4 as uuidv4 } from 'uuid';
import { Logger } from '../logging/Logger';
import { LikeRepository, ArticleLike, ArticleStatsRepository } from '../../application/services/like.service';

@injectable()
export class PostgresLikeRepository implements LikeRepository {
  private readonly logger = new Logger('PostgresLikeRepository');

  constructor(private readonly pool: Pool) {}

  async findByUserAndArticle(userId: string, articleId: string): Promise<ArticleLike | null> {
    const client = await this.pool.connect();
    try {
      const result = await client.query(
        'SELECT id, user_id, article_id, created_at FROM paperly.article_likes WHERE user_id = $1 AND article_id = $2',
        [userId, articleId]
      );

      if (result.rows.length === 0) {
        return null;
      }

      const row = result.rows[0];
      return {
        id: row.id,
        userId: row.user_id,
        articleId: row.article_id,
        createdAt: row.created_at
      };
    } catch (error) {
      this.logger.error('Failed to find like by user and article', { userId, articleId, error });
      throw error;
    } finally {
      client.release();
    }
  }

  async create(userId: string, articleId: string): Promise<ArticleLike> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      const id = uuidv4();
      const now = new Date();

      const result = await client.query(
        'INSERT INTO paperly.article_likes (id, user_id, article_id, created_at) VALUES ($1, $2, $3, $4) RETURNING *',
        [id, userId, articleId, now]
      );

      await client.query('COMMIT');

      const row = result.rows[0];
      return {
        id: row.id,
        userId: row.user_id,
        articleId: row.article_id,
        createdAt: row.created_at
      };
    } catch (error) {
      await client.query('ROLLBACK');
      this.logger.error('Failed to create like', { userId, articleId, error });
      throw error;
    } finally {
      client.release();
    }
  }

  async delete(userId: string, articleId: string): Promise<void> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      const result = await client.query(
        'DELETE FROM paperly.article_likes WHERE user_id = $1 AND article_id = $2',
        [userId, articleId]
      );

      await client.query('COMMIT');

      if (result.rowCount === 0) {
        this.logger.warn('No like found to delete', { userId, articleId });
      }
    } catch (error) {
      await client.query('ROLLBACK');
      this.logger.error('Failed to delete like', { userId, articleId, error });
      throw error;
    } finally {
      client.release();
    }
  }

  async countByArticle(articleId: string): Promise<number> {
    const client = await this.pool.connect();
    try {
      const result = await client.query(
        'SELECT COUNT(*) as count FROM paperly.article_likes WHERE article_id = $1',
        [articleId]
      );

      return parseInt(result.rows[0].count, 10);
    } catch (error) {
      this.logger.error('Failed to count likes for article', { articleId, error });
      throw error;
    } finally {
      client.release();
    }
  }
}

@injectable()
export class PostgresArticleStatsRepository implements ArticleStatsRepository {
  private readonly logger = new Logger('PostgresArticleStatsRepository');

  constructor(private readonly pool: Pool) {}

  async updateLikeCount(articleId: string, likeCount: number): Promise<void> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      await client.query(
        `INSERT INTO paperly.article_stats (article_id, like_count, updated_at)
         VALUES ($1, $2, CURRENT_TIMESTAMP)
         ON CONFLICT (article_id) 
         DO UPDATE SET 
           like_count = $2,
           updated_at = CURRENT_TIMESTAMP`,
        [articleId, likeCount]
      );

      await client.query('COMMIT');
      this.logger.info('Updated like count in article stats', { articleId, likeCount });
    } catch (error) {
      await client.query('ROLLBACK');
      this.logger.error('Failed to update like count in article stats', { articleId, likeCount, error });
      throw error;
    } finally {
      client.release();
    }
  }
}