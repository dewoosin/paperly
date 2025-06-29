-- 005_admin_content_management.sql
-- 관리자 및 작가 기능을 위한 테이블 생성 및 수정

SET search_path TO paperly, public;

-- 사용자 역할 테이블
CREATE TABLE IF NOT EXISTS paperly.user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    permissions JSONB NOT NULL DEFAULT '[]',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- 사용자-역할 매핑 테이블
CREATE TABLE IF NOT EXISTS paperly.user_role_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES paperly.users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES paperly.user_roles(id) ON DELETE CASCADE,
    assigned_by UUID REFERENCES paperly.users(id),
    assigned_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN NOT NULL DEFAULT true,
    UNIQUE(user_id, role_id)
);

-- 기존 categories 테이블에 필요한 컬럼 추가
ALTER TABLE paperly.categories 
ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES paperly.users(id),
ADD COLUMN IF NOT EXISTS is_featured BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN IF NOT EXISTS display_order INTEGER NOT NULL DEFAULT 0;

-- color_code를 color_hex로 변경하지 않고 그대로 사용
-- 기존 tags 테이블에 필요한 컬럼 추가
ALTER TABLE paperly.tags 
ADD COLUMN IF NOT EXISTS slug VARCHAR(100),
ADD COLUMN IF NOT EXISTS description TEXT,
ADD COLUMN IF NOT EXISTS color_hex VARCHAR(7),
ADD COLUMN IF NOT EXISTS usage_count INTEGER NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS is_featured BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES paperly.users(id),
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- tags 테이블에 slug 인덱스 추가 (중복 방지)
CREATE UNIQUE INDEX IF NOT EXISTS idx_tags_slug_unique ON paperly.tags(slug) WHERE slug IS NOT NULL;

-- 기사 상태 enum
CREATE TYPE paperly.article_status AS ENUM (
    'draft',        -- 초안
    'review',       -- 검토 중
    'published',    -- 발행됨
    'archived',     -- 보관됨
    'deleted'       -- 삭제됨
);

-- 기존 articles 테이블에 필요한 컬럼 추가
ALTER TABLE paperly.articles 
ADD COLUMN IF NOT EXISTS author_id UUID REFERENCES paperly.users(id),
ADD COLUMN IF NOT EXISTS editor_id UUID REFERENCES paperly.users(id),
ADD COLUMN IF NOT EXISTS subtitle VARCHAR(1000),
ADD COLUMN IF NOT EXISTS excerpt TEXT,
ADD COLUMN IF NOT EXISTS content TEXT,
ADD COLUMN IF NOT EXISTS content_html TEXT,
ADD COLUMN IF NOT EXISTS visibility VARCHAR(20) DEFAULT 'public',
ADD COLUMN IF NOT EXISTS view_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS like_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS share_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS comment_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS is_trending BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS trending_score DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS ai_summary TEXT,
ADD COLUMN IF NOT EXISTS ai_tags JSONB DEFAULT '[]',
ADD COLUMN IF NOT EXISTS ai_reading_level VARCHAR(20),
ADD COLUMN IF NOT EXISTS ai_sentiment VARCHAR(20),
ADD COLUMN IF NOT EXISTS scheduled_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}',
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

-- status 컬럼이 있지만 ENUM 타입이 아닌 경우 처리
-- 일단 기존 status를 그대로 사용하고 나중에 변환

-- 기사-태그 매핑 테이블
CREATE TABLE IF NOT EXISTS paperly.article_tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    article_id UUID NOT NULL REFERENCES paperly.articles(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES paperly.tags(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(article_id, tag_id)
);

-- 기사 버전 관리 테이블
CREATE TABLE IF NOT EXISTS paperly.article_revisions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    article_id UUID NOT NULL REFERENCES paperly.articles(id) ON DELETE CASCADE,
    version INTEGER NOT NULL,
    title VARCHAR(500) NOT NULL,
    content TEXT NOT NULL,
    content_html TEXT,
    excerpt TEXT,
    changed_by UUID NOT NULL REFERENCES paperly.users(id),
    change_summary VARCHAR(500),
    diff_json JSONB, -- 변경사항을 JSON으로 저장
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(article_id, version)
);

