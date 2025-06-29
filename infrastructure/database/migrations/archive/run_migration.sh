#!/bin/bash

# =============================================
# Paperly 데이터베이스 마이그레이션 실행 스크립트
# =============================================

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 데이터베이스 연결 정보 (환경변수 또는 직접 설정)
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-paperly}"
DB_USER="${DB_USER:-postgres}"

echo -e "${GREEN}=== Paperly 데이터베이스 마이그레이션 ===${NC}"
echo "데이터베이스: $DB_NAME"
echo "호스트: $DB_HOST:$DB_PORT"
echo "사용자: $DB_USER"
echo ""

# 1단계: paperly 스키마 생성
echo -e "${YELLOW}1. paperly 스키마 생성 중...${NC}"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f 000_create_paperly_schema.sql
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ paperly 스키마 생성 완료${NC}"
else
    echo -e "${RED}✗ paperly 스키마 생성 실패${NC}"
    exit 1
fi

# 2단계: 기존 public 스키마 확인
echo ""
echo -e "${YELLOW}2. 기존 public 스키마 테이블 확인${NC}"
echo "다음 테이블들이 public 스키마에 있습니다:"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE'
ORDER BY table_name;"

echo ""
read -p "public 스키마의 테이블을 정리하시겠습니까? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}public 스키마 정리는 clean_public_schema.sql을 직접 수정하여 실행하세요.${NC}"
fi

# 3단계: paperly 스키마에 테이블 생성
echo ""
echo -e "${YELLOW}3. paperly 스키마에 테이블 생성 중...${NC}"
echo "이 작업은 시간이 걸릴 수 있습니다..."
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f 004_paperly_complete_schema.sql
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 테이블 생성 완료${NC}"
else
    echo -e "${RED}✗ 테이블 생성 중 오류 발생${NC}"
    echo "오류 내용을 확인하고 수정 후 다시 실행하세요."
    exit 1
fi

# 4단계: 생성된 테이블 확인
echo ""
echo -e "${YELLOW}4. 생성된 테이블 확인${NC}"
echo "paperly 스키마에 생성된 테이블:"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'paperly' 
  AND table_type = 'BASE TABLE'
ORDER BY table_name;" | head -20

echo ""
echo -e "${GREEN}=== 마이그레이션 완료! ===${NC}"
echo ""
echo "다음 명령으로 paperly 스키마를 기본으로 설정할 수 있습니다:"
echo -e "${YELLOW}ALTER DATABASE $DB_NAME SET search_path TO paperly, public;${NC}"
echo ""
echo "애플리케이션에서 연결 시 다음과 같이 설정하세요:"
echo -e "${YELLOW}SET search_path TO paperly, public;${NC}"