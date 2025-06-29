-- =============================================
-- Paperly 고급 추천 시스템 및 AI 분석 스키마
-- Google/Facebook 수준의 개인화 추천 및 머신러닝
-- Version: 2.0.0
-- =============================================

-- paperly 스키마 사용 설정
SET search_path TO paperly, public;

-- =============================================
-- 1. 사용자 프로필 및 행동 분석
-- =============================================

-- 사용자 관심사 프로필 (명시적 + 암시적)
CREATE TABLE IF NOT EXISTS paperly.user_interest_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    
    -- 명시적 관심사 (사용자가 직접 설정)
    explicit_interests JSONB DEFAULT '{}',
    explicit_categories UUID[],
    explicit_tags TEXT[],
    
    -- 암시적 관심사 (행동 분석 기반)
    implicit_interests JSONB DEFAULT '{}',
    behavior_categories JSONB DEFAULT '{}',
    content_preferences JSONB DEFAULT '{}',
    
    -- 시간대별 관심사 변화
    morning_interests JSONB DEFAULT '{}',
    afternoon_interests JSONB DEFAULT '{}',
    evening_interests JSONB DEFAULT '{}',
    weekend_interests JSONB DEFAULT '{}',
    
    -- 메타데이터
    profile_confidence_score DECIMAL(3,2) DEFAULT 0.00,
    last_analyzed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id)
);

-- 사용자 읽기 패턴 분석
CREATE TABLE IF NOT EXISTS paperly.user_reading_patterns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    
    -- 읽기 속도 및 패턴
    average_reading_speed_wpm INTEGER DEFAULT 200,
    preferred_article_length VARCHAR(20) DEFAULT 'medium',
    optimal_reading_time_minutes INTEGER DEFAULT 10,
    
    -- 시간대별 읽기 패턴
    morning_reading_probability DECIMAL(3,2) DEFAULT 0.33,
    afternoon_reading_probability DECIMAL(3,2) DEFAULT 0.33,
    evening_reading_probability DECIMAL(3,2) DEFAULT 0.33,
    
    -- 요일별 읽기 패턴
    weekday_reading_frequency INTEGER DEFAULT 0,
    weekend_reading_frequency INTEGER DEFAULT 0,
    
    -- 디바이스별 읽기 패턴
    mobile_reading_percentage DECIMAL(5,2) DEFAULT 70.00,
    desktop_reading_percentage DECIMAL(5,2) DEFAULT 30.00,
    
    -- 완독률 및 참여도
    average_completion_rate DECIMAL(5,2) DEFAULT 0.00,
    average_engagement_score DECIMAL(3,2) DEFAULT 0.00,
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id)
);

-- =============================================
-- 2. 콘텐츠 AI 분석 및 임베딩
-- =============================================

-- 콘텐츠 AI 분석 결과
CREATE TABLE IF NOT EXISTS paperly.content_analysis (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    article_id UUID NOT NULL REFERENCES paperly.articles(id) ON DELETE CASCADE,
    
    -- AI 분석 결과
    ai_generated_summary TEXT,
    ai_keywords TEXT[],
    ai_topics JSONB,
    sentiment_score DECIMAL(3,2),
    complexity_score DECIMAL(3,2),
    
    -- 언어학적 분석
    readability_score DECIMAL(5,2),
    tone_analysis JSONB,
    named_entities JSONB,
    
    -- 콘텐츠 특성
    estimated_expertise_level INTEGER CHECK (estimated_expertise_level BETWEEN 1 AND 5),
    target_audience JSONB,
    content_freshness_score DECIMAL(3,2),
    
    -- 메타데이터
    analysis_model_version VARCHAR(20) DEFAULT 'v1.0',
    analyzed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(article_id)
);

