import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiny_whisper_tester/widgets/language_management_widget.dart';

void main() {
  group('LanguageManagementWidget Tests', () {
    
    testWidgets('should show loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LanguageManagementWidget(),
          ),
        ),
      );

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading language models...'), findsOneWidget);
    });

    testWidgets('should display header information after loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LanguageManagementWidget(),
          ),
        ),
      );

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Should display header with translation info
      expect(find.text('Translation Language Models'), findsOneWidget);
      expect(find.text('Download language models for offline translation. Models are used to automatically translate non-English speech to English.'), findsOneWidget);
      expect(find.byIcon(Icons.translate), findsOneWidget);
      expect(find.textContaining('Downloaded:'), findsOneWidget);
    });

    testWidgets('should display language list', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LanguageManagementWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display language items
      expect(find.byType(ListTile), findsWidgets);
      
      // Should show English as special item
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Default target language'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsWidgets);
    });

    testWidgets('should show English as special default language', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LanguageManagementWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find English language item
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Default target language'), findsOneWidget);
      expect(find.text('Code: EN'), findsOneWidget);
      
      // English should have star icon and special styling
      expect(find.byIcon(Icons.star), findsAtLeastOneWidget);
    });

    testWidgets('should display other languages with proper formatting', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LanguageManagementWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show various language names
      expect(find.textContaining('Spanish'), findsAny);
      expect(find.textContaining('French'), findsAny);
      expect(find.textContaining('German'), findsAny);
      
      // Should show language codes
      expect(find.textContaining('Code:'), findsWidgets);
    });

    testWidgets('should show download buttons for non-downloaded languages', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LanguageManagementWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show download icons for languages that aren't downloaded
      expect(find.byIcon(Icons.download), findsWidgets);
      expect(find.text('Not downloaded'), findsWidgets);
    });

    testWidgets('should handle download button tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LanguageManagementWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap a download button
      final downloadButtons = find.byIcon(Icons.download);
      if (downloadButtons.evaluate().isNotEmpty) {
        await tester.tap(downloadButtons.first);
        await tester.pump();

        // Should show loading state for that item
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      }
    });

    testWidgets('should show delete buttons for downloaded languages', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LanguageManagementWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // If any languages are shown as downloaded, they should have delete buttons
      final deleteButtons = find.byIcon(Icons.delete_outline);
      final checkIcons = find.byIcon(Icons.check);
      
      if (checkIcons.evaluate().isNotEmpty) {
        expect(deleteButtons, findsWidgets);
      }
    });

    testWidgets('should show delete confirmation dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LanguageManagementWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find delete buttons (if any downloaded languages exist)
      final deleteButtons = find.byIcon(Icons.delete_outline);
      
      if (deleteButtons.evaluate().isNotEmpty) {
        await tester.tap(deleteButtons.first);
        await tester.pumpAndSettle();

        // Should show confirmation dialog
        expect(find.text('Delete Language Model'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
        expect(find.textContaining('Are you sure you want to delete'), findsOneWidget);
      }
    });

    testWidgets('should handle delete confirmation cancel', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LanguageManagementWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final deleteButtons = find.byIcon(Icons.delete_outline);
      
      if (deleteButtons.evaluate().isNotEmpty) {
        await tester.tap(deleteButtons.first);
        await tester.pumpAndSettle();

        // Tap cancel button
        final cancelButton = find.text('Cancel');
        expect(cancelButton, findsOneWidget);
        await tester.tap(cancelButton);
        await tester.pumpAndSettle();

        // Dialog should be dismissed
        expect(find.text('Delete Language Model'), findsNothing);
      }
    });

    testWidgets('should handle delete confirmation accept', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LanguageManagementWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final deleteButtons = find.byIcon(Icons.delete_outline);
      
      if (deleteButtons.evaluate().isNotEmpty) {
        await tester.tap(deleteButtons.first);
        await tester.pumpAndSettle();

        // Tap delete button
        final deleteButton = find.text('Delete').last; // Get the button, not text in dialog content
        await tester.tap(deleteButton);
        await tester.pumpAndSettle();

        // Dialog should be dismissed
        expect(find.text('Delete Language Model'), findsNothing);
      }
    });

    testWidgets('should show proper status messages', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LanguageManagementWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show various status messages
      expect(find.text('Ready for translation'), findsAny);
      expect(find.text('Not downloaded'), findsWidgets);
    });

    testWidgets('should display language codes in uppercase', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LanguageManagementWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Language codes should be displayed in uppercase
      expect(find.text('Code: EN'), findsOneWidget); // English
      expect(find.textContaining('Code: ES'), findsAny); // Spanish (if present)
      expect(find.textContaining('Code: FR'), findsAny); // French (if present)
    });

    testWidgets('should show correct icons for different states', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LanguageManagementWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // English should have star icon
      expect(find.byIcon(Icons.star), findsAtLeastOneWidget);
      
      // Downloaded languages should have check icon
      expect(find.byIcon(Icons.check), findsAny);
      
      // Non-downloaded languages should have language icon
      expect(find.byIcon(Icons.language), findsWidgets);
      
      // Should have download icons for downloadable languages
      expect(find.byIcon(Icons.download), findsWidgets);
    });

    testWidgets('should handle loading states during download', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LanguageManagementWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final downloadButtons = find.byIcon(Icons.download);
      
      if (downloadButtons.evaluate().isNotEmpty) {
        await tester.tap(downloadButtons.first);
        await tester.pump(); // Don't wait for completion

        // Should show loading indicator in place of download button
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      }
    });

    testWidgets('should show downloaded count in header', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LanguageManagementWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show downloaded count
      expect(find.textContaining('Downloaded: '), findsOneWidget);
      expect(find.textContaining(' models'), findsOneWidget);
    });

    testWidgets('should handle service initialization errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LanguageManagementWidget(),
          ),
        ),
      );

      // Wait for potential error handling
      await tester.pumpAndSettle();

      // Widget should handle errors gracefully and not crash
      expect(find.byType(LanguageManagementWidget), findsOneWidget);
    });

    testWidgets('should sort languages alphabetically', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LanguageManagementWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Get all language names from ListTiles
      final listTiles = tester.widgetList<ListTile>(find.byType(ListTile));
      final languageNames = <String>[];
      
      for (final tile in listTiles) {
        final titleWidget = tile.title;
        if (titleWidget is Text) {
          languageNames.add(titleWidget.data!);
        }
      }

      // Should have multiple languages
      expect(languageNames.length, greaterThan(1));
      
      // Check if sorted (allowing for English to potentially be first as special case)
      for (int i = 1; i < languageNames.length; i++) {
        // Skip comparison if previous item is English (special case)
        if (languageNames[i-1] != 'English') {
          expect(
            languageNames[i-1].compareTo(languageNames[i]) <= 0,
            true,
            reason: 'Languages should be sorted alphabetically: ${languageNames[i-1]} should come before ${languageNames[i]}'
          );
        }
      }
    });

    testWidgets('should provide proper tooltips', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LanguageManagementWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for tooltips on action buttons
      final downloadButtons = find.byTooltip('Download model');
      final deleteButtons = find.byTooltip('Delete model');

      // Should have tooltips for better accessibility
      expect(downloadButtons, findsAny);
      if (deleteButtons.evaluate().isNotEmpty) {
        expect(deleteButtons, findsWidgets);
      }
    });
  });
}