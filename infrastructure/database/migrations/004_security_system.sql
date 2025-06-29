-- =============================================
-- Paperly 보안 모니터링 시스템
-- Version: 2.0.0
-- =============================================

-- paperly 스키마 사용 설정
SET search_path TO paperly, public;

-- =============================================
-- 1. 보안 이벤트 추적
-- =============================================

-- 보안 이벤트 로그
CREATE TABLE IF NOT EXISTS paperly.security_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- 기본 정보
    event_type VARCHAR(50) NOT NULL, -- login_attempt, suspicious_activity, data_access, etc.
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    
    -- 사용자 정보
    user_id UUID REFERENCES paperly.users(id) ON DELETE SET NULL,
    email VARCHAR(255),
    ip_address INET NOT NULL,
    user_agent TEXT,
    
    -- 위치 정보
    country_code VARCHAR(2),
    city VARCHAR(100),
    
    -- 상세 정보
    description TEXT NOT NULL,
    details JSONB, -- 추가 상세 정보
    
    -- 상태 정보
    status VARCHAR(20) DEFAULT 'open' CHECK (status IN ('open', 'investigating', 'resolved', 'false_positive')),
    resolved_at TIMESTAMPTZ,
    resolved_by UUID REFERENCES paperly.users(id),
    
    -- 자동 탐지 정보
    detection_rule VARCHAR(100), -- 어떤 규칙에 의해 탐지되었는지
    risk_score INTEGER CHECK (risk_score BETWEEN 0 AND 100),
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 로그인 시도 기록
CREATE TABLE IF NOT EXISTS paperly.login_attempts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- 시도 정보
    email VARCHAR(255) NOT NULL,
    success BOOLEAN NOT NULL,
    failure_reason VARCHAR(100), -- invalid_password, account_locked, etc.
    
    -- 클라이언트 정보
    ip_address INET NOT NULL,
    user_agent TEXT,
    device_fingerprint TEXT, -- 디바이스 식별자
    
    -- 위치 정보
    country_code VARCHAR(2),
    city VARCHAR(100),
    
    -- 보안 메타데이터
    is_suspicious BOOLEAN DEFAULT false,
    risk_factors JSONB, -- 위험 요소들
    
    attempted_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 사용자 세션 관리
CREATE TABLE IF NOT EXISTS paperly.user_sessions_security (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    
    -- 세션 정보
    session_token VARCHAR(255) NOT NULL UNIQUE,
    refresh_token VARCHAR(255),
    
    -- 클라이언트 정보
    ip_address INET NOT NULL,
    user_agent TEXT,
    device_fingerprint TEXT,
    
    -- 세션 상태
    is_active BOOLEAN DEFAULT true,
    last_activity_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- 보안 정보
    login_method VARCHAR(50), -- password, oauth, 2fa, etc.
    two_factor_verified BOOLEAN DEFAULT false,
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ
);

-- =============================================
-- 2. 데이터 접근 감사
-- =============================================

