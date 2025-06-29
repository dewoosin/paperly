import { Pool } from 'pg';
import { MESSAGE_CODES, MessageCode, MessageCodeInfo, MessageType } from '../../shared/constants/message-codes';

export interface MessageServiceInterface {
  getMessage(code: string, lang?: 'ko' | 'en'): Promise<string>;
  getMessageInfo(code: string): Promise<MessageCodeInfo | null>;
  formatMessage(code: string, params?: Record<string, any>, lang?: 'ko' | 'en'): Promise<string>;
}

export class MessageService implements MessageServiceInterface {
  private messageCache: Map<string, MessageCodeInfo> = new Map();
  private cacheExpiry: number = 3600000; // 1 hour
  private lastCacheUpdate: number = 0;

  constructor(private pool: Pool) {}

  /**
   * 메시지 코드로 메시지 텍스트를 가져옴
   */
  async getMessage(code: string, lang: 'ko' | 'en' = 'ko'): Promise<string> {
    const messageInfo = await this.getMessageInfo(code);
    if (!messageInfo) {
      // 메시지 코드가 없으면 기본 메시지 반환
      return lang === 'ko' ? '알 수 없는 오류가 발생했습니다' : 'An unknown error occurred';
    }
    return lang === 'ko' ? messageInfo.messageKo : messageInfo.messageEn;
  }

  /**
   * 메시지 코드의 전체 정보를 가져옴
   */
  async getMessageInfo(code: string): Promise<MessageCodeInfo | null> {
    // 캐시 확인
    if (this.isCacheValid() && this.messageCache.has(code)) {
      return this.messageCache.get(code) || null;
    }

    try {
      const query = `
        SELECT code, type, category, message_ko, message_en, http_status_code
        FROM paperly.message_codes
        WHERE code = $1
      `;
      const result = await this.pool.query(query, [code]);

      if (result.rows.length === 0) {
        return null;
      }

      const row = result.rows[0];
      const messageInfo: MessageCodeInfo = {
        code: row.code,
        type: row.type as MessageType,
        category: row.category,
        messageKo: row.message_ko,
        messageEn: row.message_en,
        httpStatusCode: row.http_status_code,
      };

      // 캐시에 저장
      this.messageCache.set(code, messageInfo);
      return messageInfo;
    } catch (error) {
      console.error('Error fetching message:', error);
      return null;
    }
  }

  /**
   * 메시지에 파라미터를 포맷팅하여 반환
   * 예: "사용자 {{name}}님이 로그인했습니다" + {name: '홍길동'} => "사용자 홍길동님이 로그인했습니다"
   */
  async formatMessage(code: string, params?: Record<string, any>, lang: 'ko' | 'en' = 'ko'): Promise<string> {
    let message = await this.getMessage(code, lang);
    
    if (params) {
      Object.entries(params).forEach(([key, value]) => {
        message = message.replace(new RegExp(`{{${key}}}`, 'g'), String(value));
      });
    }
    
    return message;
  }

  /**
   * 캐시 유효성 확인
   */
  private isCacheValid(): boolean {
    return Date.now() - this.lastCacheUpdate < this.cacheExpiry;
  }

  /**
   * 캐시 새로고침
   */
  async refreshCache(): Promise<void> {
    try {
      const query = `
        SELECT code, type, category, message_ko, message_en, http_status_code
        FROM paperly.message_codes
      `;
      const result = await this.pool.query(query);

      this.messageCache.clear();
      result.rows.forEach(row => {
        const messageInfo: MessageCodeInfo = {
          code: row.code,
          type: row.type as MessageType,
          category: row.category,
          messageKo: row.message_ko,
          messageEn: row.message_en,
          httpStatusCode: row.http_status_code,
        };
        this.messageCache.set(row.code, messageInfo);
      });

      this.lastCacheUpdate = Date.now();
    } catch (error) {
      console.error('Error refreshing message cache:', error);
    }
  }

  /**
   * 응답 포맷 생성 헬퍼
   */
  async createResponse(code: string, data?: any, params?: Record<string, any>, lang: 'ko' | 'en' = 'ko') {
    const messageInfo = await this.getMessageInfo(code);
    const message = params 
      ? await this.formatMessage(code, params, lang)
      : await this.getMessage(code, lang);

    if (!messageInfo) {
      return {
        success: false,
        code: 'SYSTEM_001',
        message: lang === 'ko' ? '시스템 오류가 발생했습니다' : 'System error occurred',
        data,
      };
    }

    const isSuccess = messageInfo.type === MessageType.SUCCESS || messageInfo.type === MessageType.INFO;

    return {
      success: isSuccess,
      code: messageInfo.code,
      type: messageInfo.type,
      message,
      data,
    };
  }

  /**
   * 에러 응답 생성 헬퍼
   */
  async createErrorResponse(code: string, params?: Record<string, any>, lang: 'ko' | 'en' = 'ko') {
    const messageInfo = await this.getMessageInfo(code);
    const message = params 
      ? await this.formatMessage(code, params, lang)
      : await this.getMessage(code, lang);

    return {
      success: false,
      error: {
        code: messageInfo?.code || 'SYSTEM_001',
        type: messageInfo?.type || MessageType.ERROR,
        message,
      },
    };
  }
}

// 싱글톤 인스턴스를 위한 변수
let messageServiceInstance: MessageService | null = null;

/**
 * MessageService 싱글톤 인스턴스 생성/반환
 */
export function createMessageService(pool: Pool): MessageService {
  if (!messageServiceInstance) {
    messageServiceInstance = new MessageService(pool);
    // 초기 캐시 로드
    messageServiceInstance.refreshCache();
  }
  return messageServiceInstance;
}