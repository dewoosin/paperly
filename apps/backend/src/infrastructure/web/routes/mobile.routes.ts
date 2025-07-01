import { Router } from 'express';
import { container } from 'tsyringe';
import { Logger } from '../../logging/Logger';
import { AuthController } from '../controllers/auth.controller';
import { authMiddleware } from '../middleware/auth.middleware';
import { strictRateLimiter, apiRateLimiter } from '../middleware/rate-limiter.middleware';
import { requireMobileClient } from '../middleware/client-auth.middleware';
import { errorHandler, notFoundHandler } from '../middleware/error-handler.middleware';

const logger = new Logger('MobileRoutes');
const router = Router();

interface Controller {
  router: Router;
}

// Mobile Auth Routes - Public endpoints for mobile app authentication
const authRouter = Router();

function setupMobileAuthRoutes(): Router {
  const authController = container.resolve(AuthController);
  return authController.router;
}

authRouter.use('/', (req, res, next) => {
  try {
    const mobileAuthRouter = setupMobileAuthRoutes();
    mobileAuthRouter(req, res, next);
  } catch (error) {
    logger.error('Mobile auth route setup failed:', error);
    next(error);
  }
});

// Mobile Articles Routes - Read-only article access for mobile
const articlesRouter = Router();

function setupMobileArticleRoutes(): Router {
  try {
    const { MobileArticleController } = require('../controllers/mobile-article.controller');
    const mobileArticleController = container.resolve(MobileArticleController) as Controller;
    return mobileArticleController.router;
  } catch (error) {
    logger.error('Mobile article controller setup failed:', error);
    throw error;
  }
}

articlesRouter.use('/', (req, res, next) => {
  try {
    const mobileArticleRouter = setupMobileArticleRoutes();
    mobileArticleRouter(req, res, next);
  } catch (error) {
    logger.error('Mobile article route setup failed:', error);
    next(error);
  }
});

// Mobile Categories Routes
const categoriesRouter = Router();

function setupMobileCategoryRoutes(): Router {
  try {
    const { CategoryController } = require('../controllers/category.controller');
    const categoryController = container.resolve(CategoryController) as Controller;
    return categoryController.router;
  } catch (error) {
    logger.error('Mobile category controller setup failed:', error);
    throw error;
  }
}

categoriesRouter.use('/', (req, res, next) => {
  try {
    const mobileCategoryRouter = setupMobileCategoryRoutes();
    mobileCategoryRouter(req, res, next);
  } catch (error) {
    logger.error('Mobile category route setup failed:', error);
    next(error);
  }
});

// Mobile Recommendations Routes
const recommendationsRouter = Router();

function setupMobileRecommendationRoutes(): Router {
  try {
    const { RecommendationController } = require('../controllers/recommendation.controller');
    const recommendationController = container.resolve(RecommendationController) as Controller;
    return recommendationController.router;
  } catch (error) {
    logger.error('Mobile recommendation controller setup failed:', error);
    throw error;
  }
}

recommendationsRouter.use('/', (req, res, next) => {
  try {
    const mobileRecommendationRouter = setupMobileRecommendationRoutes();
    mobileRecommendationRouter(req, res, next);
  } catch (error) {
    logger.error('Mobile recommendation route setup failed:', error);
    next(error);
  }
});

// Mobile Onboarding Routes
const onboardingRouter = Router();

function setupMobileOnboardingRoutes(): Router {
  try {
    const { OnboardingController } = require('../controllers/onboarding.controller');
    const onboardingController = container.resolve(OnboardingController) as Controller;
    return onboardingController.router;
  } catch (error) {
    logger.error('Mobile onboarding controller setup failed:', error);
    throw error;
  }
}

onboardingRouter.use('/', (req, res, next) => {
  try {
    const mobileOnboardingRouter = setupMobileOnboardingRoutes();
    mobileOnboardingRouter(req, res, next);
  } catch (error) {
    logger.error('Mobile onboarding route setup failed:', error);
    next(error);
  }
});

// Mobile User Routes - User profile and preferences
const userRouter = Router();

userRouter.get('/profile', authMiddleware(), (req, res) => {
  res.json({ message: 'Get mobile user profile', user: req.user });
});

userRouter.put('/profile', authMiddleware(), (req, res) => {
  res.json({ message: 'Update mobile user profile', user: req.user });
});

userRouter.get('/reading-history', authMiddleware(), (req, res) => {
  res.json({ message: 'Get mobile user reading history', user: req.user });
});

userRouter.get('/bookmarks', authMiddleware(), (req, res) => {
  res.json({ message: 'Get mobile user bookmarks', user: req.user });
});

userRouter.post('/bookmarks/:articleId', authMiddleware(), (req, res) => {
  res.json({ message: 'Add bookmark', articleId: req.params.articleId, user: req.user });
});

userRouter.delete('/bookmarks/:articleId', authMiddleware(), (req, res) => {
  res.json({ message: 'Remove bookmark', articleId: req.params.articleId, user: req.user });
});

// Mobile API Info
router.get('/', (req, res) => {
  res.json({
    name: 'Paperly Mobile API',
    version: '1.0.0',
    client: 'mobile',
    status: 'running',
    timestamp: new Date().toISOString(),
  });
});

// Apply mobile client validation to all routes
router.use(requireMobileClient);

// Register mobile-specific routes
router.use('/auth', strictRateLimiter, authRouter);
router.use('/articles', apiRateLimiter, articlesRouter);
router.use('/categories', apiRateLimiter, categoriesRouter);
router.use('/recommendations', apiRateLimiter, recommendationsRouter);
router.use('/onboarding', apiRateLimiter, onboardingRouter);
router.use('/user', apiRateLimiter, userRouter);

// Error handling
router.use(notFoundHandler);
router.use(errorHandler);

logger.info('Mobile API routes initialized with client validation and error handling');

export { router as mobileRouter };