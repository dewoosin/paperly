-- =============================================
-- Paperly 고급 추천 시스템 데이터베이스 스키마
-- Google/Facebook 수준의 사용자 행동 분석 및 개인화 추천
-- =============================================

-- paperly 스키마 사용 설정
SET search_path TO paperly, public;

-- UUID 및 확장 기능 활성화
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- 텍스트 유사도 검색
CREATE EXTENSION IF NOT EXISTS "btree_gin"; -- 복합 인덱스 최적화

-- =============================================
-- 1. 고급 사용자 프로필 및 행동 분석 테이블
-- =============================================

-- 사용자 관심사 프로필 (명시적 + 암시적)
CREATE TABLE paperly.user_interest_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    
    -- 명시적 관심사 (사용자가 직접 설정)
    explicit_interests JSONB DEFAULT '{}', -- {"technology": 0.9, "business": 0.7, "science": 0.8}
    explicit_categories UUID[], -- 관심 카테고리 ID 배열
    explicit_tags TEXT[], -- 관심 태그 배열
    
    -- 암시적 관심사 (행동 분석 기반)
    implicit_interests JSONB DEFAULT '{}', -- AI가 분석한 관심도 점수
    behavior_categories JSONB DEFAULT '{}', -- 행동 기반 카테고리 선호도
    content_preferences JSONB DEFAULT '{}', -- 콘텐츠 유형 선호도 (길이, 난이도 등)
    
    -- 시간대별 관심사 변화
    morning_interests JSONB DEFAULT '{}', -- 아침 시간대 관심사
    afternoon_interests JSONB DEFAULT '{}', -- 오후 시간대 관심사  
    evening_interests JSONB DEFAULT '{}', -- 저녁 시간대 관심사
    weekend_interests JSONB DEFAULT '{}', -- 주말 관심사
    
    -- 메타데이터
    profile_confidence_score DECIMAL(3,2) DEFAULT 0.00, -- 프로필 신뢰도 (0-1)
    last_analyzed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id)
);

-- 사용자 읽기 패턴 분석
CREATE TABLE paperly.user_reading_patterns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    
    -- 읽기 속도 및 패턴
    average_reading_speed_wpm INTEGER DEFAULT 200, -- 분당 단어수
    preferred_article_length VARCHAR(20) DEFAULT 'medium', -- short, medium, long
    optimal_reading_time_minutes INTEGER DEFAULT 10, -- 최적 읽기 시간
    
    -- 시간대별 읽기 패턴
    morning_reading_probability DECIMAL(3,2) DEFAULT 0.33, -- 아침 읽기 확률
    afternoon_reading_probability DECIMAL(3,2) DEFAULT 0.33,
    evening_reading_probability DECIMAL(3,2) DEFAULT 0.33,
    
    -- 요일별 읽기 패턴
    weekday_reading_frequency INTEGER DEFAULT 0, -- 주중 읽기 빈도
    weekend_reading_frequency INTEGER DEFAULT 0, -- 주말 읽기 빈도
    
    -- 디바이스별 읽기 패턴
    mobile_reading_percentage DECIMAL(5,2) DEFAULT 70.00,
    desktop_reading_percentage DECIMAL(5,2) DEFAULT 30.00,
    
    -- 완독률 및 참여도
    average_completion_rate DECIMAL(5,2) DEFAULT 0.00, -- 평균 완독률
    average_engagement_score DECIMAL(3,2) DEFAULT 0.00, -- 평균 참여도 점수
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id)
);

