import { Router, Request, Response, NextFunction } from 'express';
import { inject, injectable } from 'tsyringe';
import { Logger } from '../../logging/Logger';
import { ResponseUtil } from '../../../shared/utils/response.util';
import { MESSAGE_CODES } from '../../../shared/constants/message-codes';

/**
 * 사용자 온보딩 컨트롤러
 * 신규 사용자의 관심사 설정 및 개인화 프로세스를 관리합니다.
 */
@injectable()
export class OnboardingController {
  public readonly router: Router;
  private readonly logger = new Logger('OnboardingController');

  constructor(
    @inject('ResponseUtil') private responseUtil: ResponseUtil
  ) {
    this.router = Router();
    this.setupRoutes();
  }

  private setupRoutes() {
    // 온보딩 진행 상황 조회
    this.router.get('/status', this.getOnboardingStatus.bind(this));
    this.router.get('/steps', this.getOnboardingSteps.bind(this));
    
    // 온보딩 단계별 처리
    this.router.post('/interests', this.setInterests.bind(this));
    this.router.post('/reading-preferences', this.setReadingPreferences.bind(this));
    this.router.post('/ai-consent', this.setAiConsent.bind(this));
    this.router.post('/complete', this.completeOnboarding.bind(this));
    
    // 온보딩 건너뛰기 및 재시작
    this.router.post('/skip', this.skipOnboarding.bind(this));
    this.router.post('/restart', this.restartOnboarding.bind(this));
  }

