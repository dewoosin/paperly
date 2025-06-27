/**
 * Real Email Service Implementation
 * 
 * Handles actual email sending using nodemailer
 */

import nodemailer, { Transporter, SendMailOptions } from 'nodemailer';
import { config } from '../config/env.config';
import { Logger } from '../logging/Logger';

export interface EmailTemplate {
  subject: string;
  html: string;
  text: string;
}

export class RealEmailService {
  private readonly logger = new Logger('RealEmailService');
  private transporter: Transporter | null = null;
  private readonly fromEmail: string;
  private readonly fromName: string;
  private readonly clientUrl: string;
  private isInitialized = false;

  constructor() {
    this.fromEmail = config.EMAIL_FROM || 'noreply@paperly.ai';
    this.fromName = config.EMAIL_FROM_NAME || 'Paperly';
    this.clientUrl = config.CLIENT_URL || 'http://localhost:3001';
    
    this.initializeTransporter();
  }

  /**
   * Initialize email transporter
   */
  private async initializeTransporter(): Promise<void> {
    try {
      if (config.NODE_ENV === 'development') {
        // Development: Use Ethereal Email for testing
        await this.setupEtherealEmail();
      } else {
        // Production: Use real SMTP settings
        await this.setupProductionEmail();
      }
      
      this.isInitialized = true;
      this.logger.info('Email service initialized successfully', {
        environment: config.NODE_ENV,
        fromEmail: this.fromEmail
      });
    } catch (error) {
      this.logger.error('Failed to initialize email service', error);
    }
  }

  /**
   * Setup Ethereal Email for development testing
   */
  private async setupEtherealEmail(): Promise<void> {
    try {
      const testAccount = await nodemailer.createTestAccount();
      
      this.transporter = nodemailer.createTransporter({
        host: testAccount.smtp.host,
        port: testAccount.smtp.port,
        secure: testAccount.smtp.secure,
        auth: {
          user: testAccount.user,
          pass: testAccount.pass,
        },
      });

      this.logger.info('Ethereal Email account created for testing', {
        user: testAccount.user,
        previewUrl: testAccount.web
      });
    } catch (error) {
      this.logger.error('Failed to create Ethereal test account', error);
      // Fallback to console logging
      this.transporter = null;
    }
  }

  /**
   * Setup production email with real SMTP
   */
  private async setupProductionEmail(): Promise<void> {
    if (!config.SMTP_HOST || !config.SMTP_USER || !config.SMTP_PASS) {
      throw new Error('SMTP configuration missing in production environment');
    }

    this.transporter = nodemailer.createTransporter({
      host: config.SMTP_HOST,
      port: config.SMTP_PORT,
      secure: config.SMTP_SECURE,
      auth: {
        user: config.SMTP_USER,
        pass: config.SMTP_PASS,
      },
    });

    // Verify connection
    await this.transporter.verify();
    this.logger.info('Production SMTP connection verified');
  }

  /**
   * Send email verification email
   */
  async sendVerificationEmail(email: string, name: string, token: string): Promise<void> {
    const verificationUrl = `${this.clientUrl}/auth/verify-email?token=${token}`;
    
    const template = this.getVerificationEmailTemplate(name, verificationUrl);
    
    await this.sendEmail({
      to: email,
      subject: template.subject,
      html: template.html,
      text: template.text
    });

    this.logger.info('Email verification sent', { email, name });
  }

  /**
   * Send password reset email
   */
  async sendPasswordResetEmail(email: string, name: string, token: string): Promise<void> {
    const resetUrl = `${this.clientUrl}/auth/reset-password?token=${token}`;
    
    const template = this.getPasswordResetEmailTemplate(name, resetUrl);
    
    await this.sendEmail({
      to: email,
      subject: template.subject,
      html: template.html,
      text: template.text
    });

    this.logger.info('Password reset email sent', { email, name });
  }

  /**
   * Send welcome email
   */
  async sendWelcomeEmail(email: string, name: string): Promise<void> {
    const template = this.getWelcomeEmailTemplate(name);
    
    await this.sendEmail({
      to: email,
      subject: template.subject,
      html: template.html,
      text: template.text
    });

    this.logger.info('Welcome email sent', { email, name });
  }

