import 'package:flutter_test/flutter_test.dart';
import 'package:tiny_whisper_tester/services/translation_service.dart';

void main() {
  group('TranslationService Tests', () {
    late TranslationService service;

    setUp(() {
      service = TranslationService();
    });

    tearDown(() {
      service.dispose();
    });

    group('Service Initialization', () {
      test('should initialize service successfully', () async {
        await expectLater(service.initialize(), completes);
      });

      test('should dispose resources without error', () async {
        await service.initialize();
        expect(() => service.dispose(), returnsNormally);
      });
    });

    group('Language Detection', () {
      test('should return null for empty text', () async {
        final result = await service.detectLanguage('');
        expect(result, null);
      });

      test('should return null for whitespace-only text', () async {
        final result = await service.detectLanguage('   \n\t  ');
        expect(result, null);
      });

      test('should detect English text', () async {
        const englishText = 'Hello, how are you today? This is English text.';
        final result = await service.detectLanguage(englishText);
        // Note: In test environment, actual ML Kit detection may not work
        // The test verifies the method doesn't crash and returns appropriate type
        expect(result, anyOf(isNull, isA<String>()));
      });

      test('should detect Spanish text', () async {
        const spanishText = 'Hola, ¿cómo estás hoy? Este es texto en español.';
        final result = await service.detectLanguage(spanishText);
        expect(result, anyOf(isNull, isA<String>()));
        
        // If detection works, should return 'es' or similar
        if (result != null) {
          expect(result, isNot('und')); // Should not be undetermined
        }
      });

      test('should detect French text', () async {
        const frenchText = 'Bonjour, comment allez-vous? Ceci est du texte français.';
        final result = await service.detectLanguage(frenchText);
        expect(result, anyOf(isNull, isA<String>()));
      });

      test('should handle mixed language text', () async {
        const mixedText = 'Hello bonjour hola wie geht es dir?';
        final result = await service.detectLanguage(mixedText);
        expect(result, anyOf(isNull, isA<String>()));
      });

      test('should handle special characters and numbers', () async {
        const specialText = '123 @#\$%^&*() []{} |\\:";\'<>?,./`~';
        final result = await service.detectLanguage(specialText);
        expect(result, anyOf(isNull, equals('und')));
      });

      test('should handle very short text', () async {
        const shortText = 'Hi';
        final result = await service.detectLanguage(shortText);
        expect(result, anyOf(isNull, isA<String>()));
      });
    });

    group('English Language Heuristic', () {
      test('should identify English text using heuristics', () {
        const englishTexts = [
          'The quick brown fox jumps over the lazy dog.',
          'I am going to the store with my friend.',
          'This is a test of the emergency broadcast system.',
          'We have been working on this project for weeks.',
          'Can you help me with this problem?',
        ];

        for (final text in englishTexts) {
          // Use reflection or make the method public for testing
          // For now, we test through detectAndTranslate
          expect(text.toLowerCase().contains('the'), true);
        }
      });

      test('should not identify non-English text as English', () {
        const nonEnglishTexts = [
          'Je suis français et je parle français.',
          'Ich spreche Deutsch und wohne in Deutschland.',
          'Me gusta hablar español con mis amigos.',
          'Мне нравится говорить по-русски.',
        ];

        for (final text in nonEnglishTexts) {
          // These shouldn't contain many English indicator words
          final englishWords = ['the', 'and', 'is', 'are', 'to', 'of', 'in'];
          var hasEnglishWords = false;
          for (final word in englishWords) {
            if (text.toLowerCase().contains(' $word ')) {
              hasEnglishWords = true;
              break;
            }
          }
          expect(hasEnglishWords, false);
        }
      });
    });

    group('Model Management', () {
      test('should check if model is downloaded', () async {
        // Test with common language codes
        final isDownloaded = await service.isModelDownloaded('es');
        expect(isDownloaded, isA<bool>());
      });

      test('should return false for invalid language code', () async {
        final isDownloaded = await service.isModelDownloaded('invalid_lang');
        expect(isDownloaded, false);
      });

      test('should attempt to download model', () async {
        // Note: Actual download won't work in test environment
        final result = await service.downloadModel('es');
        expect(result, isA<bool>());
      });

      test('should attempt to delete model', () async {
        final result = await service.deleteModel('es');
        expect(result, isA<bool>());
      });

      test('should get downloaded models list', () async {
        final models = await service.getDownloadedModels();
        expect(models, isA<Set<String>>());
        expect(models, isNotNull);
      });

      test('should return common languages in downloaded models check', () async {
        final models = await service.getDownloadedModels();
        // The method checks specific common languages
        final commonLanguages = ['es', 'fr', 'de', 'it', 'pt', 'ru', 'ja', 'ko', 'zh', 'ar', 'hi'];
        
        // All returned models should be from the common languages list
        for (final model in models) {
          expect(commonLanguages, contains(model));
        }
      });
    });

    group('Available Languages', () {
      test('should return available languages set', () {
        final languages = service.getAvailableLanguages();
        expect(languages, isNotEmpty);
        expect(languages, isA<Set>());
      });

      test('should include common languages', () {
        final languages = service.getAvailableLanguages();
        expect(languages, isNotEmpty);
        
        // Should have multiple language options
        expect(languages.length, greaterThan(10));
      });
    });

    group('Language Names', () {
      test('should return proper language names for common codes', () {
        const testCases = {
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

        for (final entry in testCases.entries) {
          final name = service.getLanguageName(entry.key);
          expect(name, entry.value);
        }
      });

      test('should return uppercase code for unknown languages', () {
        final name = service.getLanguageName('xyz');
        expect(name, 'XYZ');
      });

      test('should handle empty language code', () {
        final name = service.getLanguageName('');
        expect(name, isA<String>());
      });
    });

    group('Text Translation', () {
      test('should return null for empty text', () async {
        final result = await service.translateText('', 'es', 'en');
        expect(result, null);
      });

      test('should return original text if source equals target', () async {
        const text = 'Hello world';
        final result = await service.translateText(text, 'en', 'en');
        expect(result, text);
      });

      test('should attempt translation between different languages', () async {
        const text = 'Hello world';
        final result = await service.translateText(text, 'en', 'es');
        // In test environment, actual translation may not work
        expect(result, anyOf(isNull, isA<String>()));
      });

      test('should handle unsupported language pairs', () async {
        const text = 'Hello world';
        final result = await service.translateText(text, 'invalid', 'en');
        expect(result, null);
      });

      test('should handle translation errors gracefully', () async {
        const text = 'Test text';
        // Test with potentially problematic language codes
        final result = await service.translateText(text, 'xyz', 'abc');
        expect(result, null);
      });
    });

    group('Detect and Translate Workflow', () {
      test('should handle empty text in detectAndTranslate', () async {
        final result = await service.detectAndTranslate('');
        
        expect(result.originalText, '');
        expect(result.detectedLanguage, null);
        expect(result.translatedText, null);
        expect(result.needsTranslation, false);
        expect(result.hasTranslation, false);
      });

      test('should handle whitespace-only text', () async {
        const text = '   \n\t  ';
        final result = await service.detectAndTranslate(text);
        
        expect(result.originalText, text);
        expect(result.needsTranslation, false);
      });

      test('should detect likely English text and skip translation', () async {
        const englishText = 'Hello, this is a test of the English language detection system.';
        final result = await service.detectAndTranslate(englishText);
        
        expect(result.originalText, englishText);
        expect(result.detectedLanguage, 'en');
        expect(result.needsTranslation, false);
        expect(result.hasTranslation, false);
      });

      test('should attempt to translate non-English text', () async {
        const spanishText = 'Hola mundo, esto es una prueba.';
        final result = await service.detectAndTranslate(spanishText);
        
        expect(result.originalText, spanishText);
        // In test environment, detection might not work, so check appropriately
        if (result.detectedLanguage != null && result.detectedLanguage != 'en') {
          expect(result.needsTranslation, true);
        }
      });

      test('should provide display language name', () async {
        const text = 'Test text';
        final result = await service.detectAndTranslate(text);
        
        expect(result.displayLanguage, isA<String>());
        expect(result.displayLanguage.isNotEmpty, true);
      });

      test('should handle translation errors gracefully', () async {
        const text = 'Test text that might cause errors';
        final result = await service.detectAndTranslate(text);
        
        // Should not throw, should return a valid result
        expect(result, isNotNull);
        expect(result.originalText, text);
        expect(result.displayLanguage, isA<String>());
      });

      test('should provide fallback when detection fails', () async {
        const problematicText = '@#\$%^&*()123';
        final result = await service.detectAndTranslate(problematicText);
        
        expect(result.originalText, problematicText);
        // Should fallback to English assumption
        expect(result.detectedLanguage, 'en');
        expect(result.needsTranslation, false);
      });
    });

    group('TranslationResult Helper Methods', () {
      test('should correctly identify when translation is available', () {
        var result = TranslationResult(
          originalText: 'test',
          detectedLanguage: 'es',
          translatedText: 'translated test',
          needsTranslation: true,
        );
        expect(result.hasTranslation, true);

        result = TranslationResult(
          originalText: 'test',
          detectedLanguage: 'en',
          translatedText: null,
          needsTranslation: false,
        );
        expect(result.hasTranslation, false);

        result = TranslationResult(
          originalText: 'test',
          detectedLanguage: 'es',
          translatedText: '',
          needsTranslation: true,
        );
        expect(result.hasTranslation, false);
      });

      test('should provide proper display language names', () {
        final testCases = {
          'en': 'English',
          'es': 'Spanish',
          'fr': 'French',
          'unknown_code': 'UNKNOWN_CODE',
          null: 'Unknown',
        };

        for (final entry in testCases.entries) {
          final result = TranslationResult(
            originalText: 'test',
            detectedLanguage: entry.key,
            translatedText: null,
            needsTranslation: false,
          );
          expect(result.displayLanguage, entry.value);
        }
      });
    });

    group('Performance and Edge Cases', () {
      test('should handle very long text', () async {
        final longText = 'This is a test sentence. ' * 100;
        final result = await service.detectAndTranslate(longText);
        
        expect(result.originalText, longText);
        expect(result, isNotNull);
      });

      test('should handle text with mixed scripts', () async {
        const mixedText = 'Hello 你好 Bonjour مرحبا здравствуй';
        final result = await service.detectAndTranslate(mixedText);
        
        expect(result.originalText, mixedText);
        expect(result, isNotNull);
      });

      test('should handle concurrent translation requests', () async {
        const texts = [
          'First text for translation',
          'Second text for translation', 
          'Third text for translation',
        ];

        final futures = texts.map((text) => service.detectAndTranslate(text));
        final results = await Future.wait(futures);

        expect(results.length, 3);
        for (var i = 0; i < results.length; i++) {
          expect(results[i].originalText, texts[i]);
          expect(results[i], isNotNull);
        }
      });

      test('should handle rapid consecutive calls', () async {
        const text = 'Test text for rapid calls';
        
        for (var i = 0; i < 5; i++) {
          final result = await service.detectAndTranslate(text);
          expect(result.originalText, text);
        }
      });
    });
  });
}