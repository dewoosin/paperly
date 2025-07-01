import { ArticleValidationError } from '../dto/writer-article.dto';

export class WriterArticleValidator {
  static validateCreateArticle(data: any): ArticleValidationError[] {
    const errors: ArticleValidationError[] = [];

    // Title validation
    if (!data.title) {
      errors.push({
        field: 'title',
        message: 'Title is required',
        code: 'TITLE_REQUIRED'
      });
    } else if (typeof data.title !== 'string') {
      errors.push({
        field: 'title',
        message: 'Title must be a string',
        code: 'TITLE_INVALID_TYPE'
      });
    } else if (data.title.trim().length === 0) {
      errors.push({
        field: 'title',
        message: 'Title cannot be empty',
        code: 'TITLE_EMPTY'
      });
    } else if (data.title.length > 200) {
      errors.push({
        field: 'title',
        message: 'Title must be 200 characters or less',
        code: 'TITLE_TOO_LONG'
      });
    }

    // Content validation
    if (!data.content) {
      errors.push({
        field: 'content',
        message: 'Content is required',
        code: 'CONTENT_REQUIRED'
      });
    } else if (typeof data.content !== 'string') {
      errors.push({
        field: 'content',
        message: 'Content must be a string',
        code: 'CONTENT_INVALID_TYPE'
      });
    } else if (data.content.trim().length === 0) {
      errors.push({
        field: 'content',
        message: 'Content cannot be empty',
        code: 'CONTENT_EMPTY'
      });
    } else if (data.content.length > 50000) {
      errors.push({
        field: 'content',
        message: 'Content must be 50,000 characters or less',
        code: 'CONTENT_TOO_LONG'
      });
    }

    // Optional field validations
    if (data.subtitle && typeof data.subtitle !== 'string') {
      errors.push({
        field: 'subtitle',
        message: 'Subtitle must be a string',
        code: 'SUBTITLE_INVALID_TYPE'
      });
    } else if (data.subtitle && data.subtitle.length > 1000) {
      errors.push({
        field: 'subtitle',
        message: 'Subtitle must be 1000 characters or less',
        code: 'SUBTITLE_TOO_LONG'
      });
    }

    if (data.excerpt && typeof data.excerpt !== 'string') {
      errors.push({
        field: 'excerpt',
        message: 'Excerpt must be a string',
        code: 'EXCERPT_INVALID_TYPE'
      });
    } else if (data.excerpt && data.excerpt.length > 500) {
      errors.push({
        field: 'excerpt',
        message: 'Excerpt must be 500 characters or less',
        code: 'EXCERPT_TOO_LONG'
      });
    }

    // Category ID validation
    if (data.categoryId && typeof data.categoryId !== 'string') {
      errors.push({
        field: 'categoryId',
        message: 'Category ID must be a string',
        code: 'CATEGORY_ID_INVALID_TYPE'
      });
    } else if (data.categoryId && !this.isValidUUID(data.categoryId)) {
      errors.push({
        field: 'categoryId',
        message: 'Category ID must be a valid UUID',
        code: 'CATEGORY_ID_INVALID_FORMAT'
      });
    }

    // Featured image validation
    if (data.featuredImageUrl && typeof data.featuredImageUrl !== 'string') {
      errors.push({
        field: 'featuredImageUrl',
        message: 'Featured image URL must be a string',
        code: 'FEATURED_IMAGE_URL_INVALID_TYPE'
      });
    } else if (data.featuredImageUrl && !this.isValidUrl(data.featuredImageUrl)) {
      errors.push({
        field: 'featuredImageUrl',
        message: 'Featured image URL must be a valid URL',
        code: 'FEATURED_IMAGE_URL_INVALID_FORMAT'
      });
    }

    if (data.featuredImageAlt && typeof data.featuredImageAlt !== 'string') {
      errors.push({
        field: 'featuredImageAlt',
        message: 'Featured image alt text must be a string',
        code: 'FEATURED_IMAGE_ALT_INVALID_TYPE'
      });
    }

    // SEO fields validation
    if (data.seoTitle && typeof data.seoTitle !== 'string') {
      errors.push({
        field: 'seoTitle',
        message: 'SEO title must be a string',
        code: 'SEO_TITLE_INVALID_TYPE'
      });
    } else if (data.seoTitle && data.seoTitle.length > 100) {
      errors.push({
        field: 'seoTitle',
        message: 'SEO title must be 100 characters or less',
        code: 'SEO_TITLE_TOO_LONG'
      });
    }

    if (data.seoDescription && typeof data.seoDescription !== 'string') {
      errors.push({
        field: 'seoDescription',
        message: 'SEO description must be a string',
        code: 'SEO_DESCRIPTION_INVALID_TYPE'
      });
    } else if (data.seoDescription && data.seoDescription.length > 200) {
      errors.push({
        field: 'seoDescription',
        message: 'SEO description must be 200 characters or less',
        code: 'SEO_DESCRIPTION_TOO_LONG'
      });
    }

    // Visibility validation
    if (data.visibility && !['public', 'private', 'unlisted'].includes(data.visibility)) {
      errors.push({
        field: 'visibility',
        message: 'Visibility must be public, private, or unlisted',
        code: 'VISIBILITY_INVALID_VALUE'
      });
    }

    // Boolean field validations
    if (data.isPremium !== undefined && typeof data.isPremium !== 'boolean') {
      errors.push({
        field: 'isPremium',
        message: 'isPremium must be a boolean',
        code: 'IS_PREMIUM_INVALID_TYPE'
      });
    }

    // Difficulty level validation
    if (data.difficultyLevel !== undefined) {
      if (typeof data.difficultyLevel !== 'number') {
        errors.push({
          field: 'difficultyLevel',
          message: 'Difficulty level must be a number',
          code: 'DIFFICULTY_LEVEL_INVALID_TYPE'
        });
      } else if (data.difficultyLevel < 1 || data.difficultyLevel > 5) {
        errors.push({
          field: 'difficultyLevel',
          message: 'Difficulty level must be between 1 and 5',
          code: 'DIFFICULTY_LEVEL_OUT_OF_RANGE'
        });
      }
    }

    // Scheduled date validation
    if (data.scheduledAt) {
      const scheduledDate = new Date(data.scheduledAt);
      if (isNaN(scheduledDate.getTime())) {
        errors.push({
          field: 'scheduledAt',
          message: 'Scheduled date must be a valid date',
          code: 'SCHEDULED_AT_INVALID_DATE'
        });
      } else if (scheduledDate <= new Date()) {
        errors.push({
          field: 'scheduledAt',
          message: 'Scheduled date must be in the future',
          code: 'SCHEDULED_AT_PAST_DATE'
        });
      }
    }

    // Metadata validation
    if (data.metadata !== undefined && typeof data.metadata !== 'object') {
      errors.push({
        field: 'metadata',
        message: 'Metadata must be an object',
        code: 'METADATA_INVALID_TYPE'
      });
    }

    return errors;
  }

