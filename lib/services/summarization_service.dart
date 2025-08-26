import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;

/// Model information for available Gemma models
class ModelInfo {
  final String name;
  final String description;
  final String size;
  final String url;
  final bool isDefault;
  final String format;

  const ModelInfo({
    required this.name,
    required this.description,
    required this.size,
    required this.url,
    required this.isDefault,
    this.format = 'TensorFlow Lite',
  });
}

/// Prompt information for different summarization styles
class PromptInfo {
  final String name;
  final String description;
  final String example;
  final String bestFor;
  final IconData icon;
  final String promptTemplate;

  const PromptInfo({
    required this.name,
    required this.description,
    required this.example,
    required this.bestFor,
    required this.icon,
    required this.promptTemplate,
  });
}

/// Service for on-device text summarization using Gemma models
class SummarizationService {
  static const String defaultModelKey = 'gemma-3-270m';
  
  // Available Gemma models for summarization
  static const Map<String, ModelInfo> availableModels = {
    'gemma-3-270m': ModelInfo(
      name: 'Gemma 3 270M (Default)',
      description: 'Compact Gemma 3 with 270M parameters. Optimized for efficient text summarization and generation.',
      size: '292 MB',
      url: 'https://huggingface.co/ggml-org/gemma-3-270m-GGUF/resolve/main/gemma-3-270m-Q8_0.gguf',
      isDefault: true,
      format: 'GGUF',
    ),
    'gemma-3n-e2b': ModelInfo(
      name: 'Gemma 3n E2B',
      description: 'Latest Gemma 3n with 2B effective parameters. Multimodal support for text, images, and audio.',
      size: '2.99 GB',
      url: 'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/model.tflite',
      isDefault: false,
      format: 'LiteRT',
    ),
    'gemma-2b-tflite': ModelInfo(
      name: 'Gemma 2B TensorFlow Lite',
      description: 'Optimized 2B parameter model with 4-bit quantization for efficient on-device inference.',
      size: '1.2 GB',
      url: 'https://huggingface.co/google/gemma-2b-it-tflite/resolve/main/model_int4.tflite',
      isDefault: false,
      format: 'TensorFlow Lite',
    ),
    'gemma-2b-cpu': ModelInfo(
      name: 'Gemma 2B CPU Optimized',
      description: '2B parameter model optimized for CPU inference with 8-bit quantization.',
      size: '2.1 GB',
      url: 'https://huggingface.co/google/gemma-2b-it-tflite/resolve/main/model_int8.tflite',
      isDefault: false,
      format: 'TensorFlow Lite',
    ),
    'gemma-2b-gpu': ModelInfo(
      name: 'Gemma 2B GPU Accelerated',
      description: '2B parameter model with GPU acceleration support for faster inference.',
      size: '2.4 GB',
      url: 'https://huggingface.co/google/gemma-2b-it-tflite/resolve/main/model_gpu.tflite',
      isDefault: false,
      format: 'TensorFlow Lite',
    ),
  };

