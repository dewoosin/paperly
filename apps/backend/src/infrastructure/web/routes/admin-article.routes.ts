import { Router } from 'express';
import { AdminArticleController } from '../controllers/admin-article.controller';
import { adminAuthMiddleware } from '../middleware/admin-auth.middleware';
import { validateRequest } from '../middleware/validation.middleware';
import { body, param, query } from 'express-validator';

export const createAdminArticleRoutes = (controller: AdminArticleController): Router => {
  const router = Router();

  // All routes require admin authentication
  router.use(adminAuthMiddleware);

  // Get all articles with pagination and filters
  router.get(
    '/',
    [
      query('page').optional().isInt({ min: 1 }),
      query('limit').optional().isInt({ min: 1, max: 100 }),
      query('status').optional().isIn(['draft', 'review', 'published', 'archived', 'deleted']),
      query('category_id').optional().isUUID(),
      query('author_id').optional().isUUID(),
      query('search').optional().isString()
    ],
    validateRequest,
    controller.getAllArticles.bind(controller)
  );

  // Get categories for dropdown
  router.get('/categories', controller.getCategories.bind(controller));

  // Get tags for autocomplete
  router.get(
    '/tags',
    [query('search').optional().isString()],
    validateRequest,
    controller.getTags.bind(controller)
  );

  // Get single article by ID
  router.get(
    '/:id',
    [param('id').isUUID()],
    validateRequest,
    controller.getArticleById.bind(controller)
  );

  // Create new article
  router.post(
    '/',
    [
      body('title').notEmpty().isString().isLength({ min: 1, max: 300 }),
      body('slug').optional().isString().matches(/^[a-z0-9-]+$/),
      body('summary').notEmpty().isString().isLength({ min: 50, max: 500 }),
      body('content').notEmpty().isString().isLength({ min: 100 }),
      body('category_id').notEmpty().isUUID(),
      body('featured_image_url').optional().isURL(),
      body('status').optional().isIn(['draft', 'review', 'published', 'archived']),
      body('is_featured').optional().isBoolean(),
      body('is_premium').optional().isBoolean(),
      body('difficulty_level').optional().isInt({ min: 1, max: 5 }),
      body('content_type').optional().isIn(['article', 'series', 'tutorial', 'opinion', 'news']),
      body('seo_title').optional().isString().isLength({ max: 150 }),
      body('seo_description').optional().isString().isLength({ max: 300 }),
      body('seo_keywords').optional().isArray(),
      body('tags').optional().isArray(),
      body('tags.*').optional().isUUID()
    ],
    validateRequest,
    controller.createArticle.bind(controller)
  );

  // Update article
  router.put(
    '/:id',
    [
      param('id').isUUID(),
      body('title').optional().isString().isLength({ min: 1, max: 300 }),
      body('slug').optional().isString().matches(/^[a-z0-9-]+$/),
      body('summary').optional().isString().isLength({ min: 50, max: 500 }),
      body('content').optional().isString().isLength({ min: 100 }),
      body('category_id').optional().isUUID(),
      body('featured_image_url').optional().isURL().nullable(),
      body('status').optional().isIn(['draft', 'review', 'published', 'archived']),
      body('is_featured').optional().isBoolean(),
      body('is_premium').optional().isBoolean(),
      body('difficulty_level').optional().isInt({ min: 1, max: 5 }),
      body('content_type').optional().isIn(['article', 'series', 'tutorial', 'opinion', 'news']),
      body('seo_title').optional().isString().isLength({ max: 150 }),
      body('seo_description').optional().isString().isLength({ max: 300 }),
      body('seo_keywords').optional().isArray(),
      body('tags').optional().isArray(),
      body('tags.*').optional().isUUID()
    ],
    validateRequest,
    controller.updateArticle.bind(controller)
  );

  // Delete article (soft or permanent)
  router.delete(
    '/:id',
    [
      param('id').isUUID(),
      query('permanent').optional().isBoolean()
    ],
    validateRequest,
    controller.deleteArticle.bind(controller)
  );

  // Publish article
  router.post(
    '/:id/publish',
    [param('id').isUUID()],
    validateRequest,
    controller.publishArticle.bind(controller)
  );

  // Unpublish article
  router.post(
    '/:id/unpublish',
    [param('id').isUUID()],
    validateRequest,
    controller.unpublishArticle.bind(controller)
  );

  return router;
};