/// App-wide constants and configuration values
class AppConstants {
  AppConstants._(); // Private constructor to prevent instantiation

  // App Information
  static const String appName = 'Tiny Whisper Tester';
  static const String appVersion = '1.0.0';
  static const String userAgent = '$appName/$appVersion';

  // UI Configuration
  static const int maxTabCount = 5;
  static const double defaultSoundLevel = 0.0;
  static const int initialTabIndex = 0;

  // Layout and Spacing
  static const double defaultHorizontalPadding = 20.0;
  static const double defaultVerticalPadding = 16.0;
  static const double defaultCardPadding = 20.0;
  static const double smallSpacing = 4.0;
  static const double mediumSpacing = 8.0;
  static const double largeSpacing = 16.0;
  static const double extraLargeSpacing = 24.0;

  // Icon Sizes
  static const double smallIconSize = 16.0;
  static const double defaultIconSize = 20.0;
  static const double largeIconSize = 24.0;

  // Font Sizes
  static const double tinyFontSize = 10.0;
  static const double smallFontSize = 11.0;
  static const double defaultFontSize = 12.0;
  static const double mediumFontSize = 14.0;
  static const double largeFontSize = 16.0;

  // Border Radius
  static const double smallBorderRadius = 4.0;
  static const double defaultBorderRadius = 6.0;
  static const double mediumBorderRadius = 8.0;
  static const double largeBorderRadius = 12.0;
  static const double extraLargeBorderRadius = 16.0;

  // Opacity Values
  static const double lowOpacity = 0.1;
  static const double mediumOpacity = 0.3;
  static const double highOpacity = 0.7;

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(seconds: 1);

  // Speech Recognition Configuration
  static const Duration speechListenDuration = Duration(minutes: 10);
  static const Duration speechPauseDuration = Duration(seconds: 30);
  static const double languageDetectionConfidenceThreshold = 0.5;

  // Network Configuration
  static const Duration networkReceiveTimeout = Duration(minutes: 30);
  static const Duration networkSendTimeout = Duration(minutes: 5);
  static const Duration shortNetworkTimeout = Duration(minutes: 10);

  // File System
  static const String recordingFileExtension = '.wav';
  static const String tempRecordingPrefix = 'recording_';
  static const String modelMetadataFileName = 'model_metadata.json';
  static const String pytorchModelFileName = 'pytorch_model.bin';
  static const String configFileName = 'config.json';

  // Model Extensions
  static const String ggufExtension = '.gguf';
  static const String ggmlExtension = '.bin';
  static const String onnxExtension = '.onnx';
  static const String pytorchExtension = '.ptl';
  static const String tfliteExtension = '.tflite';

  // File Size Limits
  static const int bytesPerKB = 1024;
  static const int bytesPerMB = 1024 * 1024;
  static const int bytesPerGB = 1024 * 1024 * 1024;

  // Text Processing
  static const int defaultSummaryMaxLength = 100;
  static const int maxBulletPoints = 4;
  static const int maxKeyWords = 5;
  static const int minWordLength = 4;
  static const int minSentenceLength = 10;
  static const int maxFilePathDisplay = 100;

  // Progress Tracking
  static const double progressStart = 0.0;
  static const double progressComplete = 1.0;
  static const double progressAnalyzing = 0.1;
  static const double progressDownloading = 0.95;

  // Default URLs and Paths
  static const String defaultModelUrl = 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin';
  static const String huggingfaceHost = 'huggingface.co';
  static const String defaultTargetLanguage = 'en';