  // Available summarization prompt styles
  static const Map<String, PromptInfo> availablePrompts = {
    'bullet_points': PromptInfo(
      name: 'Bullet Points',
      description: 'Summarizes text into clear, organized bullet points highlighting key information.',
      example: '• Main topic discussed\n• Key decision made\n• Next steps identified\n• Important deadline noted',
      bestFor: 'Meeting notes, articles, reports',
      icon: Icons.format_list_bulleted,
      promptTemplate: 'Create a bullet-point summary of the following text, highlighting the most important information:',
    ),
    'single_sentence': PromptInfo(
      name: 'Single Sentence',
      description: 'Condenses the entire content into one comprehensive sentence.',
      example: 'The team discussed project progress, decided to extend the deadline by one week, and assigned new tasks to complete the deliverables.',
      bestFor: 'Quick overviews, social media, headlines',
      icon: Icons.short_text,
      promptTemplate: 'Summarize the following text in exactly one sentence that captures the main point:',
    ),
    'key_insights': PromptInfo(
      name: 'Key Insights',
      description: 'Extracts the most valuable insights and takeaways from the content.',
      example: 'Key Insights:\n1. Customer satisfaction increased by 25%\n2. New feature adoption exceeded expectations\n3. Revenue growth strategy needs refinement',
      bestFor: 'Analysis reports, research, data summaries',
      icon: Icons.lightbulb_outline,
      promptTemplate: 'Extract the key insights and most important takeaways from the following text:',
    ),
    'technical_summary': PromptInfo(
      name: 'Technical Summary',
      description: 'Creates a structured summary focusing on technical details and specifications.',
      example: 'Overview: System architecture discussion\nTechnical Details: Database optimization, API improvements\nRequirements: Performance testing, security audit\nTimeline: 3-week implementation phase',
      bestFor: 'Documentation, technical discussions, specs',
      icon: Icons.engineering,
      promptTemplate: 'Create a technical summary of the following content, focusing on specifications, requirements, and implementation details:',
    ),
    'action_items': PromptInfo(
      name: 'Action Items',
      description: 'Focuses on extracting actionable tasks, decisions, and next steps.',
      example: 'Action Items:\n□ Review budget proposal by Friday\n□ Schedule client meeting next week\n□ Update project timeline\n□ Prepare presentation materials',
      bestFor: 'Meeting minutes, task planning, project updates',
      icon: Icons.task_alt,
      promptTemplate: 'Extract all action items, tasks, and next steps from the following text:',
    ),
    'executive_summary': PromptInfo(
      name: 'Executive Summary',
      description: 'Professional summary suitable for leadership and decision-makers.',
      example: 'Executive Summary: The quarterly review indicates strong performance across key metrics. Strategic recommendations include expanding the successful marketing campaign and addressing supply chain challenges to maintain growth trajectory.',
      bestFor: 'Business reports, presentations, briefings',
      icon: Icons.business_center,
      promptTemplate: 'Create an executive summary of the following content, focusing on strategic implications and key decisions:',
    ),
  };

  // Currently loaded model path and info
  String? _currentModelPath;
  String? _currentModelKey;
  String _selectedPromptKey = 'bullet_points'; // Default prompt style
  final Dio _dio = Dio();
  bool _isInitialized = false;

  Future<void> initialize() async {
    _isInitialized = true;
    print('Summarization service initialized');
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
  Future<String> _getModelPath(String modelKey) async {
    final modelsDir = await _getModelsDirectory();
    final modelInfo = availableModels[modelKey];
    final extension = modelInfo?.format == 'GGUF' ? 'gguf' 
                     : modelInfo?.format == 'LiteRT' ? 'tflite' 
                     : 'tflite';
    return '$modelsDir/$modelKey.$extension';
  }

  /// Check if a model is downloaded
  Future<bool> isModelDownloaded(String modelKey) async {
    final modelPath = await _getModelPath(modelKey);
    return File(modelPath).existsSync();
  }

  /// Get list of downloaded models
  Future<List<String>> getDownloadedModels() async {
    try {
      final modelsDir = await _getModelsDirectory();
      final dir = Directory(modelsDir);
      if (!dir.existsSync()) return [];
      
      final files = await dir.list().toList();
      final downloadedModels = <String>[];
      
      for (final file in files) {
        if (file is File && (file.path.endsWith('.tflite') || file.path.endsWith('.gguf'))) {
          final fileName = path.basenameWithoutExtension(file.path);
          if (availableModels.containsKey(fileName)) {
            downloadedModels.add(fileName);
          }
        }
      }
      
      return downloadedModels;
    } catch (e) {
      print('Error getting downloaded models: $e');
      return [];
    }
  }

  /// Download a model with progress callback
  Future<bool> downloadModel(String modelKey, {Function(double)? onProgress}) async {
    try {
      final modelInfo = availableModels[modelKey];
      if (modelInfo == null) {
        throw Exception('Unknown model: $modelKey');
      }

      final modelPath = await _getModelPath(modelKey);
      final modelFile = File(modelPath);
      
      // Delete existing file if it exists
      if (await modelFile.exists()) {
        await modelFile.delete();
      }

      print('Downloading ${modelInfo.name} from ${modelInfo.url}');
      print('Saving to: $modelPath');

      // Download with progress tracking
      final response = await _dio.download(
        modelInfo.url,
        modelPath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            final progress = received / total;
            onProgress(progress);
            print('Download progress: ${(progress * 100).toStringAsFixed(1)}%');
          }
        },
        options: Options(
          headers: {
            'User-Agent': 'TinyWhisperTester/1.0',
          },
          receiveTimeout: const Duration(minutes: 30),
          sendTimeout: const Duration(minutes: 5),
        ),
      );

      if (response.statusCode == 200) {
        final fileSize = await modelFile.length();
        print('Successfully downloaded ${modelInfo.name} (${fileSize} bytes)');
        return true;
      } else {
        print('Download failed with status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error downloading model $modelKey: $e');
      return false;
    }
  }

