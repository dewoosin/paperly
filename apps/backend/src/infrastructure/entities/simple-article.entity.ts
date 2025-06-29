// /Users/workspace/paperly/apps/backend/src/infrastructure/entities/simple-article.entity.ts

// 간단한 데이터베이스 접근을 위한 임시 구현
// 실제로는 PostgreSQL 스키마에 맞춰 작업하지만, 테스트를 위해 간단한 인터페이스 제공

export interface ArticleRecord {
  id: string;
  title: string;
  slug: string;
  subtitle?: string;
  excerpt?: string;
  content: string;
  content_html?: string;
  featured_image_url?: string;
  featured_image_alt?: string;
  reading_time_minutes?: number;
  word_count?: number;
  status: string;
  visibility: string;
  author_id: string;
  editor_id?: string;
  category_id?: string;
  seo_title?: string;
  seo_description?: string;
  view_count: number;
  like_count: number;
  share_count: number;
  comment_count: number;
  is_featured: boolean;
  featured_at?: Date;
  is_trending: boolean;
  trending_score: number;
  ai_summary?: string;
  ai_tags: string;
  ai_reading_level?: string;
  ai_sentiment?: string;
  scheduled_at?: Date;
  published_at?: Date;
  metadata: string;
  created_at: Date;
  updated_at: Date;
  deleted_at?: Date;
}