-- 상세 사용자 상호작용 추적 (Google Analytics 수준)
CREATE TABLE paperly.user_interactions_detailed (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    session_id UUID NOT NULL, -- 읽기 세션 ID
    article_id UUID NOT NULL REFERENCES paperly.articles(id) ON DELETE CASCADE,
    
    -- 상호작용 유형 및 상세 정보
    interaction_type VARCHAR(50) NOT NULL, -- view, click, scroll, pause, highlight, bookmark, share, like, comment
    interaction_value DECIMAL(10,2), -- 상호작용 강도/값
    interaction_context JSONB, -- 상세 컨텍스트 정보
    
    -- 위치 및 환경 정보
    content_position DECIMAL(5,2), -- 콘텐츠 내 위치 (0-100%)
    viewport_size VARCHAR(20), -- 뷰포트 크기
    device_info JSONB, -- 디바이스 상세 정보
    
    -- 시간 정보
    interaction_duration_ms INTEGER, -- 상호작용 지속 시간 (밀리초)
    time_since_page_load_ms INTEGER, -- 페이지 로드 후 경과 시간
    
    -- 행동 분석 데이터
    scroll_velocity DECIMAL(10,2), -- 스크롤 속도
    reading_velocity_wpm INTEGER, -- 읽기 속도 (단어/분)
    attention_score DECIMAL(3,2), -- 집중도 점수 (0-1)
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- 인덱스 최적화를 위한 복합 인덱스
    INDEX(user_id, article_id, interaction_type, created_at),
    INDEX(user_id, created_at DESC),
    INDEX(article_id, interaction_type, created_at)
);

-- =============================================
-- 2. 콘텐츠 분석 및 임베딩 테이블
-- =============================================

-- 콘텐츠 AI 분석 결과
CREATE TABLE paperly.content_analysis (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    article_id UUID NOT NULL REFERENCES paperly.articles(id) ON DELETE CASCADE,
    
    -- AI 분석 결과
    ai_generated_summary TEXT, -- AI가 생성한 요약
    ai_keywords TEXT[], -- AI가 추출한 키워드
    ai_topics JSONB, -- AI가 분류한 주제와 확률 {"technology": 0.8, "innovation": 0.6}
    sentiment_score DECIMAL(3,2), -- 감정 점수 (-1 to 1)
    complexity_score DECIMAL(3,2), -- 복잡도 점수 (0-1)
    
    -- 언어학적 분석
    readability_score DECIMAL(5,2), -- 가독성 점수
    tone_analysis JSONB, -- 톤 분석 {"formal": 0.7, "optimistic": 0.6}
    named_entities JSONB, -- 개체명 인식 결과
    
    -- 콘텐츠 특성
    estimated_expertise_level INTEGER CHECK (estimated_expertise_level BETWEEN 1 AND 5),
    target_audience JSONB, -- 대상 독자 분석
    content_freshness_score DECIMAL(3,2), -- 신선도 점수
    
    -- 메타데이터
    analysis_model_version VARCHAR(20) DEFAULT 'v1.0',
    analyzed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(article_id)
);

-- 콘텐츠 벡터 임베딩 (AI 추천용)
CREATE TABLE paperly.content_embeddings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    article_id UUID NOT NULL REFERENCES paperly.articles(id) ON DELETE CASCADE,
    
    -- 벡터 임베딩 (다차원 벡터를 JSONB로 저장)
    title_embedding JSONB, -- 제목 임베딩 벡터
    content_embedding JSONB, -- 본문 임베딩 벡터  
    combined_embedding JSONB, -- 결합 임베딩 벡터
    
    -- 임베딩 메타데이터
    embedding_model VARCHAR(50) DEFAULT 'openai-ada-002', -- 사용된 임베딩 모델
    embedding_dimension INTEGER DEFAULT 1536, -- 임베딩 차원
    embedding_quality_score DECIMAL(3,2), -- 임베딩 품질 점수
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(article_id)
);

-- 사용자 벡터 임베딩 (개인화용)
CREATE TABLE paperly.user_embeddings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    
    -- 사용자 선호도 벡터
    preference_embedding JSONB, -- 사용자 선호도 임베딩
    behavior_embedding JSONB, -- 행동 패턴 임베딩
    combined_embedding JSONB, -- 결합된 사용자 임베딩
    
    -- 시간적 임베딩 (시간에 따른 관심사 변화)
    temporal_embeddings JSONB, -- {"week_1": [...], "week_2": [...], ...}
    
    -- 임베딩 메타데이터
    embedding_confidence DECIMAL(3,2), -- 임베딩 신뢰도
    last_interaction_count INTEGER DEFAULT 0, -- 마지막 업데이트 시 상호작용 수
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id)
);

