# Feelu - Flutter Project

A Flutter application designed to facilitate communication between blind and deaf people with the outside world.

## VS Code Setup Instructions

### Prerequisites

Before working with this project in VS Code, ensure you have the following installed:

1. **Flutter SDK** (latest stable version)
   - Download from [flutter.dev](https://docs.flutter.dev/get-started/install)
   - Add Flutter to your PATH
   - Verify installation: `flutter doctor`

2. **Visual Studio Code**
   - Download from [code.visualstudio.com](https://code.visualstudio.com/)

3. **Platform-specific requirements:**
   - **Android**: Android Studio or Android SDK + Android SDK Command-line Tools
   - **iOS** (macOS only): Xcode

### Required VS Code Extensions

Install these essential extensions for Flutter development:

1. **Flutter** (by Dart Code)
   - Provides Flutter support, debugging, and hot reload
   - Install: `ext install Dart-Code.flutter`

2. **Dart** (by Dart Code)
   - Usually installed automatically with Flutter extension
   - Install: `ext install Dart-Code.dart-code`

3. **Recommended additional extensions:**
   - **Error Lens**: Real-time error highlighting
   - **Bracket Pair Colorizer 2**: Better bracket matching
   - **GitLens**: Enhanced Git capabilities
   - **Todo Highlight**: Highlight TODO comments
   - **Flutter Widget Snippets**: Quick widget creation

### Project Setup

1. **Clone and open the project:**
   ```bash
   git clone <repository-url>
   cd feelu
   code .
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Verify Flutter setup:**
   ```bash
   flutter doctor
   ```
   Fix any issues reported by `flutter doctor`.


### Running the Project

#### Using VS Code Interface

1. **Open Command Palette** (`Cmd+Shift+P` / `Ctrl+Shift+P`)
2. Type "Flutter: Select Device" and choose your target device
3. Press `F5` or click "Run and Debug" to start the app

#### Using Terminal

```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Run on all connected devices
flutter run -d all

# Run with hot reload (default)
flutter run

# Run in release mode
flutter run --release
```

### Development Workflow

#### Hot Reload & Hot Restart

- **Hot Reload**: `r` in terminal or `Cmd+S` / `Ctrl+S` (save file)
- **Hot Restart**: `R` in terminal or `Cmd+Shift+F5` / `Ctrl+Shift+F5`

#### Debugging

1. Set breakpoints by clicking in the gutter next to line numbers
2. Use Debug Console to inspect variables
3. Use Debug Sidebar to view call stack and variables

#### Useful VS Code Shortcuts

- `Cmd+Shift+P` / `Ctrl+Shift+P`: Command Palette
- `Cmd+.` / `Ctrl+.`: Quick Fix (show code actions)
- `F12`: Go to Definition
- `Shift+F12`: Find All References
- `Cmd+Shift+O` / `Ctrl+Shift+O`: Go to Symbol in File
- `Cmd+T` / `Ctrl+T`: Go to Symbol in Workspace

### Testing

#### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage
```

#### Using VS Code Test Explorer

1. Install "Flutter Test Explorer" extension
2. Use Test Explorer panel to run individual tests
3. View test results inline with code

### Building the App

#### Debug Builds

```bash
# Android APK
flutter build apk --debug

# iOS (macOS only)
flutter build ios --debug
```

#### Release Builds

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle

# iOS (macOS only)
flutter build ios --release

# Web
flutter build web

# macOS (macOS only)
flutter build macos

# Windows (Windows only)
flutter build windows

# Linux (Linux only)
flutter build linux
```

### Common Commands

```bash
# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Clean build cache
flutter clean

# Analyze code
flutter analyze

# Format code
dart format lib/

# Generate code (if using code generation)
flutter packages pub run build_runner build

# Update Flutter
flutter upgrade
```

### Troubleshooting

#### Common Issues

1. **"Flutter SDK not found"**
   - Ensure Flutter is in your PATH
   - Restart VS Code after installing Flutter

2. **"No devices found"**
   - For Android: Enable Developer Options and USB Debugging
   - For iOS: Trust your computer on the device
   - Check `flutter devices`

3. **Pub get fails**
   - Check internet connection
   - Try `flutter clean` then `flutter pub get`

4. **Hot reload not working**
   - Check for syntax errors
   - Try hot restart instead
   - Restart the app completely

#### Helpful Commands

```bash
# Check for issues
flutter doctor -v

# Clear all caches
flutter clean && flutter pub get

# Reset to stable channel
flutter channel stable && flutter upgrade
```

### Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Flutter Widget Catalog](https://docs.flutter.dev/development/ui/widgets)
- [VS Code Flutter Extension Guide](https://docs.flutter.dev/development/tools/vs-code)
- [Android Accessibility](https://developer.android.com/guide/topics/ui/accessibility)
- [iOS Accessibility](https://developer.apple.com/accessibility/)
