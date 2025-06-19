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
