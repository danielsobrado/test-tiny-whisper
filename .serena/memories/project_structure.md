# Project Structure

## Top-Level Directories
- `.serena/` - Serena configuration files
- `android/` - Android platform-specific code and configuration
- `assets/` - Static assets (images, models)
- `build/` - Build output directory (generated)
- `flutter/` - Flutter SDK (bundled)
- `lib/` - Main Dart source code
- `.dart_tool/` - Dart tool cache (generated)
- `.claude/` - Claude-specific files

## Key Files
- `pubspec.yaml` - Project configuration and dependencies
- `pubspec.lock` - Dependency lock file (generated)
- `CLAUDE.md` - Project documentation and guidance for Claude
- `.flutter-plugins-dependencies` - Plugin dependency metadata

## Source Code Structure (`lib/`)

### Main Entry Point
- `lib/main.dart` - Application entry point and MaterialApp setup

### Screens (`lib/screens/`)
- `home_screen.dart` - Main application screen with UI for testing Whisper models

### Services (`lib/services/`)
- `audio_service.dart` - Microphone recording, permission handling, audio file management
- `model_download_service.dart` - HuggingFace model downloading with progress tracking
- `whisper_service.dart` - ML inference (currently placeholder implementation)

### Widgets (`lib/widgets/`)
- `audio_recorder_widget.dart` - UI component for audio recording
- `model_download_widget.dart` - UI component for model download interface
- `transcription_display_widget.dart` - UI component for showing transcription results

### Models (`lib/models/`)
- Directory exists for data classes and model definitions

## Android Configuration (`android/`)

### Key Android Files
- `android/app/src/main/AndroidManifest.xml` - App permissions and configuration
- `android/app/build.gradle` - Build configuration, SDK versions, dependencies
- `android/app/src/main/kotlin/` - Native Android code (if needed)

### Important Android Settings
- **Permissions**: RECORD_AUDIO, WRITE_EXTERNAL_STORAGE, READ_EXTERNAL_STORAGE, INTERNET, ACCESS_NETWORK_STATE
- **Min SDK**: 23 (Android 6.0)
- **Target SDK**: 34
- **Package**: com.example.tiny_whisper_tester

## Assets Structure (`assets/`)
- `assets/images/` - Image assets
- `assets/models/` - Model files (GGML format)

## Data Directories (Runtime)
- `app_documents/models/` - Downloaded model files
- `temp/recordings/` - Temporary audio recordings
- Both directories are created automatically by the app
