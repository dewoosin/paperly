import { Request, Response } from 'express';
import { injectable, inject } from 'tsyringe';
import { ArticleRepository } from '../../repositories/pg-article.repository';
import { CategoryRepository } from '../../repositories/category.repository';
import { TagRepository } from '../../repositories/tag.repository';
import { Logger } from '../../logging/Logger';
import { Article } from '../../../domain/entities/article.entity';
import { v4 as uuidv4 } from 'uuid';

@injectable()
export class AdminArticleController {
  private logger: Logger;

  constructor(
    @inject('ArticleRepository') private articleRepository: ArticleRepository,
    @inject('CategoryRepository') private categoryRepository: CategoryRepository,
    @inject('TagRepository') private tagRepository: TagRepository
  ) {
    this.logger = new Logger('AdminArticleController');
  }

  async getAllArticles(req: Request, res: Response): Promise<void> {
    try {
      const { page = 1, limit = 20, status, category_id, author_id, search } = req.query;
      
      const options = {
        page: Number(page),
        limit: Number(limit),
        status: status as string,
        categoryId: category_id as string,
        authorId: author_id as string,
        search: search as string
      };

      const result = await this.articleRepository.findWithPagination(options);
      
      res.json({
        success: true,
        data: result.items,
        pagination: {
          page: result.page,
          limit: result.limit,
          total: result.total,
          totalPages: result.totalPages
        }
      });
    } catch (error) {
      this.logger.error('Error fetching articles:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch articles'
      });
    }
  }

  async getArticleById(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const article = await this.articleRepository.findById(id);
      
      if (!article) {
        res.status(404).json({
          success: false,
          message: 'Article not found'
        });
        return;
      }

      res.json({
        success: true,
        data: article
      });
    } catch (error) {
      this.logger.error('Error fetching article:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch article'
      });
    }
  }

  async createArticle(req: Request, res: Response): Promise<void> {
    try {
      const adminUser = (req as any).user;
      const {
        title,
        slug,
        summary,
        content,
        category_id,
        featured_image_url,
        status = 'draft',
        is_featured = false,
        is_premium = false,
        difficulty_level = 1,
        content_type = 'article',
        seo_title,
        seo_description,
        seo_keywords,
        tags = []
      } = req.body;

      // Calculate word count and reading time
      const wordCount = content.split(/\s+/).length;
      const estimatedReadingTime = Math.ceil(wordCount / 200); // 200 words per minute

      const article = new Article({
        id: uuidv4(),
        title,
        slug: slug || this.generateSlug(title),
        summary,
        content,
        author_id: adminUser.userId,
        author_name: adminUser.name || adminUser.email,
        category_id,
        featured_image_url,
        word_count: wordCount,
        estimated_reading_time: estimatedReadingTime,
        difficulty_level,
        content_type,
        status,
        is_featured,
        is_premium,
        published_at: status === 'published' ? new Date() : null,
        seo_title: seo_title || title,
        seo_description: seo_description || summary,
        seo_keywords,
        created_at: new Date(),
        updated_at: new Date()
      });

      const savedArticle = await this.articleRepository.save(article);

      // Handle tags
      if (tags.length > 0) {
        await this.articleRepository.syncTags(savedArticle.id, tags);
      }

      res.status(201).json({
        success: true,
        data: savedArticle,
        message: 'Article created successfully'
      });
    } catch (error) {
      this.logger.error('Error creating article:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to create article'
      });
    }
  }

  async updateArticle(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const adminUser = (req as any).user;
      
      const existingArticle = await this.articleRepository.findById(id);
      if (!existingArticle) {
        res.status(404).json({
          success: false,
          message: 'Article not found'
        });
        return;
      }

      const {
        title,
        slug,
        summary,
        content,
        category_id,
        featured_image_url,
        status,
        is_featured,
        is_premium,
        difficulty_level,
        content_type,
        seo_title,
        seo_description,
        seo_keywords,
        tags
      } = req.body;

      // Recalculate word count and reading time if content changed
      let wordCount = existingArticle.word_count;
      let estimatedReadingTime = existingArticle.estimated_reading_time;
      
      if (content && content !== existingArticle.content) {
        wordCount = content.split(/\s+/).length;
        estimatedReadingTime = Math.ceil(wordCount / 200);
      }

      const updatedArticle = {
        ...existingArticle,
        title: title || existingArticle.title,
        slug: slug || existingArticle.slug,
        summary: summary || existingArticle.summary,
        content: content || existingArticle.content,
        category_id: category_id || existingArticle.category_id,
        featured_image_url: featured_image_url !== undefined ? featured_image_url : existingArticle.featured_image_url,
        word_count: wordCount,
        estimated_reading_time: estimatedReadingTime,
        difficulty_level: difficulty_level || existingArticle.difficulty_level,
        content_type: content_type || existingArticle.content_type,
        status: status || existingArticle.status,
        is_featured: is_featured !== undefined ? is_featured : existingArticle.is_featured,
        is_premium: is_premium !== undefined ? is_premium : existingArticle.is_premium,
        published_at: status === 'published' && !existingArticle.published_at ? new Date() : existingArticle.published_at,
        seo_title: seo_title || existingArticle.seo_title,
        seo_description: seo_description || existingArticle.seo_description,
        seo_keywords: seo_keywords || existingArticle.seo_keywords,
        updated_at: new Date()
      };

      const savedArticle = await this.articleRepository.update(id, updatedArticle);

      // Handle tags if provided
      if (tags !== undefined) {
        await this.articleRepository.syncTags(id, tags);
      }

      res.json({
        success: true,
        data: savedArticle,
        message: 'Article updated successfully'
      });
    } catch (error) {
      this.logger.error('Error updating article:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to update article'
      });
    }
  }

  async deleteArticle(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const { permanent = false } = req.query;
      
      const article = await this.articleRepository.findById(id);
      if (!article) {
        res.status(404).json({
          success: false,
          message: 'Article not found'
        });
        return;
      }

      if (permanent === 'true') {
        // Permanent delete
        await this.articleRepository.delete(id);
        res.json({
          success: true,
          message: 'Article permanently deleted'
        });
      } else {
        // Soft delete - update status to 'deleted'
        await this.articleRepository.update(id, {
          ...article,
          status: 'deleted',
          updated_at: new Date()
        });
        res.json({
          success: true,
          message: 'Article moved to trash'
        });
      }
    } catch (error) {
      this.logger.error('Error deleting article:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to delete article'
      });
    }
  }

  async getCategories(req: Request, res: Response): Promise<void> {
    try {
      const categories = await this.categoryRepository.findAll();
      res.json({
        success: true,
        data: categories
      });
    } catch (error) {
      this.logger.error('Error fetching categories:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch categories'
      });
    }
  }

  async getTags(req: Request, res: Response): Promise<void> {
    try {
      const { search } = req.query;
      const tags = await this.tagRepository.search(search as string);
      res.json({
        success: true,
        data: tags
      });
    } catch (error) {
      this.logger.error('Error fetching tags:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch tags'
      });
    }
  }

  async publishArticle(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      
      const article = await this.articleRepository.findById(id);
      if (!article) {
        res.status(404).json({
          success: false,
          message: 'Article not found'
        });
        return;
      }

      const updatedArticle = await this.articleRepository.update(id, {
        ...article,
        status: 'published',
        published_at: new Date(),
        updated_at: new Date()
      });

      res.json({
        success: true,
        data: updatedArticle,
        message: 'Article published successfully'
      });
    } catch (error) {
      this.logger.error('Error publishing article:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to publish article'
      });
    }
  }

  async unpublishArticle(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      
      const article = await this.articleRepository.findById(id);
      if (!article) {
        res.status(404).json({
          success: false,
          message: 'Article not found'
        });
        return;
      }

      const updatedArticle = await this.articleRepository.update(id, {
        ...article,
        status: 'draft',
        updated_at: new Date()
      });

      res.json({
        success: true,
        data: updatedArticle,
        message: 'Article unpublished successfully'
      });
    } catch (error) {
      this.logger.error('Error unpublishing article:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to unpublish article'
      });
    }
  }

  private generateSlug(title: string): string {
    return title
      .toLowerCase()
      .replace(/[^\w\s-]/g, '')
      .replace(/\s+/g, '-')
      .replace(/--+/g, '-')
      .trim();
  }
}