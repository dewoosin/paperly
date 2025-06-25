-- =============================================
-- Paperly AI 맞춤형 학습 앱 완전한 데이터베이스 스키마
-- 개발일정 40일 완성 계획 기반
-- =============================================

-- UUID 확장 활성화
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- 1. 시스템 관리 테이블 (공통코드, 메시지, 설정)
-- =============================================

-- 시스템 설정 테이블
CREATE TABLE system_configs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    config_key VARCHAR(100) NOT NULL UNIQUE,
    config_value TEXT NOT NULL,
    description TEXT,
    config_type VARCHAR(20) DEFAULT 'string' CHECK (config_type IN ('string', 'number', 'boolean', 'json')),
    is_public BOOLEAN DEFAULT false, -- 클라이언트에서 접근 가능한지
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 공통코드 테이블
CREATE TABLE common_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code_group VARCHAR(50) NOT NULL, -- USER_STATUS, ARTICLE_STATUS 등
    code_value VARCHAR(50) NOT NULL,
    code_name VARCHAR(100) NOT NULL,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    parent_code_id UUID REFERENCES common_codes(id),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(code_group, code_value)
);

-- 시스템 메시지 테이블 (에러메시지, 알림메시지 등)
CREATE TABLE system_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_key VARCHAR(100) NOT NULL UNIQUE,
    message_ko TEXT NOT NULL, -- 한국어 메시지
    message_en TEXT, -- 영어 메시지 (다국어 지원)
    message_type VARCHAR(20) DEFAULT 'info' CHECK (message_type IN ('info', 'warning', 'error', 'success')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 2. 사용자 관련 테이블
-- =============================================

-- 사용자 기본 정보
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    nickname VARCHAR(50) UNIQUE,
    profile_image_url TEXT,
    birth_date DATE,
    gender VARCHAR(10) CHECK (gender IN ('male', 'female', 'other')),
    phone_number VARCHAR(20),
    email_verified BOOLEAN DEFAULT false,
    phone_verified BOOLEAN DEFAULT false,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended', 'deleted')),
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 사용자 프로필 확장 정보
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    occupation VARCHAR(100), -- 직업
    education_level VARCHAR(50), -- 학력
    location VARCHAR(100), -- 지역
    timezone VARCHAR(50) DEFAULT 'Asia/Seoul',
    language_preference VARCHAR(10) DEFAULT 'ko',
    bio TEXT, -- 자기소개
    website_url TEXT,
    social_links JSONB, -- SNS 링크들
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 사용자 설정
CREATE TABLE user_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- 알림 설정
    email_notifications BOOLEAN DEFAULT true,
    push_notifications BOOLEAN DEFAULT true,
    marketing_emails BOOLEAN DEFAULT false,
    daily_recommendation_time TIME DEFAULT '09:00:00', -- 일일 추천 시간
    -- 학습 설정
    daily_reading_goal INTEGER DEFAULT 3, -- 일일 읽기 목표 기사 수
    reading_speed_wpm INTEGER DEFAULT 200, -- 분당 읽기 속도 (Words Per Minute)
    preferred_article_length VARCHAR(20) DEFAULT 'medium' CHECK (preferred_article_length IN ('short', 'medium', 'long', 'any')),
    -- 개인화 설정
    difficulty_level INTEGER DEFAULT 3 CHECK (difficulty_level BETWEEN 1 AND 5), -- 난이도 선호도
    content_freshness_days INTEGER DEFAULT 7, -- 며칠 이내 콘텐츠 선호
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 사용자 관심사
CREATE TABLE user_interests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES categories(id),
    interest_level INTEGER DEFAULT 5 CHECK (interest_level BETWEEN 1 AND 10), -- 관심도 1-10
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, category_id)
);

-- =============================================
-- 3. 인증 및 보안 테이블
-- =============================================

-- 리프레시 토큰
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    device_id VARCHAR(255),
    device_name VARCHAR(100),
    user_agent TEXT,
    ip_address INET,
    expires_at TIMESTAMPTZ NOT NULL,
    last_used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 이메일 인증 토큰