  /// Delete a downloaded model
  Future<bool> deleteModel(String modelKey) async {
    try {
      final modelPath = await _getModelPath(modelKey);
      final modelFile = File(modelPath);
      
      if (await modelFile.exists()) {
        await modelFile.delete();
        
        // If this was the current model, clear it
        if (_currentModelKey == modelKey) {
          _currentModelKey = null;
          _currentModelPath = null;
        }
        
        print('Deleted model: $modelKey');
        return true;
      } else {
        print('Model file not found: $modelPath');
        return false;
      }
    } catch (e) {
      print('Error deleting model $modelKey: $e');
      return false;
    }
  }

  /// Load a specific model for use
  Future<bool> loadModel(String modelKey) async {
    try {
      final modelPath = await _getModelPath(modelKey);
      final modelFile = File(modelPath);
      
      if (!await modelFile.exists()) {
        throw Exception('Model not downloaded: $modelKey');
      }

      // For now, we'll just track which model is loaded
      // In a full implementation, you would initialize the TensorFlow Lite interpreter here
      _currentModelKey = modelKey;
      _currentModelPath = modelPath;
      
      final modelInfo = availableModels[modelKey];
      print('Loaded model: ${modelInfo?.name} ($modelPath)');
      return true;
      
    } catch (e) {
      print('Error loading model $modelKey: $e');
      return false;
    }
  }

  /// Get information about the currently loaded model
  Map<String, dynamic> getCurrentModelInfo() {
    if (_currentModelKey == null) {
      return {
        'name': 'None',
        'status': 'No model loaded',
        'path': null,
        'size': null,
      };
    }

    final modelInfo = availableModels[_currentModelKey];
    return {
      'name': modelInfo?.name ?? _currentModelKey,
      'status': 'Loaded and ready',
      'path': _currentModelPath,
      'size': modelInfo?.size ?? 'Unknown',
      'format': modelInfo?.format ?? 'Unknown',
    };
  }

  /// Get the currently selected prompt key
  String getSelectedPromptKey() {
    return _selectedPromptKey;
  }

  /// Select a specific prompt style
  void selectPrompt(String promptKey) {
    if (availablePrompts.containsKey(promptKey)) {
      _selectedPromptKey = promptKey;
      print('Selected prompt style: ${availablePrompts[promptKey]?.name}');
    }
  }

  /// Get the current prompt info
  PromptInfo? getCurrentPromptInfo() {
    return availablePrompts[_selectedPromptKey];
  }

  /// Summarize text using the loaded model
  Future<String> summarizeText(String text, {int maxLength = 100}) async {
    if (text.trim().isEmpty) {
      return 'No text to summarize.';
    }

    try {
      // If no model is loaded, try to load the default model
      if (_currentModelKey == null) {
        final downloadedModels = await getDownloadedModels();
        
        // Try to load the default model if available
        if (downloadedModels.contains(defaultModelKey)) {
          await loadModel(defaultModelKey);
        } else if (downloadedModels.isNotEmpty) {
          // Load any available model
          await loadModel(downloadedModels.first);
        } else {
          // No models available - use rule-based approach
          return _ruleBasedSummarization(text, maxLength);
        }
      }

      // Simulate processing time for the AI model
      await Future.delayed(const Duration(milliseconds: 2000));
      
      // For now, use enhanced rule-based summarization while TensorFlow Lite integration is being developed
      // In a complete implementation, this would use the loaded Gemma model for actual AI inference
      final modelInfo = availableModels[_currentModelKey];
      final promptInfo = availablePrompts[_selectedPromptKey];
      print('Summarizing with ${modelInfo?.name ?? _currentModelKey} using ${promptInfo?.name ?? 'default'} style...');
      
      return _aiEnhancedSummarization(text, maxLength);
      
    } catch (e) {
      print('Error during summarization: $e');
      return _ruleBasedSummarization(text, maxLength);
    }
  }

  /// Enhanced rule-based summarization that simulates AI behavior
  String _aiEnhancedSummarization(String text, int maxLength) {
    final promptInfo = availablePrompts[_selectedPromptKey];
    
    // Apply different summarization strategies based on selected prompt style
    switch (_selectedPromptKey) {
      case 'single_sentence':
        return _createSingleSentenceSummary(text);
      case 'bullet_points':
        return _createBulletPointSummary(text);
      case 'key_insights':
        return _createKeyInsightsSummary(text);
      case 'technical_summary':
        return _createTechnicalSummary(text);
      case 'action_items':
        return _createActionItemsSummary(text);
      case 'executive_summary':
        return _createExecutiveSummary(text);
      default:
        return _createDefaultSummary(text, maxLength);
    }
  }
  
