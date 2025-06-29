-- =============================================
-- 사용자 역할 기본 데이터 설정
-- 독자(Reader)와 작가(Writer) 역할 시스템 구축
-- =============================================

-- paperly 스키마 사용 설정
SET search_path TO paperly, public;

-- =============================================
-- 1. 기본 역할 데이터 삽입
-- =============================================

-- 독자 역할 생성
INSERT INTO paperly.user_roles (id, name, display_name, description, permissions, is_active)
VALUES (
    uuid_generate_v4(),
    'reader',
    '독자',
    '일반 사용자 - 글을 읽고 상호작용할 수 있는 역할',
    '[
        "article.read",
        "article.like",
        "article.bookmark",
        "article.share",
        "article.comment",
        "article.rate",
        "category.subscribe",
        "tag.follow",
        "writer.follow",
        "profile.update"
    ]'::jsonb,
    true
) ON CONFLICT (name) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    description = EXCLUDED.description,
    permissions = EXCLUDED.permissions,
    updated_at = CURRENT_TIMESTAMP;

-- 작가 역할 생성
INSERT INTO paperly.user_roles (id, name, display_name, description, permissions, is_active)
VALUES (
    uuid_generate_v4(),
    'writer',
    '작가',
    '콘텐츠 작성자 - 글을 작성하고 발행할 수 있는 역할',
    '[
        "article.read",
        "article.like",
        "article.bookmark",
        "article.share",
        "article.comment",
        "article.rate",
        "article.create",
        "article.update",
        "article.delete",
        "article.publish",
        "series.create",
        "series.manage",
        "category.subscribe",
        "tag.follow",
        "tag.create",
        "writer.follow",
        "profile.update",
        "writer.profile.create",
        "writer.profile.update",
        "writer.analytics.view"
    ]'::jsonb,
    true
) ON CONFLICT (name) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    description = EXCLUDED.description,
    permissions = EXCLUDED.permissions,
    updated_at = CURRENT_TIMESTAMP;

-- 관리자 역할 생성
INSERT INTO paperly.user_roles (id, name, display_name, description, permissions, is_active)
VALUES (
    uuid_generate_v4(),
    'admin',
    '관리자',
    '시스템 관리자 - 모든 권한을 가진 역할',
    '[
        "*"
    ]'::jsonb,
    true
) ON CONFLICT (name) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    description = EXCLUDED.description,
    permissions = EXCLUDED.permissions,
    updated_at = CURRENT_TIMESTAMP;

-- =============================================
-- 2. 사용자 테이블에 사용자 코드(타입) 컬럼 추가
-- =============================================

-- user_type 컬럼 추가 (독자/작가 구분용)
ALTER TABLE paperly.users 
ADD COLUMN IF NOT EXISTS user_type VARCHAR(20) DEFAULT 'reader' 
CHECK (user_type IN ('reader', 'writer', 'admin'));

-- 기존 사용자들에 대한 user_type 설정
-- 작가 프로필이 있는 사용자는 writer로 설정
UPDATE paperly.users 
SET user_type = 'writer' 
WHERE id IN (
    SELECT user_id 
    FROM paperly.writer_profiles 
    WHERE user_id IS NOT NULL
);

-- user_code 컬럼 추가 (고유한 사용자 식별 코드)
ALTER TABLE paperly.users 
ADD COLUMN IF NOT EXISTS user_code VARCHAR(20) UNIQUE;

-- 기존 사용자들에게 user_code 생성 및 할당
CREATE OR REPLACE FUNCTION paperly.generate_user_code(user_type_param VARCHAR, user_id_param UUID)
RETURNS VARCHAR AS $$
DECLARE
    prefix VARCHAR(2);
    sequence_num INTEGER;
    code VARCHAR(20);
BEGIN
    -- 사용자 타입별 접두사 설정
    CASE user_type_param
        WHEN 'reader' THEN prefix := 'RD';
        WHEN 'writer' THEN prefix := 'WR';
        WHEN 'admin' THEN prefix := 'AD';
        ELSE prefix := 'US';
    END CASE;
    
    -- 해당 타입의 다음 시퀀스 번호 생성
    SELECT COALESCE(MAX(CAST(SUBSTRING(user_code FROM 3) AS INTEGER)), 0) + 1
    INTO sequence_num
    FROM paperly.users 
    WHERE user_code LIKE prefix || '%' 
    AND user_code ~ '^[A-Z]{2}[0-9]+$';
    
    -- 코드 생성 (예: RD1001, WR2001)
    code := prefix || LPAD(sequence_num::TEXT, 4, '0');
    
    RETURN code;
END;
$$ LANGUAGE plpgsql;

-- 기존 사용자들에게 user_code 할당
UPDATE paperly.users 
SET user_code = paperly.generate_user_code(user_type, id)
WHERE user_code IS NULL;

