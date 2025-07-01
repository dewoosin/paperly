import { Router } from 'express';
import { container } from 'tsyringe';
import { AdminAuthController } from '../controllers/admin-auth.controller';
import { SecurityMonitorController } from '../controllers/security-monitor.controller';
import { AdminArticleController } from '../controllers/admin-article.controller';
import { createAdminArticleRoutes } from './admin-article.routes';
import { authMiddleware } from '../middleware/auth.middleware';
import { 
  requireAdminRole, 
  requireSuperAdminRole, 
  requirePermissions 
} from '../middleware/admin-auth.middleware';
import { validateInput } from '../middleware/validation.middleware';
import { rateLimit } from 'express-rate-limit';
import { Logger } from '../../logging/Logger';
import { requireAdminClient } from '../middleware/client-auth.middleware';
import { errorHandler, notFoundHandler } from '../middleware/error-handler.middleware';

const logger = new Logger('AdminRoutes');
const router = Router();

interface Controller {
  router: Router;
}

// 관리자 컨트롤러 인스턴스 생성
const adminAuthController = container.resolve(AdminAuthController);
const securityMonitorController = container.resolve(SecurityMonitorController);
const adminArticleController = container.resolve(AdminArticleController);

// ============================================================================
// 🔐 관리자 인증 관련 라우트
// ============================================================================

// 관리자 로그인 (레이트 리미팅 적용)
const adminLoginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15분
  max: 5, // 15분 동안 최대 5번 시도
  message: {
    success: false,
    error: {
      code: 'TOO_MANY_ATTEMPTS',
      message: '너무 많은 로그인 시도입니다. 15분 후 다시 시도해주세요.'
    }
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// Admin API Info
router.get('/', (req, res) => {
  res.json({
    name: 'Paperly Admin API',
    version: '1.0.0',
    client: 'admin',
    status: 'running',
    timestamp: new Date().toISOString(),
  });
});

// Admin Authentication Routes
const authRouter = Router();

authRouter.post('/login', 
  adminLoginLimiter,
  validateInput({
    email: { required: true, type: 'email' },
    password: { required: true, minLength: 8 }
  }),
  (req, res) => adminAuthController.login(req, res)
);

authRouter.post('/refresh', 
  (req, res) => adminAuthController.refreshToken(req, res)
);

authRouter.post('/logout', 
  authMiddleware,
  requireAdminRole,
  (req, res) => adminAuthController.logout(req, res)
);

authRouter.get('/me', 
  authMiddleware,
  requireAdminRole,
  (req, res) => adminAuthController.getCurrentUser(req, res)
);

authRouter.get('/verify', 
  (req, res) => adminAuthController.verifyAdmin(req, res)
);

// Admin Users Management Routes
const usersRouter = Router();

usersRouter.get('/', 
  authMiddleware,
  requireAdminRole,
  (req, res) => {
    res.json({ message: 'Get all users', user: req.user });
  }
);

usersRouter.get('/admins', 
  authMiddleware,
  requireAdminRole,
  (req, res) => adminAuthController.getAdminUsers(req, res)
);

usersRouter.get('/:id', 
  authMiddleware,
  requireAdminRole,
  (req, res) => {
    res.json({ message: 'Get user by ID', userId: req.params.id, user: req.user });
  }
);

usersRouter.put('/:id', 
  authMiddleware,
  requireAdminRole,
  (req, res) => {
    res.json({ message: 'Update user', userId: req.params.id, user: req.user });
  }
);

usersRouter.delete('/:id', 
  authMiddleware,
  requireSuperAdminRole,
  (req, res) => {
    res.json({ message: 'Delete user', userId: req.params.id, user: req.user });
  }
);

usersRouter.post('/:userId/assign-role', 
  authMiddleware,
  requireSuperAdminRole,
  validateInput({
    roleId: { required: true, type: 'string' },
    expiresAt: { required: false, type: 'date' }
  }),
  (req, res) => adminAuthController.assignRole(req, res)
);

usersRouter.delete('/:userId/remove-role', 
  authMiddleware,
  requireSuperAdminRole,
  (req, res) => adminAuthController.removeRole(req, res)
);

// Admin Writers Management Routes
const writersRouter = Router();

function setupAdminWriterRoutes(): Router {
  try {
    const { WriterController } = require('../controllers/writer.controller');
    const writerController = container.resolve(WriterController) as Controller;
    return writerController.router;
  } catch (error) {
    logger.error('Admin writer controller setup failed:', error);
    throw error;
  }
}

writersRouter.use('/', authMiddleware, requireAdminRole, (req, res, next) => {
  try {
    const adminWriterRouter = setupAdminWriterRoutes();
    adminWriterRouter(req, res, next);
  } catch (error) {
    logger.error('Admin writer route setup failed:', error);
    next(error);
  }
});

writersRouter.get('/pending', 
  authMiddleware,
  requireAdminRole,
  (req, res) => {
    res.json({ message: 'Get pending writer applications', user: req.user });
  }
);

writersRouter.put('/:id/approve', 
  authMiddleware,
  requireAdminRole,
  (req, res) => {
    res.json({ message: 'Approve writer', writerId: req.params.id, user: req.user });
  }
);

writersRouter.put('/:id/reject', 
  authMiddleware,
  requireAdminRole,
  (req, res) => {
    res.json({ message: 'Reject writer', writerId: req.params.id, user: req.user });
  }
);

writersRouter.get('/:id/analytics', 
  authMiddleware,
  requireAdminRole,
  (req, res) => {
    res.json({ message: 'Get writer analytics', writerId: req.params.id, user: req.user });
  }
);

// Admin Articles Management Routes
const articlesRouter = Router();

articlesRouter.use('/', createAdminArticleRoutes(adminArticleController));

// Admin Categories Management Routes
const categoriesRouter = Router();

function setupAdminCategoryRoutes(): Router {
  try {
    const { CategoryController } = require('../controllers/category.controller');
    const categoryController = container.resolve(CategoryController) as Controller;
    return categoryController.router;
  } catch (error) {
    logger.error('Admin category controller setup failed:', error);
    throw error;
  }
}

categoriesRouter.use('/', authMiddleware, requireAdminRole, (req, res, next) => {
  try {
    const adminCategoryRouter = setupAdminCategoryRoutes();
    adminCategoryRouter(req, res, next);
  } catch (error) {
    logger.error('Admin category route setup failed:', error);
    next(error);
  }
});

categoriesRouter.post('/', 
  authMiddleware,
  requireAdminRole,
  (req, res) => {
    res.json({ message: 'Create category', user: req.user });
  }
);

categoriesRouter.put('/:id', 
  authMiddleware,
  requireAdminRole,
  (req, res) => {
    res.json({ message: 'Update category', categoryId: req.params.id, user: req.user });
  }
);

categoriesRouter.delete('/:id', 
  authMiddleware,
  requireAdminRole,
  (req, res) => {
    res.json({ message: 'Delete category', categoryId: req.params.id, user: req.user });
  }
);

// Admin Security Routes
const securityRouter = Router();

securityRouter.get('/events', 
  authMiddleware,
  requireAdminRole,
  (req, res) => securityMonitorController.getSecurityEvents(req, res)
);

securityRouter.get('/events/:eventId', 
  authMiddleware,
  requireAdminRole,
  (req, res) => securityMonitorController.getSecurityEvent(req, res)
);

securityRouter.get('/stats', 
  authMiddleware,
  requireAdminRole,
  (req, res) => securityMonitorController.getSecurityStats(req, res)
);

securityRouter.post('/block-ip', 
  authMiddleware,
  requireAdminRole,
  validateInput({
    ip: { required: true, type: 'string' },
    reason: { required: true, type: 'string' },
    duration: { required: false, type: 'number', min: 1 }
  }),
  (req, res) => securityMonitorController.blockIP(req, res)
);

securityRouter.delete('/unblock-ip/:ip', 
  authMiddleware,
  requireAdminRole,
  (req, res) => securityMonitorController.unblockIP(req, res)
);

securityRouter.get('/blocked-ips', 
  authMiddleware,
  requireAdminRole,
  (req, res) => securityMonitorController.getBlockedIPs(req, res)
);

securityRouter.patch('/events/:eventId/status', 
  authMiddleware,
  requireAdminRole,
  validateInput({
    status: { 
      required: true, 
      type: 'string',
      enum: ['detected', 'investigating', 'blocked', 'resolved', 'false_positive']
    },
    notes: { required: false, type: 'string' }
  }),
  (req, res) => securityMonitorController.updateEventStatus(req, res)
);

securityRouter.get('/events/stream', 
  authMiddleware,
  requireAdminRole,
  (req, res) => securityMonitorController.getEventStream(req, res)
);

// Admin System Routes
const systemRouter = Router();

systemRouter.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    data: {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      version: process.env.API_VERSION || '1.0.0'
    },
    message: '관리자 API 서버가 정상 작동 중입니다'
  });
});

