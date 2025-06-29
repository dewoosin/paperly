-- 작가 프로필 관리를 위한 테이블들

-- 작가 프로필 테이블
CREATE TABLE IF NOT EXISTS paperly.writer_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    display_name VARCHAR(100) NOT NULL,
    bio TEXT,
    profile_image_url TEXT,
    
    -- 전문 분야
    specialties TEXT[] DEFAULT '{}',
    
    -- 경력 정보
    years_of_experience INTEGER DEFAULT 0,
    education TEXT,
    previous_publications TEXT[],
    awards TEXT[],
    
    -- 소셜 미디어 및 연락처 (선택사항)
    website_url TEXT,
    twitter_handle VARCHAR(50),
    instagram_handle VARCHAR(50),
    linkedin_url TEXT,
    contact_email VARCHAR(255),
    
    -- 작가 설정
    is_available_for_collaboration BOOLEAN DEFAULT true,
    preferred_topics TEXT[],
    writing_schedule TEXT, -- 예: "평일 오전", "주말", etc.
    
    -- 검증 상태
    is_verified BOOLEAN DEFAULT false,
    verification_date TIMESTAMP,
    verification_notes TEXT,
    
    -- 통계 정보 (캐시용)
    total_articles INTEGER DEFAULT 0,
    total_views INTEGER DEFAULT 0,
    total_likes INTEGER DEFAULT 0,
    follower_count INTEGER DEFAULT 0,
    
    -- 메타 정보
    profile_completed BOOLEAN DEFAULT false,
    last_active_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_writer_profiles_user_id ON paperly.writer_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_writer_profiles_display_name ON paperly.writer_profiles(display_name);
CREATE INDEX IF NOT EXISTS idx_writer_profiles_specialties ON paperly.writer_profiles USING gin(specialties);
CREATE INDEX IF NOT EXISTS idx_writer_profiles_verified ON paperly.writer_profiles(is_verified);
CREATE INDEX IF NOT EXISTS idx_writer_profiles_available ON paperly.writer_profiles(is_available_for_collaboration);

-- 작가 포트폴리오 항목 테이블
CREATE TABLE IF NOT EXISTS paperly.writer_portfolio_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    writer_profile_id UUID NOT NULL REFERENCES paperly.writer_profiles(id) ON DELETE CASCADE,
    
    title VARCHAR(200) NOT NULL,
    description TEXT,
    content_type VARCHAR(50) NOT NULL, -- 'article', 'book', 'blog_post', 'publication', etc.
    
    -- 링크 정보
    external_url TEXT,
    article_id UUID REFERENCES paperly.articles(id), -- 내부 기사인 경우
    
    -- 발행 정보
    published_at TIMESTAMP,
    publisher VARCHAR(100),
    
    -- 메타 정보
    tags TEXT[],
    featured BOOLEAN DEFAULT false,
    display_order INTEGER DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 포트폴리오 인덱스
CREATE INDEX IF NOT EXISTS idx_portfolio_writer_profile ON paperly.writer_portfolio_items(writer_profile_id);
CREATE INDEX IF NOT EXISTS idx_portfolio_featured ON paperly.writer_portfolio_items(featured);
CREATE INDEX IF NOT EXISTS idx_portfolio_order ON paperly.writer_portfolio_items(display_order);

-- 작가 팔로우 관계 테이블
CREATE TABLE IF NOT EXISTS paperly.writer_follows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    follower_user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    following_writer_profile_id UUID NOT NULL REFERENCES paperly.writer_profiles(id) ON DELETE CASCADE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(follower_user_id, following_writer_profile_id)
);

-- 팔로우 인덱스
CREATE INDEX IF NOT EXISTS idx_follows_follower ON paperly.writer_follows(follower_user_id);
CREATE INDEX IF NOT EXISTS idx_follows_following ON paperly.writer_follows(following_writer_profile_id);

