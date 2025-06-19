#!/bin/bash
# Paperly 개발 환경 설정 스크립트
# 이 스크립트는 프로젝트의 초기 개발 환경을 설정합니다.

echo "🔧 Paperly 개발 환경 설정 시작..."

# 스크립트가 실행되는 위치 확인
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "📍 프로젝트 루트: $PROJECT_ROOT"
cd "$PROJECT_ROOT"

# .env 파일 생성 (Backend)
echo "📄 환경 설정 파일 확인 중..."
if [ ! -f apps/backend/.env ]; then
    if [ -f apps/backend/.env.example ]; then
        cp apps/backend/.env.example apps/backend/.env
        echo "✅ Backend .env 파일이 생성되었습니다."
        echo "   ⚠️  .env 파일의 설정값을 확인하고 필요시 수정하세요."
    else
        echo "❌ .env.example 파일을 찾을 수 없습니다."
    fi
else
    echo "✅ Backend .env 파일이 이미 존재합니다."
fi

# Node.js 버전 확인
echo ""
echo "🔍 Node.js 버전 확인 중..."
NODE_VERSION=$(node -v)
echo "   현재 Node.js 버전: $NODE_VERSION"

# NPM 패키지 설치
echo ""
echo "📦 NPM 패키지 설치 중..."
if [ -f package.json ]; then
    npm install
    echo "✅ 루트 패키지 설치 완료"
    
    # Backend 패키지 설치
    if [ -f apps/backend/package.json ]; then
        echo "📦 Backend 패키지 설치 중..."
        cd apps/backend && npm install
        cd "$PROJECT_ROOT"
        echo "✅ Backend 패키지 설치 완료"
    fi
else
    echo "❌ package.json 파일을 찾을 수 없습니다."
fi

# Docker 상태 확인
echo ""
echo "🐳 Docker 상태 확인 중..."
if command -v docker &> /dev/null; then
    if docker info &> /dev/null; then
        echo "✅ Docker가 실행 중입니다."
        
        # Docker Compose 파일 확인
        COMPOSE_FILE="infrastructure/docker/docker-compose.yml"
        if [ -f "$COMPOSE_FILE" ]; then
            echo ""
            echo "🚀 Docker 컨테이너 시작 중..."
            docker-compose -f "$COMPOSE_FILE" up -d
            
            # 컨테이너 상태 확인
            echo ""
            echo "📊 컨테이너 상태:"
            docker-compose -f "$COMPOSE_FILE" ps
            
            echo ""
            echo "📌 서비스 접속 정보:"
            echo "   - PostgreSQL: localhost:5432"
            echo "   - Redis: localhost:6379"
            echo "   - pgAdmin: http://localhost:5050"
            echo "     (이메일: admin@paperly.com, 비밀번호: admin)"
        else
            echo "❌ docker-compose.yml 파일을 찾을 수 없습니다."
        fi
    else
        echo "❌ Docker가 실행되고 있지 않습니다."
        echo "   Docker Desktop을 시작하고 다시 시도하세요."
    fi
else
    echo "❌ Docker가 설치되어 있지 않습니다."
fi

echo ""
echo "✨ 개발 환경 설정이 완료되었습니다!"
echo ""
echo "🎯 다음 단계:"
echo "   1. Backend 서버 시작: npm run dev:backend"
echo "   2. Flutter 앱 실행: npm run dev:mobile"
echo ""
