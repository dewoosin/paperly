-- =============================================
-- Paperly 통합 마스터 데이터베이스 스키마
-- Google/Facebook 수준의 고급 추천 시스템 및 사용자 행동 분석
-- Version: 2.0.0 (UUID 기반 통합 스키마)
-- =============================================

-- paperly 스키마 사용 설정
SET search_path TO paperly, public;

-- 필수 확장 기능 활성화
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";      -- UUID 생성
CREATE EXTENSION IF NOT EXISTS "pg_trgm";        -- 텍스트 유사도 검색
CREATE EXTENSION IF NOT EXISTS "btree_gin";      -- 복합 인덱스 최적화
CREATE EXTENSION IF NOT EXISTS "pgcrypto";       -- 암호화

-- =============================================
-- 1. 시스템 관리 및 공통 테이블
-- =============================================

-- 시스템 설정 테이블
CREATE TABLE IF NOT EXISTS paperly.system_configs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    config_key VARCHAR(100) NOT NULL UNIQUE,
    config_value TEXT NOT NULL,
    description TEXT,
    config_type VARCHAR(20) DEFAULT 'string' CHECK (config_type IN ('string', 'number', 'boolean', 'json')),
    is_public BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 공통코드 테이블
CREATE TABLE IF NOT EXISTS paperly.common_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code_group VARCHAR(50) NOT NULL,
    code_value VARCHAR(50) NOT NULL,
    code_name VARCHAR(100) NOT NULL,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    parent_code_id UUID REFERENCES paperly.common_codes(id),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(code_group, code_value)
);

-- 시스템 메시지 테이블
CREATE TABLE IF NOT EXISTS paperly.system_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_key VARCHAR(100) NOT NULL UNIQUE,
    message_ko TEXT NOT NULL,
    message_en TEXT,
    message_type VARCHAR(20) DEFAULT 'info' CHECK (message_type IN ('info', 'warning', 'error', 'success')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 2. 사용자 관리 시스템 (강화된 버전)
-- =============================================

-- 사용자 기본 정보
CREATE TABLE IF NOT EXISTS paperly.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    nickname VARCHAR(50) UNIQUE,
    profile_image_url TEXT,
    birth_date DATE,
    gender VARCHAR(10) CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say')),
    phone_number VARCHAR(20),
    email_verified BOOLEAN DEFAULT false,
    phone_verified BOOLEAN DEFAULT false,
    
    -- 추가된 컬럼들
    onboarding_completed BOOLEAN DEFAULT false,
    ai_consent BOOLEAN DEFAULT false,
    data_collection_consent BOOLEAN DEFAULT false,
    marketing_consent BOOLEAN DEFAULT false,
    preferred_language VARCHAR(10) DEFAULT 'ko',
    timezone VARCHAR(50) DEFAULT 'Asia/Seoul',
    referral_code VARCHAR(20) UNIQUE,
    referred_by UUID REFERENCES paperly.users(id),
    
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended', 'deleted')),
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 사용자 온보딩 단계 추적
CREATE TABLE IF NOT EXISTS paperly.user_onboarding_steps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    step_name VARCHAR(50) NOT NULL,
    step_data JSONB,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, step_name)
);

-- 사용자 역할 및 권한
CREATE TABLE IF NOT EXISTS paperly.user_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    permissions JSONB NOT NULL DEFAULT '[]',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 사용자-역할 매핑
CREATE TABLE IF NOT EXISTS paperly.user_role_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES paperly.user_roles(id) ON DELETE CASCADE,
    assigned_by UUID REFERENCES paperly.users(id),
    assigned_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    UNIQUE(user_id, role_id)
);

-- =============================================
-- 3. 계층적 카테고리 시스템
-- =============================================

