-- 간단한 테스트 데이터 추가

SET search_path TO paperly, public;

-- 테스트 기사들 추가 (author_id는 기존 사용자 사용)
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
  '인공지능 기술의 발전으로 글쓰기 분야에 큰 변화가 일어나고 있습니다. ChatGPT, Claude와 같은 대화형 AI가 등장하면서 작가들은 새로운 창작 도구를 손에 넣게 되었습니다.',
  'published',
  'public',
  (SELECT id FROM paperly.users LIMIT 1),
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
  'ESG 경영이 단순한 트렌드를 넘어 기업 생존의 필수 요소가 되고 있습니다. 소비자들은 점점 더 기업의 사회적 책임을 중요하게 생각하고 있습니다.',
  'published',
  'public',
  (SELECT id FROM paperly.users LIMIT 1),
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
  '코로나19 이후 원격근무가 일반화되면서 팀 협업 방식에도 큰 변화가 필요하게 되었습니다.',
  'draft',
  'public',
  (SELECT id FROM paperly.users LIMIT 1),
  12,
  3,
  NOW() - INTERVAL '3 hours',
  NOW() - INTERVAL '1 hour',
  NULL
);

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