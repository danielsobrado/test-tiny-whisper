import 'dart:io';
// import 'package:whisper_ggml/whisper_ggml.dart';  // Temporarily disabled for Android build
// import 'pytorch_whisper_service.dart';  // Temporarily disabled for Android build

class WhisperService {
  dynamic _controller;  // Placeholder for WhisperController
  // PyTorchWhisperService? _pytorchService;  // Temporarily disabled for Android build
  String? _currentModelPath;
  bool _isInitialized = false;

  Future<void> loadModel(String modelPath) async {
    try {
      final File modelFile = File(modelPath);
      if (!await modelFile.exists()) {
        throw Exception('Model file not found: $modelPath');
      }

      if (_isPyTorchModel(modelPath)) {
        // PyTorch models temporarily disabled for Android build
        throw Exception('PyTorch models temporarily disabled. Use GGML (.bin) or GGUF (.gguf) models instead.');
      } else {
        // ML packages temporarily disabled for Android build
        // Using mock implementation
        _controller = 'mock_controller';
        _isInitialized = true;
        print('GGML/GGUF model loaded from: $modelPath');
      }
      
      _currentModelPath = modelPath;
      
    } catch (e) {
      throw Exception('Failed to load model: $e');
    }
  }

  Future<String> transcribe({
    required String audioPath,
    required String modelPath,
    String? language,
  }) async {
    try {
      // Load model if not already loaded or if different model
      if (_currentModelPath != modelPath) {
        await loadModel(modelPath);
      }

      final File audioFile = File(audioPath);
      if (!await audioFile.exists()) {
        throw Exception('Audio file not found: $audioPath');
      }

      if (!_isInitialized) {
        throw Exception('Model not initialized');
      }

      if (_isPyTorchModel(modelPath)) {
        // PyTorch models temporarily disabled for Android build
        throw Exception('PyTorch models temporarily disabled. Use GGML (.bin) or GGUF (.gguf) models instead.');
      } else {
        // Use whisper_ggml for GGML/GGUF models
        if (_controller == null) {
          throw Exception('Whisper controller not initialized');
        }

        // Check if this is a GGUF model and warn about compatibility
        if (_isGGUFModel(modelPath)) {
          print('Warning: GGUF model detected. whisper_ggml may not fully support GGUF format yet.');
        }

        // ML packages temporarily disabled for Android build
        // Return mock transcription for APK build testing
        await Future.delayed(Duration(seconds: 2)); // Simulate processing time
        return 'Mock transcription result for APK testing. Audio file: ${audioPath.split('/').last}. Model: ${modelPath.split('/').last}.';
      }
      
    } catch (e) {
      throw Exception('Transcription failed: $e');
    }
  }

  String _getModelFromPath(String modelPath) {
    final fileName = modelPath.split('/').last.toLowerCase();
    
    if (fileName.contains('tiny')) {
      return 'tiny';
    } else if (fileName.contains('base')) {
      return 'base';
    } else if (fileName.contains('small')) {
      return 'small';
    } else if (fileName.contains('medium')) {
      return 'medium';
    } else if (fileName.contains('large')) {
      return 'large';
    }
    
    // Default to tiny if we can't determine the model size
    return 'tiny';
  }

  Future<bool> isModelLoaded() async {
    return _controller != null && _isInitialized && _currentModelPath != null;
  }
  
  bool _isGGUFModel(String modelPath) {
    return modelPath.toLowerCase().endsWith('.gguf');
  }

  bool _isPyTorchModel(String modelPath) {
    final fileName = modelPath.split('/').last.toLowerCase();
    return modelPath.toLowerCase().endsWith('.ptl') || 
           fileName == 'pytorch_model.bin';
  }

  Future<List<String>> getSupportedLanguages() async {
    // Common languages supported by Whisper
    return [
      'auto', 'en', 'zh', 'de', 'es', 'ru', 'ko', 'fr', 'ja', 'pt', 'tr', 'pl',
      'ca', 'nl', 'ar', 'sv', 'it', 'id', 'hi', 'fi', 'vi', 'he', 'uk', 'el',
      'ms', 'cs', 'ro', 'da', 'hu', 'ta', 'no', 'th', 'ur', 'hr', 'bg', 'lt',
      'la', 'mi', 'ml', 'cy', 'sk', 'te', 'fa', 'lv', 'bn', 'sr', 'az', 'sl',
      'kn', 'et', 'mk', 'br', 'eu', 'is', 'hy', 'ne', 'mn', 'bs', 'kk', 'sq',
      'sw', 'gl', 'mr', 'pa', 'si', 'km', 'sn', 'yo', 'so', 'af', 'oc', 'ka',
      'be', 'tg', 'sd', 'gu', 'am', 'yi', 'lo', 'uz', 'fo', 'ht', 'ps', 'tk',
      'nn', 'mt', 'sa', 'lb', 'my', 'bo', 'tl', 'mg', 'as', 'tt', 'haw', 'ln',
      'ha', 'ba', 'jw', 'su'
    ];
  }

  Future<Map<String, dynamic>> getModelInfo() async {
    if (_currentModelPath == null) {
      return {'status': 'No model loaded'};
    }

    final File modelFile = File(_currentModelPath!);
    final int fileSize = await modelFile.length();
    final String model = _getModelFromPath(_currentModelPath!);
    
    return {
      'path': _currentModelPath,
      'size': fileSize,
      'model_type': model,
      'status': _isInitialized ? 'Ready for transcription' : 'Not initialized',
      'framework': 'Mock implementation (ML packages disabled for Android build)',
    };
  }

  void dispose() {
    // Note: WhisperController doesn't have a dispose method in current version
    _controller = null;
    // _pytorchService?.dispose();  // Temporarily disabled for Android build
    // _pytorchService = null;
    _currentModelPath = null;
    _isInitialized = false;
  }
}

// Helper class for audio format validation
class AudioProcessor {
  static Future<bool> isValidAudioFile(String path) async {
    final File file = File(path);
    if (!await file.exists()) return false;
    
    final String extension = path.split('.').last.toLowerCase();
    return ['wav', 'mp3', 'm4a', 'flac'].contains(extension);
  }

  static Future<Map<String, dynamic>> getAudioInfo(String path) async {
    final File file = File(path);
    if (!await file.exists()) {
      throw Exception('Audio file not found');
    }
    
    final int fileSize = await file.length();
    final String extension = path.split('.').last.toLowerCase();
    
    return {
      'path': path,
      'size': fileSize,
      'format': extension,
      'exists': true,
    };
  }
}