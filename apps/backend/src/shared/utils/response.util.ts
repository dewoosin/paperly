import { Response } from 'express';
import { MessageService } from '../../infrastructure/services/message.service';
import { MESSAGE_CODES } from '../constants/message-codes';

export interface ApiResponse<T = any> {
  success: boolean;
  code: string;
  message: string;
  data?: T;
  error?: {
    code: string;
    message: string;
    details?: any;
  };
}

export class ResponseUtil {
  constructor(private messageService: MessageService) {}

  /**
   * 성공 응답 전송
   */
  async success<T = any>(
    res: Response,
    code: string,
    data?: T,
    params?: Record<string, any>,
    statusCode?: number
  ): Promise<Response> {
    const messageInfo = await this.messageService.getMessageInfo(code);
    const message = params 
      ? await this.messageService.formatMessage(code, params, 'ko')
      : await this.messageService.getMessage(code, 'ko');

    const response: ApiResponse<T> = {
      success: true,
      code,
      message,
      data,
    };

    return res.status(statusCode || messageInfo?.httpStatusCode || 200).json(response);
  }

  /**
   * 에러 응답 전송
   */
  async error(
    res: Response,
    code: string,
    details?: any,
    params?: Record<string, any>,
    statusCode?: number
  ): Promise<Response> {
    const messageInfo = await this.messageService.getMessageInfo(code);
    const message = params 
      ? await this.messageService.formatMessage(code, params, 'ko')
      : await this.messageService.getMessage(code, 'ko');

    const response: ApiResponse = {
      success: false,
      code,
      message,
      error: {
        code,
        message,
        details,
      },
    };

    return res.status(statusCode || messageInfo?.httpStatusCode || 400).json(response);
  }

  /**
   * 유효성 검사 에러 응답
   */
  async validationError(
    res: Response,
    errors: Record<string, string>,
    code: string = MESSAGE_CODES.VALIDATION.REQUIRED_FIELD_MISSING
  ): Promise<Response> {
    const message = await this.messageService.getMessage(code, 'ko');

    const response: ApiResponse = {
      success: false,
      code,
      message,
      error: {
        code,
        message,
        details: errors,
      },
    };

    return res.status(400).json(response);
  }

  /**
   * 인증 에러 응답
   */
  async authError(
    res: Response,
    code: string = MESSAGE_CODES.AUTH.INVALID_TOKEN
  ): Promise<Response> {
    return this.error(res, code, undefined, undefined, 401);
  }

  /**
   * 권한 에러 응답
   */
  async forbiddenError(
    res: Response,
    code: string = MESSAGE_CODES.AUTH.ACCESS_DENIED
  ): Promise<Response> {
    return this.error(res, code, undefined, undefined, 403);
  }

  /**
   * Not Found 에러 응답
   */
  async notFoundError(
    res: Response,
    code: string = MESSAGE_CODES.SYSTEM.RESOURCE_NOT_FOUND
  ): Promise<Response> {
    return this.error(res, code, undefined, undefined, 404);
  }

  /**
   * 서버 에러 응답
   */
  async serverError(
    res: Response,
    error?: any,
    code: string = MESSAGE_CODES.SYSTEM.INTERNAL_ERROR
  ): Promise<Response> {
    console.error('Server error:', error);
    
    const details = process.env.NODE_ENV === 'development' 
      ? { stack: error?.stack, message: error?.message }
      : undefined;

    return this.error(res, code, details, undefined, 500);
  }
}

// 싱글톤 인스턴스
let responseUtilInstance: ResponseUtil | null = null;

export function createResponseUtil(messageService: MessageService): ResponseUtil {
  if (!responseUtilInstance) {
    responseUtilInstance = new ResponseUtil(messageService);
  }
  return responseUtilInstance;
}