CREATE TABLE email_verification_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 비밀번호 재설정 토큰
CREATE TABLE password_reset_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(100) NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 사용자 로그인 로그
CREATE TABLE user_login_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    email VARCHAR(255),
    ip_address INET,
    user_agent TEXT,
    login_success BOOLEAN,
    failure_reason VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 4. 콘텐츠 관리 테이블
-- =============================================

-- 카테고리 (계층적 구조)
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    parent_id UUID REFERENCES categories(id),
    icon_name VARCHAR(50), -- 아이콘 이름
    color_code VARCHAR(7), -- 색상 코드 (#FF0000)
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    seo_title VARCHAR(100),
    seo_description VARCHAR(200),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 태그
CREATE TABLE tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) NOT NULL UNIQUE,
    slug VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    color_code VARCHAR(7),
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 기사 메타데이터
CREATE TABLE articles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(200) NOT NULL,
    slug VARCHAR(200) NOT NULL UNIQUE,
    summary TEXT NOT NULL, -- 요약 (2-3문장)
    content_file_path TEXT, -- 실제 콘텐츠 파일 경로
    featured_image_url TEXT,
    author_name VARCHAR(100),
    author_bio TEXT,
    source_url TEXT, -- 원본 기사 URL
    category_id UUID NOT NULL REFERENCES categories(id),
    -- 콘텐츠 메타데이터
    word_count INTEGER DEFAULT 0,
    estimated_reading_time INTEGER DEFAULT 0, -- 분 단위
    difficulty_level INTEGER DEFAULT 3 CHECK (difficulty_level BETWEEN 1 AND 5),
    -- SEO
    seo_title VARCHAR(100),
    seo_description VARCHAR(200),
    seo_keywords TEXT[],
    -- 상태 관리
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived', 'deleted')),
    is_featured BOOLEAN DEFAULT false,
    is_premium BOOLEAN DEFAULT false,
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 기사-태그 연결
CREATE TABLE article_tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    article_id UUID NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(article_id, tag_id)
);

-- 기사 통계
CREATE TABLE article_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    article_id UUID NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
    view_count INTEGER DEFAULT 0,
    unique_view_count INTEGER DEFAULT 0,
    like_count INTEGER DEFAULT 0,
    bookmark_count INTEGER DEFAULT 0,
    share_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    average_rating DECIMAL(3,2) DEFAULT 0.00,
    rating_count INTEGER DEFAULT 0,
    completion_rate DECIMAL(5,2) DEFAULT 0.00, -- 완독률 (%)
    average_reading_time INTEGER DEFAULT 0, -- 평균 읽기 시간 (초)
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 기사 키워드 (SEO 및 검색용)
CREATE TABLE article_keywords (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    article_id UUID NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
    keyword VARCHAR(100) NOT NULL,
    relevance_score DECIMAL(3,2) DEFAULT 1.00, -- 관련도 점수
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 5. 사용자 활동 및 읽기 추적 테이블
-- =============================================

-- 읽기 세션
CREATE TABLE reading_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    article_id UUID NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
    device_type VARCHAR(20) DEFAULT 'mobile' CHECK (device_type IN ('mobile', 'tablet', 'desktop', 'web')),
    started_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMPTZ,
    duration_seconds INTEGER, -- 실제 읽기 시간
    scroll_percentage DECIMAL(5,2) DEFAULT 0.00, -- 스크롤 진행률
    is_completed BOOLEAN DEFAULT false, -- 완독 여부
    reading_speed_wpm INTEGER, -- 이 세션의 읽기 속도
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 기사 북마크
CREATE TABLE bookmarks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    article_id UUID NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
    folder_name VARCHAR(50) DEFAULT 'default', -- 북마크 폴더
    notes TEXT, -- 개인 메모
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, article_id)
);

-- 기사 좋아요
CREATE TABLE article_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    article_id UUID NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, article_id)
);

-- 기사 평점
CREATE TABLE article_ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    article_id UUID NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, article_id)
);

