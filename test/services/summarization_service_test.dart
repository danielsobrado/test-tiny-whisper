import 'package:flutter_test/flutter_test.dart';
import 'package:tiny_whisper_tester/services/summarization_service.dart';
import 'dart:io';

void main() {
  group('SummarizationService Tests', () {
    late SummarizationService service;

    setUp(() {
      service = SummarizationService();
    });

    tearDown(() {
      service.dispose();
    });

    test('should initialize service successfully', () async {
      await expectLater(service.initialize(), completes);
    });

    group('Model Management', () {
      test('should have available models defined', () {
        expect(SummarizationService.availableModels.isNotEmpty, true);
        expect(SummarizationService.availableModels.containsKey('gemma-3-270m'), true);
        
        final defaultModel = SummarizationService.availableModels['gemma-3-270m'];
        expect(defaultModel?.isDefault, true);
        expect(defaultModel?.name, contains('270M'));
      });

      test('should return empty list for downloaded models initially', () async {
        final downloaded = await service.getDownloadedModels();
        expect(downloaded, isEmpty);
      });

      test('should return correct model info when no model loaded', () {
        final info = service.getCurrentModelInfo();
        expect(info['name'], 'None');
        expect(info['status'], 'No model loaded');
        expect(info['path'], null);
      });

      test('should simulate model loading successfully', () async {
        // This test would need actual model files to work fully
        // For now, we test the error case
        final result = await service.loadModel('gemma-3-270m');
        expect(result, false); // Should fail without actual file
      });
    });

    group('Prompt Management', () {
      test('should have available prompts defined', () {
        expect(SummarizationService.availablePrompts.isNotEmpty, true);
        expect(SummarizationService.availablePrompts.length, 6);
        
        final expectedPrompts = [
          'bullet_points', 'single_sentence', 'key_insights',
          'technical_summary', 'action_items', 'executive_summary'
        ];
        
        for (final prompt in expectedPrompts) {
          expect(SummarizationService.availablePrompts.containsKey(prompt), true);
        }
      });

      test('should select prompt correctly', () {
        service.selectPrompt('key_insights');
        expect(service.getSelectedPromptKey(), 'key_insights');
        
        final promptInfo = service.getCurrentPromptInfo();
        expect(promptInfo?.name, 'Key Insights');
      });

      test('should ignore invalid prompt selection', () {
        final originalPrompt = service.getSelectedPromptKey();
        service.selectPrompt('invalid_prompt');
        expect(service.getSelectedPromptKey(), originalPrompt);
      });
    });

    group('Text Summarization', () {
      test('should handle empty text input', () async {
        final result = await service.summarizeText('');
        expect(result, 'No text to summarize.');
      });

      test('should handle whitespace-only text', () async {
        final result = await service.summarizeText('   \n\t  ');
        expect(result, 'No text to summarize.');
      });

      test('should generate bullet point summary', () async {
        service.selectPrompt('bullet_points');
        const testText = 'This is a test document. It contains multiple sentences. '
                        'The document discusses important topics. We need to summarize the key points.';
        
        final result = await service.summarizeText(testText);
        expect(result.startsWith('•'), true);
        expect(result.contains('\n'), true);
      });

      test('should generate single sentence summary', () async {
        service.selectPrompt('single_sentence');
        const testText = 'This is a test document. It contains multiple sentences. '
                        'The document discusses important topics.';
        
        final result = await service.summarizeText(testText);
        expect(result.split('.').length, lessThanOrEqualTo(2)); // One sentence + possible empty string
        expect(result.endsWith('.'), true);
      });

      test('should generate key insights summary', () async {
        service.selectPrompt('key_insights');
        const testText = 'This project involves developing new features. '
                        'The team needs to implement authentication and user management.';
        
        final result = await service.summarizeText(testText);
        expect(result.startsWith('Key Insights:'), true);
        expect(result.contains('1.'), true);
      });

      test('should generate technical summary', () async {
        service.selectPrompt('technical_summary');
        const testText = 'The system architecture includes a database layer. '
                        'We need to implement API endpoints for data access.';
        
        final result = await service.summarizeText(testText);
        expect(result.contains('Technical Summary:'), true);
        expect(result.contains('Overview:'), true);
      });

      test('should generate action items summary', () async {
        service.selectPrompt('action_items');
        const testText = 'We need to review the code. The team should complete testing. '
                        'Please update the documentation.';
        
        final result = await service.summarizeText(testText);
        expect(result.contains('Action Items:'), true);
        expect(result.contains('□'), true);
      });

      test('should generate executive summary', () async {
        service.selectPrompt('executive_summary');
        const testText = 'The quarterly results show strong performance. '
                        'Revenue increased significantly and customer satisfaction improved.';
        
        final result = await service.summarizeText(testText);
        expect(result.startsWith('Executive Summary:'), true);
        expect(result.contains('Strategic'), true);
      });

      test('should handle very long text', () async {
        final longText = 'This is a sentence. ' * 100;
        final result = await service.summarizeText(longText);
        expect(result.isNotEmpty, true);
        expect(result.length, lessThan(longText.length));
      });

      test('should extract key words correctly', () async {
        service.selectPrompt('key_insights');
        const testText = 'The development team implemented authentication features. '
                        'Security measures were enhanced through encryption protocols.';
        
        final result = await service.summarizeText(testText);
        expect(result.toLowerCase().contains('development') ||
               result.toLowerCase().contains('authentication') ||
               result.toLowerCase().contains('security'), true);
      });
    });

    group('Storage Management', () {
      test('should return storage info with correct structure', () async {
        final info = await service.getStorageInfo();
        expect(info.containsKey('totalSize'), true);
        expect(info.containsKey('modelCount'), true);
        expect(info.containsKey('formattedSize'), true);
        expect(info.containsKey('modelsPath'), true);
        
        expect(info['totalSize'], isA<int>());
        expect(info['modelCount'], isA<int>());
        expect(info['formattedSize'], isA<String>());
      });

      test('should format bytes correctly', () async {
        final info = await service.getStorageInfo();
        final formattedSize = info['formattedSize'] as String;
        expect(formattedSize.contains(RegExp(r'\d+(\.\d+)?\s*(B|KB|MB|GB)')), true);
      });
    });

    group('Error Handling', () {
      test('should handle service disposal gracefully', () {
        expect(() => service.dispose(), returnsNormally);
        
        final info = service.getCurrentModelInfo();
        expect(info['name'], 'None');
      });

      test('should handle invalid model key', () async {
        final result = await service.loadModel('nonexistent-model');
        expect(result, false);
      });

      test('should fallback to rule-based summarization on errors', () async {
        const testText = 'This is a simple test text for summarization.';
        final result = await service.summarizeText(testText);
        expect(result.isNotEmpty, true);
        expect(result, isNot('No text to summarize.'));
      });
    });
  });
}