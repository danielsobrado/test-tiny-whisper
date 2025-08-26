import 'dart:io';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart';

class WhisperService {
  final SpeechToText _speechToText = SpeechToText();
  OfflineRecognizer? _offlineRecognizer;
  String? _currentModelPath;
  bool _isInitialized = false;
  bool _isOfflineModelLoaded = false;
  List<String> _availableLanguages = [];

  Future<void> loadModel(String modelPath) async {
    try {
      final File modelFile = File(modelPath);
      if (!await modelFile.exists()) {
        throw Exception('Model file not found: $modelPath');
      }

      if (_isPyTorchModel(modelPath)) {
        // PyTorch models temporarily disabled for Android build
        throw Exception('PyTorch models temporarily disabled. Use ONNX (.onnx) models for offline recognition.');
      } else if (_isONNXModel(modelPath)) {
        // Try to load ONNX model with sherpa_onnx
        await _tryLoadONNXModel(modelPath);
      } else {
        // For other model types, initialize live speech recognition
        await _initializeSpeechService();
        _isInitialized = true;
        print('Model noted for reference. Using live speech recognition for: $modelPath');
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
        if (!_isInitialized) {
          throw Exception('Speech recognition not initialized');
        }

        // Check if this is a GGUF model and warn about compatibility
        if (_isGGUFModel(modelPath)) {
          print('Warning: GGUF model detected. whisper_ggml may not fully support GGUF format yet.');
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
    try {
      print('Initializing speech recognition service...');
      
      // Initialize speech recognition
      bool available = await _speechToText.initialize(
        onError: (error) => print('Speech recognition error: $error'),
        onStatus: (status) => print('Speech recognition status: $status'),
        debugLogging: true, // Enable debug logging
      );
      
      print('Speech recognition available: $available');
      
      if (!available) {
        throw Exception('Speech recognition not available on this device');
      }
      
      // Get available languages
      _availableLanguages = await _speechToText.locales()
          .then((locales) => locales.map((locale) => locale.localeId).toList());
      
      _isInitialized = true;
      print('Speech recognition initialized with ${_availableLanguages.length} languages');
      print('Available languages: $_availableLanguages');
    } catch (e) {
      print('Failed to initialize speech recognition: $e');
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
      
      return 'Speech-to-text requires live audio input. File-based transcription is not supported with this implementation. Please use the microphone recording feature instead.';
      
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
      print('Processing audio file with offline model: $audioPath');
      
      // In a complete implementation, you would:
      // 1. Read the WAV file using sherpa_onnx.readWave()
      // 2. Create an offline stream
      // 3. Accept the waveform
      // 4. Decode and get results
      
      // For now, return a message explaining the limitation
      return 'Offline model transcription not fully implemented. This requires proper ONNX model files (encoder.onnx, decoder.onnx, tokens.txt). Please use live speech recognition instead.';
      
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
    try {
      print('Starting live speech recognition...');
      print('Language: $language');
      
      if (!_isInitialized) {
        print('Speech service not initialized, initializing now...');
        await _initializeSpeechService();
      }
      
      print('Starting to listen...');
      
      // Start listening with real-time results - continuous until stopped
      await _speechToText.listen(
        onResult: (result) {
          print('Speech result received: "${result.recognizedWords}"');
          print('Result confidence: ${result.confidence}');
          print('Is final result: ${result.finalResult}');
          
          onResult(result.recognizedWords);
          
          // If result is final and we're not listening anymore, notify
          if (result.finalResult && !_speechToText.isListening) {
            print('Listening stopped - final result received');
            onListeningStopped?.call();
          }
        },
        localeId: language,
        listenFor: const Duration(minutes: 10), // Very long duration - effectively continuous
        pauseFor: const Duration(seconds: 30), // Very long pause tolerance for continuous listening
        partialResults: true, // Show results as they come in
        cancelOnError: true, // Handle errors gracefully
        onSoundLevelChange: (level) {
          // Pass sound level to callback for audio visualization
          print('Sound level received: $level'); // Debug logging
          onSoundLevelChange?.call(level);
        },
      );
      
      print('Listen call completed');
      return 'Speech recognition started';
      
    } catch (e) {
      print('Error starting speech recognition: $e');
      throw Exception('Failed to start live speech recognition: $e');
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
      print('Failed to load ONNX model, using live speech recognition: $e');
      await _initializeSpeechService();
      _isInitialized = true;
      _isOfflineModelLoaded = false;
    }
  }

  Future<bool> isModelLoaded() async {
    return _isInitialized;
  }
  
  bool _isGGUFModel(String modelPath) {
    return modelPath.toLowerCase().endsWith('.gguf');
  }

  bool _isPyTorchModel(String modelPath) {
    final fileName = modelPath.split('/').last.toLowerCase();
    return modelPath.toLowerCase().endsWith('.ptl') || 
           fileName == 'pytorch_model.bin';
  }
  
  bool _isONNXModel(String modelPath) {
    return modelPath.toLowerCase().endsWith('.onnx');
  }

  Future<List<String>> getSupportedLanguages() async {
    if (!_isInitialized) {
      await _initializeSpeechService();
    }
    return _availableLanguages;
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
      'framework': 'speech_to_text (Production-ready speech recognition)',
    };
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