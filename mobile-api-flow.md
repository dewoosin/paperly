# Mobile App API Flow

## Overview

The Paperly mobile app is built with Flutter and follows a clean architecture pattern with Provider state management. It communicates with the backend via RESTful APIs with JWT-based authentication and automatic token refresh capabilities.

## Architecture Stack

- **Framework**: Flutter
- **HTTP Client**: Dio with interceptors
- **State Management**: Provider pattern
- **Data Models**: Freezed for immutability
- **Secure Storage**: flutter_secure_storage
- **Navigation**: Named routes with auth guards

## API Configuration

### Base URLs
```dart
Development: http://192.168.1.100:3000/api/v1
Production: https://api.paperly.com/api/v1
```

### HTTP Client Setup
```dart
final dio = Dio(BaseOptions(
  baseUrl: ApiConfig.baseUrl,
  connectTimeout: const Duration(seconds: 5),
  receiveTimeout: const Duration(seconds: 3),
));
```

## Authentication Flow

### 1. User Registration/Login Flow

```
[Mobile App] → POST /auth/register or /auth/login
             ← { user_data, access_token, refresh_token }
             → Store tokens securely via SecureStorageService
             → Update AuthProvider state
             → Navigate to HomeScreen
```

#### Registration Payload
```json
{
  "username": "string",
  "email": "string",
  "password": "string",
  "deviceId": "generated-uuid"
}
```

#### Login Payload
```json
{
  "email": "string",
  "password": "string",
  "deviceId": "device-uuid"
}
```

#### Authentication Response
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "username": "string",
      "email": "string",
      "isEmailVerified": boolean,
      "createdAt": "ISO-date"
    },
    "tokens": {
      "access_token": "jwt-token",
      "refresh_token": "jwt-token"
    }
  }
}
```

### 2. Token Management

#### Token Storage (Secure)
```dart
// Store tokens securely
await SecureStorageService.storeToken('access_token', accessToken);
await SecureStorageService.storeToken('refresh_token', refreshToken);
await SecureStorageService.storeUserData(userData);
```

#### Token Lifecycle
1. **Access Token**: 15-30 minutes expiry
2. **Refresh Token**: 30 days expiry
3. **Auto-refresh**: Dio interceptor handles 401 responses
4. **Device ID**: Persistent per device installation

### 3. Automatic Token Refresh

```
[API Request] → 401 Unauthorized Response
              → Dio Interceptor catches error
              → POST /auth/refresh with refresh_token
              ← New access_token
              → Update stored token
              → Retry original request
```

If refresh fails:
```
Refresh Token Invalid → Clear all stored tokens
                     → Update AuthProvider to logged out
                     → Navigate to LoginScreen
```

## API Request Flow

### 1. Request Interceptor Chain

```
API Call → Add Authorization Header (Bearer token)
        → Add Device ID Header (x-device-id)
        → Add Content-Type (application/json)
        → Send Request
```

### 2. Response Interceptor Chain

```
Response Received → Check Status Code
                 → 200-299: Return data
                 → 401: Attempt token refresh
                 → 4xx/5xx: Convert to user-friendly error