-- 콘텐츠 벡터 임베딩 (AI 추천용)
CREATE TABLE IF NOT EXISTS paperly.content_embeddings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    article_id UUID NOT NULL REFERENCES paperly.articles(id) ON DELETE CASCADE,
    
    -- 벡터 임베딩 (다차원 벡터를 JSONB로 저장)
    title_embedding JSONB,
    content_embedding JSONB,
    combined_embedding JSONB,
    
    -- 임베딩 메타데이터
    embedding_model VARCHAR(50) DEFAULT 'openai-ada-002',
    embedding_dimension INTEGER DEFAULT 1536,
    embedding_quality_score DECIMAL(3,2),
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(article_id)
);

-- 사용자 벡터 임베딩 (개인화용)
CREATE TABLE IF NOT EXISTS paperly.user_embeddings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    
    -- 사용자 선호도 벡터
    preference_embedding JSONB,
    behavior_embedding JSONB,
    combined_embedding JSONB,
    
    -- 시간적 임베딩
    temporal_embeddings JSONB,
    
    -- 임베딩 메타데이터
    embedding_confidence DECIMAL(3,2),
    last_interaction_count INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id)
);

-- =============================================
-- 3. 추천 시스템 테이블
-- =============================================

-- 추천 모델 메타데이터
CREATE TABLE IF NOT EXISTS paperly.recommendation_models (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_name VARCHAR(100) NOT NULL UNIQUE,
    model_type VARCHAR(50) NOT NULL,
    model_version VARCHAR(20) NOT NULL,
    
    -- 모델 성능 지표
    accuracy_score DECIMAL(5,4),
    precision_score DECIMAL(5,4),
    recall_score DECIMAL(5,4),
    f1_score DECIMAL(5,4),
    
    -- 모델 설정
    hyperparameters JSONB,
    training_data_period INTERVAL,
    
    -- 상태 관리
    is_active BOOLEAN DEFAULT false,
    is_production BOOLEAN DEFAULT false,
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 실시간 개인화 추천
CREATE TABLE IF NOT EXISTS paperly.user_recommendations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    article_id UUID NOT NULL REFERENCES paperly.articles(id) ON DELETE CASCADE,
    model_id UUID NOT NULL REFERENCES paperly.recommendation_models(id),
    
    -- 추천 점수 및 순위
    recommendation_score DECIMAL(8,6) NOT NULL,
    rank_position INTEGER NOT NULL,
    
    -- 추천 이유 및 설명
    recommendation_reasons JSONB,
    explanation_text TEXT,
    
    -- 추천 컨텍스트
    recommendation_context VARCHAR(50),
    time_slot VARCHAR(20),
    device_type VARCHAR(20),
    
    -- 추천 성과 추적
    was_shown BOOLEAN DEFAULT false,
    was_clicked BOOLEAN DEFAULT false,
    was_read BOOLEAN DEFAULT false,
    engagement_score DECIMAL(3,2),
    
    -- 시간 정보
    generated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    shown_at TIMESTAMPTZ,
    clicked_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP + INTERVAL '24 hours'),
    
    UNIQUE(user_id, article_id, recommendation_context, generated_at)
);

-- 추천 성과 피드백
CREATE TABLE IF NOT EXISTS paperly.recommendation_feedback (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recommendation_id UUID NOT NULL REFERENCES paperly.user_recommendations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    
    -- 피드백 유형
    feedback_type VARCHAR(30) NOT NULL,
    feedback_action VARCHAR(50) NOT NULL,
    feedback_value DECIMAL(3,2),
    
    -- 상세 피드백 정보
    reading_duration_seconds INTEGER,
    completion_percentage DECIMAL(5,2),
    user_rating INTEGER CHECK (user_rating BETWEEN 1 AND 5),
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 4. A/B 테스팅 프레임워크
-- =============================================

-- A/B 테스트 실험
CREATE TABLE IF NOT EXISTS paperly.ab_test_experiments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    experiment_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    
    -- 실험 설정
    experiment_type VARCHAR(50) NOT NULL,
    control_group_percentage DECIMAL(5,2) DEFAULT 50.00,
    treatment_variants JSONB,
    
    -- 성공 지표
    primary_metric VARCHAR(50) NOT NULL,
    secondary_metrics TEXT[],
    
    -- 실험 기간
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    
    -- 상태
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'running', 'paused', 'completed', 'cancelled')),
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- A/B 테스트 참가자
CREATE TABLE IF NOT EXISTS paperly.ab_test_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    experiment_id UUID NOT NULL REFERENCES paperly.ab_test_experiments(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    
    -- 그룹 할당
    group_type VARCHAR(20) NOT NULL,
    variant_name VARCHAR(50),
    assignment_context JSONB,
    
    -- 참가 시간
    assigned_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    first_exposure_at TIMESTAMPTZ,
    
    UNIQUE(experiment_id, user_id)
);

