import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiny_whisper_tester/services/summarization_service.dart';

void main() {
  group('Summarization Integration Tests', () {
    late SummarizationService service;

    setUp(() {
      service = SummarizationService();
    });

    tearDown(() {
      service.dispose();
    });

    group('Full Workflow Integration', () {
      test('should complete full summarization workflow', () async {
        // Initialize service
        await service.initialize();
        expect(service, isNotNull);

        // Select a prompt style
        service.selectPrompt('bullet_points');
        expect(service.getSelectedPromptKey(), 'bullet_points');

        // Perform summarization
        const testText = '''
          The quarterly meeting discussed several important topics. 
          First, we reviewed the financial performance which showed a 15% increase in revenue.
          Second, the team presented new product features that will be launched next month.
          Third, we discussed hiring plans to expand the development team by 5 new members.
          Finally, we set goals for the next quarter including improving customer satisfaction scores.
        ''';

        final summary = await service.summarizeText(testText);
        
        // Verify summarization results
        expect(summary.isNotEmpty, true);
        expect(summary.contains('•'), true); // Bullet point format
        expect(summary.length, lessThan(testText.length)); // Should be shorter
      });

      test('should handle workflow with different prompt styles', () async {
        await service.initialize();
        
        const testText = 'The team completed the project on time. Quality was excellent and client was satisfied.';

        // Test different prompt styles
        final promptKeys = ['single_sentence', 'key_insights', 'action_items'];
        
        for (final promptKey in promptKeys) {
          service.selectPrompt(promptKey);
          final summary = await service.summarizeText(testText);
          
          expect(summary.isNotEmpty, true);
          expect(summary, isNot('No text to summarize.'));
          
          // Verify format based on prompt type
          switch (promptKey) {
            case 'single_sentence':
              expect(summary.split('.').length, lessThanOrEqualTo(2));
              break;
            case 'key_insights':
              expect(summary.contains('Key Insights:'), true);
              break;
            case 'action_items':
              expect(summary.contains('Action Items:'), true);
              expect(summary.contains('□'), true);
              break;
          }
        }
      });

      test('should handle model loading workflow', () async {
        await service.initialize();

        // Initially no model should be loaded
        final initialInfo = service.getCurrentModelInfo();
        expect(initialInfo['name'], 'None');
        expect(initialInfo['status'], 'No model loaded');

        // Attempt to load a model (should fail without actual file)
        final loadResult = await service.loadModel('gemma-3-270m');
        expect(loadResult, false); // Should fail in test environment

        // Model info should remain unchanged
        final infoAfterLoad = service.getCurrentModelInfo();
        expect(infoAfterLoad['name'], 'None');
      });

      test('should handle storage management workflow', () async {
        await service.initialize();

        // Get storage information
        final storageInfo = await service.getStorageInfo();
        
        expect(storageInfo.containsKey('totalSize'), true);
        expect(storageInfo.containsKey('modelCount'), true);
        expect(storageInfo.containsKey('formattedSize'), true);
        expect(storageInfo.containsKey('modelsPath'), true);

        expect(storageInfo['totalSize'], isA<int>());
        expect(storageInfo['modelCount'], isA<int>());
        expect(storageInfo['formattedSize'], isA<String>());
      });
    });

    group('Error Recovery Integration', () {
      test('should recover from summarization errors', () async {
        await service.initialize();

        // Test with potentially problematic text
        const problematicTexts = [
          '', // Empty text
          '   \n\t  ', // Whitespace only
          'A', // Very short text
          'Text with special chars: @#\$%^&*()[]{}|\\:";\'<>?,./`~',
        ];

        for (final text in problematicTexts) {
          final result = await service.summarizeText(text);
          expect(result, isNotNull);
          expect(result, isA<String>());
          
          if (text.trim().isEmpty) {
            expect(result, 'No text to summarize.');
          } else {
            expect(result.isNotEmpty, true);
          }
        }
      });

      test('should handle service disposal and reinitialization', () async {
        // Initialize service
        await service.initialize();
        service.selectPrompt('bullet_points');
        
        // Use service
        final summary1 = await service.summarizeText('First test text.');
        expect(summary1.isNotEmpty, true);

        // Dispose service
        service.dispose();
        
        // Reinitialize
        await service.initialize();
        
        // Service should work again
        final summary2 = await service.summarizeText('Second test text.');
        expect(summary2.isNotEmpty, true);
      });

      test('should handle concurrent summarization requests', () async {
        await service.initialize();
        service.selectPrompt('single_sentence');

        const testTexts = [
          'First concurrent summarization request with some test content.',
          'Second concurrent request with different content to summarize.',
          'Third request testing concurrent processing capabilities.',
        ];

        // Submit concurrent requests
        final futures = testTexts.map((text) => service.summarizeText(text));
        final results = await Future.wait(futures);

        // All requests should complete successfully
        expect(results.length, 3);
        for (final result in results) {
          expect(result.isNotEmpty, true);
          expect(result, isNot('No text to summarize.'));
        }
      });
    });

    group('Performance Integration', () {
      test('should handle large text efficiently', () async {
        await service.initialize();
        service.selectPrompt('executive_summary');

        // Generate large text
        final largeText = List.generate(50, (i) => 
          'This is sentence number $i in a large document. '
          'It contains meaningful content that should be summarized effectively. '
          'The summarization service should handle this text efficiently.'
        ).join(' ');

        expect(largeText.length, greaterThan(1000));

        final stopwatch = Stopwatch()..start();
        final summary = await service.summarizeText(largeText);
        stopwatch.stop();

        // Should complete in reasonable time (less than 5 seconds for mock)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
        expect(summary.isNotEmpty, true);
        expect(summary.length, lessThan(largeText.length));
      });

      test('should handle rapid prompt switching', () async {
        await service.initialize();
        
        const testText = 'Test content for rapid prompt switching evaluation.';
        const prompts = [
          'bullet_points', 'single_sentence', 'key_insights', 
          'technical_summary', 'action_items', 'executive_summary'
        ];

        // Rapidly switch prompts and summarize
        for (final prompt in prompts) {
          service.selectPrompt(prompt);
          expect(service.getSelectedPromptKey(), prompt);
          
          final summary = await service.summarizeText(testText);
          expect(summary.isNotEmpty, true);
        }
      });
    });

    group('State Management Integration', () {
      test('should maintain state consistency across operations', () async {
        await service.initialize();

        // Initial state
        expect(service.getSelectedPromptKey(), 'bullet_points'); // Default
        expect(service.getCurrentModelInfo()['name'], 'None');

        // Change prompt
        service.selectPrompt('key_insights');
        expect(service.getSelectedPromptKey(), 'key_insights');

        // Perform summarization
        final summary = await service.summarizeText('Test text for state consistency.');
        expect(summary.contains('Key Insights:'), true);

        // State should remain consistent
        expect(service.getSelectedPromptKey(), 'key_insights');

        // Attempt model loading
        await service.loadModel('gemma-3-270m');
        
        // Prompt selection should remain unchanged
        expect(service.getSelectedPromptKey(), 'key_insights');
      });

      test('should handle invalid state transitions gracefully', () async {
        await service.initialize();

        // Try invalid prompt
        final originalPrompt = service.getSelectedPromptKey();
        service.selectPrompt('invalid_prompt_key');
        expect(service.getSelectedPromptKey(), originalPrompt); // Should remain unchanged

        // Try invalid model
        final loadResult = await service.loadModel('nonexistent_model');
        expect(loadResult, false);

        // Service should still function normally
        final summary = await service.summarizeText('Test after invalid operations.');
        expect(summary.isNotEmpty, true);
      });

      test('should provide consistent prompt information', () async {
        await service.initialize();

        for (final promptKey in SummarizationService.availablePrompts.keys) {
          service.selectPrompt(promptKey);
          
          final selectedKey = service.getSelectedPromptKey();
          final promptInfo = service.getCurrentPromptInfo();
          
          expect(selectedKey, promptKey);
          expect(promptInfo, isNotNull);
          expect(promptInfo!.key, promptKey);
          expect(SummarizationService.availablePrompts.containsKey(promptKey), true);
        }
      });
    });

    group('Data Validation Integration', () {
      test('should validate text input properly', () async {
        await service.initialize();
        service.selectPrompt('single_sentence');

        final testCases = [
          ('', 'No text to summarize.'),
          ('   ', 'No text to summarize.'),
          ('\n\t\r', 'No text to summarize.'),
          ('Valid text', isNot('No text to summarize.')),
        ];

        for (final (input, expected) in testCases) {
          final result = await service.summarizeText(input);
          if (expected is String) {
            expect(result, expected);
          } else {
            expect(result, expected as Matcher);
          }
        }
      });

      test('should handle edge cases in model information', () async {
        await service.initialize();

        // Test available models structure
        expect(SummarizationService.availableModels.isNotEmpty, true);
        
        for (final model in SummarizationService.availableModels.values) {
          expect(model.name.isNotEmpty, true);
          expect(model.description.isNotEmpty, true);
          expect(model.size.isNotEmpty, true);
          expect(model.url.isNotEmpty, true);
          expect(model.format.isNotEmpty, true);
        }

        // Test default model exists
        final defaultModels = SummarizationService.availableModels.values
            .where((m) => m.isDefault);
        expect(defaultModels.isNotEmpty, true);
        expect(defaultModels.length, 1); // Should have exactly one default
      });
    });
  });
}