CREATE TABLE IF NOT EXISTS paperly.categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    parent_id UUID REFERENCES paperly.categories(id),
    
    -- 시각적 요소
    icon_name VARCHAR(50),
    color_code VARCHAR(7),
    cover_image_url TEXT,
    
    -- AI 분석을 위한 메타데이터
    ai_keywords TEXT[],
    ai_topics JSONB,
    
    -- 카테고리 설정
    is_active BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,
    min_reading_level INTEGER DEFAULT 1 CHECK (min_reading_level BETWEEN 1 AND 5),
    max_reading_level INTEGER DEFAULT 5 CHECK (max_reading_level BETWEEN 1 AND 5),
    
    -- 통계 (캐시된 값들)
    article_count INTEGER DEFAULT 0,
    subscriber_count INTEGER DEFAULT 0,
    avg_rating DECIMAL(3,2) DEFAULT 0.00,
    
    -- 순서 및 시간
    sort_order INTEGER DEFAULT 0,
    created_by UUID REFERENCES paperly.users(id),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 카테고리 구독 시스템
CREATE TABLE IF NOT EXISTS paperly.category_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES paperly.categories(id) ON DELETE CASCADE,
    notification_enabled BOOLEAN DEFAULT true,
    priority_level INTEGER DEFAULT 5 CHECK (priority_level BETWEEN 1 AND 10),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, category_id)
);

-- =============================================
-- 4. 스마트 태그 시스템
-- =============================================

CREATE TABLE IF NOT EXISTS paperly.tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    tag_type VARCHAR(20) DEFAULT 'general' CHECK (tag_type IN ('general', 'technical', 'trending', 'editorial')),
    
    -- AI 관련 메타데이터
    ai_generated BOOLEAN DEFAULT false,
    confidence_score DECIMAL(3,2),
    related_concepts JSONB,
    
    -- 시각적 요소
    color_code VARCHAR(7),
    
    -- 통계 및 인기도
    usage_count INTEGER DEFAULT 0,
    trending_score DECIMAL(8,2) DEFAULT 0.00,
    
    -- 상태
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    
    created_by UUID REFERENCES paperly.users(id),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 태그 계층 관계
CREATE TABLE IF NOT EXISTS paperly.tag_relationships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_tag_id UUID NOT NULL REFERENCES paperly.tags(id) ON DELETE CASCADE,
    child_tag_id UUID NOT NULL REFERENCES paperly.tags(id) ON DELETE CASCADE,
    relationship_type VARCHAR(20) NOT NULL CHECK (relationship_type IN ('synonym', 'related', 'broader', 'narrower')),
    strength DECIMAL(3,2) DEFAULT 1.00,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(parent_tag_id, child_tag_id, relationship_type)
);

-- 사용자 태그 관심도
CREATE TABLE IF NOT EXISTS paperly.user_tag_interests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES paperly.tags(id) ON DELETE CASCADE,
    explicit_interest DECIMAL(3,2) DEFAULT 0.00,
    implicit_interest DECIMAL(3,2) DEFAULT 0.00,
    combined_interest DECIMAL(3,2) DEFAULT 0.00,
    interaction_count INTEGER DEFAULT 0,
    last_interaction_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, tag_id)
);

-- =============================================
-- 5. 작가 프로필 및 콘텐츠 관리
-- =============================================

-- 작가 프로필
CREATE TABLE IF NOT EXISTS paperly.writer_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    pen_name VARCHAR(100),
    bio TEXT,
    expertise_areas TEXT[],
    writing_style VARCHAR(50),
    
    -- 검증 및 상태
    is_verified BOOLEAN DEFAULT false,
    verification_badge VARCHAR(50),
    writer_level VARCHAR(20) DEFAULT 'new' CHECK (writer_level IN ('new', 'rising', 'established', 'featured')),
    
    -- 통계
    total_articles INTEGER DEFAULT 0,
    total_views INTEGER DEFAULT 0,
    total_likes INTEGER DEFAULT 0,
    average_rating DECIMAL(3,2) DEFAULT 0.00,
    follower_count INTEGER DEFAULT 0,
    
    -- 수익 관련
    revenue_share_percentage DECIMAL(5,2) DEFAULT 70.00,
    total_earnings DECIMAL(12,2) DEFAULT 0.00,
    
    -- 소셜 링크
    social_links JSONB,
    website_url TEXT,
    
    -- 상태
    is_active BOOLEAN DEFAULT true,
    application_status VARCHAR(20) DEFAULT 'pending' CHECK (application_status IN ('pending', 'approved', 'rejected', 'suspended')),
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- 작가 팔로우 시스템
CREATE TABLE IF NOT EXISTS paperly.writer_follows (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    follower_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    writer_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    notification_enabled BOOLEAN DEFAULT true,
    email_digest BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(follower_id, writer_id),
    CHECK (follower_id != writer_id)
);

