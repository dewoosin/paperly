-- =============================================
-- Paperly 기초 데이터 적재 스크립트
-- Version: 2.0.0
-- =============================================

-- paperly 스키마 사용 설정
SET search_path TO paperly, public;

-- =============================================
-- 1. 시스템 설정 데이터
-- =============================================

-- 시스템 설정 기본값
INSERT INTO paperly.system_configs (config_key, config_value, description, config_type, is_public) VALUES
('app_name', 'Paperly', 'Application name', 'string', true),
('app_version', '2.0.0', 'Application version', 'string', true),
('default_language', 'ko', 'Default language', 'string', true),
('max_articles_per_day', '5', 'Maximum articles per user per day', 'number', false),
('recommendation_refresh_hours', '6', 'Hours between recommendation refresh', 'number', false),
('session_timeout_minutes', '1440', 'Session timeout in minutes (24 hours)', 'number', false),
('ai_model_version', 'gpt-4', 'AI model version for content analysis', 'string', false),
('embedding_model', 'openai-ada-002', 'Embedding model for recommendations', 'string', false),
('max_file_upload_mb', '10', 'Maximum file upload size in MB', 'number', true),
('maintenance_mode', 'false', 'Maintenance mode flag', 'boolean', true)
ON CONFLICT (config_key) DO NOTHING;

-- 공통코드 데이터
INSERT INTO paperly.common_codes (code_group, code_value, code_name, sort_order, is_active) VALUES
-- 사용자 상태
('USER_STATUS', 'active', '활성', 1, true),
('USER_STATUS', 'inactive', '비활성', 2, true),
('USER_STATUS', 'suspended', '정지', 3, true),
('USER_STATUS', 'deleted', '삭제', 4, true),

-- 글 상태
('ARTICLE_STATUS', 'draft', '초안', 1, true),
('ARTICLE_STATUS', 'review', '검토중', 2, true),
('ARTICLE_STATUS', 'published', '발행됨', 3, true),
('ARTICLE_STATUS', 'archived', '보관됨', 4, true),
('ARTICLE_STATUS', 'deleted', '삭제됨', 5, true),

-- 콘텐츠 타입
('CONTENT_TYPE', 'article', '기사', 1, true),
('CONTENT_TYPE', 'series', '연재', 2, true),
('CONTENT_TYPE', 'tutorial', '튜토리얼', 3, true),
('CONTENT_TYPE', 'opinion', '의견', 4, true),
('CONTENT_TYPE', 'news', '뉴스', 5, true),

-- 디바이스 타입
('DEVICE_TYPE', 'mobile', '모바일', 1, true),
('DEVICE_TYPE', 'tablet', '태블릿', 2, true),
('DEVICE_TYPE', 'desktop', '데스크톱', 3, true),

-- 난이도 레벨
('DIFFICULTY_LEVEL', '1', '입문', 1, true),
('DIFFICULTY_LEVEL', '2', '초급', 2, true),
('DIFFICULTY_LEVEL', '3', '중급', 3, true),
('DIFFICULTY_LEVEL', '4', '고급', 4, true),
('DIFFICULTY_LEVEL', '5', '전문가', 5, true)
ON CONFLICT (code_group, code_value) DO NOTHING;

-- =============================================
-- 2. 사용자 역할 및 권한
-- =============================================

INSERT INTO paperly.user_roles (name, display_name, description, permissions) VALUES
('admin', '시스템 관리자', '모든 권한을 가진 시스템 관리자', 
 '["user.manage", "content.manage", "category.manage", "tag.manage", "writer.manage", "system.config", "security.view", "analytics.view"]'),
('editor', '에디터', '콘텐츠 편집 및 관리 권한', 
 '["content.edit", "content.review", "category.view", "tag.view", "writer.view", "analytics.content"]'),
('writer', '작가', '글 작성 및 자신의 콘텐츠 관리 권한', 
 '["content.create", "content.edit_own", "tag.view", "analytics.own"]'),
('user', '일반 사용자', '기본 사용자 권한', 
 '["content.read", "content.bookmark", "content.like", "content.share", "profile.edit_own"]'),
('moderator', '모더레이터', '콘텐츠 검토 및 사용자 관리 권한', 
 '["content.review", "user.moderate", "content.moderate", "security.moderate"]')
