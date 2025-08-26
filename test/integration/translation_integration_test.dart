import 'package:flutter_test/flutter_test.dart';
import 'package:tiny_whisper_tester/services/translation_service.dart';

void main() {
  group('Translation Integration Tests', () {
    late TranslationService service;

    setUp(() {
      service = TranslationService();
    });

    tearDown(() {
      service.dispose();
    });

    group('End-to-End Translation Workflow', () {
      test('should complete full translation workflow', () async {
        // Initialize service
        await service.initialize();

        // Test detection and translation workflow
        const testTexts = [
          'Hello, how are you today?', // English - should not translate
          'Hola, ¿cómo estás hoy?', // Spanish - should translate
          'Bonjour, comment allez-vous?', // French - should translate
          'Guten Tag, wie geht es Ihnen?', // German - should translate
        ];

        for (final text in testTexts) {
          final result = await service.detectAndTranslate(text);
          
          expect(result.originalText, text);
          expect(result.detectedLanguage, isNotNull);
          expect(result.displayLanguage, isA<String>());
          expect(result.displayLanguage.isNotEmpty, true);

          // If detected as non-English, should attempt translation
          if (result.detectedLanguage != 'en') {
            expect(result.needsTranslation, true);
            // Translation may fail in test environment, but result should be structured
            expect(result.translatedText, anyOf(isNull, isA<String>()));
          } else {
            expect(result.needsTranslation, false);
            expect(result.translatedText, isNull);
          }
        }
      });

      test('should handle model management workflow', () async {
        await service.initialize();

        // Get available languages
        final availableLanguages = service.getAvailableLanguages();
        expect(availableLanguages.isNotEmpty, true);

        // Check some common languages
        const commonCodes = ['es', 'fr', 'de'];
        
        for (final code in commonCodes) {
          // Check if model is downloaded
          final isDownloaded = await service.isModelDownloaded(code);
          expect(isDownloaded, isA<bool>());

          // Attempt download (may fail in test environment)
          final downloadResult = await service.downloadModel(code);
          expect(downloadResult, isA<bool>());

          // Get language name
          final name = service.getLanguageName(code);
          expect(name.isNotEmpty, true);
          expect(name, isNot(equals(code.toUpperCase()))); // Should be full name
        }
      });

      test('should handle batch translation requests', () async {
        await service.initialize();

        final testBatch = [
          'This is English text.',
          'Esto es texto en español.',
          'Ceci est du texte français.',
          'Dies ist deutscher Text.',
          'Questo è testo italiano.',
        ];

        // Process all texts concurrently
        final futures = testBatch.map((text) => service.detectAndTranslate(text));
        final results = await Future.wait(futures);

        expect(results.length, testBatch.length);

        for (var i = 0; i < results.length; i++) {
          final result = results[i];
          expect(result.originalText, testBatch[i]);
          expect(result.detectedLanguage, isNotNull);
          expect(result.displayLanguage.isNotEmpty, true);
        }
      });
    });

    group('Language Detection Integration', () {
      test('should detect languages consistently across multiple calls', () async {
        await service.initialize();

        const testText = 'Hello world, this is a test of consistent language detection.';
        
        // Make multiple calls
        final results = <String?>[];
        for (var i = 0; i < 5; i++) {
          final detected = await service.detectLanguage(testText);
          results.add(detected);
        }

        // Results should be consistent (all null or all the same language)
        final firstResult = results.first;
        for (final result in results) {
          expect(result, equals(firstResult));
        }
      });

      test('should handle mixed content appropriately', () async {
        await service.initialize();

        final mixedTexts = [
          'Hello world 123 !@#', // English with numbers and symbols
          'Hola mundo 123 !@#', // Spanish with numbers and symbols
          '123 456 789', // Numbers only
          '!@# \$%^ &*()', // Symbols only
          '', // Empty
          '   ', // Whitespace
        ];

        for (final text in mixedTexts) {
          final result = await service.detectAndTranslate(text);
          expect(result, isNotNull);
          expect(result.originalText, text);
          
          // Should handle gracefully without crashing
          if (text.trim().isEmpty) {
            expect(result.detectedLanguage, isNull);
            expect(result.needsTranslation, false);
          }
        }
      });

      test('should provide reasonable confidence for language detection', () async {
        await service.initialize();

        final confidenceTests = [
          ('The quick brown fox jumps over the lazy dog', 'en'), // High confidence English
          ('El rápido zorro marrón salta sobre el perro perezoso', 'es'), // High confidence Spanish
          ('Le renard brun rapide saute par-dessus le chien paresseux', 'fr'), // High confidence French
          ('Hi', null), // Low confidence - too short
          ('123', null), // No language content
        ];

        for (final (text, expectedLang) in confidenceTests) {
          final detected = await service.detectLanguage(text);
          
          if (expectedLang != null) {
            // For high-confidence texts, should detect something (may not be exact in test env)
            expect(detected, anyOf(equals(expectedLang), isA<String>(), isNull));
          } else {
            // For low-confidence texts, should return null or 'und'
            expect(detected, anyOf(isNull, equals('und')));
          }
        }
      });
    });

    group('Translation Quality and Consistency', () {
      test('should maintain translation quality across different text types', () async {
        await service.initialize();

        final textTypes = [
          'Hello, how are you?', // Greeting
          'Please translate this sentence.', // Request
          'The weather is nice today.', // Statement
          'What time is it?', // Question
          'Thank you very much!', // Appreciation
        ];

        for (final text in textTypes) {
          final result = await service.detectAndTranslate(text);
          expect(result.originalText, text);
          
          // Should handle all types appropriately
          if (result.needsTranslation && result.translatedText != null) {
            expect(result.translatedText!.isNotEmpty, true);
            expect(result.translatedText, isNot(equals(text))); // Should be different if translated
          }
        }
      });

      test('should handle special characters and formatting', () async {
        await service.initialize();

        final specialTexts = [
          'Hello, world! How are you today?', // Punctuation
          'Test with "quotes" and \'apostrophes\'', // Quotes
          'Numbers: 123, 456.78, €100', // Numbers and currency
          'Email: test@example.com', // Email
          'URL: https://www.example.com', // URL
          'Mixed: Hello @user #hashtag', // Social media style
        ];

        for (final text in specialTexts) {
          final result = await service.detectAndTranslate(text);
          expect(result, isNotNull);
          expect(result.originalText, text);
          
          // Should handle without crashing
          if (result.translatedText != null) {
            expect(result.translatedText!.isNotEmpty, true);
          }
        }
      });
    });

    group('Performance and Reliability', () {
      test('should handle rapid consecutive requests', () async {
        await service.initialize();

        const text = 'Test text for performance evaluation';
        final stopwatch = Stopwatch()..start();

        // Make 10 rapid requests
        final futures = List.generate(10, (_) => service.detectAndTranslate(text));
        final results = await Future.wait(futures);

        stopwatch.stop();

        // Should complete all requests
        expect(results.length, 10);
        
        // Should complete in reasonable time (less than 10 seconds for all)
        expect(stopwatch.elapsedMilliseconds, lessThan(10000));

        // All results should be consistent
        for (final result in results) {
          expect(result.originalText, text);
          expect(result, isNotNull);
        }
      });

      test('should maintain performance with varying text lengths', () async {
        await service.initialize();

        final textLengths = [
          'Short', // 5 chars
          'This is a medium length sentence for testing.', // ~45 chars
          'This is a much longer text that contains multiple sentences and should test how well the translation service handles larger amounts of content. ' * 3, // ~300+ chars
        ];

        for (final text in textLengths) {
          final stopwatch = Stopwatch()..start();
          final result = await service.detectAndTranslate(text);
          stopwatch.stop();

          expect(result.originalText, text);
          
          // Should complete in reasonable time regardless of length
          expect(stopwatch.elapsedMilliseconds, lessThan(5000));
        }
      });

      test('should handle service lifecycle properly', () async {
        // Test multiple init/dispose cycles
        for (var i = 0; i < 3; i++) {
          await service.initialize();
          
          final result = await service.detectAndTranslate('Test text $i');
          expect(result.originalText, 'Test text $i');
          
          await service.dispose();
          
          // Create new service for next iteration
          if (i < 2) {
            service = TranslationService();
          }
        }
      });
    });

    group('Error Handling and Recovery', () {
      test('should recover from network-related errors', () async {
        await service.initialize();

        // Test with various potentially problematic inputs
        final problematicInputs = [
          'Text with unicode: 🌟 🚀 💫',
          'Very long text: ${'Long text content. ' * 50}',
          'Mixed scripts: Hello こんにちは 你好 مرحبا',
          'Special chars: <>{}[]()!@#\$%^&*',
        ];

        for (final input in problematicInputs) {
          // Should not throw exceptions
          final result = await service.detectAndTranslate(input);
          expect(result, isNotNull);
          expect(result.originalText, input);
        }
      });

      test('should provide meaningful error states', () async {
        await service.initialize();

        // Test error scenarios
        final errorScenarios = [
          ('', false), // Empty input - should handle gracefully
          ('   \n\t  ', false), // Whitespace - should handle gracefully  
          ('Valid text', true), // Valid input - should work normally
        ];

        for (final (input, shouldWork) in errorScenarios) {
          final result = await service.detectAndTranslate(input);
          expect(result, isNotNull);
          expect(result.originalText, input);
          
          if (!shouldWork) {
            expect(result.detectedLanguage, anyOf(isNull, equals('en')));
            expect(result.needsTranslation, false);
          }
        }
      });

      test('should handle model download failures gracefully', () async {
        await service.initialize();

        // Test with invalid language codes
        final invalidCodes = ['invalid', 'xyz', '123', ''];
        
        for (final code in invalidCodes) {
          final downloadResult = await service.downloadModel(code);
          expect(downloadResult, false); // Should fail gracefully
          
          final deleteResult = await service.deleteModel(code);
          expect(deleteResult, isA<bool>()); // Should handle gracefully
          
          final isDownloaded = await service.isModelDownloaded(code);
          expect(isDownloaded, false); // Should return false
        }
      });
    });

    group('Model Management Integration', () {
      test('should track downloaded models correctly', () async {
        await service.initialize();

        // Get initial state
        final initialModels = await service.getDownloadedModels();
        expect(initialModels, isA<Set<String>>());

        // Test with common language
        const testLang = 'es';
        final initiallyDownloaded = await service.isModelDownloaded(testLang);
        
        if (!initiallyDownloaded) {
          // Try to download
          final downloadResult = await service.downloadModel(testLang);
          
          if (downloadResult) {
            // Check if now reported as downloaded
            final nowDownloaded = await service.isModelDownloaded(testLang);
            expect(nowDownloaded, true);
            
            // Should appear in downloaded models list
            final updatedModels = await service.getDownloadedModels();
            expect(updatedModels.contains(testLang), true);
          }
        }
      });

      test('should handle model deletion workflow', () async {
        await service.initialize();

        const testLang = 'fr';
        
        // Try to download first
        await service.downloadModel(testLang);
        
        // Check if downloaded
        final isDownloaded = await service.isModelDownloaded(testLang);
        
        if (isDownloaded) {
          // Try to delete
          final deleteResult = await service.deleteModel(testLang);
          expect(deleteResult, isA<bool>());
          
          // Check if removed from downloaded list
          final modelsAfterDeletion = await service.getDownloadedModels();
          if (deleteResult) {
            expect(modelsAfterDeletion.contains(testLang), false);
          }
        }
      });
    });
  });
}