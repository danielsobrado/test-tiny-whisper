# Task Completion Workflow

## Pre-Completion Checks

### Code Quality
1. `flutter analyze` - Ensure no linting errors or warnings
2. Review code follows project conventions (see code_style_conventions.md)
3. Check imports are properly organized
4. Verify error handling is implemented
5. Ensure resource cleanup (dispose methods) where applicable

### Testing
1. `flutter test` - Run all unit and widget tests
2. Manual testing on Android device/emulator
3. Test edge cases and error scenarios
4. Verify permissions work correctly
5. Test audio recording and file operations

### Functionality Verification
1. Test model download functionality
2. Verify audio recording works (16kHz mono WAV format)
3. Check file system operations (model storage, recording cleanup)
4. Test permission handling flows
5. Verify UI responsiveness and error display

## Build Verification
1. `flutter clean` - Clean previous builds
2. `flutter pub get` - Refresh dependencies
3. `flutter build apk --release` - Create release build
4. Test release build on actual device
5. Verify APK size and performance

## Documentation Updates
1. Update CLAUDE.md if architecture changes
2. Add inline comments for complex logic
3. Document any new dependencies or configuration
4. Update project structure documentation if needed

## Final Checklist
- [ ] Code analyzed successfully (`flutter analyze`)
- [ ] All tests pass (`flutter test`)
- [ ] Manual testing completed on device
- [ ] Release build created and tested
- [ ] No TODO comments or placeholder code (unless intentional)
- [ ] Error handling implemented appropriately
- [ ] Resources properly disposed
- [ ] Code follows project conventions
- [ ] Documentation updated if needed

## Platform-Specific Considerations

### Android
- Verify AndroidManifest.xml permissions are correct
- Test on different Android API levels if possible
- Check that storage and microphone permissions work
- Verify network requests work correctly
- Test APK installation and running

### Future iOS Considerations (Not Currently Implemented)
- iOS permissions (Info.plist)
- iOS-specific audio configuration
- App Store compliance checks
