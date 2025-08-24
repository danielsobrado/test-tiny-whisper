# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Tiny Whisper Tester is a Flutter Android application for testing different fine-tuned Whisper Tiny models for offline speech-to-text transcription on mobile devices. Users can download GGML models from HuggingFace URLs and test them with microphone input.

## Development Commands

```bash
# Get Flutter dependencies
flutter pub get

# Run on Android device/emulator
flutter run

# Build APK for release
flutter build apk --release

# Clean build artifacts
flutter clean

# Analyze code
flutter analyze

# Run tests
flutter test
```

## Project Architecture

### Directory Structure
- `lib/screens/` - UI screens (HomeScreen)
- `lib/services/` - Business logic services
  - `model_download_service.dart` - HuggingFace model downloading
  - `audio_service.dart` - Microphone recording functionality
  - `whisper_service.dart` - ML inference (placeholder for real Whisper integration)
- `lib/widgets/` - Reusable UI components
- `android/` - Android-specific configuration and permissions

### Key Dependencies
- `dio` & `http` - HTTP requests for model downloads
- `record` - Audio recording from microphone
- `permission_handler` - Android runtime permissions
- `path_provider` - File system access
- `tflite_flutter` - ML inference framework (placeholder)

### Android Configuration
- **Permissions**: Microphone, storage, internet access
- **Min SDK**: 23 (Android 6.0)
- **Target SDK**: 34

## Implementation Notes

### Whisper Integration
The current `WhisperService` is a placeholder implementation. For production use, you need:

1. **Real GGML Integration**: Use whisper.cpp Flutter plugin or FFI bindings
2. **Model Format**: Currently expects GGML .bin files from whisper.cpp
3. **Audio Processing**: Implement proper WAV file parsing and preprocessing

### Model Download
- Downloads models to `app_documents/models/` directory
- Supports HuggingFace direct file URLs
- Progress tracking and error handling included

### Audio Recording
- Records in 16kHz mono WAV format (optimized for Whisper)
- Stores temporary recordings in `temp/recordings/` directory
- Automatic cleanup of old recordings

## Testing Workflow

1. Download a Whisper GGML model from HuggingFace
2. Grant microphone and storage permissions
3. Record audio using the microphone
4. View transcription results (currently mock data)

## Known Limitations

- Whisper inference is currently mocked - needs real implementation
- Only supports Android platform
- No model caching or management features
- Limited error handling for corrupted models

## Future Enhancements

- Integrate real whisper.cpp for actual inference
- Add model validation and metadata extraction
- Implement model comparison and benchmarking
- Add iOS support
- Include audio preprocessing visualizations