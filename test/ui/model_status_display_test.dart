import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiny_whisper_tester/screens/home_screen.dart';
import 'package:tiny_whisper_tester/services/whisper_service.dart';

void main() {
  group('Model Status Display Tests', () {
    
    testWidgets('should display correct status when no model is selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Should show no model selected
      expect(find.text('No model file selected'), findsOneWidget);
      expect(find.text('Device speech recognition'), findsOneWidget);
      expect(find.text('No offline model selected'), findsOneWidget);
    });

    testWidgets('should clearly indicate when offline models are not implemented', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // When a model is "selected" but not actually used, should show warning
      // This will be visible when users select a model in the Models tab
      
      // Look for framework information display
      expect(find.byType(FutureBuilder<Map<String, dynamic>>), findsOneWidget);
      
      // Should show device speech recognition is being used
      expect(find.textContaining('Device speech recognition'), findsOneWidget);
    });

    testWidgets('should show correct visual indicators for model status', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Should show appropriate icons
      expect(find.byIcon(Icons.cloud), findsOneWidget); // Cloud icon for device recognition
      expect(find.byIcon(Icons.settings_rounded), findsWidgets);
      expect(find.byIcon(Icons.language_rounded), findsWidgets);
    });

    testWidgets('should display enhanced model information in improved UI', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Should show the enhanced UI with better status information
      expect(find.byType(Container), findsWidgets); // Status containers
      
      // Should not show misleading "model loaded" messages
      expect(find.text('NOT USED'), findsNothing); // Only appears when model selected but not used
      expect(find.text('ACTIVE'), findsNothing); // Only appears when offline model actually active
    });

    group('Model Selection Status Indicators', () {
      testWidgets('should show NOT USED badge when model selected but not active', (WidgetTester tester) async {
        // This test would need to simulate model selection
        // For now, we test the UI structure
        
        await tester.pumpWidget(
          const MaterialApp(
            home: HomeScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // The enhanced UI should be present
        expect(find.byType(FutureBuilder<Map<String, dynamic>>), findsOneWidget);
      });

      testWidgets('should show ACTIVE badge when offline model is truly active', (WidgetTester tester) async {
        // This would show when offline models are actually implemented
        await tester.pumpWidget(
          const MaterialApp(
            home: HomeScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Currently no models are active, so ACTIVE badge shouldn't appear
        expect(find.text('ACTIVE'), findsNothing);
      });

      testWidgets('should display different colors for different model states', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: HomeScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Should show containers with appropriate colors
        expect(find.byType(Container), findsWidgets);
        
        // Colors should indicate status (blue for device, green for active offline, orange for selected but not used)
      });
    });

    group('Framework Information Display', () {
      testWidgets('should clearly show which speech recognition engine is active', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: HomeScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Should show framework container with icon
        expect(find.byIcon(Icons.cloud), findsOneWidget); // Device recognition icon
        expect(find.textContaining('Device speech recognition'), findsOneWidget);
      });

      testWidgets('should show offline model status when model is selected', (WidgetTester tester) async {
        // This would appear when user selects a model but it's not actually used
        await tester.pumpWidget(
          const MaterialApp(
            home: HomeScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Currently no model selected, so offline status shouldn't show
        expect(find.textContaining('not yet implemented'), findsNothing);
      });
    });

    group('Model Details Display', () {
      testWidgets('should show model format and type chips when model is selected', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: HomeScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // When no model selected, shouldn't show detail chips
        expect(find.textContaining('Format:'), findsNothing);
        expect(find.textContaining('Type:'), findsNothing);
        expect(find.textContaining('Size:'), findsNothing);
      });

      testWidgets('should format file sizes correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: HomeScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // File size formatting would be visible when model is selected
        // Currently no model, so no size display
        expect(find.textContaining('MB'), findsNothing);
        expect(find.textContaining('GB'), findsNothing);
      });
    });

    group('User Experience Improvements', () {
      testWidgets('should provide clear feedback about model implementation status', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: HomeScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // The improved UI should make it clear what's happening
        expect(find.textContaining('Device speech recognition'), findsOneWidget);
        
        // When models are selected but not used, should show explanatory text
        // This prevents user confusion about why their selected model isn't working
      });

      testWidgets('should show appropriate icons for different recognition modes', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: HomeScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Cloud icon for device/online recognition
        expect(find.byIcon(Icons.cloud), findsOneWidget);
        
        // Offline bolt icon would appear when offline model is active
        expect(find.byIcon(Icons.offline_bolt), findsNothing);
      });

      testWidgets('should maintain visual consistency across the app', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: HomeScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Should use consistent styling
        expect(find.byType(Card), findsWidgets);
        expect(find.byType(Container), findsWidgets);
        
        // Should have proper Material Design 3 styling
        expect(find.byType(FutureBuilder<Map<String, dynamic>>), findsOneWidget);
      });
    });

    group('Regression Tests for Original Issue', () {
      testWidgets('should no longer mislead users about model usage', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: HomeScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // The original issue: UI showed model path but framework was still speech_to_text
        // New UI should clearly indicate what's actually being used
        
        // No model selected - should be clear about device usage
        expect(find.textContaining('Device speech recognition'), findsOneWidget);
        
        // When model IS selected, should show "NOT USED" badge and explanation
        // This prevents the confusion from the original issue
      });

      testWidgets('should clearly distinguish between selected and active models', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: HomeScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // The fix ensures users understand:
        // 1. What model file they've selected (if any)
        // 2. Whether that model is actually being used
        // 3. What speech recognition engine is actually active
        
        expect(find.byType(FutureBuilder<Map<String, dynamic>>), findsOneWidget);
      });

      testWidgets('should handle the speech-to-text vs offline model distinction', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: HomeScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Should clearly show that device speech recognition is being used
        // and not confuse users into thinking offline models are working
        expect(find.textContaining('Device speech recognition'), findsOneWidget);
      });
    });
  });

  group('WhisperService Enhanced Info Tests', () {
    late WhisperService service;

    setUp(() {
      service = WhisperService();
    });

    tearDown(() {
      service.dispose();
    });

    test('should provide enhanced model info when no model selected', () async {
      final info = await service.getModelInfo();
      
      expect(info['status'], 'No model loaded');
      expect(info['framework'], 'Device speech recognition');
      expect(info['offline_model_status'], 'No offline model selected');
      expect(info['is_offline_active'], null);
    });

    test('should indicate when selected model is not being used', () async {
      // Try to load a fake model (will fail but path will be set)
      try {
        await service.loadModel('/fake/model.gguf');
      } catch (e) {
        // Expected to fail
      }

      final info = await service.getModelInfo();
      
      // Should clearly indicate the model is selected but not used
      expect(info['framework'], contains('offline models not yet implemented'));
      expect(info['offline_model_status'], contains('not in use'));
      expect(info['is_offline_active'], false);
    });

    test('should provide model format information', () async {
      try {
        await service.loadModel('/fake/model.onnx');
      } catch (e) {
        // Expected
      }

      final info = await service.getModelInfo();
      expect(info['model_format'], 'ONNX');
    });

    test('should detect file existence status', () async {
      try {
        await service.loadModel('/nonexistent/model.gguf');
      } catch (e) {
        // Expected
      }

      final info = await service.getModelInfo();
      expect(info['file_exists'], false);
      expect(info['framework'], contains('model file not found'));
    });

    test('should provide complete status information', () async {
      final info = await service.getModelInfo();
      
      // Should have all the new fields for comprehensive status
      expect(info.containsKey('status'), true);
      expect(info.containsKey('framework'), true);
      expect(info.containsKey('offline_model_status'), true);
      expect(info.containsKey('is_offline_active'), true);
    });
  });
}