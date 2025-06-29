-- =============================================
-- Paperly 사용자 행동 분석 및 추적 시스템
-- Google Analytics/Facebook Pixel 수준의 상세 행동 추적
-- Version: 2.0.0
-- =============================================

-- paperly 스키마 사용 설정
SET search_path TO paperly, public;

-- =============================================
-- 1. 상세 사용자 행동 추적
-- =============================================

-- 사용자 세션 추적 (전체 앱 사용 세션)
CREATE TABLE IF NOT EXISTS paperly.user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES paperly.users(id) ON DELETE CASCADE,
    
    -- 세션 식별
    session_id UUID NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    anonymous_id UUID, -- 비로그인 사용자용 익명 ID
    
    -- 디바이스 및 환경 정보
    device_type VARCHAR(20) NOT NULL CHECK (device_type IN ('mobile', 'tablet', 'desktop', 'smart_tv', 'unknown')),
    operating_system VARCHAR(50),
    browser VARCHAR(50),
    browser_version VARCHAR(20),
    app_version VARCHAR(20),
    
    -- 위치 정보 (개인정보 동의 시)
    country_code VARCHAR(2),
    city VARCHAR(100),
    timezone VARCHAR(50),
    ip_address INET,
    
    -- 세션 정보
    started_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMPTZ,
    duration_seconds INTEGER, -- 세션 지속 시간
    is_active BOOLEAN DEFAULT true,
    
    -- 참조 정보
    referrer_source VARCHAR(100), -- google, facebook, direct, etc.
    referrer_url TEXT,
    utm_source VARCHAR(100),
    utm_medium VARCHAR(100),
    utm_campaign VARCHAR(100),
    utm_content VARCHAR(100),
    
    -- 세션 통계 (캐시된 값들)
    page_views INTEGER DEFAULT 0,
    articles_viewed INTEGER DEFAULT 0,
    articles_read INTEGER DEFAULT 0,
    interactions_count INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 페이지 조회 추적 (Google Analytics 수준)
