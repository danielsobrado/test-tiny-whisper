import 'dart:developer' as developer;
import '../config/app_constants.dart';

/// Centralized logging utility with different log levels and filtering
class AppLogger {
  AppLogger._(); // Private constructor

  static void _log(String level, String prefix, String message, {Object? error, StackTrace? stackTrace}) {
    if (!AppConstants.Logging.enableDebugLogs) return;
    
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $level $prefix $message';
    
    // Use developer.log for better debugging support
    developer.log(
      logMessage,
      name: prefix.replaceAll('[', '').replaceAll(']', ''),
      error: error,
      stackTrace: stackTrace,
    );
  }

  // Speech Recognition Logging
  static void speechInfo(String message) {
    if (AppConstants.Logging.enableSpeechLogs) {
      _log(AppConstants.Logging.infoPrefix, AppConstants.Logging.speechPrefix, message);
    }
  }

  static void speechError(String message, {Object? error, StackTrace? stackTrace}) {
    if (AppConstants.Logging.enableSpeechLogs) {
      _log(AppConstants.Logging.errorPrefix, AppConstants.Logging.speechPrefix, message, error: error, stackTrace: stackTrace);
    }
  }

  static void speechWarning(String message) {
    if (AppConstants.Logging.enableSpeechLogs) {
      _log(AppConstants.Logging.warningPrefix, AppConstants.Logging.speechPrefix, message);
    }
  }

  // Model Management Logging
  static void modelInfo(String message) {
    if (AppConstants.Logging.enableModelLogs) {
      _log(AppConstants.Logging.infoPrefix, AppConstants.Logging.modelPrefix, message);
    }
  }

  static void modelError(String message, {Object? error, StackTrace? stackTrace}) {
    if (AppConstants.Logging.enableModelLogs) {
      _log(AppConstants.Logging.errorPrefix, AppConstants.Logging.modelPrefix, message, error: error, stackTrace: stackTrace);
    }
  }

  static void modelWarning(String message) {
    if (AppConstants.Logging.enableModelLogs) {
      _log(AppConstants.Logging.warningPrefix, AppConstants.Logging.modelPrefix, message);
    }
  }

  // Network Logging
  static void networkInfo(String message) {
    if (AppConstants.Logging.enableNetworkLogs) {
      _log(AppConstants.Logging.infoPrefix, AppConstants.Logging.networkPrefix, message);
    }
  }

  static void networkError(String message, {Object? error, StackTrace? stackTrace}) {
    if (AppConstants.Logging.enableNetworkLogs) {
      _log(AppConstants.Logging.errorPrefix, AppConstants.Logging.networkPrefix, message, error: error, stackTrace: stackTrace);
    }
  }

  // Summarization Logging
  static void summarizationInfo(String message) {
    if (AppConstants.Logging.enableSummarizationLogs) {
      _log(AppConstants.Logging.infoPrefix, AppConstants.Logging.summarizationPrefix, message);
    }
  }

  static void summarizationError(String message, {Object? error, StackTrace? stackTrace}) {
    if (AppConstants.Logging.enableSummarizationLogs) {
      _log(AppConstants.Logging.errorPrefix, AppConstants.Logging.summarizationPrefix, message, error: error, stackTrace: stackTrace);
    }
  }

  // Translation Logging
  static void translationInfo(String message) {
    if (AppConstants.Logging.enableTranslationLogs) {
      _log(AppConstants.Logging.infoPrefix, AppConstants.Logging.translationPrefix, message);
    }
  }

  static void translationError(String message, {Object? error, StackTrace? stackTrace}) {
    if (AppConstants.Logging.enableTranslationLogs) {
      _log(AppConstants.Logging.errorPrefix, AppConstants.Logging.translationPrefix, message, error: error, stackTrace: stackTrace);
    }
  }

  // UI Logging
  static void uiInfo(String message) {
    _log(AppConstants.Logging.infoPrefix, AppConstants.Logging.uiPrefix, message);
  }

  static void uiError(String message, {Object? error, StackTrace? stackTrace}) {
    _log(AppConstants.Logging.errorPrefix, AppConstants.Logging.uiPrefix, message, error: error, stackTrace: stackTrace);
  }

  // General Logging
  static void info(String message, {String? category}) {
    final prefix = category != null ? '[$category]' : AppConstants.Logging.infoPrefix;
    _log(AppConstants.Logging.infoPrefix, prefix, message);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace, String? category}) {
    final prefix = category != null ? '[$category]' : AppConstants.Logging.errorPrefix;
    _log(AppConstants.Logging.errorPrefix, prefix, message, error: error, stackTrace: stackTrace);
  }

  static void warning(String message, {String? category}) {
    final prefix = category != null ? '[$category]' : AppConstants.Logging.warningPrefix;
    _log(AppConstants.Logging.warningPrefix, prefix, message);
  }

  // Performance Logging
  static void performanceInfo(String operation, Duration duration) {
    info('$operation completed in ${duration.inMilliseconds}ms', category: 'PERFORMANCE');
  }

  // Debug helper methods
  static void logMethodEntry(String className, String methodName, {Map<String, dynamic>? parameters}) {
    if (!AppConstants.Logging.enableDebugLogs) return;
    
    String message = '$className.$methodName() called';
    if (parameters != null && parameters.isNotEmpty) {
      message += ' with parameters: $parameters';
    }
    info(message, category: 'METHOD');
  }

  static void logMethodExit(String className, String methodName, {dynamic result}) {
    if (!AppConstants.Logging.enableDebugLogs) return;
    
    String message = '$className.$methodName() completed';
    if (result != null) {
      message += ' with result: $result';
    }
    info(message, category: 'METHOD');
  }

  // Network request logging
  static void logNetworkRequest(String method, String url, {Map<String, dynamic>? headers}) {
    if (!AppConstants.Logging.enableNetworkLogs) return;
    
    String message = '$method $url';
    if (headers != null && headers.isNotEmpty) {
      message += ' headers: $headers';
    }
    networkInfo('Request: $message');
  }

  static void logNetworkResponse(String method, String url, int statusCode, {Duration? duration}) {
    if (!AppConstants.Logging.enableNetworkLogs) return;
    
    String message = '$method $url -> $statusCode';
    if (duration != null) {
      message += ' (${duration.inMilliseconds}ms)';
    }
    networkInfo('Response: $message');
  }

  // Progress logging
  static void logProgress(String operation, double progress, {String? details}) {
    String message = '$operation: ${(progress * 100).toStringAsFixed(1)}%';
    if (details != null) {
      message += ' - $details';
    }
    info(message, category: 'PROGRESS');
  }

  // Configuration logging
  static void logConfiguration() {
    if (!AppConstants.Logging.enableDebugLogs) return;
    
    info('App Configuration:');
    info('- Debug logs: ${AppConstants.Logging.enableDebugLogs}');
    info('- PyTorch models: ${AppConstants.Features.enablePyTorchModels}');
    info('- Offline transcription: ${AppConstants.Features.enableOfflineTranscription}');
    info('- Real-time transcription: ${AppConstants.Features.enableRealTimeTranscription}');
    info('- Model download: ${AppConstants.Features.enableModelDownload}');
    info('- Translation: ${AppConstants.Features.enableTranslation}');
    info('- Summarization: ${AppConstants.Features.enableSummarization}');
  }
}