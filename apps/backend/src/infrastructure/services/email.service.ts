// apps/backend/src/infrastructure/services/email.service.ts

import { injectable, inject } from 'tsyringe';
import nodemailer from 'nodemailer';
import { IEmailService, EmailTemplate } from '../../domain/services/email.service';
import { Email } from '../../domain/value-objects/auth.value-objects';
import { Config } from '../config/config';
import { Logger } from '../logging/Logger';
import { AppError, ErrorCode } from '../../shared/errors/app-error';

/**
 * 이메일 서비스 구현
 * - Nodemailer를 사용한 이메일 발송
 * - 템플릿 기반 이메일
 */
@injectable()
export class EmailService implements IEmailService {
  private readonly logger = new Logger('EmailService');
  private transporter: nodemailer.Transporter;
  private readonly fromEmail: string;
  private readonly fromName: string;
  private readonly frontendUrl: string;

  constructor(@inject('Config') private config: Config) {
    // 개발 환경에서는 Ethereal Email 사용 (테스트용 SMTP)
    // 프로덕션에서는 실제 SMTP 설정 사용
    if (this.config.get('NODE_ENV') === 'development') {
      this.initDevTransporter();
    } else {
      this.initProdTransporter();
    }

    this.fromEmail = this.config.get('EMAIL_FROM', 'noreply@paperly.ai');
    this.fromName = this.config.get('EMAIL_FROM_NAME', 'Paperly');
    this.frontendUrl = this.config.get('FRONTEND_URL', 'http://localhost:3001');
  }

  /**
   * 개발용 이메일 전송 설정
   */
  private async initDevTransporter() {
    // Ethereal Email 테스트 계정 생성
    const testAccount = await nodemailer.createTestAccount();

    this.transporter = nodemailer.createTransporter({
      host: 'smtp.ethereal.email',
      port: 587,
      secure: false,
      auth: {
        user: testAccount.user,
        pass: testAccount.pass
      }
    });

    this.logger.info('개발용 이메일 서비스 초기화 완료', {
      testAccount: testAccount.user
    });
  }

  /**
   * 프로덕션 이메일 전송 설정
   */
  private initProdTransporter() {
    this.transporter = nodemailer.createTransporter({
      host: this.config.get('SMTP_HOST'),
      port: this.config.get('SMTP_PORT', 587),
      secure: this.config.get('SMTP_SECURE', false),
      auth: {
        user: this.config.get('SMTP_USER'),
        pass: this.config.get('SMTP_PASS')
      }
    });
  }

  /**
   * 이메일 인증 메일 발송
   */
  async sendVerificationEmail(email: Email, token: string, userName: string): Promise<void> {
    const verificationUrl = `${this.frontendUrl}/auth/verify-email?token=${token}`;
    
    const html = this.getEmailTemplate(EmailTemplate.VERIFICATION, {
      userName,
      verificationUrl,
      expiresIn: '24시간'
    });

    await this.sendEmail({
      to: email.value,
      subject: '[Paperly] 이메일 인증을 완료해주세요',
      html
    });

    this.logger.info('이메일 인증 메일 발송', { email: email.value });
  }

  /**
   * 비밀번호 재설정 메일 발송
   */
  async sendPasswordResetEmail(email: Email, token: string, userName: string): Promise<void> {
    const resetUrl = `${this.frontendUrl}/auth/reset-password?token=${token}`;
    
    const html = this.getEmailTemplate(EmailTemplate.PASSWORD_RESET, {
      userName,
      resetUrl,
      expiresIn: '1시간'
    });

    await this.sendEmail({
      to: email.value,
      subject: '[Paperly] 비밀번호 재설정',
      html
    });

    this.logger.info('비밀번호 재설정 메일 발송', { email: email.value });
  }

  /**
   * 환영 메일 발송
   */
  async sendWelcomeEmail(email: Email, userName: string): Promise<void> {
    const html = this.getEmailTemplate(EmailTemplate.WELCOME, {
      userName,
      loginUrl: `${this.frontendUrl}/auth/login`
    });

    await this.sendEmail({
      to: email.value,
      subject: '[Paperly] 환영합니다! 지식의 여정을 시작하세요',
      html
    });

    this.logger.info('환영 메일 발송', { email: email.value });
  }

  /**
   * 일일 추천 콘텐츠 메일 발송
   */
  async sendDailyRecommendationEmail(email: Email, userName: string, recommendations: any[]): Promise<void> {
    // TODO: Day 10+ 구현
    this.logger.info('일일 추천 메일 발송', { email: email.value });
  }

