-- =====================================================
-- Paperly Database Schema
-- Version: 1.0.0
-- Description: 초기 데이터베이스 스키마 생성
-- =====================================================

-- 확장 프로그램 활성화
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";      -- UUID 생성
CREATE EXTENSION IF NOT EXISTS "pgcrypto";       -- 암호화
-- CREATE EXTENSION IF NOT EXISTS "vector";      -- 임베딩 (나중에 필요시 추가)

-- =====================================================
-- 1. 사용자 관련 테이블
-- =====================================================

-- 사용자 기본 정보
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    
    -- 인증 정보
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email_verified BOOLEAN DEFAULT FALSE,
    email_verification_token VARCHAR(255),
    email_verification_expires_at TIMESTAMP,
    
    -- 프로필 정보
    username VARCHAR(50) UNIQUE,
    full_name VARCHAR(100),
    profile_image_url VARCHAR(500),         -- 나중에 S3로 업그레이드 예정
    bio TEXT,
    
    -- 상태 정보
    is_active BOOLEAN DEFAULT TRUE,
    last_login_at TIMESTAMP,
    
    -- 타임스탬프
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 사용자 인구통계 정보 (선택적)
CREATE TABLE user_demographics (
    user_id INTEGER PRIMARY KEY,
    age_group VARCHAR(20),                  -- '20-24', '25-29', etc
    gender VARCHAR(20),
    occupation VARCHAR(50),
    education_level VARCHAR(30),
    
    -- 추가 정보
    interests_text TEXT,                    -- 자유 입력 관심사
    learning_goals TEXT[],                  -- 학습 목표들
    
    updated_at TIMESTAMP DEFAULT NOW(),
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- =====================================================
-- 2. 카테고리 및 태그
-- =====================================================

-- 카테고리 (계층 구조 지원)
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    slug VARCHAR(50) UNIQUE NOT NULL,
    
    -- UI/UX를 위한 정보
    emoji VARCHAR(10),                      -- '🚀', '🎨', '💡'
    color_hex VARCHAR(7),                   -- '#FF6B6B'
    description TEXT,
    example_topics TEXT[],                  -- 예시 주제들
    
    -- 계층 구조
    parent_id INTEGER,
    display_order INTEGER DEFAULT 0,
    
    -- 상태
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,      -- 온보딩에서 강조 표시
    
    created_at TIMESTAMP DEFAULT NOW(),
    
    FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL
);

