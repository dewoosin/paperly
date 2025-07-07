# Integration Architecture Overview

## System Overview

Paperly is a comprehensive content platform consisting of three client applications integrated with a unified backend API. The architecture follows microservices principles with clean separation of concerns, robust authentication, and comprehensive security monitoring.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        PAPERLY ECOSYSTEM                        │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │   Mobile    │  │   Writer    │  │    Admin    │             │
│  │     App     │  │     App     │  │    Panel    │             │
│  │  (Flutter)  │  │  (Flutter)  │  │  (Next.js)  │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│         │                │                │                     │
│         └────────────────┼────────────────┘                     │
│                          │                                      │
│  ┌─────────────────────────────────────────────────────────────┤
│  │                 UNIFIED BACKEND API                         │
│  │                   (Node.js/Express)                        │
│  │                                                             │
│  │  ┌─────────────────────────────────────────────────────┐   │
│  │  │              API GATEWAY LAYER                      │   │
│  │  │  ┌─────────┐  ┌─────────┐  ┌─────────┐             │   │
│  │  │  │ Mobile  │  │ Writer  │  │  Admin  │             │   │
│  │  │  │ Routes  │  │ Routes  │  │ Routes  │             │   │
│  │  │  └─────────┘  └─────────┘  └─────────┘             │   │
│  │  └─────────────────────────────────────────────────────┘   │
│  │                                                             │
│  │  ┌─────────────────────────────────────────────────────┐   │
│  │  │               SECURITY LAYER                        │   │
│  │  │  ┌─────────┐  ┌─────────┐  ┌─────────┐             │   │
│  │  │  │   JWT   │  │  RBAC   │  │  Rate   │             │   │
│  │  │  │  Auth   │  │ System  │  │ Limit   │             │   │
│  │  │  └─────────┘  └─────────┘  └─────────┘             │   │
│  │  └─────────────────────────────────────────────────────┘   │
│  │                                                             │
│  │  ┌─────────────────────────────────────────────────────┐   │
│  │  │              BUSINESS LOGIC LAYER                   │   │
│  │  │  ┌─────────┐  ┌─────────┐  ┌─────────┐             │   │
│  │  │  │  Auth   │  │Article  │  │  User   │             │   │
│  │  │  │Service  │  │Service  │  │Service  │             │   │
│  │  │  └─────────┘  └─────────┘  └─────────┘             │   │
│  │  └─────────────────────────────────────────────────────┘   │
│  │                                                             │
│  │  ┌─────────────────────────────────────────────────────┐   │
│  │  │               DATA ACCESS LAYER                     │   │
│  │  │  ┌─────────┐  ┌─────────┐  ┌─────────┐             │   │
│  │  │  │  User   │  │Article  │  │Category │             │   │
│  │  │  │  Repo   │  │  Repo   │  │  Repo   │             │   │
│  │  │  └─────────┘  └─────────┘  └─────────┘             │   │
│  │  └─────────────────────────────────────────────────────┘   │
│  └─────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┤
│  │                    DATABASE LAYER                           │
│  │  ┌─────────────────────────────────────────────────────┐   │
│  │  │                PostgreSQL Database                  │   │
│  │  │  ┌─────────┐  ┌─────────┐  ┌─────────┐             │   │
│  │  │  │  Users  │  │Articles │  │Security │             │   │
│  │  │  │  Table  │  │  Table  │  │  Logs   │             │   │
│  │  │  └─────────┘  └─────────┘  └─────────┘             │   │
│  │  └─────────────────────────────────────────────────────┘   │
│  └─────────────────────────────────────────────────────────────┘
└─────────────────────────────────────────────────────────────────┘
```

## Application Communication Matrix

### Client-to-Backend Communication

| Client | Protocol | Base Path | Authentication | Primary Use Cases |
|--------|----------|-----------|----------------|-------------------|
| Mobile App | HTTPS/REST | `/api/mobile/` | JWT Bearer | Content consumption, user engagement |
| Writer App | HTTPS/REST | `/api/writer/` | JWT Bearer | Content creation, analytics |
| Admin Panel | HTTPS/REST | `/api/admin/` | JWT Bearer | System administration, moderation |

### API Endpoint Distribution

```
Backend API Structure:
├── /api/mobile/          # Mobile-specific endpoints
│   ├── auth/            # Mobile authentication
│   ├── articles/        # Read-only article access
│   ├── user/            # User profile & bookmarks
│   ├── recommendations/ # Personalized content
│   └── categories/      # Category browsing
│
├── /api/writer/         # Writer-specific endpoints
│   ├── auth/           # Writer authentication
│   ├── articles/       # Full CRUD operations
│   ├── drafts/         # Draft management
│   ├── analytics/      # Performance metrics
│   └── profile/        # Writer profile management
│
└── /api/admin/         # Admin-specific endpoints
    ├── auth/          # Admin authentication
    ├── users/         # User management
    ├── articles/      # Content moderation
    ├── security/      # Security monitoring
    └── system/        # System configuration