-- 작가 프로필 조회수 로그 테이블 (통계용)
CREATE TABLE IF NOT EXISTS paperly.writer_profile_views (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    writer_profile_id UUID NOT NULL REFERENCES paperly.writer_profiles(id) ON DELETE CASCADE,
    viewer_user_id UUID REFERENCES paperly.users(id) ON DELETE SET NULL,
    viewer_ip_address INET,
    user_agent TEXT,
    
    viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 조회수 인덱스
CREATE INDEX IF NOT EXISTS idx_profile_views_profile ON paperly.writer_profile_views(writer_profile_id);
CREATE INDEX IF NOT EXISTS idx_profile_views_date ON paperly.writer_profile_views(viewed_at);

-- 기존 users 테이블에 profile_completed 컬럼 추가 (있으면 무시)
ALTER TABLE paperly.users 
ADD COLUMN IF NOT EXISTS profile_completed BOOLEAN DEFAULT false;

-- 업데이트 트리거 함수 생성
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 트리거 생성
DROP TRIGGER IF EXISTS update_writer_profiles_updated_at ON paperly.writer_profiles;
CREATE TRIGGER update_writer_profiles_updated_at
    BEFORE UPDATE ON paperly.writer_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_portfolio_items_updated_at ON paperly.writer_portfolio_items;
CREATE TRIGGER update_portfolio_items_updated_at
    BEFORE UPDATE ON paperly.writer_portfolio_items
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 통계 업데이트 함수
CREATE OR REPLACE FUNCTION update_writer_profile_stats(profile_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE paperly.writer_profiles 
    SET 
        total_articles = (
            SELECT COUNT(*) 
            FROM paperly.articles a 
            JOIN paperly.users u ON a.author_id = u.id
            WHERE u.id = (SELECT user_id FROM paperly.writer_profiles WHERE id = profile_id)
            AND a.status = 'published'
        ),
        total_views = (
            SELECT COALESCE(SUM(a.view_count), 0)
            FROM paperly.articles a 
            JOIN paperly.users u ON a.author_id = u.id
            WHERE u.id = (SELECT user_id FROM paperly.writer_profiles WHERE id = profile_id)
            AND a.status = 'published'
        ),
        total_likes = (
            SELECT COALESCE(SUM(a.like_count), 0)
            FROM paperly.articles a 
            JOIN paperly.users u ON a.author_id = u.id
            WHERE u.id = (SELECT user_id FROM paperly.writer_profiles WHERE id = profile_id)
            AND a.status = 'published'
        ),
        follower_count = (
            SELECT COUNT(*) 
            FROM paperly.writer_follows 
            WHERE following_writer_profile_id = profile_id
        ),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = profile_id;
END;
$$ LANGUAGE plpgsql;

-- 프로필 완료 상태 체크 함수
CREATE OR REPLACE FUNCTION check_profile_completion()
RETURNS TRIGGER AS $$
BEGIN
    -- 프로필 완료 조건: display_name, bio, specialties가 모두 있어야 함
    NEW.profile_completed = (
        NEW.display_name IS NOT NULL AND NEW.display_name != '' AND
        NEW.bio IS NOT NULL AND NEW.bio != '' AND
        array_length(NEW.specialties, 1) > 0
    );
    
    -- users 테이블의 profile_completed도 업데이트
    UPDATE paperly.users 
    SET profile_completed = NEW.profile_completed
    WHERE id = NEW.user_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 프로필 완료 체크 트리거
DROP TRIGGER IF EXISTS check_writer_profile_completion ON paperly.writer_profiles;
CREATE TRIGGER check_writer_profile_completion
    BEFORE INSERT OR UPDATE ON paperly.writer_profiles
    FOR EACH ROW
    EXECUTE FUNCTION check_profile_completion();

-- 초기 데이터: 기본 작가 역할 추가
INSERT INTO paperly.user_roles (name, display_name, description, permissions) 
VALUES (
    'writer', 
    '작가', 
    '글을 작성하고 발행할 수 있는 기본 작가 권한', 
    '["article:create", "article:edit_own", "article:delete_own", "article:publish_own", "profile:edit_own"]'::jsonb
) ON CONFLICT (name) DO NOTHING;

-- 전문 분야 기본 카테고리들
COMMENT ON COLUMN paperly.writer_profiles.specialties IS '전문 분야: 기술, 문학, 과학, 경제, 정치, 사회, 문화, 예술, 스포츠, 여행, 음식, 패션, 건강, 교육, 환경 등';
COMMENT ON COLUMN paperly.writer_profiles.writing_schedule IS '글쓰기 일정: 평일 오전, 평일 오후, 주말, 자유롭게, 기타';
COMMENT ON COLUMN paperly.writer_profiles.profile_completed IS '프로필 완료 여부: display_name, bio, specialties가 모두 입력되면 true';