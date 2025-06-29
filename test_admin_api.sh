#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

API_URL="http://localhost:3000/api/v1"

echo -e "${YELLOW}=== Paperly 관리자 기능 API 테스트 ===${NC}\n"

# 1. 로그인해서 토큰 받기
echo -e "${GREEN}1. 관리자 로그인 테스트${NC}"
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }')

TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.access_token // .accessToken // empty')

if [ -z "$TOKEN" ]; then
  echo -e "${RED}로그인 실패! 응답:${NC}"
  echo $LOGIN_RESPONSE | jq '.'
  echo -e "\n${YELLOW}테스트 계정을 생성해보겠습니다...${NC}"
  
  # 회원가입
  SIGNUP_RESPONSE=$(curl -s -X POST "$API_URL/auth/signup" \
    -H "Content-Type: application/json" \
    -d '{
      "email": "admin@paperly.com",
      "password": "admin123!",
      "name": "관리자"
    }')
  
  echo $SIGNUP_RESPONSE | jq '.'
  
  # 다시 로그인
  LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{
      "email": "admin@paperly.com",
      "password": "admin123!"
    }')
  
  TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.access_token // .accessToken // empty')
fi

if [ ! -z "$TOKEN" ]; then
  echo -e "${GREEN}✓ 로그인 성공!${NC}"
  echo "토큰: ${TOKEN:0:50}..."
else
  echo -e "${RED}✗ 로그인 실패${NC}"
  exit 1
fi

# 2. 기사 작성 (작가 권한 필요)
echo -e "\n${GREEN}2. 새 기사 작성${NC}"
CREATE_RESPONSE=$(curl -s -X POST "$API_URL/articles" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "AI 시대의 글쓰기: 인간과 기계의 협업",
    "subtitle": "ChatGPT와 함께하는 창의적 글쓰기의 미래",
    "content": "인공지능이 글쓰기 영역에 진출하면서 많은 변화가 일어나고 있습니다. 이제 우리는 AI를 활용해 더 나은 글을 쓸 수 있게 되었습니다.",
    "excerpt": "AI와 인간이 함께 만들어가는 새로운 글쓰기 패러다임",
    "categoryId": null,
    "status": "draft",
    "visibility": "public",
    "metadata": {
      "keywords": ["AI", "글쓰기", "ChatGPT", "창의성"]
    }
  }')

ARTICLE_ID=$(echo $CREATE_RESPONSE | jq -r '.article.id // empty')

if [ ! -z "$ARTICLE_ID" ]; then
  echo -e "${GREEN}✓ 기사 작성 성공!${NC}"
  echo "기사 ID: $ARTICLE_ID"
  echo $CREATE_RESPONSE | jq '.article | {id, title, status, authorId}'
else
  echo -e "${RED}✗ 기사 작성 실패${NC}"
  echo $CREATE_RESPONSE | jq '.'
fi

# 3. 기사 목록 조회
echo -e "\n${GREEN}3. 기사 목록 조회${NC}"
LIST_RESPONSE=$(curl -s -X GET "$API_URL/articles?limit=5" \
  -H "Authorization: Bearer $TOKEN")

echo $LIST_RESPONSE | jq '.articles[] | {id, title, status, publishedAt}' 2>/dev/null || echo $LIST_RESPONSE | jq '.'

# 4. 기사 상태 변경 (발행)
if [ ! -z "$ARTICLE_ID" ]; then
  echo -e "\n${GREEN}4. 기사 발행 (에디터/관리자 권한 필요)${NC}"
  PUBLISH_RESPONSE=$(curl -s -X PATCH "$API_URL/articles/$ARTICLE_ID/publish" \
    -H "Authorization: Bearer $TOKEN")
  
  if echo $PUBLISH_RESPONSE | jq -e '.article' > /dev/null 2>&1; then
    echo -e "${GREEN}✓ 기사 발행 성공!${NC}"
    echo $PUBLISH_RESPONSE | jq '.article | {id, title, status, publishedAt}'
  else
    echo -e "${YELLOW}! 발행 권한이 없을 수 있습니다${NC}"
    echo $PUBLISH_RESPONSE | jq '.'
  fi
fi

# 5. 발행된 기사 목록
echo -e "\n${GREEN}5. 발행된 기사 목록${NC}"
PUBLISHED_RESPONSE=$(curl -s -X GET "$API_URL/articles/published?limit=5")
echo $PUBLISHED_RESPONSE | jq '.articles[] | {id, title, viewCount, publishedAt}' 2>/dev/null || echo $PUBLISHED_RESPONSE | jq '.'

# 6. 추천 기사 조회
echo -e "\n${GREEN}6. 추천 기사 목록${NC}"
FEATURED_RESPONSE=$(curl -s -X GET "$API_URL/articles/featured")
echo $FEATURED_RESPONSE | jq '.articles[] | {id, title, featuredAt}' 2>/dev/null || echo "추천 기사 없음"

# 7. 카테고리 목록
echo -e "\n${GREEN}7. 카테고리 목록 조회${NC}"
CATEGORIES_RESPONSE=$(curl -s -X GET "$API_URL/categories")
echo $CATEGORIES_RESPONSE | jq '.[] | {id, name, slug, colorCode}' 2>/dev/null || echo $CATEGORIES_RESPONSE | jq '.'

# 8. API 문서 확인
echo -e "\n${GREEN}8. Swagger API 문서${NC}"
echo -e "API 문서를 확인하려면 브라우저에서 다음 주소를 열어보세요:"
echo -e "${YELLOW}http://localhost:3000/api-docs${NC}"

# 9. 현재 사용자 정보
echo -e "\n${GREEN}9. 현재 사용자 정보${NC}"
ME_RESPONSE=$(curl -s -X GET "$API_URL/auth/me" \
  -H "Authorization: Bearer $TOKEN")
echo $ME_RESPONSE | jq '.' 2>/dev/null || echo "사용자 정보 조회 실패"

echo -e "\n${YELLOW}=== 테스트 완료 ===${NC}"