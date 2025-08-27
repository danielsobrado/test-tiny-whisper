import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import '../config/app_constants.dart';
import '../utils/app_logger.dart';

/// Service for offline language detection and translation
class TranslationService {
  static const String _defaultTargetLanguage = AppConstants.defaultTargetLanguage;
  
  OnDeviceTranslator? _currentTranslator;
  final LanguageIdentifier _languageIdentifier = LanguageIdentifier(
    confidenceThreshold: AppConstants.languageDetectionConfidenceThreshold
  );
  final OnDeviceTranslatorModelManager _modelManager = OnDeviceTranslatorModelManager();
  
  /// Initialize the translation service
  Future<void> initialize() async {
    // No initialization needed - models are downloaded on demand
  }
  
  /// Detect the language of the given text
  Future<String?> detectLanguage(String text) async {
    try {
      if (text.trim().isEmpty) return null;
      
      final String language = await _languageIdentifier.identifyLanguage(text);
      
      // If detection fails or confidence is too low, return null
      if (language == 'und') { // 'und' means undetermined language
        return null;
      }
      
      return language;
    } catch (e) {
      AppLogger.translationError('Error detecting language', error: e);
      return null;
    }
  }
  
  /// Check if a language model is downloaded
  Future<bool> isModelDownloaded(String languageCode) async {
    try {
      return await _modelManager.isModelDownloaded(languageCode);
    } catch (e) {
      AppLogger.translationError('Error checking if model is downloaded', error: e);
      return false;
    }
  }
  
  /// Download language model for translation
  Future<bool> downloadModel(String languageCode) async {
    try {
      await _modelManager.downloadModel(languageCode);
      return true;
    } catch (e) {
      AppLogger.translationError('Error downloading model for $languageCode', error: e);
      return false;
    }
  }
  
  /// Delete language model
  Future<bool> deleteModel(String languageCode) async {
    try {
      await _modelManager.deleteModel(languageCode);
      return true;
    } catch (e) {
      AppLogger.translationError('Error deleting model for $languageCode', error: e);
      return false;
    }
  }
  
  /// Get list of available languages for translation
  Set<TranslateLanguage> getAvailableLanguages() {
    return TranslateLanguage.values.toSet();
  }
  
  /// Get downloaded model languages
  Future<Set<String>> getDownloadedModels() async {
    try {
      final downloadedModels = <String>{};
      
      // Check some common languages to see which models are downloaded
      final commonLanguages = ['es', 'fr', 'de', 'it', 'pt', 'ru', 'ja', 'ko', 'zh', 'ar', 'hi'];
      
      for (final languageCode in commonLanguages) {
        if (await isModelDownloaded(languageCode)) {
          downloadedModels.add(languageCode);
        }
      }
      
      return downloadedModels;
    } catch (e) {
      AppLogger.translationError('Error getting downloaded models', error: e);
      return {};
    }
  }
  
  /// Translate text from source language to target language
  Future<String?> translateText(String text, String sourceLanguage, String targetLanguage) async {
    try {
      if (text.trim().isEmpty) return null;
      
      // Don't translate if source and target are the same
      if (sourceLanguage == targetLanguage) {
        return text;
      }
      
      // Create or recreate translator if needed
      if (_currentTranslator == null || 
          _currentTranslator!.sourceLanguage.bcpCode != sourceLanguage ||
          _currentTranslator!.targetLanguage.bcpCode != targetLanguage) {
        
        await _currentTranslator?.close();
        
        // Find the TranslateLanguage objects
        final sourceTranslateLanguage = _getTranslateLanguageFromCode(sourceLanguage);
        final targetTranslateLanguage = _getTranslateLanguageFromCode(targetLanguage);
        
        if (sourceTranslateLanguage == null || targetTranslateLanguage == null) {
          AppLogger.translationError('Unsupported language pair: $sourceLanguage -> $targetLanguage');
          return null;
        }
        
        // Ensure models are downloaded
        final sourceDownloaded = await isModelDownloaded(sourceLanguage);
        final targetDownloaded = await isModelDownloaded(targetLanguage);
        
        if (!sourceDownloaded) {
          final downloaded = await downloadModel(sourceLanguage);
          if (!downloaded) {
            AppLogger.translationError('Failed to download source model: $sourceLanguage');
            return null;
          }
        }
        
        if (!targetDownloaded) {
          final downloaded = await downloadModel(targetLanguage);
          if (!downloaded) {
            AppLogger.translationError('Failed to download target model: $targetLanguage');
            return null;
          }
        }
        
        _currentTranslator = OnDeviceTranslator(
          sourceLanguage: sourceTranslateLanguage,
          targetLanguage: targetTranslateLanguage,
        );
      }
      
      final translatedText = await _currentTranslator!.translateText(text);
      return translatedText;
    } catch (e) {
      AppLogger.translationError('Error translating text', error: e);
      return null;
    }
  }
  