-- 민감한 데이터 접근 로그
CREATE TABLE IF NOT EXISTS paperly.data_access_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- 접근 주체
    user_id UUID REFERENCES paperly.users(id) ON DELETE SET NULL,
    admin_user_id UUID REFERENCES paperly.users(id) ON DELETE SET NULL,
    
    -- 접근 대상
    resource_type VARCHAR(50) NOT NULL, -- user_profile, article, payment_info, etc.
    resource_id UUID,
    table_name VARCHAR(100),
    
    -- 작업 정보
    operation VARCHAR(20) NOT NULL CHECK (operation IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE')),
    affected_columns TEXT[], -- 영향받은 컬럼들
    old_values JSONB, -- 변경 전 값
    new_values JSONB, -- 변경 후 값
    
    -- 메타데이터
    ip_address INET,
    user_agent TEXT,
    request_id UUID, -- API 요청 ID
    
    accessed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- API 접근 로그
CREATE TABLE IF NOT EXISTS paperly.api_access_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- 요청 정보
    request_id UUID DEFAULT uuid_generate_v4(),
    method VARCHAR(10) NOT NULL,
    endpoint VARCHAR(200) NOT NULL,
    query_params JSONB,
    
    -- 클라이언트 정보
    user_id UUID REFERENCES paperly.users(id) ON DELETE SET NULL,
    ip_address INET NOT NULL,
    user_agent TEXT,
    api_key_id UUID, -- API 키 ID (있는 경우)
    
    -- 응답 정보
    status_code INTEGER NOT NULL,
    response_time_ms INTEGER,
    response_size_bytes INTEGER,
    
    -- 보안 정보
    rate_limit_exceeded BOOLEAN DEFAULT false,
    suspicious_activity BOOLEAN DEFAULT false,
    
    requested_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 3. 위험 요소 탐지
-- =============================================

-- 사용자 위험 프로필
CREATE TABLE IF NOT EXISTS paperly.user_risk_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    
    -- 위험 점수
    current_risk_score INTEGER DEFAULT 0 CHECK (current_risk_score BETWEEN 0 AND 100),
    max_risk_score INTEGER DEFAULT 0,
    
    -- 위험 요소들
    failed_login_attempts INTEGER DEFAULT 0,
    suspicious_ips INET[],
    unusual_locations TEXT[],
    account_age_days INTEGER,
    
    -- 행동 패턴
    typical_login_hours INTEGER[], -- 일반적인 로그인 시간대
    typical_locations TEXT[], -- 일반적인 접속 위치
    device_fingerprints TEXT[], -- 사용한 디바이스들
    
    -- 메타데이터
    last_risk_assessment_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id)
);

-- 의심스러운 활동 패턴
CREATE TABLE IF NOT EXISTS paperly.suspicious_patterns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- 패턴 정보
    pattern_name VARCHAR(100) NOT NULL,
    pattern_type VARCHAR(50) NOT NULL, -- login_anomaly, data_scraping, brute_force, etc.
    description TEXT,
    
    -- 탐지 규칙
    detection_rules JSONB NOT NULL,
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    
    -- 상태
    is_active BOOLEAN DEFAULT true,
    auto_block BOOLEAN DEFAULT false, -- 자동 차단 여부
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 4. 실시간 모니터링 뷰
-- =============================================

-- 실시간 보안 대시보드 뷰
CREATE VIEW IF NOT EXISTS paperly.security_dashboard AS
SELECT 
    -- 오늘의 보안 이벤트 요약
    COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE) as events_today,
    COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE AND severity IN ('high', 'critical')) as critical_events_today,
    COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE - INTERVAL '7 days') as events_week,
    
    -- 로그인 시도 요약
    (SELECT COUNT(*) FROM paperly.login_attempts WHERE attempted_at >= CURRENT_DATE) as login_attempts_today,
    (SELECT COUNT(*) FROM paperly.login_attempts WHERE attempted_at >= CURRENT_DATE AND success = false) as failed_logins_today,
    
    -- 활성 세션
    (SELECT COUNT(*) FROM paperly.user_sessions_security WHERE is_active = true) as active_sessions,
    
    -- 위험한 사용자들
    (SELECT COUNT(*) FROM paperly.user_risk_profiles WHERE current_risk_score >= 70) as high_risk_users
    
FROM paperly.security_events;

-- 실시간 위험 사용자 뷰
CREATE VIEW IF NOT EXISTS paperly.high_risk_users AS
SELECT 
    u.id,
    u.email,
    u.name,
    urp.current_risk_score,
    urp.failed_login_attempts,
    urp.last_risk_assessment_at,
    
    -- 최근 의심스러운 활동
    recent_events.event_count,
    recent_events.last_event_at
    
