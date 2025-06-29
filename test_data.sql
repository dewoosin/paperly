-- 테스트 데이터 추가

SET search_path TO paperly, public;

-- 먼저 테스트 사용자 추가
INSERT INTO paperly.users (id, email, name, email_verified, created_at, updated_at) 
VALUES (
  gen_random_uuid(), 
  'admin@paperly.com', 
  '관리자', 
  true, 
  NOW(), 
  NOW()
) ON CONFLICT (email) DO NOTHING;

-- 사용자 ID 변수로 저장
DO $$
DECLARE
    admin_user_id UUID;
BEGIN
    SELECT id INTO admin_user_id FROM paperly.users WHERE email = 'admin@paperly.com';
    
    -- 관리자 역할 할당
    INSERT INTO paperly.user_role_assignments (user_id, role_id, assigned_at) 
    SELECT 
      admin_user_id,
      ur.id,
      NOW()
    FROM paperly.user_roles ur 
    WHERE ur.name = 'admin'
    ON CONFLICT (user_id, role_id) DO NOTHING;

-- 테스트 기사들 추가
INSERT INTO paperly.articles (
  id, title, slug, subtitle, excerpt, content, 
  status, visibility, author_id, view_count, like_count,
  created_at, updated_at, published_at
) VALUES 
(
  gen_random_uuid(),
  'AI 시대의 글쓰기 혁신',
  'ai-writing-innovation',
  '인공지능과 함께하는 새로운 창작의 시대',
  '인공지능 기술이 글쓰기 영역에 가져온 혁신적 변화를 살펴봅니다.',
  '인공지능 기술의 발전으로 글쓰기 분야에 큰 변화가 일어나고 있습니다. ChatGPT, Claude와 같은 대화형 AI가 등장하면서 작가들은 새로운 창작 도구를 손에 넣게 되었습니다. 

이러한 변화는 단순히 기술적 혁신을 넘어 창작 과정 자체를 변화시키고 있습니다. AI는 아이디어 발상부터 초고 작성, 편집까지 전 과정에서 작가를 도울 수 있습니다.

하지만 여전히 인간 고유의 창의성과 감성은 대체할 수 없는 영역입니다. AI와 인간이 협력하는 새로운 창작 패러다임이 만들어지고 있습니다.',
  'published',
  'public',
  'test-admin-1',
  127,
  23,
  NOW() - INTERVAL '2 days',
  NOW() - INTERVAL '2 days',
  NOW() - INTERVAL '2 days'
),
(
  gen_random_uuid(),
  '지속가능한 비즈니스 모델의 미래',
  'sustainable-business-future',
  'ESG 경영이 가져올 비즈니스 혁신',
  '환경과 사회적 가치를 중시하는 새로운 비즈니스 모델을 탐구합니다.',
  'ESG(Environmental, Social, Governance) 경영이 단순한 트렌드를 넘어 기업 생존의 필수 요소가 되고 있습니다. 

소비자들은 점점 더 기업의 사회적 책임을 중요하게 생각하고 있으며, 투자자들도 지속가능한 기업에 더 많은 관심을 보이고 있습니다.

성공적인 ESG 경영을 위해서는 단순한 마케팅 차원을 넘어 비즈니스 모델 전반의 변화가 필요합니다. 환경 친화적 제품 개발, 공정한 노동 환경 조성, 투명한 거버넌스 구축 등이 핵심입니다.',
  'published',
  'public',
  'test-admin-1',
  89,
  15,
  NOW() - INTERVAL '1 day',
  NOW() - INTERVAL '1 day',
  NOW() - INTERVAL '1 day'
),
(
  gen_random_uuid(),
  '원격근무 시대의 팀 협업 전략',
  'remote-work-collaboration',
  '디지털 환경에서 효과적인 팀워크 구축하기',
  '원격근무 환경에서 팀의 생산성과 협업을 극대화하는 방법을 알아봅니다.',
  '코로나19 이후 원격근무가 일반화되면서 팀 협업 방식에도 큰 변화가 필요하게 되었습니다.

물리적으로 떨어져 있는 팀원들과의 효과적인 소통을 위해서는 새로운 도구와 방법론이 필요합니다. Slack, Zoom, Notion과 같은 협업 도구의 활용법을 익히는 것은 기본이고, 비동기 커뮤니케이션의 중요성도 높아졌습니다.

또한 팀 문화와 신뢰 구축을 위한 새로운 접근법도 필요합니다. 정기적인 가상 미팅, 명확한 업무 프로세스, 성과 평가 방식의 변화 등이 그 예입니다.',
  'draft',
  'public',
  'test-admin-1',
  12,
  3,
  NOW() - INTERVAL '3 hours',
  NOW() - INTERVAL '1 hour',
  NULL
);

-- 카테고리에 기사 연결
UPDATE paperly.articles SET category_id = (
  SELECT id FROM paperly.categories WHERE slug = 'business' LIMIT 1
) WHERE slug IN ('sustainable-business-future', 'remote-work-collaboration');

UPDATE paperly.articles SET category_id = (
  SELECT id FROM paperly.categories WHERE name LIKE '%기술%' OR name LIKE '%tech%' LIMIT 1
) WHERE slug = 'ai-writing-innovation';

-- 추천 기사로 설정
UPDATE paperly.articles SET 
  is_featured = true,
  featured_at = NOW()
WHERE slug IN ('ai-writing-innovation', 'sustainable-business-future');

-- 인기 기사로 설정  
UPDATE paperly.articles SET 
  is_trending = true,
  trending_score = view_count * 0.7 + like_count * 1.5
WHERE view_count > 50;