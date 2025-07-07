# JWT Authentication System

## Overview

Paperly implements a comprehensive JWT-based authentication system that serves three distinct client applications: Mobile, Writer, and Admin. The system uses a dual-token approach with automatic refresh, role-based access control, and advanced security monitoring.

## JWT Token Structure

### Token Configuration
- **Algorithm**: HS256 (HMAC SHA-256)
- **Issuer**: "paperly"
- **Audience**: "paperly-app"
- **Access Token Expiry**: 15 minutes (security-focused)
- **Refresh Token Expiry**: 7 days (usability-focused)

### JWT Payload Structure
```json
{
  "userId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "email": "user@example.com",
  "userType": "writer",
  "userCode": "WR0001",
  "role": "writer",
  "permissions": ["article:create", "article:publish"],
  "type": "access",
  "iat": 1735819200,
  "exp": 1735820100,
  "iss": "paperly",
  "aud": "paperly-app"
}
```

### Token Types

#### Access Token
- **Purpose**: API authentication
- **Lifespan**: 15 minutes
- **Usage**: Attached to all API requests
- **Claims**: User identity, role, permissions

#### Refresh Token
- **Purpose**: Generate new access tokens
- **Lifespan**: 7 days
- **Usage**: Token refresh endpoint only
- **Security**: Hashed before database storage

## Authentication Flow by Client

### 1. Mobile App Authentication

#### Login Process
```
1. User enters credentials
   ↓
2. POST /api/mobile/auth/login
   {
     "email": "user@example.com",
     "password": "secure_password",
     "deviceId": "device-uuid"
   }
   ↓
3. Backend validates credentials
   ↓
4. Generate access + refresh tokens
   ↓
5. Return tokens + user data
   ↓
6. Store tokens in Flutter Secure Storage
   ↓
7. Navigate to main app
```

#### Token Refresh (Automatic)
```
1. API request with expired access token
   ↓
2. Server returns 401 Unauthorized
   ↓
3. Dio interceptor catches error
   ↓
4. POST /api/mobile/auth/refresh
   {
     "refreshToken": "stored-refresh-token",
     "deviceId": "device-uuid"
   }
   ↓
5. Validate refresh token
   ↓
6. Issue new access token
   ↓
7. Update stored token
   ↓
8. Retry original request
```

### 2. Writer App Authentication

#### Enhanced Writer Flow
```
Writer Login → Same as mobile flow
            → Additional writer profile data
            → Writer-specific permissions
            → Access to content management APIs
```

#### Writer-Specific Token Claims
```json
{
  "userId": "writer-uuid",
  "userType": "writer",
  "userCode": "WR0001",
  "permissions": [
    "article:create",
    "article:edit:own",
    "article:publish:own",
    "draft:manage",
    "analytics:view:own"
  ]
}
```

### 3. Admin App Authentication

#### Admin Login Flow
```
1. Admin credentials validation
   ↓
2. POST /api/admin/auth/login
   {
     "email": "admin@paperly.com",
     "password": "admin_password",
     "deviceId": "admin-device-id"
   }
   ↓
3. Role validation (admin/super_admin)
   ↓
4. Generate tokens with admin permissions
   ↓
5. Store in localStorage (admin context)
   ↓
6. Setup periodic token refresh (30 minutes)
```

#### Admin Token Claims
```json
{
  "userId": "admin-uuid",
  "userType": "admin",
  "userCode": "AD0001",
  "role": "super_admin",
  "permissions": [
    "user:manage",
    "article:moderate",
    "system:configure",
    "security:monitor"
  ]
}
```

## Token Generation and Validation

### Token Generation Service

```typescript
class JwtService {
  generateTokens(user: User, deviceId: string): TokenPair {
    const payload = {
      userId: user.id,
      email: user.email,
      userType: user.userType,
      userCode: user.userCode,
      role: user.role,
      permissions: user.permissions
    };

    const accessToken = this.generateAccessToken(payload);
    const refreshToken = this.generateRefreshToken(payload);
    
    return { accessToken, refreshToken };
  }
}
```

### Token Validation

```typescript
class JwtMiddleware {
  async validateToken(token: string): Promise<JwtPayload> {
    try {
      const decoded = jwt.verify(token, JWT_SECRET, {
        issuer: 'paperly',
        audience: 'paperly-app'
      });
      
      // Additional validation
      if (decoded.type !== 'access') {
        throw new Error('Invalid token type');
      }
      
      return decoded as JwtPayload;
    } catch (error) {
      throw new AuthenticationError('Invalid token');
    }
  }
}
```

