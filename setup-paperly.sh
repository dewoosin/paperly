#!/bin/bash

# Paperly 엔터프라이즈급 모노레포 프로젝트 구조 생성 스크립트
# 실행 전 현재 디렉토리 확인 필요

echo "🚀 Paperly 엔터프라이즈 프로젝트 구조 생성 시작..."

# 프로젝트 루트 디렉토리 생성
PROJECT_NAME="paperly"
echo "📁 프로젝트 루트 디렉토리 생성: $PROJECT_NAME"

# 이미 존재하는 디렉토리 확인
if [ -d "$PROJECT_NAME" ]; then
    echo "⚠️  $PROJECT_NAME 디렉토리가 이미 존재합니다."
    read -p "삭제하고 새로 생성하시겠습니까? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$PROJECT_NAME"
    else
        echo "❌ 작업을 취소합니다."
        exit 1
    fi
fi

mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# 메인 디렉토리 구조 생성
echo "📂 메인 디렉토리 구조 생성 중..."

# apps 디렉토리
mkdir -p apps/backend
mkdir -p apps/mobile
mkdir -p apps/admin

# packages 디렉토리
mkdir -p packages/shared-types
mkdir -p packages/config
mkdir -p packages/ui-components

# infrastructure 디렉토리
mkdir -p infrastructure/docker/postgres
mkdir -p infrastructure/docker/redis
mkdir -p infrastructure/k8s/base
mkdir -p infrastructure/k8s/production
mkdir -p infrastructure/terraform

# 기타 디렉토리
mkdir -p scripts
mkdir -p docs/api
mkdir -p docs/architecture
mkdir -p .github/workflows
mkdir -p .github/ISSUE_TEMPLATE

# 루트 파일들 생성
echo "📄 루트 설정 파일 생성 중..."

# .gitignore 생성
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
.pnp
.pnp.js

# Testing
coverage/
.nyc_output

# Production
build/
dist/
out/

# Environment files
.env
.env.local
.env.development.local
.env.test.local
.env.production.local
*.env

# IDE
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store

# Logs
logs/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
lerna-debug.log*

# Flutter
**/doc/api/
**/ios/Flutter/.last_build_id
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
/build/
*.iml
*.ipr
*.iws

# Docker
.docker/

# Terraform
*.tfstate
*.tfstate.*
.terraform/
EOF

# README.md 생성
cat > README.md << 'EOF'
# Paperly - AI 기반 맞춤형 학습 플랫폼

## 🏗️ 프로젝트 구조

```
paperly/
├── apps/                  # 애플리케이션들
│   ├── backend/          # Node.js API 서버
│   ├── mobile/           # Flutter 모바일 앱
│   └── admin/            # 관리자 대시보드 (추후 개발)
├── packages/             # 공유 패키지
│   ├── shared-types/     # TypeScript 타입 정의
│   ├── config/           # 공통 설정
│   └── ui-components/    # 공유 UI 컴포넌트
├── infrastructure/       # 인프라 설정
│   ├── docker/          # Docker 설정
│   ├── k8s/             # Kubernetes 매니페스트
│   └── terraform/       # IaC 설정
├── scripts/             # 유틸리티 스크립트
└── docs/                # 프로젝트 문서
```

## 🚀 시작하기

### 필수 요구사항
- Node.js v23+
- Flutter 3.32+
- Docker 28+
- PostgreSQL 15+ (Docker로 실행)

### 설치 및 실행
```bash
# 의존성 설치
npm install

# 개발 환경 실행
npm run dev
```

## 📚 문서
- [API 문서](./docs/api/README.md)
- [아키텍처 문서](./docs/architecture/README.md)
EOF

# package.json (워크스페이스 설정)
cat > package.json << 'EOF'
{
  "name": "paperly",
  "version": "1.0.0",
  "description": "AI 기반 맞춤형 학습 플랫폼",
  "private": true,
  "workspaces": [
    "apps/*",
    "packages/*"
  ],
  "scripts": {
    "dev": "npm run dev:docker && npm run dev:backend",
    "dev:docker": "docker-compose -f infrastructure/docker/docker-compose.yml up -d",
    "dev:backend": "npm run dev --workspace=@paperly/backend",
    "dev:mobile": "cd apps/mobile && flutter run",
    "build": "npm run build --workspaces",
    "test": "npm run test --workspaces",
    "lint": "npm run lint --workspaces",
    "clean": "npm run clean --workspaces && rm -rf node_modules"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "typescript": "^5.0.0"
  },
  "engines": {
    "node": ">=20.0.0",
    "npm": ">=10.0.0"
  }
}
EOF

# Docker Compose 설정
cat > infrastructure/docker/docker-compose.yml << 'EOF'
version: '3.9'

