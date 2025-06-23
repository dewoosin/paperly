// apps/backend/src/application/use-cases/auth/refresh-token.use-case.ts

import { inject, injectable } from 'tsyringe';
import { z } from 'zod';
import { UseCase } from '../../../shared/application/use-case';
import { ITokenService } from '../../../domain/services/token.service';
import { IRefreshTokenRepository } from '../../../domain/repositories/refresh-token.repository';
import { Token } from '../../../domain/value-objects/auth.value-objects';
import { AppError, ErrorCode } from '../../../shared/errors/app-error';
import { logger } from '../../../infrastructure/logging/logger';

const RefreshTokenInputSchema = z.object({
  refreshToken: z.string()
});

export type RefreshTokenInput = z.infer<typeof RefreshTokenInputSchema>;

export interface RefreshTokenOutput {
  accessToken: string;
  refreshToken: string;
}

/**
 * 토큰 갱신 유스케이스
 */
@injectable()
export class RefreshTokenUseCase implements UseCase<RefreshTokenInput, RefreshTokenOutput> {
  constructor(
    @inject('TokenService') private tokenService: ITokenService,
    @inject('RefreshTokenRepository') private refreshTokenRepository: IRefreshTokenRepository
  ) {}

  async execute(input: RefreshTokenInput): Promise<RefreshTokenOutput> {
    const validatedInput = RefreshTokenInputSchema.parse(input);
    
    logger.info('토큰 갱신 시도');

    try {
      const token = Token.create(validatedInput.refreshToken);
      
      // 1. Refresh Token 검증 및 새 토큰 발급
      const newTokens = await this.tokenService.refreshTokens(token);

      logger.info('토큰 갱신 완료');

      return {
        accessToken: newTokens.accessToken,
        refreshToken: newTokens.refreshToken
      };

    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      
      logger.error('토큰 갱신 실패', { error });
      throw new AppError(
        ErrorCode.UNAUTHORIZED,
        '토큰 갱신에 실패했습니다'
      );
    }
  }
}
