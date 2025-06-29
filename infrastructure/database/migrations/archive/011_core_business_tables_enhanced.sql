-- =============================================
-- Paperly 핵심 비즈니스 테이블 강화 스키마
-- 기존 테이블 개선 및 누락된 핵심 기능 추가
-- =============================================

-- paperly 스키마 사용 설정
SET search_path TO paperly, public;

-- =============================================
-- 1. 사용자 테이블 강화
-- =============================================

-- 기존 users 테이블이 있으면 컬럼 추가, 없으면 새로 생성
DO $$
BEGIN
    -- users 테이블 확인 및 컬럼 추가
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'paperly' AND table_name = 'users') THEN
        CREATE TABLE paperly.users (
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
            status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended', 'deleted')),
            last_login_at TIMESTAMPTZ,
            created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
        );
    END IF;

    -- 새로운 컬럼들 추가 (이미 존재하면 무시)
    BEGIN
        ALTER TABLE paperly.users ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT false;
        ALTER TABLE paperly.users ADD COLUMN IF NOT EXISTS ai_consent BOOLEAN DEFAULT false; -- AI 개인화 동의
        ALTER TABLE paperly.users ADD COLUMN IF NOT EXISTS data_collection_consent BOOLEAN DEFAULT false; -- 데이터 수집 동의
        ALTER TABLE paperly.users ADD COLUMN IF NOT EXISTS marketing_consent BOOLEAN DEFAULT false; -- 마케팅 동의
        ALTER TABLE paperly.users ADD COLUMN IF NOT EXISTS preferred_language VARCHAR(10) DEFAULT 'ko';
        ALTER TABLE paperly.users ADD COLUMN IF NOT EXISTS timezone VARCHAR(50) DEFAULT 'Asia/Seoul';
        ALTER TABLE paperly.users ADD COLUMN IF NOT EXISTS referral_code VARCHAR(20) UNIQUE; -- 추천인 코드
        ALTER TABLE paperly.users ADD COLUMN IF NOT EXISTS referred_by UUID REFERENCES paperly.users(id); -- 추천한 사용자
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Some columns may already exist in users table';
    END;
END $$;

-- 사용자 온보딩 단계 추적
CREATE TABLE IF NOT EXISTS paperly.user_onboarding_steps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    step_name VARCHAR(50) NOT NULL, -- interests_selection, reading_preferences, ai_consent, etc.
    step_data JSONB, -- 각 단계에서 수집된 데이터
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id, step_name)
);

-- =============================================
-- 2. 카테고리 시스템 강화
-- =============================================

-- 계층적 카테고리 시스템
CREATE TABLE IF NOT EXISTS paperly.categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    parent_id UUID REFERENCES paperly.categories(id), -- 부모 카테고리 (계층 구조)
    
    -- 시각적 요소
    icon_name VARCHAR(50), -- 아이콘 이름
    color_code VARCHAR(7), -- 색상 코드 (#RRGGBB)
    cover_image_url TEXT,
    
    -- AI 분석을 위한 메타데이터
    ai_keywords TEXT[], -- AI가 이 카테고리를 식별할 키워드들
    ai_topics JSONB, -- AI 주제 분류 {"technology": 0.9, "programming": 0.8}
    
    -- 카테고리 설정
    is_active BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false, -- 메인 페이지 노출
    min_reading_level INTEGER DEFAULT 1 CHECK (min_reading_level BETWEEN 1 AND 5),
    max_reading_level INTEGER DEFAULT 5 CHECK (max_reading_level BETWEEN 1 AND 5),
    
    -- 통계 (캐시된 값들)
    article_count INTEGER DEFAULT 0,
    subscriber_count INTEGER DEFAULT 0,
    avg_rating DECIMAL(3,2) DEFAULT 0.00,
    
    -- 순서 및 시간
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 카테고리 구독 시스템
CREATE TABLE IF NOT EXISTS paperly.category_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES paperly.categories(id) ON DELETE CASCADE,
    
    -- 구독 설정
    notification_enabled BOOLEAN DEFAULT true,
    priority_level INTEGER DEFAULT 5 CHECK (priority_level BETWEEN 1 AND 10), -- 높을수록 우선순위
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id, category_id)
);

-- =============================================
-- 3. 태그 시스템 강화
-- =============================================