-- 읽기 하이라이트
CREATE TABLE reading_highlights (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    article_id UUID NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
    highlighted_text TEXT NOT NULL,
    start_position INTEGER NOT NULL, -- 텍스트 시작 위치
    end_position INTEGER NOT NULL, -- 텍스트 끝 위치
    color_code VARCHAR(7) DEFAULT '#FFFF00', -- 하이라이트 색상
    notes TEXT, -- 개인 메모
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 사용자 기사 상호작용 로그
CREATE TABLE article_interactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    article_id UUID NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
    interaction_type VARCHAR(20) NOT NULL CHECK (interaction_type IN ('view', 'like', 'bookmark', 'share', 'comment', 'rating')),
    interaction_data JSONB, -- 추가 데이터 (공유 플랫폼, 평점 등)
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 6. AI 추천 시스템 테이블
-- =============================================

-- 사용자 선호도 프로필 (AI 학습 결과)
CREATE TABLE user_preference_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_preferences JSONB, -- 카테고리별 선호도 점수
    tag_preferences JSONB, -- 태그별 선호도 점수
    reading_time_preferences JSONB, -- 읽기 시간대 선호도
    difficulty_preferences JSONB, -- 난이도별 선호도
    content_length_preferences JSONB, -- 글 길이별 선호도
    source_preferences JSONB, -- 출처별 선호도
    last_updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    model_version VARCHAR(20) DEFAULT '1.0' -- AI 모델 버전
);

-- 일일 추천 기사 (배치 처리 결과)
CREATE TABLE daily_recommendations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    article_id UUID NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
    recommendation_date DATE NOT NULL,
    recommendation_score DECIMAL(5,3) NOT NULL, -- 추천 점수 (0.000-1.000)
    recommendation_reason JSONB, -- 추천 이유 (category_match, user_history 등)
    position_in_feed INTEGER NOT NULL, -- 피드에서의 순서
    is_clicked BOOLEAN DEFAULT false,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, article_id, recommendation_date)
);

-- 실시간 추천 큐
CREATE TABLE recommendation_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    article_id UUID NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
    recommendation_type VARCHAR(30) NOT NULL CHECK (recommendation_type IN ('trending', 'personalized', 'similar', 'category_based', 'collaborative')),
    score DECIMAL(5,3) NOT NULL,
    context_data JSONB, -- 추천 컨텍스트 데이터
    expires_at TIMESTAMPTZ NOT NULL,
    served_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 연령대별 선호도 통계 (집단 지성)
CREATE TABLE demographic_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    age_group VARCHAR(20) NOT NULL, -- 20s, 30s, 40s, 50s+
    gender VARCHAR(10),
    category_id UUID REFERENCES categories(id),
    preference_score DECIMAL(5,3) NOT NULL,
    interaction_count INTEGER DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(age_group, gender, category_id)
);

-- =============================================
-- 7. 구독 및 결제 테이블
-- =============================================

-- 구독 플랜
CREATE TABLE subscription_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) NOT NULL,
    description TEXT,
    price_monthly DECIMAL(10,2) NOT NULL,
    price_yearly DECIMAL(10,2),
    features JSONB, -- 플랜별 기능 목록
    max_daily_articles INTEGER, -- 일일 읽기 제한
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 사용자 구독
CREATE TABLE user_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES subscription_plans(id),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired', 'paused')),
    billing_cycle VARCHAR(10) DEFAULT 'monthly' CHECK (billing_cycle IN ('monthly', 'yearly')),
    price_paid DECIMAL(10,2) NOT NULL,
    started_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    ends_at TIMESTAMPTZ,
    auto_renewal BOOLEAN DEFAULT true,
    payment_method VARCHAR(20), -- stripe, apple_pay, google_pay
    external_subscription_id VARCHAR(100), -- 외부 결제 시스템 ID
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 결제 내역
CREATE TABLE payment_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES user_subscriptions(id),
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('payment', 'refund', 'chargeback')),
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'KRW',
    payment_method VARCHAR(20),
    external_transaction_id VARCHAR(100),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'cancelled')),
    processed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 8. 알림 및 커뮤니케이션 테이블
-- =============================================