services:
  postgres:
    image: postgres:15-alpine
    container_name: paperly_postgres
    restart: unless-stopped
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: paperly_user
      POSTGRES_PASSWORD: paperly_dev_password
      POSTGRES_DB: paperly_db
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./postgres/init.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U paperly_user"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: paperly_redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  pgadmin:
    image: dpage/pgadmin4:latest
    container_name: paperly_pgadmin
    restart: unless-stopped
    ports:
      - "5050:80"
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@paperly.com
      PGADMIN_DEFAULT_PASSWORD: admin
    depends_on:
      - postgres

volumes:
  postgres_data:
  redis_data:
EOF

# PostgreSQL 초기화 스크립트
cat > infrastructure/docker/postgres/init.sql << 'EOF'
-- Paperly 데이터베이스 초기 설정
-- 개발 환경용 초기 스키마

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 기본 스키마 생성
CREATE SCHEMA IF NOT EXISTS paperly;

-- 개발용 샘플 데이터는 마이그레이션으로 관리
EOF

# Backend 프로젝트 설정
echo "🔧 Backend 프로젝트 설정 중..."
cd apps/backend

# Backend package.json
cat > package.json << 'EOF'
{
  "name": "@paperly/backend",
  "version": "1.0.0",
  "description": "Paperly API 서버",
  "main": "dist/index.js",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.ts",
    "test": "jest",
    "lint": "eslint src --ext .ts",
    "clean": "rm -rf dist node_modules"
  },
  "dependencies": {
    "express": "^4.19.0",
    "cors": "^2.8.5",
    "helmet": "^7.1.0",
    "dotenv": "^16.4.0",
    "pg": "^8.11.0",
    "jsonwebtoken": "^9.0.0",
    "bcrypt": "^5.1.0",
    "zod": "^3.22.0",
    "winston": "^3.11.0"
  },
  "devDependencies": {
    "@types/express": "^4.17.21",
    "@types/node": "^20.0.0",
    "@types/cors": "^2.8.17",
    "@types/bcrypt": "^5.0.2",
    "@types/jsonwebtoken": "^9.0.5",
    "@types/pg": "^8.11.0",
    "typescript": "^5.0.0",
    "tsx": "^4.7.0",
    "@typescript-eslint/eslint-plugin": "^6.19.0",
    "@typescript-eslint/parser": "^6.19.0",
    "eslint": "^8.56.0",
    "jest": "^29.7.0",
    "@types/jest": "^29.5.11"
  }
}
EOF

# Backend 디렉토리 구조
mkdir -p src/{config,controllers,middleware,models,routes,services,utils,types}
mkdir -p src/database/{migrations,seeds}
mkdir -p tests/{unit,integration}

# TypeScript 설정
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "moduleResolution": "node",
    "allowJs": false,
    "noEmit": false,
    "incremental": true,
    "sourceMap": true,
    "declaration": true,
    "declarationMap": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedIndexedAccess": true,
    "allowSyntheticDefaultImports": true,
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "tests"]
}
EOF

# .env.example
cat > .env.example << 'EOF'
# Environment
NODE_ENV=development
PORT=3000

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=paperly_db
DB_USER=paperly_user
DB_PASSWORD=paperly_dev_password

# JWT
JWT_SECRET=your-super-secret-jwt-key-change-this
JWT_EXPIRES_IN=7d

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# OpenAI (나중에 추가)
# OPENAI_API_KEY=your-openai-api-key
EOF

# Flutter 프로젝트는 이미 있으므로 이동
cd ../../..

# Scripts 디렉토리에 유용한 스크립트 추가
cat > scripts/setup-dev.sh << 'EOF'
#!/bin/bash
# 개발 환경 설정 스크립트

echo "🔧 개발 환경 설정 시작..."

# .env 파일 생성
if [ ! -f apps/backend/.env ]; then
    cp apps/backend/.env.example apps/backend/.env
    echo "✅ Backend .env 파일 생성됨"
fi

# npm 패키지 설치
echo "📦 NPM 패키지 설치 중..."
npm install

# Docker 컨테이너 시작
echo "🐳 Docker 컨테이너 시작 중..."
npm run dev:docker

echo "✨ 개발 환경 설정 완료!"
EOF

chmod +x scripts/setup-dev.sh

# GitHub Actions 워크플로우
cat > .github/workflows/ci.yml << 'EOF'
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  backend-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run test --workspace=@paperly/backend
      - run: npm run lint --workspace=@paperly/backend

  mobile-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.32.4'
      - run: cd apps/mobile && flutter pub get
      - run: cd apps/mobile && flutter analyze
      - run: cd apps/mobile && flutter test
EOF

echo "✅ 프로젝트 구조 생성 완료!"
echo ""
echo "다음 단계:"
echo "1. cd $PROJECT_NAME"
echo "2. npm install"
echo "3. ./scripts/setup-dev.sh"
echo ""
echo "🎉 Paperly 엔터프라이즈 프로젝트가 준비되었습니다!"
