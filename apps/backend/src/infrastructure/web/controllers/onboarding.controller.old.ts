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
        isCompleted: false,
        currentStep: 'interests_selection',
        completedSteps: ['ai_consent'],
        totalSteps: 4,
        progressPercentage: 25,
        steps: [
          {
            stepName: 'ai_consent',
            stepTitle: 'AI 개인화 동의',
            isCompleted: true,
            completedAt: '2024-01-01T00:00:00Z'
          },
          {
            stepName: 'interests_selection',
            stepTitle: '관심사 선택',
            isCompleted: false,
            completedAt: null
          },
          {
            stepName: 'reading_preferences',
            stepTitle: '읽기 선호도 설정',
            isCompleted: false,
            completedAt: null
          },
          {
            stepName: 'final_setup',
            stepTitle: '최종 설정',
            isCompleted: false,
            completedAt: null
          }
        ]
      };

      res.json({
        success: true,
        data: status
      });
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

      res.json({
        success: true,
        data: steps
      });
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
        return res.status(400).json({
          success: false,
          error: { 
            code: 'VALIDATION_ERROR', 
            message: '최소 3개 이상의 관심 카테고리를 선택해주세요.' 
          }
        });
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

      res.json({
        success: true,
        data: result,
        message: '관심사가 성공적으로 설정되었습니다.'
      });
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
        preferredArticleLength,
        difficultyLevel,
        readingTimeSlots,
        readingSpeed,
        contentTypes,
        readingGoals
      } = req.body;

      // TODO: OnboardingService 구현 후 실제 로직 연결
      // const result = await this.onboardingService.setReadingPreferences({
      //   userId,
      //   preferredArticleLength: preferredArticleLength || 'medium',
      //   difficultyLevel: difficultyLevel || 3,
      //   readingTimeSlots: readingTimeSlots || ['morning'],
      //   readingSpeed: readingSpeed || 200,
      //   contentTypes: contentTypes || ['article'],
      //   readingGoals: readingGoals || ['learn']
      // });

      // 임시 응답
      const result = {
        stepCompleted: 'reading_preferences',
        nextStep: 'final_setup',
        preferences: {
          preferredArticleLength,
          difficultyLevel,
          readingTimeSlots
        }
      };

      this.logger.info('사용자 읽기 선호도 설정 완료', { userId, preferredArticleLength, difficultyLevel });

      res.json({
        success: true,
        data: result,
        message: '읽기 선호도가 설정되었습니다.'
      });
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

      const { 
        aiConsent, 
        dataCollectionConsent, 
        marketingConsent,
        personalizedRecommendations 
      } = req.body;

      // AI 동의는 필수
      if (aiConsent !== true) {
        return res.status(400).json({
          success: false,
          error: { 
            code: 'VALIDATION_ERROR', 
            message: 'AI 개인화 서비스 이용을 위해서는 동의가 필요합니다.' 
          }
        });
      }

      // TODO: OnboardingService 구현 후 실제 로직 연결
      // const result = await this.onboardingService.setAiConsent({
      //   userId,
      //   aiConsent,
      //   dataCollectionConsent: dataCollectionConsent || false,
      //   marketingConsent: marketingConsent || false,
      //   personalizedRecommendations: personalizedRecommendations || true
      // });

      // 임시 응답
      const result = {
        stepCompleted: 'ai_consent',
        nextStep: 'interests_selection',
        consentSettings: {
          aiConsent,
          dataCollectionConsent,
          marketingConsent
        }
      };

      this.logger.info('사용자 AI 동의 설정 완료', { userId, aiConsent, dataCollectionConsent });

      res.json({
        success: true,
        data: result,
        message: 'AI 개인화 설정이 완료되었습니다.'
      });
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

      const { finalSettings } = req.body;

      // TODO: OnboardingService 구현 후 실제 로직 연결
      // const result = await this.onboardingService.completeOnboarding({
      //   userId,
      //   finalSettings: finalSettings || {}
      // });

      // 임시 응답
      const result = {
        onboardingCompleted: true,
        completedAt: new Date().toISOString(),
        totalStepsCompleted: 4,
        initialRecommendationsGenerated: true
      };

      this.logger.info('사용자 온보딩 완료', { userId });

      res.json({
        success: true,
        data: result,
        message: '온보딩이 완료되었습니다! 맞춤 추천을 시작합니다.'
      });
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
        onboardingCompleted: true,
        skipped: true,
        completedAt: new Date().toISOString(),
        defaultSettingsApplied: true
      };

      this.logger.info('사용자 온보딩 건너뛰기 완료', { userId });

      res.json({
        success: true,
        data: result,
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
        currentStep: 'ai_consent',
        previousDataCleared: true,
        restartedAt: new Date().toISOString()
      };

      this.logger.info('사용자 온보딩 재시작 완료', { userId });

      res.json({
        success: true,
        data: result,
        message: '온보딩이 재시작되었습니다.'
      });
    } catch (error) {
      next(error);
    }
  }
}