-- 기사 통계 테이블 (일별)
CREATE TABLE IF NOT EXISTS paperly.article_stats_daily (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    article_id UUID NOT NULL REFERENCES paperly.articles(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    views INTEGER NOT NULL DEFAULT 0,
    likes INTEGER NOT NULL DEFAULT 0,
    shares INTEGER NOT NULL DEFAULT 0,
    comments INTEGER NOT NULL DEFAULT 0,
    reading_completion_rate DECIMAL(5,2), -- 완독률 퍼센트
    avg_reading_time_seconds INTEGER,
    unique_visitors INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(article_id, date)
);

-- 워크플로우 상태 테이블
CREATE TABLE IF NOT EXISTS paperly.workflow_states (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    article_id UUID NOT NULL REFERENCES paperly.articles(id) ON DELETE CASCADE,
    from_status paperly.article_status,
    to_status paperly.article_status NOT NULL,
    changed_by UUID NOT NULL REFERENCES paperly.users(id),
    reason VARCHAR(500),
    notes TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- 기본 역할 데이터 삽입
INSERT INTO paperly.user_roles (name, display_name, description, permissions) VALUES
    ('super_admin', '슈퍼 관리자', '모든 권한을 가진 최고 관리자', '["*"]'),
    ('admin', '관리자', '시스템 관리 권한', '["user.manage", "article.manage", "category.manage", "analytics.view"]'),
    ('editor', '에디터', '기사 편집 및 발행 권한', '["article.edit", "article.publish", "article.view_all"]'),
    ('author', '작가', '기사 작성 권한', '["article.create", "article.edit_own", "article.view_own"]'),
    ('reviewer', '검토자', '기사 검토 권한', '["article.review", "article.view_all"]'),
    ('user', '일반 사용자', '기본 사용자 권한', '["article.view_published"]')
ON CONFLICT (name) DO NOTHING;

-- 기존 카테고리 데이터 업데이트 (color_code 사용)
UPDATE paperly.categories SET 
    color_code = '#3b82f6', 
    display_order = 1, 
    is_featured = true,
    created_by = (SELECT id FROM paperly.users LIMIT 1)
WHERE slug = 'business';

UPDATE paperly.categories SET 
    color_code = '#8b5cf6', 
    display_order = 2, 
    is_featured = true,
    created_by = (SELECT id FROM paperly.users LIMIT 1)
WHERE name LIKE '%자기계발%' OR name LIKE '%self%';

-- 새로운 카테고리 추가 (기존에 없는 경우만)
INSERT INTO paperly.categories (name, slug, description, color_code, icon_name, display_order, is_featured, created_by) 
SELECT '비즈니스', 'business', '비즈니스와 경영에 관한 글', '#3b82f6', '💼', 1, true, (SELECT id FROM paperly.users LIMIT 1)
WHERE NOT EXISTS (SELECT 1 FROM paperly.categories WHERE slug = 'business');

INSERT INTO paperly.categories (name, slug, description, color_code, icon_name, display_order, is_featured, created_by) 
SELECT '자기계발', 'self-development', '개인 성장과 자기계발', '#8b5cf6', '📈', 2, true, (SELECT id FROM paperly.users LIMIT 1)
WHERE NOT EXISTS (SELECT 1 FROM paperly.categories WHERE slug = 'self-development');

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_articles_status ON paperly.articles(status);
CREATE INDEX IF NOT EXISTS idx_articles_author_id ON paperly.articles(author_id);
CREATE INDEX IF NOT EXISTS idx_articles_category_id ON paperly.articles(category_id);
CREATE INDEX IF NOT EXISTS idx_articles_published_at ON paperly.articles(published_at);
CREATE INDEX IF NOT EXISTS idx_articles_featured ON paperly.articles(is_featured);
CREATE INDEX IF NOT EXISTS idx_articles_trending ON paperly.articles(is_trending);
CREATE INDEX IF NOT EXISTS idx_articles_view_count ON paperly.articles(view_count);
CREATE INDEX IF NOT EXISTS idx_articles_slug ON paperly.articles(slug);

CREATE INDEX IF NOT EXISTS idx_article_tags_article_id ON paperly.article_tags(article_id);
CREATE INDEX IF NOT EXISTS idx_article_tags_tag_id ON paperly.article_tags(tag_id);

CREATE INDEX IF NOT EXISTS idx_categories_parent_id ON paperly.categories(parent_id);
CREATE INDEX IF NOT EXISTS idx_categories_slug ON paperly.categories(slug);
CREATE INDEX IF NOT EXISTS idx_categories_active ON paperly.categories(is_active);

CREATE INDEX IF NOT EXISTS idx_tags_slug ON paperly.tags(slug);
CREATE INDEX IF NOT EXISTS idx_tags_usage_count ON paperly.tags(usage_count);

CREATE INDEX IF NOT EXISTS idx_user_role_assignments_user_id ON paperly.user_role_assignments(user_id);
CREATE INDEX IF NOT EXISTS idx_user_role_assignments_role_id ON paperly.user_role_assignments(role_id);
CREATE INDEX IF NOT EXISTS idx_user_role_assignments_active ON paperly.user_role_assignments(is_active);

CREATE INDEX IF NOT EXISTS idx_article_stats_daily_article_id ON paperly.article_stats_daily(article_id);
CREATE INDEX IF NOT EXISTS idx_article_stats_daily_date ON paperly.article_stats_daily(date);

CREATE INDEX IF NOT EXISTS idx_workflow_states_article_id ON paperly.workflow_states(article_id);
CREATE INDEX IF NOT EXISTS idx_workflow_states_created_at ON paperly.workflow_states(created_at);

-- 트리거 함수들
CREATE OR REPLACE FUNCTION paperly.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- updated_at 자동 업데이트 트리거
CREATE TRIGGER update_categories_updated_at 
    BEFORE UPDATE ON paperly.categories 
    FOR EACH ROW EXECUTE FUNCTION paperly.update_updated_at_column();

CREATE TRIGGER update_tags_updated_at 
    BEFORE UPDATE ON paperly.tags 
    FOR EACH ROW EXECUTE FUNCTION paperly.update_updated_at_column();

CREATE TRIGGER update_articles_updated_at 
    BEFORE UPDATE ON paperly.articles 
    FOR EACH ROW EXECUTE FUNCTION paperly.update_updated_at_column();

CREATE TRIGGER update_user_roles_updated_at 
    BEFORE UPDATE ON paperly.user_roles 
    FOR EACH ROW EXECUTE FUNCTION paperly.update_updated_at_column();

-- 태그 사용량 업데이트 함수
CREATE OR REPLACE FUNCTION paperly.update_tag_usage_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE paperly.tags 
        SET usage_count = usage_count + 1 
        WHERE id = NEW.tag_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE paperly.tags 
        SET usage_count = GREATEST(usage_count - 1, 0) 
        WHERE id = OLD.tag_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

-- 태그 사용량 트리거
CREATE TRIGGER update_tag_usage_count_trigger
    AFTER INSERT OR DELETE ON paperly.article_tags
    FOR EACH ROW EXECUTE FUNCTION paperly.update_tag_usage_count();

-- 기사 통계 업데이트 함수
CREATE OR REPLACE FUNCTION paperly.update_article_counts()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        -- 조회수, 좋아요 등의 변화가 있을 때 통계 테이블 업데이트
        INSERT INTO paperly.article_stats_daily (article_id, date, views, likes, shares, comments)
        VALUES (NEW.id, CURRENT_DATE, NEW.view_count, NEW.like_count, NEW.share_count, NEW.comment_count)
        ON CONFLICT (article_id, date) 
        DO UPDATE SET 
            views = EXCLUDED.views,
            likes = EXCLUDED.likes,
            shares = EXCLUDED.shares,
            comments = EXCLUDED.comments;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 기사 통계 트리거
CREATE TRIGGER update_article_counts_trigger
    AFTER UPDATE OF view_count, like_count, share_count, comment_count ON paperly.articles
    FOR EACH ROW EXECUTE FUNCTION paperly.update_article_counts();

COMMENT ON TABLE paperly.user_roles IS '사용자 역할 정의';
COMMENT ON TABLE paperly.user_role_assignments IS '사용자-역할 매핑';
COMMENT ON TABLE paperly.categories IS '기사 카테고리';
COMMENT ON TABLE paperly.tags IS '기사 태그';
COMMENT ON TABLE paperly.articles IS '기사 메인 테이블';
COMMENT ON TABLE paperly.article_tags IS '기사-태그 매핑';
COMMENT ON TABLE paperly.article_revisions IS '기사 버전 관리';
COMMENT ON TABLE paperly.article_stats_daily IS '기사 일별 통계';
COMMENT ON TABLE paperly.workflow_states IS '기사 워크플로우 상태 변경 이력';