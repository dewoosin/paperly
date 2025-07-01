// apps/backend/src/infrastructure/logging/log-sanitizer.ts

/**
 * Log Sanitizer Utility
 * 
 * Removes sensitive information from log messages to prevent data leaks
 */

// Sensitive field patterns
const SENSITIVE_FIELDS = [
  'password',
  'pass',
  'pwd',
  'token',
  'secret',
  'key',
  'auth',
  'authorization',
  'credential',
  'session',
  'cookie',
  'jwt',
  'refresh_token',
  'access_token',
  'api_key',
  'private_key',
  'public_key',
  'salt',
  'hash',
  'signature',
  'ssn',
  'social_security',
  'credit_card',
  'card_number',
  'cvv',
  'pin',
  'otp',
  'verification_code',
];

// Sensitive value patterns (regex)
const SENSITIVE_PATTERNS = [
  /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/g, // Email
  /\b(?:\d{4}[-\s]?){3}\d{4}\b/g, // Credit card numbers
  /\b\d{3}-\d{2}-\d{4}\b/g, // SSN
  /Bearer\s+[A-Za-z0-9\-._~+/]+=*/gi, // Bearer tokens
  /eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*/g, // JWT tokens
  /\$2[ayb]\$[0-9]{2}\$[A-Za-z0-9./]{53}/g, // Bcrypt hashes
];

/**
 * Sanitize a single value
 */
function sanitizeValue(value: any): any {
  if (typeof value === 'string') {
    let sanitized = value;
    
    // Apply pattern-based sanitization
    for (const pattern of SENSITIVE_PATTERNS) {
      sanitized = sanitized.replace(pattern, '[REDACTED]');
    }
    
    return sanitized;
  }
  
  if (Array.isArray(value)) {
    return value.map(sanitizeValue);
  }
  
  if (value && typeof value === 'object') {
    return sanitizeObject(value);
  }
  
  return value;
}

/**
 * Sanitize an object by removing or masking sensitive fields
 */
function sanitizeObject(obj: any): any {
  if (!obj || typeof obj !== 'object') {
    return obj;
  }
  
  const sanitized: any = {};
  
  for (const [key, value] of Object.entries(obj)) {
    const lowerKey = key.toLowerCase();
    
    // Check if the key matches sensitive field patterns
    const isSensitive = SENSITIVE_FIELDS.some(pattern => 
      lowerKey.includes(pattern.toLowerCase())
    );
    
    if (isSensitive) {
      // Mask sensitive fields
      if (typeof value === 'string' && value.length > 0) {
        sanitized[key] = value.length <= 4 
          ? '[REDACTED]' 
          : `${value.substring(0, 2)}***${value.substring(value.length - 2)}`;
      } else {
        sanitized[key] = '[REDACTED]';
      }
    } else {
      // Recursively sanitize non-sensitive fields
      sanitized[key] = sanitizeValue(value);
    }
  }
  
  return sanitized;
}

/**
 * Sanitize log data before logging
 */
export function sanitizeLogData(data: any): any {
  if (typeof data === 'string') {
    return sanitizeValue(data);
  }
  
  if (Array.isArray(data)) {
    return data.map(sanitizeValue);
  }
  
  if (data && typeof data === 'object') {
    return sanitizeObject(data);
  }
  
  return data;
}

/**
 * Create a sanitized log message
 */
export function createSanitizedLogMessage(
  message: string, 
  data?: any
): { message: string; data?: any } {
  const sanitizedMessage = sanitizeValue(message);
  const sanitizedData = data ? sanitizeLogData(data) : undefined;
  
  return {
    message: sanitizedMessage,
    ...(sanitizedData && { data: sanitizedData })
  };
}

/**
 * Utility function to safely log user actions without exposing sensitive data
 */
export function createUserActionLog(
  action: string,
  userId?: string,
  metadata?: any
): any {
  const baseLog = {
    action,
    userId: userId || '[ANONYMOUS]',
    timestamp: new Date().toISOString(),
  };
  
  if (metadata) {
    return {
      ...baseLog,
      metadata: sanitizeLogData(metadata)
    };
  }
  
  return baseLog;
}

/**
 * Utility function to safely log API requests
 */
export function createApiRequestLog(
  method: string,
  path: string,
  userId?: string,
  statusCode?: number,
  duration?: number
): any {
  return {
    type: 'api_request',
    method,
    path,
    userId: userId || '[ANONYMOUS]',
    statusCode,
    duration,
    timestamp: new Date().toISOString(),
  };
}