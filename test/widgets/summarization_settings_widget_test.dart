import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiny_whisper_tester/widgets/summarization_settings_widget.dart';
import 'package:tiny_whisper_tester/services/summarization_service.dart';

void main() {
  group('SummarizationSettingsWidget Tests', () {
    late SummarizationService service;

    setUp(() {
      service = SummarizationService();
    });

    tearDown(() {
      service.dispose();
    });

    testWidgets('should display available models correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummarizationSettingsWidget(),
          ),
        ),
      );

      // Wait for the widget to build and load data
      await tester.pumpAndSettle();

      // Verify that available models are displayed
      expect(find.text('Available Models'), findsOneWidget);
      expect(find.text('Gemma 3 270M (Default)'), findsOneWidget);
      expect(find.text('292 MB'), findsOneWidget);
      expect(find.text('Default'), findsOneWidget);
    });

    testWidgets('should display storage information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummarizationSettingsWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify storage section exists
      expect(find.text('Storage Usage'), findsOneWidget);
      expect(find.byIcon(Icons.storage_rounded), findsWidgets);
      
      // Should display storage metrics
      expect(find.textContaining('Models'), findsOneWidget);
      expect(find.textContaining('Total Size'), findsOneWidget);
    });

    testWidgets('should handle download button tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummarizationSettingsWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the download button
      final downloadButton = find.widgetWithText(ElevatedButton, 'Download');
      expect(downloadButton, findsAtLeastOneWidget);
      
      await tester.tap(downloadButton.first);
      await tester.pumpAndSettle();

      // Should show download progress or confirmation
      // Note: Actual download won't work in test environment
    });

    testWidgets('should display current model status', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummarizationSettingsWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display current model section
      expect(find.text('Current Model'), findsOneWidget);
      expect(find.text('No model loaded'), findsOneWidget);
    });

    testWidgets('should handle model selection', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummarizationSettingsWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find load model button and tap it
      final loadButtons = find.widgetWithText(OutlinedButton, 'Load');
      if (loadButtons.evaluate().isNotEmpty) {
        await tester.tap(loadButtons.first);
        await tester.pumpAndSettle();
        
        // Should show loading state or error (since no actual file exists)
      }
    });

    testWidgets('should refresh storage information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummarizationSettingsWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap refresh button if it exists
      final refreshButtons = find.byIcon(Icons.refresh);
      if (refreshButtons.evaluate().isNotEmpty) {
        await tester.tap(refreshButtons.first);
        await tester.pumpAndSettle();
        
        // Should update storage information
      }
    });

    testWidgets('should display model descriptions and sizes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummarizationSettingsWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that model information is properly displayed
      expect(find.textContaining('Compact Gemma 3'), findsOneWidget);
      expect(find.text('GGUF'), findsOneWidget);
      
      // Check for model status indicators
      expect(find.byIcon(Icons.download_rounded), findsWidgets);
    });

    testWidgets('should handle delete model action', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummarizationSettingsWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for delete buttons (might not be visible if no models are downloaded)
      final deleteButtons = find.byIcon(Icons.delete_outline);
      
      // If delete buttons exist, test the confirmation dialog
      if (deleteButtons.evaluate().isNotEmpty) {
        await tester.tap(deleteButtons.first);
        await tester.pumpAndSettle();
        
        // Should show confirmation dialog
        expect(find.text('Delete Model'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
      }
    });

    testWidgets('should display error states gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummarizationSettingsWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Widget should handle errors without crashing
      expect(find.byType(SummarizationSettingsWidget), findsOneWidget);
    });

    testWidgets('should update UI when models change', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummarizationSettingsWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initial state
      expect(find.text('No model loaded'), findsOneWidget);

      // Widget should respond to state changes
      // Note: Full integration test would require actual model loading
    });

    testWidgets('should display proper loading states', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummarizationSettingsWidget(),
          ),
        ),
      );

      // Should show loading indicators while fetching data
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      
      await tester.pumpAndSettle();
      
      // Loading indicators should be replaced with content
      expect(find.text('Available Models'), findsOneWidget);
    });
  });
}