ON CONFLICT (name) DO NOTHING;

-- =============================================
-- 3. 카테고리 계층 구조
-- =============================================

-- 최상위 카테고리
INSERT INTO paperly.categories (id, name, slug, description, icon_name, color_code, is_featured, sort_order) VALUES
(uuid_generate_v4(), '기술', 'technology', 'IT, 프로그래밍, 소프트웨어 개발 관련 글', '💻', '#2563EB', true, 1),
(uuid_generate_v4(), '비즈니스', 'business', '경영, 창업, 마케팅, 투자 관련 글', '💼', '#059669', true, 2),
(uuid_generate_v4(), '라이프스타일', 'lifestyle', '건강, 여행, 취미, 일상 관련 글', '🌟', '#DC2626', true, 3),
(uuid_generate_v4(), '학습', 'learning', '교육, 스킬 개발, 자기계발 관련 글', '📚', '#7C3AED', true, 4),
(uuid_generate_v4(), '창작', 'creative', '예술, 디자인, 창작 활동 관련 글', '🎨', '#EA580C', true, 5),
(uuid_generate_v4(), '과학', 'science', '과학, 연구, 혁신 관련 글', '🔬', '#0891B2', true, 6)
ON CONFLICT (slug) DO NOTHING;

-- 하위 카테고리 (기술)
WITH tech_parent AS (SELECT id FROM paperly.categories WHERE slug = 'technology' LIMIT 1)
INSERT INTO paperly.categories (id, name, slug, description, parent_id, icon_name, color_code, sort_order) 
SELECT 
    uuid_generate_v4(), 
    sub.name, 
    sub.slug, 
    sub.description, 
    tech_parent.id, 
    sub.icon_name, 
    sub.color_code, 
    sub.sort_order
FROM tech_parent, (VALUES
    ('프로그래밍', 'programming', 'Python, JavaScript, Java 등 프로그래밍 언어', '⌨️', '#1E40AF', 1),
    ('웹 개발', 'web-development', 'Frontend, Backend, Full Stack 개발', '🌐', '#3B82F6', 2),
    ('모바일 개발', 'mobile-development', 'iOS, Android 앱 개발', '📱', '#6366F1', 3),
    ('AI/ML', 'ai-ml', '인공지능, 머신러닝, 딥러닝', '🤖', '#8B5CF6', 4),
    ('데이터 사이언스', 'data-science', '데이터 분석, 빅데이터, 통계', '📊', '#A855F7', 5),
    ('클라우드', 'cloud', 'AWS, Azure, GCP 클라우드 서비스', '☁️', '#EC4899', 6)
) AS sub(name, slug, description, icon_name, color_code, sort_order)
ON CONFLICT (slug) DO NOTHING;

-- 하위 카테고리 (비즈니스)
WITH business_parent AS (SELECT id FROM paperly.categories WHERE slug = 'business' LIMIT 1)
INSERT INTO paperly.categories (id, name, slug, description, parent_id, icon_name, color_code, sort_order) 
SELECT 
    uuid_generate_v4(), 
    sub.name, 
    sub.slug, 
    sub.description, 
    business_parent.id, 
    sub.icon_name, 
    sub.color_code, 
    sub.sort_order
FROM business_parent, (VALUES
    ('창업', 'startup', '스타트업, 창업 아이디어, 사업 계획', '🚀', '#10B981', 1),
    ('마케팅', 'marketing', '디지털 마케팅, 브랜딩, 광고', '📢', '#059669', 2),
    ('투자', 'investment', '주식, 부동산, 가상화폐 투자', '💰', '#047857', 3),
    ('경영', 'management', '조직 관리, 리더십, 전략', '👔', '#065F46', 4)
) AS sub(name, slug, description, icon_name, color_code, sort_order)
ON CONFLICT (slug) DO NOTHING;

-- =============================================
-- 4. 기본 태그 데이터
-- =============================================