-- =============================================
-- 6. 게시글 시스템 (강화된 버전)
-- =============================================

CREATE TABLE IF NOT EXISTS paperly.articles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(200) NOT NULL,
    slug VARCHAR(200) NOT NULL UNIQUE,
    summary TEXT NOT NULL,
    content TEXT NOT NULL,
    featured_image_url TEXT,
    
    -- 작가 정보
    author_id UUID NOT NULL REFERENCES paperly.users(id),
    author_name VARCHAR(100),
    
    -- 분류
    category_id UUID NOT NULL REFERENCES paperly.categories(id),
    
    -- 콘텐츠 메타데이터
    word_count INTEGER DEFAULT 0,
    estimated_reading_time INTEGER DEFAULT 0,
    difficulty_level INTEGER DEFAULT 3 CHECK (difficulty_level BETWEEN 1 AND 5),
    content_type VARCHAR(20) DEFAULT 'article' CHECK (content_type IN ('article', 'series', 'tutorial', 'opinion', 'news')),
    
    -- 추가된 컬럼들
    language VARCHAR(10) DEFAULT 'ko',
    target_audience JSONB,
    reading_goals TEXT[],
    external_source_url TEXT,
    license_type VARCHAR(50) DEFAULT 'all_rights_reserved',
    monetization_enabled BOOLEAN DEFAULT true,
    ai_generated_summary TEXT,
    ai_topics JSONB,
    
    -- SEO
    seo_title VARCHAR(100),
    seo_description VARCHAR(200),
    seo_keywords TEXT[],
    
    -- 발행 관리
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'review', 'published', 'archived', 'deleted')),
    is_featured BOOLEAN DEFAULT false,
    is_premium BOOLEAN DEFAULT false,
    published_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 게시글-태그 연결
CREATE TABLE IF NOT EXISTS paperly.article_tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    article_id UUID NOT NULL REFERENCES paperly.articles(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES paperly.tags(id) ON DELETE CASCADE,
    relevance_score DECIMAL(3,2) DEFAULT 1.00,
    is_primary BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(article_id, tag_id)
);

-- 게시글 시리즈 관리
CREATE TABLE IF NOT EXISTS paperly.article_series (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(200) NOT NULL,
    slug VARCHAR(200) NOT NULL UNIQUE,
    description TEXT,
    cover_image_url TEXT,
    author_id UUID NOT NULL REFERENCES paperly.users(id),
    is_active BOOLEAN DEFAULT true,
    is_completed BOOLEAN DEFAULT false,
    estimated_total_parts INTEGER,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 시리즈-게시글 연결
CREATE TABLE IF NOT EXISTS paperly.series_articles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    series_id UUID NOT NULL REFERENCES paperly.article_series(id) ON DELETE CASCADE,
    article_id UUID NOT NULL REFERENCES paperly.articles(id) ON DELETE CASCADE,
    part_number INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(series_id, article_id),
    UNIQUE(series_id, part_number)
);

-- =============================================
-- 7. 사용자 참여 및 소셜 기능
-- =============================================

-- 게시글 북마크
CREATE TABLE IF NOT EXISTS paperly.bookmarks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    article_id UUID NOT NULL REFERENCES paperly.articles(id) ON DELETE CASCADE,
    folder_name VARCHAR(50) DEFAULT 'default',
    notes TEXT,
    is_public BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, article_id)
);

-- 게시글 좋아요
CREATE TABLE IF NOT EXISTS paperly.article_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    article_id UUID NOT NULL REFERENCES paperly.articles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, article_id)
);

-- 게시글 평점
CREATE TABLE IF NOT EXISTS paperly.article_ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    article_id UUID NOT NULL REFERENCES paperly.articles(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, article_id)
);