-- 알림 템플릿
CREATE TABLE notification_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_key VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    title_template TEXT NOT NULL,
    body_template TEXT NOT NULL,
    notification_type VARCHAR(20) NOT NULL CHECK (notification_type IN ('push', 'email', 'in_app')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 사용자 알림
CREATE TABLE user_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    notification_type VARCHAR(20) NOT NULL CHECK (notification_type IN ('push', 'email', 'in_app')),
    data JSONB, -- 알림 관련 추가 데이터
    is_read BOOLEAN DEFAULT false,
    sent_at TIMESTAMPTZ,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 이메일 발송 로그
CREATE TABLE email_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    email_address VARCHAR(255) NOT NULL,
    subject VARCHAR(200) NOT NULL,
    template_key VARCHAR(100),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed', 'bounced')),
    external_message_id VARCHAR(100),
    error_message TEXT,
    sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 9. 분석 및 로깅 테이블
-- =============================================

-- 사용자 활동 로그
CREATE TABLE user_activity_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(50) NOT NULL, -- login, logout, read_article, bookmark, etc.
    resource_type VARCHAR(50), -- article, category, user, etc.
    resource_id UUID,
    details JSONB, -- 추가 상세 정보
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 시스템 에러 로그
CREATE TABLE system_error_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    error_level VARCHAR(10) NOT NULL CHECK (error_level IN ('info', 'warning', 'error', 'critical')),
    error_code VARCHAR(50),
    error_message TEXT NOT NULL,
    stack_trace TEXT,
    request_url TEXT,
    request_method VARCHAR(10),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 일일 통계 요약
CREATE TABLE daily_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    stats_date DATE NOT NULL UNIQUE,
    active_users INTEGER DEFAULT 0,
    new_users INTEGER DEFAULT 0,
    total_articles_read INTEGER DEFAULT 0,
    total_reading_time_minutes INTEGER DEFAULT 0,
    total_bookmarks INTEGER DEFAULT 0,
    total_shares INTEGER DEFAULT 0,
    revenue_krw DECIMAL(12,2) DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 인덱스 생성
-- =============================================

-- 사용자 관련 인덱스
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_created_at ON users(created_at);

-- 기사 관련 인덱스
CREATE INDEX idx_articles_category_id ON articles(category_id);
CREATE INDEX idx_articles_status ON articles(status);
CREATE INDEX idx_articles_published_at ON articles(published_at);
CREATE INDEX idx_articles_is_featured ON articles(is_featured);
CREATE INDEX idx_articles_title_search ON articles USING gin(to_tsvector('korean', title));
CREATE INDEX idx_articles_content_search ON articles USING gin(to_tsvector('korean', summary));

-- 읽기 추적 인덱스
CREATE INDEX idx_reading_sessions_user_id ON reading_sessions(user_id);
CREATE INDEX idx_reading_sessions_article_id ON reading_sessions(article_id);
CREATE INDEX idx_reading_sessions_started_at ON reading_sessions(started_at);

-- 추천 시스템 인덱스
CREATE INDEX idx_daily_recommendations_user_date ON daily_recommendations(user_id, recommendation_date);
CREATE INDEX idx_recommendation_queue_user_id ON recommendation_queue(user_id);
CREATE INDEX idx_recommendation_queue_expires_at ON recommendation_queue(expires_at);

-- 알림 인덱스
CREATE INDEX idx_user_notifications_user_id ON user_notifications(user_id);
CREATE INDEX idx_user_notifications_is_read ON user_notifications(is_read);

-- 활동 로그 인덱스
CREATE INDEX idx_user_activity_logs_user_id ON user_activity_logs(user_id);
CREATE INDEX idx_user_activity_logs_action ON user_activity_logs(action);
CREATE INDEX idx_user_activity_logs_created_at ON user_activity_logs(created_at);

-- =============================================
-- 트리거 함수 생성
-- =============================================

-- updated_at 자동 업데이트 함수
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- updated_at 트리거 생성
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_settings_updated_at BEFORE UPDATE ON user_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_articles_updated_at BEFORE UPDATE ON articles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_article_ratings_updated_at BEFORE UPDATE ON article_ratings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_subscriptions_updated_at BEFORE UPDATE ON user_subscriptions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 기사 통계 업데이트 함수
CREATE OR REPLACE FUNCTION update_article_stats()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- 새로운 상호작용 시 통계 업데이트
        UPDATE article_stats 
        SET 
            view_count = CASE WHEN NEW.interaction_type = 'view' THEN view_count + 1 ELSE view_count END,
            like_count = CASE WHEN NEW.interaction_type = 'like' THEN like_count + 1 ELSE like_count END,
            bookmark_count = CASE WHEN NEW.interaction_type = 'bookmark' THEN bookmark_count + 1 ELSE bookmark_count END,
            share_count = CASE WHEN NEW.interaction_type = 'share' THEN share_count + 1 ELSE share_count END,
            updated_at = CURRENT_TIMESTAMP
        WHERE article_id = NEW.article_id;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

-- 기사 상호작용 통계 트리거
CREATE TRIGGER update_article_stats_trigger 
    AFTER INSERT ON article_interactions 
    FOR EACH ROW EXECUTE FUNCTION update_article_stats();

-- =============================================
-- 기본 데이터 삽입
-- =============================================

-- 시스템 설정 기본 데이터
INSERT INTO system_configs (config_key, config_value, description, config_type, is_public) VALUES
('app_name', 'Paperly', '앱 이름', 'string', true),
('app_version', '1.0.0', '앱 버전', 'string', true),
('max_daily_free_articles', '3', '무료 사용자 일일 기사 제한', 'number', false),
('recommendation_refresh_hours', '6', '추천 새로고침 주기 (시간)', 'number', false),
('ai_model_version', 'v1.0', 'AI 추천 모델 버전', 'string', false);

-- 공통코드 기본 데이터
INSERT INTO common_codes (code_group, code_value, code_name, sort_order) VALUES
('USER_STATUS', 'ACTIVE', '활성', 1),
('USER_STATUS', 'INACTIVE', '비활성', 2),
('USER_STATUS', 'SUSPENDED', '정지', 3),
('USER_STATUS', 'DELETED', '삭제', 4),
('ARTICLE_STATUS', 'DRAFT', '초안', 1),
('ARTICLE_STATUS', 'PUBLISHED', '발행', 2),
('ARTICLE_STATUS', 'ARCHIVED', '보관', 3),
('ARTICLE_STATUS', 'DELETED', '삭제', 4),
('DIFFICULTY_LEVEL', '1', '매우 쉬움', 1),
('DIFFICULTY_LEVEL', '2', '쉬움', 2),
('DIFFICULTY_LEVEL', '3', '보통', 3),
('DIFFICULTY_LEVEL', '4', '어려움', 4),
('DIFFICULTY_LEVEL', '5', '매우 어려움', 5);

-- 카테고리 기본 데이터
INSERT INTO categories (name, slug, description, icon_name, color_code, sort_order) VALUES
('기술', 'technology', 'IT, 프로그래밍, 인공지능, 과학기술', 'code', '#007ACC', 1),
('비즈니스', 'business', '경영, 마케팅, 창업, 경제', 'briefcase', '#28A745', 2),
('인문학', 'humanities', '철학, 역사, 문학, 예술', 'book', '#6F42C1', 3),
('과학', 'science', '자연과학, 의학, 연구', 'flask', '#FD7E14', 4),
('라이프스타일', 'lifestyle', '건강, 요리, 여행, 취미', 'heart', '#E83E8C', 5),
('사회', 'society', '정치, 사회이슈, 환경', 'users', '#20C997', 6),
('교육', 'education', '학습, 교육방법, 자기계발', 'graduation-cap', '#FFC107', 7),
('문화', 'culture', '영화, 음악, 예술, 엔터테인먼트', 'palette', '#DC3545', 8);

-- 태그 기본 데이터
INSERT INTO tags (name, slug, description, color_code) VALUES
('AI', 'ai', '인공지능', '#007ACC'),
('머신러닝', 'machine-learning', '기계학습', '#007ACC'),
('블록체인', 'blockchain', '블록체인 기술', '#F39C12'),
('스타트업', 'startup', '창업', '#28A745'),
('마케팅', 'marketing', '마케팅 전략', '#28A745'),
('철학', 'philosophy', '철학적 사고', '#6F42C1'),
('심리학', 'psychology', '심리학', '#E83E8C'),
('건강', 'health', '건강 관리', '#E83E8C'),
('요리', 'cooking', '요리법', '#FFC107'),
('여행', 'travel', '여행 정보', '#20C997'),
('환경', 'environment', '환경 보호', '#28A745'),
('경제', 'economy', '경제 이슈', '#FD7E14'),
('정치', 'politics', '정치 이슈', '#6C757D'),
('예술', 'art', '예술 작품', '#DC3545'),
('음악', 'music', '음악', '#DC3545'),
('영화', 'movie', '영화 리뷰', '#DC3545'),
('독서', 'reading', '독서법', '#6F42C1'),
('자기계발', 'self-development', '자기계발', '#FFC107'),
('리더십', 'leadership', '리더십', '#28A745');

-- 구독 플랜 기본 데이터
INSERT INTO subscription_plans (name, description, price_monthly, price_yearly, features, max_daily_articles) VALUES
('무료', '기본 기능 제공', 0.00, 0.00, '{"daily_articles": 3, "bookmarks": true, "basic_recommendations": true}', 3),
('프리미엄', '모든 기능 이용 가능', 9900.00, 99000.00, '{"unlimited_articles": true, "advanced_ai": true, "priority_support": true, "offline_reading": true}', -1),
('프로', '전문가를 위한 고급 기능', 19900.00, 199000.00, '{"everything_in_premium": true, "api_access": true, "custom_categories": true, "analytics": true}', -1);

-- 알림 템플릿 기본 데이터
INSERT INTO notification_templates (template_key, name, title_template, body_template, notification_type) VALUES
('daily_recommendation', '일일 추천', '오늘의 맞춤 기사가 준비되었어요!', '{{user_name}}님을 위한 {{article_count}}개의 새로운 기사를 확인해보세요.', 'push'),
('reading_streak', '연속 읽기 달성', '{{streak_days}}일 연속 읽기 달성! 🎉', '꾸준한 학습 습관을 유지하고 계시네요. 계속 화이팅!', 'push'),
('weekly_summary', '주간 읽기 요약', '이번 주 읽기 활동 요약', '{{articles_read}}개 기사를 읽고 {{reading_time}}분을 학습에 투자하셨습니다.', 'email'),
('subscription_reminder', '구독 갱신 알림', '구독이 곧 만료됩니다', '{{days_left}}일 후 구독이 만료됩니다. 지속적인 학습을 위해 갱신해주세요.', 'email');

-- =============================================
-- 뷰 생성 (자주 사용하는 복잡한 쿼리)
-- =============================================

-- 사용자별 읽기 통계 뷰
CREATE VIEW user_reading_stats AS
SELECT 
    u.id as user_id,
    u.name,
    COUNT(rs.id) as total_reading_sessions,
    COUNT(CASE WHEN rs.is_completed = true THEN 1 END) as completed_articles,
    COALESCE(AVG(rs.duration_seconds), 0) as avg_reading_time,
    COALESCE(SUM(rs.duration_seconds), 0) as total_reading_time,
    COUNT(b.id) as total_bookmarks,
    COUNT(al.id) as total_likes
FROM users u
LEFT JOIN reading_sessions rs ON u.id = rs.user_id
LEFT JOIN bookmarks b ON u.id = b.user_id
LEFT JOIN article_likes al ON u.id = al.user_id
WHERE u.status = 'active'
GROUP BY u.id, u.name;

-- 인기 기사 뷰
CREATE VIEW popular_articles AS
SELECT 
    a.*,
    c.name as category_name,
    ast.view_count,
    ast.like_count,
    ast.bookmark_count,
    ast.average_rating,
    ast.completion_rate
FROM articles a
JOIN categories c ON a.category_id = c.id
JOIN article_stats ast ON a.id = ast.article_id
WHERE a.status = 'published'
ORDER BY 
    (ast.view_count * 0.3 + ast.like_count * 0.4 + ast.bookmark_count * 0.3) DESC;

-- =============================================
-- 파티셔닝 (대용량 데이터 대비)
-- =============================================

-- 읽기 세션 테이블 월별 파티셔닝 준비
-- CREATE TABLE reading_sessions_2024_01 PARTITION OF reading_sessions
--     FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

-- 활동 로그 테이블 월별 파티셔닝 준비  
-- CREATE TABLE user_activity_logs_2024_01 PARTITION OF user_activity_logs
--     FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

-- =============================================
-- 스키마 완성!
-- 총 테이블 수: 32개
-- - 시스템 관리: 3개
-- - 사용자 관련: 4개  
-- - 인증/보안: 5개
-- - 콘텐츠 관리: 6개
-- - 활동 추적: 6개
-- - AI 추천: 4개
-- - 구독/결제: 3개
-- - 알림: 3개
-- - 분석/로깅: 3개
-- =============================================