-- =============================================
-- 3. 실시간 추천 시스템 테이블
-- =============================================

-- 추천 모델 메타데이터
CREATE TABLE paperly.recommendation_models (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_name VARCHAR(100) NOT NULL UNIQUE,
    model_type VARCHAR(50) NOT NULL, -- collaborative_filtering, content_based, hybrid, deep_learning
    model_version VARCHAR(20) NOT NULL,
    
    -- 모델 성능 지표
    accuracy_score DECIMAL(5,4), -- 정확도
    precision_score DECIMAL(5,4), -- 정밀도
    recall_score DECIMAL(5,4), -- 재현율
    f1_score DECIMAL(5,4), -- F1 점수
    
    -- 모델 설정
    hyperparameters JSONB, -- 하이퍼파라미터
    training_data_period INTERVAL, -- 훈련 데이터 기간
    
    -- 상태 관리
    is_active BOOLEAN DEFAULT false,
    is_production BOOLEAN DEFAULT false,
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 실시간 개인화 추천
CREATE TABLE paperly.user_recommendations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    article_id UUID NOT NULL REFERENCES paperly.articles(id) ON DELETE CASCADE,
    model_id UUID NOT NULL REFERENCES paperly.recommendation_models(id),
    
    -- 추천 점수 및 순위
    recommendation_score DECIMAL(8,6) NOT NULL, -- 추천 점수 (0-1)
    rank_position INTEGER NOT NULL, -- 추천 순위
    
    -- 추천 이유 및 설명
    recommendation_reasons JSONB, -- 추천 이유 {"similarity": 0.8, "popularity": 0.6, "recency": 0.4}
    explanation_text TEXT, -- 사용자에게 보여줄 추천 이유
    
    -- 추천 컨텍스트
    recommendation_context VARCHAR(50), -- home_feed, category_page, similar_articles
    time_slot VARCHAR(20), -- morning, afternoon, evening
    device_type VARCHAR(20), -- mobile, desktop, tablet
    
    -- 추천 성과 추적
    was_shown BOOLEAN DEFAULT false, -- 사용자에게 노출되었는지
    was_clicked BOOLEAN DEFAULT false, -- 클릭되었는지
    was_read BOOLEAN DEFAULT false, -- 읽어졌는지
    engagement_score DECIMAL(3,2), -- 참여도 점수
    
    -- 시간 정보
    generated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    shown_at TIMESTAMPTZ,
    clicked_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP + INTERVAL '24 hours'),
    
    UNIQUE(user_id, article_id, recommendation_context, generated_at)
);

-- 추천 성과 피드백
CREATE TABLE paperly.recommendation_feedback (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recommendation_id UUID NOT NULL REFERENCES paperly.user_recommendations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    
    -- 피드백 유형
    feedback_type VARCHAR(30) NOT NULL, -- implicit (행동 기반), explicit (명시적)
    feedback_action VARCHAR(50) NOT NULL, -- click, read, like, bookmark, share, hide, not_interested
    feedback_value DECIMAL(3,2), -- 피드백 강도 (-1 to 1)
    
    -- 상세 피드백 정보
    reading_duration_seconds INTEGER,
    completion_percentage DECIMAL(5,2),
    user_rating INTEGER CHECK (user_rating BETWEEN 1 AND 5),
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 4. A/B 테스팅 및 실험 프레임워크
-- =============================================

-- A/B 테스트 실험
CREATE TABLE paperly.ab_test_experiments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    experiment_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    
    -- 실험 설정
    experiment_type VARCHAR(50) NOT NULL, -- recommendation_algorithm, ui_variant, content_ranking
    control_group_percentage DECIMAL(5,2) DEFAULT 50.00, -- 대조군 비율
    treatment_variants JSONB, -- 실험군 변형들
    
    -- 성공 지표
    primary_metric VARCHAR(50) NOT NULL, -- click_through_rate, reading_time, engagement_score
    secondary_metrics TEXT[], -- 보조 지표들
    
    -- 실험 기간
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    
    -- 상태
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'running', 'paused', 'completed', 'cancelled')),
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- A/B 테스트 참가자
CREATE TABLE paperly.ab_test_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    experiment_id UUID NOT NULL REFERENCES paperly.ab_test_experiments(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    
    -- 그룹 할당
    group_type VARCHAR(20) NOT NULL, -- control, treatment_a, treatment_b
    variant_name VARCHAR(50), -- 실험 변형 이름
    assignment_context JSONB, -- 할당 컨텍스트
    
    -- 참가 시간
    assigned_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    first_exposure_at TIMESTAMPTZ,
    
    UNIQUE(experiment_id, user_id)
);

