// /Users/workspace/paperly/apps/backend/src/infrastructure/container/container.ts

import { container } from 'tsyringe';
import { DatabaseConnection } from '../database/database.connection';
import { SecurityEventRepository } from '../repositories/security-event.repository';
import { AdminRoleRepository } from '../repositories/admin-role.repository';
import { SecurityMonitor } from '../security/monitoring/security-monitor';

/**
 * 의존성 주입 컨테이너 설정
 * 
 * 애플리케이션에서 사용하는 모든 서비스와 리포지토리의 의존성을 등록합니다.
 */

// 데이터베이스 연결
container.registerSingleton<DatabaseConnection>('DatabaseConnection', DatabaseConnection);

// 리포지토리 등록
container.register<SecurityEventRepository>('SecurityEventRepository', {
  useFactory: (c) => new SecurityEventRepository(c.resolve('DatabaseConnection'))
});

container.register<AdminRoleRepository>('AdminRoleRepository', {
  useFactory: (c) => new AdminRoleRepository(c.resolve('DatabaseConnection'))
});

// 보안 모니터링 서비스 등록
container.register<SecurityMonitor>('SecurityMonitor', {
  useFactory: (c) => new SecurityMonitor(c.resolve('SecurityEventRepository'))
});

export { container };