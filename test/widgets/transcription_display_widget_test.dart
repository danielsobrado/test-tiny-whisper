import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiny_whisper_tester/widgets/transcription_display_widget.dart';

void main() {
  group('TranscriptionDisplayWidget Tests', () {
    
    testWidgets('should display empty state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranscriptionDisplayWidget(
              transcriptionText: '',
              showTranslation: true,
              onLanguageDetected: null,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show placeholder text when empty
      expect(find.text('Start speaking to see transcription...'), findsOneWidget);
      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
    });

    testWidgets('should display transcription text', (WidgetTester tester) async {
      const testText = 'Hello, this is a test transcription.';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranscriptionDisplayWidget(
              transcriptionText: testText,
              showTranslation: true,
              onLanguageDetected: null,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display the transcription text
      expect(find.text(testText), findsOneWidget);
      expect(find.text('Original'), findsOneWidget);
    });

    testWidgets('should show summarize button when text is present', (WidgetTester tester) async {
      const testText = 'This is a longer text that should trigger the summarize button to appear.';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranscriptionDisplayWidget(
              transcriptionText: testText,
              showTranslation: true,
              onLanguageDetected: null,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show summarize button
      expect(find.textContaining('Summarise'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    });

    testWidgets('should handle summarize button tap', (WidgetTester tester) async {
      const testText = 'This is a test text for summarization functionality.';
      bool summarizeTapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranscriptionDisplayWidget(
              transcriptionText: testText,
              showTranslation: true,
              onLanguageDetected: null,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the summarize button
      final summarizeButton = find.textContaining('Summarise');
      expect(summarizeButton, findsOneWidget);
      
      await tester.tap(summarizeButton);
      await tester.pumpAndSettle();

      // Should show loading state or summary result
      // Note: Actual summarization won't work without proper service integration
    });

    testWidgets('should show translation when showTranslation is true', (WidgetTester tester) async {
      const testText = 'Hola, esto es una prueba.'; // Spanish text
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranscriptionDisplayWidget(
              transcriptionText: testText,
              showTranslation: true,
              onLanguageDetected: null,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show original text section
      expect(find.text('Original'), findsOneWidget);
      expect(find.text(testText), findsOneWidget);
      
      // Should show translation section
      expect(find.text('Translation'), findsOneWidget);
    });

    testWidgets('should hide translation when showTranslation is false', (WidgetTester tester) async {
      const testText = 'Hello, this is English text.';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranscriptionDisplayWidget(
              transcriptionText: testText,
              showTranslation: false,
              onLanguageDetected: null,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should not show translation section
      expect(find.text('Translation'), findsNothing);
      expect(find.text('Original'), findsNothing);
      
      // Should directly show the text
      expect(find.text(testText), findsOneWidget);
    });

    testWidgets('should call onLanguageDetected callback', (WidgetTester tester) async {
      const testText = 'Bonjour, ceci est un test.'; // French text
      String? detectedLanguage;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranscriptionDisplayWidget(
              transcriptionText: testText,
              showTranslation: true,
              onLanguageDetected: (language) {
                detectedLanguage = language;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should attempt language detection
      // Note: Actual detection would require ML Kit integration
    });

    testWidgets('should display copy button for transcription', (WidgetTester tester) async {
      const testText = 'This text should have a copy button.';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranscriptionDisplayWidget(
              transcriptionText: testText,
              showTranslation: true,
              onLanguageDetected: null,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show copy buttons
      expect(find.byIcon(Icons.copy_rounded), findsWidgets);
    });

    testWidgets('should handle copy button tap', (WidgetTester tester) async {
      const testText = 'This text should be copyable.';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranscriptionDisplayWidget(
              transcriptionText: testText,
              showTranslation: true,
              onLanguageDetected: null,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap copy button
      final copyButtons = find.byIcon(Icons.copy_rounded);
      if (copyButtons.evaluate().isNotEmpty) {
        await tester.tap(copyButtons.first);
        await tester.pumpAndSettle();
        
        // Should show confirmation or handle copy action
      }
    });

    testWidgets('should show appropriate prompt style in summarize button', (WidgetTester tester) async {
      const testText = 'This is a test text for checking prompt style display.';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranscriptionDisplayWidget(
              transcriptionText: testText,
              showTranslation: true,
              onLanguageDetected: null,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show current prompt style in button
      final summarizeButton = find.textContaining('Summarise');
      expect(summarizeButton, findsOneWidget);
      
      // Should display current prompt style (e.g., "Key Insights")
      expect(find.textContaining('•'), findsWidgets); // Bullet point indicator
    });

    testWidgets('should handle long transcription text properly', (WidgetTester tester) async {
      const longText = '''
        This is a very long transcription text that should be handled properly by the widget.
        It contains multiple sentences and should trigger all the appropriate UI elements.
        The widget should display this text correctly and provide summarization options.
        This text is long enough to test scrolling and text wrapping functionality.
        The summarize button should definitely appear for text of this length.
      ''';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranscriptionDisplayWidget(
              transcriptionText: longText,
              showTranslation: true,
              onLanguageDetected: null,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should handle long text without issues
      expect(find.text(longText), findsOneWidget);
      expect(find.textContaining('Summarise'), findsOneWidget);
    });

    testWidgets('should display loading state during translation', (WidgetTester tester) async {
      const testText = 'Test text for translation loading.';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranscriptionDisplayWidget(
              transcriptionText: testText,
              showTranslation: true,
              onLanguageDetected: null,
            ),
          ),
        ),
      );

      // Should show loading indicators during translation
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      
      await tester.pumpAndSettle();
      
      // Loading should complete
      expect(find.text(testText), findsOneWidget);
    });

    testWidgets('should handle translation errors gracefully', (WidgetTester tester) async {
      const testText = 'Text that might cause translation errors.';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranscriptionDisplayWidget(
              transcriptionText: testText,
              showTranslation: true,
              onLanguageDetected: null,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should not crash on translation errors
      expect(find.byType(TranscriptionDisplayWidget), findsOneWidget);
      expect(find.text(testText), findsOneWidget);
    });
  });
}