-- A/B 테스트 결과
CREATE TABLE paperly.ab_test_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    experiment_id UUID NOT NULL REFERENCES paperly.ab_test_experiments(id) ON DELETE CASCADE,
    participant_id UUID NOT NULL REFERENCES paperly.ab_test_participants(id) ON DELETE CASCADE,
    
    -- 측정 지표
    metric_name VARCHAR(50) NOT NULL,
    metric_value DECIMAL(10,4) NOT NULL,
    measurement_context JSONB, -- 측정 컨텍스트
    
    measured_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 5. 실시간 이벤트 스트리밍 테이블
-- =============================================

-- 실시간 이벤트 스트림 (높은 처리량)
CREATE TABLE paperly.real_time_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES paperly.users(id) ON DELETE SET NULL,
    session_id UUID NOT NULL,
    
    -- 이벤트 정보
    event_type VARCHAR(50) NOT NULL, -- page_view, article_click, scroll, time_spent, etc.
    event_category VARCHAR(30) NOT NULL, -- user_interaction, content_consumption, system
    event_data JSONB NOT NULL, -- 이벤트 상세 데이터
    
    -- 컨텍스트 정보
    user_agent TEXT,
    ip_address INET,
    referrer_url TEXT,
    current_url TEXT,
    
    -- 시간 정보 (마이크로초 정밀도)
    event_timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    server_timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- 파티셔닝을 위한 날짜 필드
    event_date DATE GENERATED ALWAYS AS (event_timestamp::date) STORED
) PARTITION BY RANGE (event_date);

-- 실시간 이벤트 테이블 파티셔닝 (성능 최적화)
-- 매일 새로운 파티션 자동 생성
CREATE OR REPLACE FUNCTION paperly.create_daily_partition()
RETURNS void AS $$
DECLARE
    partition_date date;
    partition_name text;
    start_date text;
    end_date text;
BEGIN
    partition_date := CURRENT_DATE;
    partition_name := 'real_time_events_' || to_char(partition_date, 'YYYY_MM_DD');
    start_date := partition_date::text;
    end_date := (partition_date + interval '1 day')::date::text;
    
    EXECUTE format('CREATE TABLE IF NOT EXISTS paperly.%I PARTITION OF paperly.real_time_events FOR VALUES FROM (%L) TO (%L)',
                   partition_name, start_date, end_date);
END;
$$ LANGUAGE plpgsql;

-- 매일 자동으로 파티션 생성하는 크론 작업용 함수
SELECT paperly.create_daily_partition();

-- =============================================
-- 6. 고급 분석 및 리포팅 뷰
-- =============================================

-- 사용자 360도 뷰 (종합 사용자 프로필)
CREATE VIEW paperly.user_360_view AS
SELECT 
    u.id as user_id,
    u.email,
    u.name,
    u.status,
    u.created_at as user_since,
    
    -- 구독 정보
    s.plan_id,
    s.status as subscription_status,
    
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
LEFT JOIN paperly.user_subscriptions s ON u.id = s.user_id AND s.status = 'active'
LEFT JOIN paperly.user_reading_patterns rp ON u.id = rp.user_id
LEFT JOIN paperly.user_interest_profiles ip ON u.id = ip.user_id
LEFT JOIN (
    SELECT 
        user_id,
        COUNT(DISTINCT article_id) as articles_read,
        SUM(duration_seconds) as total_reading_time,
        COUNT(DISTINCT article_id)::float / 30 as avg_daily_articles,
        MAX(started_at::date) as last_active_date
    FROM paperly.reading_sessions
    WHERE started_at >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY user_id
) recent_stats ON u.id = recent_stats.user_id;