  /**
   * Generic email sending method
   */
  private async sendEmail(options: {
    to: string;
    subject: string;
    html: string;
    text: string;
  }): Promise<void> {
    if (!this.isInitialized) {
      throw new Error('Email service not initialized');
    }

    if (!this.transporter) {
      // Fallback: Log email to console in development
      this.logger.info('📧 Email would be sent (Console fallback)', {
        to: options.to,
        subject: options.subject,
        text: options.text
      });
      return;
    }

    const mailOptions: SendMailOptions = {
      from: `"${this.fromName}" <${this.fromEmail}>`,
      to: options.to,
      subject: options.subject,
      html: options.html,
      text: options.text,
    };

    try {
      const info = await this.transporter.sendMail(mailOptions);
      
      if (config.NODE_ENV === 'development') {
        // Show preview URL for Ethereal emails
        const previewUrl = nodemailer.getTestMessageUrl(info);
        if (previewUrl) {
          this.logger.info('📧 Email sent - Preview URL:', { 
            messageId: info.messageId,
            previewUrl 
          });
        }
      } else {
        this.logger.info('📧 Email sent successfully', { 
          messageId: info.messageId,
          to: options.to 
        });
      }
    } catch (error) {
      this.logger.error('Failed to send email', error);
      throw error;
    }
  }

  /**
   * Email verification template
   */
  private getVerificationEmailTemplate(name: string, verificationUrl: string): EmailTemplate {
    return {
      subject: '📧 Paperly 이메일 인증',
      html: `
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <style>
              body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { text-align: center; padding: 20px 0; border-bottom: 1px solid #eee; }
              .content { padding: 30px 0; }
              .button { display: inline-block; padding: 12px 24px; background: #90A990; color: white; text-decoration: none; border-radius: 6px; margin: 20px 0; }
              .footer { text-align: center; padding: 20px 0; border-top: 1px solid #eee; font-size: 14px; color: #666; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1 style="color: #90A990; margin: 0;">📚 Paperly</h1>
              </div>
              
              <div class="content">
                <h2>안녕하세요, ${name}님!</h2>
                <p>Paperly에 가입해 주셔서 감사합니다. 아래 버튼을 클릭하여 이메일 주소를 인증해 주세요.</p>
                
                <div style="text-align: center;">
                  <a href="${verificationUrl}" class="button">이메일 인증하기</a>
                </div>
                
                <p>버튼이 작동하지 않는다면 아래 링크를 복사해서 브라우저에 붙여넣어 주세요:</p>
                <p style="word-break: break-all; background: #f5f5f5; padding: 10px; border-radius: 4px;">
                  ${verificationUrl}
                </p>
                
                <p>이 인증 링크는 24시간 후에 만료됩니다.</p>
              </div>
              
              <div class="footer">
                <p>이 이메일을 요청하지 않으셨다면 무시하시기 바랍니다.</p>
                <p>© ${new Date().getFullYear()} Paperly. All rights reserved.</p>
              </div>
            </div>
          </body>
        </html>
      `,
      text: `
안녕하세요, ${name}님!

Paperly에 가입해 주셔서 감사합니다. 아래 링크를 클릭하여 이메일 주소를 인증해 주세요.

${verificationUrl}

이 인증 링크는 24시간 후에 만료됩니다.

이 이메일을 요청하지 않으셨다면 무시하시기 바랍니다.

© ${new Date().getFullYear()} Paperly. All rights reserved.
      `
    };
  }