-- 게시글 공유 추적
CREATE TABLE IF NOT EXISTS paperly.article_shares (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES paperly.users(id) ON DELETE SET NULL,
    article_id UUID NOT NULL REFERENCES paperly.articles(id) ON DELETE CASCADE,
    platform VARCHAR(50) NOT NULL,
    share_method VARCHAR(20) NOT NULL CHECK (share_method IN ('button', 'url_copy', 'external')),
    share_url TEXT,
    referrer_url TEXT,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 8. 읽기 세션 및 진행 추적
-- =============================================

CREATE TABLE IF NOT EXISTS paperly.reading_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    article_id UUID NOT NULL REFERENCES paperly.articles(id) ON DELETE CASCADE,
    session_token UUID DEFAULT uuid_generate_v4(),
    device_type VARCHAR(20) DEFAULT 'mobile' CHECK (device_type IN ('mobile', 'tablet', 'desktop')),
    device_info JSONB,
    
    started_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_position INTEGER DEFAULT 0,
    last_position_percentage DECIMAL(5,2) DEFAULT 0.00,
    reading_duration_seconds INTEGER DEFAULT 0,
    
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMPTZ,
    completion_percentage DECIMAL(5,2) DEFAULT 0.00,
    
    reading_speed_wpm INTEGER,
    attention_score DECIMAL(3,2),
    engagement_score DECIMAL(3,2),
    
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 9. 통계 및 캐시 테이블
-- =============================================

-- 게시글 통계
CREATE TABLE IF NOT EXISTS paperly.article_stats (
    article_id UUID PRIMARY KEY REFERENCES paperly.articles(id) ON DELETE CASCADE,
    view_count INTEGER DEFAULT 0,
    unique_view_count INTEGER DEFAULT 0,
    total_reading_time INTEGER DEFAULT 0,
    like_count INTEGER DEFAULT 0,
    bookmark_count INTEGER DEFAULT 0,
    share_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    rating_count INTEGER DEFAULT 0,
    rating_sum INTEGER DEFAULT 0,
    average_rating DECIMAL(3,2) DEFAULT 0.00,
    completion_count INTEGER DEFAULT 0,
    average_completion_rate DECIMAL(5,2) DEFAULT 0.00,
    average_reading_time INTEGER DEFAULT 0,
    
    -- 시간대별 통계
    morning_views INTEGER DEFAULT 0,
    afternoon_views INTEGER DEFAULT 0,
    evening_views INTEGER DEFAULT 0,
    night_views INTEGER DEFAULT 0,
    
    -- 요일별 통계
    weekday_views INTEGER DEFAULT 0,
    weekend_views INTEGER DEFAULT 0,
    
    -- 디바이스별 통계
    mobile_views INTEGER DEFAULT 0,
    desktop_views INTEGER DEFAULT 0,
    tablet_views INTEGER DEFAULT 0,
    
    last_view_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 일일 사용자 활동 통계
CREATE TABLE IF NOT EXISTS paperly.daily_user_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    stat_date DATE NOT NULL,
    articles_read INTEGER DEFAULT 0,
    articles_completed INTEGER DEFAULT 0,
    total_reading_time INTEGER DEFAULT 0,
    likes_given INTEGER DEFAULT 0,
    bookmarks_added INTEGER DEFAULT 0,
    shares_made INTEGER DEFAULT 0,
    recommendations_viewed INTEGER DEFAULT 0,
    recommendations_clicked INTEGER DEFAULT 0,
    search_queries INTEGER DEFAULT 0,
    session_count INTEGER DEFAULT 0,
    avg_session_duration INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, stat_date)
);

-- =============================================
-- 10. 기본 인덱스 생성
-- =============================================

-- 사용자 관련 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_email_status ON paperly.users (email, status) WHERE status = 'active';
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_created_at ON paperly.users (created_at DESC);

-- 카테고리 관련 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_categories_parent_active ON paperly.categories (parent_id, is_active) WHERE is_active = true;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_category_subscriptions_user ON paperly.category_subscriptions (user_id, notification_enabled);

