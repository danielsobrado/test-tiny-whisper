# Code Style and Conventions

## Linting and Analysis
- Uses `flutter_lints: ^3.0.0` for standard Flutter linting rules
- No custom analysis_options.yaml file - relies on Flutter defaults
- Code follows Material Design 3 patterns with `useMaterial3: true`

## Naming Conventions
- **Files**: snake_case (e.g., `audio_service.dart`, `model_download_widget.dart`)
- **Classes**: PascalCase (e.g., `AudioService`, `TinyWhisperTesterApp`)
- **Variables/Methods**: camelCase (e.g., `_currentRecordingPath`, `startRecording()`)
- **Constants**: camelCase with appropriate prefixes (e.g., `_isRecording`)
- **Private members**: Leading underscore (e.g., `_recorder`, `_currentRecordingPath`)

## Code Organization Patterns

### Service Classes
- Single responsibility principle
- Comprehensive error handling with descriptive Exception messages
- Async/await pattern for asynchronous operations
- Proper resource cleanup (dispose methods)
- Permission checking before operations

### Widget Structure
- Stateless widgets preferred where possible
- Clean separation of concerns
- Material Design 3 theming

### Error Handling
- Try-catch blocks with descriptive error messages
- Graceful fallbacks for non-critical operations
- User-friendly error reporting

## Documentation Style
- Inline comments for complex logic
- Method-level documentation for public APIs
- Configuration comments for important settings (e.g., Whisper audio format requirements)

## Import Organization
- Dart core imports first
- Package imports
- Relative imports last
- Alphabetical ordering within each group

## File Structure Conventions
- Services in `lib/services/`
- UI screens in `lib/screens/`
- Reusable widgets in `lib/widgets/`
- Models/data classes in `lib/models/`
- One class per file with matching filename
