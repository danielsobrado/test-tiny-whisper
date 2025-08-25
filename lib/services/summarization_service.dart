import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:dio/dio.dart';

/// Service for on-device text summarization using Gemma models
class SummarizationService {
  static const String defaultModelName = 'gemma-2b-it';
  static const String defaultModelUrl = 'https://huggingface.co/google/gemma-2b-it/resolve/main/model.tflite';
  
  Interpreter? _interpreter;
  String? _currentModelPath;
  final Dio _dio = Dio();
  
  // Available models for download
  static const Map<String, ModelInfo> availableModels = {
    'gemma-2b-it': ModelInfo(
      name: 'Gemma 2B Instruct',
      description: 'Small, fast model for basic summarization',
      size: '2.5 GB',
      url: 'https://huggingface.co/google/gemma-2b-it/resolve/main/model.tflite',
      isDefault: true,
    ),
    'gemma-7b-it': ModelInfo(
      name: 'Gemma 7B Instruct', 
      description: 'Larger model with better quality summaries',
      size: '7.2 GB',
      url: 'https://huggingface.co/google/gemma-7b-it/resolve/main/model.tflite',
      isDefault: false,
    ),
    'gemini-nano': ModelInfo(
      name: 'Gemini Nano',
      description: 'Ultra-efficient model for mobile devices',
      size: '1.8 GB', 
      url: 'https://ai.google.dev/edge/models/gemini-nano.tflite',
      isDefault: false,
    ),
  };

  /// Initialize the summarization service
  Future<void> initialize() async {
    // Check if default model exists, otherwise use placeholder
    final modelPath = await _getModelPath(defaultModelName);
    if (File(modelPath).existsSync()) {
      await _loadModel(modelPath);
    }
  }

