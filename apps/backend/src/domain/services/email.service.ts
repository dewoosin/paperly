// apps/backend/src/domain/services/email.service.ts (인터페이스)

import { Email } from '../value-objects/auth.value-objects';

/**
 * 이메일 템플릿 종류
 */
export enum EmailTemplate {
  VERIFICATION = 'verification',
  PASSWORD_RESET = 'password_reset',
  WELCOME = 'welcome',
  DAILY_RECOMMENDATION = 'daily_recommendation'
}

/**
 * 이메일 서비스 인터페이스
 */
export interface IEmailService {
  /**
   * 이메일 인증 메일 발송
   */
  sendVerificationEmail(email: Email, token: string, userName: string): Promise<void>;

  /**
   * 비밀번호 재설정 메일 발송
   */
  sendPasswordResetEmail(email: Email, token: string, userName: string): Promise<void>;

  /**
   * 환영 메일 발송
   */
  sendWelcomeEmail(email: Email, userName: string): Promise<void>;

  /**
   * 일일 추천 콘텐츠 메일 발송
   */
  sendDailyRecommendationEmail(email: Email, userName: string, recommendations: any[]): Promise<void>;
}
