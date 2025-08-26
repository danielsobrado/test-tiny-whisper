import 'package:flutter_test/flutter_test.dart';
import 'package:tiny_whisper_tester/services/summarization_service.dart';

void main() {
  group('Summarization Fix Tests', () {
    late SummarizationService service;

    setUp(() {
      service = SummarizationService();
    });

    tearDown(() {
      service.dispose();
    });

    group('Bullet Points Summarization Fix', () {
      test('should create actual bullet point summaries, not full sentences', () async {
        await service.initialize();
        service.selectPrompt('bullet_points');
        
        const longText = '''
          The quarterly meeting was held yesterday to discuss the financial performance of the company.
          We reviewed the sales figures which showed a significant increase of 15% compared to last quarter.
          The marketing team presented their new campaign strategy for the upcoming product launch.
          Management decided to allocate additional resources to the development team to accelerate the project timeline.
          The meeting concluded with plans to schedule a follow-up session next month to review progress.
        ''';
        
        final result = await service.summarizeText(longText);
        
        // Should be bullet points
        expect(result.startsWith('•'), true);
        expect(result.contains('\n'), true);
        
        // Should NOT be the same as original text
        expect(result, isNot(equals(longText)));
        expect(result.length, lessThan(longText.length));
        
        // Each bullet point should be shorter than original sentences
        final bulletPoints = result.split('\n');
        expect(bulletPoints.length, greaterThan(1));
        
        for (final bullet in bulletPoints) {
          if (bullet.trim().isNotEmpty) {
            expect(bullet.startsWith('•'), true);
            // Bullet points should be concise, not full sentences
            expect(bullet.length, lessThan(200));
          }
        }
        
        print('Original text length: ${longText.length}');
        print('Summary length: ${result.length}');
        print('Summary:\n$result');
      });

      test('should extract key phrases instead of copying full sentences', () async {
        await service.initialize();
        service.selectPrompt('bullet_points');
        
        const testText = '''
          The development team is working on implementing the new authentication system for the mobile application.
          This system will include biometric authentication, two-factor authentication, and social media login options.
          The project manager announced that the deadline has been moved up by two weeks due to client requirements.
        ''';
        
        final result = await service.summarizeText(testText);
        
        // Should contain key concepts but be much shorter
        expect(result.length, lessThan(testText.length / 2));
        expect(result.contains('•'), true);
        
        // Should not contain full original sentences
        expect(result.contains('The development team is working on implementing the new authentication system for the mobile application'), false);
        
        // Should contain key concepts
        expect(result.toLowerCase().contains('authentication') || 
               result.toLowerCase().contains('development') ||
               result.toLowerCase().contains('system'), true);
               
        print('Bullet points result:\n$result');
      });
    });

    group('Single Sentence Summarization Fix', () {
      test('should create a truly single sentence summary', () async {
        await service.initialize();
        service.selectPrompt('single_sentence');
        
        const multipleText = '''
          The company reported record profits this quarter. Sales increased by 25% year over year. 
          The CEO announced plans for expansion into new markets. Employee satisfaction scores also improved significantly.
          The board approved a dividend increase for shareholders.
        ''';
        
        final result = await service.summarizeText(multipleText);
        
        // Should be a single sentence
        final sentences = result.split('.').where((s) => s.trim().isNotEmpty).length;
        expect(sentences, equals(1));
        expect(result.endsWith('.'), true);
        
        // Should be much shorter than original
        expect(result.length, lessThan(multipleText.length / 3));
        
        // Should contain key information
        expect(result.toLowerCase().contains('company') ||
               result.toLowerCase().contains('profits') ||
               result.toLowerCase().contains('sales'), true);
               
        print('Single sentence result: $result');
      });

      test('should shorten long single sentences', () async {
        await service.initialize();
        service.selectPrompt('single_sentence');
        
        const longSingleSentence = '''
          The comprehensive quarterly business review meeting that was scheduled for last Tuesday included detailed presentations from all department heads covering financial performance, operational efficiency metrics, strategic planning initiatives, customer satisfaction surveys, employee engagement scores, and future growth projections for the next fiscal year.
        ''';
        
        final result = await service.summarizeText(longSingleSentence);
        
        // Should be shorter than original
        expect(result.length, lessThan(longSingleSentence.length));
        
        // Should still be meaningful
        expect(result.length, greaterThan(20));
        
        print('Shortened sentence: $result');
      });
    });

    group('All Prompt Types Should Summarize', () {
      const testText = '''
        The project team completed the quarterly review meeting yesterday. 
        Key achievements included launching the new mobile app feature, 
        improving customer satisfaction scores by 20%, and reducing system downtime to less than 1%.
        Next quarter goals focus on expanding the user base and implementing advanced analytics.
      ''';

      test('bullet_points should create concise bullet points', () async {
        await service.initialize();
        service.selectPrompt('bullet_points');
        
        final result = await service.summarizeText(testText);
        
        expect(result.startsWith('•'), true);
        expect(result.length, lessThan(testText.length));
        expect(result, isNot(equals(testText.trim())));
        
        print('Bullet points:\n$result');
      });

      test('single_sentence should create one concise sentence', () async {
        await service.initialize();
        service.selectPrompt('single_sentence');
        
        final result = await service.summarizeText(testText);
        
        final sentenceCount = result.split('.').where((s) => s.trim().isNotEmpty).length;
        expect(sentenceCount, equals(1));
        expect(result.length, lessThan(testText.length));
        
        print('Single sentence: $result');
      });

      test('key_insights should provide structured insights', () async {
        await service.initialize();
        service.selectPrompt('key_insights');
        
        final result = await service.summarizeText(testText);
        
        expect(result.contains('Key Insights:'), true);
        expect(result.contains('1.'), true);
        expect(result.length, lessThan(testText.length * 1.5)); // Allow some expansion for structure
        
        print('Key insights:\n$result');
      });

      test('executive_summary should be concise and strategic', () async {
        await service.initialize();
        service.selectPrompt('executive_summary');
        
        final result = await service.summarizeText(testText);
        
        expect(result.contains('Executive Summary:'), true);
        expect(result.length, lessThan(testText.length));
        
        print('Executive summary: $result');
      });
    });

    group('Regression Tests', () {
      test('should never return the exact original text as summary', () async {
        await service.initialize();
        
        const originalText = 'This is a test sentence that should be summarized in some way.';
        
        final prompts = ['bullet_points', 'single_sentence', 'key_insights', 'executive_summary'];
        
        for (final prompt in prompts) {
          service.selectPrompt(prompt);
          final result = await service.summarizeText(originalText);
          
          // Should never return exactly the same text
          expect(result, isNot(equals(originalText)));
          expect(result, isNot(equals(originalText.trim())));
          
          print('$prompt result: $result');
        }
      });

      test('should handle edge cases properly', () async {
        await service.initialize();
        service.selectPrompt('bullet_points');
        
        // Very short text
        final shortResult = await service.summarizeText('Short text.');
        expect(shortResult, isNot(equals('Short text.')));
        expect(shortResult.isNotEmpty, true);
        
        // Empty text
        final emptyResult = await service.summarizeText('');
        expect(emptyResult, 'No text to summarize.');
        
        // Whitespace only
        final whitespaceResult = await service.summarizeText('   \n\t  ');
        expect(whitespaceResult, 'No text to summarize.');
      });
    });
  });
}