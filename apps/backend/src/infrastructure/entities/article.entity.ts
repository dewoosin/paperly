// /Users/workspace/paperly/apps/backend/src/infrastructure/entities/article.entity.ts

import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  ManyToMany,
  JoinTable,
  Index,
} from 'typeorm';
import { UserEntity } from './user.entity';
import { CategoryEntity } from './category.entity';
import { TagEntity } from './tag.entity';

@Entity({ schema: 'paperly', name: 'articles' })
@Index(['status'])
@Index(['authorId'])
@Index(['categoryId'])
@Index(['publishedAt'])
@Index(['slug'])
export class ArticleEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 500 })
  title: string;

  @Column({ length: 100, unique: true })
  slug: string;

  @Column({ length: 1000, nullable: true })
  subtitle?: string;

  @Column({ type: 'text', nullable: true })
  excerpt?: string;

  @Column({ type: 'text' })
  content: string;

  @Column({ name: 'content_html', type: 'text', nullable: true })
  contentHtml?: string;

  @Column({ name: 'featured_image_url', nullable: true })
  featuredImageUrl?: string;

  @Column({ name: 'featured_image_alt', nullable: true })
  featuredImageAlt?: string;

  @Column({ name: 'reading_time_minutes', nullable: true })
  readingTimeMinutes?: number;

  @Column({ name: 'word_count', nullable: true })
  wordCount?: number;

  @Column({ length: 20, default: 'draft' })
  status: string;

  @Column({ length: 20, default: 'public' })
  visibility: string;

  @Column({ name: 'author_id' })
  authorId: string;

  @Column({ name: 'editor_id', nullable: true })
  editorId?: string;

  @Column({ name: 'category_id', nullable: true })
  categoryId?: string;

  @Column({ name: 'seo_title', nullable: true })
  seoTitle?: string;

  @Column({ name: 'seo_description', nullable: true })
  seoDescription?: string;

  @Column({ name: 'seo_keywords', type: 'text', nullable: true })
  seoKeywords?: string;

  @Column({ name: 'author_name', length: 255, nullable: true })
  authorName?: string;

  @Column({ name: 'difficulty_level', type: 'smallint', default: 1 })
  difficultyLevel: number;

  @Column({ name: 'content_type', length: 50, default: 'article' })
  contentType: string;

  @Column({ name: 'is_premium', default: false })
  isPremium: boolean;

  @Column({ name: 'estimated_reading_time', type: 'smallint', nullable: true })
  estimatedReadingTime?: number;

  @Column({ name: 'view_count', default: 0 })
  viewCount: number;

  @Column({ name: 'like_count', default: 0 })
  likeCount: number;

  @Column({ name: 'share_count', default: 0 })
  shareCount: number;

  @Column({ name: 'comment_count', default: 0 })
  commentCount: number;

  @Column({ name: 'is_featured', default: false })
  isFeatured: boolean;

  @Column({ name: 'featured_at', type: 'timestamp with time zone', nullable: true })
  featuredAt?: Date;

  @Column({ name: 'is_trending', default: false })
  isTrending: boolean;

  @Column({ name: 'trending_score', type: 'decimal', precision: 10, scale: 2, default: 0 })
  trendingScore: number;

  @Column({ name: 'ai_summary', type: 'text', nullable: true })
  aiSummary?: string;

  @Column({ name: 'ai_tags', type: 'jsonb', default: '[]' })
  aiTags: string;

  @Column({ name: 'ai_reading_level', length: 20, nullable: true })
  aiReadingLevel?: string;

  @Column({ name: 'ai_sentiment', length: 20, nullable: true })
  aiSentiment?: string;

  @Column({ name: 'scheduled_at', type: 'timestamp with time zone', nullable: true })
  scheduledAt?: Date;

  @Column({ name: 'published_at', type: 'timestamp with time zone', nullable: true })
  publishedAt?: Date;

  @Column({ type: 'jsonb', default: '{}' })
  metadata: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamp with time zone' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamp with time zone' })
  updatedAt: Date;

  @Column({ name: 'deleted_at', type: 'timestamp with time zone', nullable: true })
  deletedAt?: Date;

  // Relations
  @ManyToOne(() => UserEntity, { nullable: false })
  @JoinColumn({ name: 'author_id' })
  author: UserEntity;

  @ManyToOne(() => UserEntity, { nullable: true })
  @JoinColumn({ name: 'editor_id' })
  editor?: UserEntity;

  @ManyToOne(() => CategoryEntity, { nullable: true })
  @JoinColumn({ name: 'category_id' })
  category?: CategoryEntity;

  @ManyToMany(() => TagEntity, (tag) => tag.articles)
  @JoinTable({
    schema: 'paperly',
    name: 'article_tags',
    joinColumn: {
      name: 'article_id',
      referencedColumnName: 'id',
    },
    inverseJoinColumn: {
      name: 'tag_id',
      referencedColumnName: 'id',
    },
  })
  tags: TagEntity[];
}