-- 스마트 태그 시스템
CREATE TABLE IF NOT EXISTS paperly.tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    
    -- 태그 유형
    tag_type VARCHAR(20) DEFAULT 'general' CHECK (tag_type IN ('general', 'technical', 'trending', 'editorial')),
    
    -- AI 관련 메타데이터
    ai_generated BOOLEAN DEFAULT false, -- AI가 자동 생성한 태그인지
    confidence_score DECIMAL(3,2), -- AI 태그의 신뢰도
    related_concepts JSONB, -- 관련 개념들
    
    -- 시각적 요소
    color_code VARCHAR(7),
    
    -- 통계 및 인기도
    usage_count INTEGER DEFAULT 0,
    trending_score DECIMAL(8,2) DEFAULT 0.00, -- 트렌딩 점수
    
    -- 상태
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false, -- 에디터가 검증한 태그
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 태그 계층 관계 (연관 태그)
CREATE TABLE IF NOT EXISTS paperly.tag_relationships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_tag_id UUID NOT NULL REFERENCES paperly.tags(id) ON DELETE CASCADE,
    child_tag_id UUID NOT NULL REFERENCES paperly.tags(id) ON DELETE CASCADE,
    relationship_type VARCHAR(20) NOT NULL CHECK (relationship_type IN ('synonym', 'related', 'broader', 'narrower')),
    strength DECIMAL(3,2) DEFAULT 1.00, -- 관계 강도 (0-1)
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(parent_tag_id, child_tag_id, relationship_type)
);

-- 사용자 태그 관심도
CREATE TABLE IF NOT EXISTS paperly.user_tag_interests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES paperly.tags(id) ON DELETE CASCADE,
    
    -- 관심도 점수 (명시적 + 암시적)
    explicit_interest DECIMAL(3,2) DEFAULT 0.00, -- 사용자가 직접 설정한 관심도
    implicit_interest DECIMAL(3,2) DEFAULT 0.00, -- 행동 분석 기반 관심도
    combined_interest DECIMAL(3,2) DEFAULT 0.00, -- 결합된 관심도
    
    -- 메타데이터
    interaction_count INTEGER DEFAULT 0, -- 이 태그와 상호작용한 횟수
    last_interaction_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id, tag_id)
);

-- =============================================
-- 4. 작가 및 콘텐츠 관리 강화
-- =============================================

-- 작가 프로필 (writers는 users의 확장)
CREATE TABLE IF NOT EXISTS paperly.writer_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    
    -- 작가 정보
    pen_name VARCHAR(100), -- 필명
    bio TEXT, -- 작가 소개
    expertise_areas TEXT[], -- 전문 분야
    writing_style VARCHAR(50), -- 글쓰기 스타일 (academic, casual, technical, etc.)
    
    -- 검증 및 상태
    is_verified BOOLEAN DEFAULT false, -- 인증된 작가
    verification_badge VARCHAR(50), -- 인증 배지 타입
    writer_level VARCHAR(20) DEFAULT 'new' CHECK (writer_level IN ('new', 'rising', 'established', 'featured')),
    
    -- 통계 (캐시된 값들)
    total_articles INTEGER DEFAULT 0,
    total_views INTEGER DEFAULT 0,
    total_likes INTEGER DEFAULT 0,
    average_rating DECIMAL(3,2) DEFAULT 0.00,
    follower_count INTEGER DEFAULT 0,
    
    -- 수익 관련
    revenue_share_percentage DECIMAL(5,2) DEFAULT 70.00, -- 수익 분배율
    total_earnings DECIMAL(12,2) DEFAULT 0.00,
    
    -- 소셜 링크
    social_links JSONB, -- {"twitter": "handle", "linkedin": "url", ...}
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
    
    -- 팔로우 설정
    notification_enabled BOOLEAN DEFAULT true,
    email_digest BOOLEAN DEFAULT false,
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(follower_id, writer_id),
    CHECK (follower_id != writer_id) -- 자기 자신은 팔로우 불가
);

-- =============================================
-- 5. 게시글 시스템 강화
-- =============================================