  /**
   * 온보딩 진행 상황 조회
   * GET /api/onboarding/status
   */
  private async getOnboardingStatus(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId;

      if (!userId) {
        return this.responseUtil.authError(res);
      }

      // TODO: OnboardingService 구현 후 실제 로직 연결
      // const status = await this.onboardingService.getOnboardingStatus(userId);

      // 임시 응답
      const status = {
        userId,
        isCompleted: false,
        completedSteps: ['ai_consent'],
        currentStep: 'interests_selection',
        progress: 25,
        estimatedTimeRemaining: 8
      };

      return this.responseUtil.success(res, MESSAGE_CODES.SYSTEM.RESOURCE_NOT_FOUND, status, undefined, 200);
    } catch (error) {
      next(error);
    }
  }

  /**
   * 온보딩 단계 정보 조회
   * GET /api/onboarding/steps
   */
  private async getOnboardingSteps(req: Request, res: Response, next: NextFunction) {
    try {
      // 온보딩 단계별 가이드 정보
      const steps = [
        {
          stepName: 'ai_consent',
          stepTitle: 'AI 개인화 동의',
          description: 'AI 기반 맞춤 추천을 위한 데이터 사용에 동의해주세요.',
          order: 1,
          isRequired: true,
          estimatedTimeMinutes: 1
        },
        {
          stepName: 'interests_selection',
          stepTitle: '관심사 선택',
          description: '관심 있는 주제를 선택해주세요. 더 정확한 추천을 위해 최소 3개 이상 선택해주세요.',
          order: 2,
          isRequired: true,
          estimatedTimeMinutes: 3,
          minimumSelections: 3,
          maximumSelections: 10
        },
        {
          stepName: 'reading_preferences',
          stepTitle: '읽기 선호도 설정',
          description: '선호하는 글의 길이, 난이도, 읽기 시간대를 설정해주세요.',
          order: 3,
          isRequired: false,
          estimatedTimeMinutes: 2
        },
        {
          stepName: 'final_setup',
          stepTitle: '최종 설정',
          description: '알림 설정 및 추가 개인화 옵션을 설정해주세요.',
          order: 4,
          isRequired: false,
          estimatedTimeMinutes: 2
        }
      ];

      return this.responseUtil.success(res, MESSAGE_CODES.SYSTEM.RESOURCE_NOT_FOUND, steps, undefined, 200);
    } catch (error) {
      next(error);
    }
  }

  /**
   * 관심사 설정
   * POST /api/onboarding/interests
   */
  private async setInterests(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId;

      if (!userId) {
        return this.responseUtil.authError(res);
      }

      const { categoryIds, tagNames, customInterests } = req.body;

      // 유효성 검사
      if (!categoryIds || !Array.isArray(categoryIds) || categoryIds.length < 3) {
        return this.responseUtil.error(res, MESSAGE_CODES.ONBOARDING.MINIMUM_INTERESTS_REQUIRED);
      }

      // TODO: OnboardingService 구현 후 실제 로직 연결
      // const result = await this.onboardingService.setUserInterests({
      //   userId,
      //   categoryIds,
      //   tagNames: tagNames || [],
      //   customInterests: customInterests || []
      // });

      // 임시 응답
      const result = {
        stepCompleted: 'interests_selection',
        nextStep: 'reading_preferences',
        selectedCount: categoryIds.length
      };

      this.logger.info('사용자 관심사 설정 완료', { 
        userId, 
        categoryCount: categoryIds.length, 
        tagCount: tagNames?.length || 0 
      });

      return this.responseUtil.success(res, MESSAGE_CODES.ONBOARDING.INTERESTS_SAVED, result);
    } catch (error) {
      next(error);
    }
  }

  /**
   * 읽기 선호도 설정
   * POST /api/onboarding/reading-preferences
   */
  private async setReadingPreferences(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId;

      if (!userId) {
        return this.responseUtil.authError(res);
      }

      const { 
        preferredLength, 
        difficulty, 
        readingTimeSlots,
        dailyReadingGoal,
        preferredTopics
      } = req.body;

      // TODO: OnboardingService 구현 후 실제 로직 연결
      // const result = await this.onboardingService.setReadingPreferences({
      //   userId,
      //   preferredLength,
      //   difficulty,
      //   readingTimeSlots: readingTimeSlots || [],
      //   dailyReadingGoal: dailyReadingGoal || 15,
      //   preferredTopics: preferredTopics || []
      // });

      // 임시 응답
      const result = {
        stepCompleted: 'reading_preferences',
        nextStep: 'final_setup',
        preferences: {
          preferredLength,
          difficulty,
          dailyGoal: dailyReadingGoal || 15
        }
      };

      this.logger.info('읽기 선호도 설정 완료', { userId, preferences: result.preferences });

      return this.responseUtil.success(res, MESSAGE_CODES.USER.PROFILE_UPDATED, result);
    } catch (error) {
      next(error);
    }
  }

  /**
   * AI 개인화 동의 설정
   * POST /api/onboarding/ai-consent
   */
  private async setAiConsent(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId;

      if (!userId) {
        return this.responseUtil.authError(res);
      }

      const { aiPersonalizationConsent, dataCollectionConsent } = req.body;

      // 필수 동의 체크
      if (!aiPersonalizationConsent) {
        return this.responseUtil.error(res, MESSAGE_CODES.VALIDATION.REQUIRED_FIELD_MISSING, {
          aiConsent: 'AI 개인화 서비스 이용을 위해서는 동의가 필요합니다.'
        });
      }

      // TODO: OnboardingService 구현 후 실제 로직 연결
      // const result = await this.onboardingService.setAiConsent({
      //   userId,
      //   aiPersonalizationConsent,
      //   dataCollectionConsent: dataCollectionConsent || false
      // });

      // 임시 응답
      const result = {
        stepCompleted: 'ai_consent',
        nextStep: 'interests_selection',
        consentData: {
          aiPersonalization: aiPersonalizationConsent,
          dataCollection: dataCollectionConsent || false,
          consentDate: new Date().toISOString()
        }
      };

      this.logger.info('AI 개인화 동의 설정 완료', { 
        userId, 
        aiConsent: aiPersonalizationConsent,
        dataConsent: dataCollectionConsent 
      });

      return this.responseUtil.success(res, MESSAGE_CODES.USER.PROFILE_UPDATED, result);
    } catch (error) {
      next(error);
    }
  }

  /**
   * 온보딩 완료
   * POST /api/onboarding/complete
   */
  private async completeOnboarding(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId;

      if (!userId) {
        return this.responseUtil.authError(res);
      }

      // TODO: OnboardingService 구현 후 실제 로직 연결
      // const result = await this.onboardingService.completeOnboarding(userId);

      // 임시 응답
      const result = {
        onboardingCompleted: true,
        completedAt: new Date().toISOString(),
        personalizedFeedReady: true,
        recommendationsEnabled: true
      };

      this.logger.info('온보딩 완료', { userId });

      return this.responseUtil.success(res, MESSAGE_CODES.ONBOARDING.COMPLETED, result);
    } catch (error) {
      next(error);
    }
  }

  /**
   * 온보딩 건너뛰기
   * POST /api/onboarding/skip
   */
  private async skipOnboarding(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId;

      if (!userId) {
        return this.responseUtil.authError(res);
      }

      // TODO: OnboardingService 구현 후 실제 로직 연결
      // const result = await this.onboardingService.skipOnboarding(userId);

      // 임시 응답
      const result = {
        onboardingSkipped: true,
        skippedAt: new Date().toISOString(),
        canRestartLater: true,
        defaultRecommendationsEnabled: true
      };

      this.logger.info('온보딩 건너뛰기', { userId });

      return this.responseUtil.success(res, MESSAGE_CODES.USER.PROFILE_UPDATED, result, {
        message: '온보딩을 건너뛰었습니다. 나중에 설정에서 변경할 수 있습니다.'
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * 온보딩 재시작
   * POST /api/onboarding/restart
   */
  private async restartOnboarding(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.userId;

      if (!userId) {
        return this.responseUtil.authError(res);
      }

      // TODO: OnboardingService 구현 후 실제 로직 연결
      // const result = await this.onboardingService.restartOnboarding(userId);

      // 임시 응답
      const result = {
        onboardingRestarted: true,
        restartedAt: new Date().toISOString(),
        currentStep: 'ai_consent',
        progress: 0
      };

      this.logger.info('온보딩 재시작', { userId });

      return this.responseUtil.success(res, MESSAGE_CODES.USER.PROFILE_UPDATED, result, {
        message: '온보딩이 재시작되었습니다.'
      });
    } catch (error) {
      next(error);
    }
  }
}