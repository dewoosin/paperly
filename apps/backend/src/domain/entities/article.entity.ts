// /Users/workspace/paperly/apps/backend/src/domain/entities/article.entity.ts

import { v4 as uuidv4 } from 'uuid';

export enum ArticleStatus {
  DRAFT = 'draft',
  REVIEW = 'review', 
  PUBLISHED = 'published',
  ARCHIVED = 'archived',
  DELETED = 'deleted'
}

export enum ArticleVisibility {
  PUBLIC = 'public',
  PRIVATE = 'private',
  UNLISTED = 'unlisted'
}

export enum ReadingLevel {
  BEGINNER = 'beginner',
  INTERMEDIATE = 'intermediate', 
  ADVANCED = 'advanced'
}

export enum Sentiment {
  POSITIVE = 'positive',
  NEUTRAL = 'neutral',
  NEGATIVE = 'negative'
}

export interface ArticleMetadata {
  readingProgress?: number;
  estimatedReadingTime?: number;
  keyPoints?: string[];
  relatedTopics?: string[];
  difficulty?: number;
  [key: string]: any;
}

export interface CreateArticleProps {
  title: string;
  slug?: string;
  subtitle?: string;
  excerpt?: string;
  content: string;
  contentHtml?: string;
  featuredImageUrl?: string;
  featuredImageAlt?: string;
  authorId: string;
  categoryId?: string;
  tagIds?: string[];
  status?: ArticleStatus;
  visibility?: ArticleVisibility;
  seoTitle?: string;
  seoDescription?: string;
  scheduledAt?: Date;
  metadata?: ArticleMetadata;
}

export interface UpdateArticleProps {
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
  metadata?: ArticleMetadata;
  editorId?: string;
}

export class Article {
  private constructor(
    private readonly _id: string,
    private _title: string,
    private _slug: string,
    private _subtitle: string | null,
    private _excerpt: string | null,
    private _content: string,
    private _contentHtml: string | null,
    private _featuredImageUrl: string | null,
    private _featuredImageAlt: string | null,
    private _readingTimeMinutes: number | null,
    private _wordCount: number | null,
    private _status: ArticleStatus,
    private _visibility: ArticleVisibility,
    private _authorId: string,
    private _editorId: string | null,
    private _categoryId: string | null,
    private _seoTitle: string | null,
    private _seoDescription: string | null,
    private _viewCount: number,
    private _likeCount: number,
    private _shareCount: number,
    private _commentCount: number,
    private _isFeatured: boolean,
    private _featuredAt: Date | null,
    private _isTrending: boolean,
    private _trendingScore: number,
    private _aiSummary: string | null,
    private _aiTags: string[],
    private _aiReadingLevel: ReadingLevel | null,
    private _aiSentiment: Sentiment | null,
    private _scheduledAt: Date | null,
    private _publishedAt: Date | null,
    private _metadata: ArticleMetadata,
    private _createdAt: Date,
    private _updatedAt: Date,
    private _deletedAt: Date | null
  ) {}

  // Getters
  get id(): string { return this._id; }
  get title(): string { return this._title; }
  get slug(): string { return this._slug; }
  get subtitle(): string | null { return this._subtitle; }
  get excerpt(): string | null { return this._excerpt; }
  get content(): string { return this._content; }
  get contentHtml(): string | null { return this._contentHtml; }
  get featuredImageUrl(): string | null { return this._featuredImageUrl; }
  get featuredImageAlt(): string | null { return this._featuredImageAlt; }
  get readingTimeMinutes(): number | null { return this._readingTimeMinutes; }
  get wordCount(): number | null { return this._wordCount; }
  get status(): ArticleStatus { return this._status; }
  get visibility(): ArticleVisibility { return this._visibility; }
  get authorId(): string { return this._authorId; }
  get editorId(): string | null { return this._editorId; }
  get categoryId(): string | null { return this._categoryId; }
  get seoTitle(): string | null { return this._seoTitle; }
  get seoDescription(): string | null { return this._seoDescription; }
  get viewCount(): number { return this._viewCount; }
  get likeCount(): number { return this._likeCount; }
  get shareCount(): number { return this._shareCount; }
  get commentCount(): number { return this._commentCount; }
  get isFeatured(): boolean { return this._isFeatured; }
  get featuredAt(): Date | null { return this._featuredAt; }
  get isTrending(): boolean { return this._isTrending; }
  get trendingScore(): number { return this._trendingScore; }
  get aiSummary(): string | null { return this._aiSummary; }
  get aiTags(): string[] { return this._aiTags; }
  get aiReadingLevel(): ReadingLevel | null { return this._aiReadingLevel; }
  get aiSentiment(): Sentiment | null { return this._aiSentiment; }
  get scheduledAt(): Date | null { return this._scheduledAt; }
  get publishedAt(): Date | null { return this._publishedAt; }
  get metadata(): ArticleMetadata { return this._metadata; }
  get createdAt(): Date { return this._createdAt; }
  get updatedAt(): Date { return this._updatedAt; }
  get deletedAt(): Date | null { return this._deletedAt; }