systemRouter.get('/stats', 
  authMiddleware,
  requireAdminRole,
  (req, res) => {
    res.status(501).json({
      success: false,
      error: {
        code: 'NOT_IMPLEMENTED',
        message: '아직 구현되지 않은 기능입니다'
      }
    });
  }
);

systemRouter.get('/settings', 
  authMiddleware,
  requireSuperAdminRole,
  (req, res) => {
    res.status(501).json({
      success: false,
      error: {
        code: 'NOT_IMPLEMENTED',
        message: '아직 구현되지 않은 기능입니다'
      }
    });
  }
);

systemRouter.put('/settings', 
  authMiddleware,
  requireSuperAdminRole,
  (req, res) => {
    res.status(501).json({
      success: false,
      error: {
        code: 'NOT_IMPLEMENTED',
        message: '아직 구현되지 않은 기능입니다'
      }
    });
  }
);

systemRouter.get('/logs', 
  authMiddleware,
  requirePermissions('logs:read'),
  (req, res) => {
    res.status(501).json({
      success: false,
      error: {
        code: 'NOT_IMPLEMENTED',
        message: '아직 구현되지 않은 기능입니다'
      }
    });
  }
);

// Apply admin client validation to all routes
router.use(requireAdminClient);

// Register admin-specific routes with proper middleware
router.use('/auth', authRouter);
router.use('/users', usersRouter);
router.use('/writers', writersRouter);
router.use('/articles', articlesRouter);
router.use('/categories', categoriesRouter);
router.use('/security', securityRouter);
router.use('/system', systemRouter);

// Error handling
router.use(notFoundHandler);
router.use(errorHandler);

logger.info('Admin API routes initialized with client validation and error handling');

export { router as adminRouter };