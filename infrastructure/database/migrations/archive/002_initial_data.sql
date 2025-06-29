-- =====================================================
-- Paperly Initial Data
-- Version: 1.0.0
-- Description: 초기 카테고리, 태그, 샘플 데이터 삽입
-- =====================================================

-- =====================================================
-- 1. 카테고리 데이터
-- =====================================================

-- 메인 카테고리
INSERT INTO categories (name, slug, emoji, color_hex, description, example_topics, display_order, is_featured) VALUES
('기술 & 개발', 'tech', '💻', '#4ECDC4', '최신 기술 트렌드와 개발 이야기', 
 ARRAY['AI/ML', '웹개발', '모바일', '클라우드', '블록체인'], 1, true),

('비즈니스', 'business', '📈', '#FF6B6B', '성공적인 커리어와 창업 인사이트',
 ARRAY['스타트업', '마케팅', '리더십', '투자', '경제'], 2, true),

('예술 & 디자인', 'art', '🎨', '#FFE66D', '창의성과 미적 감각을 키우는 콘텐츠',
 ARRAY['UI/UX', '일러스트', '사진', '건축', '패션'], 3, true),

('과학', 'science', '🔬', '#95E1D3', '과학적 사고와 최신 연구 동향',
 ARRAY['물리학', '생물학', '천문학', '환경', '의학'], 4, true),

('인문학', 'humanities', '📚', '#C7CEEA', '인간과 사회를 이해하는 깊이 있는 통찰',
 ARRAY['철학', '역사', '문학', '심리학', '사회학'], 5, true),

('라이프스타일', 'lifestyle', '🌿', '#FFDAB9', '더 나은 삶을 위한 실용적인 팁',
 ARRAY['건강', '요리', '여행', '취미', '자기계발'], 6, true),

('교육', 'education', '🎓', '#B4A7D6', '효과적인 학습과 성장을 위한 가이드',
 ARRAY['학습법', '언어', '시험준비', '온라인강의', '독서'], 7, false),

('엔터테인먼트', 'entertainment', '🎬', '#FFB6C1', '문화와 여가를 즐기는 다양한 콘텐츠',
 ARRAY['영화', '음악', '게임', '웹툰', '공연'], 8, false);

-- 서브 카테고리 예시 (기술 카테고리 하위)
INSERT INTO categories (name, slug, emoji, color_hex, description, parent_id, display_order) 
SELECT 
    '인공지능', 'ai', '🤖', '#4ECDC4', 'AI와 머신러닝의 최신 동향',
    id, 1
FROM categories WHERE slug = 'tech';

INSERT INTO categories (name, slug, emoji, color_hex, description, parent_id, display_order) 
SELECT 
    '웹 개발', 'web-dev', '🌐', '#4ECDC4', '프론트엔드와 백엔드 개발 이야기',
    id, 2
FROM categories WHERE slug = 'tech';

-- =====================================================
-- 2. 태그 데이터
-- =====================================================

INSERT INTO tags (name, slug) VALUES
-- 기술 관련
('JavaScript', 'javascript'),
('Python', 'python'),
('React', 'react'),
('Node.js', 'nodejs'),
('AI', 'ai'),
('머신러닝', 'machine-learning'),
('데이터사이언스', 'data-science'),
('클라우드', 'cloud'),

-- 비즈니스 관련
('스타트업', 'startup'),
('마케팅', 'marketing'),
('리더십', 'leadership'),
('생산성', 'productivity'),
('원격근무', 'remote-work'),

-- 일반
('초보자', 'beginner'),
('튜토리얼', 'tutorial'),
('입문', 'introduction'),
('고급', 'advanced'),
('트렌드', 'trends'),
('팁', 'tips');

-- =====================================================
-- 3. 샘플 사용자 데이터 (테스트용)
-- =====================================================

-- 비밀번호는 모두 'password123' (bcrypt 해시)
INSERT INTO users (email, password_hash, username, full_name, email_verified) VALUES
('admin@paperly.com', '$2b$10$YourHashHere', 'admin', '관리자', true),
('test1@example.com', '$2b$10$YourHashHere', 'techie', '김개발', true),
('test2@example.com', '$2b$10$YourHashHere', 'designer', '이디자인', true),
('test3@example.com', '$2b$10$YourHashHere', 'reader', '박독서', true);

-- 사용자 관심사 설정
INSERT INTO user_interests (user_id, category_id, interest_level, source)
SELECT 
    u.id,
    c.id,
    CASE 
        WHEN u.username = 'techie' AND c.slug = 'tech' THEN 9
        WHEN u.username = 'designer' AND c.slug = 'art' THEN 9
        WHEN u.username = 'reader' AND c.slug = 'humanities' THEN 8
        ELSE 5
    END,
    'onboarding'
