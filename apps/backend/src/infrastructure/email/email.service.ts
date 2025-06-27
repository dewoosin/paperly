// /Users/workspace/paperly/apps/backend/src/infrastructure/email/email.service.ts

import nodemailer, { Transporter } from 'nodemailer';
import { config } from '../config/env.config';
import { Logger } from '../logging/Logger';

/**
 * 이메일 서비스
 * 
 * 이메일 발송 기능을 담당합니다.
 * 개발 환경에서는 콘솔 출력, 프로덕션에서는 실제 SMTP 사용
 */
export class EmailService {
  private static readonly logger = new Logger('EmailService');
  private transporter: Transporter | null = null;

  constructor() {
    this.initializeTransporter();
  }

  /**
   * 이메일 전송자 초기화
   */
  private initializeTransporter(): void {
    if (config.NODE_ENV === 'development') {
      // 개발 환경: Ethereal Email (테스트용)
      nodemailer.createTestAccount((err, account) => {
        if (err) {
          EmailService.logger.error('Failed to create test account', err);
          return;
        }

        this.transporter = nodemailer.createTransport({
          host: account.smtp.host,
          port: account.smtp.port,
          secure: account.smtp.secure,
          auth: {
            user: account.user,
            pass: account.pass,
          },
        });

        EmailService.logger.info('Test email account created', {
          user: account.user,
          web: account.web,
        });
      });
    } else {
      // 프로덕션 환경: 실제 SMTP 설정
      this.transporter = nodemailer.createTransport({
        host: config.SMTP_HOST,
        port: config.SMTP_PORT || 587,
        secure: config.SMTP_SECURE || false,
        auth: {
          user: config.SMTP_USER,
          pass: config.SMTP_PASS,
        },
      });
    }
  }

  /**
   * 이메일 발송
   * 
   * @param to - 수신자 이메일
   * @param subject - 제목
   * @param html - HTML 내용
   * @param text - 텍스트 내용 (선택적)
   */
  private async sendEmail(
    to: string,
    subject: string,
    html: string,
    text?: string
  ): Promise<void> {
    if (!this.transporter) {
      EmailService.logger.warn('Email transporter not initialized, logging email instead');
      EmailService.logger.info('Email to send', { to, subject, html });
      return;
    }

    try {
      const info = await this.transporter.sendMail({
        from: `"Paperly" <${config.EMAIL_FROM || 'noreply@paperly.com'}>`,
        to,
        subject,
        text: text || this.htmlToText(html),
        html,
      });

      EmailService.logger.info('Email sent successfully', {
        messageId: info.messageId,
        to,
        subject,
      });

      // 개발 환경에서 미리보기 URL 출력
      if (config.NODE_ENV === 'development') {
        const previewUrl = nodemailer.getTestMessageUrl(info);
        if (previewUrl) {
          EmailService.logger.info('Preview URL', { url: previewUrl });
        }
      }
    } catch (error) {
      EmailService.logger.error('Failed to send email', error);
      throw error;
    }
  }

