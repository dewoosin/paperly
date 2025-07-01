import { injectable, inject } from 'tsyringe';
import { Logger } from '../../infrastructure/logging/Logger';

export interface LikeRepository {
  findByUserAndArticle(userId: string, articleId: string): Promise<ArticleLike | null>;
  create(userId: string, articleId: string): Promise<ArticleLike>;
  delete(userId: string, articleId: string): Promise<void>;
  countByArticle(articleId: string): Promise<number>;
}

export interface ArticleStatsRepository {
  updateLikeCount(articleId: string, likeCount: number): Promise<void>;
}

export interface ArticleLike {
  id: string;
  userId: string;
  articleId: string;
  createdAt: Date;
}

export class LikeAlreadyExistsException extends Error {
  constructor(message: string = 'User has already liked this article') {
    super(message);
    this.name = 'LikeAlreadyExistsException';
  }
}

export class LikeNotFoundException extends Error {
  constructor(message: string = 'Like not found') {
    super(message);
    this.name = 'LikeNotFoundException';
  }
}

@injectable()
export class LikeService {
  private readonly logger = new Logger('LikeService');

  constructor(
    @inject('LikeRepository') private readonly likeRepository: LikeRepository,
    @inject('ArticleStatsRepository') private readonly articleStatsRepository: ArticleStatsRepository
  ) {}

  async likeArticle(userId: string, articleId: string): Promise<{ liked: boolean; likeCount: number }> {
    this.logger.info('Attempting to like article', { userId, articleId });

    const existingLike = await this.likeRepository.findByUserAndArticle(userId, articleId);
    
    if (existingLike) {
      this.logger.info('User has already liked this article', { userId, articleId });
      const likeCount = await this.likeRepository.countByArticle(articleId);
      return { liked: true, likeCount };
    }

    try {
      await this.likeRepository.create(userId, articleId);
      const newLikeCount = await this.likeRepository.countByArticle(articleId);
      
      await this.articleStatsRepository.updateLikeCount(articleId, newLikeCount);
      
      this.logger.info('Article liked successfully', { userId, articleId, newLikeCount });
      return { liked: true, likeCount: newLikeCount };
    } catch (error) {
      this.logger.error('Failed to like article', { userId, articleId, error });
      throw error;
    }
  }

  async unlikeArticle(userId: string, articleId: string): Promise<{ liked: boolean; likeCount: number }> {
    this.logger.info('Attempting to unlike article', { userId, articleId });

    const existingLike = await this.likeRepository.findByUserAndArticle(userId, articleId);
    
    if (!existingLike) {
      this.logger.info('User has not liked this article', { userId, articleId });
      const likeCount = await this.likeRepository.countByArticle(articleId);
      return { liked: false, likeCount };
    }

    try {
      await this.likeRepository.delete(userId, articleId);
      const newLikeCount = await this.likeRepository.countByArticle(articleId);
      
      await this.articleStatsRepository.updateLikeCount(articleId, newLikeCount);
      
      this.logger.info('Article unliked successfully', { userId, articleId, newLikeCount });
      return { liked: false, likeCount: newLikeCount };
    } catch (error) {
      this.logger.error('Failed to unlike article', { userId, articleId, error });
      throw error;
    }
  }

  async toggleLike(userId: string, articleId: string): Promise<{ liked: boolean; likeCount: number }> {
    const existingLike = await this.likeRepository.findByUserAndArticle(userId, articleId);
    
    if (existingLike) {
      return this.unlikeArticle(userId, articleId);
    } else {
      return this.likeArticle(userId, articleId);
    }
  }

  async getUserLikeStatus(userId: string, articleId: string): Promise<{ liked: boolean; likeCount: number }> {
    const existingLike = await this.likeRepository.findByUserAndArticle(userId, articleId);
    const likeCount = await this.likeRepository.countByArticle(articleId);
    
    return {
      liked: !!existingLike,
      likeCount
    };
  }

  async getArticleLikeCount(articleId: string): Promise<number> {
    return this.likeRepository.countByArticle(articleId);
  }
}