-- A/B 테스트 결과
CREATE TABLE IF NOT EXISTS paperly.ab_test_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    experiment_id UUID NOT NULL REFERENCES paperly.ab_test_experiments(id) ON DELETE CASCADE,
    participant_id UUID NOT NULL REFERENCES paperly.ab_test_participants(id) ON DELETE CASCADE,
    
    -- 측정 지표
    metric_name VARCHAR(50) NOT NULL,
    metric_value DECIMAL(10,4) NOT NULL,
    measurement_context JSONB,
    
    measured_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 5. 분석 뷰
-- =============================================

-- 사용자 360도 뷰
CREATE VIEW IF NOT EXISTS paperly.user_360_view AS
SELECT 
    u.id as user_id,
    u.email,
    u.name,
    u.status,
    u.created_at as user_since,
    
    -- 읽기 패턴
    rp.average_reading_speed_wpm,
    rp.preferred_article_length,
    rp.average_completion_rate,
    rp.average_engagement_score,
    
    -- 관심사 프로필
    ip.explicit_interests,
    ip.implicit_interests,
    ip.profile_confidence_score,
    
    -- 활동 통계 (최근 30일)
    recent_stats.articles_read,
    recent_stats.total_reading_time,
    recent_stats.avg_daily_articles,
    recent_stats.last_active_date
    
FROM paperly.users u
LEFT JOIN paperly.user_reading_patterns rp ON u.id = rp.user_id
LEFT JOIN paperly.user_interest_profiles ip ON u.id = ip.user_id
LEFT JOIN (
    SELECT 
        user_id,
        COUNT(DISTINCT article_id) as articles_read,
        SUM(reading_duration_seconds) as total_reading_time,
        COUNT(DISTINCT article_id)::float / 30 as avg_daily_articles,
        MAX(started_at::date) as last_active_date
    FROM paperly.reading_sessions
    WHERE started_at >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY user_id
) recent_stats ON u.id = recent_stats.user_id;

-- 콘텐츠 성과 대시보드 뷰
CREATE VIEW IF NOT EXISTS paperly.content_performance_dashboard AS
SELECT 
    a.id as article_id,
    a.title,
    a.category_id,
    a.published_at,
    a.word_count,
    a.estimated_reading_time,
    
    -- 기본 지표
    ast.view_count,
    ast.unique_view_count,
    ast.average_completion_rate,
    ast.average_reading_time,
    ast.like_count,
    ast.bookmark_count,
    ast.share_count,
    
    -- 고급 지표
    ca.complexity_score,
    ca.sentiment_score,
    ca.readability_score,
    
    -- 추천 성과
    rec_stats.total_recommendations,
    rec_stats.recommendation_ctr,
    rec_stats.recommendation_conversion,
    
    -- 사용자 참여도
    engagement_stats.avg_engagement_score,
    engagement_stats.high_engagement_users
    