  // Factory methods
  static create(props: CreateArticleProps): Article {
    const now = new Date();
    const slug = props.slug || this.generateSlug(props.title);
    const wordCount = this.calculateWordCount(props.content);
    const readingTime = this.calculateReadingTime(wordCount);

    return new Article(
      uuidv4(),
      props.title,
      slug,
      props.subtitle || null,
      props.excerpt || null,
      props.content,
      props.contentHtml || null,
      props.featuredImageUrl || null,
      props.featuredImageAlt || null,
      readingTime,
      wordCount,
      props.status || ArticleStatus.DRAFT,
      props.visibility || ArticleVisibility.PUBLIC,
      props.authorId,
      null, // editorId
      props.categoryId || null,
      props.seoTitle || null,
      props.seoDescription || null,
      0, // viewCount
      0, // likeCount
      0, // shareCount
      0, // commentCount
      false, // isFeatured
      null, // featuredAt
      false, // isTrending
      0, // trendingScore
      null, // aiSummary
      [], // aiTags
      null, // aiReadingLevel
      null, // aiSentiment
      props.scheduledAt || null,
      null, // publishedAt
      props.metadata || {},
      now,
      now,
      null // deletedAt
    );
  }

  static fromPersistence(data: any): Article {
    return new Article(
      data.id,
      data.title,
      data.slug,
      data.subtitle,
      data.excerpt,
      data.content,
      data.content_html,
      data.featured_image_url,
      data.featured_image_alt,
      data.estimated_reading_time || data.reading_time_minutes,
      data.word_count,
      data.status || ArticleStatus.DRAFT,
      data.visibility || ArticleVisibility.PUBLIC,
      data.author_id || data.author_name, // 호환성
      data.editor_id,
      data.category_id,
      data.seo_title,
      data.seo_description,
      data.view_count || 0,
      data.like_count || 0,
      data.share_count || 0,
      data.comment_count || 0,
      data.is_featured || false,
      data.featured_at,
      data.is_trending || false,
      data.trending_score || 0,
      data.ai_summary,
      data.ai_tags || [],
      data.ai_reading_level,
      data.ai_sentiment,
      data.scheduled_at,
      data.published_at,
      data.metadata || {},
      data.created_at,
      data.updated_at,
      data.deleted_at
    );
  }

  // Business methods
  update(props: UpdateArticleProps): void {
    if (props.title !== undefined) {
      this._title = props.title;
      if (props.slug === undefined) {
        this._slug = Article.generateSlug(props.title);
      }
    }
    
    if (props.slug !== undefined) this._slug = props.slug;
    if (props.subtitle !== undefined) this._subtitle = props.subtitle;
    if (props.excerpt !== undefined) this._excerpt = props.excerpt;
    
    if (props.content !== undefined) {
      this._content = props.content;
      this._wordCount = Article.calculateWordCount(props.content);
      this._readingTimeMinutes = Article.calculateReadingTime(this._wordCount);
    }
    
    if (props.contentHtml !== undefined) this._contentHtml = props.contentHtml;
    if (props.featuredImageUrl !== undefined) this._featuredImageUrl = props.featuredImageUrl;
    if (props.featuredImageAlt !== undefined) this._featuredImageAlt = props.featuredImageAlt;
    if (props.categoryId !== undefined) this._categoryId = props.categoryId;
    if (props.status !== undefined) this._status = props.status;
    if (props.visibility !== undefined) this._visibility = props.visibility;
    if (props.seoTitle !== undefined) this._seoTitle = props.seoTitle;
    if (props.seoDescription !== undefined) this._seoDescription = props.seoDescription;
    if (props.scheduledAt !== undefined) this._scheduledAt = props.scheduledAt;
    if (props.metadata !== undefined) this._metadata = { ...this._metadata, ...props.metadata };
    if (props.editorId !== undefined) this._editorId = props.editorId;
    
    this._updatedAt = new Date();
  }

  publish(): void {
    if (this._status === ArticleStatus.DELETED) {
      throw new Error('삭제된 기사는 발행할 수 없습니다.');
    }
    
    this._status = ArticleStatus.PUBLISHED;
    this._publishedAt = new Date();
    this._updatedAt = new Date();
  }

  unpublish(): void {
    this._status = ArticleStatus.DRAFT;
    this._publishedAt = null;
    this._updatedAt = new Date();
  }

  archive(): void {
    this._status = ArticleStatus.ARCHIVED;
    this._updatedAt = new Date();
  }

  softDelete(): void {
    this._status = ArticleStatus.DELETED;
    this._deletedAt = new Date();
    this._updatedAt = new Date();
  }

  restore(): void {
    if (this._status !== ArticleStatus.DELETED) {
      throw new Error('삭제되지 않은 기사는 복원할 수 없습니다.');
    }
    
    this._status = ArticleStatus.DRAFT;
    this._deletedAt = null;
    this._updatedAt = new Date();
  }

  feature(): void {
    this._isFeatured = true;
    this._featuredAt = new Date();
    this._updatedAt = new Date();
  }