-- 기존 articles 테이블 확인 및 강화
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'paperly' AND table_name = 'articles') THEN
        CREATE TABLE paperly.articles (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            title VARCHAR(200) NOT NULL,
            slug VARCHAR(200) NOT NULL UNIQUE,
            summary TEXT NOT NULL,
            content TEXT NOT NULL, -- 실제 콘텐츠 내용
            featured_image_url TEXT,
            
            -- 작가 정보
            author_id UUID NOT NULL REFERENCES paperly.users(id),
            author_name VARCHAR(100), -- 캐시된 작가 이름
            
            -- 분류
            category_id UUID NOT NULL REFERENCES paperly.categories(id),
            
            -- 콘텐츠 메타데이터
            word_count INTEGER DEFAULT 0,
            estimated_reading_time INTEGER DEFAULT 0, -- 분 단위
            difficulty_level INTEGER DEFAULT 3 CHECK (difficulty_level BETWEEN 1 AND 5),
            content_type VARCHAR(20) DEFAULT 'article' CHECK (content_type IN ('article', 'series', 'tutorial', 'opinion', 'news')),
            
            -- SEO
            seo_title VARCHAR(100),
            seo_description VARCHAR(200),
            seo_keywords TEXT[],
            
            -- 발행 관리
            status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'review', 'published', 'archived', 'deleted')),
            is_featured BOOLEAN DEFAULT false,
            is_premium BOOLEAN DEFAULT false,
            published_at TIMESTAMPTZ,
            
            -- 시간 정보
            created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
        );
    END IF;

    -- 새로운 컬럼들 추가
    BEGIN
        ALTER TABLE paperly.articles ADD COLUMN IF NOT EXISTS language VARCHAR(10) DEFAULT 'ko';
        ALTER TABLE paperly.articles ADD COLUMN IF NOT EXISTS target_audience JSONB; -- {"age_group": "25-35", "expertise": "beginner"}
        ALTER TABLE paperly.articles ADD COLUMN IF NOT EXISTS reading_goals TEXT[]; -- ["learn", "entertainment", "professional"]
        ALTER TABLE paperly.articles ADD COLUMN IF NOT EXISTS external_source_url TEXT; -- 외부 소스 URL
        ALTER TABLE paperly.articles ADD COLUMN IF NOT EXISTS license_type VARCHAR(50) DEFAULT 'all_rights_reserved';
        ALTER TABLE paperly.articles ADD COLUMN IF NOT EXISTS monetization_enabled BOOLEAN DEFAULT true;
        ALTER TABLE paperly.articles ADD COLUMN IF NOT EXISTS ai_generated_summary TEXT; -- AI가 생성한 요약
        ALTER TABLE paperly.articles ADD COLUMN IF NOT EXISTS ai_topics JSONB; -- AI가 분석한 주제들
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Some columns may already exist in articles table';
    END;
END $$;

-- 게시글-태그 연결 테이블
CREATE TABLE IF NOT EXISTS paperly.article_tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    article_id UUID NOT NULL REFERENCES paperly.articles(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES paperly.tags(id) ON DELETE CASCADE,
    
    -- 태그 관련성 점수
    relevance_score DECIMAL(3,2) DEFAULT 1.00, -- AI가 계산한 관련성 점수
    is_primary BOOLEAN DEFAULT false, -- 주요 태그 여부
    
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
    
    -- 작가 정보
    author_id UUID NOT NULL REFERENCES paperly.users(id),
    
    -- 시리즈 설정
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
-- 6. 사용자 참여 및 소셜 기능
-- =============================================

-- 게시글 북마크 (기존 있으면 무시)
CREATE TABLE IF NOT EXISTS paperly.bookmarks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    article_id UUID NOT NULL REFERENCES paperly.articles(id) ON DELETE CASCADE,
    
    -- 북마크 설정
    folder_name VARCHAR(50) DEFAULT 'default',
    notes TEXT, -- 개인 메모
    is_public BOOLEAN DEFAULT false, -- 공개 북마크 여부
    
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
    review_text TEXT, -- 선택적 리뷰
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id, article_id)
);