INSERT INTO paperly.tags (name, slug, description, tag_type, color_code, is_verified) VALUES
-- 기술 관련 태그
('Python', 'python', 'Python 프로그래밍 언어', 'technical', '#3776AB', true),
('JavaScript', 'javascript', 'JavaScript 프로그래밍 언어', 'technical', '#F7DF1E', true),
('React', 'react', 'React 프론트엔드 라이브러리', 'technical', '#61DAFB', true),
('Node.js', 'nodejs', 'Node.js 백엔드 런타임', 'technical', '#339933', true),
('AI', 'ai', '인공지능 관련', 'technical', '#FF6B6B', true),
('머신러닝', 'machine-learning', '머신러닝 관련', 'technical', '#4ECDC4', true),
('데이터분석', 'data-analysis', '데이터 분석 관련', 'technical', '#45B7D1', true),

-- 비즈니스 관련 태그
('스타트업', 'startup', '스타트업 관련', 'general', '#95E1D3', true),
('마케팅', 'marketing', '마케팅 전략', 'general', '#F38BA8', true),
('투자', 'investment', '투자 관련', 'general', '#A8DADC', true),
('리더십', 'leadership', '리더십 개발', 'general', '#457B9D', true),

-- 일반 태그
('초보자', 'beginner', '초보자를 위한 내용', 'general', '#98D8C8', true),
('고급', 'advanced', '고급 사용자를 위한 내용', 'general', '#F7DC6F', true),
('튜토리얼', 'tutorial', '단계별 가이드', 'general', '#BB8FCE', true),
('팁', 'tips', '유용한 팁과 노하우', 'general', '#85C1E9', true),
('리뷰', 'review', '제품이나 서비스 리뷰', 'general', '#F8C471', true),
('트렌드', 'trend', '최신 트렌드', 'trending', '#82E0AA', true)
ON CONFLICT (name) DO NOTHING;

-- =============================================
-- 5. 테스트 사용자 데이터
-- =============================================

-- 관리자 사용자
INSERT INTO paperly.users (id, email, password_hash, name, nickname, status, email_verified, onboarding_completed) VALUES
(uuid_generate_v4(), 'admin@paperly.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LeGgJp7IfYA8pVIeG', '시스템 관리자', 'admin', 'active', true, true),
(uuid_generate_v4(), 'editor@paperly.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LeGgJp7IfYA8pVIeG', '에디터', 'editor', 'active', true, true)
ON CONFLICT (email) DO NOTHING;

-- 테스트 작가들
INSERT INTO paperly.users (id, email, password_hash, name, nickname, status, email_verified, onboarding_completed) VALUES
(uuid_generate_v4(), 'writer1@paperly.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LeGgJp7IfYA8pVIeG', '김개발', 'dev_kim', 'active', true, true),
(uuid_generate_v4(), 'writer2@paperly.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LeGgJp7IfYA8pVIeG', '박데이터', 'data_park', 'active', true, true),
(uuid_generate_v4(), 'writer3@paperly.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LeGgJp7IfYA8pVIeG', '이비즈', 'biz_lee', 'active', true, true)
ON CONFLICT (email) DO NOTHING;

-- 일반 테스트 사용자들
INSERT INTO paperly.users (id, email, password_hash, name, nickname, status, email_verified, onboarding_completed) VALUES
(uuid_generate_v4(), 'user1@paperly.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LeGgJp7IfYA8pVIeG', '홍길동', 'hong_gd', 'active', true, false),
(uuid_generate_v4(), 'user2@paperly.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LeGgJp7IfYA8pVIeG', '김철수', 'kim_cs', 'active', true, false),
(uuid_generate_v4(), 'user3@paperly.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LeGgJp7IfYA8pVIeG', '이영희', 'lee_yh', 'active', true, true)
ON CONFLICT (email) DO NOTHING;

-- =============================================
-- 6. 사용자 역할 할당
-- =============================================

-- 관리자 역할 할당
WITH admin_user AS (SELECT id FROM paperly.users WHERE email = 'admin@paperly.com' LIMIT 1),
     admin_role AS (SELECT id FROM paperly.user_roles WHERE name = 'admin' LIMIT 1)
INSERT INTO paperly.user_role_assignments (user_id, role_id)
SELECT admin_user.id, admin_role.id
FROM admin_user, admin_role
ON CONFLICT (user_id, role_id) DO NOTHING;

-- 에디터 역할 할당
WITH editor_user AS (SELECT id FROM paperly.users WHERE email = 'editor@paperly.com' LIMIT 1),
     editor_role AS (SELECT id FROM paperly.user_roles WHERE name = 'editor' LIMIT 1)