  static validateUpdateArticle(data: any): ArticleValidationError[] {
    const errors: ArticleValidationError[] = [];

    // For updates, all fields are optional, but if provided, they must be valid
    if (data.title !== undefined) {
      if (typeof data.title !== 'string') {
        errors.push({
          field: 'title',
          message: 'Title must be a string',
          code: 'TITLE_INVALID_TYPE'
        });
      } else if (data.title.trim().length === 0) {
        errors.push({
          field: 'title',
          message: 'Title cannot be empty',
          code: 'TITLE_EMPTY'
        });
      } else if (data.title.length > 200) {
        errors.push({
          field: 'title',
          message: 'Title must be 200 characters or less',
          code: 'TITLE_TOO_LONG'
        });
      }
    }

    if (data.content !== undefined) {
      if (typeof data.content !== 'string') {
        errors.push({
          field: 'content',
          message: 'Content must be a string',
          code: 'CONTENT_INVALID_TYPE'
        });
      } else if (data.content.trim().length === 0) {
        errors.push({
          field: 'content',
          message: 'Content cannot be empty',
          code: 'CONTENT_EMPTY'
        });
      } else if (data.content.length > 50000) {
        errors.push({
          field: 'content',
          message: 'Content must be 50,000 characters or less',
          code: 'CONTENT_TOO_LONG'
        });
      }
    }

    // Apply the same validation logic for optional fields as in create validation
    if (data.subtitle !== undefined && typeof data.subtitle !== 'string') {
      errors.push({
        field: 'subtitle',
        message: 'Subtitle must be a string',
        code: 'SUBTITLE_INVALID_TYPE'
      });
    } else if (data.subtitle && data.subtitle.length > 1000) {
      errors.push({
        field: 'subtitle',
        message: 'Subtitle must be 1000 characters or less',
        code: 'SUBTITLE_TOO_LONG'
      });
    }

    if (data.excerpt !== undefined && typeof data.excerpt !== 'string') {
      errors.push({
        field: 'excerpt',
        message: 'Excerpt must be a string',
        code: 'EXCERPT_INVALID_TYPE'
      });
    } else if (data.excerpt && data.excerpt.length > 500) {
      errors.push({
        field: 'excerpt',
        message: 'Excerpt must be 500 characters or less',
        code: 'EXCERPT_TOO_LONG'
      });
    }

    if (data.categoryId !== undefined) {
      if (typeof data.categoryId !== 'string') {
        errors.push({
          field: 'categoryId',
          message: 'Category ID must be a string',
          code: 'CATEGORY_ID_INVALID_TYPE'
        });
      } else if (!this.isValidUUID(data.categoryId)) {
        errors.push({
          field: 'categoryId',
          message: 'Category ID must be a valid UUID',
          code: 'CATEGORY_ID_INVALID_FORMAT'
        });
      }
    }

    if (data.visibility !== undefined && !['public', 'private', 'unlisted'].includes(data.visibility)) {
      errors.push({
        field: 'visibility',
        message: 'Visibility must be public, private, or unlisted',
        code: 'VISIBILITY_INVALID_VALUE'
      });
    }

    if (data.difficultyLevel !== undefined) {
      if (typeof data.difficultyLevel !== 'number') {
        errors.push({
          field: 'difficultyLevel',
          message: 'Difficulty level must be a number',
          code: 'DIFFICULTY_LEVEL_INVALID_TYPE'
        });
      } else if (data.difficultyLevel < 1 || data.difficultyLevel > 5) {
        errors.push({
          field: 'difficultyLevel',
          message: 'Difficulty level must be between 1 and 5',
          code: 'DIFFICULTY_LEVEL_OUT_OF_RANGE'
        });
      }
    }

    if (data.scheduledAt !== undefined) {
      const scheduledDate = new Date(data.scheduledAt);
      if (isNaN(scheduledDate.getTime())) {
        errors.push({
          field: 'scheduledAt',
          message: 'Scheduled date must be a valid date',
          code: 'SCHEDULED_AT_INVALID_DATE'
        });
      } else if (scheduledDate <= new Date()) {
        errors.push({
          field: 'scheduledAt',
          message: 'Scheduled date must be in the future',
          code: 'SCHEDULED_AT_PAST_DATE'
        });
      }
    }

    return errors;
  }

