// apps/backend/src/infrastructure/di/container.ts

import 'reflect-metadata';
import { container } from 'tsyringe';

// Configuration
import { config } from '../config/env.config';

/**
 * 의존성 주입 컨테이너 설정 (간소화 버전)
 * 
 * 기본 설정만 먼저 등록하고, 점진적으로 확장합니다.
 */
export function setupContainer(): void {
  
  // =============================================================================
  // 설정 및 Config 등록
  // =============================================================================
  
  container.registerInstance('Config', config);

  console.log('✅ DI Container가 성공적으로 설정되었습니다 (기본 설정).');
}

/**
 * 컨테이너 상태 확인 (디버깅용)
 */
export function validateContainer(): void {
  try {
    // 기본 설정 확인
    const configInstance = container.resolve('Config');
    
    console.log('✅ 컨테이너 검증 완료: 기본 의존성이 올바르게 등록되었습니다.');
  } catch (error) {
    console.error('❌ 컨테이너 검증 실패:', error);
    throw error;
  }
}