  unfeature(): void {
    this._isFeatured = false;
    this._featuredAt = null;
    this._updatedAt = new Date();
  }

  incrementViewCount(): void {
    this._viewCount++;
    this._updatedAt = new Date();
  }

  incrementLikeCount(): void {
    this._likeCount++;
    this._updatedAt = new Date();
  }

  incrementShareCount(): void {
    this._shareCount++;
    this._updatedAt = new Date();
  }

  updateTrendingScore(score: number): void {
    this._trendingScore = score;
    this._isTrending = score > 0;
    this._updatedAt = new Date();
  }

  updateAiAnalysis(summary: string, tags: string[], readingLevel: ReadingLevel, sentiment: Sentiment): void {
    this._aiSummary = summary;
    this._aiTags = tags;
    this._aiReadingLevel = readingLevel;
    this._aiSentiment = sentiment;
    this._updatedAt = new Date();
  }

  // Validation methods
  canBeEditedBy(userId: string): boolean {
    return this._authorId === userId || this._editorId === userId;
  }

  canBePublished(): boolean {
    return this._status === ArticleStatus.DRAFT || this._status === ArticleStatus.REVIEW;
  }

  isPublished(): boolean {
    return this._status === ArticleStatus.PUBLISHED && this._publishedAt !== null;
  }

  isScheduled(): boolean {
    return this._scheduledAt !== null && this._scheduledAt > new Date();
  }

  isDraft(): boolean {
    return this._status === ArticleStatus.DRAFT;
  }

  isDeleted(): boolean {
    return this._status === ArticleStatus.DELETED || this._deletedAt !== null;
  }

  // Utility methods
  private static generateSlug(title: string): string {
    return title
      .toLowerCase()
      .replace(/[^a-z0-9가-힣\s-]/g, '')
      .replace(/\s+/g, '-')
      .replace(/-+/g, '-')
      .trim()
      .substring(0, 100);
  }

  private static calculateWordCount(content: string): number {
    // HTML 태그 제거 후 단어 수 계산
    const plainText = content.replace(/<[^>]*>/g, '');
    const words = plainText.trim().split(/\s+/);
    return words.length;
  }

  private static calculateReadingTime(wordCount: number): number {
    // 분당 200단어 기준
    return Math.ceil(wordCount / 200);
  }

  // Persistence methods
  toPersistence(): any {
    return {
      id: this._id,
      title: this._title,
      slug: this._slug,
      subtitle: this._subtitle,
      excerpt: this._excerpt,
      content: this._content,
      content_html: this._contentHtml,
      featured_image_url: this._featuredImageUrl,
      featured_image_alt: this._featuredImageAlt,
      reading_time_minutes: this._readingTimeMinutes,
      word_count: this._wordCount,
      status: this._status,
      visibility: this._visibility,
      author_id: this._authorId,
      editor_id: this._editorId,
      category_id: this._categoryId,
      seo_title: this._seoTitle,
      seo_description: this._seoDescription,
      view_count: this._viewCount,
      like_count: this._likeCount,
      share_count: this._shareCount,
      comment_count: this._commentCount,
      is_featured: this._isFeatured,
      featured_at: this._featuredAt,
      is_trending: this._isTrending,
      trending_score: this._trendingScore,
      ai_summary: this._aiSummary,
      ai_tags: JSON.stringify(this._aiTags),
      ai_reading_level: this._aiReadingLevel,
      ai_sentiment: this._aiSentiment,
      scheduled_at: this._scheduledAt,
      published_at: this._publishedAt,
      metadata: JSON.stringify(this._metadata),
      created_at: this._createdAt,
      updated_at: this._updatedAt,
      deleted_at: this._deletedAt
    };
  }

  toResponse(): any {
    return {
      id: this._id,
      title: this._title,
      slug: this._slug,
      subtitle: this._subtitle,
      excerpt: this._excerpt,
      content: this._content,
      contentHtml: this._contentHtml,
      featuredImageUrl: this._featuredImageUrl,
      featuredImageAlt: this._featuredImageAlt,
      readingTimeMinutes: this._readingTimeMinutes,
      wordCount: this._wordCount,
      status: this._status,
      visibility: this._visibility,
      authorId: this._authorId,
      editorId: this._editorId,
      categoryId: this._categoryId,
      seoTitle: this._seoTitle,
      seoDescription: this._seoDescription,
      viewCount: this._viewCount,
      likeCount: this._likeCount,
      shareCount: this._shareCount,
      commentCount: this._commentCount,
      isFeatured: this._isFeatured,
      featuredAt: this._featuredAt,
      isTrending: this._isTrending,
      trendingScore: this._trendingScore,
      aiSummary: this._aiSummary,
      aiTags: this._aiTags,
      aiReadingLevel: this._aiReadingLevel,
      aiSentiment: this._aiSentiment,
      scheduledAt: this._scheduledAt,
      publishedAt: this._publishedAt,
      metadata: this._metadata,
      createdAt: this._createdAt,
      updatedAt: this._updatedAt,
      deletedAt: this._deletedAt
    };
  }
}