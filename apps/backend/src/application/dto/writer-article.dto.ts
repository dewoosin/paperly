export interface CreateArticleDto {
  title: string;
  subtitle?: string;
  content: string;
  excerpt?: string;
  categoryId?: string;
  featuredImageUrl?: string;
  featuredImageAlt?: string;
  seoTitle?: string;
  seoDescription?: string;
  seoKeywords?: string;
  visibility?: 'public' | 'private' | 'unlisted';
  isPremium?: boolean;
  difficultyLevel?: number;
  contentType?: string;
  scheduledAt?: Date;
  metadata?: Record<string, any>;
}

export interface UpdateArticleDto {
  title?: string;
  subtitle?: string;
  content?: string;
  excerpt?: string;
  categoryId?: string;
  featuredImageUrl?: string;
  featuredImageAlt?: string;
  seoTitle?: string;
  seoDescription?: string;
  seoKeywords?: string;
  visibility?: 'public' | 'private' | 'unlisted';
  isPremium?: boolean;
  difficultyLevel?: number;
  contentType?: string;
  scheduledAt?: Date;
  metadata?: Record<string, any>;
}

export interface PublishArticleDto {
  publishedAt?: Date;
  scheduledAt?: Date;
}

export interface ArticleStatusDto {
  status: 'draft' | 'review' | 'published' | 'archived' | 'deleted';
  reason?: string;
}

export interface WriterArticleResponseDto {
  id: string;
  title: string;
  subtitle?: string;
  slug: string;
  content: string;
  excerpt?: string;
  authorId: string;
  authorName?: string;
  categoryId?: string;
  featuredImageUrl?: string;
  featuredImageAlt?: string;
  status: string;
  visibility: string;
  wordCount: number;
  readingTimeMinutes?: number;
  difficultyLevel: number;
  contentType: string;
  isPremium: boolean;
  isFeatured: boolean;
  seoTitle?: string;
  seoDescription?: string;
  seoKeywords?: string;
  viewCount: number;
  likeCount: number;
  shareCount: number;
  commentCount: number;
  createdAt: Date;
  updatedAt: Date;
  publishedAt?: Date;
  scheduledAt?: Date;
  metadata?: Record<string, any>;
}

export interface WriterArticleListDto {
  id: string;
  title: string;
  subtitle?: string;
  slug: string;
  excerpt?: string;
  status: string;
  visibility: string;
  wordCount: number;
  readingTimeMinutes?: number;
  isPremium: boolean;
  isFeatured: boolean;
  viewCount: number;
  likeCount: number;
  shareCount: number;
  commentCount: number;
  createdAt: Date;
  updatedAt: Date;
  publishedAt?: Date;
  scheduledAt?: Date;
}

export interface WriterArticleStatsDto {
  totalArticles: number;
  publishedArticles: number;
  draftArticles: number;
  archivedArticles: number;
  totalViews: number;
  totalLikes: number;
  totalShares: number;
  totalComments: number;
  averageReadingTime: number;
  topPerformingArticles: WriterArticleListDto[];
  recentArticles: WriterArticleListDto[];
}

export interface ArticleValidationError {
  field: string;
  message: string;
  code: string;
}