```

## Mobile-Specific API Endpoints

### Article Operations

#### Get Articles Feed
```http
GET /mobile/articles?page=1&limit=20&category=tech
Authorization: Bearer <access_token>
x-device-id: <device_uuid>
```

Response:
```json
{
  "success": true,
  "data": {
    "articles": [
      {
        "id": "uuid",
        "title": "Article Title",
        "excerpt": "Article excerpt...",
        "content": "Full content...",
        "author": {
          "id": "uuid",
          "username": "writer1",
          "avatar": "url"
        },
        "category": "Technology",
        "publishedAt": "ISO-date",
        "readTime": 5,
        "likes": 42,
        "isLiked": false
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

#### Article Interactions

**Get Article Details**
```http
GET /mobile/articles/:id
```

**Like/Unlike Article**
```http
POST /mobile/articles/:id/toggle-like
```

**Check Like Status**
```http
GET /mobile/articles/:id/like-status
```

### User Profile Operations

#### Get User Profile
```http
GET /mobile/user/profile
Authorization: Bearer <access_token>
```

#### Update Profile
```http
PUT /mobile/user/profile
Content-Type: application/json

{
  "username": "new_username",
  "bio": "User bio",
  "avatar": "base64_image_data"
}
```

### Bookmarks

#### Get Bookmarks
```http
GET /mobile/user/bookmarks?page=1&limit=20
```

#### Add Bookmark
```http
POST /mobile/user/bookmarks/:articleId
```

#### Remove Bookmark
```http
DELETE /mobile/user/bookmarks/:articleId
```

### Reading History

```http
GET /mobile/user/reading-history?page=1&limit=20
```

### Recommendations

#### Personalized Recommendations
```http
GET /mobile/recommendations
```

#### Trending Articles
```http
GET /mobile/recommendations/trending
```

#### Latest Articles
```http
GET /mobile/recommendations/new
```

## State Management Flow

### AuthProvider State Flow

```
App Start → Check stored tokens
         → Valid tokens: Set authenticated state
         → Invalid/missing: Set unauthenticated state
         → Notify UI via Provider

Login Action → Call AuthService.login()
            → Store tokens on success
            → Update user state
            → Trigger UI rebuild

Logout Action → Call AuthService.logout()
             → Clear stored tokens
             → Reset user state
             → Navigate to login
```

### Article State Management

```
Screen Load → Check if data cached
           → Call ArticleService.getArticles()
           → Update Provider state
           → Trigger UI rebuild with new data

Infinite Scroll → Detect scroll position
               → Load next page
               → Append to existing articles
               → Update pagination state
```

## Error Handling

### Network Error Handling

```dart
try {
  final response = await dio.get('/mobile/articles');
  return response.data;
} on DioException catch (e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
      throw NetworkException('Connection timeout');
    case DioExceptionType.receiveTimeout:
      throw NetworkException('Request timeout');
    case DioExceptionType.badResponse:
      if (e.response?.statusCode == 401) {
        // Handle authentication error
        await _refreshToken();
      }
      break;
    default:
      throw NetworkException('Network error occurred');
  }
}
```

### User-Friendly Error Messages

- **Network Issues**: "Please check your internet connection"
- **Server Errors**: "Something went wrong. Please try again."
- **Authentication**: "Please log in again"
- **Validation**: Field-specific error messages

## Offline Behavior

### Current Limitations
- No article caching for offline reading
- Limited offline functionality
- Requires internet for most operations

### Offline Capabilities
- User data persists locally
- Authentication tokens stored securely
- App state maintained across app restarts
- Graceful error handling for network issues

### Improvement Opportunities
- Implement article caching with SQLite
- Add offline reading capability
- Queue actions for online sync
- Implement data synchronization

## Performance Optimizations

### Image Loading
- Lazy loading for article images
- Image caching with flutter_cached_network_image
- Placeholder images during loading

### API Optimizations
- Pagination for large datasets
- Request debouncing for search
- Connection pooling via Dio

### Memory Management
- Dispose providers when not needed
- Clear cached data periodically
- Efficient list rendering with ListView.builder

## Security Considerations

### Token Security
- Secure storage using platform keychain/keystore
- Token rotation on refresh
- No sensitive data in regular SharedPreferences

### API Security
- All requests over HTTPS in production
- Certificate pinning (recommended addition)
- Request/response validation

### Data Protection
- No sensitive data logged
- User data encryption at rest
- Secure handling of authentication state

## Complete Request-Response Cycle

```
1. User Action (e.g., tap article)
   ↓
2. UI calls Provider method
   ↓
3. Provider calls Service method
   ↓
4. Service creates Dio request
   ↓
5. Dio interceptor adds auth headers
   ↓
6. HTTP request sent to backend
   ↓
7. Backend processes request
   ↓
8. Response received by Dio
   ↓
9. Response interceptor handles errors
   ↓
10. Service parses response data
    ↓
11. Provider updates state
    ↓
12. UI rebuilds with new data
```

## Development vs Production

### Development Environment
- Local backend server (192.168.1.100:3000)
- Relaxed CORS policies
- Detailed error logging
- Debug mode features

### Production Environment
- HTTPS API endpoints
- Production error handling
- Analytics integration
- Performance monitoring
- Crash reporting