## Refresh Token Security

### Token Rotation Strategy

```typescript
async refreshToken(oldRefreshToken: string, deviceId: string) {
  // 1. Validate old refresh token
  const payload = await this.validateRefreshToken(oldRefreshToken);
  
  // 2. Verify device ID matches
  if (payload.deviceId !== deviceId) {
    throw new Error('Device mismatch');
  }
  
  // 3. Delete old refresh token (one-time use)
  await this.deleteRefreshToken(oldRefreshToken);
  
  // 4. Generate new token pair
  const newTokens = await this.generateTokens(payload.userId, deviceId);
  
  // 5. Store new refresh token hash
  await this.storeRefreshToken(newTokens.refreshToken, deviceId);
  
  return newTokens;
}
```

### Database Storage
```sql
-- Refresh tokens table
CREATE TABLE user_refresh_tokens (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  token_hash VARCHAR(256) NOT NULL, -- SHA-256 hash
  device_id VARCHAR(255) NOT NULL,
  ip_address INET,
  user_agent TEXT,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);
```

## Role-Based Access Control

### Permission System

#### Role Hierarchy
```
super_admin (All permissions)
  ↓
admin (Administrative permissions)
  ↓ 
writer (Content management)
  ↓
reader (Basic access)
```

#### Permission Granularity
```typescript
enum Permissions {
  // Article permissions
  ARTICLE_CREATE = 'article:create',
  ARTICLE_EDIT_OWN = 'article:edit:own',
  ARTICLE_EDIT_ANY = 'article:edit:any',
  ARTICLE_PUBLISH_OWN = 'article:publish:own',
  ARTICLE_MODERATE = 'article:moderate',
  
  // User permissions
  USER_VIEW = 'user:view',
  USER_EDIT = 'user:edit',
  USER_DELETE = 'user:delete',
  
  // System permissions
  SYSTEM_CONFIGURE = 'system:configure',
  SECURITY_MONITOR = 'security:monitor'
}
```

### Access Control Middleware

```typescript
function requirePermissions(permissions: string[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    const userPermissions = req.user.permissions || [];
    
    // Super admin bypasses all checks
    if (req.user.role === 'super_admin') {
      return next();
    }
    
    // Check required permissions
    const hasPermission = permissions.every(permission => 
      userPermissions.includes(permission)
    );
    
    if (!hasPermission) {
      return res.status(403).json({
        success: false,
        error: { code: 'INSUFFICIENT_PERMISSIONS' }
      });
    }
    
    next();
  };
}
```

## Device and Session Management

### Device Identification

#### Mobile Apps (Flutter)
```dart
class DeviceIdService {
  static Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; // Android ID
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown';
    }
    
    // Fallback
    return 'device-${DateTime.now().millisecondsSinceEpoch}';
  }
}
```

#### Web Apps (Admin Panel)
```typescript
function generateDeviceId(): string {
  const fingerprint = [
    navigator.userAgent,
    navigator.language,
    screen.width,
    screen.height,
    new Date().getTimezoneOffset()
  ].join('|');
  
  return btoa(fingerprint).slice(0, 32);
}
```

### Multi-Device Support

```typescript
class SessionManager {
  async createSession(userId: string, deviceId: string, refreshToken: string) {
    // Limit to 5 active sessions per user
    await this.cleanupOldSessions(userId, 5);
    
    // Store new session
    await this.storeRefreshToken({
      userId,
      deviceId,
      tokenHash: this.hashToken(refreshToken),
      ipAddress: req.ip,
      userAgent: req.get('User-Agent'),
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 days
    });
  }
}
```

## Security Measures

### Rate Limiting

```typescript
const authRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 attempts per window
  message: {
    success: false,
    error: { code: 'TOO_MANY_ATTEMPTS' }
  }
});

const refreshRateLimit = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 10, // 10 refresh attempts per minute
  keyGenerator: (req) => req.body.deviceId
});
```

### Brute Force Protection

```typescript
class BruteForceProtection {
  async checkLoginAttempts(email: string): Promise<void> {
    const attempts = await this.getFailedAttempts(email);
    
    if (attempts >= 5) {
      const lockoutUntil = new Date(Date.now() + 15 * 60 * 1000);
      await this.lockAccount(email, lockoutUntil);
      throw new Error('Account temporarily locked');
    }
  }
  
  async recordFailedAttempt(email: string): Promise<void> {
    await this.incrementFailedAttempts(email);
  }
  
  async resetFailedAttempts(email: string): Promise<void> {
    await this.clearFailedAttempts(email);
  }
}
```

