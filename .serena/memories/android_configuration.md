# Android Configuration and Permissions

## AndroidManifest.xml Configuration

### Required Permissions
- `RECORD_AUDIO` - Essential for microphone recording functionality
- `WRITE_EXTERNAL_STORAGE` - For saving downloaded models and audio files
- `READ_EXTERNAL_STORAGE` - For reading model files and recordings
- `INTERNET` - For downloading models from HuggingFace URLs
- `ACCESS_NETWORK_STATE` - For checking network connectivity before downloads

### Application Configuration
- **Application Name**: "Tiny Whisper Tester"
- **Package ID**: com.example.tiny_whisper_tester
- **Clear Text Traffic**: Enabled (for HTTP model downloads)
- **Legacy External Storage**: Enabled (for broader file access compatibility)
- **Hardware Accelerated**: Enabled (for better performance)

### Activity Configuration
- **Launch Mode**: singleTop
- **Config Changes**: Handles orientation, keyboard, screen size changes
- **Window Soft Input Mode**: adjustResize
- **Theme**: Custom launch and normal themes

## Build Configuration (build.gradle)

### SDK Versions
- **Compile SDK**: 34 (Android 14)
- **Min SDK**: 23 (Android 6.0) - Required for modern audio and permission APIs
- **Target SDK**: 34 (Android 14) - Latest features and security
- **NDK Version**: 25.1.8937393 (for potential native libraries)

### Compatibility
- **Java Version**: 1.8 (for broad compatibility)
- **Kotlin JVM Target**: 1.8
- **Gradle Plugin**: Uses Flutter's gradle plugin

## Permission Handling in Code

### Runtime Permissions
- Microphone permission checked and requested via `permission_handler` package
- Graceful handling of permission denial
- User-friendly error messages when permissions are required

### Storage Access
- Uses `path_provider` for accessing app-specific directories
- Models stored in app documents directory
- Temporary recordings in app temporary directory
- Automatic directory creation if not exists

## Testing Considerations

### Device Requirements
- Android 6.0+ (API 23+)
- Microphone hardware
- Network connectivity for model downloads
- Adequate storage space for models (GGML files can be large)

### Permission Testing
- Test permission request flow on first launch
- Test app behavior when permissions are denied
- Test app behavior when permissions are revoked after granting
- Verify permission persistence across app restarts

### Platform-Specific Issues
- Test on different Android versions (6.0, 7.0, 8.0+, 10+, 11+, 14)
- Verify scoped storage compliance on Android 10+
- Test audio recording quality on different devices
- Check network security policy compliance

## Future Considerations
- **iOS Support**: Will need Info.plist configuration and different permission handling
- **Scoped Storage**: May need to update for stricter Android storage policies
- **Background Processing**: May need background processing permissions for long downloads
- **Audio Focus**: May need to implement proper audio focus handling