FROM paperly.articles a
LEFT JOIN paperly.article_stats ast ON a.id = ast.article_id
LEFT JOIN paperly.content_analysis ca ON a.id = ca.article_id
LEFT JOIN (
    SELECT 
        article_id,
        COUNT(*) as total_recommendations,
        (COUNT(*) FILTER (WHERE was_clicked = true))::float / NULLIF(COUNT(*) FILTER (WHERE was_shown = true), 0) as recommendation_ctr,
        (COUNT(*) FILTER (WHERE was_read = true))::float / NULLIF(COUNT(*) FILTER (WHERE was_clicked = true), 0) as recommendation_conversion
    FROM paperly.user_recommendations
    GROUP BY article_id
) rec_stats ON a.id = rec_stats.article_id
LEFT JOIN (
    SELECT 
        article_id,
        AVG(engagement_score) as avg_engagement_score,
        COUNT(*) FILTER (WHERE engagement_score > 0.7) as high_engagement_users
    FROM paperly.user_recommendations
    WHERE engagement_score IS NOT NULL
    GROUP BY article_id
) engagement_stats ON a.id = engagement_stats.article_id;

-- =============================================
-- 6. 추천 시스템 인덱스
-- =============================================

-- 사용자 상호작용 최적화 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_interest_profiles_user ON paperly.user_interest_profiles (user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_reading_patterns_user ON paperly.user_reading_patterns (user_id);

-- 추천 시스템 최적화 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_recommendations_user_context ON paperly.user_recommendations (user_id, recommendation_context, expires_at);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_recommendations_score ON paperly.user_recommendations (recommendation_score DESC) WHERE expires_at > CURRENT_TIMESTAMP;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_recommendations_performance ON paperly.user_recommendations (was_shown, was_clicked, was_read);

-- 콘텐츠 임베딩 검색 최적화
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_content_embeddings_gin ON paperly.content_embeddings USING gin (combined_embedding);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_embeddings_gin ON paperly.user_embeddings USING gin (combined_embedding);

-- A/B 테스트 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_ab_participants_experiment_user ON paperly.ab_test_participants (experiment_id, user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_ab_results_experiment_metric ON paperly.ab_test_results (experiment_id, metric_name, measured_at);

-- =============================================
-- 7. 자동화 함수 및 트리거
-- =============================================

-- 사용자 관심사 프로필 자동 업데이트 함수
CREATE OR REPLACE FUNCTION paperly.update_user_interest_profile()
RETURNS TRIGGER AS $$
BEGIN
    -- 새로운 상호작용 발생 시 사용자 관심사 프로필 업데이트
    IF TG_OP = 'INSERT' THEN
        UPDATE paperly.user_interest_profiles 
        SET updated_at = CURRENT_TIMESTAMP
        WHERE user_id = NEW.user_id;
        
        -- 사용자 임베딩도 업데이트 필요 표시
        UPDATE paperly.user_embeddings 
        SET updated_at = CURRENT_TIMESTAMP
        WHERE user_id = NEW.user_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 사용자 상호작용 발생 시 프로필 업데이트 트리거
CREATE TRIGGER update_user_profile_trigger 
    AFTER INSERT ON paperly.reading_sessions 
    FOR EACH ROW EXECUTE FUNCTION paperly.update_user_interest_profile();

-- =============================================
-- 완료 메시지
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '================================='
    RAISE NOTICE 'Paperly 고급 추천 시스템 스키마 생성 완료';
    RAISE NOTICE '================================='
    RAISE NOTICE '생성된 추천 시스템 테이블:';
    RAISE NOTICE '- user_interest_profiles: 사용자 관심사 프로필';
    RAISE NOTICE '- user_reading_patterns: 읽기 패턴 분석';
    RAISE NOTICE '- content_analysis: 콘텐츠 AI 분석';
    RAISE NOTICE '- content_embeddings: 콘텐츠 벡터 임베딩';
    RAISE NOTICE '- user_embeddings: 사용자 벡터 임베딩';
    RAISE NOTICE '- user_recommendations: 개인화 추천';
    RAISE NOTICE '- ab_test_experiments: A/B 테스팅';
    RAISE NOTICE '================================='
    RAISE NOTICE '다음 단계: 003_user_behavior_analytics.sql 실행';
    RAISE NOTICE '================================='
END $$;