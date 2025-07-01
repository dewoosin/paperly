import { Router } from 'express';
import { container } from 'tsyringe';
import { Logger } from '../../logging/Logger';
import { AuthController } from '../controllers/auth.controller';
import { authMiddleware } from '../middleware/auth.middleware';
import { strictRateLimiter, apiRateLimiter } from '../middleware/rate-limiter.middleware';
import { requireWriterClient } from '../middleware/client-auth.middleware';
import { errorHandler, notFoundHandler } from '../middleware/error-handler.middleware';

const logger = new Logger('WriterRoutes');
const router = Router();

interface Controller {
  router: Router;
}

// Writer Auth Routes - Authentication for writer app
const authRouter = Router();

function setupWriterAuthRoutes(): Router {
  const authController = container.resolve(AuthController);
  return authController.router;
}

authRouter.use('/', (req, res, next) => {
  try {
    const writerAuthRouter = setupWriterAuthRoutes();
    writerAuthRouter(req, res, next);
  } catch (error) {
    logger.error('Writer auth route setup failed:', error);
    next(error);
  }
});

// Writer Profile Routes
const profileRouter = Router();

function setupWriterProfileRoutes(): Router {
  try {
    const { WriterController } = require('../controllers/writer.controller');
    const writerController = container.resolve(WriterController) as Controller;
    return writerController.router;
  } catch (error) {
    logger.error('Writer profile controller setup failed:', error);
    throw error;
  }
}

profileRouter.use('/', (req, res, next) => {
  try {
    const writerProfileRouter = setupWriterProfileRoutes();
    writerProfileRouter(req, res, next);
  } catch (error) {
    logger.error('Writer profile route setup failed:', error);
    next(error);
  }
});

// Writer Articles Routes - Full CRUD for writer's own articles
const articlesRouter = Router();

function setupWriterArticleRoutes(): Router {
  try {
    const { WriterArticleController } = require('../controllers/writer-article.controller');
    const writerArticleController = container.resolve(WriterArticleController) as Controller;
    return writerArticleController.router;
  } catch (error) {
    logger.error('Writer article controller setup failed:', error);
    throw error;
  }
}

articlesRouter.use('/', (req, res, next) => {
  try {
    const writerArticleRouter = setupWriterArticleRoutes();
    writerArticleRouter(req, res, next);
  } catch (error) {
    logger.error('Writer article route setup failed:', error);
    next(error);
  }
});

// Writer Analytics Routes
const analyticsRouter = Router();

analyticsRouter.get('/overview', authMiddleware, (req, res) => {
  res.json({ message: 'Get writer analytics overview', user: req.user });
});

analyticsRouter.get('/articles/:id/stats', authMiddleware, (req, res) => {
  res.json({ message: 'Get article statistics', articleId: req.params.id, user: req.user });
});

analyticsRouter.get('/engagement', authMiddleware, (req, res) => {
  res.json({ message: 'Get writer engagement metrics', user: req.user });
});

analyticsRouter.get('/revenue', authMiddleware, (req, res) => {
  res.json({ message: 'Get writer revenue data', user: req.user });
});

// Writer Dashboard Routes - Enhanced metrics for dashboard
const dashboardRouter = Router();

function setupWriterDashboardRoutes(): Router {
  try {
    const { WriterDashboardController } = require('../controllers/writer-dashboard.controller');
    const dashboardController = container.resolve(WriterDashboardController) as Controller;
    return dashboardController.router;
  } catch (error) {
    logger.error('Writer dashboard controller setup failed:', error);
    throw error;
  }
}

dashboardRouter.use('/', (req, res, next) => {
  try {
    const writerDashboardRouter = setupWriterDashboardRoutes();
    writerDashboardRouter(req, res, next);
  } catch (error) {
    logger.error('Writer dashboard route setup failed:', error);
    next(error);
  }
});

// Writer Categories Routes - Read-only access to categories
const categoriesRouter = Router();

function setupWriterCategoryRoutes(): Router {
  try {
    const { CategoryController } = require('../controllers/category.controller');
    const categoryController = container.resolve(CategoryController) as Controller;
    return categoryController.router;
  } catch (error) {
    logger.error('Writer category controller setup failed:', error);
    throw error;
  }
}

categoriesRouter.use('/', (req, res, next) => {
  try {
    const writerCategoryRouter = setupWriterCategoryRoutes();
    writerCategoryRouter(req, res, next);
  } catch (error) {
    logger.error('Writer category route setup failed:', error);
    next(error);
  }
});

// Writer Drafts Routes
const draftsRouter = Router();

draftsRouter.get('/', authMiddleware, (req, res) => {
  res.json({ message: 'Get writer drafts', user: req.user });
});

draftsRouter.post('/', authMiddleware, (req, res) => {
  res.json({ message: 'Create new draft', user: req.user });
});

draftsRouter.put('/:id', authMiddleware, (req, res) => {
  res.json({ message: 'Update draft', draftId: req.params.id, user: req.user });
});

draftsRouter.delete('/:id', authMiddleware, (req, res) => {
  res.json({ message: 'Delete draft', draftId: req.params.id, user: req.user });
});

draftsRouter.post('/:id/autosave', authMiddleware, (req, res) => {
  res.json({ message: 'Autosave draft', draftId: req.params.id, user: req.user });
});

// Writer API Info
router.get('/', (req, res) => {
  res.json({
    name: 'Paperly Writer API',
    version: '1.0.0',
    client: 'writer',
    status: 'running',
    timestamp: new Date().toISOString(),
  });
});

// Apply writer client validation to all routes
router.use(requireWriterClient);

// Register writer-specific routes
router.use('/auth', strictRateLimiter, authRouter);
router.use('/profile', apiRateLimiter, authMiddleware, profileRouter);
router.use('/articles', apiRateLimiter, articlesRouter); // Auth handled in controller
router.use('/analytics', apiRateLimiter, authMiddleware, analyticsRouter);
router.use('/dashboard', apiRateLimiter, authMiddleware, dashboardRouter);
router.use('/categories', apiRateLimiter, categoriesRouter);
router.use('/drafts', apiRateLimiter, authMiddleware, draftsRouter);

// Error handling
router.use(notFoundHandler);
router.use(errorHandler);

logger.info('Writer API routes initialized with client validation and error handling');

export { router as writerRouter };