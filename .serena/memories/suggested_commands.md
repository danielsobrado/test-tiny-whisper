# Suggested Commands for Development

## Windows/WSL Commands (System Utilities)
- `ls` - List files (or `dir` on Windows)
- `cd <directory>` - Change directory
- `pwd` - Show current directory
- `mkdir <directory>` - Create directory
- `rm <file>` or `del <file>` - Delete file
- `cp <source> <dest>` or `copy <source> <dest>` - Copy file
- `find . -name "*.dart"` or `dir /s *.dart` - Find Dart files
- `grep -r "pattern" .` or `findstr /s "pattern" *.dart` - Search in files

## Git Commands
- `git status` - Check repository status
- `git add .` - Stage all changes
- `git commit -m "message"` - Commit changes
- `git push` - Push to remote repository
- `git pull` - Pull from remote repository
- `git branch` - List branches
- `git checkout <branch>` - Switch branch

## Flutter Development Commands

### Setup and Dependencies
- `flutter pub get` - Get Flutter dependencies (run after changing pubspec.yaml)
- `flutter clean` - Clean build artifacts (helpful for resolving build issues)
- `flutter doctor` - Check Flutter installation and dependencies

### Running and Building
- `flutter run` - Run app on connected device/emulator (debug mode)
- `flutter run --release` - Run in release mode
- `flutter build apk` - Build APK for Android
- `flutter build apk --release` - Build release APK
- `flutter install` - Install built APK on connected device

### Development Tools
- `flutter analyze` - Run static analysis on code (check for issues)
- `flutter test` - Run unit and widget tests
- `flutter test --coverage` - Run tests with coverage report

### Device Management
- `flutter devices` - List available devices and emulators
- `flutter emulators` - List available emulators
- `flutter emulators --launch <emulator_id>` - Launch emulator

### Debugging and Inspection
- `flutter logs` - Show device logs
- `flutter inspect` - Open Flutter Inspector
- `flutter attach` - Attach to running Flutter app

## Android Development Commands
- `adb devices` - List connected Android devices
- `adb install app-release.apk` - Install APK manually
- `adb logcat` - View Android system logs
- `adb shell` - Access device shell

## Project-Specific Workflow
1. `flutter pub get` - Get dependencies
2. `flutter analyze` - Check code quality
3. `flutter test` - Run tests
4. `flutter run` - Test on device/emulator
5. `flutter build apk --release` - Create release build