  /// Get the models directory path
  Future<String> _getModelsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${appDir.path}/summarization_models');
    if (!modelsDir.existsSync()) {
      await modelsDir.create(recursive: true);
    }
    return modelsDir.path;
  }

  /// Get the path for a specific model
  Future<String> _getModelPath(String modelName) async {
    final modelsDir = await _getModelsDirectory();
    return '$modelsDir/$modelName.tflite';
  }

  /// Check if a model is downloaded
  Future<bool> isModelDownloaded(String modelName) async {
    final modelPath = await _getModelPath(modelName);
    return File(modelPath).existsSync();
  }

  /// Get list of downloaded models
  Future<List<String>> getDownloadedModels() async {
    final modelsDir = await _getModelsDirectory();
    final dir = Directory(modelsDir);
    if (!dir.existsSync()) return [];
    
    final files = await dir.list().toList();
    return files
        .whereType<File>()
        .where((file) => file.path.endsWith('.tflite'))
        .map((file) => file.path.split('/').last.replaceAll('.tflite', ''))
        .toList();
  }

  /// Download a model
  Future<bool> downloadModel(
    String modelName, {
    Function(double)? onProgress,
  }) async {
    try {
      final modelInfo = availableModels[modelName];
      if (modelInfo == null) {
        throw Exception('Unknown model: $modelName');
      }

      final modelPath = await _getModelPath(modelName);
      
      // Check if already downloaded
      if (File(modelPath).existsSync()) {
        return true;
      }

      // Download with progress tracking
      await _dio.download(
        modelInfo.url,
        modelPath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      // Verify download
      if (!File(modelPath).existsSync()) {
        throw Exception('Download failed - file not found');
      }

      return true;
    } catch (e) {
      print('Error downloading model $modelName: $e');
      return false;
    }
  }

  /// Delete a model
  Future<bool> deleteModel(String modelName) async {
    try {
      final modelPath = await _getModelPath(modelName);
      final file = File(modelPath);
      if (file.existsSync()) {
        await file.delete();
        
        // If this was the current model, unload it
        if (_currentModelPath == modelPath) {
          _interpreter?.close();
          _interpreter = null;
          _currentModelPath = null;
        }
      }
      return true;
    } catch (e) {
      print('Error deleting model $modelName: $e');
      return false;
    }
  }

  /// Load a specific model
  Future<bool> loadModel(String modelName) async {
    try {
      final modelPath = await _getModelPath(modelName);
      if (!File(modelPath).existsSync()) {
        throw Exception('Model not found: $modelName');
      }
      
      return await _loadModel(modelPath);
    } catch (e) {
      print('Error loading model $modelName: $e');
      return false;
    }
  }

  /// Internal method to load model from path
  Future<bool> _loadModel(String modelPath) async {
    try {
      // Close existing interpreter
      _interpreter?.close();
      
      // Load new model
      _interpreter = await Interpreter.fromFile(File(modelPath));
      _currentModelPath = modelPath;
      
      return true;
    } catch (e) {
      print('Error loading model from $modelPath: $e');
      return false;
    }
  }

  /// Get current model information
  Map<String, dynamic> getCurrentModelInfo() {
    if (_currentModelPath == null || _interpreter == null) {
      return {
        'name': 'None',
        'status': 'No model loaded',
        'path': null,
      };
    }

    final modelName = _currentModelPath!.split('/').last.replaceAll('.tflite', '');
    final modelInfo = availableModels[modelName];
    
    return {
      'name': modelInfo?.name ?? modelName,
      'status': 'Ready',
      'path': _currentModelPath,
      'description': modelInfo?.description ?? 'Custom model',
      'size': modelInfo?.size ?? 'Unknown',
    };
  }

  /// Summarize text using the loaded model
  Future<String?> summarizeText(String text, {
    int maxLength = 100,
    double temperature = 0.7,
  }) async {
    if (_interpreter == null) {
      // Try to load default model if none is loaded
      final defaultModelPath = await _getModelPath(defaultModelName);
      if (File(defaultModelPath).existsSync()) {
        await _loadModel(defaultModelPath);
      } else {
        throw Exception('No model loaded. Please download a model first.');
      }
    }

    try {
      // This is a simplified implementation
      // Real Gemma models would require proper tokenization and post-processing
      
      // For now, return a mock summary while the TensorFlow Lite implementation
      // is being developed. In a real implementation, this would:
      // 1. Tokenize the input text
      // 2. Run inference through the model
      // 3. Decode the output tokens back to text
      
      await Future.delayed(const Duration(milliseconds: 1500)); // Simulate processing time
      
      return _generateMockSummary(text, maxLength);
    } catch (e) {
      print('Error during summarization: $e');
      return null;
    }
  }

  /// Generate a mock summary for demonstration purposes
  /// TODO: Replace with actual TensorFlow Lite inference
  String _generateMockSummary(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    
    // Simple extractive summarization as placeholder
    final sentences = text.split(RegExp(r'[.!?]+'));
    final nonEmptySentences = sentences.where((s) => s.trim().isNotEmpty).toList();
    
    if (nonEmptySentences.isEmpty) {
      return text.substring(0, maxLength.clamp(0, text.length));
    }
    
    // Take first and potentially middle sentences
    String summary = nonEmptySentences.first.trim();
    
    if (nonEmptySentences.length > 2 && summary.length < maxLength * 0.7) {
      final middleIndex = nonEmptySentences.length ~/ 2;
      final middleSentence = nonEmptySentences[middleIndex].trim();
      if (summary.length + middleSentence.length + 2 <= maxLength) {
        summary += '. $middleSentence';
      }
    }
    
    if (!summary.endsWith('.') && !summary.endsWith('!') && !summary.endsWith('?')) {
      summary += '.';
    }
    
    return summary;
  }

  /// Dispose resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _currentModelPath = null;
  }
}

/// Model information class
class ModelInfo {
  final String name;
  final String description;
  final String size;
  final String url;
  final bool isDefault;

  const ModelInfo({
    required this.name,
    required this.description,
    required this.size,
    required this.url,
    required this.isDefault,
  });
}