-- 콘텐츠 성과 대시보드 뷰
CREATE VIEW paperly.content_performance_dashboard AS
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
    ast.completion_rate,
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
    engagement_stats.high_engagement_users,
    
    -- 시간대별 인기도
    time_stats.morning_views,
    time_stats.afternoon_views,
    time_stats.evening_views
    
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
) engagement_stats ON a.id = engagement_stats.article_id
LEFT JOIN (
    SELECT 
        article_id,
        COUNT(*) FILTER (WHERE EXTRACT(hour FROM created_at) BETWEEN 6 AND 11) as morning_views,
        COUNT(*) FILTER (WHERE EXTRACT(hour FROM created_at) BETWEEN 12 AND 17) as afternoon_views,
        COUNT(*) FILTER (WHERE EXTRACT(hour FROM created_at) BETWEEN 18 AND 23) as evening_views
    FROM paperly.user_interactions_detailed
    WHERE interaction_type = 'view'
    GROUP BY article_id
) time_stats ON a.id = time_stats.article_id;

-- =============================================
-- 7. 고성능 인덱스 생성
-- =============================================

-- 사용자 상호작용 최적화 인덱스
CREATE INDEX CONCURRENTLY idx_user_interactions_user_time ON paperly.user_interactions_detailed (user_id, created_at DESC);
CREATE INDEX CONCURRENTLY idx_user_interactions_article_type ON paperly.user_interactions_detailed (article_id, interaction_type);
CREATE INDEX CONCURRENTLY idx_user_interactions_composite ON paperly.user_interactions_detailed (user_id, article_id, interaction_type, created_at DESC);

-- 추천 시스템 최적화 인덱스
CREATE INDEX CONCURRENTLY idx_recommendations_user_context ON paperly.user_recommendations (user_id, recommendation_context, expires_at);
CREATE INDEX CONCURRENTLY idx_recommendations_score ON paperly.user_recommendations (recommendation_score DESC) WHERE expires_at > CURRENT_TIMESTAMP;
CREATE INDEX CONCURRENTLY idx_recommendations_performance ON paperly.user_recommendations (was_shown, was_clicked, was_read);

-- 실시간 이벤트 인덱스
CREATE INDEX CONCURRENTLY idx_real_time_events_user_time ON paperly.real_time_events (user_id, event_timestamp DESC);
CREATE INDEX CONCURRENTLY idx_real_time_events_type_time ON paperly.real_time_events (event_type, event_timestamp DESC);

-- 콘텐츠 임베딩 검색 최적화 (PostgreSQL의 GIN 인덱스 활용)
CREATE INDEX CONCURRENTLY idx_content_embeddings_gin ON paperly.content_embeddings USING gin (combined_embedding);
CREATE INDEX CONCURRENTLY idx_user_embeddings_gin ON paperly.user_embeddings USING gin (combined_embedding);

-- =============================================
-- 8. 자동화 함수 및 트리거
-- =============================================

-- 사용자 관심사 프로필 자동 업데이트 함수
CREATE OR REPLACE FUNCTION paperly.update_user_interest_profile()
RETURNS TRIGGER AS $$
BEGIN
    -- 새로운 상호작용 발생 시 사용자 관심사 프로필 업데이트
    IF TG_OP = 'INSERT' THEN
        -- 비동기적으로 관심사 프로필 재계산 (실제로는 별도 백그라운드 작업으로 처리)
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
    AFTER INSERT ON paperly.user_interactions_detailed 
    FOR EACH ROW EXECUTE FUNCTION paperly.update_user_interest_profile();