-- =============================================  
-- 3. 기존 사용자들에게 기본 역할 할당
-- =============================================

-- 독자 역할 할당 (writer_profiles가 없는 사용자)
INSERT INTO paperly.user_role_assignments (user_id, role_id, assigned_at, is_active)
SELECT 
    u.id,
    (SELECT id FROM paperly.user_roles WHERE name = 'reader'),
    CURRENT_TIMESTAMP,
    true
FROM paperly.users u
WHERE u.user_type = 'reader'
AND NOT EXISTS (
    SELECT 1 FROM paperly.user_role_assignments ura 
    WHERE ura.user_id = u.id
)
ON CONFLICT (user_id, role_id) DO NOTHING;

-- 작가 역할 할당 (writer_profiles가 있는 사용자)  
INSERT INTO paperly.user_role_assignments (user_id, role_id, assigned_at, is_active)
SELECT 
    u.id,
    (SELECT id FROM paperly.user_roles WHERE name = 'writer'),
    CURRENT_TIMESTAMP,
    true
FROM paperly.users u
WHERE u.user_type = 'writer'
AND NOT EXISTS (
    SELECT 1 FROM paperly.user_role_assignments ura 
    WHERE ura.user_id = u.id
)
ON CONFLICT (user_id, role_id) DO NOTHING;

-- =============================================
-- 4. 사용자 코드 자동 생성 트리거 함수 생성
-- =============================================

-- 새 사용자 생성 시 자동으로 user_code와 기본 역할 할당
CREATE OR REPLACE FUNCTION paperly.assign_user_code_and_role()
RETURNS TRIGGER AS $$
DECLARE
    default_role_id UUID;
BEGIN
    -- user_code가 없다면 생성
    IF NEW.user_code IS NULL THEN
        NEW.user_code := paperly.generate_user_code(NEW.user_type, NEW.id);
    END IF;
    
    -- 기본 역할 ID 가져오기
    SELECT id INTO default_role_id 
    FROM paperly.user_roles 
    WHERE name = NEW.user_type AND is_active = true;
    
    -- 기본 역할 할당 (트리거 후에 실행하기 위해 별도 처리)
    IF default_role_id IS NOT NULL THEN
        INSERT INTO paperly.user_role_assignments (user_id, role_id, assigned_at, is_active)
        VALUES (NEW.id, default_role_id, CURRENT_TIMESTAMP, true)
        ON CONFLICT (user_id, role_id) DO NOTHING;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 사용자 생성 시 트리거 설정
DROP TRIGGER IF EXISTS assign_user_code_and_role_trigger ON paperly.users;
CREATE TRIGGER assign_user_code_and_role_trigger
    BEFORE INSERT ON paperly.users
    FOR EACH ROW
    EXECUTE FUNCTION paperly.assign_user_code_and_role();

-- =============================================
-- 5. 인덱스 생성
-- =============================================

-- 사용자 코드 및 타입 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_user_code ON paperly.users (user_code);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_user_type ON paperly.users (user_type);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_type_status ON paperly.users (user_type, status) WHERE status = 'active';

-- 역할 할당 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_role_assignments_user_active ON paperly.user_role_assignments (user_id, is_active) WHERE is_active = true;

-- =============================================
-- 6. 사용자 역할 확인용 뷰 생성
-- =============================================

-- 사용자와 역할 정보를 조합한 뷰
CREATE OR REPLACE VIEW paperly.v_user_roles AS
SELECT 
    u.id,
    u.email,
    u.name,
    u.user_code,
    u.user_type,
    u.status,
    r.name as role_name,
    r.display_name as role_display_name,
    r.permissions,
    ura.assigned_at,
    ura.is_active as role_active
FROM paperly.users u
LEFT JOIN paperly.user_role_assignments ura ON u.id = ura.user_id AND ura.is_active = true
LEFT JOIN paperly.user_roles r ON ura.role_id = r.id
WHERE u.status = 'active';

-- =============================================
-- 완료 메시지
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '================================='
    RAISE NOTICE '사용자 역할 시스템 설정 완료';
    RAISE NOTICE '================================='
    RAISE NOTICE '설정된 기본 역할:';
    RAISE NOTICE '- reader (독자): 글 읽기 및 상호작용';
    RAISE NOTICE '- writer (작가): 글 작성 및 발행';
    RAISE NOTICE '- admin (관리자): 모든 권한';
    RAISE NOTICE '================================='
    RAISE NOTICE '사용자 코드 형식:';
    RAISE NOTICE '- 독자: RD#### (예: RD0001)';
    RAISE NOTICE '- 작가: WR#### (예: WR0001)';
    RAISE NOTICE '- 관리자: AD#### (예: AD0001)';
    RAISE NOTICE '================================='
END $$;