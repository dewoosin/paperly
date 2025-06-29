#!/bin/bash

# 관리자 기사 관리 API 테스트 스크립트
# 사용법: ./test_admin_article_api.sh

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 설정
BASE_URL="http://localhost:3000/api/v1"  # 백엔드 서버 URL
ADMIN_EMAIL="admin@paperly.com"
ADMIN_PASSWORD="admin123"

# 전역 변수
ACCESS_TOKEN=""
ARTICLE_ID=""
CATEGORY_ID=""
TAG_ID=""

# 함수들
print_header() {
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# HTTP 요청 함수
make_request() {
    local method=$1
    local endpoint=$2
    local data=$3
    local description=$4
    
    echo -e "\n${YELLOW}Testing: $description${NC}"
    echo -e "Method: $method"
    echo -e "Endpoint: $endpoint"
    
    if [ ! -z "$data" ]; then
        echo -e "Data: $data"
    fi
    
    local response
    local status_code
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "\n%{http_code}" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $ACCESS_TOKEN" \
            "$BASE_URL$endpoint")
    elif [ "$method" = "DELETE" ]; then
        response=$(curl -s -w "\n%{http_code}" \
            -X DELETE \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $ACCESS_TOKEN" \
            "$BASE_URL$endpoint")
    else
        response=$(curl -s -w "\n%{http_code}" \
            -X "$method" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $ACCESS_TOKEN" \
            -d "$data" \
            "$BASE_URL$endpoint")
    fi
    
    status_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | head -n -1)
    
    echo -e "Status Code: $status_code"
    echo -e "Response: $response_body"
    
    if [ "$status_code" -ge 200 ] && [ "$status_code" -lt 300 ]; then
        print_success "$description"
        echo "$response_body"
    else
        print_error "$description (Status: $status_code)"
        echo "$response_body"
        return 1
    fi
}

# 1. 관리자 로그인
test_admin_login() {
    print_header "1. 관리자 로그인 테스트"
    
    local login_data='{
        "email": "'$ADMIN_EMAIL'",
        "password": "'$ADMIN_PASSWORD'"
    }'
    
    local response=$(make_request "POST" "/admin/auth/login" "$login_data" "관리자 로그인")
    
    if [ $? -eq 0 ]; then
        ACCESS_TOKEN=$(echo "$response" | jq -r '.data.accessToken // .accessToken // empty')
        if [ ! -z "$ACCESS_TOKEN" ] && [ "$ACCESS_TOKEN" != "null" ]; then
            print_success "Access token 획득: ${ACCESS_TOKEN:0:20}..."
        else
            print_error "Access token 추출 실패"
            exit 1
        fi
    else
        print_error "관리자 로그인 실패"
        exit 1
    fi
}

# 2. 카테고리 목록 조회
test_get_categories() {
    print_header "2. 카테고리 목록 조회"
    
    local response=$(make_request "GET" "/admin/articles/categories" "" "카테고리 목록 조회")
    
    if [ $? -eq 0 ]; then
        CATEGORY_ID=$(echo "$response" | jq -r '.data[0].id // empty')
        if [ ! -z "$CATEGORY_ID" ] && [ "$CATEGORY_ID" != "null" ]; then
            print_success "첫 번째 카테고리 ID: $CATEGORY_ID"
        else
            print_warning "카테고리가 없습니다. 임시 카테고리를 생성하겠습니다."
            # TODO: 카테고리 생성 API 호출
            CATEGORY_ID="temp-category-id"
        fi
    fi
}

# 3. 태그 목록 조회
test_get_tags() {
    print_header "3. 태그 목록 조회"
    
    local response=$(make_request "GET" "/admin/articles/tags" "" "태그 목록 조회")
    
    if [ $? -eq 0 ]; then
        TAG_ID=$(echo "$response" | jq -r '.data[0].id // empty')
        if [ ! -z "$TAG_ID" ] && [ "$TAG_ID" != "null" ]; then
            print_success "첫 번째 태그 ID: $TAG_ID"
        else
            print_warning "태그가 없습니다."
        fi
    fi
}

# 4. 기사 생성
test_create_article() {
    print_header "4. 기사 생성 테스트"
    
    local article_data='{
        "title": "테스트 기사 제목",
        "slug": "test-article-'$(date +%s)'",
        "summary": "이것은 테스트용 기사의 요약입니다. 최소 50자 이상 작성해야 합니다. 테스트를 위한 내용입니다.",
        "content": "<h1>테스트 기사</h1><p>이것은 테스트용 기사의 본문입니다. 다양한 HTML 태그를 포함하고 있습니다.</p><p>두 번째 문단입니다.</p>",
        "category_id": "'$CATEGORY_ID'",
        "status": "draft",
        "is_featured": false,
        "is_premium": false,
        "difficulty_level": 3,
        "content_type": "article",
        "seo_title": "테스트 기사 SEO 제목",
        "seo_description": "테스트 기사 SEO 설명",
        "seo_keywords": ["테스트", "기사", "API"],
        "tags": ["'$TAG_ID'"]
    }'
    
    local response=$(make_request "POST" "/admin/articles" "$article_data" "새 기사 생성")
    
    if [ $? -eq 0 ]; then
        ARTICLE_ID=$(echo "$response" | jq -r '.data.id // empty')
        if [ ! -z "$ARTICLE_ID" ] && [ "$ARTICLE_ID" != "null" ]; then
            print_success "생성된 기사 ID: $ARTICLE_ID"
        else
            print_error "기사 ID 추출 실패"
        fi
    fi
}