FROM paperly.users u
JOIN paperly.user_risk_profiles urp ON u.id = urp.user_id
LEFT JOIN (
    SELECT 
        user_id,
        COUNT(*) as event_count,
        MAX(created_at) as last_event_at
    FROM paperly.security_events
    WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
    GROUP BY user_id
) recent_events ON u.id = recent_events.user_id
WHERE urp.current_risk_score >= 50
ORDER BY urp.current_risk_score DESC;

-- =============================================
-- 5. 인덱스 및 최적화
-- =============================================

-- 보안 이벤트 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_security_events_type_severity ON paperly.security_events (event_type, severity, created_at DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_security_events_user_time ON paperly.security_events (user_id, created_at DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_security_events_ip ON paperly.security_events (ip_address, created_at DESC);

-- 로그인 시도 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_login_attempts_email_time ON paperly.login_attempts (email, attempted_at DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_login_attempts_ip_time ON paperly.login_attempts (ip_address, attempted_at DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_login_attempts_suspicious ON paperly.login_attempts (is_suspicious, attempted_at DESC) WHERE is_suspicious = true;

-- 세션 관리 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_sessions_security_user_active ON paperly.user_sessions_security (user_id, is_active, last_activity_at DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_sessions_security_token ON paperly.user_sessions_security (session_token);

-- API 접근 로그 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_api_access_logs_user_time ON paperly.api_access_logs (user_id, requested_at DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_api_access_logs_endpoint_time ON paperly.api_access_logs (endpoint, requested_at DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_api_access_logs_ip_time ON paperly.api_access_logs (ip_address, requested_at DESC);

-- =============================================
-- 6. 자동화 함수
-- =============================================

-- 위험 점수 자동 계산 함수
CREATE OR REPLACE FUNCTION paperly.calculate_user_risk_score(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    risk_score INTEGER := 0;
    failed_attempts INTEGER;
    recent_events INTEGER;
    account_age_days INTEGER;
    unusual_activity_count INTEGER;
BEGIN
    -- 실패한 로그인 시도 (최근 24시간)
    SELECT COUNT(*)
    INTO failed_attempts
    FROM paperly.login_attempts
    WHERE email = (SELECT email FROM paperly.users WHERE id = p_user_id)
    AND attempted_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
    AND success = false;
    
    risk_score := risk_score + (failed_attempts * 10);
    
    -- 최근 보안 이벤트 (최근 7일)
    SELECT COUNT(*)
    INTO recent_events
    FROM paperly.security_events
    WHERE user_id = p_user_id
    AND created_at >= CURRENT_DATE - INTERVAL '7 days'
    AND severity IN ('medium', 'high', 'critical');
    
    risk_score := risk_score + (recent_events * 15);
    
    -- 계정 나이 (너무 새로운 계정은 위험)
    SELECT EXTRACT(days FROM CURRENT_TIMESTAMP - created_at)
    INTO account_age_days
    FROM paperly.users
    WHERE id = p_user_id;
    
    IF account_age_days < 7 THEN
        risk_score := risk_score + 20;
    ELSIF account_age_days < 30 THEN
        risk_score := risk_score + 10;
    END IF;
    
    -- 위험 점수는 0-100 사이로 제한
    risk_score := LEAST(100, GREATEST(0, risk_score));
    
    -- 사용자 위험 프로필 업데이트
    INSERT INTO paperly.user_risk_profiles (user_id, current_risk_score, failed_login_attempts, last_risk_assessment_at)
    VALUES (p_user_id, risk_score, failed_attempts, CURRENT_TIMESTAMP)
    ON CONFLICT (user_id) DO UPDATE SET
        current_risk_score = EXCLUDED.current_risk_score,
        max_risk_score = GREATEST(user_risk_profiles.max_risk_score, EXCLUDED.current_risk_score),
        failed_login_attempts = EXCLUDED.failed_login_attempts,
        last_risk_assessment_at = EXCLUDED.last_risk_assessment_at,
        updated_at = CURRENT_TIMESTAMP;
    
    RETURN risk_score;
END;
$$ LANGUAGE plpgsql;

-- 로그인 시도 후 자동 위험 평가 트리거
CREATE OR REPLACE FUNCTION paperly.auto_assess_login_risk()
RETURNS TRIGGER AS $$
DECLARE
    user_id_found UUID;
    risk_score INTEGER;
BEGIN
    -- 이메일로 사용자 ID 찾기
    SELECT id INTO user_id_found
    FROM paperly.users
    WHERE email = NEW.email;
    
    IF user_id_found IS NOT NULL THEN
        -- 위험 점수 계산
        risk_score := paperly.calculate_user_risk_score(user_id_found);
        
        -- 위험 점수가 높으면 보안 이벤트 생성
        IF risk_score >= 70 THEN
            INSERT INTO paperly.security_events (
                event_type,
                severity,
                user_id,
                email,
                ip_address,
                user_agent,
                description,
                details,
                detection_rule,
                risk_score
            ) VALUES (
                'high_risk_login',
                CASE 
                    WHEN risk_score >= 90 THEN 'critical'
                    WHEN risk_score >= 80 THEN 'high'
                    ELSE 'medium'
                END,
                user_id_found,
                NEW.email,
                NEW.ip_address,
                NEW.user_agent,
                format('High risk login attempt detected for user %s (risk score: %s)', NEW.email, risk_score),
                jsonb_build_object(
                    'risk_score', risk_score,
                    'login_success', NEW.success,
                    'failure_reason', NEW.failure_reason
                ),
                'auto_risk_assessment',
                risk_score
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 로그인 시도 후 위험 평가 트리거
CREATE TRIGGER trigger_auto_assess_login_risk
    AFTER INSERT ON paperly.login_attempts
    FOR EACH ROW EXECUTE FUNCTION paperly.auto_assess_login_risk();

-- =============================================
-- 7. 보안 정책 및 규칙
-- =============================================

-- 기본 보안 패턴 삽입
INSERT INTO paperly.suspicious_patterns (pattern_name, pattern_type, description, detection_rules, severity) VALUES
('Brute Force Login', 'brute_force', 'Multiple failed login attempts from same IP', 
 '{"max_failed_attempts": 5, "time_window_minutes": 15}', 'high'),
('Unusual Location Login', 'location_anomaly', 'Login from unusual geographic location',
 '{"check_previous_locations": true, "distance_threshold_km": 500}', 'medium'),
('Multiple Device Login', 'device_anomaly', 'Login from multiple devices in short time',
 '{"max_devices": 3, "time_window_hours": 1}', 'medium'),
('Data Scraping Pattern', 'data_scraping', 'Rapid API calls indicating automated access',
 '{"max_requests_per_minute": 100, "suspicious_endpoints": ["/api/users", "/api/articles"]}', 'high'),
('Privilege Escalation', 'privilege_escalation', 'Attempt to access admin functions',
 '{"monitor_admin_endpoints": true, "check_role_changes": true}', 'critical')
ON CONFLICT (pattern_name) DO NOTHING;

-- =============================================
-- 완료 메시지
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '================================='
    RAISE NOTICE 'Paperly 보안 모니터링 시스템 구축 완료';
    RAISE NOTICE '================================='
    RAISE NOTICE '생성된 보안 테이블:';
    RAISE NOTICE '- security_events: 보안 이벤트 로그';
    RAISE NOTICE '- login_attempts: 로그인 시도 기록';
    RAISE NOTICE '- user_sessions_security: 세션 보안 관리';
    RAISE NOTICE '- data_access_logs: 데이터 접근 감사';
    RAISE NOTICE '- api_access_logs: API 접근 로그';
    RAISE NOTICE '- user_risk_profiles: 사용자 위험 프로필';
    RAISE NOTICE '- suspicious_patterns: 의심 패턴 탐지';
    RAISE NOTICE '================================='
    RAISE NOTICE '보안 모니터링 및 자동 위험 평가 시스템 활성화됨';
    RAISE NOTICE '================================='
END $$;