FROM users u
CROSS JOIN categories c
WHERE c.parent_id IS NULL
AND (
    (u.username = 'techie' AND c.slug IN ('tech', 'science', 'education')) OR
    (u.username = 'designer' AND c.slug IN ('art', 'tech', 'lifestyle')) OR
    (u.username = 'reader' AND c.slug IN ('humanities', 'science', 'education'))
);

-- =====================================================
-- 4. 샘플 기사 데이터
-- =====================================================

-- 기술 카테고리 기사
INSERT INTO articles (
    title, 
    slug, 
    summary_short, 
    summary_medium,
    summary_bullet_points,
    category_id,
    content_path,
    source_type,
    author_id,
    reading_time_minutes,
    difficulty_level,
    target_audience,
    status,
    published_at
) VALUES 
(
    '2024년 주목해야 할 AI 트렌드 5가지',
    '2024-ai-trends-5',
    '올해 가장 뜨거운 AI 기술 트렌드를 알아보자',
    '생성형 AI의 발전, 멀티모달 AI의 부상, 엣지 AI의 확산 등 2024년 AI 업계를 뒤흔들 5가지 핵심 트렌드를 심층 분석합니다. 개발자와 비즈니스 리더가 꼭 알아야 할 인사이트를 제공합니다.',
    '{"핵심 포인트": ["생성형 AI의 산업 적용 확대", "멀티모달 AI 기술의 성숙", "엣지 컴퓨팅과 AI의 결합"]}',
    (SELECT id FROM categories WHERE slug = 'tech'),
    'articles/2024/01/sample-ai-trends.json',
    'ai',
    (SELECT id FROM users WHERE username = 'admin'),
    8,
    3,
    'intermediate',
    'published',
    NOW() - INTERVAL '2 days'
),
(
    'React 19 새로운 기능 완벽 가이드',
    'react-19-new-features-guide',
    'React 19의 혁신적인 새 기능들을 만나보세요',
    'React 19에서 도입된 서버 컴포넌트, 자동 배치 업데이트, 새로운 훅 등 주요 기능을 실제 예제와 함께 상세히 알아봅니다. 기존 프로젝트 마이그레이션 가이드도 포함되어 있습니다.',
    '{"주요 기능": ["React Server Components", "자동 배치 업데이트", "use() 훅", "개선된 Suspense"]}',
    (SELECT id FROM categories WHERE slug = 'web-dev'),
    'articles/2024/01/react-19-guide.json',
    'original',
    (SELECT id FROM users WHERE username = 'techie'),
    12,
    4,
    'intermediate',
    'published',
    NOW() - INTERVAL '1 day'
);

-- 비즈니스 카테고리 기사
INSERT INTO articles (
    title, 
    slug, 
    summary_short, 
    summary_medium,
    summary_bullet_points,
    category_id,
    content_path,
    source_type,
    reading_time_minutes,
    difficulty_level,
    target_audience,
    status,
    published_at
) VALUES 
(
    '스타트업 성장을 위한 데이터 드리븐 마케팅',
    'startup-data-driven-marketing',
    '데이터로 만드는 효과적인 마케팅 전략',
    '한정된 리소스로 최대의 효과를 내야 하는 스타트업을 위한 데이터 기반 마케팅 전략을 소개합니다. A/B 테스트, 코호트 분석, 퍼널 최적화 등 실무에 바로 적용 가능한 방법론을 다룹니다.',
    '{"핵심 전략": ["A/B 테스트 설계", "코호트 분석 활용", "CAC/LTV 최적화"]}',
    (SELECT id FROM categories WHERE slug = 'business'),
    'articles/2024/01/data-driven-marketing.json',
    'original',
    10,
    3,
    'intermediate',
    'published',
    NOW() - INTERVAL '3 days'
);

-- 기사 통계 초기화
INSERT INTO article_stats (article_id, view_count, like_count, avg_rating, completion_rate)
SELECT 
    id,
    FLOOR(RANDOM() * 1000 + 100),          -- 100-1100 조회수
    FLOOR(RANDOM() * 100 + 10),            -- 10-110 좋아요
    3.5 + RANDOM() * 1.5,                  -- 3.5-5.0 평점
    0.6 + RANDOM() * 0.3                   -- 0.6-0.9 완독률
FROM articles
WHERE status = 'published';

-- 기사-태그 연결
INSERT INTO article_tags (article_id, tag_id)
SELECT 
    a.id,
    t.id