```

## Authentication Flow Diagram

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Mobile    │    │   Writer    │    │    Admin    │
│     App     │    │     App     │    │    Panel    │
└─────┬───────┘    └─────┬───────┘    └─────┬───────┘
      │                  │                  │
      │ Login Request    │ Login Request    │ Login Request
      ├─────────────────────────────────────┼─────────────────┐
      │                  │                  │                 │
      │                  │                  │                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                    BACKEND AUTH SERVICE                         │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                JWT TOKEN GENERATION                     │   │
│  │                                                         │   │
│  │  User Credentials → Validation → Role Check             │   │
│  │        ↓                ↓           ↓                   │   │
│  │  Database Query → Permission → Token Generation         │   │
│  │                     Assignment                          │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                 TOKEN STRUCTURE                         │   │
│  │                                                         │   │
│  │  Access Token (15 min):                                │   │
│  │  - User identity                                        │   │
│  │  - Role & permissions                                   │   │
│  │  - Client type                                          │   │
│  │                                                         │   │
│  │  Refresh Token (7 days):                               │   │
│  │  - Device tracking                                      │   │
│  │  - Session management                                   │   │
│  │  - Auto-rotation                                        │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
      │                  │                  │
      │ Tokens Returned  │ Tokens Returned  │ Tokens Returned
      ▼                  ▼                  ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ Secure      │    │ Secure      │    │ Local       │
│ Storage     │    │ Storage     │    │ Storage     │
│ (Keychain)  │    │ (Keychain)  │    │ (Browser)   │
└─────────────┘    └─────────────┘    └─────────────┘
```

## Data Flow Patterns

### 1. Content Consumption Flow (Mobile App)

```
User Action → API Request → Backend Processing → Database Query → Response
     ↓              ↓              ↓                 ↓            ↓
Open Article → GET /mobile/   → Validate JWT   → SELECT article → JSON Response
               articles/:id     Check permissions   FROM database   with content
                                                                      ↓
                                                               UI Update
```

### 2. Content Creation Flow (Writer App)

```
Writer Action → Local Storage → API Request → Backend Processing → Database
      ↓              ↓             ↓              ↓                ↓
Create Article → Auto-save     → POST /writer/ → Validate       → INSERT article
                 every 30s       articles        ownership         to database
                                                                      ↓
                                                               Success Response
                                                                      ↓
                                                               Update UI state
```

### 3. Administration Flow (Admin Panel)

```
Admin Action → Permission Check → API Request → Backend → Database → Response
     ↓               ↓               ↓            ↓         ↓         ↓
Moderate User → Check admin      → PUT /admin/  → Validate → UPDATE  → Success
                permissions        users/:id      super     user      notification
                                                 admin      status
```

## Security Integration

### Multi-Layer Security Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        SECURITY LAYERS                          │
├─────────────────────────────────────────────────────────────────┤
│  Layer 1: Network Security                                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ • HTTPS/TLS Encryption                                  │   │
│  │ • CORS Configuration                                    │   │
│  │ • IP Whitelisting/Blacklisting                         │   │
│  │ • DDoS Protection                                       │   │
│  └─────────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────────┤
│  Layer 2: API Gateway Security                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ • Rate Limiting (per client/endpoint)                   │   │
│  │ • Request Validation                                    │   │
│  │ • Client Authentication                                 │   │
│  │ • Header Validation                                     │   │
│  └─────────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────────┤
│  Layer 3: Authentication & Authorization                       │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ • JWT Token Validation                                  │   │
│  │ • User Session Management                               │   │
│  │ • Role-Based Access Control                             │   │
│  │ • Permission Granularity                                │   │
│  └─────────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────────┤
│  Layer 4: Application Security                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ • Input Sanitization                                    │   │
│  │ • SQL Injection Prevention                              │   │
│  │ • XSS Protection                                        │   │
│  │ • CSRF Protection                                       │   │
│  └─────────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────────┤
│  Layer 5: Real-time Monitoring                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ • Threat Detection                                      │   │
│  │ • Anomaly Detection                                     │   │
│  │ • Security Event Logging                                │   │
│  │ • Automated Response                                     │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Client-Specific Features

