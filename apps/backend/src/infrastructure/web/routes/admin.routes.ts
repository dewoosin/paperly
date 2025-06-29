// /Users/workspace/paperly/apps/backend/src/infrastructure/web/routes/admin.routes.ts

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

/**
 * 관리자 라우트 설정
 * 
 * 관리자 인증, 사용자 관리, 시스템 관리 등의 API 엔드포인트를 정의합니다.
 * 모든 관리자 API는 '/admin' 접두사를 가집니다.
 */

const adminRouter = Router();

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

adminRouter.post('/auth/login', 
  adminLoginLimiter,
  validateInput({
    email: { required: true, type: 'email' },
    password: { required: true, minLength: 8 }
  }),
  (req, res) => adminAuthController.login(req, res)
);

// 관리자 토큰 새로고침
adminRouter.post('/auth/refresh', 
  (req, res) => adminAuthController.refreshToken(req, res)
);

// 관리자 로그아웃
adminRouter.post('/auth/logout', 
  authMiddleware,
  requireAdminRole,
  (req, res) => adminAuthController.logout(req, res)
);

// 현재 관리자 정보 조회
adminRouter.get('/auth/me', 
  authMiddleware,
  requireAdminRole,
  (req, res) => adminAuthController.getCurrentUser(req, res)
);

// 관리자 권한 확인
adminRouter.get('/auth/verify', 
  (req, res) => adminAuthController.verifyAdmin(req, res)
);

// ============================================================================
// 👥 사용자 관리 라우트
// ============================================================================

// 모든 관리자 사용자 목록 조회
adminRouter.get('/users/admins', 
  authMiddleware,
  requireAdminRole,
  (req, res) => adminAuthController.getAdminUsers(req, res)
);

// 사용자에게 관리자 역할 할당 (최고 관리자 권한 필요)
adminRouter.post('/users/:userId/assign-role', 
  authMiddleware,
  requireSuperAdminRole,
  validateInput({
    roleId: { required: true, type: 'string' },
    expiresAt: { required: false, type: 'date' }
  }),
  (req, res) => adminAuthController.assignRole(req, res)
);

// 사용자의 관리자 역할 제거 (최고 관리자 권한 필요)
adminRouter.delete('/users/:userId/remove-role', 
  authMiddleware,
  requireSuperAdminRole,
  (req, res) => adminAuthController.removeRole(req, res)
);

// ============================================================================
// 📊 시스템 관리 라우트 (미래 확장용)
// ============================================================================

// 시스템 통계 조회
adminRouter.get('/stats/overview', 
  authMiddleware,
  requireAdminRole,
  (req, res) => {
    // TODO: 시스템 통계 컨트롤러 구현
    res.status(501).json({
      success: false,
      error: {
        code: 'NOT_IMPLEMENTED',
        message: '아직 구현되지 않은 기능입니다'
      }
    });
  }
);

// ============================================================================
// 🛡️ 보안 모니터링 라우트
// ============================================================================

// 보안 이벤트 목록 조회
adminRouter.get('/security/events', 
  authMiddleware,
  requireAdminRole,
  (req, res) => securityMonitorController.getSecurityEvents(req, res)
);

// 보안 이벤트 상세 조회
adminRouter.get('/security/events/:eventId', 
  authMiddleware,
  requireAdminRole,
  (req, res) => securityMonitorController.getSecurityEvent(req, res)
);

// 보안 통계 조회
adminRouter.get('/security/stats', 
  authMiddleware,
  requireAdminRole,
  (req, res) => securityMonitorController.getSecurityStats(req, res)
);

// IP 차단
adminRouter.post('/security/block-ip', 
  authMiddleware,
  requireAdminRole,
  validateInput({
    ip: { required: true, type: 'string' },
    reason: { required: true, type: 'string' },
    duration: { required: false, type: 'number', min: 1 }
  }),
  (req, res) => securityMonitorController.blockIP(req, res)
);

// IP 차단 해제
adminRouter.delete('/security/unblock-ip/:ip', 
  authMiddleware,
  requireAdminRole,
  (req, res) => securityMonitorController.unblockIP(req, res)
);

// 차단된 IP 목록 조회
adminRouter.get('/security/blocked-ips', 
  authMiddleware,
  requireAdminRole,
  (req, res) => securityMonitorController.getBlockedIPs(req, res)
);

// 보안 이벤트 상태 업데이트
adminRouter.patch('/security/events/:eventId/status', 
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

// 실시간 보안 이벤트 스트림
adminRouter.get('/security/events/stream', 
  authMiddleware,
  requireAdminRole,
  (req, res) => securityMonitorController.getEventStream(req, res)
);

// 시스템 로그 조회
adminRouter.get('/logs', 
  authMiddleware,
  requirePermissions('logs:read'),
  (req, res) => {
    // TODO: 로그 조회 컨트롤러 구현
    res.status(501).json({
      success: false,
      error: {
        code: 'NOT_IMPLEMENTED',
        message: '아직 구현되지 않은 기능입니다'
      }
    });
  }
);

// 공통코드 관리
adminRouter.get('/codes', 
  authMiddleware,
  requirePermissions('codes:read'),
  (req, res) => {
    // TODO: 공통코드 컨트롤러 구현
    res.status(501).json({
      success: false,
      error: {
        code: 'NOT_IMPLEMENTED',
        message: '아직 구현되지 않은 기능입니다'
      }
    });
  }
);

// 메시지코드 관리
adminRouter.get('/messages', 
  authMiddleware,
  requirePermissions('messages:read'),
  (req, res) => {
    // TODO: 메시지코드 컨트롤러 구현
    res.status(501).json({
      success: false,
      error: {
        code: 'NOT_IMPLEMENTED',
        message: '아직 구현되지 않은 기능입니다'
      }
    });
  }
);

// ============================================================================
// 📝 콘텐츠 관리 라우트
// ============================================================================

// 기사 관리 라우트 마운트
adminRouter.use('/articles', createAdminArticleRoutes(adminArticleController));

// ============================================================================
// 🔧 시스템 설정 라우트
// ============================================================================

// 시스템 설정 조회
adminRouter.get('/settings', 
  authMiddleware,
  requireSuperAdminRole,
  (req, res) => {
    // TODO: 시스템 설정 컨트롤러 구현
    res.status(501).json({
      success: false,
      error: {
        code: 'NOT_IMPLEMENTED',
        message: '아직 구현되지 않은 기능입니다'
      }
    });
  }
);

// 시스템 설정 수정
adminRouter.put('/settings', 
  authMiddleware,
  requireSuperAdminRole,
  (req, res) => {
    // TODO: 시스템 설정 컨트롤러 구현
    res.status(501).json({
      success: false,
      error: {
        code: 'NOT_IMPLEMENTED',
        message: '아직 구현되지 않은 기능입니다'
      }
    });
  }
);

// ============================================================================
// 🏥 시스템 헬스체크
// ============================================================================

// 관리자 API 헬스체크
adminRouter.get('/health', (req, res) => {
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

export { adminRouter };