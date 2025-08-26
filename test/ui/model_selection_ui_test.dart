import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiny_whisper_tester/screens/home_screen.dart';

void main() {
  group('Model Selection UI Tests', () {
    
    testWidgets('should display model status correctly on Speech tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Wait for initialization
      await tester.pumpAndSettle();

      // Should be on Speech tab by default
      expect(find.text('Current Model'), findsOneWidget);
      
      // Should show no model selected initially
      expect(find.text('No model file selected'), findsOneWidget);
      expect(find.text('Using device speech recognition'), findsOneWidget);
    });

    testWidgets('should switch between tabs correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Initially on Speech tab
      expect(find.text('Current Model'), findsOneWidget);

      // Switch to Models tab
      await tester.tap(find.text('Models'));
      await tester.pumpAndSettle();

      // Should show model download/management UI
      expect(find.text('Downloaded Models'), findsOneWidget);
      expect(find.text('No models downloaded yet'), findsAny);

      // Switch back to Speech tab
      await tester.tap(find.text('Speech'));
      await tester.pumpAndSettle();

      // Should show speech interface again
      expect(find.text('Current Model'), findsOneWidget);
    });

    testWidgets('should show model information when model is selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // The issue we're testing: even when a model path is set,
      // it still shows device speech recognition
      
      // Look for FutureBuilder that displays model info
      expect(find.byType(FutureBuilder<Map<String, dynamic>>), findsOneWidget);
      
      // Should show framework information
      expect(find.textContaining('device speech recognition'), findsAny);
    });

    testWidgets('should handle model selection workflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to Models tab
      await tester.tap(find.text('Models'));
      await tester.pumpAndSettle();

      // Should show model management interface
      expect(find.text('Downloaded Models'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // If no models are downloaded, should show appropriate message
      expect(find.text('No models downloaded yet'), findsAny);
      
      // Should show download form
      expect(find.textContaining('Download'), findsWidgets);
    });

    testWidgets('should display correct model status indicators', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Check Speech tab shows current model status
      expect(find.byIcon(Icons.settings_rounded), findsWidgets);
      expect(find.text('Current Model'), findsOneWidget);

      // Should have language selection
      expect(find.byIcon(Icons.language_rounded), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Auto-detect'), findsOneWidget);
    });

    testWidgets('should show the discrepancy between selected model and actual usage', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // This test documents the current UI issue:
      // 1. User can select a model file in the Models tab
      // 2. The model path gets stored and displayed
      // 3. But the framework line always shows "speech_to_text"
      // 4. This misleads users into thinking their model is being used

      // Look for framework information display
      expect(find.textContaining('speech recognition'), findsWidgets);

      // The issue: UI doesn't clearly indicate that offline models aren't working
      // Users see model path but framework is still device-based
    });

    testWidgets('should show appropriate loading states', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Should show loading indicators while initializing
      expect(find.byType(CircularProgressIndicator), findsAny);

      await tester.pumpAndSettle();

      // After loading, should show content
      expect(find.text('Tiny Whisper Tester'), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('should handle permission requests appropriately', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // App should handle permission requests
      // In test environment, may not trigger actual permission dialogs
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('should show recording controls in Speech tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Should show audio recording interface
      expect(find.byType(Card), findsWidgets);
      
      // Look for recording controls (may be in AudioRecorderWidget)
      expect(find.textContaining('Start'), findsAny);
      expect(find.byIcon(Icons.mic_rounded), findsWidgets);
    });

    testWidgets('should display transcription area', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Should show transcription display area
      expect(find.textContaining('transcription'), findsAny);
      
      // Should have translation capabilities
      expect(find.textContaining('translation'), findsAny);
    });

    testWidgets('should maintain state when switching tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Note initial state on Speech tab
      expect(find.text('Speech'), findsOneWidget);

      // Switch to Settings tab
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Switch back to Speech
      await tester.tap(find.text('Speech'));
      await tester.pumpAndSettle();

      // State should be maintained
      expect(find.text('Current Model'), findsOneWidget);
    });

    testWidgets('should show appropriate error handling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // App should handle initialization errors gracefully
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      
      // Should not crash on initialization issues
      expect(tester.takeException(), isNull);
    });

    testWidgets('should demonstrate the core issue with model selection', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // This test demonstrates the core issue:
      // 1. UI allows model selection
      // 2. Shows model path when selected  
      // 3. But framework line reveals it's still using device speech recognition
      // 4. Users are misled about which system is actually being used

      // Go to Models tab
      await tester.tap(find.text('Models'));
      await tester.pumpAndSettle();

      // User can see model management interface
      expect(find.text('Downloaded Models'), findsOneWidget);
      
      // Go back to Speech tab
      await tester.tap(find.text('Speech'));
      await tester.pumpAndSettle();

      // UI shows framework info but it's always speech_to_text
      expect(find.textContaining('device speech recognition'), findsAny);
      
      // The problem: even if user "selects" a model file,
      // this framework line doesn't change to reflect offline model usage
      // because offline models aren't actually implemented
    });

    group('Model Status Display Issues', () {
      testWidgets('should reveal the misleading model status display', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: HomeScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Find the model status display
        expect(find.text('Current Model'), findsOneWidget);
        
        // This shows "No model file selected" initially
        expect(find.text('No model file selected'), findsOneWidget);
        
        // But also shows "Using device speech recognition"
        expect(find.textContaining('device speech recognition'), findsAny);
        
        // The issue: when a model IS selected, it will show:
        // 1. The model file path (misleading users)
        // 2. "speech_to_text (Production-ready speech recognition)" 
        // 3. Users think their model is loaded but it's not actually used
      });

      testWidgets('should show framework information consistently', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: HomeScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Look for FutureBuilder that gets model info
        final futureBuilders = find.byType(FutureBuilder<Map<String, dynamic>>);
        expect(futureBuilders, findsOneWidget);
        
        // This FutureBuilder calls WhisperService.getModelInfo()
        // which always returns framework: 'speech_to_text'
        // regardless of what model file is "selected"
      });
    });

    group('User Experience Issues', () {
      testWidgets('should expose the confusing user workflow', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: HomeScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Confusing workflow for users:
        // 1. Download a model in Models tab
        await tester.tap(find.text('Models'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Download'), findsWidgets);
        
        // 2. "Select" the model (users think it's now active)
        expect(find.text('Downloaded Models'), findsOneWidget);
        
        // 3. Go back to Speech tab expecting to use their model
        await tester.tap(find.text('Speech'));
        await tester.pumpAndSettle();
        
        // 4. See model path displayed (reinforcing false belief)
        // 5. But framework line shows it's still device speech recognition
        expect(find.textContaining('device speech recognition'), findsAny);
        
        // Users are confused: "I selected a model, why isn't it being used?"
      });

      testWidgets('should show the need for clearer UI messaging', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: HomeScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // The UI should be clearer about:
        // 1. Which models are actually supported/working
        // 2. What the current status really means
        // 3. When offline models will be implemented
        
        // Currently the UI is misleading
        expect(find.textContaining('speech recognition'), findsWidgets);
        
        // Better UI would clearly state:
        // "Offline models not yet supported. Using device speech recognition."
      });
    });
  });
}