### Mobile App Integration

**Primary Functions:**
- Content consumption and discovery
- User engagement (likes, bookmarks, comments)
- Personalized recommendations
- Reading history tracking
- Offline content access (limited)

**Technical Integration:**
- Flutter framework with Provider state management
- Secure token storage using Flutter Secure Storage
- Automatic token refresh via Dio interceptors
- Real-time content updates via push notifications

### Writer App Integration

**Primary Functions:**
- Article creation and editing
- Draft management with auto-save
- Publishing workflow
- Performance analytics dashboard
- Revenue tracking and monetization

**Technical Integration:**
- Flutter framework with advanced state management
- Local draft storage with server synchronization
- Rich text editor with markdown support
- Real-time analytics via WebSocket connections
- Image upload and management

### Admin Panel Integration

**Primary Functions:**
- User and role management
- Content moderation and approval
- Security monitoring and threat response
- System configuration and maintenance
- Analytics and reporting

**Technical Integration:**
- Next.js React framework
- Server-side rendering for SEO
- Real-time dashboard updates
- Comprehensive admin UI components
- Advanced filtering and search capabilities

## Database Integration

### Data Architecture

```sql
-- Core Tables Structure
Users                    Articles                Categories
├── id (UUID)           ├── id (UUID)           ├── id (UUID)
├── email               ├── title               ├── name
├── username            ├── content             ├── description
├── user_type           ├── author_id (FK)      ├── slug
├── role                ├── category_id (FK)    └── created_at
├── permissions         ├── status
├── created_at          ├── published_at
└── updated_at          ├── view_count
                        ├── like_count
                        └── word_count

-- Security Tables
user_refresh_tokens     audit_logs             security_events
├── user_id (FK)       ├── user_id (FK)       ├── event_type
├── token_hash         ├── action             ├── ip_address
├── device_id          ├── resource_type      ├── user_agent
├── ip_address         ├── resource_id        ├── risk_score
├── expires_at         ├── timestamp          ├── blocked
└── created_at         └── metadata           └── timestamp
```

### Transaction Management

```typescript
// Example: Article Creation with Analytics
async createArticle(articleData: CreateArticleDto, userId: string) {
  return await this.database.transaction(async (trx) => {
    // 1. Create article
    const article = await this.articleRepo.create(articleData, trx);
    
    // 2. Update user statistics
    await this.userRepo.incrementArticleCount(userId, trx);
    
    // 3. Log creation event
    await this.auditRepo.logEvent({
      userId,
      action: 'article_created',
      resourceType: 'article',
      resourceId: article.id
    }, trx);
    
    // 4. Trigger notifications (async)
    this.notificationService.notifyFollowers(userId, article.id);
    
    return article;
  });
}
```

## Real-time Communication

### WebSocket Integration

```typescript
// Writer App Analytics Updates
class AnalyticsWebSocket {
  constructor(private io: Server) {
    this.setupWriterNamespace();
  }
  
  private setupWriterNamespace() {
    const writerNamespace = this.io.of('/writer/analytics');
    
    writerNamespace.use(this.authenticateSocket);
    
    writerNamespace.on('connection', (socket) => {
      // Join writer-specific room
      socket.join(`writer:${socket.userId}`);
      
      // Send real-time analytics updates
      this.startAnalyticsStream(socket);
    });
  }
}
```

### Push Notifications

```typescript
// Mobile App Notifications
class NotificationService {
  async notifyNewArticle(followerId: string, articleId: string) {
    const devices = await this.getDeviceTokens(followerId);
    
    const notification = {
      title: 'New Article Available',
      body: 'One of your followed writers published a new article',
      data: { articleId }
    };
    
    await this.fcm.sendToDevices(devices, notification);
  }
}
```

## Performance Optimizations

### Caching Strategy