-- 태그
CREATE TABLE tags (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    slug VARCHAR(50) UNIQUE NOT NULL,
    usage_count INTEGER DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- 3. 기사 관련 테이블
-- =====================================================

-- 기사 메타데이터 (핵심 정보만)
CREATE TABLE articles (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    
    -- 기본 정보
    title VARCHAR(200) NOT NULL,
    slug VARCHAR(200) UNIQUE NOT NULL,
    
    -- 요약 계층 구조
    summary_short VARCHAR(100),             -- 한 줄 요약 (리스트용)
    summary_medium VARCHAR(500),            -- 단락 요약 (미리보기용)
    summary_bullet_points JSONB,            -- ["핵심1", "핵심2", "핵심3"]
    
    -- 분류
    category_id INTEGER NOT NULL,
    subcategory_id INTEGER,
    
    -- 콘텐츠 위치 (실제 내용은 파일로)
    content_path VARCHAR(500),              -- 'articles/2024/01/uuid.json'
    content_version INTEGER DEFAULT 1,
    
    -- 출처 정보
    source_type VARCHAR(20) NOT NULL,       -- 'ai', 'crawled', 'original'
    source_url VARCHAR(500),
    author_id INTEGER,
    
    -- 독자 경험 메타데이터
    reading_time_minutes INTEGER,
    difficulty_level INTEGER CHECK (difficulty_level >= 1 AND difficulty_level <= 5),
    target_audience VARCHAR(50),            -- 'beginner', 'intermediate', 'expert'
    
    -- 상태
    status VARCHAR(20) DEFAULT 'draft',     -- 'draft', 'published', 'archived'
    published_at TIMESTAMP,
    
    -- 타임스탬프
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    FOREIGN KEY (category_id) REFERENCES categories(id),
    FOREIGN KEY (subcategory_id) REFERENCES categories(id),
    FOREIGN KEY (author_id) REFERENCES users(id)
);

-- 기사 통계 (자주 변경되는 데이터)
CREATE TABLE article_stats (
    article_id INTEGER PRIMARY KEY,
    
    -- 조회/평가
    view_count INTEGER DEFAULT 0,
    unique_view_count INTEGER DEFAULT 0,
    like_count INTEGER DEFAULT 0,
    dislike_count INTEGER DEFAULT 0,
    
    -- 계산된 값
    avg_rating DECIMAL(2,1),
    avg_reading_time DECIMAL(5,2),          -- 실제 평균 읽기 시간
    completion_rate DECIMAL(3,2),           -- 완독률 (0.00 ~ 1.00)
    
    -- 상호작용
    share_count INTEGER DEFAULT 0,
    bookmark_count INTEGER DEFAULT 0,
    print_count INTEGER DEFAULT 0,
    
    -- 업데이트 시간
    last_calculated_at TIMESTAMP DEFAULT NOW(),
    
    FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE CASCADE
);

-- 기사-태그 관계 (다대다)
CREATE TABLE article_tags (
    article_id INTEGER,
    tag_id INTEGER,
    
    PRIMARY KEY (article_id, tag_id),
    FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

-- 기사 키워드 (SEO/검색용)
CREATE TABLE article_keywords (
    article_id INTEGER,
    keyword VARCHAR(50),
    relevance_score DECIMAL(3,2),           -- 0.00 ~ 1.00
    
    PRIMARY KEY (article_id, keyword),
    FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE CASCADE
);

-- 프린터 관련 설정
CREATE TABLE article_print_config (
    article_id INTEGER PRIMARY KEY,
    estimated_pages INTEGER,
    layout_config JSONB,                    -- 레이아웃 설정
    font_size_recommendation VARCHAR(20),
    last_printed_version INTEGER,
    
    FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE CASCADE
);

-- =====================================================
-- 4. 사용자 관심사 및 선호도
-- =====================================================

-- 사용자 관심 카테고리 (온보딩에서 선택)
CREATE TABLE user_interests (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    category_id INTEGER NOT NULL,
    interest_level INTEGER DEFAULT 5 CHECK (interest_level >= 1 AND interest_level <= 10),
    
    selected_at TIMESTAMP DEFAULT NOW(),
    source VARCHAR(20) DEFAULT 'onboarding', -- 'onboarding', 'manual', 'inferred'
    
    UNIQUE(user_id, category_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id)
);

-- =====================================================
-- 5. 읽기 행동 추적
-- =====================================================

-- 읽기 세션
CREATE TABLE reading_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    article_id INTEGER NOT NULL,
    
    -- 시간 추적
    started_at TIMESTAMP NOT NULL,
    ended_at TIMESTAMP,
    total_duration_seconds INTEGER,
    active_duration_seconds INTEGER,        -- 실제 활동 시간 (idle 제외)
    
    -- 읽기 진행
    max_scroll_percentage DECIMAL(5,2),     -- 최대 스크롤 위치 (0-100)
    completion_percentage DECIMAL(5,2),     -- 완독률
    
    -- 컨텍스트
    device_type VARCHAR(20),                -- 'mobile', 'tablet', 'desktop'
    app_version VARCHAR(20),
    reading_mode VARCHAR(20),               -- 'normal', 'night', 'focus'
    font_size INTEGER,
    
    -- 읽기 패턴
    scroll_speed_avg DECIMAL(6,2),          -- 평균 스크롤 속도
    pause_count INTEGER,
    longest_pause_seconds INTEGER,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE CASCADE
);

-- 하이라이트
CREATE TABLE reading_highlights (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    article_id INTEGER NOT NULL,
    session_id INTEGER,
    
    highlighted_text TEXT,
    start_position INTEGER,                 -- 텍스트 내 시작 위치
    end_position INTEGER,
    paragraph_index INTEGER,                -- 몇 번째 단락
    
    highlight_type VARCHAR(20) DEFAULT 'yellow', -- 'yellow', 'important', 'question'
    note TEXT,                              -- 사용자 메모
    
    created_at TIMESTAMP DEFAULT NOW(),
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE CASCADE,
    FOREIGN KEY (session_id) REFERENCES reading_sessions(id) ON DELETE SET NULL
);

-- 읽기 흐름 추적 (어떤 경로로 기사를 읽었는지)
CREATE TABLE reading_flows (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    
    from_article_id INTEGER,
    to_article_id INTEGER NOT NULL,
    
    flow_type VARCHAR(30),                  -- 'search_result', 'recommendation_end', etc
    trigger_element VARCHAR(50),            -- 클릭한 UI 요소
    
    occurred_at TIMESTAMP DEFAULT NOW(),
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (from_article_id) REFERENCES articles(id) ON DELETE CASCADE,
    FOREIGN KEY (to_article_id) REFERENCES articles(id) ON DELETE CASCADE
);

-- 기사 상호작용
CREATE TABLE article_interactions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    article_id INTEGER NOT NULL,
    
    interaction_type VARCHAR(30) NOT NULL,   -- 'like', 'bookmark', 'share', etc
    interaction_value TEXT,                  -- 유연한 값 저장
    
    occurred_at TIMESTAMP DEFAULT NOW(),
    session_id INTEGER,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE CASCADE,
    FOREIGN KEY (session_id) REFERENCES reading_sessions(id) ON DELETE SET NULL
);