  // Error Messages
  static class ErrorMessages {
    static const String microphonePermissionRequired = 'This app needs microphone access to record your voice for speech recognition.';
    static const String storagePermissionRequired = 'This app needs storage access to download and manage speech recognition models.';
    static const String noTextToSummarize = 'No text to summarize.';
    static const String speechRecognitionFailed = 'Failed to start speech recognition';
    static const String modelNotFound = 'Model file not found';
    static const String connectionTimeout = 'Connection timeout. Please check your internet connection.';
    static const String downloadTimeout = 'Download timeout. The file might be too large.';
    static const String serverError = 'Server error. Please check the URL.';
    static const String connectionError = 'Connection error. Please check your internet connection.';
    static const String pytorchDisabled = 'PyTorch models temporarily disabled. Use ONNX (.onnx) models for offline recognition.';
    static const String onnxNotImplemented = 'ONNX model loading not fully implemented. ONNX models require encoder.onnx, decoder.onnx, and tokens.txt files. Falling back to live speech recognition.';
    static const String fileTranscriptionNotSupported = 'Speech-to-text requires live audio input. File-based transcription is not supported with this implementation. Please use the microphone recording feature instead.';
    static const String offlineTranscriptionNotImplemented = 'Offline model transcription not fully implemented. This requires proper ONNX model files (encoder.onnx, decoder.onnx, tokens.txt). Please use live speech recognition instead.';
  }

  // Success Messages
  static class SuccessMessages {
    static const String speechRecognitionStarted = 'Speech recognition started. Start speaking...';
    static const String listeningStarted = 'Listening started';
    static const String listeningStopped = 'Listening stopped. Tap Start to continue.';
    static const String modelDownloaded = 'Model downloaded successfully';
    static const String modelDeleted = 'Model deleted successfully';
    static const String replaceModeActivated = 'Replace mode activated. Download a new model to replace the selected one.';
  }

  // Status Messages
  static class StatusMessages {
    static const String noModelLoaded = 'No model loaded';
    static const String deviceSpeechRecognition = 'Device speech recognition';
    static const String noOfflineModelSelected = 'No offline model selected';
    static const String modelFileNotFound = 'Device speech recognition (model file not found)';
    static const String selectedModelNotExists = 'Selected model file does not exist';
    static const String modelMissingFallback = 'Model file missing - using device speech recognition';
    static const String offlineModelActive = 'Offline model (sherpa_onnx)';
    static const String offlineModelLoaded = 'Offline model loaded and active';
    static const String usingOfflineModel = 'Using offline model for transcription';
    static const String deviceFallbackNotImplemented = 'Device speech recognition (offline models not yet implemented)';
    static const String selectedModelNotUsed = 'Selected model not in use - offline processing not implemented';
    static const String modelSelectedDeviceFallback = 'Model selected but using device speech recognition';
  }

  // Logging Configuration
  static class Logging {
    static const bool enableDebugLogs = true; // Set to false for production
    static const bool enableNetworkLogs = true;
    static const bool enableModelLogs = true;
    static const bool enableSpeechLogs = true;
    static const bool enableSummarizationLogs = true;
    static const bool enableTranslationLogs = true;
    
    // Log prefixes for filtering
    static const String speechPrefix = '[SPEECH]';
    static const String modelPrefix = '[MODEL]';
    static const String networkPrefix = '[NETWORK]';
    static const String summarizationPrefix = '[SUMMARIZATION]';
    static const String translationPrefix = '[TRANSLATION]';
    static const String uiPrefix = '[UI]';
    static const String errorPrefix = '[ERROR]';
    static const String warningPrefix = '[WARNING]';
    static const String infoPrefix = '[INFO]';
  }

  // Validation Rules
  static class Validation {
    static const int minUrlLength = 10;
    static const int maxUrlLength = 500;
    static const int maxModelNameLength = 100;
    static const int maxErrorMessageLength = 1000;
    static const double minFileSize = 1.0; // bytes
    static const double maxModelSizeGB = 10.0; // GB
  }

  // Feature Flags
  static class Features {
    static const bool enablePyTorchModels = false; // Disabled due to Android conflicts
    static const bool enableOfflineTranscription = false; // Not yet implemented
    static const bool enableRealTimeTranscription = true;
    static const bool enableModelDownload = true;
    static const bool enableTranslation = true;
    static const bool enableSummarization = true;
    static const bool enableAudioVisualization = true;
  }
}