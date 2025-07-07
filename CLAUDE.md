# Paperly Developer Documentation

This comprehensive guide provides everything you need to understand, develop, and contribute to the Paperly platform. It serves as the primary reference for developers working with Claude Code or any IDE.

## Table of Contents

1. [Project Overview](#project-overview)
2. [System Architecture](#system-architecture)
3. [Technology Stack](#technology-stack)
4. [Project Structure](#project-structure)
5. [Development Environment](#development-environment)
6. [API Documentation](#api-documentation)
7. [Database Schema](#database-schema)
8. [Development Guidelines](#development-guidelines)
9. [Security & Authentication](#security--authentication)
10. [Testing Strategy](#testing-strategy)
11. [Deployment & Operations](#deployment--operations)
12. [Troubleshooting](#troubleshooting)

---

## Project Overview

### Vision
Paperly is an AI-powered personalized learning platform that transforms how people consume and retain knowledge in the digital age. By combining AI curation with minimalist design principles, we create a sustainable learning ecosystem that promotes deep thinking and knowledge preservation.

### Core Problem
The platform addresses three critical challenges:
1. **Attention Economy Crisis**: Average attention span has decreased by 74% since 2000
2. **Knowledge Volatility**: Digital content retention rate is only 5% after 3 days
3. **Environmental Impact**: Reducing digital carbon footprint by 98.8%

### Solution
Paperly delivers personalized daily learning content through:
- AI-curated articles tailored to individual interests
- Minimalist, distraction-free reading experience
- Offline-first architecture for better retention
- Multi-client ecosystem (Mobile, Writer, Admin)

### Key Metrics
- **Target**: App store launch within 40-day sprint
- **Users**: B2C readers, content creators, platform administrators
- **Scale**: Designed for 100K+ concurrent users

---

## System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Client Applications                         │
├─────────────────┬─────────────────┬─────────────────────────────────┤
│   Mobile App    │   Writer App    │         Admin Panel             │
│   (Flutter)     │   (Next.js)     │         (Next.js)               │
└────────┬────────┴────────┬────────┴────────┬────────────────────────┘
         │                 │                 │
         └─────────────────┴─────────────────┘
                           │
                    ┌──────▼──────┐
                    │   API Gateway│
                    │  (Express.js)│
                    └──────┬──────┘
                           │
     ┌─────────────────────┼─────────────────────┐
     │                     │                     │
┌────▼─────┐      ┌────────▼────────┐   ┌───────▼────────┐
│  Backend │      │  AI Service     │   │ Notification   │
│   API    │◄─────┤  (Python/       │   │   Service      │
│(Node.js) │      │   OpenAI)       │   │   (Node.js)    │
└────┬─────┘      └─────────────────┘   └────────────────┘
     │
     ├──────────────┬──────────────┬────────────────┐
     │              │              │                │
┌────▼─────┐  ┌────▼────┐  ┌──────▼─────┐  ┌──────▼──────┐
│PostgreSQL│  │  Redis  │  │   Email    │  │   Storage   │
│    15    │  │  Cache  │  │  Service   │  │   (S3)      │
└──────────┘  └─────────┘  └────────────┘  └─────────────┘
```

### Architecture Principles
- **Clean Architecture**: Separation of concerns with clear boundaries
- **Domain-Driven Design (DDD)**: Business logic at the core
- **Microservices Ready**: Modular design for future scaling
- **Event-Driven**: Asynchronous communication where appropriate
- **API-First**: All functionality exposed through well-defined APIs

---

## Technology Stack

### Backend Services
| Component | Technology | Purpose |
|-----------|------------|---------|
| Runtime | Node.js 20.x | Server runtime |
| Language | TypeScript 5.x | Type safety |
| Framework | Express.js | HTTP server |
| Database | PostgreSQL 15 | Primary data store |
| Cache | Redis 7.x | Session & cache |
| ORM | TypeORM | Database abstraction |
| Validation | Zod | Schema validation |
| DI | TSyringe | Dependency injection |
| Testing | Jest + Supertest | Unit & integration tests |
| Logging | Winston | Structured logging |
| Auth | JWT + bcrypt | Security |

### Mobile Application
| Component | Technology | Purpose |
|-----------|------------|---------|
| Framework | Flutter 3.32+ | Cross-platform UI |
| Language | Dart | Mobile development |
| State | Riverpod | State management |
| HTTP | Dio | Network requests |
| Storage | SharedPreferences | Local storage |
| Auth | flutter_secure_storage | Secure token storage |

### Infrastructure
| Component | Technology | Purpose |
|-----------|------------|---------|
| Containers | Docker | Development environment |
| Orchestration | Docker Compose | Service management |
| Monitoring | Winston + Sentry | Error tracking |
| CI/CD | GitHub Actions | Automation |

---

## Project Structure

### Repository Organization
```
paperly/
├── apps/                      # Application workspaces
│   ├── backend/              # Node.js API server
│   │   ├── src/
│   │   │   ├── domain/       # Business logic & entities
│   │   │   │   ├── entities/        # Core business objects
│   │   │   │   ├── value-objects/   # Domain primitives
│   │   │   │   ├── repositories/    # Data access interfaces
│   │   │   │   └── services/        # Domain services
│   │   │   ├── application/  # Use cases & DTOs
│   │   │   │   ├── auth/           # Authentication use cases
│   │   │   │   ├── content/        # Content management
│   │   │   │   ├── user/           # User management
│   │   │   │   └── recommendation/ # AI recommendations
│   │   │   ├── infrastructure/ # External dependencies
│   │   │   │   ├── database/      # TypeORM implementations
│   │   │   │   ├── cache/         # Redis implementations
│   │   │   │   ├── email/         # Email providers
│   │   │   │   ├── ai/            # AI service integration
│   │   │   │   └── security/      # Security implementations
│   │   │   ├── presentation/  # API layer
│   │   │   │   ├── controllers/   # Request handlers
│   │   │   │   ├── routes/        # Route definitions
│   │   │   │   ├── middleware/    # Express middleware
│   │   │   │   └── validators/    # Request validation
│   │   │   └── shared/        # Cross-cutting concerns
│   │   │       ├── errors/        # Error definitions
│   │   │       ├── utils/         # Utility functions
│   │   │       └── types/         # Shared types
│   │   ├── tests/            # Test suites
│   │   ├── scripts/          # Utility scripts
│   │   └── config/           # Configuration files
│   ├── mobile/               # Flutter mobile app
│   │   ├── lib/
│   │   │   ├── core/             # Core functionality
│   │   │   ├── data/             # Data layer
│   │   │   ├── domain/           # Business logic
│   │   │   ├── presentation/     # UI layer
│   │   │   └── main.dart         # Entry point
│   │   ├── assets/           # Images, fonts, etc.
│   │   ├── test/             # Flutter tests
│   │   └── pubspec.yaml      # Dependencies
│   ├── writer/               # Writer dashboard (Next.js)
│   └── admin/                # Admin panel (Next.js)
├── packages/                 # Shared packages
│   └── shared-types/        # TypeScript types
├── infrastructure/          # Docker & deployment
│   ├── docker/             # Dockerfiles
│   └── docker-compose.yml  # Service orchestration
├── docs/                    # Additional documentation
│   ├── api/                # API specifications
│   ├── database/           # DB schema & migrations
│   └── architecture/       # Architecture decisions
├── scripts/                # Global scripts
└── logs/                   # Development logs
    └── work-history/       # Monthly progress logs
```

### Key Design Patterns
1. **Repository Pattern**: Abstract data access behind interfaces
2. **Use Case Pattern**: Encapsulate business operations
3. **Value Objects**: Type-safe domain primitives
4. **Dependency Injection**: Loose coupling via TSyringe
5. **DTO Pattern**: Separate API contracts from domain

---

## Development Environment

### Prerequisites
- Node.js 20.x or higher
- npm 10.x or higher
- Docker & Docker Compose
- Flutter SDK 3.32+
- Git

### Quick Start

#### 1. Clone Repository
```bash
git clone https://github.com/your-org/paperly.git
cd paperly
```

#### 2. Install Dependencies
```bash
npm install  # Installs all workspace dependencies
```

#### 3. Environment Configuration
```bash
# Copy environment template
cp apps/backend/.env.example apps/backend/.env

# Generate secure secrets
openssl rand -hex 32  # For JWT_ACCESS_SECRET
openssl rand -hex 32  # For JWT_REFRESH_SECRET
```

#### 4. Start Development Environment
```bash
# Start everything (Docker + Backend)
npm run dev

# Or run services separately
npm run dev:docker      # PostgreSQL + Redis
npm run dev:backend     # Backend API only
npm run dev:mobile      # Flutter app
```

#### 5. Verify Setup
```bash
# Check database connection
npm run db:check

# Run tests
npm run test

# Check API health
curl http://localhost:3000/api/v1/health
```

### Development Commands

| Command | Description |
|---------|-------------|
| `npm run dev` | Start full development environment |
| `npm run dev:backend` | Start backend server only |
| `npm run dev:mobile` | Run Flutter mobile app |
| `npm run dev:wsl` | Special mode for WSL environments |
| `npm run build` | Build all applications |
| `npm run test` | Run all test suites |
| `npm run lint` | Lint all code |
| `npm run docker:stop` | Stop Docker containers |
| `npm run docker:reset` | Reset containers and volumes |
| `npm run db:seed` | Seed development data |

### Path Aliases (TypeScript)
```typescript
// Available path aliases in backend
import { User } from '@domain/entities/user.entity';
import { LoginUseCase } from '@application/auth/login.usecase';
import { DatabaseConfig } from '@infrastructure/database/config';
import { AppError } from '@shared/errors/app-error';

// Alias mapping
@/*               → src/*
@domain/*         → src/domain/*
@application/*    → src/application/*
@infrastructure/* → src/infrastructure/*
@shared/*         → src/shared/*
```

---

## API Documentation

### Base URL Structure
```
https://api.paperly.com/api/{version}/{client}/{resource}
```

- **Version**: API version (e.g., `v1`)
- **Client**: Target client (`mobile`, `writer`, `admin`)
- **Resource**: API resource path

## Complete API Specifications

**📖 Full API specifications are available in [apps/backend/CLAUDE.md](./apps/backend/CLAUDE.md)**

The backend documentation contains comprehensive API specifications for all three client applications:

### API Coverage by Client

#### Mobile App API (`/api/v1/mobile/`)
- **Authentication**: Registration, login, token refresh, email verification
- **Articles**: Feed browsing, search, article details, reading tracking
- **User Profile**: Profile management, reading history, bookmarks
- **Recommendations**: Personalized, trending, and latest content
- **Categories**: Content organization and filtering
- **Onboarding**: Topic selection and preference setup

#### Writer App API (`/api/v1/writer/`)
- **Authentication**: Writer-specific login with enhanced profile data
- **Profile Management**: Bio, avatar, social links, statistics
- **Article Management**: Full CRUD operations, publishing workflow
- **Draft System**: Auto-save, versioning, draft-to-article conversion
- **Analytics**: Performance metrics, engagement data, revenue tracking
- **Dashboard**: Summary views, activity feeds, notifications

#### Admin Panel API (`/api/v1/admin/`)
- **Authentication**: Admin login with enhanced security
- **User Management**: User administration, role assignment, account management
- **Writer Management**: Application approval, writer analytics
- **Content Moderation**: Article approval, content management
- **Security Monitoring**: Event tracking, IP management, threat detection
- **System Management**: Configuration, health checks, system logs

### Quick Reference

#### Base URL Structure
```
https://api.paperly.com/api/v1/{client}/{resource}
```

#### Authentication
```http
Authorization: Bearer {access_token}
X-Client-Type: mobile|writer|admin
X-Device-ID: {device_uuid}
```

#### Standard Response Format
```json
{
  "success": true,
  "data": { /* response payload */ },
  "meta": { "timestamp": "ISO-date", "requestId": "uuid" }
}
```

### Security & Rate Limiting
- **JWT Tokens**: 15-minute access tokens, 7-day refresh tokens
- **Rate Limits**: 5 auth requests, 100 API requests per 15 minutes
- **Device Tracking**: Multi-device session management
- **Security Monitoring**: Real-time threat detection and IP blocking

For detailed endpoint specifications, request/response examples, error codes, and implementation notes, see the [complete API documentation](./apps/backend/CLAUDE.md).

---

## Database Schema

### Overview
The database consists of 33 tables organized into logical domains:

```
┌─────────────────────────────────────────────────────────┐
│                    Database Schema                       │
├──────────────┬────────────────┬────────────────────────┤
│ User Domain  │ Content Domain │ Analytics Domain       │
├──────────────┼────────────────┼────────────────────────┤
│ • users      │ • articles     │ • reading_sessions     │
│ • profiles   │ • categories   │ • user_activity_logs   │
│ • settings   │ • tags         │ • daily_stats          │
│ • interests  │ • authors      │ • recommendation_logs  │
├──────────────┼────────────────┼────────────────────────┤
│ Auth Domain  │ Subscription   │ System Domain          │
├──────────────┼────────────────┼────────────────────────┤
│ • tokens     │ • plans        │ • system_configs       │
│ • sessions   │ • subscriptions│ • common_codes         │
│ • devices    │ • payments     │ • error_logs           │
└──────────────┴────────────────┴────────────────────────┘
```

### Key Entities

#### Users
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Articles
```sql
CREATE TABLE articles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    summary TEXT,
    author_id UUID REFERENCES authors(id),
    category_id UUID REFERENCES categories(id),
    reading_time INT NOT NULL,
    published_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Reading Sessions
```sql
CREATE TABLE reading_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    article_id UUID REFERENCES articles(id),
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    duration INT,
    scroll_depth DECIMAL(3,2),
    completed BOOLEAN DEFAULT false
);
```

### Database Documentation Links
- [Complete Schema](./docs/database/schema.sql)
- [Entity Relationship Diagram](./docs/database/erd.png)
- [Migration Guide](./docs/database/migrations.md)

---

## Development Guidelines

### Code Style

#### TypeScript/JavaScript
- Use ESLint configuration provided
- Prefer functional programming patterns
- Use async/await over callbacks
- Implement proper error handling

```typescript
// ✅ Good
export class CreateUserUseCase {
  async execute(dto: CreateUserDto): Promise<Result<User>> {
    try {
      const email = Email.create(dto.email);
      if (email.isFailure) {
        return Result.fail(email.error);
      }
      // ... implementation
    } catch (error) {
      return Result.fail(new AppError.UnexpectedError(error));
    }
  }
}

// ❌ Bad
export class CreateUserUseCase {
  execute(dto) {
    // No types, no error handling
    const user = new User(dto);
    return user.save();
  }
}
```

#### Flutter/Dart
- Follow Flutter style guide
- Use Riverpod for state management
- Implement proper error boundaries

```dart
// ✅ Good
class ArticleRepository {
  final Dio _dio;
  
  ArticleRepository(this._dio);
  
  Future<Either<Failure, Article>> getArticle(String id) async {
    try {
      final response = await _dio.get('/articles/$id');
      return Right(Article.fromJson(response.data));
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Unknown error'));
    }
  }
}
```

### Git Workflow

#### Branch Naming
- `feature/description` - New features
- `fix/description` - Bug fixes
- `refactor/description` - Code refactoring
- `docs/description` - Documentation updates

#### Commit Messages
Follow conventional commits:
```
feat: add user authentication
fix: resolve token refresh issue
docs: update API documentation
refactor: simplify validation logic
test: add auth service tests
```

### Testing Requirements

#### Backend Testing
```typescript
// Unit tests for business logic
describe('CreateUserUseCase', () => {
  it('should create user with valid data', async () => {
    // Arrange
    const dto = { email: 'test@example.com', password: 'Test123!' };
    
    // Act
    const result = await useCase.execute(dto);
    
    // Assert
    expect(result.isSuccess).toBe(true);
    expect(result.getValue().email.value).toBe(dto.email);
  });
});

// Integration tests for APIs
describe('POST /auth/register', () => {
  it('should register new user', async () => {
    const response = await request(app)
      .post('/api/v1/mobile/auth/register')
      .send({ email: 'test@example.com', password: 'Test123!' });
      
    expect(response.status).toBe(201);
    expect(response.body.success).toBe(true);
  });
});
```

#### Mobile Testing
```dart
// Widget tests
testWidgets('Login button shows loading state', (tester) async {
  await tester.pumpWidget(LoginScreen());
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();
  
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

---

## Security & Authentication

### JWT Configuration
- **Access Token**: 15 minutes expiry
- **Refresh Token**: 7 days with rotation
- **Algorithm**: RS256 for production, HS256 for development

### Security Headers
```typescript
// Helmet.js configuration
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true,
  },
}));
```

### Security Best Practices
1. **Input Validation**: All inputs validated with Zod
2. **SQL Injection**: Use parameterized queries
3. **XSS Prevention**: Sanitize all user content
4. **Rate Limiting**: Implement per-endpoint limits
5. **CORS**: Strict origin validation
6. **Secrets**: Use environment variables
7. **Logging**: Never log sensitive data

### Device Tracking
```typescript
interface DeviceInfo {
  deviceId: string;
  platform: 'ios' | 'android' | 'web';
  appVersion: string;
  osVersion: string;
  lastSeen: Date;
}
```

---

## Testing Strategy

### Test Pyramid
```
         ┌─────┐
        /  E2E  \       5%
       /─────────\
      / Integration\    25%
     /──────────────\
    /   Unit Tests   \  70%
   └──────────────────┘
```

### Coverage Requirements
- Unit Tests: 80% minimum
- Integration Tests: Critical paths
- E2E Tests: User journeys

### Running Tests
```bash
# Run all tests
npm run test

# Run with coverage
npm run test:coverage

# Run specific suite
npm run test:unit
npm run test:integration
npm run test:e2e

# Mobile tests
cd apps/mobile && flutter test
```

---

## Deployment & Operations

### Environment Strategy
```
┌──────────┐    ┌──────────┐    ┌────────────┐
│   Local  │───▶│ Staging  │───▶│ Production │
└──────────┘    └──────────┘    └────────────┘
```

### Infrastructure Requirements

#### Production
- **API Server**: 2 vCPU, 4GB RAM minimum
- **Database**: PostgreSQL 15, 100GB SSD
- **Redis**: 2GB RAM
- **CDN**: CloudFlare for static assets

#### Monitoring
- **APM**: Sentry for error tracking
- **Logs**: Winston with daily rotation
- **Metrics**: Custom dashboards
- **Alerts**: PagerDuty integration

### Deployment Checklist
- [ ] All tests passing
- [ ] Environment variables configured
- [ ] Database migrations applied
- [ ] Redis cache cleared
- [ ] Health checks verified
- [ ] Rollback plan prepared

---

## Troubleshooting

### Common Issues

#### Database Connection Failed
```bash
# Check PostgreSQL status
docker ps | grep postgres

# Test connection
npm run db:check

# Reset database
npm run docker:reset
```

#### Flutter Build Errors
```bash
# Clean Flutter cache
flutter clean
flutter pub cache repair
flutter pub get

# iOS specific
cd ios && pod install
```

#### API Not Responding
```bash
# Check logs
npm run docker:logs

# Restart services
npm run docker:stop
npm run dev
```

### Debug Tools
- **pgAdmin**: http://localhost:5050
- **Redis CLI**: `docker exec -it paperly_redis redis-cli`
- **API Logs**: `npm run dev:backend -- --verbose`

---

## Contributing

### Pull Request Process
1. Create feature branch from `main`
2. Write tests for new functionality
3. Ensure all tests pass
4. Update documentation
5. Submit PR with clear description
6. Wait for code review

### Code Review Checklist
- [ ] Tests included and passing
- [ ] Documentation updated
- [ ] No security vulnerabilities
- [ ] Performance impact considered
- [ ] Follows coding standards

---

## Resources

### Internal Documentation
- [API Specification](./docs/api/)
- [Database Schema](./docs/database/)
- [Architecture Decisions](./docs/architecture/)
- [Work History Logs](./logs/work-history/)

### External Resources
- [Flutter Documentation](https://flutter.dev/docs)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Domain-Driven Design](https://martinfowler.com/tags/domain%20driven%20design.html)

---

## Support

### Getting Help
- **Documentation**: This file and `/docs` directory
- **Issues**: GitHub Issues for bug reports
- **Discussions**: GitHub Discussions for questions

### Contact
- **Technical Lead**: tech@paperly.com
- **Project Manager**: pm@paperly.com

---

*Last Updated: January 2025*  
*Version: 2.0.0*  
*Status: Active Development*