CREATE TABLE IF NOT EXISTS paperly.page_views (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES paperly.user_sessions(session_id) ON DELETE CASCADE,
    user_id UUID REFERENCES paperly.users(id) ON DELETE SET NULL,
    
    -- 페이지 정보
    page_url TEXT NOT NULL,
    page_title VARCHAR(200),
    page_type VARCHAR(50) NOT NULL, -- home, article, category, profile, search, etc.
    page_category VARCHAR(50), -- content categorization
    
    -- 콘텐츠 정보 (게시글 페이지인 경우)
    article_id UUID REFERENCES paperly.articles(id) ON DELETE SET NULL,
    category_id UUID REFERENCES paperly.categories(id) ON DELETE SET NULL,
    
    -- 페이지 성능
    load_time_ms INTEGER, -- 페이지 로드 시간
    time_on_page_seconds INTEGER, -- 페이지 체류 시간
    scroll_depth_percentage DECIMAL(5,2) DEFAULT 0.00, -- 스크롤 깊이
    
    -- 이탈 정보
    is_bounce BOOLEAN, -- 바운스 여부 (단일 페이지 방문)
    exit_page BOOLEAN DEFAULT false, -- 이탈 페이지 여부
    
    -- 상호작용 요약
    clicks_count INTEGER DEFAULT 0,
    form_interactions INTEGER DEFAULT 0,
    video_plays INTEGER DEFAULT 0,
    
    -- 메타데이터
    user_agent TEXT,
    viewport_width INTEGER,
    viewport_height INTEGER,
    screen_resolution VARCHAR(20),
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 클릭 및 상호작용 이벤트 추적
CREATE TABLE IF NOT EXISTS paperly.interaction_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES paperly.user_sessions(session_id) ON DELETE CASCADE,
    user_id UUID REFERENCES paperly.users(id) ON DELETE SET NULL,
    page_view_id UUID REFERENCES paperly.page_views(id) ON DELETE CASCADE,
    
    -- 이벤트 정보
    event_category VARCHAR(50) NOT NULL, -- click, scroll, form, media, etc.
    event_action VARCHAR(100) NOT NULL, -- button_click, article_share, bookmark_add, etc.
    event_label VARCHAR(200), -- 구체적인 요소 식별
    event_value DECIMAL(10,2), -- 이벤트 값 (선택적)
    
    -- 이벤트 상세 정보
    element_type VARCHAR(50), -- button, link, image, text, etc.
    element_id VARCHAR(100), -- HTML element ID
    element_class VARCHAR(200), -- CSS class
    element_text TEXT, -- 요소의 텍스트 내용
    
    -- 위치 정보
    element_position JSONB, -- {"x": 100, "y": 200}
    scroll_position INTEGER, -- 스크롤 위치
    viewport_position JSONB, -- 뷰포트 내 위치
    
    -- 컨텍스트 정보
    article_id UUID REFERENCES paperly.articles(id) ON DELETE SET NULL,
    recommendation_id UUID, -- 추천을 통한 클릭인 경우
    search_query TEXT, -- 검색을 통한 클릭인 경우
    
    -- 시간 정보
    time_since_page_load INTEGER, -- 페이지 로드 후 경과 시간 (ms)
    time_since_last_interaction INTEGER, -- 마지막 상호작용 후 경과 시간 (ms)
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 2. 읽기 행동 상세 분석
-- =============================================

-- 상세 읽기 행동 추적 (스크롤, 하이라이트, 일시정지 등)
CREATE TABLE IF NOT EXISTS paperly.reading_behaviors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES paperly.user_sessions(session_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    article_id UUID NOT NULL REFERENCES paperly.articles(id) ON DELETE CASCADE,
    reading_session_id UUID REFERENCES paperly.reading_sessions(id) ON DELETE CASCADE,
    
    -- 행동 유형
    behavior_type VARCHAR(50) NOT NULL, -- scroll, pause, highlight, copy, share, etc.
    behavior_data JSONB NOT NULL, -- 행동별 상세 데이터
    
    -- 콘텐츠 위치
    content_position INTEGER, -- 콘텐츠 내 문자 위치
    content_percentage DECIMAL(5,2), -- 콘텐츠 위치 백분율
    paragraph_index INTEGER, -- 문단 번호
    
    -- 시간 정보
    behavior_timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    duration_ms INTEGER, -- 행동 지속 시간
    
    -- 읽기 품질 지표
    reading_speed_wpm INTEGER, -- 순간 읽기 속도
    attention_level DECIMAL(3,2), -- 집중도 (AI 추정)
    
    -- 메타데이터
    device_orientation VARCHAR(20), -- portrait, landscape
    font_size VARCHAR(20),
    theme VARCHAR(20) -- light, dark
);

-- 텍스트 하이라이트 및 메모
CREATE TABLE IF NOT EXISTS paperly.text_highlights (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    article_id UUID NOT NULL REFERENCES paperly.articles(id) ON DELETE CASCADE,
    
    -- 하이라이트 정보
    highlighted_text TEXT NOT NULL,
    start_position INTEGER NOT NULL, -- 시작 문자 위치
    end_position INTEGER NOT NULL, -- 끝 문자 위치
    context_before TEXT, -- 앞 문맥 (검색용)
    context_after TEXT, -- 뒤 문맥 (검색용)
    
    -- 사용자 메모
    user_note TEXT,
    note_type VARCHAR(20) DEFAULT 'highlight' CHECK (note_type IN ('highlight', 'note', 'question', 'idea')),
    
    -- 색상/스타일
    highlight_color VARCHAR(7) DEFAULT '#FFFF00', -- 하이라이트 색상
    
    -- 공유 설정
    is_public BOOLEAN DEFAULT false,
    is_shared BOOLEAN DEFAULT false,
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 읽기 패턴 분석 (하루 단위)
CREATE TABLE IF NOT EXISTS paperly.daily_reading_patterns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    analysis_date DATE NOT NULL,
    
    -- 읽기 시간 분석
    total_reading_time_minutes INTEGER DEFAULT 0,
    active_reading_time_minutes INTEGER DEFAULT 0, -- 실제 읽기 시간 (일시정지 제외)
    average_session_duration_minutes DECIMAL(8,2) DEFAULT 0.00,
    
    -- 읽기 속도 분석
    average_reading_speed_wpm INTEGER DEFAULT 0,
    fastest_reading_speed_wpm INTEGER DEFAULT 0,
    slowest_reading_speed_wpm INTEGER DEFAULT 0,
    
    -- 완독률 분석
    articles_started INTEGER DEFAULT 0,
    articles_completed INTEGER DEFAULT 0,
    completion_rate DECIMAL(5,2) DEFAULT 0.00,
    
    -- 시간대별 읽기 패턴
    morning_reading_minutes INTEGER DEFAULT 0, -- 6-12시
    afternoon_reading_minutes INTEGER DEFAULT 0, -- 12-18시
    evening_reading_minutes INTEGER DEFAULT 0, -- 18-24시
    night_reading_minutes INTEGER DEFAULT 0, -- 0-6시
    
    -- 카테고리별 읽기 시간 (JSONB)
    category_reading_time JSONB DEFAULT '{}', -- {"technology": 120, "business": 60}
    
    -- 디바이스별 읽기 시간
    mobile_reading_minutes INTEGER DEFAULT 0,
    desktop_reading_minutes INTEGER DEFAULT 0,
    tablet_reading_minutes INTEGER DEFAULT 0,
    
    -- 읽기 집중도
    average_attention_score DECIMAL(3,2) DEFAULT 0.00,
    distraction_events INTEGER DEFAULT 0, -- 다른 앱/탭으로 이동한 횟수
    
    -- 상호작용 패턴
    total_highlights INTEGER DEFAULT 0,
    total_bookmarks INTEGER DEFAULT 0,
    total_shares INTEGER DEFAULT 0,
    total_likes INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id, analysis_date)
);