  /// Detect language and translate to English if needed
  Future<TranslationResult> detectAndTranslate(String text) async {
    try {
      if (text.trim().isEmpty) {
        return TranslationResult(
          originalText: text,
          detectedLanguage: null,
          translatedText: null,
          needsTranslation: false,
        );
      }
      
      // First check if text contains mostly English words (simple heuristic)
      if (_isLikelyEnglish(text)) {
        return TranslationResult(
          originalText: text,
          detectedLanguage: 'en',
          translatedText: null,
          needsTranslation: false,
        );
      }
      
      // Detect language
      final detectedLanguage = await detectLanguage(text);
      
      // If detection failed, assume English for safety
      if (detectedLanguage == null || detectedLanguage == 'und') {
        return TranslationResult(
          originalText: text,
          detectedLanguage: 'en', // Assume English if uncertain
          translatedText: null,
          needsTranslation: false,
        );
      }
      
      // If text is already in English, no translation needed
      if (detectedLanguage == _defaultTargetLanguage) {
        return TranslationResult(
          originalText: text,
          detectedLanguage: detectedLanguage,
          translatedText: null,
          needsTranslation: false,
        );
      }
      
      // Translate to English
      final translatedText = await translateText(text, detectedLanguage, _defaultTargetLanguage);
      
      return TranslationResult(
        originalText: text,
        detectedLanguage: detectedLanguage,
        translatedText: translatedText,
        needsTranslation: true,
      );
    } catch (e) {
      AppLogger.translationError('Error in detectAndTranslate', error: e);
      // On error, assume English and don't translate
      return TranslationResult(
        originalText: text,
        detectedLanguage: 'en',
        translatedText: null,
        needsTranslation: false,
      );
    }
  }
  
  /// Simple heuristic to check if text is likely English
  bool _isLikelyEnglish(String text) {
    final lowerText = text.toLowerCase();
    
    // Common English words that are good indicators
    final englishIndicators = [
      'the', 'and', 'is', 'are', 'was', 'were', 'a', 'an', 'to', 'of', 'in', 
      'for', 'with', 'on', 'at', 'by', 'from', 'this', 'that', 'these', 'those',
      'i', 'you', 'he', 'she', 'it', 'we', 'they', 'me', 'him', 'her', 'us', 'them',
      'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should',
      'can', 'may', 'might', 'must', 'shall', 'be', 'been', 'being'
    ];
    
    int matches = 0;
    final words = lowerText.split(' ');
    
    for (final word in words) {
      final cleanWord = word.replaceAll(RegExp(r'[^\w]'), '');
      if (englishIndicators.contains(cleanWord)) {
        matches++;
      }
    }
    
    // If more than 30% of words are common English words, assume English
    return matches > 0 && (matches / words.length) > 0.3;
  }
  
  /// Get language name from code
  String getLanguageName(String languageCode) {
    final translateLanguage = _getTranslateLanguageFromCode(languageCode);
    if (translateLanguage == null) return languageCode.toUpperCase();
    
    // Map common language codes to readable names
    const languageNames = {
      'en': 'English',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'it': 'Italian',
      'pt': 'Portuguese',
      'ru': 'Russian',
      'ja': 'Japanese',
      'ko': 'Korean',
      'zh': 'Chinese',
      'ar': 'Arabic',
      'hi': 'Hindi',
      'tr': 'Turkish',
      'pl': 'Polish',
      'nl': 'Dutch',
      'sv': 'Swedish',
      'da': 'Danish',
      'no': 'Norwegian',
      'fi': 'Finnish',
      'cs': 'Czech',
      'sk': 'Slovak',
      'hu': 'Hungarian',
      'ro': 'Romanian',
      'bg': 'Bulgarian',
      'hr': 'Croatian',
      'sl': 'Slovenian',
      'et': 'Estonian',
      'lv': 'Latvian',
      'lt': 'Lithuanian',
      'uk': 'Ukrainian',
      'be': 'Belarusian',
      'ca': 'Catalan',
      'eu': 'Basque',
      'gl': 'Galician',
      'mt': 'Maltese',
      'cy': 'Welsh',
      'ga': 'Irish',
      'is': 'Icelandic',
      'mk': 'Macedonian',
      'sq': 'Albanian',
      'sr': 'Serbian',
      'bs': 'Bosnian',
      'me': 'Montenegrin',
    };
    
    return languageNames[languageCode] ?? languageCode.toUpperCase();
  }
  
  /// Helper method to find TranslateLanguage from BCP code
  TranslateLanguage? _getTranslateLanguageFromCode(String code) {
    try {
      return TranslateLanguage.values.firstWhere(
        (lang) => lang.bcpCode == code,
      );
    } catch (e) {
      return null;
    }
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    await _currentTranslator?.close();
    _languageIdentifier.close();
  }
}

/// Result of language detection and translation operation
class TranslationResult {
  final String originalText;
  final String? detectedLanguage;
  final String? translatedText;
  final bool needsTranslation;
  
  TranslationResult({
    required this.originalText,
    required this.detectedLanguage,
    required this.translatedText,
    required this.needsTranslation,
  });
  
  bool get hasTranslation => translatedText != null && translatedText!.isNotEmpty;
  
  String get displayLanguage {
    if (detectedLanguage == null) return 'Unknown';
    const languageNames = {
      'en': 'English',
      'es': 'Spanish', 
      'fr': 'French',
      'de': 'German',
      'it': 'Italian',
      'pt': 'Portuguese',
      'ru': 'Russian',
      'ja': 'Japanese',
      'ko': 'Korean',
      'zh': 'Chinese',
      'ar': 'Arabic',
      'hi': 'Hindi',
    };
    return languageNames[detectedLanguage!] ?? detectedLanguage!.toUpperCase();
  }
}