INSERT INTO paperly.user_role_assignments (user_id, role_id)
SELECT editor_user.id, editor_role.id
FROM editor_user, editor_role
ON CONFLICT (user_id, role_id) DO NOTHING;

-- 작가 역할 할당
WITH writer_role AS (SELECT id FROM paperly.user_roles WHERE name = 'writer' LIMIT 1)
INSERT INTO paperly.user_role_assignments (user_id, role_id)
SELECT u.id, writer_role.id
FROM paperly.users u, writer_role
WHERE u.email IN ('writer1@paperly.com', 'writer2@paperly.com', 'writer3@paperly.com')
ON CONFLICT (user_id, role_id) DO NOTHING;

-- =============================================
-- 7. 작가 프로필 생성
-- =============================================

-- 작가 프로필 데이터
WITH writer_users AS (
    SELECT id, email, name FROM paperly.users 
    WHERE email IN ('writer1@paperly.com', 'writer2@paperly.com', 'writer3@paperly.com')
)
INSERT INTO paperly.writer_profiles (
    user_id, pen_name, bio, expertise_areas, writing_style, 
    is_verified, writer_level, application_status
)
SELECT 
    u.id,
    CASE 
        WHEN u.email = 'writer1@paperly.com' THEN '개발자 김'
        WHEN u.email = 'writer2@paperly.com' THEN '데이터 박사'
        WHEN u.email = 'writer3@paperly.com' THEN '비즈니스 리'
    END,
    CASE 
        WHEN u.email = 'writer1@paperly.com' THEN '10년차 풀스택 개발자로, 복잡한 기술을 쉽게 설명하는 것을 좋아합니다.'
        WHEN u.email = 'writer2@paperly.com' THEN '데이터 사이언티스트로, AI와 머신러닝을 실무에 적용하는 방법을 공유합니다.'
        WHEN u.email = 'writer3@paperly.com' THEN '스타트업 창업가이자 비즈니스 컨설턴트로, 실전 경험을 바탕으로 글을 씁니다.'
    END,
    CASE 
        WHEN u.email = 'writer1@paperly.com' THEN ARRAY['웹개발', '모바일개발', '백엔드']
        WHEN u.email = 'writer2@paperly.com' THEN ARRAY['데이터분석', 'AI/ML', '통계']
        WHEN u.email = 'writer3@paperly.com' THEN ARRAY['창업', '마케팅', '경영전략']
    END,
    'casual',
    true,
    'established',
    'approved'
FROM writer_users u
ON CONFLICT (user_id) DO NOTHING;

-- =============================================
-- 8. 테스트 글 데이터
-- =============================================

-- 테스트 글들
WITH categories AS (
    SELECT id, slug FROM paperly.categories WHERE parent_id IS NULL
),
writers AS (
    SELECT u.id, u.name, wp.pen_name 
    FROM paperly.users u 
    JOIN paperly.writer_profiles wp ON u.id = wp.user_id
)
INSERT INTO paperly.articles (
    id, title, slug, summary, content, author_id, author_name, category_id,
    word_count, estimated_reading_time, difficulty_level, status, is_featured, published_at
)
SELECT 
    uuid_generate_v4(),
    articles_data.title,
    articles_data.slug,
    articles_data.summary,
    articles_data.content,
    w.id,
    w.pen_name,
    c.id,
    articles_data.word_count,
    articles_data.reading_time,
    articles_data.difficulty,
    'published',
    articles_data.is_featured,
    CURRENT_TIMESTAMP - (articles_data.days_ago || ' days')::INTERVAL
