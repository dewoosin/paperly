// lib/config/environment.dart

enum Environment {
  development,
  staging,
  production,
}

class AppEnvironment {
  static const String _currentEnv = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  
  static Environment get current {
    switch (_currentEnv.toLowerCase()) {
      case 'production':
      case 'prod':
        return Environment.production;
      case 'staging':
      case 'stage':
        return Environment.staging;
      case 'development':
      case 'dev':
      default:
        return Environment.development;
    }
  }
  
  static bool get isDevelopment => current == Environment.development;
  static bool get isStaging => current == Environment.staging;
  static bool get isProduction => current == Environment.production;
  
  static String get name => current.name;
}

class ApiConfig {
  // API Base URLs for different environments
  static const Map<Environment, String> _baseUrls = {
    Environment.development: 'http://localhost:3000/api/v1',
    Environment.staging: 'https://staging-api.paperly.com/api/v1',
    Environment.production: 'https://api.paperly.com/api/v1',
  };
  
  // WebSocket URLs
  static const Map<Environment, String> _wsUrls = {
    Environment.development: 'ws://localhost:3000',
    Environment.staging: 'wss://staging-api.paperly.com',
    Environment.production: 'wss://api.paperly.com',
  };
  
  // Get current API base URL
  static String get baseUrl {
    const customUrl = String.fromEnvironment('API_BASE_URL');
    if (customUrl.isNotEmpty) {
      return customUrl;
    }
    return _baseUrls[AppEnvironment.current] ?? _baseUrls[Environment.development]!;
  }
  
  // Get current WebSocket URL
  static String get wsUrl {
    const customWsUrl = String.fromEnvironment('WS_BASE_URL');
    if (customWsUrl.isNotEmpty) {
      return customWsUrl;
    }
    return _wsUrls[AppEnvironment.current] ?? _wsUrls[Environment.development]!;
  }
  
  // Request timeout configuration
  static Duration get requestTimeout {
    switch (AppEnvironment.current) {
      case Environment.production:
        return const Duration(seconds: 30);
      case Environment.staging:
        return const Duration(seconds: 15);
      case Environment.development:
      default:
        return const Duration(seconds: 10);
    }
  }
  
  // Connection timeout
  static Duration get connectionTimeout {
    switch (AppEnvironment.current) {
      case Environment.production:
        return const Duration(seconds: 10);
      case Environment.staging:
        return const Duration(seconds: 8);
      case Environment.development:
      default:
        return const Duration(seconds: 5);
    }
  }
  
  // Enable debug logging
  static bool get enableDebugLogging {
    const forceDebug = bool.fromEnvironment('DEBUG_LOGGING', defaultValue: false);
    return forceDebug || AppEnvironment.isDevelopment;
  }
  
  // Enable mock services (development only)
  static bool get enableMockServices {
    const forceMock = bool.fromEnvironment('ENABLE_MOCKS', defaultValue: false);
    return forceMock || AppEnvironment.isDevelopment;
  }
  
  // Security features
  static bool get enableCertificatePinning => AppEnvironment.isProduction;
  
  // App configuration
  static String get appName {
    switch (AppEnvironment.current) {
      case Environment.production:
        return 'Paperly Writer';
      case Environment.staging:
        return 'Paperly Writer (Staging)';
      case Environment.development:
      default:
        return 'Paperly Writer (Dev)';
    }
  }
  
  // Feature flags
  static bool get enableAnalytics => AppEnvironment.isProduction;
  static bool get enableCrashReporting => !AppEnvironment.isDevelopment;
  static bool get enableOfflineMode => true;
  
  // Print current configuration (debug only)
  static void printConfig() {
    if (!enableDebugLogging) return;
    
    print('=== App Environment Configuration ===');
    print('Environment: ${AppEnvironment.name}');
    print('API Base URL: $baseUrl');
    print('WebSocket URL: $wsUrl');
    print('Request Timeout: ${requestTimeout.inSeconds}s');
    print('Debug Logging: $enableDebugLogging');
    print('Mock Services: $enableMockServices');
    print('Certificate Pinning: $enableCertificatePinning');
    print('Analytics: $enableAnalytics');
    print('Crash Reporting: $enableCrashReporting');
    print('=====================================');
  }
}