  /**
   * 이메일 발송 공통 메서드
   */
  private async sendEmail(options: {
    to: string;
    subject: string;
    html: string;
  }): Promise<void> {
    try {
      const info = await this.transporter.sendMail({
        from: `"${this.fromName}" <${this.fromEmail}>`,
        to: options.to,
        subject: options.subject,
        html: options.html
      });

      // 개발 환경에서는 Ethereal Email URL 로깅
      if (this.config.get('NODE_ENV') === 'development') {
        this.logger.info('이메일 미리보기 URL:', {
          url: nodemailer.getTestMessageUrl(info)
        });
      }

      this.logger.info('이메일 발송 완료', { messageId: info.messageId });
    } catch (error) {
      this.logger.error('이메일 발송 실패', { error });
      throw new AppError(ErrorCode.INTERNAL_ERROR, '이메일 발송에 실패했습니다');
    }
  }

  /**
   * 이메일 템플릿 가져오기
   */
  private getEmailTemplate(template: EmailTemplate, data: Record<string, any>): string {
    switch (template) {
      case EmailTemplate.VERIFICATION:
        return this.getVerificationEmailTemplate(data);
      case EmailTemplate.PASSWORD_RESET:
        return this.getPasswordResetTemplate(data);
      case EmailTemplate.WELCOME:
        return this.getWelcomeTemplate(data);
      default:
        throw new Error(`Unknown email template: ${template}`);
    }
  }

  /**
   * 이메일 인증 템플릿
   */
  private getVerificationEmailTemplate(data: {
    userName: string;
    verificationUrl: string;
    expiresIn: string;
  }): string {
    return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>이메일 인증</title>
  <style>
    body {
      margin: 0;
      padding: 0;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background-color: #FCFBF7;
      color: #2C2C2C;
    }
    .container {
      max-width: 600px;
      margin: 0 auto;
      padding: 40px 20px;
    }
    .card {
      background: #FFFFFF;
      border-radius: 16px;
      padding: 40px;
      box-shadow: 0 2px 20px rgba(0,0,0,0.04);
    }
    .logo {
      font-size: 24px;
      font-weight: 600;
      color: #90A990;
      margin-bottom: 32px;
    }
    h1 {
      font-size: 28px;
      font-weight: 600;
      margin: 0 0 16px 0;
      color: #2C2C2C;
    }
    p {
      font-size: 16px;
      line-height: 1.6;
      color: #4A4A4A;
      margin: 0 0 24px 0;
    }
    .button {
      display: inline-block;
      background-color: #90A990;
      color: white;
      text-decoration: none;
      padding: 14px 32px;
      border-radius: 8px;
      font-weight: 500;
      margin: 24px 0;
    }
    .footer {
      margin-top: 32px;
      padding-top: 32px;
      border-top: 1px solid #F0F0F0;
      font-size: 14px;
      color: #7A7A7A;
    }
    .url-fallback {
      margin-top: 16px;
      padding: 16px;
      background: #F9F7F3;
      border-radius: 8px;
      font-size: 14px;
      word-break: break-all;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="card">
      <div class="logo">Paperly</div>
      
      <h1>이메일 인증</h1>
      
      <p>안녕하세요, ${data.userName}님!</p>
      
      <p>
        Paperly에 가입해 주셔서 감사합니다. 
        아래 버튼을 클릭하여 이메일 인증을 완료해주세요.
      </p>
      
      <a href="${data.verificationUrl}" class="button">이메일 인증하기</a>
      
      <p style="font-size: 14px; color: #7A7A7A;">
        이 링크는 ${data.expiresIn} 동안 유효합니다.
      </p>
      
      <div class="url-fallback">
        <strong>버튼이 작동하지 않나요?</strong><br>
        아래 링크를 복사하여 브라우저에 붙여넣어 주세요:<br>
        <span style="color: #90A990;">${data.verificationUrl}</span>
      </div>
      
      <div class="footer">
        <p>
          이 메일은 Paperly 계정 생성 시 발송되는 인증 메일입니다.<br>
          본인이 요청하지 않으셨다면 이 메일을 무시하셔도 됩니다.
        </p>
        <p>
          © 2025 Paperly. All rights reserved.
        </p>
      </div>
    </div>
  </div>
</body>
</html>
    `;
  }

  /**
   * 비밀번호 재설정 템플릿
   */
  private getPasswordResetTemplate(data: {
    userName: string;
    resetUrl: string;
    expiresIn: string;
  }): string {
    // 비슷한 구조로 구현
    return `<!-- Password Reset Template -->`;
  }

  /**
   * 환영 이메일 템플릿
   */
  private getWelcomeTemplate(data: {
    userName: string;
    loginUrl: string;
  }): string {
    // 비슷한 구조로 구현
    return `<!-- Welcome Template -->`;
  }
}
