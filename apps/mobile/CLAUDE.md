# Paperly Mobile App Developer Guide

This comprehensive guide provides everything you need to understand, develop, and contribute to the Paperly mobile application. It serves as the primary reference for developers working on the Flutter-based mobile client.

## Table of Contents

1. [App Overview](#app-overview)
2. [Role in Paperly Ecosystem](#role-in-paperly-ecosystem)
3. [Key Features](#key-features)
4. [Architecture & Tech Stack](#architecture--tech-stack)
5. [Project Structure](#project-structure)
6. [Development Setup](#development-setup)
7. [API Integration](#api-integration)
8. [State Management](#state-management)
9. [UI/UX Guidelines](#uiux-guidelines)
10. [Testing Strategy](#testing-strategy)
11. [Build & Deployment](#build--deployment)
12. [Troubleshooting](#troubleshooting)

---

## App Overview

### Purpose
The Paperly mobile app is the primary content consumption interface for readers in the Paperly ecosystem. It delivers AI-curated, personalized daily learning content through a minimalist, distraction-free reading experience optimized for knowledge retention.

### Target Users
- **Primary**: Knowledge workers, students, and lifelong learners seeking curated content
- **Secondary**: Professionals looking to stay updated in their fields
- **Demographics**: 25-45 years old, education-focused, sustainability-conscious

### Core Value Proposition
1. **Personalized Learning**: AI-curated content based on individual interests and reading patterns
2. **Distraction-Free Reading**: Minimalist design inspired by MUJI aesthetics
3. **Knowledge Retention**: Offline-first architecture and thoughtful reading experience
4. **Environmental Impact**: Reduced digital carbon footprint through efficient design

---

## Role in Paperly Ecosystem

The mobile app is one of three client applications in the Paperly platform:

```
┌─────────────────────────────────────────────────────┐
│                 Paperly Ecosystem                    │
├──────────────┬────────────────┬────────────────────┤
│  Mobile App  │  Writer App    │   Admin Panel      │
│  (Reader)    │  (Creator)     │   (Manager)        │
├──────────────┼────────────────┼────────────────────┤
│ • Content    │ • Content      │ • Platform         │
│   Consumption│   Creation     │   Management       │
│ • Reading    │ • Analytics    │ • User             │
│   Experience │ • Publishing   │   Moderation       │
│ • Personal   │ • Revenue      │ • Content          │
│   Library    │   Tracking     │   Curation         │
└──────────────┴────────────────┴────────────────────┘
                         │
                    Backend API
```

### Mobile App Responsibilities
1. **Content Delivery**: Present AI-curated articles in an engaging format
2. **User Experience**: Provide seamless reading experience with offline support
3. **Personalization**: Track reading patterns and preferences for better recommendations
4. **Engagement**: Enable interactions like bookmarks, likes, and author follows
5. **Authentication**: Secure user authentication and session management

---

## Key Features

### 1. Content Discovery & Reading
- **Daily Recommendations**: AI-curated articles based on user preferences
- **Category Browsing**: Explore content by topics (Technology, Business, Science, etc.)
- **Search Functionality**: Full-text search across articles and authors
- **Reading Experience**: Clean, typography-focused layout with adjustable settings
- **Offline Support**: Download articles for offline reading

### 2. Personalization & AI
- **Interest Tracking**: Monitor reading patterns to improve recommendations
- **Adaptive Learning**: AI adjusts content difficulty and topics based on engagement
- **Reading Goals**: Set and track daily/weekly reading targets
- **Custom Collections**: Create personal reading lists and collections

### 3. Social & Engagement
- **Author Following**: Subscribe to favorite writers for updates
- **Article Interactions**: Like, bookmark, and share articles
- **Reading Progress**: Track reading time and completion rates
- **Achievements**: Gamification elements for consistent reading habits

### 4. User Management
- **Secure Authentication**: JWT-based auth with biometric support
- **Profile Management**: Customize reading preferences and interests
- **Multi-Device Sync**: Seamless experience across devices
- **Privacy Controls**: Manage data collection and sharing preferences

### 5. Technical Features
- **Push Notifications**: Daily reading reminders and author updates
- **Performance Monitoring**: Track app performance and user experience
- **Error Handling**: Graceful error recovery with offline fallbacks
- **Analytics Integration**: Privacy-focused usage analytics

---

## Architecture & Tech Stack

### Technology Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Framework** | Flutter 3.32+ | Cross-platform UI framework |
| **Language** | Dart 3.0+ | Primary development language |
| **State Management** | Provider 6.0+ | Simple, efficient state management |
| **Navigation** | Navigator 2.0 | Declarative navigation |
| **HTTP Client** | Dio 5.4+ | Advanced HTTP client with interceptors |
| **Local Storage** | Flutter Secure Storage | Encrypted storage for sensitive data |
| **Database** | SharedPreferences | Simple key-value storage |
| **Authentication** | JWT + Biometric | Secure multi-factor authentication |
| **UI Components** | Material Design 3 | Modern, adaptive UI components |
| **Code Generation** | Freezed + JsonSerializable | Immutable models and JSON parsing |
| **Logging** | Logger 2.0+ | Structured logging with levels |
| **Testing** | Flutter Test + Mockito | Unit and widget testing |

### Architecture Pattern

The app follows Clean Architecture principles with clear separation of concerns:

```
┌─────────────────────────────────────────────────────┐
│                  Presentation Layer                  │
│  (Screens, Widgets, Providers, UI Logic)            │
├─────────────────────────────────────────────────────┤
│                   Domain Layer                       │
│  (Business Logic, Entities, Use Cases)              │
├─────────────────────────────────────────────────────┤
│                    Data Layer                        │
│  (Services, Repositories, Models, APIs)             │
└─────────────────────────────────────────────────────┘
```

### Design Patterns

1. **Repository Pattern**: Abstract data sources behind interfaces
2. **Provider Pattern**: Reactive state management with change notifications
3. **Service Locator**: Dependency injection for services
4. **Factory Pattern**: Model creation from JSON
5. **Singleton Pattern**: Single instances for services and managers

---

## Project Structure

```
apps/mobile/
├── lib/                          # Main source code directory
│   ├── config/                   # App configuration
│   │   └── api_config.dart      # API endpoints and environment config
│   ├── models/                   # Data models
│   │   ├── article_models.dart  # Article-related models
│   │   ├── auth_models.dart     # Authentication models
│   │   └── author_models.dart   # Author/writer models
│   ├── providers/                # State management
│   │   ├── auth_provider.dart   # Authentication state
│   │   └── follow_provider.dart # Follow/subscription state
│   ├── screens/                  # UI screens
│   │   ├── auth/                # Authentication screens
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── email_verification_screen.dart
│   │   ├── article_detail_screen.dart    # Article reading view
│   │   ├── article_list_screen.dart      # Article browsing
│   │   ├── author_detail_screen.dart     # Author profile
│   │   ├── home_screen.dart              # Main home screen
│   │   ├── search_screen.dart            # Search functionality
│   │   └── obsidian_view_screen.dart     # Special reading mode
│   ├── services/                 # Business logic & API calls
│   │   ├── article_service.dart         # Article API operations
│   │   ├── auth_service.dart            # Authentication logic
│   │   ├── device_info_service.dart     # Device information
│   │   ├── error_translation_service.dart # Error message localization
│   │   ├── follow_service.dart          # Follow/unfollow operations
│   │   └── secure_storage_service.dart  # Encrypted storage
│   ├── theme/                    # UI theming
│   │   └── muji_theme.dart      # MUJI-inspired design system
│   ├── utils/                    # Utility functions
│   │   ├── error_handler.dart   # Centralized error handling
│   │   └── logger.dart          # Logging utilities
│   ├── widgets/                  # Reusable UI components
│   │   ├── muji_button.dart     # Custom button widget
│   │   └── muji_text_field.dart # Custom text input
│   └── main.dart                # App entry point
├── assets/                       # Static assets
│   ├── images/                  # Image assets
│   ├── fonts/                   # Custom fonts
│   └── icons/                   # App icons
├── test/                        # Test files
│   ├── unit/                    # Unit tests
│   ├── widget/                  # Widget tests
│   └── integration/             # Integration tests
├── android/                     # Android platform code
├── ios/                         # iOS platform code
├── web/                         # Web platform code
├── pubspec.yaml                 # Dependencies and metadata
└── README.md                    # Basic project info
```

### Key Directories Explained

- **`config/`**: Environment-specific configurations (dev, staging, prod)
- **`models/`**: Immutable data models with JSON serialization
- **`providers/`**: State management classes extending ChangeNotifier
- **`screens/`**: Full-page UI components representing app screens
- **`services/`**: Business logic, API calls, and external integrations
- **`theme/`**: Design system implementation with colors, typography, spacing
- **`utils/`**: Helper functions and utilities used across the app
- **`widgets/`**: Reusable UI components following MUJI design principles

---

## Development Setup

### Prerequisites
- Flutter SDK 3.32 or higher
- Dart SDK 3.0 or higher
- Android Studio / Xcode (for platform tools)
- VS Code or IntelliJ IDEA with Flutter plugins

### Getting Started

1. **Navigate to Mobile Directory**
```bash
cd apps/mobile
```

2. **Install Dependencies**
```bash
flutter pub get
```

3. **Generate Code**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. **Configure Environment**
```dart
// Update lib/config/api_config.dart with your backend URL
static const String baseUrl = 'http://192.168.1.100:3000'; // Your local IP
```

5. **Run the App**
```bash
# iOS Simulator
flutter run -d ios

# Android Emulator
flutter run -d android

# All devices
flutter run -d all
```

### Development Commands

| Command | Description |
|---------|-------------|
| `flutter pub get` | Install dependencies |
| `flutter run` | Run app in debug mode |
| `flutter build apk` | Build Android APK |
| `flutter build ios` | Build iOS app |
| `flutter test` | Run all tests |
| `flutter analyze` | Analyze code quality |
| `flutter clean` | Clean build artifacts |

### Environment Configuration

The app supports multiple environments through build flavors:

```bash
# Development
flutter run --flavor dev

# Staging
flutter run --flavor staging

# Production
flutter run --flavor prod
```

---

## API Integration

### Base Configuration
```dart
// lib/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'http://192.168.1.100:3000';
  static const String apiPrefix = '/api/v1/mobile';
  
  // Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String articles = '/articles';
  static const String recommendations = '/recommendations/daily';
}
```

### API Service Pattern
```dart
// Example: Article Service
class ArticleService {
  final Dio _dio;
  
  Future<List<Article>> getArticles({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.apiPrefix}/articles',
        queryParameters: {'page': page, 'limit': limit},
      );
      return (response.data['data'] as List)
          .map((json) => Article.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }
}
```

### Authentication Flow
1. **Login**: Email/password → JWT tokens (access + refresh)
2. **Token Storage**: Encrypted storage using Flutter Secure Storage
3. **Token Refresh**: Automatic refresh when access token expires
4. **Logout**: Clear tokens and redirect to login

### Error Handling
```dart
// Centralized error handling
mixin ErrorHandlerMixin {
  void handleError(dynamic error) {
    if (error is DioException) {
      // Network errors
    } else if (error is FormatException) {
      // Parsing errors
    } else {
      // Unknown errors
    }
  }
}
```

---

## State Management

### Provider Architecture

The app uses Provider for state management with the following structure:

```dart
// Main app providers
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => FollowProvider()),
    // Add more providers as needed
  ],
  child: MyApp(),
)
```

### Provider Guidelines

1. **Single Responsibility**: Each provider manages one domain
2. **Immutable State**: Use copyWith pattern for state updates
3. **Async Operations**: Handle loading/error states properly
4. **Memory Management**: Dispose resources in dispose()

### Example Provider
```dart
class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _user = await _authService.login(email, password);
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

---

## UI/UX Guidelines

### Design Principles

The app follows MUJI-inspired minimalist design:

1. **Simplicity**: Clean interfaces with essential elements only
2. **Typography**: Focus on readability with thoughtful font choices
3. **Whitespace**: Generous spacing for visual breathing room
4. **Natural Colors**: Muted earth tones (sage, clay, moss, charcoal)
5. **Subtle Animations**: Smooth, purposeful transitions

### Color Palette
```dart
class MujiTheme {
  // Primary colors
  static const Color ink = Color(0xFF1C1C1E);      // Near black
  static const Color paper = Color(0xFFFAFAF8);    // Off white
  
  // Accent colors
  static const Color sage = Color(0xFF7C9885);     // Muted green
  static const Color clay = Color(0xFFB08968);     // Warm brown
  static const Color moss = Color(0xFF5F7161);     // Deep green
  static const Color sand = Color(0xFFE5D4B7);     // Light beige
}
```

### Typography
```dart
// Heading styles
static const TextStyle h1 = TextStyle(
  fontFamily: 'NotoSans',
  fontSize: 28,
  fontWeight: FontWeight.w600,
  height: 1.2,
);

// Body text
static const TextStyle body = TextStyle(
  fontFamily: 'NotoSans',
  fontSize: 16,
  fontWeight: FontWeight.w400,
  height: 1.6,
);
```

### Component Guidelines

1. **Buttons**: Flat design with subtle shadows on press
2. **Cards**: Soft corners (8px radius) with light shadows
3. **Lists**: Clean dividers with ample padding
4. **Forms**: Minimal borders with focus states
5. **Loading**: Skeleton screens over spinners

---

## Testing Strategy

### Test Structure
```
test/
├── unit/               # Business logic tests
│   ├── services/      # Service layer tests
│   ├── providers/     # State management tests
│   └── utils/         # Utility function tests
├── widget/            # UI component tests
│   ├── screens/       # Screen widget tests
│   └── widgets/       # Reusable widget tests
└── integration/       # End-to-end tests
```

### Running Tests
```bash
# All tests
flutter test

# Specific test file
flutter test test/unit/services/auth_service_test.dart

# With coverage
flutter test --coverage
```

### Test Guidelines

1. **Unit Tests**: Test services, providers, and utilities
2. **Widget Tests**: Test UI components in isolation
3. **Integration Tests**: Test complete user flows
4. **Mock Data**: Use fake repositories for consistent testing
5. **Coverage Target**: Maintain 80%+ code coverage

---

## Build & Deployment

### Android Build
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle for Play Store
flutter build appbundle --release
```

### iOS Build
```bash
# Debug build
flutter build ios --debug

# Release build
flutter build ios --release

# Archive for App Store
flutter build ipa --release
```

### CI/CD Pipeline

The app uses GitHub Actions for automated builds:

1. **PR Checks**: Run tests and linting on pull requests
2. **Beta Builds**: Deploy to TestFlight/Play Console on develop
3. **Production**: Release builds on version tags

### Version Management
```yaml
# pubspec.yaml
version: 1.0.0+1  # version+buildNumber
```

---

## Troubleshooting

### Common Issues

#### 1. Build Failures
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 2. iOS Pod Issues
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter run
```

#### 3. Android Gradle Issues
```bash
cd android
./gradlew clean
cd ..
flutter run
```

#### 4. State Not Updating
- Check `notifyListeners()` calls
- Verify provider is above widget in tree
- Use `Consumer` or `context.watch()`

#### 5. API Connection Issues
- Verify backend is running
- Check network permissions
- Use device IP instead of localhost

### Debug Tools

1. **Flutter Inspector**: Analyze widget tree
2. **Network Inspector**: Monitor API calls
3. **Performance Overlay**: Check frame rates
4. **Debug Console**: View logs and errors

### Getting Help

- **Documentation**: Check `/docs` folder
- **Team Chat**: Slack #mobile-dev channel
- **Issue Tracker**: GitHub Issues
- **Code Review**: Submit PRs for feedback

---

## API Documentation

**📖 Complete API specifications are available in [../backend/CLAUDE.md](../backend/CLAUDE.md)**

The mobile app uses the Mobile API endpoints (`/api/v1/mobile/`) which include:

### Mobile App API Usage

#### Authentication APIs
- Registration and login with JWT tokens
- Automatic token refresh with device tracking
- Email verification and password reset

#### Content APIs
- Article feed with pagination and filtering
- Search functionality across articles and authors
- Category-based content browsing
- Personalized daily recommendations

#### User Profile APIs
- Profile management and preferences
- Reading history tracking
- Bookmark management
- Follow/unfollow authors

#### Interaction APIs
- Article likes and engagement tracking
- Reading session analytics
- Onboarding and preference setup

### Key Endpoints Reference

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/mobile/auth/login` | POST | User login |
| `/api/v1/mobile/auth/register` | POST | User registration |
| `/api/v1/mobile/auth/refresh` | POST | Refresh JWT token |
| `/api/v1/mobile/articles` | GET | List articles |
| `/api/v1/mobile/articles/:id` | GET | Get article details |
| `/api/v1/mobile/articles/:id/toggle-like` | POST | Like/unlike an article |
| `/api/v1/mobile/recommendations` | GET | Personalized recommendations |
| `/api/v1/mobile/user/bookmarks` | GET | User bookmarks |

### Authentication Headers
```http
Authorization: Bearer {access_token}
X-Client-Type: mobile
X-Device-ID: {device_uuid}
```

For complete endpoint specifications, request/response examples, and error handling details, see the [backend API documentation](../backend/CLAUDE.md).

---

## Best Practices

### Code Quality
1. Follow Dart style guide and linting rules
2. Use meaningful variable and function names
3. Add documentation comments for public APIs
4. Keep functions small and focused
5. Handle errors gracefully

### Performance
1. Use `const` constructors where possible
2. Implement lazy loading for lists
3. Optimize images (WebP format preferred)
4. Minimize widget rebuilds
5. Profile before optimizing

### Security
1. Never store sensitive data in SharedPreferences
2. Use Flutter Secure Storage for tokens
3. Implement certificate pinning for production
4. Validate all user inputs
5. Follow OWASP mobile guidelines

### Accessibility
1. Add semantic labels to all interactive elements
2. Ensure sufficient color contrast (WCAG AA)
3. Support screen readers
4. Test with accessibility tools
5. Provide alternative text for images

---

*Last Updated: January 2025*  
*Version: 1.0.0*  
*Maintainer: Mobile Team*