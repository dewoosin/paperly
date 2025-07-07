# Writer App API Flow

## Overview

The Paperly writer app is a Flutter-based content management application that provides writers with comprehensive tools for article creation, editing, publishing, and analytics. It follows a Provider-based state management pattern and communicates with dedicated writer API endpoints.

## Architecture Stack

- **Framework**: Flutter
- **State Management**: Provider pattern
- **HTTP Client**: Dio with interceptors
- **Authentication**: JWT with automatic refresh
- **Storage**: Secure storage for tokens, local storage for drafts
- **Real-time Updates**: WebSockets for analytics dashboard

## Writer-Specific Authentication Flow

### 1. Writer Registration

```http
POST /api/writer/auth/register
Content-Type: application/json
X-Client-Type: writer

{
  "username": "writer_username",
  "email": "writer@example.com",
  "password": "secure_password",
  "fullName": "Writer Full Name",
  "bio": "Writer bio",
  "deviceId": "device-uuid"
}
```

Response includes writer-specific fields:
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "username": "writer_username",
      "email": "writer@example.com",
      "userType": "writer",
      "isEmailVerified": false,
      "profile": {
        "fullName": "Writer Full Name",
        "bio": "Writer bio",
        "avatar": null,
        "socialLinks": {}
      }
    },
    "tokens": {
      "access_token": "jwt-token",
      "refresh_token": "jwt-token"
    }
  }
}
```

### 2. Writer Login Flow

```
[Writer App] → POST /api/writer/auth/login
             ← JWT tokens + writer profile
             → Store in secure storage
             → Update AuthProvider state
             → Navigate to writer dashboard
```

## Article Management API Flow

### 1. Create Article

#### Frontend Flow
```dart
// ArticleProvider.createArticle()
final article = await _articleService.createArticle(
  title: 'Article Title',
  content: 'Article content...',
  category: 'Technology',
  tags: ['flutter', 'mobile'],
  isPremium: false
);
```

#### API Request
```http
POST /api/writer/articles
Authorization: Bearer <access_token>
X-Client-Type: writer
Content-Type: application/json

{
  "title": "Article Title",
  "content": "Full article content...",
  "excerpt": "Article excerpt...",
  "categoryId": "category-uuid",
  "tags": ["flutter", "mobile", "development"],
  "featuredImage": "image-url",
  "isPremium": false,
  "status": "draft"
}
```

#### Backend Processing Flow
```
Controller → Validate input
          → Check user permissions
          → Generate slug from title
          → Calculate reading time
          → Extract word count
          → Create article record
          → Return created article
```

#### Response
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
      "tags": ["flutter", "mobile"],
      "readingTime": 5,
      "wordCount": 1200,
      "status": "draft",
      "createdAt": "2024-12-02T10:00:00Z",
      "updatedAt": "2024-12-02T10:00:00Z"
    }
  }
}
```

### 2. Update Article

#### Optimistic UI Update
```dart
// Update UI immediately
_articles[index] = updatedArticle;
notifyListeners();

// Then sync with server
try {
  final result = await _articleService.updateArticle(articleId, data);
  // Confirm update or revert on error
} catch (e) {
  // Revert optimistic update
  _articles[index] = originalArticle;
  notifyListeners();
}
```

#### API Request
```http
PUT /api/writer/articles/:id
Authorization: Bearer <access_token>

{
  "title": "Updated Title",
  "content": "Updated content...",
  "tags": ["updated", "tags"]
}
```

### 3. Get Writer's Articles

```http
GET /api/writer/articles?page=1&limit=20&status=all&sortBy=updatedAt&order=desc
Authorization: Bearer <access_token>
```

Response with pagination:
```json
{
  "success": true,
  "data": {
    "articles": [
      {
        "id": "uuid",
        "title": "Article Title",
        "excerpt": "Excerpt...",
        "status": "published",
        "views": 1250,
        "likes": 85,
        "createdAt": "2024-12-02T10:00:00Z",
        "publishedAt": "2024-12-02T12:00:00Z"
      }
    ],
    "pagination": {
      "total": 45,
      "page": 1,
      "limit": 20,
      "totalPages": 3
    }
  }
}
```

## Draft Management & Auto-Save

### 1. Auto-Save Implementation

#### Frontend Auto-Save Timer
```dart
class DraftProvider extends ChangeNotifier {
  Timer? _autoSaveTimer;
  
  void startAutoSave(String articleId) {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(
      Duration(seconds: 30),
      (_) => _performAutoSave(articleId),
    );
  }
  
  Future<void> _performAutoSave(String articleId) async {
    if (_hasChanges) {
      await _saveDraftLocally();
      await _syncWithServer(articleId);
    }
  }
}
```

#### Local Draft Storage
```dart
// Save draft locally for offline editing
await LocalStorage.saveDraft(articleId, {
  'title': currentTitle,
  'content': currentContent,
  'lastModified': DateTime.now().toIso8601String(),
  'wordCount': _calculateWordCount(),
});
```

### 2. Draft API Operations

#### Save Draft
```http
POST /api/writer/drafts/:id/autosave
Authorization: Bearer <access_token>

{
  "title": "Draft title",
  "content": "Current content...",
  "lastModified": "2024-12-02T10:30:00Z"
}
```

#### Get Drafts
```http
GET /api/writer/drafts?page=1&limit=10
```

#### Convert Draft to Article
```http
POST /api/writer/drafts/:id/publish
```

## Publishing Workflow