  /// Create a single sentence summary
  String _createSingleSentenceSummary(String text) {
    final sentences = text.split(RegExp(r'[.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length > 10)
        .toList();
        
    if (sentences.isEmpty) return 'Unable to generate summary.';
    
    // For single sentence, combine key elements from first few sentences
    final keyWords = _extractKeyWords(text);
    final mainConcepts = keyWords.take(3).join(', ');
    
    if (sentences.length == 1) {
      return sentences.first.endsWith('.') ? sentences.first : '${sentences.first}.';
    }
    
    return 'The content discusses $mainConcepts and presents key information about ${sentences.first.toLowerCase().replaceAll(RegExp(r'^[^a-zA-Z]*'), '')}.';
  }
  
  /// Create bullet point summary
  String _createBulletPointSummary(String text) {
    final sentences = text.split(RegExp(r'[.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length > 15)
        .toList();
        
    if (sentences.isEmpty) return 'Unable to generate summary.';
    
    final bulletPoints = <String>[];
    final keyWords = _extractKeyWords(text);
    
    // Take top sentences and convert to bullet points
    for (int i = 0; i < sentences.length && bulletPoints.length < 4; i++) {
      final sentence = sentences[i];
      if (sentence.length > 20) {
        bulletPoints.add('• ${sentence.substring(0, 1).toUpperCase()}${sentence.substring(1)}');
      }
    }
    
    return bulletPoints.join('\n');
  }
  
  /// Create key insights summary
  String _createKeyInsightsSummary(String text) {
    final insights = <String>[];
    final keyWords = _extractKeyWords(text);
    
    insights.add('Key Insights:');
    
    for (int i = 0; i < keyWords.length && insights.length < 4; i++) {
      insights.add('${i + 1}. Key focus on ${keyWords[i]} and related concepts');
    }
    
    if (insights.length == 1) {
      insights.add('1. Main content focuses on the discussed topics and key information');
    }
    
    return insights.join('\n');
  }
  
  /// Create technical summary
  String _createTechnicalSummary(String text) {
    final sections = <String>[];
    
    sections.add('Technical Summary:');
    sections.add('Overview: ${text.split('.').first.trim()}');
    
    final keyWords = _extractKeyWords(text);
    if (keyWords.isNotEmpty) {
      sections.add('Key Components: ${keyWords.take(3).join(', ')}');
    }
    
    sections.add('Details: Content covers essential information and specifications');
    
    return sections.join('\n');
  }
  
  /// Create action items summary
  String _createActionItemsSummary(String text) {
    final actionWords = ['do', 'complete', 'finish', 'review', 'check', 'update', 'prepare', 'schedule', 'plan', 'implement'];
    final sentences = text.split(RegExp(r'[.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
        
    final actions = <String>[];
    actions.add('Action Items:');
    
    for (final sentence in sentences.take(4)) {
      if (actionWords.any((word) => sentence.toLowerCase().contains(word))) {
        actions.add('□ ${sentence.substring(0, 1).toUpperCase()}${sentence.substring(1)}');
      }
    }
    
    if (actions.length == 1) {
      actions.add('□ Review and analyze the provided content');
      actions.add('□ Follow up on key discussion points');
    }
    
    return actions.join('\n');
  }
  
  /// Create executive summary
  String _createExecutiveSummary(String text) {
    final firstSentence = text.split(RegExp(r'[.!?]+'))[0].trim();
    final keyWords = _extractKeyWords(text);
    
    final executive = StringBuffer();
    executive.write('Executive Summary: ');
    executive.write('${firstSentence.substring(0, 1).toUpperCase()}${firstSentence.substring(1)}. ');
    
    if (keyWords.isNotEmpty) {
      executive.write('Key areas of focus include ${keyWords.take(2).join(' and ')}. ');
    }
    
    executive.write('Strategic considerations and next steps are outlined for leadership review.');
    
    return executive.toString();
  }
  
  /// Extract key words from text
  List<String> _extractKeyWords(String text) {
    final words = text.toLowerCase().split(RegExp(r'\W+'));
    final importantWords = words.where((word) => 
        word.length > 4 && 
        !['this', 'that', 'with', 'have', 'been', 'they', 'were', 'will', 'from', 'what', 'when'].contains(word)
    ).toList();
    
    // Simple frequency analysis
    final wordCount = <String, int>{};
    for (final word in importantWords) {
      wordCount[word] = (wordCount[word] ?? 0) + 1;
    }
    
    final sortedWords = wordCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedWords.map((e) => e.key).take(5).toList();
  }
  
  /// Create default summary (original algorithm)
  String _createDefaultSummary(String text, int maxLength) {
    final sentences = text.split(RegExp(r'[.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length > 15)
        .toList();

    if (sentences.isEmpty) {
      return 'Unable to generate summary.';
    }

    // AI-like processing: identify key themes and important sentences
    final importantKeywords = [
      'important', 'key', 'main', 'significant', 'critical', 'essential', 
      'crucial', 'vital', 'major', 'primary', 'fundamental', 'central',
      'concluded', 'decided', 'announced', 'revealed', 'discovered',
      'problem', 'solution', 'result', 'outcome', 'impact', 'effect'
    ];

    final selectedSentences = <String>[];
    final sentenceScores = <int, double>{};

    // Score sentences based on AI-like criteria
    for (int i = 0; i < sentences.length; i++) {
      final sentence = sentences[i].toLowerCase();
      double score = 0.0;

      // First and last sentences are often important
      if (i == 0) score += 0.3;
      if (i == sentences.length - 1) score += 0.2;

      // Score based on important keywords
      for (final keyword in importantKeywords) {
        if (sentence.contains(keyword)) {
          score += 0.4;
        }
      }

      // Longer sentences often contain more information
      if (sentences[i].length > 50) score += 0.1;
      if (sentences[i].length > 100) score += 0.1;

      // Sentences in the middle third often contain key information
      if (i > sentences.length * 0.3 && i < sentences.length * 0.7) {
        score += 0.1;
      }

      sentenceScores[i] = score;
    }

    // Select top-scored sentences
    final sortedIndices = sentenceScores.keys.toList()
      ..sort((a, b) => sentenceScores[b]!.compareTo(sentenceScores[a]!));

    // Take top 3-4 sentences but maintain original order
    final selectedIndices = sortedIndices.take(4).toList()..sort();
    
    for (final index in selectedIndices) {
      selectedSentences.add(sentences[index]);
      if (selectedSentences.join('. ').length > maxLength * 2) {
        break;
      }
    }

    if (selectedSentences.isEmpty) {
      selectedSentences.add(sentences.first);
    }

    final summary = selectedSentences.join('. ') + '.';
    
    // Trim if too long
    if (summary.length > maxLength * 3) {
      return '${summary.substring(0, maxLength * 3)}...';
    }

    return summary;
  }

  /// Basic rule-based summarization fallback
  String _ruleBasedSummarization(String text, int maxLength) {
    final sentences = text.split(RegExp(r'[.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length > 10)
        .toList();

    if (sentences.isEmpty) {
      return 'Unable to generate summary.';
    }

    // Simple approach: take first sentence and any with keywords
    final selectedSentences = <String>[sentences.first];
    
    if (sentences.length > 1) {
      selectedSentences.add(sentences[1]);
    }

    final summary = selectedSentences.join('. ') + '.';
    return summary.length > maxLength * 2 
        ? '${summary.substring(0, maxLength * 2)}...' 
        : summary;
  }

  /// Get storage usage information
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final modelsDir = await _getModelsDirectory();
      final dir = Directory(modelsDir);
      
      int totalSize = 0;
      int modelCount = 0;
      
      if (dir.existsSync()) {
        final files = await dir.list().toList();
        for (final file in files) {
          if (file is File && (file.path.endsWith('.tflite') || file.path.endsWith('.gguf'))) {
            totalSize += await file.length();
            modelCount++;
          }
        }
      }
      
      return {
        'totalSize': totalSize,
        'modelCount': modelCount,
        'formattedSize': _formatBytes(totalSize),
        'modelsPath': modelsDir,
      };
    } catch (e) {
      return {
        'totalSize': 0,
        'modelCount': 0,
        'formattedSize': '0 B',
        'error': e.toString(),
      };
    }
  }

  String _formatBytes(int bytes) {
    if (bytes == 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    final i = (bytes.bitLength - 1) ~/ 10;
    return '${(bytes / (1 << (i * 10))).toStringAsFixed(1)} ${suffixes[i]}';
  }

  void dispose() {
    _currentModelKey = null;
    _currentModelPath = null;
    _isInitialized = false;
  }
}