FROM articles a
CROSS JOIN tags t
WHERE 
    (a.slug = '2024-ai-trends-5' AND t.slug IN ('ai', 'machine-learning', 'trends')) OR
    (a.slug = 'react-19-new-features-guide' AND t.slug IN ('javascript', 'react', 'tutorial')) OR
    (a.slug = 'startup-data-driven-marketing' AND t.slug IN ('startup', 'marketing', 'data-science'));

-- =====================================================
-- 5. 샘플 읽기 기록 (테스트용)
-- =====================================================

-- 읽기 세션 샘플
INSERT INTO reading_sessions (
    user_id,
    article_id,
    started_at,
    ended_at,
    total_duration_seconds,
    active_duration_seconds,
    max_scroll_percentage,
    completion_percentage,
    device_type
)
SELECT 
    u.id,
    a.id,
    NOW() - INTERVAL '1 day' - (RANDOM() * INTERVAL '7 days'),
    NOW() - INTERVAL '1 day' - (RANDOM() * INTERVAL '7 days') + (INTERVAL '1 minute' * (5 + RANDOM() * 10)),
    300 + FLOOR(RANDOM() * 600),           -- 5-15분
    250 + FLOOR(RANDOM() * 500),           -- 활동 시간
    60 + RANDOM() * 40,                    -- 60-100% 스크롤
    CASE 
        WHEN RANDOM() > 0.7 THEN 100       -- 30% 확률로 완독
        ELSE 40 + RANDOM() * 50            -- 아니면 40-90%
    END,
    CASE 
        WHEN RANDOM() < 0.6 THEN 'mobile'
        WHEN RANDOM() < 0.9 THEN 'desktop'
        ELSE 'tablet'
    END
FROM users u
CROSS JOIN articles a
WHERE u.username != 'admin'
AND a.status = 'published'
AND RANDOM() < 0.5;                        -- 50% 확률로 읽기 기록 생성

-- =====================================================
-- 6. 연령대별 선호도 샘플 데이터 (추천용)
-- =====================================================

INSERT INTO demographic_preferences (demographic_key, category_id, preference_score, sample_size)
SELECT 
    age_key,
    c.id,
    CASE 
        WHEN age_key = 'age:20-24' AND c.slug IN ('tech', 'entertainment') THEN 0.8 + RANDOM() * 0.2
        WHEN age_key = 'age:25-29' AND c.slug IN ('tech', 'business') THEN 0.7 + RANDOM() * 0.3
        WHEN age_key = 'age:30-34' AND c.slug IN ('business', 'lifestyle') THEN 0.7 + RANDOM() * 0.3
        ELSE 0.3 + RANDOM() * 0.4
    END,
    100 + FLOOR(RANDOM() * 900)            -- 100-1000 샘플 크기
FROM 
    (VALUES ('age:20-24'), ('age:25-29'), ('age:30-34'), ('age:35-39')) AS ages(age_key)
CROSS JOIN categories c
WHERE c.parent_id IS NULL;

-- =====================================================
-- 7. 오늘의 추천 샘플 (테스트 사용자용)
-- =====================================================

INSERT INTO daily_recommendations (
    user_id,
    article_id,
    recommendation_date,
    rank,
    score,
    recommendation_type,
    reason_display
)
SELECT 
    u.id,
    a.id,
    CURRENT_DATE,
    ROW_NUMBER() OVER (PARTITION BY u.id ORDER BY RANDOM()),
    0.7 + RANDOM() * 0.3,                  -- 0.7-1.0 점수
    CASE 
        WHEN ROW_NUMBER() OVER (PARTITION BY u.id ORDER BY RANDOM()) <= 2 
        THEN 'interest_based'
        ELSE 'trending_demographic'
    END,
    CASE 
        WHEN ROW_NUMBER() OVER (PARTITION BY u.id ORDER BY RANDOM()) <= 2 
        THEN '관심 분야 최신 글'
        ELSE '같은 연령대에서 인기'
    END
FROM users u
CROSS JOIN articles a
WHERE u.username != 'admin'
AND a.status = 'published'
AND NOT EXISTS (
    SELECT 1 FROM daily_recommendations dr 
    WHERE dr.user_id = u.id 
    AND dr.article_id = a.id 
    AND dr.recommendation_date = CURRENT_DATE
)
LIMIT 8;                                   -- 각 사용자당 2-3개씩

-- =====================================================
-- 완료 메시지
-- =====================================================
-- 초기 데이터 삽입 완료!
-- 테스트 계정:
-- - admin@paperly.com / password123 (관리자)
-- - test1@example.com / password123 (기술 관심사)
-- - test2@example.com / password123 (디자인 관심사)
-- - test3@example.com / password123 (인문학 관심사)
