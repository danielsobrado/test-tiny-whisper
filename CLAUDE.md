# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Tiny Whisper Tester is a Flutter Android application for testing different fine-tuned Whisper models for offline speech-to-text transcription on mobile devices. The app features real-time speech recognition, audio visualization, and model management capabilities.

## Development Commands

```bash
# Get Flutter dependencies
flutter pub get

# Run on Android device/emulator
flutter run

# Build debug APK
flutter build apk --debug

# Build release APK
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
- `lib/screens/` - UI screens (home_screen.dart)
- `lib/services/` - Business logic services
  - `model_download_service.dart` - HuggingFace model downloading
  - `audio_service.dart` - Microphone recording functionality
  - `whisper_service.dart` - ML inference (placeholder for offline models)
  - `pytorch_model_downloader.dart` - PyTorch model handling
  - `pytorch_whisper_service.dart` - PyTorch Whisper integration
- `lib/widgets/` - Reusable UI components
  - `audio_recorder_widget.dart` - Recording interface
  - `audio_visualizer_widget.dart` - Real-time waveform visualization
  - `model_download_widget.dart` - Model download interface
  - `model_management_widget.dart` - Model selection and management
  - `transcription_display_widget.dart` - Results display
- `android/` - Android-specific configuration and permissions

### Key Dependencies
- `speech_to_text: ^7.0.0` - Production-ready live speech recognition
- `sherpa_onnx: ^1.10.41` - Offline ONNX model support (framework ready)
- `audio_waveforms: ^1.1.0` - Real-time audio visualization
- `fl_chart: ^0.69.0` - Additional charts and visualizations
- `dio: ^5.3.2` & `http: ^1.1.0` - HTTP requests for model downloads
- `record: ^6.1.1` - Audio recording from microphone
- `permission_handler: ^12.0.1` - Android runtime permissions
- `path_provider: ^2.1.1` - File system access

### Android Configuration
- **Permissions**: Microphone, storage, internet access
- **Min SDK**: 23 (Android 6.0)
- **Package**: com.example.tiny_whisper_tester

## Implementation Notes

### Current Production Status
The app uses **real-time speech recognition** via the device's built-in speech engine through the `speech_to_text` package. This is production-ready and does not require downloaded models for basic functionality.

### Speech Recognition Architecture
- **Live Recognition**: Uses `speech_to_text` for real-time transcription
- **Audio Visualization**: Real-time waveform display with frequency bars
- **Permission Handling**: Smart permission requests with settings navigation
- **Multi-language Support**: Supports all languages available on device

### Model Management System
- **Storage Location**: `/storage/emulated/0/Android/data/com.example.tiny_whisper_tester/files/models/`
- **Supported Formats**: GGML (.bin), GGUF (.gguf), ONNX (.onnx), PyTorch (.ptl)
- **Download Sources**: HuggingFace direct URLs
- **Management UI**: Built-in download, replace, and delete functionality

### Audio Processing
- **Sample Rate**: 16kHz mono WAV (optimized for Whisper)
- **Recording Location**: `temp/recordings/` directory
- **Auto-cleanup**: Automatic cleanup of old recordings
- **Real-time Visualization**: Waveform and frequency spectrum display

### Future Offline Model Integration
Framework is ready for offline models via:
- `sherpa_onnx` for ONNX models
- `whisper_service.dart` placeholder for GGML/GGUF integration
- `pytorch_whisper_service.dart` for PyTorch models (currently has Android build issues)

## Model Compatibility

| Format | Extension | Status | Integration |
|--------|-----------|--------|-------------|
| ONNX | .onnx | ✅ Framework Ready | sherpa_onnx |
| GGML | .bin | 🔧 Development | whisper_service |
| GGUF | .gguf | 🔧 Development | whisper_service |
| PyTorch | .ptl, .bin | ❌ Android Issues | pytorch_whisper_service |

## Testing Workflow

### Live Speech Recognition (Current)
1. Grant microphone permissions when prompted
2. Tap "Start Recording" and speak clearly
3. View real-time transcription and audio visualization
4. Tap "Stop Recording" when finished

### Model Testing (Development)
1. Download models via Model Management interface
2. Select downloaded model from dropdown
3. Record audio and test with offline inference
4. Compare results between different models

## Known Limitations

- PyTorch models have Android NDK build conflicts
- Offline model inference is framework-ready but not fully implemented
- Currently Android-only (no iOS support)
- Real-time recognition requires internet connection (standard for mobile speech recognition)