-- 태그 관련 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tags_trending ON paperly.tags (trending_score DESC, is_active) WHERE is_active = true;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_tag_interests_combined ON paperly.user_tag_interests (user_id, combined_interest DESC);

-- 게시글 관련 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_articles_author_status ON paperly.articles (author_id, status, published_at DESC) WHERE status = 'published';
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_articles_category_published ON paperly.articles (category_id, published_at DESC) WHERE status = 'published';
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_articles_featured ON paperly.articles (is_featured, published_at DESC) WHERE is_featured = true AND status = 'published';

-- 읽기 세션 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_reading_sessions_user_completed ON paperly.reading_sessions (user_id, is_completed, started_at DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_reading_sessions_article_stats ON paperly.reading_sessions (article_id, is_completed, reading_duration_seconds);

-- 통계 테이블 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_article_stats_views ON paperly.article_stats (view_count DESC, average_rating DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_daily_user_stats_date ON paperly.daily_user_stats (user_id, stat_date DESC);

-- =============================================
-- 11. 트리거 및 자동화 함수
-- =============================================

-- updated_at 자동 업데이트 함수
CREATE OR REPLACE FUNCTION paperly.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 각 테이블에 updated_at 트리거 추가
DROP TRIGGER IF EXISTS update_users_updated_at ON paperly.users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON paperly.users FOR EACH ROW EXECUTE FUNCTION paperly.update_updated_at_column();

DROP TRIGGER IF EXISTS update_categories_updated_at ON paperly.categories;
CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON paperly.categories FOR EACH ROW EXECUTE FUNCTION paperly.update_updated_at_column();

DROP TRIGGER IF EXISTS update_articles_updated_at ON paperly.articles;
CREATE TRIGGER update_articles_updated_at BEFORE UPDATE ON paperly.articles FOR EACH ROW EXECUTE FUNCTION paperly.update_updated_at_column();

DROP TRIGGER IF EXISTS update_writer_profiles_updated_at ON paperly.writer_profiles;
CREATE TRIGGER update_writer_profiles_updated_at BEFORE UPDATE ON paperly.writer_profiles FOR EACH ROW EXECUTE FUNCTION paperly.update_updated_at_column();

-- 게시글 통계 자동 업데이트 함수
CREATE OR REPLACE FUNCTION paperly.update_article_stats_on_view()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO paperly.article_stats (article_id, view_count, unique_view_count, last_view_at)
    VALUES (NEW.article_id, 1, 1, NEW.started_at)
    ON CONFLICT (article_id) DO UPDATE SET
        view_count = article_stats.view_count + 1,
        unique_view_count = article_stats.unique_view_count + CASE 
            WHEN NOT EXISTS (
                SELECT 1 FROM paperly.reading_sessions 
                WHERE article_id = NEW.article_id 
                AND user_id = NEW.user_id 
                AND id != NEW.id
            ) THEN 1 ELSE 0 END,
        last_view_at = NEW.started_at,
        updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 읽기 세션 시작 시 통계 업데이트 트리거
DROP TRIGGER IF EXISTS update_stats_on_reading_session ON paperly.reading_sessions;
CREATE TRIGGER update_stats_on_reading_session 
    AFTER INSERT ON paperly.reading_sessions 
    FOR EACH ROW EXECUTE FUNCTION paperly.update_article_stats_on_view();

-- =============================================
-- 완료 메시지
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '================================='
    RAISE NOTICE 'Paperly 통합 마스터 스키마 생성 완료';
    RAISE NOTICE '================================='
    RAISE NOTICE '생성된 핵심 테이블:';
    RAISE NOTICE '- 사용자 관리: users, user_roles, user_onboarding_steps';
    RAISE NOTICE '- 콘텐츠: categories, tags, articles, article_series';
    RAISE NOTICE '- 작가: writer_profiles, writer_follows';
    RAISE NOTICE '- 소셜: bookmarks, article_likes, article_ratings';
    RAISE NOTICE '- 추적: reading_sessions, article_stats';
    RAISE NOTICE '================================='
    RAISE NOTICE '다음 단계: 002_recommendation_system.sql 실행';
    RAISE NOTICE '=================================';
END $$;