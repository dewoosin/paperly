// apps/backend/src/infrastructure/web/routes/index.ts

import { Router } from 'express';
import { container } from 'tsyringe';
import { Logger } from '../../logging/Logger';
import { AuthController } from '../controllers/auth.controller';

const logger = new Logger('Routes');

// Controller interface for type safety
interface Controller {
  router: Router;
}

export const apiRouter = Router();

/**
 * API 버전 및 상태 정보
 */
apiRouter.get('/', (req, res) => {
  res.json({
    name: 'Paperly API',
    version: '1.0.0',
    status: 'running',
    timestamp: new Date().toISOString(),
  });
});

/**
 * 실제 Auth 라우트 설정 (지연 로딩)
 */
function setupAuthRoutes(): Router {
  const authController = container.resolve(AuthController);
  return authController.router;
}

// 실제 Auth 라우트 등록 (지연 로딩으로 수정)
apiRouter.use('/auth', (req, res, next) => {
  try {
    const authRouter = setupAuthRoutes();
    authRouter(req, res, next);
  } catch (error) {
    logger.error('Auth route setup failed:', error);
    next(error);
  }
});

logger.info('API routes initialized with real Auth endpoints');

// TODO: Day 4 - User routes  
// apiRouter.use('/users', userRouter);

// Article routes
function setupArticleRoutes(): Router {
  try {
    const ArticleController = require('../controllers/article.controller').ArticleController;
    const articleController = container.resolve(ArticleController) as Controller;
    return articleController.router;
  } catch (error) {
    logger.error('Article controller setup failed:', error);
    throw error;
  }
}

apiRouter.use('/articles', (req, res, next) => {
  try {
    const articleRouter = setupArticleRoutes();
    articleRouter(req, res, next);
  } catch (error) {
    logger.error('Article route setup failed:', error);
    next(error);
  }
});

// Writer routes
function setupWriterRoutes(): Router {
  try {
    const { WriterController } = require('../controllers/writer.controller');
    const writerController = container.resolve(WriterController) as Controller;
    return writerController.router;
  } catch (error) {
    logger.error('Writer controller setup failed:', error);
    throw error;
  }
}

apiRouter.use('/writers', (req, res, next) => {
  try {
    const writerRouter = setupWriterRoutes();
    writerRouter(req, res, next);
  } catch (error) {
    logger.error('Writer route setup failed:', error);
    next(error);
  }
});

// Category routes
function setupCategoryRoutes(): Router {
  try {
    const { CategoryController } = require('../controllers/category.controller');
    const categoryController = container.resolve(CategoryController) as Controller;
    return categoryController.router;
  } catch (error) {
    logger.error('Category controller setup failed:', error);
    throw error;
  }
}

apiRouter.use('/categories', (req, res, next) => {
  try {
    const categoryRouter = setupCategoryRoutes();
    categoryRouter(req, res, next);
  } catch (error) {
    logger.error('Category route setup failed:', error);
    next(error);
  }
});

// Onboarding routes
function setupOnboardingRoutes(): Router {
  try {
    const { OnboardingController } = require('../controllers/onboarding.controller');
    const onboardingController = container.resolve(OnboardingController) as Controller;
    return onboardingController.router;
  } catch (error) {
    logger.error('Onboarding controller setup failed:', error);
    throw error;
  }
}

apiRouter.use('/onboarding', (req, res, next) => {
  try {
    const onboardingRouter = setupOnboardingRoutes();
    onboardingRouter(req, res, next);
  } catch (error) {
    logger.error('Onboarding route setup failed:', error);
    next(error);
  }
});

// Recommendation routes
function setupRecommendationRoutes(): Router {
  try {
    const { RecommendationController } = require('../controllers/recommendation.controller');
    const recommendationController = container.resolve(RecommendationController) as Controller;
    return recommendationController.router;
  } catch (error) {
    logger.error('Recommendation controller setup failed:', error);
    throw error;
  }
}

apiRouter.use('/recommendations', (req, res, next) => {
  try {
    const recommendationRouter = setupRecommendationRoutes();
    recommendationRouter(req, res, next);
  } catch (error) {
    logger.error('Recommendation route setup failed:', error);
    next(error);
  }
});

logger.info('All API routes initialized: Auth, Articles, Writers, Categories, Onboarding, Recommendations');

// Admin routes setup (관리자 라우트 설정)
function setupAdminRoutes(): Router {
  try {
    const { adminRouter } = require('./admin.routes');
    return adminRouter;
  } catch (error) {
    logger.error('Admin route setup failed:', error);
    throw error;
  }
}

apiRouter.use('/admin', (req, res, next) => {
  try {
    const adminRoutes = setupAdminRoutes();
    adminRoutes(req, res, next);
  } catch (error) {
    logger.error('Admin route setup failed:', error);
    next(error);
  }
});

logger.info('Admin routes initialized');