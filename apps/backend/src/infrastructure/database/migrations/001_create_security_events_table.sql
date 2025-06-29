-- 보안 이벤트 테이블 생성 스크립트
-- Paperly Backend Security Monitoring System

-- 보안 이벤트 저장을 위한 테이블 생성
CREATE TABLE IF NOT EXISTS paperly.security_events (
    -- 기본 정보
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type VARCHAR(100) NOT NULL,
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    status VARCHAR(30) NOT NULL DEFAULT 'detected' CHECK (status IN ('detected', 'investigating', 'blocked', 'resolved', 'false_positive')),
    
    -- 타임스탬프
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- 출처 정보 (JSONB로 저장)
    source JSONB NOT NULL,
    source_ip INET, -- 인덱싱을 위한 별도 컬럼
    source_user_id UUID, -- 인덱싱을 위한 별도 컬럼
    
    -- 대상 정보 (JSONB로 저장)
    target JSONB NOT NULL,
    target_endpoint VARCHAR(500), -- 인덱싱을 위한 별도 컬럼
    
    -- 상세 정보 (JSONB로 저장)
    details JSONB NOT NULL,
    risk_score INTEGER CHECK (risk_score >= 0 AND risk_score <= 100),
    threats TEXT[],
    
    -- 대응 정보 (JSONB로 저장)
    response JSONB,
    blocked BOOLEAN DEFAULT false,
    
    -- 추가 메타데이터
    metadata JSONB DEFAULT '{}'::jsonb
);

-- 인덱스 생성 (성능 최적화)
CREATE INDEX IF NOT EXISTS idx_security_events_timestamp ON paperly.security_events (timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_security_events_type ON paperly.security_events (type);
CREATE INDEX IF NOT EXISTS idx_security_events_severity ON paperly.security_events (severity);
CREATE INDEX IF NOT EXISTS idx_security_events_source_ip ON paperly.security_events (source_ip);
CREATE INDEX IF NOT EXISTS idx_security_events_source_user_id ON paperly.security_events (source_user_id);
CREATE INDEX IF NOT EXISTS idx_security_events_status ON paperly.security_events (status);
CREATE INDEX IF NOT EXISTS idx_security_events_risk_score ON paperly.security_events (risk_score);
CREATE INDEX IF NOT EXISTS idx_security_events_target_endpoint ON paperly.security_events (target_endpoint);

-- 복합 인덱스 (자주 사용되는 쿼리 패턴)
CREATE INDEX IF NOT EXISTS idx_security_events_type_severity ON paperly.security_events (type, severity);
CREATE INDEX IF NOT EXISTS idx_security_events_timestamp_type ON paperly.security_events (timestamp DESC, type);
CREATE INDEX IF NOT EXISTS idx_security_events_source_ip_timestamp ON paperly.security_events (source_ip, timestamp DESC);

-- JSONB 필드에 대한 GIN 인덱스 (검색 성능 향상)
CREATE INDEX IF NOT EXISTS idx_security_events_source_gin ON paperly.security_events USING gin (source);
CREATE INDEX IF NOT EXISTS idx_security_events_target_gin ON paperly.security_events USING gin (target);
CREATE INDEX IF NOT EXISTS idx_security_events_details_gin ON paperly.security_events USING gin (details);

-- 자동 updated_at 업데이트 트리거 함수
CREATE OR REPLACE FUNCTION paperly.update_security_events_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 트리거 생성
DROP TRIGGER IF EXISTS trigger_update_security_events_updated_at ON paperly.security_events;
CREATE TRIGGER trigger_update_security_events_updated_at
    BEFORE UPDATE ON paperly.security_events
    FOR EACH ROW
    EXECUTE FUNCTION paperly.update_security_events_updated_at();

-- 파티셔닝을 위한 함수 (향후 대용량 데이터 처리용)
-- 월별 파티션 테이블 생성 예시 (주석 처리)
/*
CREATE OR REPLACE FUNCTION paperly.create_security_events_partition(year_month TEXT)
RETURNS VOID AS $$
BEGIN
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS paperly.security_events_%s 
        PARTITION OF paperly.security_events 
        FOR VALUES FROM (%L) TO (%L)',
        year_month,
        year_month || '-01',
        (year_month || '-01')::date + interval '1 month'
    );
END;
$$ LANGUAGE plpgsql;
*/

-- 테이블 코멘트
COMMENT ON TABLE paperly.security_events IS '보안 이벤트 저장 테이블 - XSS, SQL Injection, Path Traversal 등 모든 보안 위협 이벤트를 저장';
COMMENT ON COLUMN paperly.security_events.id IS '보안 이벤트 고유 ID (UUID)';
COMMENT ON COLUMN paperly.security_events.type IS '보안 이벤트 타입 (XSS_ATTACK_DETECTED, SQL_INJECTION_DETECTED 등)';
COMMENT ON COLUMN paperly.security_events.severity IS '심각도 (low, medium, high, critical)';
COMMENT ON COLUMN paperly.security_events.status IS '처리 상태 (detected, investigating, blocked, resolved, false_positive)';
COMMENT ON COLUMN paperly.security_events.source IS '출처 정보 JSON (ip, userAgent, userId, sessionId, deviceId)';
COMMENT ON COLUMN paperly.security_events.target IS '대상 정보 JSON (endpoint, method, parameters, headers)';
COMMENT ON COLUMN paperly.security_events.details IS '상세 정보 JSON (description, payload, threats, riskScore, validationResults, context)';
COMMENT ON COLUMN paperly.security_events.response IS '대응 정보 JSON (action, blocked, message, recommendations)';
COMMENT ON COLUMN paperly.security_events.risk_score IS '위험 점수 (0-100)';
COMMENT ON COLUMN paperly.security_events.threats IS '감지된 위협 목록 배열';

-- 초기 데이터 확인 쿼리 (관리자용)
-- SELECT COUNT(*) FROM paperly.security_events;
-- SELECT type, COUNT(*) FROM paperly.security_events GROUP BY type;
-- SELECT severity, COUNT(*) FROM paperly.security_events GROUP BY severity;