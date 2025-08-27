/// Custom exceptions for the application
abstract class AppException implements Exception {
  final String message;
  final String? details;
  final Object? originalError;
  
  const AppException(this.message, {this.details, this.originalError});

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType: $message');
    if (details != null) {
      buffer.write('\nDetails: $details');
    }
    if (originalError != null) {
      buffer.write('\nCaused by: $originalError');
    }
    return buffer.toString();
  }
}

/// Exceptions related to model operations
class ModelException extends AppException {
  const ModelException(String message, {String? details, Object? originalError})
      : super(message, details: details, originalError: originalError);
}

/// Exceptions related to speech recognition
class SpeechRecognitionException extends AppException {
  const SpeechRecognitionException(String message, {String? details, Object? originalError})
      : super(message, details: details, originalError: originalError);
}

/// Exceptions related to audio processing
class AudioException extends AppException {
  const AudioException(String message, {String? details, Object? originalError})
      : super(message, details: details, originalError: originalError);
}

/// Exceptions related to network operations
class NetworkException extends AppException {
  const NetworkException(String message, {String? details, Object? originalError})
      : super(message, details: details, originalError: originalError);
}

/// Exceptions related to file operations
class FileException extends AppException {
  const FileException(String message, {String? details, Object? originalError})
      : super(message, details: details, originalError: originalError);
}

/// Exceptions related to translation
class TranslationException extends AppException {
  const TranslationException(String message, {String? details, Object? originalError})
      : super(message, details: details, originalError: originalError);
}

/// Exceptions related to summarization
class SummarizationException extends AppException {
  const SummarizationException(String message, {String? details, Object? originalError})
      : super(message, details: details, originalError: originalError);
}

/// Exceptions related to permissions
class PermissionException extends AppException {
  const PermissionException(String message, {String? details, Object? originalError})
      : super(message, details: details, originalError: originalError);
}

/// Exceptions related to configuration
class ConfigurationException extends AppException {
  const ConfigurationException(String message, {String? details, Object? originalError})
      : super(message, details: details, originalError: originalError);
}