FROM (VALUES
    ('Python으로 시작하는 웹 크롤링', 'python-web-crawling-guide', 
     'BeautifulSoup과 Requests를 활용해 웹 크롤링의 기초부터 고급 기법까지 알아봅시다.',
     E'# Python 웹 크롤링 완전 가이드\n\n웹 크롤링은 웹사이트에서 데이터를 자동으로 수집하는 기술입니다.\n\n## 1. 기본 설정\n\n```python\nimport requests\nfrom bs4 import BeautifulSoup\n\nurl = "https://example.com"\nresponse = requests.get(url)\nsoup = BeautifulSoup(response.content, "html.parser")\n```\n\n## 2. 데이터 추출\n\n```python\ntitles = soup.find_all("h2", class_="title")\nfor title in titles:\n    print(title.text.strip())\n```\n\n이제 실제 프로젝트에 적용해보세요!',
     1200, 8, 2, true, 1, 'technology'),
     
    ('스타트업 창업 전 꼭 알아야 할 10가지', 'startup-essential-checklist',
     '창업을 준비하고 계신가요? 실패하지 않기 위한 핵심 체크포인트를 공유합니다.',
     E'# 스타트업 창업 필수 체크리스트\n\n창업은 인생을 바꿀 수 있는 도전입니다.\n\n## 1. 시장 조사는 필수\n\n- 타겟 고객 분석\n- 경쟁사 현황 파악\n- 시장 규모 추정\n\n## 2. 최소 실행 가능 제품(MVP)\n\n```\n기능 우선순위:\n1. 핵심 기능만 개발\n2. 사용자 피드백 수집\n3. 빠른 개선 사이클\n```\n\n## 3. 자금 조달 계획\n\n- 초기 자본금 계산\n- 투자 유치 전략\n- 캐시플로우 관리',
     1500, 10, 3, true, 2, 'business'),
     
    ('React Hook의 모든 것', 'complete-guide-to-react-hooks',
     'useState부터 커스텀 훅까지, React Hook을 마스터하기 위한 완전 가이드입니다.',
     E'# React Hook 완전 정복\n\nReact Hook은 함수형 컴포넌트에서 상태와 생명주기를 다루는 방법입니다.\n\n## useState Hook\n\n```jsx\nimport React, { useState } from "react";\n\nfunction Counter() {\n  const [count, setCount] = useState(0);\n  \n  return (\n    <div>\n      <p>Count: {count}</p>\n      <button onClick={() => setCount(count + 1)}>\n        증가\n      </button>\n    </div>\n  );\n}\n```\n\n## useEffect Hook\n\n```jsx\nuseEffect(() => {\n  console.log("컴포넌트가 렌더링됨");\n  \n  return () => {\n    console.log("컴포넌트가 언마운트됨");\n  };\n}, []);\n```',
     2000, 12, 3, false, 3, 'technology'),
     
    ('데이터 분석으로 비즈니스 인사이트 찾기', 'business-insights-with-data-analysis',
     '실무에서 바로 사용할 수 있는 데이터 분석 기법과 비즈니스 적용 사례를 소개합니다.',
     E'# 데이터로 읽는 비즈니스 트렌드\n\n데이터 분석은 현대 비즈니스의 핵심입니다.\n\n## 1. 고객 세그먼테이션\n\n```python\nimport pandas as pd\nfrom sklearn.cluster import KMeans\n\n# 고객 데이터 로드\ndf = pd.read_csv("customer_data.csv")\n\n# K-means 클러스터링\nkmeans = KMeans(n_clusters=4)\nclusters = kmeans.fit_predict(df)\n```\n\n## 2. 매출 예측 모델\n\n- 시계열 분석\n- 회귀 분석\n- 머신러닝 예측\n\n## 3. A/B 테스트 설계\n\n통계적 유의성을 확보하는 방법을 알아봅시다.',
     1800, 11, 4, false, 5, 'technology'),
     
    ('마케팅 자동화로 효율성 극대화하기', 'marketing-automation-guide',
     '반복적인 마케팅 업무를 자동화하여 더 전략적인 일에 집중하는 방법을 알아봅시다.',
     E'# 마케팅 자동화 실전 가이드\n\n마케팅 자동화는 단순 반복 업무를 줄이고 성과를 높이는 핵심 전략입니다.\n\n## 1. 이메일 마케팅 자동화\n\n### 웰컴 시퀀스\n- 1일차: 환영 메시지\n- 3일차: 제품 소개\n- 7일차: 사용 팁 공유\n\n### 세그먼트별 타겟팅\n```\n신규 고객: 온보딩 중심\n기존 고객: 업셀링 중심\n비활성 고객: 재참여 유도\n```\n\n## 2. 소셜미디어 자동화\n\n- 콘텐츠 스케줄링\n- 자동 응답 시스템\n- 성과 분석 대시보드',
     1300, 9, 2, false, 7, 'business')
) AS articles_data(title, slug, summary, content, word_count, reading_time, difficulty, is_featured, days_ago, category_slug)
JOIN categories c ON c.slug = articles_data.category_slug
JOIN writers w ON (
    (articles_data.category_slug = 'technology' AND w.pen_name IN ('개발자 김', '데이터 박사')) OR
    (articles_data.category_slug = 'business' AND w.pen_name = '비즈니스 리')
)
ON CONFLICT (slug) DO NOTHING;

