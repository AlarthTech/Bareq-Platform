# براق للشركات - Flutter Mobile App

Company Management System for Maid/Worker Service Companies

## 📱 Project Overview

This is a production-ready Flutter mobile application built with Clean Architecture principles. The app manages companies that provide maid/worker services, including worker management, bookings, shifts, and analytics.

## 🏗️ Architecture

The project follows **Clean Architecture** with strict separation of concerns:

```
lib/
├── core/                    # Core infrastructure
│   ├── constants/          # App constants and API endpoints
│   ├── di/                  # Dependency injection setup
│   ├── error/              # Error handling (failures, exceptions)
│   ├── network/            # API client and networking
│   ├── routing/            # App routing with go_router
│   ├── theme/              # App theme and styling
│   ├── utils/              # Utility functions and helpers
│   └── widgets/            # Reusable UI components
│
└── features/                # Feature modules
    └── feature_name/
        ├── data/           # Data layer
        │   ├── datasources/    # Remote/local data sources
        │   ├── models/         # Data models
        │   └── repositories/   # Repository implementations
        │
        ├── domain/         # Domain layer (business logic)
        │   ├── entities/       # Domain entities
        │   ├── repositories/   # Repository interfaces
        │   └── usecases/       # Use cases
        │
        └── presentation/   # Presentation layer
            ├── bloc/          # BLoC (state management)
            ├── screens/       # UI screens
            └── widgets/       # Feature-specific widgets
```

## 🎯 Key Features

### ✅ Implemented
- ✅ Authentication (Login, Register, Logout)
- ✅ Core infrastructure (Network, Error Handling, Theme, Routing)
- ✅ Reusable UI components
- ✅ Dependency Injection setup

### 🚧 To Be Implemented
- Company Management
- Dashboard with KPIs and Charts
- Workers Management
- Work Types (Shifts) Management
- Bookings Management
- Calendar Views

## 📦 Dependencies

### State Management
- `flutter_bloc` - BLoC pattern
- `equatable` - Value equality
- `dartz` - Functional programming (Either type)

### Networking
- `dio` - HTTP client
- `pretty_dio_logger` - Request/response logging

### Dependency Injection
- `get_it` - Service locator
- `injectable` - Code generation for DI

### Routing
- `go_router` - Declarative routing

### Local Storage
- `shared_preferences` - Key-value storage

### UI & Charts
- `fl_chart` - Beautiful charts
- `table_calendar` - Calendar widget
- `shimmer` - Loading placeholders
- `cached_network_image` - Image caching

### Internationalization
- `intl` - Date/number formatting

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.7.0 or higher
- Dart 3.7.0 or higher

### Installation

1. Clone the repository
2. Install dependencies:
```bash
flutter pub get
```

3. Run code generation (if using injectable):
```bash
flutter pub run build_runner build
```

4. Run the app:
```bash
flutter run
```

## 🔧 Configuration

### API Base URL
Update the base URL in `lib/core/constants/api_constants.dart`:
```dart
static const String baseUrl = 'http://102.203.200.55:5545';
```

## 📝 Code Style

- Follow Flutter/Dart style guide
- Use `const` constructors where possible
- Prefer composition over inheritance
- Keep widgets small and focused
- Use meaningful variable and function names

## 🧪 Testing

Run tests with:
```bash
flutter test
```

## 📱 Features Implementation Guide

Each feature follows this pattern:

1. **Domain Layer**: Define entities, repository interfaces, and use cases
2. **Data Layer**: Implement data sources, models, and repository implementations
3. **Presentation Layer**: Create BLoC, screens, and widgets
4. **Dependency Injection**: Register all dependencies in `core/di/injection.dart`
5. **Routing**: Add routes in `core/routing/app_router.dart`

## 🎨 UI/UX Guidelines

- Modern, corporate, clean design
- Soft shadows and rounded corners (12-20px radius)
- 8pt grid system for spacing
- Calm color palette
- Smooth animations
- Full RTL support for Arabic
- Professional feel (ERP/Admin Dashboard style)

## 🌍 Localization

The app supports Arabic (RTL) as the primary language:
- Locale: `ar_SA`
- Text direction: RTL
- Date/Time formatting: Arabic locale
- Currency: د.ل (Libyan Dinar)

## 📄 License

This project is private and proprietary.

## 👥 Development Team

Built with ❤️ for Bareq Companies