### Token Validation Security

```typescript
class TokenValidator {
  async validateAndExtractUser(token: string): Promise<User> {
    // 1. JWT signature validation
    const payload = jwt.verify(token, JWT_SECRET);
    
    // 2. Token type validation
    if (payload.type !== 'access') {
      throw new Error('Invalid token type');
    }
    
    // 3. User existence check
    const user = await this.userRepository.findById(payload.userId);
    if (!user) {
      throw new Error('User not found');
    }
    
    // 4. Account status check
    if (user.isBlocked || user.isDeleted) {
      throw new Error('Account not accessible');
    }
    
    return user;
  }
}
```

## Client-Specific Token Handling

### Mobile/Writer Apps (Flutter)

```dart
class AuthService {
  final FlutterSecureStorage _secureStorage;
  
  Future<void> storeTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: 'access_token', value: accessToken);
    await _secureStorage.write(key: 'refresh_token', value: refreshToken);
  }
  
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access_token');
  }
  
  Future<void> clearTokens() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
  }
}
```

### Admin App (Next.js)

```typescript
class AuthManager {
  storeTokens(accessToken: string, refreshToken: string): void {
    localStorage.setItem('paperly_access_token', accessToken);
    localStorage.setItem('paperly_refresh_token', refreshToken);
  }
  
  getAccessToken(): string | null {
    return localStorage.getItem('paperly_access_token');
  }
  
  clearTokens(): void {
    localStorage.removeItem('paperly_access_token');
    localStorage.removeItem('paperly_refresh_token');
  }
  
  // Auto-refresh every 30 minutes
  startTokenRefreshTimer(): void {
    setInterval(() => {
      this.refreshTokenIfNeeded();
    }, 30 * 60 * 1000);
  }
}
```

## Security Monitoring

### Real-time Threat Detection

```typescript
class SecurityMonitor {
  async monitorAuthentication(req: Request, user: User): Promise<void> {
    // Detect suspicious patterns
    const riskScore = await this.calculateRiskScore({
      ipAddress: req.ip,
      userAgent: req.get('User-Agent'),
      location: await this.getLocationFromIP(req.ip),
      timeOfDay: new Date().getHours(),
      deviceId: req.body.deviceId
    });
    
    if (riskScore > 0.8) {
      await this.triggerSecurityAlert(user, riskScore, req);
    }
  }
}
```

### Audit Trail

```typescript
interface AuthEvent {
  userId: string;
  event: 'login' | 'logout' | 'token_refresh' | 'password_change';
  ipAddress: string;
  userAgent: string;
  deviceId: string;
  success: boolean;
  timestamp: Date;
  metadata?: Record<string, any>;
}
```

## Error Handling

### Authentication Errors

```json
{
  "success": false,
  "error": {
    "code": "TOKEN_EXPIRED",
    "message": "Access token has expired",
    "details": {
      "expiredAt": "2024-12-02T10:15:00Z",
      "action": "refresh_required"
    }
  }
}
```

### Common Error Codes
- `TOKEN_EXPIRED`: Access token expired
- `TOKEN_INVALID`: Malformed or invalid token
- `REFRESH_TOKEN_EXPIRED`: Refresh token expired
- `DEVICE_MISMATCH`: Device ID doesn't match
- `INSUFFICIENT_PERMISSIONS`: User lacks required permissions
- `ACCOUNT_LOCKED`: Account temporarily locked
- `TOO_MANY_ATTEMPTS`: Rate limit exceeded

## Best Practices Implemented

1. **Short-lived Access Tokens**: 15-minute expiry reduces exposure
2. **Token Rotation**: Refresh tokens are one-time use
3. **Secure Storage**: Platform-appropriate secure storage
4. **Device Tracking**: Multi-device support with device identification
5. **Rate Limiting**: Protection against brute force attacks
6. **Comprehensive Logging**: Full audit trail for security events
7. **Permission Granularity**: Fine-grained access control
8. **Automatic Cleanup**: Expired tokens automatically removed
9. **Risk Assessment**: Real-time security monitoring
10. **Error Masking**: Generic error messages prevent information leakage