# 5. 기사 목록 조회
test_get_articles() {
    print_header "5. 기사 목록 조회 테스트"
    
    make_request "GET" "/admin/articles?page=1&limit=10" "" "기사 목록 조회 (페이지네이션)"
    make_request "GET" "/admin/articles?status=draft" "" "기사 목록 조회 (상태 필터)"
    make_request "GET" "/admin/articles?search=테스트" "" "기사 목록 조회 (검색)"
}

# 6. 기사 상세 조회
test_get_article() {
    print_header "6. 기사 상세 조회 테스트"
    
    if [ ! -z "$ARTICLE_ID" ]; then
        make_request "GET" "/admin/articles/$ARTICLE_ID" "" "기사 상세 조회"
    else
        print_error "기사 ID가 없습니다. 이전 테스트를 확인하세요."
    fi
}

# 7. 기사 수정
test_update_article() {
    print_header "7. 기사 수정 테스트"
    
    if [ ! -z "$ARTICLE_ID" ]; then
        local update_data='{
            "title": "수정된 테스트 기사 제목",
            "summary": "수정된 테스트용 기사의 요약입니다. 최소 50자 이상 작성해야 합니다. 수정 테스트를 위한 내용입니다.",
            "content": "<h1>수정된 테스트 기사</h1><p>이것은 수정된 테스트용 기사의 본문입니다.</p>",
            "is_featured": true,
            "difficulty_level": 4
        }'
        
        make_request "PUT" "/admin/articles/$ARTICLE_ID" "$update_data" "기사 수정"
    else
        print_error "기사 ID가 없습니다. 이전 테스트를 확인하세요."
    fi
}

# 8. 기사 발행
test_publish_article() {
    print_header "8. 기사 발행 테스트"
    
    if [ ! -z "$ARTICLE_ID" ]; then
        make_request "POST" "/admin/articles/$ARTICLE_ID/publish" "" "기사 발행"
    else
        print_error "기사 ID가 없습니다. 이전 테스트를 확인하세요."
    fi
}

# 9. 기사 발행 취소
test_unpublish_article() {
    print_header "9. 기사 발행 취소 테스트"
    
    if [ ! -z "$ARTICLE_ID" ]; then
        make_request "POST" "/admin/articles/$ARTICLE_ID/unpublish" "" "기사 발행 취소"
    else
        print_error "기사 ID가 없습니다. 이전 테스트를 확인하세요."
    fi
}

# 10. 기사 삭제 (소프트 삭제)
test_soft_delete_article() {
    print_header "10. 기사 소프트 삭제 테스트"
    
    if [ ! -z "$ARTICLE_ID" ]; then
        make_request "DELETE" "/admin/articles/$ARTICLE_ID" "" "기사 소프트 삭제"
    else
        print_error "기사 ID가 없습니다. 이전 테스트를 확인하세요."
    fi
}

# 11. 기사 영구 삭제
test_permanent_delete_article() {
    print_header "11. 기사 영구 삭제 테스트"
    
    if [ ! -z "$ARTICLE_ID" ]; then
        make_request "DELETE" "/admin/articles/$ARTICLE_ID?permanent=true" "" "기사 영구 삭제"
    else
        print_error "기사 ID가 없습니다. 이전 테스트를 확인하세요."
    fi
}

# 메인 테스트 실행
main() {
    print_header "관리자 기사 관리 API 테스트 시작"
    
    # jq 설치 확인
    if ! command -v jq &> /dev/null; then
        print_error "jq가 설치되어 있지 않습니다. JSON 파싱을 위해 jq를 설치해주세요."
        echo "macOS: brew install jq"
        echo "Ubuntu: sudo apt-get install jq"
        exit 1
    fi
    
    # 서버 연결 확인
    if ! curl -s --head "$BASE_URL/health" >/dev/null; then
        print_error "서버에 연결할 수 없습니다: $BASE_URL"
        print_info "백엔드 서버가 실행 중인지 확인하세요."
        exit 1
    fi
    
    print_success "서버 연결 확인됨: $BASE_URL"
    
    # 테스트 실행
    test_admin_login
    test_get_categories
    test_get_tags
    test_create_article
    test_get_articles
    test_get_article
    test_update_article
    test_publish_article
    test_unpublish_article
    test_soft_delete_article
    test_permanent_delete_article
    
    print_header "테스트 완료"
    print_success "모든 API 테스트가 완료되었습니다."
}

# 스크립트 실행
main "$@"