-- =============================================
-- 3. 검색 및 발견 행동 추적
-- =============================================

-- 검색 쿼리 및 결과 추적
CREATE TABLE IF NOT EXISTS paperly.search_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES paperly.user_sessions(session_id) ON DELETE CASCADE,
    user_id UUID REFERENCES paperly.users(id) ON DELETE SET NULL,
    
    -- 검색 정보
    search_query TEXT NOT NULL,
    search_type VARCHAR(30) DEFAULT 'general' CHECK (search_type IN ('general', 'category', 'tag', 'author', 'advanced')),
    search_filters JSONB, -- 적용된 필터들
    
    -- 검색 결과
    results_count INTEGER DEFAULT 0,
    results_shown INTEGER DEFAULT 0, -- 실제 보여진 결과 수
    
    -- 사용자 행동
    clicked_position INTEGER, -- 클릭한 결과의 순위 (1부터 시작)
    clicked_article_id UUID REFERENCES paperly.articles(id) ON DELETE SET NULL,
    time_to_click_ms INTEGER, -- 검색 후 클릭까지 시간
    
    -- 검색 성과
    found_relevant_result BOOLEAN, -- 관련 결과를 찾았는지 (추후 분석)
    search_session_id UUID, -- 연속된 검색 세션 ID
    
    -- 자동완성 및 제안
    used_autocomplete BOOLEAN DEFAULT false,
    suggested_queries TEXT[], -- 제안된 쿼리들
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 추천 클릭 및 성과 추적
CREATE TABLE IF NOT EXISTS paperly.recommendation_interactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES paperly.user_sessions(session_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    recommendation_id UUID, -- user_recommendations 테이블과 연결
    
    -- 추천 컨텍스트
    recommendation_type VARCHAR(50) NOT NULL, -- homepage, category, similar, trending, etc.
    recommendation_algorithm VARCHAR(50), -- collaborative, content_based, hybrid, etc.
    recommendation_position INTEGER, -- 추천 목록에서의 위치
    
    -- 상호작용 정보
    interaction_type VARCHAR(30) NOT NULL, -- impression, click, like, bookmark, share, dismiss
    article_id UUID REFERENCES paperly.articles(id) ON DELETE CASCADE,
    
    -- 성과 지표
    time_to_interaction_ms INTEGER, -- 노출 후 상호작용까지 시간
    subsequent_reading_time INTEGER, -- 클릭 후 읽기 시간
    completed_reading BOOLEAN, -- 완독 여부
    
    -- 추천 품질
    relevance_feedback INTEGER CHECK (relevance_feedback BETWEEN 1 AND 5), -- 사용자 피드백
    user_satisfaction DECIMAL(3,2), -- 만족도 점수 (AI 추정)
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 4. 소셜 및 공유 행동 분석
-- =============================================

-- 소셜 상호작용 추적
CREATE TABLE IF NOT EXISTS paperly.social_interactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES paperly.user_sessions(session_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    
    -- 상호작용 대상
    target_type VARCHAR(30) NOT NULL CHECK (target_type IN ('article', 'user', 'comment', 'highlight')),
    target_id UUID NOT NULL, -- article_id, user_id, comment_id, highlight_id
    
    -- 상호작용 유형
    interaction_type VARCHAR(30) NOT NULL, -- follow, unfollow, like, unlike, share, comment, etc.
    interaction_context VARCHAR(50), -- where the interaction happened
    
    -- 공유 상세 정보 (공유인 경우)
    share_platform VARCHAR(30), -- twitter, facebook, linkedin, email, copy_link
    share_message TEXT, -- 사용자가 추가한 메시지
    
    -- 메타데이터
    metadata JSONB, -- 추가 컨텍스트 정보
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 콘텐츠 발견 경로 추적
CREATE TABLE IF NOT EXISTS paperly.content_discovery_paths (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES paperly.user_sessions(session_id) ON DELETE CASCADE,
    user_id UUID REFERENCES paperly.users(id) ON DELETE SET NULL,
    article_id UUID NOT NULL REFERENCES paperly.articles(id) ON DELETE CASCADE,
    
    -- 발견 경로
    discovery_source VARCHAR(50) NOT NULL, -- homepage, recommendation, search, social, direct, etc.
    discovery_method VARCHAR(50), -- algorithm, trending, featured, category_browse, etc.
    source_page_url TEXT, -- 출발 페이지
    
    -- 추천 상세 (추천을 통한 발견인 경우)
    recommendation_algorithm VARCHAR(50),
    recommendation_score DECIMAL(8,6),
    recommendation_position INTEGER,
    
    -- 검색 상세 (검색을 통한 발견인 경우)
    search_query TEXT,
    search_result_position INTEGER,
    
    -- 소셜 상세 (소셜을 통한 발견인 경우)
    social_platform VARCHAR(30),
    shared_by_user_id UUID REFERENCES paperly.users(id) ON DELETE SET NULL,
    
    -- 성과 측정
    time_to_engagement INTEGER, -- 발견 후 실제 읽기까지 시간
    engagement_depth VARCHAR(20), -- surface, medium, deep
    conversion_achieved BOOLEAN, -- 목표 전환 달성 (완독, 구독 등)
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 5. 실시간 행동 분석 뷰
-- =============================================

-- 실시간 사용자 활동 대시보드
CREATE VIEW IF NOT EXISTS paperly.real_time_user_activity AS
SELECT 
    s.user_id,
    s.session_id,
    s.device_type,
    s.started_at as session_start,
    s.duration_seconds as session_duration,
    s.is_active,
    
    -- 현재 세션 활동
    COUNT(pv.id) as page_views,
    COUNT(DISTINCT pv.article_id) as unique_articles_viewed,
    COUNT(ie.id) as total_interactions,
    
    -- 최근 활동
    MAX(pv.created_at) as last_page_view,
    MAX(ie.created_at) as last_interaction,
    
    -- 읽기 활동
    COUNT(rs.id) as reading_sessions,
    SUM(rs.reading_duration_seconds) as total_reading_time,
    COUNT(rs.id) FILTER (WHERE rs.is_completed = true) as completed_readings

FROM paperly.user_sessions s
LEFT JOIN paperly.page_views pv ON s.session_id = pv.session_id
LEFT JOIN paperly.interaction_events ie ON s.session_id = ie.session_id  
LEFT JOIN paperly.reading_sessions rs ON s.user_id = rs.user_id 
    AND rs.started_at >= s.started_at
    AND (rs.started_at <= s.ended_at OR s.ended_at IS NULL)
WHERE s.started_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
GROUP BY s.user_id, s.session_id, s.device_type, s.started_at, s.duration_seconds, s.is_active;

-- 콘텐츠 실시간 성과 뷰
CREATE VIEW IF NOT EXISTS paperly.real_time_content_performance AS
SELECT 
    a.id as article_id,
    a.title,
    a.published_at,
    
    -- 최근 24시간 지표
    COUNT(pv.id) as views_24h,
    COUNT(DISTINCT pv.user_id) as unique_readers_24h,
    COUNT(rs.id) FILTER (WHERE rs.is_completed = true) as completions_24h,
    
    -- 실시간 참여도
    COUNT(ie.id) FILTER (WHERE ie.event_action = 'like') as likes_24h,
    COUNT(ie.id) FILTER (WHERE ie.event_action = 'bookmark') as bookmarks_24h,
    COUNT(ie.id) FILTER (WHERE ie.event_action = 'share') as shares_24h,
    
    -- 최근 활동
    MAX(pv.created_at) as last_view,
    MAX(ie.created_at) as last_interaction

FROM paperly.articles a
LEFT JOIN paperly.page_views pv ON a.id = pv.article_id 
    AND pv.created_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
LEFT JOIN paperly.reading_sessions rs ON a.id = rs.article_id 
    AND rs.started_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
LEFT JOIN paperly.interaction_events ie ON a.id = ie.article_id 
    AND ie.created_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
WHERE a.status = 'published'
GROUP BY a.id, a.title, a.published_at
HAVING COUNT(pv.id) > 0
ORDER BY views_24h DESC;

-- =============================================
-- 6. 고성능 인덱스
-- =============================================

-- 세션 추적 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_sessions_user_active ON paperly.user_sessions (user_id, is_active, started_at DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_sessions_device_time ON paperly.user_sessions (device_type, started_at DESC);

-- 페이지 뷰 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_page_views_session_time ON paperly.page_views (session_id, created_at DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_page_views_article_time ON paperly.page_views (article_id, created_at DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_page_views_user_time ON paperly.page_views (user_id, created_at DESC);

-- 상호작용 이벤트 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_interaction_events_composite ON paperly.interaction_events (session_id, event_category, event_action, created_at);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_interaction_events_article ON paperly.interaction_events (article_id, event_action, created_at);

-- 검색 이벤트 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_search_events_user_time ON paperly.search_events (user_id, created_at DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_search_events_query ON paperly.search_events USING gin (to_tsvector('english', search_query));

-- 읽기 행동 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_reading_behaviors_composite ON paperly.reading_behaviors (user_id, article_id, behavior_type, behavior_timestamp);

-- 일일 패턴 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_daily_reading_patterns_user_date ON paperly.daily_reading_patterns (user_id, analysis_date DESC);

-- =============================================
-- 완료 메시지
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '================================='
    RAISE NOTICE 'Paperly 사용자 행동 분석 시스템 구축 완료';
    RAISE NOTICE '================================='
    RAISE NOTICE '생성된 테이블:';
    RAISE NOTICE '- user_sessions: 전체 앱 세션 추적';
    RAISE NOTICE '- page_views: 페이지 조회 상세 추적';
    RAISE NOTICE '- interaction_events: 모든 클릭/상호작용';
    RAISE NOTICE '- reading_behaviors: 읽기 행동 상세 분석';
    RAISE NOTICE '- text_highlights: 하이라이트 및 메모';
    RAISE NOTICE '- daily_reading_patterns: 일일 읽기 패턴';
    RAISE NOTICE '- search_events: 검색 행동 추적';
    RAISE NOTICE '- recommendation_interactions: 추천 성과';
    RAISE NOTICE '- social_interactions: 소셜 활동';
    RAISE NOTICE '- content_discovery_paths: 콘텐츠 발견 경로';
    RAISE NOTICE '================================='
    RAISE NOTICE 'Google Analytics 수준의 상세 추적이 가능합니다.';
    RAISE NOTICE '================================='
END $$;