-- 게시글 공유 추적
CREATE TABLE IF NOT EXISTS paperly.article_shares (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES paperly.users(id) ON DELETE SET NULL,
    article_id UUID NOT NULL REFERENCES paperly.articles(id) ON DELETE CASCADE,
    
    -- 공유 정보
    platform VARCHAR(50) NOT NULL, -- twitter, facebook, linkedin, email, copy_link
    share_method VARCHAR(20) NOT NULL CHECK (share_method IN ('button', 'url_copy', 'external')),
    
    -- 추적 정보
    share_url TEXT,
    referrer_url TEXT,
    user_agent TEXT,
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 7. 읽기 세션 및 진행 추적
-- =============================================

-- 상세 읽기 세션 (기존 있으면 무시)
CREATE TABLE IF NOT EXISTS paperly.reading_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    article_id UUID NOT NULL REFERENCES paperly.articles(id) ON DELETE CASCADE,
    
    -- 세션 정보
    session_token UUID DEFAULT uuid_generate_v4(), -- 세션 식별자
    device_type VARCHAR(20) DEFAULT 'mobile' CHECK (device_type IN ('mobile', 'tablet', 'desktop')),
    device_info JSONB, -- 디바이스 상세 정보
    
    -- 읽기 진행 정보
    started_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_position INTEGER DEFAULT 0, -- 마지막 읽은 위치 (문자 수)
    last_position_percentage DECIMAL(5,2) DEFAULT 0.00, -- 마지막 읽은 위치 (%)
    reading_duration_seconds INTEGER DEFAULT 0, -- 실제 읽기 시간
    
    -- 읽기 완료 정보
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMPTZ,
    completion_percentage DECIMAL(5,2) DEFAULT 0.00,
    
    -- 읽기 품질 지표
    reading_speed_wpm INTEGER, -- 이 세션의 읽기 속도
    attention_score DECIMAL(3,2), -- 집중도 점수 (AI 계산)
    engagement_score DECIMAL(3,2), -- 참여도 점수
    
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 8. 통계 및 캐시 테이블
-- =============================================

-- 게시글 통계 (실시간 업데이트)
CREATE TABLE IF NOT EXISTS paperly.article_stats (
    article_id UUID PRIMARY KEY REFERENCES paperly.articles(id) ON DELETE CASCADE,
    
    -- 기본 조회 통계
    view_count INTEGER DEFAULT 0,
    unique_view_count INTEGER DEFAULT 0,
    total_reading_time INTEGER DEFAULT 0, -- 총 읽기 시간 (초)
    
    -- 참여 통계
    like_count INTEGER DEFAULT 0,
    bookmark_count INTEGER DEFAULT 0,
    share_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    
    -- 평점 통계
    rating_count INTEGER DEFAULT 0,
    rating_sum INTEGER DEFAULT 0,
    average_rating DECIMAL(3,2) DEFAULT 0.00,
    
    -- 읽기 완료 통계
    completion_count INTEGER DEFAULT 0,
    average_completion_rate DECIMAL(5,2) DEFAULT 0.00,
    average_reading_time INTEGER DEFAULT 0, -- 평균 읽기 시간 (초)
    
    -- 시간대별 통계
    morning_views INTEGER DEFAULT 0, -- 6-12시
    afternoon_views INTEGER DEFAULT 0, -- 12-18시  
    evening_views INTEGER DEFAULT 0, -- 18-24시
    night_views INTEGER DEFAULT 0, -- 0-6시
    
    -- 요일별 통계
    weekday_views INTEGER DEFAULT 0,
    weekend_views INTEGER DEFAULT 0,
    
    -- 디바이스별 통계
    mobile_views INTEGER DEFAULT 0,
    desktop_views INTEGER DEFAULT 0,
    tablet_views INTEGER DEFAULT 0,
    
    -- 메타데이터
    last_view_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 일일 사용자 활동 통계
CREATE TABLE IF NOT EXISTS paperly.daily_user_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    stat_date DATE NOT NULL,
    
    -- 읽기 활동
    articles_read INTEGER DEFAULT 0,
    articles_completed INTEGER DEFAULT 0,
    total_reading_time INTEGER DEFAULT 0,
    
    -- 참여 활동
    likes_given INTEGER DEFAULT 0,
    bookmarks_added INTEGER DEFAULT 0,
    shares_made INTEGER DEFAULT 0,
    
    -- 발견 활동
    recommendations_viewed INTEGER DEFAULT 0,
    recommendations_clicked INTEGER DEFAULT 0,
    search_queries INTEGER DEFAULT 0,
    
    -- 세션 정보
    session_count INTEGER DEFAULT 0,
    avg_session_duration INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id, stat_date)
);

-- =============================================
-- 9. 인덱스 최적화
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
-- 10. 트리거 및 자동화 함수
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
    RAISE NOTICE '=================================';
    RAISE NOTICE 'Paperly 핵심 비즈니스 테이블 강화 완료';
    RAISE NOTICE '=================================';
    RAISE NOTICE '업데이트된 테이블:';
    RAISE NOTICE '- users: 사용자 관리 강화';
    RAISE NOTICE '- categories: 계층적 카테고리 시스템';
    RAISE NOTICE '- tags: 스마트 태그 및 관심사 추적';
    RAISE NOTICE '- articles: 게시글 시스템 강화';
    RAISE NOTICE '- writer_profiles: 작가 관리 시스템';
    RAISE NOTICE '- reading_sessions: 상세 읽기 추적';
    RAISE NOTICE '- article_stats: 실시간 통계';
    RAISE NOTICE '=================================';
    RAISE NOTICE '모든 비즈니스 핵심 기능이 준비되었습니다.';
    RAISE NOTICE '=================================';
END $$;