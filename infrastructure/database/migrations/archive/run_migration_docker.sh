#!/bin/bash

# =============================================
# Paperly 데이터베이스 마이그레이션 실행 스크립트 (Docker 버전)
# =============================================

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 데이터베이스 연결 정보
DB_HOST="${DB_HOST:-host.docker.internal}"  # macOS에서 로컬 호스트 접근
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-paperly}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-}"

# 현재 디렉토리 경로
CURRENT_DIR=$(pwd)

echo -e "${GREEN}=== Paperly 데이터베이스 마이그레이션 (Docker) ===${NC}"
echo "데이터베이스: $DB_NAME"
echo "호스트: $DB_HOST:$DB_PORT"
echo "사용자: $DB_USER"
echo ""

# Docker 이미지 확인
echo -e "${YELLOW}PostgreSQL Docker 이미지 확인 중...${NC}"
docker pull postgres:16-alpine

# 비밀번호 환경변수 설정
if [ -z "$DB_PASSWORD" ]; then
    read -s -p "데이터베이스 비밀번호를 입력하세요: " DB_PASSWORD
    echo ""
fi

# psql 실행 함수
run_psql() {
    local sql_file=$1
    docker run --rm -i \
        -e PGPASSWORD="$DB_PASSWORD" \
        -v "$CURRENT_DIR":/migrations \
        postgres:16-alpine \
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "/migrations/$sql_file"
}

# psql 명령 실행 함수
run_psql_command() {
    local command=$1
    docker run --rm -i \
        -e PGPASSWORD="$DB_PASSWORD" \
        postgres:16-alpine \
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "$command"
}

# 1단계: paperly 스키마 생성
echo -e "${YELLOW}1. paperly 스키마 생성 중...${NC}"
run_psql "000_create_paperly_schema.sql"
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
run_psql_command "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE' ORDER BY table_name;"

echo ""
read -p "계속 진행하시겠습니까? (Y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "마이그레이션을 취소했습니다."
    exit 0
fi

# 3단계: paperly 스키마에 테이블 생성
echo ""
echo -e "${YELLOW}3. paperly 스키마에 테이블 생성 중...${NC}"
echo "이 작업은 시간이 걸릴 수 있습니다..."
run_psql "004_paperly_complete_schema.sql"
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
run_psql_command "SELECT table_name FROM information_schema.tables WHERE table_schema = 'paperly' AND table_type = 'BASE TABLE' ORDER BY table_name LIMIT 20;"

echo ""
echo -e "${GREEN}=== 마이그레이션 완료! ===${NC}"
echo ""
echo "다음 명령으로 paperly 스키마를 기본으로 설정할 수 있습니다:"
echo -e "${YELLOW}docker run --rm -e PGPASSWORD='$DB_PASSWORD' postgres:16-alpine psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c \"ALTER DATABASE $DB_NAME SET search_path TO paperly, public;\"${NC}"