-- =====================================================
-- 6. 추천 시스템
-- =====================================================

-- 일일 추천 (배치 생성)
CREATE TABLE daily_recommendations (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    article_id INTEGER NOT NULL,
    recommendation_date DATE NOT NULL,
    
    -- 추천 정보
    rank INTEGER NOT NULL CHECK (rank >= 1 AND rank <= 10),
    score DECIMAL(5,4) CHECK (score >= 0 AND score <= 1),
    recommendation_type VARCHAR(30),        -- 'interest_based', 'collaborative', etc
    reason_code VARCHAR(50),
    reason_display TEXT,                    -- 사용자에게 보여줄 이유
    
    -- 상태 추적
    status VARCHAR(20) DEFAULT 'pending',   -- 'pending', 'viewed', 'read', 'ignored'
    viewed_at TIMESTAMP,
    interaction_type VARCHAR(30),           -- 'clicked', 'dismissed', 'saved'
    
    -- 메타데이터
    generated_at TIMESTAMP DEFAULT NOW(),
    algorithm_version VARCHAR(20),
    
    UNIQUE(user_id, article_id, recommendation_date),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE CASCADE
);

-- 실시간 추천 큐
CREATE TABLE recommendation_queue (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    article_id INTEGER NOT NULL,
    
    score DECIMAL(5,4),
    priority INTEGER DEFAULT 5,
    expires_at TIMESTAMP,
    
    added_at TIMESTAMP DEFAULT NOW(),
    consumed BOOLEAN DEFAULT FALSE,
    consumed_at TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE CASCADE
);

-- 연령대별 선호 패턴 (추천용)
CREATE TABLE demographic_preferences (
    id SERIAL PRIMARY KEY,
    demographic_key VARCHAR(50),            -- 'age:20-24', 'occupation:developer'
    category_id INTEGER,
    preference_score DECIMAL(3,2),          -- 0.00-1.00
    sample_size INTEGER,                    -- 통계 신뢰도
    
    last_calculated_at TIMESTAMP DEFAULT NOW(),
    
    FOREIGN KEY (category_id) REFERENCES categories(id)
);

-- =====================================================
-- 7. 인덱스 생성
-- =====================================================

-- 사용자 관련
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);

-- 기사 관련
CREATE INDEX idx_articles_category ON articles(category_id);
CREATE INDEX idx_articles_published ON articles(published_at DESC);
CREATE INDEX idx_articles_status ON articles(status);
CREATE INDEX idx_articles_slug ON articles(slug);

-- 읽기 행동
CREATE INDEX idx_reading_sessions_user ON reading_sessions(user_id);
CREATE INDEX idx_reading_sessions_article ON reading_sessions(article_id);
CREATE INDEX idx_reading_sessions_started ON reading_sessions(started_at DESC);

-- 추천
CREATE INDEX idx_daily_recommendations_user_date ON daily_recommendations(user_id, recommendation_date);
CREATE INDEX idx_daily_recommendations_status ON daily_recommendations(status);

-- 태그 (GIN 인덱스는 나중에 필요시 추가)
-- CREATE INDEX idx_articles_gin_tags ON articles USING GIN(tags);

-- =====================================================
-- 8. 트리거 함수
-- =====================================================

-- updated_at 자동 업데이트 함수
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- updated_at 트리거 적용
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_articles_updated_at BEFORE UPDATE ON articles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 9. 기본 데이터 타입 정의 (ENUM 대안)
-- =====================================================

-- 체크 제약조건으로 ENUM 효과 구현
ALTER TABLE articles ADD CONSTRAINT chk_source_type 
    CHECK (source_type IN ('ai', 'crawled', 'original'));

ALTER TABLE articles ADD CONSTRAINT chk_status 
    CHECK (status IN ('draft', 'published', 'archived'));

ALTER TABLE articles ADD CONSTRAINT chk_target_audience 
    CHECK (target_audience IN ('beginner', 'intermediate', 'expert', 'all'));

ALTER TABLE daily_recommendations ADD CONSTRAINT chk_status_recommendations
    CHECK (status IN ('pending', 'viewed', 'read', 'ignored'));

-- =====================================================
-- 완료 메시지
-- =====================================================
-- 스키마 생성 완료!
-- 다음 단계: 002_initial_data.sql 실행하여 초기 데이터 삽입
