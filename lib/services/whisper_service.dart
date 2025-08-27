import 'dart:io';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart';
import '../config/app_constants.dart';
import '../utils/app_logger.dart';

class WhisperService {
  final SpeechToText _speechToText = SpeechToText();
  OfflineRecognizer? _offlineRecognizer;
  String? _currentModelPath;
  bool _isInitialized = false;
  bool _isOfflineModelLoaded = false;
  List<String> _availableLanguages = [];

  Future<void> loadModel(String modelPath) async {
    AppLogger.logMethodEntry('WhisperService', 'loadModel', parameters: {'modelPath': modelPath});
    
    try {
      final File modelFile = File(modelPath);
      if (!await modelFile.exists()) {
        final error = '${AppConstants.ErrorMessages.modelNotFound}: $modelPath';
        AppLogger.modelError(error);
        throw Exception(error);
      }

      if (_isPyTorchModel(modelPath)) {
        final error = AppConstants.ErrorMessages.pytorchDisabled;
        AppLogger.modelError(error);
        throw Exception(error);
      } else if (_isONNXModel(modelPath)) {
        AppLogger.modelInfo('Attempting to load ONNX model: $modelPath');
        await _tryLoadONNXModel(modelPath);
      } else {
        AppLogger.modelInfo('Loading model as reference for live speech recognition: $modelPath');
        await _initializeSpeechService();
        _isInitialized = true;
        AppLogger.modelInfo('Model noted for reference. Using live speech recognition for: $modelPath');
      }
      
      _currentModelPath = modelPath;
      AppLogger.logMethodExit('WhisperService', 'loadModel', result: 'Success');
      
    } catch (e) {
      AppLogger.modelError('Failed to load model', error: e);
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
        final error = AppConstants.ErrorMessages.pytorchDisabled.replaceAll('ONNX (.onnx)', 'GGML (.bin) or GGUF (.gguf)');
        AppLogger.modelError(error);
        throw Exception(error);
      } else {
        if (!_isInitialized) {
          final error = 'Speech recognition not initialized';
          AppLogger.speechError(error);
          throw Exception(error);
        }

        if (_isGGUFModel(modelPath)) {
          AppLogger.modelWarning('GGUF model detected. whisper_ggml may not fully support GGUF format yet.');
        }

        // Use appropriate transcription method based on model type
        if (_isOfflineModelLoaded && _offlineRecognizer != null) {
          return await _transcribeWithOfflineModel(audioPath, language);
        } else {
          return await _transcribeWithSpeechToText(audioPath, language);
        }
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

  Future<void> _initializeSpeechService() async {
    AppLogger.logMethodEntry('WhisperService', '_initializeSpeechService');
    
    try {
      AppLogger.speechInfo('Initializing speech recognition service...');
      
      final stopwatch = Stopwatch()..start();
      
      bool available = await _speechToText.initialize(
        onError: (error) => AppLogger.speechError('Speech recognition error: $error'),
        onStatus: (status) => AppLogger.speechInfo('Speech recognition status: $status'),
        debugLogging: AppConstants.Logging.enableDebugLogs,
      );
      
      stopwatch.stop();
      AppLogger.performanceInfo('Speech recognition initialization', stopwatch.elapsed);
      
      AppLogger.speechInfo('Speech recognition available: $available');
      
      if (!available) {
        final error = 'Speech recognition not available on this device';
        AppLogger.speechError(error);
        throw Exception(error);
      }
      
      // Get available languages
      _availableLanguages = await _speechToText.locales()
          .then((locales) => locales.map((locale) => locale.localeId).toList());
      
      _isInitialized = true;
      AppLogger.speechInfo('Speech recognition initialized with ${_availableLanguages.length} languages');
      AppLogger.speechInfo('Available languages: $_availableLanguages');
      AppLogger.logMethodExit('WhisperService', '_initializeSpeechService', result: 'Success');
    } catch (e) {
      AppLogger.speechError('Failed to initialize speech recognition', error: e);
      throw Exception('Failed to initialize speech recognition: $e');
    }
  }

  Future<String> _transcribeWithSpeechToText(String audioPath, String? language) async {
    try {
      if (!_isInitialized) {
        throw Exception('Speech recognition not initialized');
      }

      // Note: speech_to_text works with live audio input, not audio files
      // For file-based transcription, we'll need a different approach
      // This is a limitation of the current implementation
      
      return AppConstants.ErrorMessages.fileTranscriptionNotSupported;
      
    } catch (e) {
      throw Exception('Transcription failed: $e');
    }
  }

  Future<String> _transcribeWithOfflineModel(String audioPath, String? language) async {
    try {
      if (_offlineRecognizer == null) {
        throw Exception('Offline recognizer not initialized');
      }

      // Read and process audio file with sherpa_onnx
      // This is a placeholder implementation
      
      AppLogger.modelInfo('Processing audio file with offline model: $audioPath');
      
      // In a complete implementation, you would:
      // 1. Read the WAV file using sherpa_onnx.readWave()
      // 2. Create an offline stream
      // 3. Accept the waveform
      // 4. Decode and get results
      
      // For now, return a message explaining the limitation
      return AppConstants.ErrorMessages.offlineTranscriptionNotImplemented;
      
    } catch (e) {
      throw Exception('Offline transcription failed: $e');
    }
  }

  Future<String> startLiveSpeechRecognition({
    String? language,
    required Function(String) onResult,
    Function(double)? onSoundLevelChange,
    Function()? onListeningStopped,
  }) async {
    AppLogger.logMethodEntry('WhisperService', 'startLiveSpeechRecognition', parameters: {'language': language});
    
    try {
      AppLogger.speechInfo('Starting live speech recognition...');
      AppLogger.speechInfo('Language: ${language ?? 'auto-detect'}');
      
      if (!_isInitialized) {
        AppLogger.speechInfo('Speech service not initialized, initializing now...');
        await _initializeSpeechService();
      }
      
      AppLogger.speechInfo('Starting to listen...');
      
      // Start listening with real-time results - continuous until stopped
      await _speechToText.listen(
        onResult: (result) {
          AppLogger.speechInfo('Speech result received: "${result.recognizedWords}"');
          AppLogger.speechInfo('Result confidence: ${result.confidence}');
          AppLogger.speechInfo('Is final result: ${result.finalResult}');
          
          onResult(result.recognizedWords);
          
          // If result is final and we're not listening anymore, notify
          if (result.finalResult && !_speechToText.isListening) {
            AppLogger.speechInfo('Listening stopped - final result received');
            onListeningStopped?.call();
          }
        },
        localeId: language,
        listenFor: AppConstants.speechListenDuration,
        pauseFor: AppConstants.speechPauseDuration,
        partialResults: true, // Show results as they come in
        cancelOnError: true, // Handle errors gracefully
        onSoundLevelChange: (level) {
          // Pass sound level to callback for audio visualization
          if (AppConstants.Logging.enableSpeechLogs) {
            AppLogger.speechInfo('Sound level received: $level');
          }
          onSoundLevelChange?.call(level);
        },
      );
      
      AppLogger.speechInfo('Listen call completed');
      AppLogger.logMethodExit('WhisperService', 'startLiveSpeechRecognition', result: 'Success');
      return AppConstants.SuccessMessages.speechRecognitionStarted;
      
    } catch (e) {
      AppLogger.speechError('Error starting speech recognition', error: e);
      throw Exception('${AppConstants.ErrorMessages.speechRecognitionFailed}: $e');
    }
  }

  Future<void> stopLiveSpeechRecognition() async {
    try {
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
    } catch (e) {
      throw Exception('Failed to stop speech recognition: $e');
    }
  }

  bool isListening() {
    return _speechToText.isListening;
  }

  Future<void> _tryLoadONNXModel(String modelPath) async {
    try {
      // For ONNX models, we need to implement proper sherpa_onnx loading
      // This is a simplified implementation that explains the requirements
      print('Attempting to load ONNX model: $modelPath');
      
      // sherpa_onnx requires multiple files for Whisper models:
      // - encoder.onnx, decoder.onnx, tokens.txt
      // For now, we'll fall back to live speech recognition
      await _initializeSpeechService();
      _isInitialized = true;
      _isOfflineModelLoaded = false; // Mark as not truly offline yet
      
      throw Exception('ONNX model loading not fully implemented. ONNX models require encoder.onnx, decoder.onnx, and tokens.txt files. Falling back to live speech recognition.');
      
    } catch (e) {
      AppLogger.modelError('Failed to load ONNX model, using live speech recognition', error: e);
      await _initializeSpeechService();
      _isInitialized = true;
      _isOfflineModelLoaded = false;
    }
  }

  Future<bool> isModelLoaded() async {
    return _isInitialized;
  }
  
  bool _isGGUFModel(String modelPath) {
    return modelPath.toLowerCase().endsWith(AppConstants.ggufExtension);
  }

  bool _isPyTorchModel(String modelPath) {
    final fileName = modelPath.split('/').last.toLowerCase();
    return modelPath.toLowerCase().endsWith(AppConstants.pytorchExtension) || 
           fileName == AppConstants.pytorchModelFileName;
  }
  
  bool _isONNXModel(String modelPath) {
    return modelPath.toLowerCase().endsWith(AppConstants.onnxExtension);
  }

  Future<List<String>> getSupportedLanguages() async {
    if (!_isInitialized) {
      await _initializeSpeechService();
    }
    return _availableLanguages;
  }

  Future<Map<String, dynamic>> getModelInfo() async {
    if (_currentModelPath == null) {
      return {
        'status': AppConstants.StatusMessages.noModelLoaded,
        'framework': AppConstants.StatusMessages.deviceSpeechRecognition,
        'offline_model_status': AppConstants.StatusMessages.noOfflineModelSelected
      };
    }

    final File modelFile = File(_currentModelPath!);
    final bool fileExists = await modelFile.exists();
    final int fileSize = fileExists ? await modelFile.length() : 0;
    final String model = _getModelFromPath(_currentModelPath!);
    final String modelFormat = _getModelFormat(_currentModelPath!);
    
    // Determine actual status
    String actualFramework;
    String offlineStatus;
    String mainStatus;
    
    if (!fileExists) {
      actualFramework = AppConstants.StatusMessages.modelFileNotFound;
      offlineStatus = AppConstants.StatusMessages.selectedModelNotExists;
      mainStatus = AppConstants.StatusMessages.modelMissingFallback;
    } else if (_isOfflineModelLoaded && _offlineRecognizer != null) {
      actualFramework = AppConstants.StatusMessages.offlineModelActive;
      offlineStatus = AppConstants.StatusMessages.offlineModelLoaded;
      mainStatus = AppConstants.StatusMessages.usingOfflineModel;
    } else {
      // This is the current reality - model selected but not used
      actualFramework = AppConstants.StatusMessages.deviceFallbackNotImplemented;
      offlineStatus = AppConstants.StatusMessages.selectedModelNotUsed;
      mainStatus = AppConstants.StatusMessages.modelSelectedDeviceFallback;
    }
    
    return {
      'path': _currentModelPath,
      'size': fileSize,
      'model_type': model,
      'model_format': modelFormat,
      'status': mainStatus,
      'framework': actualFramework,
      'offline_model_status': offlineStatus,
      'is_offline_active': _isOfflineModelLoaded,
      'file_exists': fileExists,
    };
  }

  String _getModelFormat(String modelPath) {
    final String extension = modelPath.split('.').last.toLowerCase();
    switch (extension) {
      case 'onnx':
        return 'ONNX';
      case 'gguf':
        return 'GGUF';
      case 'bin':
        return 'GGML';
      case 'ptl':
        return 'PyTorch';
      case 'tflite':
        return 'TensorFlow Lite';
      default:
        return 'Unknown';
    }
  }

  void dispose() {
    _speechToText.stop();
    _offlineRecognizer?.free();
    _offlineRecognizer = null;
    _currentModelPath = null;
    _isInitialized = false;
    _isOfflineModelLoaded = false;
    _availableLanguages.clear();
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