### 1. Article Status Transitions

```
draft → review → published → archived
  ↓       ↓         ↓
pending  approved  live
```

### 2. Publish Article Flow

#### Pre-Publish Validation
```dart
class PublishValidator {
  static ValidationResult validate(Article article) {
    final errors = <String>[];
    
    if (article.title.length < 10) {
      errors.add('Title must be at least 10 characters');
    }
    
    if (article.wordCount < 300) {
      errors.add('Article must be at least 300 words');
    }
    
    if (article.featuredImage == null) {
      errors.add('Featured image is required');
    }
    
    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }
}
```

#### Publish API Call
```http
POST /api/writer/articles/:id/publish
Authorization: Bearer <access_token>

{
  "scheduledAt": "2024-12-02T15:00:00Z", // Optional
  "notifyFollowers": true
}
```

Response:
```json
{
  "success": true,
  "data": {
    "article": {
      "id": "uuid",
      "status": "published",
      "publishedAt": "2024-12-02T15:00:00Z",
      "slug": "final-article-slug"
    }
  }
}
```

## Analytics Dashboard API

### 1. Dashboard Overview

```http
GET /api/writer/analytics/overview
Authorization: Bearer <access_token>
```

Response:
```json
{
  "success": true,
  "data": {
    "summary": {
      "totalArticles": 25,
      "totalViews": 15420,
      "totalLikes": 892,
      "totalShares": 156,
      "followersCount": 234
    },
    "recentPerformance": {
      "thisWeek": {
        "views": 1250,
        "likes": 85,
        "shares": 12
      },
      "lastWeek": {
        "views": 980,
        "likes": 67,
        "shares": 8
      },
      "percentageChange": {
        "views": 27.5,
        "likes": 26.9,
        "shares": 50.0
      }
    }
  }
}
```

### 2. Article-Specific Analytics

```http
GET /api/writer/analytics/articles/:id/stats
```

### 3. Real-Time Analytics Updates

```dart
class AnalyticsProvider extends ChangeNotifier {
  late WebSocketChannel _channel;
  
  void connectToRealTimeUpdates() {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://api.paperly.com/writer/analytics/realtime'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    
    _channel.stream.listen((data) {
      final update = AnalyticsUpdate.fromJson(jsonDecode(data));
      _updateMetrics(update);
      notifyListeners();
    });
  }
}
```

## Revenue Tracking

### 1. Revenue Analytics

```http
GET /api/writer/analytics/revenue?period=monthly&year=2024
```

Response:
```json
{
  "success": true,
  "data": {
    "totalRevenue": 1250.75,
    "thisMonth": 185.25,
    "lastMonth": 142.50,
    "growthRate": 30.0,
    "revenueByArticle": [
      {
        "articleId": "uuid",
        "title": "Premium Article",
        "revenue": 45.50,
        "views": 125
      }
    ],
    "payoutSchedule": "monthly",
    "nextPayout": "2024-01-01T00:00:00Z"
  }
}
```

## Writer Profile Management

### 1. Update Profile

```http
PUT /api/writer/profile
Content-Type: multipart/form-data

{
  "fullName": "Updated Name",
  "bio": "Updated bio...",
  "socialLinks": {
    "twitter": "https://twitter.com/username",
    "linkedin": "https://linkedin.com/in/username"
  },
  "avatar": <file-upload>
}
```

### 2. Writer Statistics

```http
GET /api/writer/profile/stats
```

## Error Handling & Offline Support

### 1. Network Error Handling

```dart
class WriterApiService {
  Future<T> handleApiCall<T>(Future<T> Function() apiCall) async {
    try {
      return await apiCall();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        // Save to local storage for later sync
        await _saveForOfflineSync();
        throw WriterException('No internet connection. Changes saved locally.');
      }
      
      if (e.response?.statusCode == 403) {
        throw WriterException('You don\'t have permission to perform this action.');
      }
      
      throw WriterException('Something went wrong. Please try again.');
    }
  }
}
```

### 2. Offline Draft Support

```dart
class OfflineDraftManager {
  Future<void> syncPendingChanges() async {
    final pendingDrafts = await LocalStorage.getPendingDrafts();
    
    for (final draft in pendingDrafts) {
      try {
        await _syncDraftWithServer(draft);
        await LocalStorage.markDraftAsSynced(draft.id);
      } catch (e) {
        // Keep in pending queue for next sync attempt
        print('Failed to sync draft ${draft.id}: $e');
      }
    }
  }
}
```

## Complete Request Lifecycle

```
1. User Action (e.g., save article)
   ↓
2. Provider method called
   ↓
3. Optimistic UI update
   ↓
4. API service method
   ↓
5. Dio HTTP request with interceptors
   ↓
6. Backend route handler
   ↓
7. Controller validation
   ↓
8. Service layer business logic
   ↓
9. Repository data operations
   ↓
10. Database transaction
    ↓
11. Response sent back
    ↓
12. Provider updates final state
    ↓
13. UI rebuilds with confirmed data
```

## Performance Optimizations

### 1. Lazy Loading
- Articles loaded in batches of 20
- Infinite scroll with pagination
- Image lazy loading for better performance

### 2. Caching Strategy
- Draft auto-save with local caching
- Analytics data cached for 5 minutes
- Image caching for frequently accessed content

### 3. Debounced Operations
- Search input debounced by 500ms
- Auto-save debounced by 30 seconds
- Analytics updates throttled to prevent spam