#!/bin/bash

# Paperly Backend Enterprise Architecture Setup Script
# 엔터프라이즈급 클린 아키텍처 + DDD 폴더 구조 생성

echo "🏗️  Creating enterprise-grade backend structure..."

# Base directory (run from apps/backend)
BASE_DIR="src"

# Create domain layer directories
echo "📁 Creating domain layer..."
mkdir -p $BASE_DIR/domain/{entities,value-objects,repositories,services,events,exceptions}

# Create application layer directories
echo "📁 Creating application layer..."
mkdir -p $BASE_DIR/application/{use-cases/{auth,user,article,recommendation},dto,mappers,interfaces}

# Create infrastructure layer directories
echo "📁 Creating infrastructure layer..."
mkdir -p $BASE_DIR/infrastructure/{persistence/{postgres/{migrations,seeders},redis,repositories},web/{express/{middlewares,interceptors},controllers,routes,validators,filters,decorators},external/{openai,storage,email,notification},config,logging,monitoring}

# Create shared directories
echo "📁 Creating shared layer..."
mkdir -p $BASE_DIR/shared/{errors,utils,constants,types,interfaces}

# Create test directories
echo "📁 Creating test structure..."
mkdir -p tests/{unit/{domain,application,infrastructure},integration,e2e,fixtures,mocks}

# Create root config directories
echo "📁 Creating config directories..."
mkdir -p {config,scripts,docs}

# Create .gitkeep files to preserve empty directories
find $BASE_DIR -type d -empty -exec touch {}/.gitkeep \;
find tests -type d -empty -exec touch {}/.gitkeep \;

echo "✅ Folder structure created successfully!"

# Create index files for better organization
echo "📝 Creating index files..."

# Domain indices
touch $BASE_DIR/domain/index.ts
touch $BASE_DIR/domain/entities/index.ts
touch $BASE_DIR/domain/repositories/index.ts
touch $BASE_DIR/domain/services/index.ts

# Application indices
touch $BASE_DIR/application/index.ts
touch $BASE_DIR/application/use-cases/index.ts
touch $BASE_DIR/application/dto/index.ts

# Infrastructure indices
touch $BASE_DIR/infrastructure/index.ts
touch $BASE_DIR/infrastructure/web/controllers/index.ts
touch $BASE_DIR/infrastructure/web/routes/index.ts

echo "🎉 Enterprise backend structure ready!"
