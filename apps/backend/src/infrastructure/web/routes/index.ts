import { Router } from 'express';
import { Logger } from '../../logging/Logger';
import { strictRateLimiter, apiRateLimiter } from '../middleware/rate-limiter.middleware';

const logger = new Logger('Routes');

export const apiRouter = Router();

// API Root - General API Information
apiRouter.get('/', (req, res) => {
  res.json({
    name: 'Paperly API',
    version: '1.0.0',
    status: 'running',
    timestamp: new Date().toISOString(),
    endpoints: {
      mobile: '/api/mobile/',
      writer: '/api/writer/',
      admin: '/api/admin/'
    }
  });
});

// Client-Specific Route Modules
function setupMobileRoutes(): Router {
  try {
    const { mobileRouter } = require('./mobile.routes');
    return mobileRouter;
  } catch (error) {
    logger.error('Mobile route setup failed:', error);
    throw error;
  }
}

function setupWriterRoutes(): Router {
  try {
    const { writerRouter } = require('./writer.routes');
    return writerRouter;
  } catch (error) {
    logger.error('Writer route setup failed:', error);
    throw error;
  }
}

function setupAdminRoutes(): Router {
  try {
    const { adminRouter } = require('./admin.routes');
    return adminRouter;
  } catch (error) {
    logger.error('Admin route setup failed:', error);
    throw error;
  }
}

// Register client-specific routes with lazy loading and rate limiting
apiRouter.use('/mobile', apiRateLimiter, (req, res, next) => {
  try {
    const mobileRoutes = setupMobileRoutes();
    mobileRoutes(req, res, next);
  } catch (error) {
    logger.error('Mobile route setup failed:', error);
    next(error);
  }
});

apiRouter.use('/writer', apiRateLimiter, (req, res, next) => {
  try {
    const writerRoutes = setupWriterRoutes();
    writerRoutes(req, res, next);
  } catch (error) {
    logger.error('Writer route setup failed:', error);
    next(error);
  }
});

apiRouter.use('/admin', apiRateLimiter, (req, res, next) => {
  try {
    const adminRoutes = setupAdminRoutes();
    adminRoutes(req, res, next);
  } catch (error) {
    logger.error('Admin route setup failed:', error);
    next(error);
  }
});

// Backward compatibility routes (deprecated - will be removed in future versions)
// These maintain the old endpoints for gradual migration
const setupLegacyRoutes = () => {
  logger.warn('Loading legacy routes for backward compatibility - these will be deprecated');
  
  // Legacy auth routes
  function setupAuthRoutes(): Router {
    try {
      const { container } = require('tsyringe');
      const { AuthController } = require('../controllers/auth.controller');
      const authController = container.resolve(AuthController);
      return authController.router;
    } catch (error) {
      logger.error('Legacy auth controller setup failed:', error);
      throw error;
    }
  }

  apiRouter.use('/auth', strictRateLimiter, (req, res, next) => {
    logger.warn('Legacy /auth endpoint used - please migrate to /mobile/auth or /writer/auth', {
      ip: req.ip,
      userAgent: req.get('User-Agent')
    });
    try {
      const authRouter = setupAuthRoutes();
      authRouter(req, res, next);
    } catch (error) {
      logger.error('Legacy auth route setup failed:', error);
      next(error);
    }
  });

  // Legacy article routes
  function setupArticleRoutes(): Router {
    try {
      const { container } = require('tsyringe');
      const ArticleController = require('../controllers/article.controller').ArticleController;
      const articleController = container.resolve(ArticleController);
      return articleController.router;
    } catch (error) {
      logger.error('Legacy article controller setup failed:', error);
      throw error;
    }
  }

  apiRouter.use('/articles', apiRateLimiter, (req, res, next) => {
    logger.warn('Legacy /articles endpoint used - please migrate to /mobile/articles', {
      ip: req.ip,
      userAgent: req.get('User-Agent')
    });
    try {
      const articleRouter = setupArticleRoutes();
      articleRouter(req, res, next);
    } catch (error) {
      logger.error('Legacy article route setup failed:', error);
      next(error);
    }
  });

  // Legacy category routes
  function setupCategoryRoutes(): Router {
    try {
      const { container } = require('tsyringe');
      const { CategoryController } = require('../controllers/category.controller');
      const categoryController = container.resolve(CategoryController);
      return categoryController.router;
    } catch (error) {
      logger.error('Legacy category controller setup failed:', error);
      throw error;
    }
  }

  apiRouter.use('/categories', apiRateLimiter, (req, res, next) => {
    logger.warn('Legacy /categories endpoint used - please migrate to /mobile/categories', {
      ip: req.ip,
      userAgent: req.get('User-Agent')
    });
    try {
      const categoryRouter = setupCategoryRoutes();
      categoryRouter(req, res, next);
    } catch (error) {
      logger.error('Legacy category route setup failed:', error);
      next(error);
    }
  });

  // Other legacy routes...
  function setupRecommendationRoutes(): Router {
    try {
      const { container } = require('tsyringe');
      const { RecommendationController } = require('../controllers/recommendation.controller');
      const recommendationController = container.resolve(RecommendationController);
      return recommendationController.router;
    } catch (error) {
      logger.error('Legacy recommendation controller setup failed:', error);
      throw error;
    }
  }

  apiRouter.use('/recommendations', apiRateLimiter, (req, res, next) => {
    logger.warn('Legacy /recommendations endpoint used - please migrate to /mobile/recommendations', {
      ip: req.ip,
      userAgent: req.get('User-Agent')
    });
    try {
      const recommendationRouter = setupRecommendationRoutes();
      recommendationRouter(req, res, next);
    } catch (error) {
      logger.error('Legacy recommendation route setup failed:', error);
      next(error);
    }
  });

  function setupOnboardingRoutes(): Router {
    try {
      const { container } = require('tsyringe');
      const { OnboardingController } = require('../controllers/onboarding.controller');
      const onboardingController = container.resolve(OnboardingController);
      return onboardingController.router;
    } catch (error) {
      logger.error('Legacy onboarding controller setup failed:', error);
      throw error;
    }
  }

  apiRouter.use('/onboarding', apiRateLimiter, (req, res, next) => {
    logger.warn('Legacy /onboarding endpoint used - please migrate to /mobile/onboarding', {
      ip: req.ip,
      userAgent: req.get('User-Agent')
    });
    try {
      const onboardingRouter = setupOnboardingRoutes();
      onboardingRouter(req, res, next);
    } catch (error) {
      logger.error('Legacy onboarding route setup failed:', error);
      next(error);
    }
  });
};

// Load legacy routes for backward compatibility
setupLegacyRoutes();

logger.info('API routes initialized with client-specific routing: Mobile, Writer, Admin + Legacy compatibility');