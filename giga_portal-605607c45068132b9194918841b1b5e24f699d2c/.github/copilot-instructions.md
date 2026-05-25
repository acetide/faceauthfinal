# GIGA Portal - Copilot Instructions

## Project Overview
Employee/company portal Flutter app connecting to a backend API (http://192.168.2.182:5298). Features include user authentication, announcements, leave management, and admin functionality across mobile platforms (Android, iOS, Windows, Linux, Web).

## Architecture Patterns

### Service Layer
- **Singleton pattern for services**: `ApiService` is a static singleton initialized once at app start with hardcoded base URL.
- **Token management**: `ApiService.setToken()` called immediately after login. Auth header set globally via `dio.options.headers`.
- **Error handling**: Use `handleDioError()` utility to parse `DioException` responses with consistent error messages.

**Example**: All API calls inherit the token from `ApiService` singleton—don't pass tokens as parameters.

### Model-Screen Flow
- Models use `fromJson()` factory constructors for API deserialization (e.g., `User.fromJson(response.data['userData'])`)
- Screens receive models as constructor parameters, not fetched internally
- Login screen creates `User` and passes to `HomeScreen`, establishing the session pattern

### State Management
- **Stateful widgets** with `setState()` for local UI state (loading, errors, lists)
- **Global variable fallback**: `currentUser` in `user_session.dart` as temporary session holder (migrate to provider/storage later)
- **LocalStorageService**: Static methods using `SharedPreferences`, handles serialization (base64 for binary), recovers from corrupted data

### Widget Composition
- Reusable widgets: `AnnouncementCard`, `UserInfoCard` in `/widgets/`
- **Tab-based navigation**: `TabController` with `TabBar`/`TabBarView` in employee home screen (2 tabs: Announcements, Admin)
- Simple layouts prefer Padding, Column, Row, SizedBox over complex layouts

## Key File Locations

| Component | Location |
|-----------|----------|
| API/Auth | [lib/services/](lib/services/) (api_service.dart, auth_service.dart) |
| Models | [lib/models/](lib/models/) (user_model.dart, announcement_model.dart) |
| Screens | [lib/screens/](lib/screens/), [lib/employee/](lib/employee/) |
| Widgets | [lib/widgets/](lib/widgets/) |
| Session | [lib/session/user_session.dart](lib/session/user_session.dart) |
| Storage | [lib/services/local_storage_service.dart](lib/services/local_storage_service.dart) |

## Developer Workflows

### Build & Run
```bash
flutter pub get          # Install dependencies
flutter run              # Debug on available device
flutter build apk        # Android release
flutter build ios        # iOS release
flutter build windows    # Windows build
```

### Dependencies
Key packages: `dio` (HTTP), `shared_preferences` (local storage), `image_picker`, `flutter_secure_storage`, `uuid`.

## Important Conventions

1. **Null handling in API responses**: Explicitly cast JSON to strings (`as String`) before type-coercing (see `AuthService.login()`)
2. **Resource disposal**: `TextEditingController.dispose()`, `TabController.dispose()` in State's dispose method
3. **Mounted checks**: Always check `if (!mounted) return;` after async operations before calling `setState()`
4. **Error messages**: Strip `DioException:` and `Exception:` prefixes before displaying to users
5. **LocalStorage recovery**: Catch corrupted data and clear storage to prevent white-screen crashes
6. **Test devices**: Base API URL hardcoded to `192.168.2.182:5298`—update for different environments

## Anti-Patterns to Avoid

- Don't create new `ApiService()` instances; always use the singleton
- Don't pass tokens as function parameters (relies on global state)
- Don't skip mounted checks after async calls in Stateful widgets
- Don't serialize image binary data without base64 encoding for SharedPreferences
- Avoid direct navigation without error handling—always wrap in try/catch with user feedback

## Future Refactoring Notes

- Replace `currentUser` global with Provider/GetX state management
- Extract Dio configuration and interceptors
- Migrate `UserSession` serialization to secure storage
- Add integration tests for auth flow