```
┌─────────────────────────────────────────────────────────────────┐
│                      CACHING LAYERS                             │
├─────────────────────────────────────────────────────────────────┤
│  Browser Cache (Client-side)                                   │
│  ├── Static assets (CSS, JS, images)                           │
│  ├── API responses (short-term)                                │
│  └── User preferences                                           │
├─────────────────────────────────────────────────────────────────┤
│  CDN Cache (Global)                                             │
│  ├── Static content delivery                                   │
│  ├── Image optimization                                         │
│  └── Geographic distribution                                    │
├─────────────────────────────────────────────────────────────────┤
│  Application Cache (Backend)                                    │
│  ├── Redis for session data                                    │
│  ├── Frequently accessed articles                               │
│  ├── User preferences                                           │
│  └── Analytics data                                             │
├─────────────────────────────────────────────────────────────────┤
│  Database Query Cache                                           │
│  ├── PostgreSQL query cache                                    │
│  ├── Connection pooling                                         │
│  └── Index optimization                                         │
└─────────────────────────────────────────────────────────────────┘
```

### Load Balancing

```
Internet → Load Balancer → Backend Instances
    ↓           ↓              ↓
  Users    Round Robin    Instance 1
           Algorithm      Instance 2
                         Instance 3
                             ↓
                      Shared Database
                      Shared Redis
```

## Monitoring and Observability

### Application Monitoring

```typescript
// Example: Request Monitoring
class RequestMonitor {
  logRequest(req: Request, res: Response, responseTime: number) {
    const metrics = {
      method: req.method,
      url: req.url,
      statusCode: res.statusCode,
      responseTime,
      userAgent: req.get('User-Agent'),
      ip: req.ip,
      userId: req.user?.id,
      timestamp: new Date()
    };
    
    // Log to monitoring service
    this.logger.info('API Request', metrics);
    
    // Send to analytics
    this.analytics.track('api_request', metrics);
  }
}
```

### Health Checks

```typescript
// System Health Monitoring
class HealthController {
  async getSystemHealth() {
    const checks = await Promise.allSettled([
      this.checkDatabase(),
      this.checkRedis(),
      this.checkExternalAPIs(),
      this.checkMemoryUsage(),
      this.checkDiskSpace()
    ]);
    
    return {
      status: checks.every(c => c.status === 'fulfilled') ? 'healthy' : 'unhealthy',
      timestamp: new Date(),
      details: checks
    };
  }
}
```

## Deployment Architecture

### Development Environment
```
Local Development:
├── Backend: localhost:3000
├── Mobile App: Emulator/Device
├── Writer App: Emulator/Device
├── Admin Panel: localhost:3001
└── Database: Local PostgreSQL
```

### Production Environment
```
Production Setup:
├── Backend: api.paperly.com (Load Balanced)
├── Mobile Apps: App Stores
├── Writer Apps: App Stores
├── Admin Panel: admin.paperly.com
├── Database: Managed PostgreSQL (AWS RDS)
├── Cache: Redis Cluster
├── CDN: CloudFront
└── Monitoring: CloudWatch + Custom Analytics
```

## Error Handling and Recovery

### Error Propagation

```
Database Error → Repository → Service → Controller → Client
      ↓             ↓          ↓          ↓          ↓
 Connection    Transform   Business   HTTP      User-friendly
   Timeout     to Domain   Logic     Response    Error Message
               Error       Handling
```

### Graceful Degradation

```typescript
// Example: Article Service with Fallbacks
class ArticleService {
  async getArticles(params: GetArticlesParams) {
    try {
      // Primary: Get from cache
      return await this.cache.getArticles(params);
    } catch (cacheError) {
      try {
        // Fallback: Get from database
        const articles = await this.database.getArticles(params);
        
        // Async: Update cache
        this.cache.setArticles(params, articles).catch(console.error);
        
        return articles;
      } catch (dbError) {
        // Last resort: Return cached stale data
        return await this.cache.getStaleArticles(params);
      }
    }
  }
}
```

## Integration Benefits

1. **Unified Authentication**: Single JWT system across all clients
2. **Consistent API Design**: RESTful endpoints with standard response format
3. **Role-based Access**: Granular permissions for different user types
4. **Real-time Updates**: WebSocket integration for live data
5. **Comprehensive Security**: Multi-layer security with monitoring
6. **Scalable Architecture**: Clean separation allows independent scaling
7. **Monitoring & Analytics**: Full observability across the system
8. **Fault Tolerance**: Graceful error handling and recovery mechanisms

This architecture provides a robust, scalable, and secure foundation for the Paperly platform while maintaining clear separation of concerns and enabling independent development and deployment of each client application.