  static validatePublishArticle(data: any): ArticleValidationError[] {
    const errors: ArticleValidationError[] = [];

    if (data.publishedAt !== undefined) {
      const publishedDate = new Date(data.publishedAt);
      if (isNaN(publishedDate.getTime())) {
        errors.push({
          field: 'publishedAt',
          message: 'Published date must be a valid date',
          code: 'PUBLISHED_AT_INVALID_DATE'
        });
      }
    }

    if (data.scheduledAt !== undefined) {
      const scheduledDate = new Date(data.scheduledAt);
      if (isNaN(scheduledDate.getTime())) {
        errors.push({
          field: 'scheduledAt',
          message: 'Scheduled date must be a valid date',
          code: 'SCHEDULED_AT_INVALID_DATE'
        });
      }
    }

    return errors;
  }

  static validateStatusChange(data: any): ArticleValidationError[] {
    const errors: ArticleValidationError[] = [];

    if (!data.status) {
      errors.push({
        field: 'status',
        message: 'Status is required',
        code: 'STATUS_REQUIRED'
      });
    } else if (!['draft', 'review', 'published', 'archived', 'deleted'].includes(data.status)) {
      errors.push({
        field: 'status',
        message: 'Status must be draft, review, published, archived, or deleted',
        code: 'STATUS_INVALID_VALUE'
      });
    }

    if (data.reason && typeof data.reason !== 'string') {
      errors.push({
        field: 'reason',
        message: 'Reason must be a string',
        code: 'REASON_INVALID_TYPE'
      });
    }

    return errors;
  }

  private static isValidUUID(uuid: string): boolean {
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    return uuidRegex.test(uuid);
  }

  private static isValidUrl(url: string): boolean {
    try {
      new URL(url);
      return true;
    } catch {
      return false;
    }
  }

  static calculateWordCount(content: string): number {
    // Remove HTML tags and count words
    const plainText = content.replace(/<[^>]*>/g, '');
    const words = plainText.trim().split(/\s+/);
    return words.length > 0 && words[0] !== '' ? words.length : 0;
  }

  static calculateReadingTime(wordCount: number): number {
    // Average reading speed is 200-250 words per minute
    const wordsPerMinute = 225;
    return Math.ceil(wordCount / wordsPerMinute);
  }

  static generateSlug(title: string): string {
    return title
      .toLowerCase()
      .trim()
      .replace(/[^\w\s-]/g, '') // Remove special characters
      .replace(/\s+/g, '-') // Replace spaces with hyphens
      .replace(/-+/g, '-') // Replace multiple hyphens with single hyphen
      .substring(0, 200); // Limit length
  }
}