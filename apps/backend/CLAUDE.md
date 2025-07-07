# Paperly Backend Developer Guide

This guide provides comprehensive documentation for developers working on the Paperly backend API server. It covers architecture, setup, development practices, and deployment procedures.

## Table of Contents

1. [Overview](#overview)
2. [Role in Paperly System](#role-in-paperly-system)
3. [Core Functions](#core-functions)
4. [Architecture](#architecture)
5. [Technology Stack](#technology-stack)
6. [Project Structure](#project-structure)
7. [Development Setup](#development-setup)
8. [API Documentation](#api-documentation)
9. [Database Schema](#database-schema)
10. [Testing](#testing)
11. [Deployment](#deployment)
12. [Troubleshooting](#troubleshooting)

---

## Overview

The Paperly backend is the central API server that powers all client applications (Mobile, Writer, Admin). Built with Node.js and TypeScript, it follows Clean Architecture and Domain-Driven Design principles to ensure scalability, maintainability, and testability.

### Key Responsibilities
- **API Gateway**: Unified API for all client applications
- **Business Logic**: Core domain logic and use cases
- **Data Persistence**: Database operations and caching
- **Authentication**: JWT-based auth with refresh tokens
- **AI Integration**: Content recommendations and generation
- **Email Services**: Transactional emails and notifications
- **Security**: Rate limiting, input validation, and monitoring

---

## Role in Paperly System

The backend serves as the central nervous system of the Paperly platform:

```
┌─────────────────────────────────────────────────────────┐
│                    Client Applications                   │
├───────────────┬─────────────────┬───────────────────────┤
│  Mobile App   │   Writer App    │    Admin Panel       │
└───────┬───────┴────────┬────────┴───────┬───────────────┘
        │                │                │
        └────────────────┼────────────────┘
                         │
                   ┌─────▼─────┐
                   │  Backend   │
                   │  API Server│
                   └─────┬─────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
   ┌────▼────┐    ┌─────▼─────┐   ┌─────▼─────┐
   │PostgreSQL│    │   Redis   │   │ AI Service│
   │    DB    │    │   Cache   │   │  (OpenAI) │
   └─────────┘    └───────────┘   └───────────┘
```

### Multi-Client Architecture
- **Mobile API** (`/api/v1/mobile/*`): Reader-focused endpoints
- **Writer API** (`/api/v1/writer/*`): Content creation endpoints
- **Admin API** (`/api/v1/admin/*`): Platform management endpoints

---

## Core Functions

### 1. User Management
- **Registration**: Email/password with verification
- **Authentication**: JWT tokens with device tracking
- **Profile Management**: User preferences and settings
- **Session Management**: Multi-device support

### 2. Content Management
- **Article CRUD**: Create, read, update, delete articles
- **Categories & Tags**: Content organization
- **Search & Filter**: Full-text search capabilities
- **Versioning**: Article history and drafts

### 3. Personalization & AI
- **Recommendations**: AI-powered content suggestions
- **User Behavior**: Reading pattern analysis
- **Content Generation**: AI-assisted writing
- **Preference Learning**: Adaptive algorithms

### 4. Social Features
- **Author Following**: Subscribe to writers
- **Likes & Bookmarks**: Content interactions
- **Comments**: Reader engagement (planned)
- **Sharing**: Social media integration

### 5. Analytics & Reporting
- **Reading Analytics**: Time, completion, engagement
- **Writer Dashboard**: Performance metrics
- **Admin Analytics**: Platform-wide statistics
- **Revenue Tracking**: Subscription analytics

### 6. System Services
- **Email Service**: Transactional emails
- **Notification System**: Push notifications
- **File Storage**: Image and document handling
- **Background Jobs**: Async task processing

---

## Architecture

### Clean Architecture Layers

```
┌─────────────────────────────────────────────────────┐
│                 Presentation Layer                   │
│         (Controllers, Routes, Middleware)            │
├─────────────────────────────────────────────────────┤
│                 Application Layer                    │
│          (Use Cases, DTOs, Services)                │
├─────────────────────────────────────────────────────┤
│                   Domain Layer                       │
│     (Entities, Value Objects, Domain Services)      │
├─────────────────────────────────────────────────────┤
│                Infrastructure Layer                  │
│  (Database, External APIs, Email, File System)      │
└─────────────────────────────────────────────────────┘
```

### Design Principles
1. **Dependency Inversion**: Core domain has no external dependencies
2. **Single Responsibility**: Each class has one reason to change
3. **Interface Segregation**: Small, focused interfaces
4. **Dependency Injection**: TSyringe for IoC container
5. **Domain-Driven Design**: Rich domain models

---

## Technology Stack

### Core Technologies
| Technology | Version | Purpose |
|------------|---------|---------|
| Node.js | 20.x | Runtime environment |
| TypeScript | 5.x | Type safety |
| Express.js | 4.x | Web framework |
| PostgreSQL | 15 | Primary database |
| Redis | 7.x | Caching & sessions |
| TypeORM | 0.3.x | ORM |
| TSyringe | 4.x | Dependency injection |

### Security & Validation
| Technology | Purpose |
|------------|---------|
| JWT | Authentication tokens |
| bcrypt | Password hashing |
| Helmet | Security headers |
| express-rate-limit | Rate limiting |
| Zod | Schema validation |
| express-validator | Input validation |

### Development & Testing
| Technology | Purpose |
|------------|---------|
| Jest | Unit testing |
| Supertest | Integration testing |
| Winston | Logging |
| ESLint | Code linting |
| tsx | TypeScript execution |

---

## Project Structure

```
apps/backend/
├── src/
│   ├── domain/                 # Core business logic
│   │   ├── entities/          # Business entities
│   │   ├── value-objects/     # Value objects (Email, Password)
│   │   ├── repositories/      # Repository interfaces
│   │   ├── services/          # Domain services
│   │   └── events/            # Domain events
│   │
│   ├── application/           # Application business logic
│   │   ├── use-cases/        # Business operations
│   │   ├── dto/              # Data transfer objects
│   │   ├── services/         # Application services
│   │   └── interfaces/       # Port interfaces
│   │
│   ├── infrastructure/        # External concerns
│   │   ├── web/              # HTTP layer
│   │   │   ├── controllers/  # Request handlers
│   │   │   ├── routes/       # Route definitions
│   │   │   ├── middleware/   # Express middleware
│   │   │   └── validators/   # Request validation
│   │   ├── database/         # Database implementation
│   │   ├── repositories/     # Repository implementations
│   │   ├── email/           # Email service
│   │   ├── auth/            # Auth implementation
│   │   ├── logging/         # Logger setup
│   │   └── config/          # Configuration
│   │
│   ├── shared/               # Shared utilities
│   │   ├── errors/          # Error definitions
│   │   ├── constants/       # Constants
│   │   └── utils/           # Helper functions
│   │
│   └── main.ts              # Application entry point
│
├── scripts/                  # Utility scripts
│   ├── check-db.ts          # Database connection test
│   ├── test-email.ts        # Email service test
│   └── setup-gmail.ts       # Gmail configuration
│
├── tests/                    # Test files
│   ├── unit/                # Unit tests
│   ├── integration/         # Integration tests
│   └── e2e/                 # End-to-end tests
│
├── database/                # Database files
│   ├── migrations/          # Database migrations
│   └── seeds/               # Seed data
│
└── config/                  # Configuration files
```

### Key Directories Explained

- **domain/**: Pure business logic, no framework dependencies
- **application/**: Orchestrates domain logic, handles use cases
- **infrastructure/**: All external dependencies and integrations
- **shared/**: Cross-cutting concerns used across layers

---

## Development Setup

### Prerequisites
- Node.js 20.x or higher
- Docker & Docker Compose
- PostgreSQL client (optional)

### Quick Start

1. **Navigate to Backend**
```bash
cd apps/backend
```

2. **Install Dependencies**
```bash
npm install
```

3. **Environment Setup**
```bash
# Copy environment template
cp .env.example .env

# Generate JWT secrets
openssl rand -hex 32  # JWT_ACCESS_SECRET
openssl rand -hex 32  # JWT_REFRESH_SECRET
```

4. **Start Services**
```bash
# Start Docker services (PostgreSQL, Redis)
npm run docker:up

# Verify database connection
npm run db:check
```

5. **Run Development Server**
```bash
# Standard development
npm run dev

# WSL development (auto-detect host IP)
npm run dev:wsl

# With debug logging
npm run dev:debug
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | 3000 |
| `NODE_ENV` | Environment | development |
| `DATABASE_URL` | PostgreSQL connection | - |
| `REDIS_URL` | Redis connection | - |
| `JWT_ACCESS_SECRET` | Access token secret | - |
| `JWT_REFRESH_SECRET` | Refresh token secret | - |
| `JWT_ACCESS_EXPIRY` | Access token TTL | 15m |
| `JWT_REFRESH_EXPIRY` | Refresh token TTL | 7d |

---

## API Documentation

### Base URL Structure
```
https://api.paperly.com/api/v1/{client}/{resource}
```

Where `{client}` is one of:
- `mobile` - Mobile app endpoints
- `writer` - Writer dashboard endpoints  
- `admin` - Admin panel endpoints

### Authentication & Security

#### JWT Token Structure
- **Algorithm**: HS256 (HMAC SHA-256)
- **Issuer**: "paperly"
- **Audience**: "paperly-app"
- **Access Token Expiry**: 15 minutes
- **Refresh Token Expiry**: 7 days

#### Authentication Headers
All protected endpoints require JWT token in header:
```
Authorization: Bearer {access_token}
X-Client-Type: mobile|writer|admin
X-Device-ID: {device_uuid} (optional but recommended)
```

#### Client Validation
Each endpoint validates the client type using middleware:
- `requireMobileClient` - For mobile endpoints
- `requireWriterClient` - For writer endpoints
- `requireAdminClient` - For admin endpoints

#### Rate Limiting
- **Authentication**: 5 requests per 15 minutes (strict rate limiter)
- **API calls**: 100 requests per 15 minutes (standard rate limiter)
- **Admin login**: 5 requests per 15 minutes (admin-specific limiter)

#### Implementation Status

**Mobile API (`/api/v1/mobile/`)**
- ✅ **Fully Implemented**: Authentication, article browsing, categories (basic + advanced), comprehensive recommendation system, full onboarding flow
- ⚠️ **Placeholder Implementation**: User profile management, bookmarks, reading history (endpoints exist but return mock data)

**Writer API (`/api/v1/writer/`)**
- ✅ **Fully Implemented**: Authentication, article CRUD operations, dashboard metrics
- ⚠️ **Placeholder Implementation**: Profile management, analytics, drafts management (endpoints exist but return mock data)

**Admin API (`/api/v1/admin/`)**
- ✅ **Fully Implemented**: Authentication, security monitoring, article management
- ⚠️ **Placeholder Implementation**: User management, writer management, category management (endpoints exist but return mock data)
- ❌ **Not Implemented**: System management endpoints (stats, settings, logs) - return 501 Not Implemented

**Legacy API (`/api/v1/`)**
- ✅ **Fully Implemented**: Backward compatibility endpoints for auth, articles, categories, recommendations, onboarding

---

## Mobile App API (`/api/v1/mobile/`)

### Authentication (`/auth`)

#### Register User
```http
POST /api/v1/mobile/auth/register
Content-Type: application/json
X-Client-Type: mobile

{
  "username": "string",
  "email": "string", 
  "password": "string",
  "name": "string",
  "deviceId": "generated-uuid"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "username": "string",
      "email": "string",
      "name": "string",
      "isEmailVerified": false,
      "createdAt": "ISO-date"
    },
    "tokens": {
      "accessToken": "jwt-token",
      "refreshToken": "jwt-token"
    }
  }
}
```

#### Login User
```http
POST /api/v1/mobile/auth/login
Content-Type: application/json
X-Client-Type: mobile

{
  "email": "string",
  "password": "string",
  "deviceId": "device-uuid"
}
```

**Response:** Same as register

#### Refresh Token
```http
POST /api/v1/mobile/auth/refresh
Content-Type: application/json

{
  "refreshToken": "stored-refresh-token",
  "deviceId": "device-uuid"
}
```

#### Logout
```http
POST /api/v1/mobile/auth/logout
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "deviceId": "device-uuid"
}
```

#### Email Verification
```http
GET /api/v1/mobile/auth/verify-email?token=verification-token
```

#### Resend Verification Email
```http
POST /api/v1/mobile/auth/resend-verification
Content-Type: application/json

{
  "email": "user@example.com"
}
```

#### Check Username Availability
```http
POST /api/v1/mobile/auth/check-username
Content-Type: application/json

{
  "username": "desired_username"
}
```

#### Skip Email Verification (Development Only)
```http
POST /api/v1/mobile/auth/skip-verification
Authorization: Bearer <access_token>
```

### Articles (`/articles`)

#### Get Published Articles (Default Feed)
```http
GET /api/v1/mobile/articles?page=1&limit=20&category=categoryId&sort=newest
X-Client-Type: mobile
```

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 20)
- `category` (optional): Category ID filter
- `sort` (optional): Sort order (newest, oldest, popular)

**Response:**
```json
{
  "success": true,
  "data": {
    "articles": [
      {
        "id": "uuid",
        "title": "Article Title",
        "excerpt": "Article excerpt...",
        "author": {
          "id": "uuid",
          "username": "writer1",
          "avatar": "url"
        },
        "category": {
          "id": "uuid",
          "name": "Technology"
        },
        "publishedAt": "ISO-date",
        "readingTimeMinutes": 5,
        "likesCount": 42,
        "isLiked": false,
        "featuredImage": "url"
      }
    ],
    "pagination": {
      "total": 150,
      "page": 1,
      "limit": 20,
      "totalPages": 8
    }
  }
}
```

#### Get Featured Articles
```http
GET /api/v1/mobile/articles/featured
X-Client-Type: mobile
```

#### Get Trending Articles
```http
GET /api/v1/mobile/articles/trending
X-Client-Type: mobile
```

#### Search Articles
```http
GET /api/v1/mobile/articles/search?q=keyword&page=1&limit=20
X-Client-Type: mobile
```

#### Get Article by ID
```http
GET /api/v1/mobile/articles/:id
X-Client-Type: mobile
```

#### Get Articles by Author
```http
GET /api/v1/mobile/articles/author/:authorId?page=1&limit=20
X-Client-Type: mobile
```

#### Get Articles by Category
```http
GET /api/v1/mobile/articles/category/:categoryId?page=1&limit=20
X-Client-Type: mobile
```

#### Like Article
```http
POST /api/v1/mobile/articles/:id/like
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

#### Unlike Article  
```http
DELETE /api/v1/mobile/articles/:id/like
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

#### Toggle Like Status
```http
POST /api/v1/mobile/articles/:id/toggle-like
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

#### Get Like Status
```http
GET /api/v1/mobile/articles/:id/like-status
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

### Categories (`/categories`)

#### Get All Categories
```http
GET /api/v1/mobile/categories
X-Client-Type: mobile
```

**Response:**
```json
{
  "success": true,
  "data": {
    "categories": [
      {
        "id": "uuid",
        "name": "Technology",
        "slug": "technology",
        "description": "Tech articles",
        "articlesCount": 45,
        "featured": true
      }
    ]
  }
}
```

#### Get Category Tree
```http
GET /api/v1/mobile/categories/tree
X-Client-Type: mobile
```

#### Get Featured Categories
```http
GET /api/v1/mobile/categories/featured
X-Client-Type: mobile
```

#### Get Category Details
```http
GET /api/v1/mobile/categories/:id
X-Client-Type: mobile
```

#### Get Category Articles
```http
GET /api/v1/mobile/categories/:id/articles?page=1&limit=20
X-Client-Type: mobile
```

#### Get Subcategories
```http
GET /api/v1/mobile/categories/:id/subcategories
X-Client-Type: mobile
```

#### Subscribe to Category
```http
POST /api/v1/mobile/categories/:id/subscribe
Authorization: Bearer <access_token>
X-Client-Type: mobile
Content-Type: application/json

{
  "notificationEnabled": true,
  "priorityLevel": 5
}
```

#### Unsubscribe from Category
```http
DELETE /api/v1/mobile/categories/:id/subscribe
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

#### Get My Category Subscriptions
```http
GET /api/v1/mobile/categories/subscriptions/my
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

### Recommendations (`/recommendations`)

#### Get Personalized Recommendations
```http
GET /api/v1/mobile/recommendations/personal
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

#### Get Homepage Recommendations
```http
GET /api/v1/mobile/recommendations/homepage
X-Client-Type: mobile
```

#### Get Similar Articles
```http
GET /api/v1/mobile/recommendations/similar/:articleId?limit=5
X-Client-Type: mobile
```

#### Get Trending Recommendations
```http
GET /api/v1/mobile/recommendations/trending?period=24h&limit=10&category=categoryId
X-Client-Type: mobile
```

#### Get Category Recommendations
```http
GET /api/v1/mobile/recommendations/category/:categoryId?limit=10
X-Client-Type: mobile
```

#### Submit Recommendation Feedback
```http
POST /api/v1/mobile/recommendations/feedback
Authorization: Bearer <access_token>
X-Client-Type: mobile
Content-Type: application/json

{
  "recommendationId": "rec-uuid",
  "feedbackType": "like|dislike|not_interested|inappropriate",
  "feedbackValue": true,
  "reason": "optional reason",
  "articleId": "article-uuid"
}
```

#### Track Recommendation Interaction
```http
POST /api/v1/mobile/recommendations/interaction
Authorization: Bearer <access_token>
X-Client-Type: mobile
Content-Type: application/json

{
  "recommendationId": "rec-uuid",
  "interactionType": "impression|click|like|bookmark|share",
  "articleId": "article-uuid",
  "timeToInteraction": 1500,
  "context": "homepage"
}
```

#### Dismiss Recommendation
```http
POST /api/v1/mobile/recommendations/dismiss/:recommendationId
Authorization: Bearer <access_token>
X-Client-Type: mobile
Content-Type: application/json

{
  "reason": "not_interested"
}
```

#### Refresh Recommendations
```http
POST /api/v1/mobile/recommendations/refresh
Authorization: Bearer <access_token>
X-Client-Type: mobile
Content-Type: application/json

{
  "force": false
}
```

#### Get Recommendation Settings
```http
GET /api/v1/mobile/recommendations/settings
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

#### Update Recommendation Settings
```http
PUT /api/v1/mobile/recommendations/settings
Authorization: Bearer <access_token>
X-Client-Type: mobile
Content-Type: application/json

{
  "personalizedRecommendations": true,
  "includePopularContent": true,
  "diversityLevel": "medium",
  "noveltyPreference": 0.3,
  "difficultyRange": [2, 4],
  "contentTypes": ["article", "tutorial", "opinion"],
  "excludedCategories": [],
  "refreshFrequency": "daily",
  "notificationSettings": {
    "newRecommendations": true,
    "weeklyDigest": true,
    "trendingAlerts": false
  }
}
```

### Onboarding (`/onboarding`)

#### Get Onboarding Status
```http
GET /api/v1/mobile/onboarding/status
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

#### Get Onboarding Steps
```http
GET /api/v1/mobile/onboarding/steps
X-Client-Type: mobile
```

#### Set User Interests
```http
POST /api/v1/mobile/onboarding/interests
Authorization: Bearer <access_token>
X-Client-Type: mobile
Content-Type: application/json

{
  "categoryIds": ["tech-id", "business-id", "lifestyle-id"],
  "tagNames": ["programming", "startup", "productivity"],
  "customInterests": ["machine learning", "blockchain"]
}
```

#### Set Reading Preferences
```http
POST /api/v1/mobile/onboarding/reading-preferences
Authorization: Bearer <access_token>
X-Client-Type: mobile
Content-Type: application/json

{
  "preferredLength": "medium",
  "difficulty": 3,
  "readingTimeSlots": ["morning", "evening"],
  "dailyReadingGoal": 15,
  "preferredTopics": ["tutorials", "opinion"]
}
```

#### Set AI Personalization Consent
```http
POST /api/v1/mobile/onboarding/ai-consent
Authorization: Bearer <access_token>
X-Client-Type: mobile
Content-Type: application/json

{
  "aiPersonalizationConsent": true,
  "dataCollectionConsent": true
}
```

#### Complete Onboarding
```http
POST /api/v1/mobile/onboarding/complete
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

#### Skip Onboarding
```http
POST /api/v1/mobile/onboarding/skip
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

#### Restart Onboarding
```http
POST /api/v1/mobile/onboarding/restart
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

### User Profile (`/user`)
**Note:** All user endpoints are placeholder implementations returning mock responses. Database integration for user profiles, bookmarks, and reading history is pending implementation.

#### Get User Profile
```http
GET /api/v1/mobile/user/profile
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

#### Update Profile  
```http
PUT /api/v1/mobile/user/profile
Authorization: Bearer <access_token>
X-Client-Type: mobile
Content-Type: application/json

{
  "username": "new_username",
  "bio": "User bio",
  "avatar": "base64_image_data"
}
```

#### Get Reading History
```http
GET /api/v1/mobile/user/reading-history
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

#### Get Bookmarks
```http
GET /api/v1/mobile/user/bookmarks
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

#### Add Bookmark
```http
POST /api/v1/mobile/user/bookmarks/:articleId
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

#### Remove Bookmark
```http
DELETE /api/v1/mobile/user/bookmarks/:articleId
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

---

## Writer App API (`/api/v1/writer/`)

### Authentication (`/auth`)
Same endpoints as mobile auth with identical implementation but different client validation.

### Profile (`/profile`)

#### Get Writer Profile  
```http
GET /api/v1/writer/profile
Authorization: Bearer <access_token>
X-Client-Type: writer
```

**Note:** Placeholder implementation - returns mock response.

#### Update Writer Profile
```http
PUT /api/v1/writer/profile  
Authorization: Bearer <access_token>
X-Client-Type: writer
Content-Type: application/json

{
  "fullName": "Updated Name",
  "bio": "Updated bio...",
  "socialLinks": {
    "twitter": "https://twitter.com/username",
    "linkedin": "https://linkedin.com/in/username"
  }
}
```

**Note:** Placeholder implementation - returns mock response.

### Articles (`/articles`)

#### Create Article
```http
POST /api/v1/writer/articles
Authorization: Bearer <access_token>
X-Client-Type: writer
Content-Type: application/json

{
  "title": "Article Title",
  "content": "Full article content...",
  "excerpt": "Article excerpt...",
  "categoryId": "category-uuid",
  "tags": ["tag1", "tag2"],
  "featuredImage": "image-url",
  "targetAudience": ["beginner", "intermediate"],
  "isDraft": false
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "article": {
      "id": "article-uuid",
      "title": "Article Title",
      "slug": "article-title",
      "content": "Full content...",
      "excerpt": "Article excerpt...",
      "authorId": "writer-uuid",
      "categoryId": "category-uuid",
      "tags": ["tag1", "tag2"],
      "readingTimeMinutes": 5,
      "wordCount": 1200,
      "status": "draft",
      "createdAt": "ISO-date",
      "updatedAt": "ISO-date"
    }
  }
}
```

#### Get Writer's Articles
```http
GET /api/v1/writer/articles?page=1&limit=20&status=all&sortBy=updatedAt
Authorization: Bearer <access_token>
X-Client-Type: writer
```

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 20) 
- `status` (optional): Filter by status (draft, published, archived)
- `sortBy` (optional): Sort field (createdAt, updatedAt, title)

#### Get Writer Statistics
```http
GET /api/v1/writer/articles/stats
Authorization: Bearer <access_token>
X-Client-Type: writer
```

**Response:**
```json
{
  "success": true,
  "data": {
    "totalArticles": 25,
    "publishedArticles": 20,
    "draftArticles": 5,
    "totalViews": 15420,
    "totalLikes": 892,
    "averageReadingTime": 6.5
  }
}
```

#### Get Article by ID
```http
GET /api/v1/writer/articles/:id
Authorization: Bearer <access_token>
X-Client-Type: writer
```

#### Update Article
```http
PUT /api/v1/writer/articles/:id
Authorization: Bearer <access_token>
X-Client-Type: writer
Content-Type: application/json

{
  "title": "Updated Title",
  "content": "Updated content...",
  "excerpt": "Updated excerpt...",
  "tags": ["updated", "tags"]
}
```

#### Delete Article
```http
DELETE /api/v1/writer/articles/:id
Authorization: Bearer <access_token>
X-Client-Type: writer
```

#### Publish Article
```http
POST /api/v1/writer/articles/:id/publish
Authorization: Bearer <access_token>
X-Client-Type: writer
Content-Type: application/json

{
  "publishAt": "ISO-date", // Optional scheduled publish
  "notifySubscribers": true
}
```

#### Unpublish Article
```http
POST /api/v1/writer/articles/:id/unpublish
Authorization: Bearer <access_token>
X-Client-Type: writer
```

#### Archive Article
```http
POST /api/v1/writer/articles/:id/archive
Authorization: Bearer <access_token>
X-Client-Type: writer
```

### Analytics (`/analytics`)
**Note:** All analytics endpoints are placeholder implementations returning mock responses.

#### Get Analytics Overview
```http
GET /api/v1/writer/analytics/overview
Authorization: Bearer <access_token>
X-Client-Type: writer
```

#### Get Article Statistics
```http
GET /api/v1/writer/analytics/articles/:id/stats
Authorization: Bearer <access_token>
X-Client-Type: writer
```

#### Get Engagement Metrics
```http
GET /api/v1/writer/analytics/engagement
Authorization: Bearer <access_token>
X-Client-Type: writer
```

#### Get Revenue Analytics
```http
GET /api/v1/writer/analytics/revenue
Authorization: Bearer <access_token>
X-Client-Type: writer
```

### Dashboard (`/dashboard`)

#### Get Dashboard Metrics
```http
GET /api/v1/writer/dashboard/metrics
Authorization: Bearer <access_token>
X-Client-Type: writer
```

**Response:**
```json
{
  "success": true,
  "data": {
    "totalViews": 15420,
    "totalLikes": 892,
    "subscribersCount": 234,
    "totalArticles": 25,
    "publishedArticles": 20,
    "draftArticles": 5,
    "averageEngagement": 8.5,
    "weeklyViews": 1250,
    "weeklyLikes": 85,
    "weeklySubscribers": 12
  }
}
```

#### Get Real-time Dashboard Data
```http
GET /api/v1/writer/dashboard/realtime
Authorization: Bearer <access_token>
X-Client-Type: writer
```

#### Get Detailed Dashboard Data
```http
GET /api/v1/writer/dashboard/detailed
Authorization: Bearer <access_token>
X-Client-Type: writer
```

#### Get Dashboard Data by Period
```http
GET /api/v1/writer/dashboard/period?period=week&startDate=2024-01-01&endDate=2024-01-07
Authorization: Bearer <access_token>
X-Client-Type: writer
```

#### Get Dashboard Comparison Data
```http
GET /api/v1/writer/dashboard/comparison?period=month
Authorization: Bearer <access_token>
X-Client-Type: writer
```

### Categories (`/categories`)

#### Get All Categories (Read-only)
```http
GET /api/v1/writer/categories
Authorization: Bearer <access_token>
X-Client-Type: writer
```

### Drafts (`/drafts`)
**Note:** All draft endpoints are placeholder implementations returning mock responses.

#### Get Drafts
```http
GET /api/v1/writer/drafts
Authorization: Bearer <access_token>
X-Client-Type: writer
```

#### Create Draft
```http
POST /api/v1/writer/drafts
Authorization: Bearer <access_token>
X-Client-Type: writer
Content-Type: application/json

{
  "title": "Draft Title",
  "content": "Draft content..."
}
```

#### Update Draft
```http
PUT /api/v1/writer/drafts/:id
Authorization: Bearer <access_token>
X-Client-Type: writer
Content-Type: application/json

{
  "title": "Updated Draft Title",
  "content": "Updated draft content..."
}
```

#### Delete Draft
```http
DELETE /api/v1/writer/drafts/:id
Authorization: Bearer <access_token>
X-Client-Type: writer
```

#### Auto-save Draft
```http
POST /api/v1/writer/drafts/:id/autosave
Authorization: Bearer <access_token>
X-Client-Type: writer
Content-Type: application/json

{
  "title": "Draft title",
  "content": "Current content...",
  "lastModified": "ISO-date"
}
```

---

## Admin Panel API (`/api/v1/admin/`)

### Authentication (`/auth`)

#### Admin Login
```http
POST /api/v1/admin/auth/login
Content-Type: application/json
X-Client-Type: admin

{
  "email": "admin@paperly.com",
  "password": "admin_password"
}
```

**Security:** Rate-limited to 5 requests per 15 minutes

#### Refresh Admin Token
```http
POST /api/v1/admin/auth/refresh
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### Admin Logout
```http
POST /api/v1/admin/auth/logout
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### Get Current Admin User
```http
GET /api/v1/admin/auth/me
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### Verify Admin Status
```http
GET /api/v1/admin/auth/verify
X-Client-Type: admin
```

### User Management (`/users`)
**Note:** Most user endpoints are placeholder implementations returning mock responses.

#### List All Users
```http
GET /api/v1/admin/users?page=1&limit=50&search=keyword&role=all
Authorization: Bearer <access_token>
X-Client-Type: admin
```

**Permissions Required:** admin role

#### Get Admin Users
```http
GET /api/v1/admin/users/admins
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### Get User Details
```http
GET /api/v1/admin/users/:id
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### Update User
```http
PUT /api/v1/admin/users/:id
Authorization: Bearer <access_token>
X-Client-Type: admin
Content-Type: application/json

{
  "name": "Updated Name",
  "email": "updated@example.com",
  "status": "active"
}
```

#### Delete User (Super Admin Only)
```http
DELETE /api/v1/admin/users/:id
Authorization: Bearer <access_token>
X-Client-Type: admin
```

**Permissions Required:** super_admin role

#### Assign Role to User (Super Admin Only)
```http
POST /api/v1/admin/users/:userId/assign-role
Authorization: Bearer <access_token>
X-Client-Type: admin
Content-Type: application/json

{
  "roleId": "writer",
  "expiresAt": "ISO-date" // Optional
}
```

#### Remove Role from User (Super Admin Only)
```http
DELETE /api/v1/admin/users/:userId/remove-role
Authorization: Bearer <access_token>
X-Client-Type: admin
```

### Writer Management (`/writers`)
**Note:** All writer endpoints are placeholder implementations returning mock responses.

#### Get All Writers
```http
GET /api/v1/admin/writers
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### Get Pending Writer Applications
```http
GET /api/v1/admin/writers/pending
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### Approve Writer Application
```http
PUT /api/v1/admin/writers/:id/approve
Authorization: Bearer <access_token>
X-Client-Type: admin
Content-Type: application/json

{
  "reason": "Approval reason",
  "permissions": ["article:create", "article:publish"]
}
```

#### Reject Writer Application
```http
PUT /api/v1/admin/writers/:id/reject
Authorization: Bearer <access_token>
X-Client-Type: admin
Content-Type: application/json

{
  "reason": "Rejection reason"
}
```

#### Get Writer Analytics
```http
GET /api/v1/admin/writers/:id/analytics
Authorization: Bearer <access_token>
X-Client-Type: admin
```

### Content Management (`/articles`)

#### List All Articles
```http
GET /api/v1/admin/articles?page=1&limit=50&status=all&author=author-id
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### Create Article (Admin)
```http
POST /api/v1/admin/articles
Authorization: Bearer <access_token>
X-Client-Type: admin
Content-Type: application/json

{
  "title": "Admin Article",
  "content": "Article content...",
  "authorId": "writer-uuid",
  "categoryId": "category-uuid"
}
```

#### Get Article Details
```http
GET /api/v1/admin/articles/:id
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### Update Article
```http
PUT /api/v1/admin/articles/:id
Authorization: Bearer <access_token>
X-Client-Type: admin
Content-Type: application/json

{
  "title": "Updated Title",
  "content": "Updated content..."
}
```

#### Delete Article
```http
DELETE /api/v1/admin/articles/:id
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### Feature Article
```http
PATCH /api/v1/admin/articles/:id/feature
Authorization: Bearer <access_token>
X-Client-Type: admin
Content-Type: application/json

{
  "featured": true,
  "featuredOrder": 1
}
```

#### Unfeature Article
```http
PATCH /api/v1/admin/articles/:id/unfeature
Authorization: Bearer <access_token>
X-Client-Type: admin
```

### Category Management (`/categories`)

#### List Categories
```http
GET /api/v1/admin/categories
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### Create Category
```http
POST /api/v1/admin/categories
Authorization: Bearer <access_token>
X-Client-Type: admin
Content-Type: application/json

{
  "name": "New Category",
  "description": "Category description",
  "slug": "new-category"
}
```

**Note:** Placeholder implementation - returns mock response.

#### Update Category
```http
PUT /api/v1/admin/categories/:id
Authorization: Bearer <access_token>
X-Client-Type: admin
Content-Type: application/json

{
  "name": "Updated Category",
  "description": "Updated description"
}
```

**Note:** Placeholder implementation - returns mock response.

#### Delete Category
```http
DELETE /api/v1/admin/categories/:id
Authorization: Bearer <access_token>
X-Client-Type: admin
```

**Note:** Placeholder implementation - returns mock response.

### Security Monitoring (`/security`)

#### Get Security Events Log
```http
GET /api/v1/admin/security/events?page=1&limit=50&type=all&severity=high
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### Get Security Event Details
```http
GET /api/v1/admin/security/events/:eventId
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### Get Security Statistics
```http
GET /api/v1/admin/security/stats
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### Block IP Address
```http
POST /api/v1/admin/security/block-ip
Authorization: Bearer <access_token>
X-Client-Type: admin
Content-Type: application/json

{
  "ip": "192.168.1.100",
  "reason": "Suspicious activity",
  "duration": 24 // hours
}
```

#### Unblock IP Address
```http
DELETE /api/v1/admin/security/unblock-ip/:ip
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### Get Blocked IPs
```http
GET /api/v1/admin/security/blocked-ips
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### Update Event Status
```http
PATCH /api/v1/admin/security/events/:eventId/status
Authorization: Bearer <access_token>
X-Client-Type: admin
Content-Type: application/json

{
  "status": "resolved", // detected | investigating | blocked | resolved | false_positive
  "notes": "Event resolved - false positive"
}
```

#### Real-time Event Stream (Server-Sent Events)
```http
GET /api/v1/admin/security/events/stream
Authorization: Bearer <access_token>
X-Client-Type: admin
Accept: text/event-stream
```

### System Management (`/system`)

#### Health Check
```http
GET /api/v1/admin/system/health
X-Client-Type: admin
```

**Response:**
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "timestamp": "ISO-date",
    "version": "1.0.0"
  },
  "message": "관리자 API 서버가 정상 작동 중입니다"
}
```

#### Get System Statistics (Not Implemented)
```http
GET /api/v1/admin/system/stats
Authorization: Bearer <access_token>
X-Client-Type: admin
```

**Response:** 501 Not Implemented

#### Get System Settings (Super Admin Only - Not Implemented)
```http
GET /api/v1/admin/system/settings
Authorization: Bearer <access_token>
X-Client-Type: admin
```

**Permissions Required:** super_admin role  
**Response:** 501 Not Implemented

#### Update System Settings (Super Admin Only - Not Implemented)
```http
PUT /api/v1/admin/system/settings
Authorization: Bearer <access_token>
X-Client-Type: admin
Content-Type: application/json
```

**Permissions Required:** super_admin role  
**Response:** 501 Not Implemented

#### Get System Logs (Not Implemented)
```http
GET /api/v1/admin/system/logs?level=error&limit=100
Authorization: Bearer <access_token>
X-Client-Type: admin
```

**Permissions Required:** logs:read permission  
**Response:** 501 Not Implemented

---

## Legacy API Endpoints (Deprecated)

**⚠️ Deprecation Notice:** These endpoints are maintained for backward compatibility but should not be used in new implementations. All clients should migrate to the client-specific endpoints above.

### Legacy Authentication (`/api/v1/auth`)
- `POST /api/v1/auth/register` - Same as mobile registration
- `POST /api/v1/auth/login` - Same as mobile login
- `POST /api/v1/auth/refresh` - Same as mobile token refresh
- `POST /api/v1/auth/logout` - Same as mobile logout
- `GET /api/v1/auth/verify-email` - Same as mobile email verification
- `POST /api/v1/auth/resend-verification` - Same as mobile resend verification

### Legacy Articles (`/api/v1/articles`)
- All endpoints from ArticleController (legacy implementation)

### Legacy Categories (`/api/v1/categories`)
- Same endpoints as mobile categories

### Legacy Recommendations (`/api/v1/recommendations`)
- Same endpoints as mobile recommendations

### Legacy Onboarding (`/api/v1/onboarding`)
- Same endpoints as mobile onboarding

**Migration Timeline:**
- **Current:** Legacy endpoints functional
- **Q2 2025:** Deprecation warnings added
- **Q4 2025:** Legacy endpoints removed

---

## Response Format

### Success Response
```json
{
  "success": true,
  "message": "Operation successful",
  "data": {
    // Response payload
  },
  "meta": {
    "timestamp": "2025-01-20T10:00:00Z",
    "requestId": "uuid-v4",
    "version": "1.0.0"
  }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error description",
  "error": {
    "code": "ERROR_CODE",
    "message": "Detailed error message",
    "details": {}
  },
  "meta": {
    "timestamp": "2025-01-20T10:00:00Z",
    "requestId": "uuid-v4"
  }
}
```

### Common Error Codes

#### Authentication Errors
- `TOKEN_EXPIRED`: Access token has expired
- `TOKEN_INVALID`: Malformed or invalid token
- `REFRESH_TOKEN_EXPIRED`: Refresh token expired
- `DEVICE_MISMATCH`: Device ID doesn't match
- `INSUFFICIENT_PERMISSIONS`: User lacks required permissions
- `ACCOUNT_LOCKED`: Account temporarily locked
- `TOO_MANY_ATTEMPTS`: Rate limit exceeded

#### Validation Errors
- `VALIDATION_ERROR`: Request validation failed
- `INVALID_INPUT`: Invalid input data
- `REQUIRED_FIELD_MISSING`: Required field is missing
- `INVALID_EMAIL_FORMAT`: Email format is invalid
- `PASSWORD_TOO_WEAK`: Password doesn't meet requirements

#### Business Logic Errors
- `RESOURCE_NOT_FOUND`: Requested resource not found
- `DUPLICATE_RESOURCE`: Resource already exists
- `OPERATION_NOT_ALLOWED`: Operation not permitted
- `QUOTA_EXCEEDED`: User quota exceeded

#### System Errors
- `INTERNAL_SERVER_ERROR`: Unexpected server error
- `SERVICE_UNAVAILABLE`: Service temporarily unavailable
- `DATABASE_ERROR`: Database operation failed

---

## Security Features

### JWT Token Management
- **Short-lived Access Tokens**: 15-minute expiry reduces exposure
- **Token Rotation**: Refresh tokens are one-time use
- **Device Tracking**: Multi-device support with device identification
- **Automatic Cleanup**: Expired tokens automatically removed

### Request Security
- **Rate Limiting**: Protection against brute force attacks
- **CORS Policy**: Client-specific origins allowed
- **Security Headers**: Helmet.js implementation
- **Input Validation**: Comprehensive validation and sanitization
- **SQL Injection Protection**: Parameterized queries only

### Monitoring & Auditing
- **Real-time Threat Detection**: Risk assessment for suspicious activities
- **Comprehensive Logging**: Full audit trail for security events
- **IP Address Tracking**: Monitor and block suspicious IPs
- **Session Management**: Track and manage user sessions

---

## Client-Specific Features

### Mobile App
- Read-only access to articles and recommendations
- Personalized content based on reading patterns
- Bookmark and reading history management
- Push notification support for updates

### Writer App
- Full CRUD operations on own articles
- Draft management with auto-save functionality
- Real-time analytics dashboard with WebSocket updates
- Revenue tracking and payout information
- Publishing workflow with approval process

### Admin Panel
- Comprehensive user and role management
- Content moderation and approval workflows
- Real-time security monitoring with event streaming
- System configuration and settings management
- Platform-wide analytics and reporting

---

## Versioning & Deprecation

### API Versioning
- Current version: `v1`
- Version specified in URL path: `/api/v1/`
- Backward compatibility maintained for minor versions

### Deprecation Policy
- **Legacy endpoints** without client prefix (e.g., `/api/auth`) are deprecated
- **Migration period**: 6 months before removal
- **Deprecation headers**: `X-API-Deprecated: true` with migration instructions
- **All clients** should migrate to client-specific endpoints

### Migration Path
```
Old: /api/v1/auth/login (legacy)
New: /api/v1/mobile/auth/login (for mobile)
New: /api/v1/writer/auth/login (for writer)
New: /api/v1/admin/auth/login (for admin)
```

---

## Database Schema

### Overview
PostgreSQL database with 33 tables organized by domain:

- **User Domain**: users, profiles, settings, sessions
- **Content Domain**: articles, categories, tags, authors
- **Interaction Domain**: likes, bookmarks, comments, follows
- **Analytics Domain**: reading_sessions, metrics, logs
- **System Domain**: configs, migrations, jobs

### Key Relationships
```
users ─┬─< articles (author)
       ├─< reading_sessions
       ├─< bookmarks
       └─< user_follows

articles ─┬─< article_tags >── tags
          ├─< article_likes
          └─< reading_sessions

categories ──< articles
```

### Database Links
- [Full Schema](../../docs/database/schema.sql)
- [ERD Diagram](../../docs/database/erd.png)
- [Migration Guide](../../docs/database/migrations.md)

---

## Testing

### Test Structure
```
tests/
├── unit/           # Business logic tests
├── integration/    # API integration tests
└── e2e/           # End-to-end tests
```

### Running Tests
```bash
# All tests
npm test

# Unit tests only
npm test -- unit

# Integration tests
npm test -- integration

# With coverage
npm test -- --coverage
```

### Testing Guidelines
1. Write tests first (TDD approach)
2. Mock external dependencies
3. Test edge cases and errors
4. Maintain 80%+ coverage
5. Use descriptive test names

---

## Deployment

### Development Pipeline
```
Local → GitHub → CI/CD → Staging → Production
```

### Build Process
```bash
# Build TypeScript
npm run build

# Run production
npm start
```

### Docker Deployment
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build
CMD ["npm", "start"]
```

### Health Checks
- `GET /health` - Basic health check
- `GET /health/ready` - Readiness probe
- `GET /health/live` - Liveness probe

---

## Troubleshooting

### Common Issues

#### Database Connection Failed
```bash
# Check PostgreSQL
docker ps | grep postgres

# Test connection
npm run db:check

# Check credentials
echo $DATABASE_URL
```

#### Port Already in Use
```bash
# Find process
lsof -i :3000

# Kill process
kill -9 <PID>

# Use different port
PORT=3001 npm run dev
```

#### TypeScript Errors
```bash
# Clean build
rm -rf dist
npm run build

# Check tsconfig
npx tsc --noEmit
```

### Debug Mode
```bash
# Enable all debug logs
DEBUG=* npm run dev

# Specific namespace
DEBUG=paperly:* npm run dev
```

### Logs Location
- Development: Console output
- Production: `logs/` directory
- Error logs: `logs/error.log`
- Combined logs: `logs/combined.log`

---

## Best Practices

### Code Quality
1. Follow TypeScript strict mode
2. Use dependency injection
3. Write pure functions
4. Handle errors explicitly
5. Log important operations

### Security
1. Validate all inputs
2. Use parameterized queries
3. Implement rate limiting
4. Audit dependencies regularly
5. Follow OWASP guidelines

### Performance
1. Use database indexes
2. Implement caching strategy
3. Paginate large datasets
4. Optimize N+1 queries
5. Monitor response times

---

## Support

### Getting Help
- **Docs**: Check `/docs` folder
- **Team Chat**: Slack #backend channel
- **Issues**: GitHub issue tracker

### Useful Links
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

---

*Last Updated: January 2025*  
*Version: 1.0.0*  
*Maintainer: Backend Team*