-- 콘텐츠 통계 실시간 업데이트 함수 (개선된 버전)
CREATE OR REPLACE FUNCTION paperly.update_content_stats()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE paperly.article_stats 
        SET 
            view_count = CASE WHEN NEW.interaction_type = 'view' THEN view_count + 1 ELSE view_count END,
            like_count = CASE WHEN NEW.interaction_type = 'like' THEN like_count + 1 ELSE like_count END,
            bookmark_count = CASE WHEN NEW.interaction_type = 'bookmark' THEN bookmark_count + 1 ELSE bookmark_count END,
            share_count = CASE WHEN NEW.interaction_type = 'share' THEN share_count + 1 ELSE share_count END,
            updated_at = CURRENT_TIMESTAMP
        WHERE article_id = NEW.article_id;
        
        -- 존재하지 않으면 새로 생성
        INSERT INTO paperly.article_stats (article_id, view_count, like_count, bookmark_count, share_count)
        SELECT NEW.article_id, 
               CASE WHEN NEW.interaction_type = 'view' THEN 1 ELSE 0 END,
               CASE WHEN NEW.interaction_type = 'like' THEN 1 ELSE 0 END,
               CASE WHEN NEW.interaction_type = 'bookmark' THEN 1 ELSE 0 END,
               CASE WHEN NEW.interaction_type = 'share' THEN 1 ELSE 0 END
        WHERE NOT EXISTS (SELECT 1 FROM paperly.article_stats WHERE article_id = NEW.article_id);
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 콘텐츠 통계 업데이트 트리거
CREATE TRIGGER update_content_stats_trigger 
    AFTER INSERT ON paperly.user_interactions_detailed 
    FOR EACH ROW EXECUTE FUNCTION paperly.update_content_stats();

-- =============================================
-- 9. 데이터 파티셔닝 및 보관 정책
-- =============================================

-- 과거 데이터 자동 아카이빙 함수
CREATE OR REPLACE FUNCTION paperly.archive_old_events()
RETURNS void AS $$
BEGIN
    -- 90일 이상 된 실시간 이벤트 삭제
    DELETE FROM paperly.real_time_events 
    WHERE event_date < CURRENT_DATE - INTERVAL '90 days';
    
    -- 1년 이상 된 상세 상호작용 데이터 압축
    -- (실제로는 별도 아카이브 테이블로 이동)
    
END;
$$ LANGUAGE plpgsql;

-- 매주 일요일 자정에 아카이빙 실행 (cron job 설정 필요)
-- SELECT cron.schedule('archive-weekly', '0 0 * * 0', 'SELECT paperly.archive_old_events();');

-- =============================================
-- 완료 메시지
-- =============================================

-- 스키마 생성 완료 로그
DO $$
BEGIN
    RAISE NOTICE '=================================';
    RAISE NOTICE 'Paperly 고급 추천 시스템 스키마 생성 완료';
    RAISE NOTICE '=================================';
    RAISE NOTICE '생성된 테이블:';
    RAISE NOTICE '- user_interest_profiles: 사용자 관심사 프로필';
    RAISE NOTICE '- user_reading_patterns: 읽기 패턴 분석';
    RAISE NOTICE '- user_interactions_detailed: 상세 상호작용 추적';
    RAISE NOTICE '- content_analysis: 콘텐츠 AI 분석';
    RAISE NOTICE '- content_embeddings: 콘텐츠 벡터 임베딩';
    RAISE NOTICE '- user_embeddings: 사용자 벡터 임베딩';
    RAISE NOTICE '- recommendation_models: 추천 모델 메타데이터';
    RAISE NOTICE '- user_recommendations: 개인화 추천';
    RAISE NOTICE '- recommendation_feedback: 추천 피드백';
    RAISE NOTICE '- ab_test_experiments: A/B 테스팅';
    RAISE NOTICE '- real_time_events: 실시간 이벤트 스트림';
    RAISE NOTICE '=================================';
    RAISE NOTICE '이 스키마는 Google/Facebook 수준의';
    RAISE NOTICE '고급 추천 시스템을 지원합니다.';
    RAISE NOTICE '=================================';
END $$;