# Backend API Overview

## Overview

The Paperly backend provides a comprehensive RESTful API serving three distinct client applications: Mobile App, Writer App, and Admin Panel. Built with Node.js, Express, and TypeScript, it follows Clean Architecture and Domain-Driven Design principles.

## Architecture

- **Framework**: Express.js with TypeScript
- **Architecture Pattern**: Clean Architecture + DDD
- **Authentication**: JWT-based with refresh token rotation
- **Database**: PostgreSQL with Prisma ORM
- **Dependency Injection**: TSyringe
- **API Prefix**: `/api` (configurable via `API_PREFIX` env var)

## API Structure

### Base URL Pattern
```
https://api.paperly.com/api/{client}/{resource}
```

Where `{client}` is one of: `mobile`, `writer`, `admin`, or legacy endpoints without client prefix.

## Mobile App Endpoints

### Authentication (`/api/mobile/auth`)
- `POST /register` - New user registration
- `POST /login` - User authentication
- `POST /refresh` - Refresh access token
- `POST /logout` - Invalidate refresh tokens
- `GET /verify-email` - Email verification
- `POST /resend-verification` - Resend verification email
- `POST /check-username` - Username availability

### Articles (`/api/mobile/articles`)
- `GET /` - List articles (paginated, filterable)
- `GET /:id` - Get article details
- `GET /search` - Search articles
- `POST /:id/view` - Track article view

### Categories (`/api/mobile/categories`)
- `GET /` - List all categories
- `GET /:id/articles` - Articles by category

### Recommendations (`/api/mobile/recommendations`)
- `GET /` - Personalized recommendations
- `GET /trending` - Trending articles
- `GET /new` - Latest articles

### User Profile (`/api/mobile/user`)
- `GET /profile` - User profile data
- `PUT /profile` - Update profile
- `GET /reading-history` - Reading history
- `GET /bookmarks` - Bookmarked articles
- `POST /bookmarks/:articleId` - Add bookmark
- `DELETE /bookmarks/:articleId` - Remove bookmark

### Onboarding (`/api/mobile/onboarding`)
- `GET /topics` - Available topics
- `POST /preferences` - Save user preferences

## Writer App Endpoints

### Authentication (`/api/writer/auth`)
Same as mobile auth endpoints with additional writer-specific validations

### Profile (`/api/writer/profile`)
- `GET /` - Writer profile with stats
- `PUT /` - Update writer profile
- `POST /bio` - Update writer bio
- `POST /avatar` - Upload avatar

### Articles (`/api/writer/articles`)
- `GET /` - List writer's articles
- `GET /:id` - Get article details
- `POST /` - Create new article
- `PUT /:id` - Update article
- `DELETE /:id` - Delete article
- `POST /:id/publish` - Publish article
- `POST /:id/unpublish` - Unpublish article

### Drafts (`/api/writer/drafts`)
- `GET /` - List drafts
- `POST /` - Create draft
- `PUT /:id` - Update draft
- `DELETE /:id` - Delete draft
- `POST /:id/autosave` - Auto-save draft

### Analytics (`/api/writer/analytics`)
- `GET /overview` - Analytics dashboard
- `GET /articles/:id/stats` - Article statistics
- `GET /engagement` - Engagement metrics
- `GET /revenue` - Revenue analytics

### Dashboard (`/api/writer/dashboard`)
- `GET /summary` - Dashboard summary
- `GET /recent-activity` - Recent activities
- `GET /notifications` - Writer notifications

## Admin Panel Endpoints

### Authentication (`/api/admin/auth`)
- `POST /login` - Admin login (rate-limited)
- `POST /refresh` - Refresh admin token
- `POST /logout` - Admin logout
- `GET /me` - Current admin user
- `GET /verify` - Verify admin status

### User Management (`/api/admin/users`)
- `GET /` - List all users (paginated)
- `GET /admins` - List admin users
- `GET /:id` - User details
- `PUT /:id` - Update user
- `DELETE /:id` - Delete user (super admin only)
- `POST /:userId/assign-role` - Assign role
- `DELETE /:userId/remove-role` - Remove role

### Writer Management (`/api/admin/writers`)
- `GET /pending` - Pending applications
- `PUT /:id/approve` - Approve writer
- `PUT /:id/reject` - Reject writer
- `GET /:id/analytics` - Writer analytics

### Content Management (`/api/admin/articles`)
- `GET /` - List all articles
- `GET /:id` - Article details
- `PUT /:id/approve` - Approve article
- `PUT /:id/reject` - Reject article
- `DELETE /:id` - Delete article

### Category Management (`/api/admin/categories`)
- `GET /` - List categories
- `POST /` - Create category
- `PUT /:id` - Update category
- `DELETE /:id` - Delete category

### Security Monitoring (`/api/admin/security`)
- `GET /events` - Security events log
- `GET /events/:eventId` - Event details
- `GET /stats` - Security statistics
- `POST /block-ip` - Block IP address
- `DELETE /unblock-ip/:ip` - Unblock IP
- `GET /blocked-ips` - List blocked IPs
- `PATCH /events/:eventId/status` - Update event status
- `GET /events/stream` - Real-time event stream (SSE)

### System Management (`/api/admin/system`)
- `GET /health` - Health check
- `GET /stats` - System statistics
- `GET /settings` - System settings (super admin)
- `PUT /settings` - Update settings (super admin)
- `GET /logs` - System logs

## Authentication & Security

### JWT Token Structure
```json
{
  "userId": "uuid",
  "email": "user@example.com",
  "userType": "mobile|writer|admin",
  "userCode": "unique-identifier",
  "role": "user|writer|admin|super_admin",
  "permissions": ["read", "write", "delete"],
  "type": "access|refresh"
}
```

### Token Expiration
- Access Token: 15 minutes
- Refresh Token: 7 days

### Security Features
- Rate limiting per endpoint
- CORS with client-specific origins
- Helmet.js security headers
- Input validation and sanitization
- SQL injection protection
- XSS protection
- Device ID tracking
- IP address logging
- Request ID tracing

## Middleware Stack

1. **Request Processing**
   - Request ID generation
   - Request logging
   - Body parsing
   - Compression

2. **Security**
   - CORS validation
   - Rate limiting
   - Authentication verification
   - Role-based access control
   - Client validation

3. **Business Logic**
   - Input validation
   - Use case execution
   - Response formatting

4. **Error Handling**
   - Structured error responses
   - Error logging
   - Client-friendly messages

## Response Format

All API responses follow this structure:

```json
{
  "success": true,
  "message": "Operation successful",
  "data": {
    // Response payload
  }
}
```

Error responses:

```json
{
  "success": false,
  "message": "Error description",
  "error": {
    "code": "ERROR_CODE",
    "message": "Detailed error message",
    "details": {}
  }
}
```

## Client-Specific Features

### Mobile App
- Read-only access to articles
- Personalized recommendations
- Reading history tracking
- Bookmark management
- Push notification support

### Writer App
- Full CRUD on own articles
- Draft management with auto-save
- Analytics dashboard
- Revenue tracking
- Publishing workflow

### Admin Panel
- User and role management
- Content moderation
- Security monitoring
- System configuration
- Real-time event streaming

## Rate Limiting

Different limits apply to different endpoints:
- Authentication: 5 requests per minute
- API calls: 100 requests per minute
- File uploads: 10 requests per minute
- Admin endpoints: Custom limits based on operation

## Deprecation Notice

Legacy endpoints without client prefix (e.g., `/api/auth`, `/api/articles`) are deprecated and will be removed in future versions. All clients should migrate to the new client-specific endpoints.