  /**
   * Password reset email template
   */
  private getPasswordResetEmailTemplate(name: string, resetUrl: string): EmailTemplate {
    return {
      subject: '🔐 Paperly 비밀번호 재설정',
      html: `
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <style>
              body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { text-align: center; padding: 20px 0; border-bottom: 1px solid #eee; }
              .content { padding: 30px 0; }
              .button { display: inline-block; padding: 12px 24px; background: #D4A09A; color: white; text-decoration: none; border-radius: 6px; margin: 20px 0; }
              .footer { text-align: center; padding: 20px 0; border-top: 1px solid #eee; font-size: 14px; color: #666; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1 style="color: #90A990; margin: 0;">📚 Paperly</h1>
              </div>
              
              <div class="content">
                <h2>비밀번호 재설정 요청</h2>
                <p>안녕하세요, ${name}님!</p>
                <p>Paperly 계정의 비밀번호 재설정을 요청하셨습니다. 아래 버튼을 클릭하여 새로운 비밀번호를 설정해 주세요.</p>
                
                <div style="text-align: center;">
                  <a href="${resetUrl}" class="button">비밀번호 재설정</a>
                </div>
                
                <p>버튼이 작동하지 않는다면 아래 링크를 복사해서 브라우저에 붙여넣어 주세요:</p>
                <p style="word-break: break-all; background: #f5f5f5; padding: 10px; border-radius: 4px;">
                  ${resetUrl}
                </p>
                
                <p>이 링크는 1시간 후에 만료됩니다.</p>
              </div>
              
              <div class="footer">
                <p>이 이메일을 요청하지 않으셨다면 무시하시기 바랍니다.</p>
                <p>© ${new Date().getFullYear()} Paperly. All rights reserved.</p>
              </div>
            </div>
          </body>
        </html>
      `,
      text: `
비밀번호 재설정 요청

안녕하세요, ${name}님!

Paperly 계정의 비밀번호 재설정을 요청하셨습니다. 아래 링크를 클릭하여 새로운 비밀번호를 설정해 주세요.

${resetUrl}

이 링크는 1시간 후에 만료됩니다.

이 이메일을 요청하지 않으셨다면 무시하시기 바랍니다.

© ${new Date().getFullYear()} Paperly. All rights reserved.
      `
    };
  }

  /**
   * Welcome email template
   */
  private getWelcomeEmailTemplate(name: string): EmailTemplate {
    return {
      subject: '🎉 Paperly에 오신 것을 환영합니다!',
      html: `
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <style>
              body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { text-align: center; padding: 20px 0; border-bottom: 1px solid #eee; }
              .content { padding: 30px 0; }
              .button { display: inline-block; padding: 12px 24px; background: #90A990; color: white; text-decoration: none; border-radius: 6px; margin: 20px 0; }
              .footer { text-align: center; padding: 20px 0; border-top: 1px solid #eee; font-size: 14px; color: #666; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1 style="color: #90A990; margin: 0;">📚 Paperly</h1>
              </div>
              
              <div class="content">
                <h2>환영합니다, ${name}님! 🎉</h2>
                <p>Paperly 회원가입이 완료되었습니다. 이제 개인화된 아티클 추천 서비스를 이용하실 수 있습니다.</p>
                
                <h3>Paperly에서 할 수 있는 것들:</h3>
                <ul>
                  <li>📖 AI 기반 개인화된 아티클 추천</li>
                  <li>📑 관심 있는 아티클 북마크</li>
                  <li>💡 아티클에 하이라이트와 메모 추가</li>
                  <li>📊 읽기 통계와 진도 추적</li>
                </ul>
                
                <div style="text-align: center;">
                  <a href="${this.clientUrl}" class="button">Paperly 시작하기</a>
                </div>
                
                <p>궁금한 점이 있으시면 언제든지 문의해 주세요. 즐거운 독서 여행을 시작하세요!</p>
              </div>
              
              <div class="footer">
                <p>© ${new Date().getFullYear()} Paperly. All rights reserved.</p>
              </div>
            </div>
          </body>
        </html>
      `,
      text: `
환영합니다, ${name}님! 🎉

Paperly 회원가입이 완료되었습니다. 이제 개인화된 아티클 추천 서비스를 이용하실 수 있습니다.

Paperly에서 할 수 있는 것들:
- AI 기반 개인화된 아티클 추천
- 관심 있는 아티클 북마크
- 아티클에 하이라이트와 메모 추가
- 읽기 통계와 진도 추적

지금 바로 시작하세요: ${this.clientUrl}

궁금한 점이 있으시면 언제든지 문의해 주세요. 즐거운 독서 여행을 시작하세요!

© ${new Date().getFullYear()} Paperly. All rights reserved.
      `
    };
  }
}