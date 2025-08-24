# Tech Stack and Dependencies

## Framework
- **Flutter**: >=3.10.0
- **Dart**: >=3.0.0 <4.0.0
- **Android**: Min SDK 23 (Android 6.0), Target SDK 34

## Key Dependencies

### UI Framework
- `flutter` - Core Flutter framework
- `cupertino_icons: ^1.0.6` - iOS-style icons

### HTTP & Networking
- `http: ^1.1.0` - HTTP requests
- `dio: ^5.3.2` - Advanced HTTP client for model downloads with progress tracking

### Audio Recording
- `record: ^5.0.4` - Audio recording functionality
- `permission_handler: ^11.0.1` - Runtime permission handling

### File System
- `path_provider: ^2.1.1` - Access to device directories
- `path: ^1.8.3` - Path manipulation utilities

### Machine Learning (Placeholder)
- `tflite_flutter: ^0.10.4` - TensorFlow Lite integration (currently for placeholder)

### Development Dependencies
- `flutter_test` - Testing framework
- `flutter_lints: ^3.0.0` - Linting rules

## Build Configuration
- **Compile SDK**: 34
- **NDK Version**: 25.1.8937393
- **Java Compatibility**: VERSION_1_8
- **Kotlin Target**: JVM 1.8
- **Application ID**: com.example.tiny_whisper_tester

## Future Dependencies (Needed for Real Implementation)
- Whisper.cpp Flutter plugin or FFI bindings
- Audio preprocessing libraries
- Model validation and metadata extraction tools