-- =============================================
-- 9. 글-태그 연결
-- =============================================

-- 각 글에 관련 태그 할당
WITH article_tag_mapping AS (
    SELECT a.id as article_id, t.id as tag_id
    FROM paperly.articles a
    JOIN paperly.tags t ON (
        (a.slug LIKE '%python%' AND t.name IN ('Python', '초보자', '튜토리얼')) OR
        (a.slug LIKE '%startup%' AND t.name IN ('스타트업', '마케팅', '팁')) OR
        (a.slug LIKE '%react%' AND t.name IN ('JavaScript', 'React', '고급')) OR
        (a.slug LIKE '%data-analysis%' AND t.name IN ('데이터분석', 'AI', '고급')) OR
        (a.slug LIKE '%marketing%' AND t.name IN ('마케팅', '비즈니스', '튜토리얼'))
    )
)
INSERT INTO paperly.article_tags (article_id, tag_id, relevance_score, is_primary)
SELECT 
    article_id, 
    tag_id, 
    0.8 + (RANDOM() * 0.2), -- 0.8-1.0 사이의 관련성 점수
    ROW_NUMBER() OVER (PARTITION BY article_id ORDER BY RANDOM()) = 1 -- 첫 번째 태그를 주요 태그로
FROM article_tag_mapping
ON CONFLICT (article_id, tag_id) DO NOTHING;

-- =============================================
-- 10. 추천 모델 기본 설정
-- =============================================

INSERT INTO paperly.recommendation_models (
    model_name, model_type, model_version, 
    accuracy_score, precision_score, recall_score, f1_score,
    hyperparameters, is_active, is_production
) VALUES
('collaborative_filtering_v1', 'collaborative_filtering', '1.0.0',
 0.8500, 0.8200, 0.8700, 0.8400,
 '{"n_factors": 50, "n_epochs": 20, "lr_all": 0.005}', true, true),
('content_based_v1', 'content_based', '1.0.0',
 0.7800, 0.8000, 0.7600, 0.7800,
 '{"tfidf_max_features": 5000, "similarity_threshold": 0.3}', true, false),
('hybrid_v1', 'hybrid', '1.0.0',
 0.8900, 0.8700, 0.9100, 0.8900,
 '{"cf_weight": 0.6, "cb_weight": 0.4, "min_interactions": 5}', true, true)
ON CONFLICT (model_name) DO NOTHING;

-- =============================================
-- 완료 메시지
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '================================='
    RAISE NOTICE 'Paperly 기초 데이터 적재 완료';
    RAISE NOTICE '================================='
    RAISE NOTICE '생성된 데이터:';
    RAISE NOTICE '- 시스템 설정: 10개';
    RAISE NOTICE '- 공통코드: 20개';
    RAISE NOTICE '- 사용자 역할: 5개';
    RAISE NOTICE '- 카테고리: 10개 (계층 구조)';
    RAISE NOTICE '- 태그: 16개';
    RAISE NOTICE '- 테스트 사용자: 6명';
    RAISE NOTICE '- 작가 프로필: 3명';
    RAISE NOTICE '- 테스트 글: 5개';
    RAISE NOTICE '- 추천 모델: 3개';
    RAISE NOTICE '================================='
    RAISE NOTICE '테스트 계정 정보:';
    RAISE NOTICE '- admin@paperly.com (관리자)';
    RAISE NOTICE '- editor@paperly.com (에디터)';
    RAISE NOTICE '- writer1@paperly.com (작가)';
    RAISE NOTICE '- user1@paperly.com (일반사용자)';
    RAISE NOTICE '비밀번호: password123 (모든 계정 공통)';
    RAISE NOTICE '================================='
END $$;