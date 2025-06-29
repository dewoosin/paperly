# Database Migrations

이 디렉토리는 더 이상 사용되지 않습니다.

새로운 마이그레이션 파일들은 `/infrastructure/database/migrations/` 디렉토리에 있습니다.

## 마이그레이션 실행

```bash
cd /Users/workspace/paperly/infrastructure/database/migrations
node run_migration.js
```

또는

```bash
./run_migration.sh  # psql이 설치된 경우
./run_migration_docker.sh  # Docker 사용 시
```