  /**
   * 회원가입 인증 이메일 발송
   * 
   * @param email - 수신자 이메일
   * @param name - 사용자 이름
   * @param verificationToken - 인증 토큰
   */
  async sendVerificationEmail(
    email: string,
    name: string,
    verificationToken: string
  ): Promise<void> {
    const verificationUrl = `${config.CLIENT_URL}/auth/verify-email?token=${verificationToken}`;
    
    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h1 style="color: #333;">Paperly 이메일 인증</h1>
        <p>안녕하세요 ${name}님,</p>
        <p>Paperly에 가입해 주셔서 감사합니다!</p>
        <p>아래 버튼을 클릭하여 이메일 인증을 완료해주세요:</p>
        <div style="margin: 30px 0;">
          <a href="${verificationUrl}" 
             style="background-color: #007bff; color: white; padding: 12px 24px; 
                    text-decoration: none; border-radius: 4px; display: inline-block;">
            이메일 인증하기
          </a>
        </div>
        <p>또는 다음 링크를 브라우저에 복사하여 붙여넣으세요:</p>
        <p style="word-break: break-all; color: #666;">${verificationUrl}</p>
        <p>이 링크는 24시간 동안 유효합니다.</p>
        <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
        <p style="color: #666; font-size: 14px;">
          이 메일은 Paperly 서비스 가입을 위해 발송되었습니다. 
          만약 가입하신 적이 없다면 이 메일을 무시해주세요.
        </p>
      </div>
    `;

    await this.sendEmail(
      email,
      'Paperly 이메일 인증',
      html
    );
  }

  /**
   * 비밀번호 재설정 이메일 발송
   * 
   * @param email - 수신자 이메일
   * @param name - 사용자 이름
   * @param resetToken - 재설정 토큰
   */
  async sendPasswordResetEmail(
    email: string,
    name: string,
    resetToken: string
  ): Promise<void> {
    const resetUrl = `${config.CLIENT_URL}/auth/reset-password?token=${resetToken}`;
    
    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h1 style="color: #333;">비밀번호 재설정</h1>
        <p>안녕하세요 ${name}님,</p>
        <p>비밀번호 재설정을 요청하셨습니다.</p>
        <p>아래 버튼을 클릭하여 새로운 비밀번호를 설정해주세요:</p>
        <div style="margin: 30px 0;">
          <a href="${resetUrl}" 
             style="background-color: #dc3545; color: white; padding: 12px 24px; 
                    text-decoration: none; border-radius: 4px; display: inline-block;">
            비밀번호 재설정
          </a>
        </div>
        <p>또는 다음 링크를 브라우저에 복사하여 붙여넣으세요:</p>
        <p style="word-break: break-all; color: #666;">${resetUrl}</p>
        <p>이 링크는 1시간 동안 유효합니다.</p>
        <p style="color: #dc3545; font-weight: bold;">
          비밀번호 재설정을 요청하지 않으셨다면 이 메일을 무시해주세요.
        </p>
        <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
        <p style="color: #666; font-size: 14px;">
          보안을 위해 이 링크는 1회만 사용 가능합니다.
        </p>
      </div>
    `;

    await this.sendEmail(
      email,
      'Paperly 비밀번호 재설정',
      html
    );
  }

  /**
   * 환영 이메일 발송
   * 
   * @param email - 수신자 이메일
   * @param name - 사용자 이름
   */
  async sendWelcomeEmail(email: string, name: string): Promise<void> {
    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h1 style="color: #333;">Paperly에 오신 것을 환영합니다!</h1>
        <p>안녕하세요 ${name}님,</p>
        <p>Paperly 가입을 축하드립니다! 🎉</p>
        <p>이제 매일 맞춤형 학습 콘텐츠를 받아보실 수 있습니다.</p>
        <h2 style="color: #666; font-size: 18px;">시작하기</h2>
        <ul style="line-height: 1.8;">
          <li>프로필에서 관심사를 설정해주세요</li>
          <li>매일 아침 맞춤 콘텐츠를 확인하세요</li>
          <li>꾸준히 읽고 성장하는 모습을 지켜보세요</li>
        </ul>
        <div style="margin: 30px 0;">
          <a href="${config.CLIENT_URL}/profile" 
             style="background-color: #28a745; color: white; padding: 12px 24px; 
                    text-decoration: none; border-radius: 4px; display: inline-block;">
            프로필 설정하기
          </a>
        </div>
        <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
        <p style="color: #666; font-size: 14px;">
          궁금한 점이 있으시면 언제든지 문의해주세요.
        </p>
      </div>
    `;

    await this.sendEmail(
      email,
      'Paperly에 오신 것을 환영합니다!',
      html
    );
  }

  /**
   * HTML을 텍스트로 변환 (간단한 버전)
   */
  private htmlToText(html: string): string {
    return html
      .replace(/<[^>]*>/g, '')
      .replace(/\s+/g, ' ')
      .trim();
  }
}