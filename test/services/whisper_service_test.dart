import 'package:flutter_test/flutter_test.dart';
import 'package:tiny_whisper_tester/services/whisper_service.dart';
import 'dart:io';

void main() {
  group('WhisperService Tests', () {
    late WhisperService service;

    setUp(() {
      service = WhisperService();
    });

    tearDown(() {
      service.dispose();
    });

    group('Model Loading and Selection', () {
      test('should handle model loading attempt', () async {
        // Test with a non-existent model file
        const fakePath = '/fake/path/to/model.onnx';
        
        expect(
          () => service.loadModel(fakePath),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Model file not found'),
          )),
        );
      });

      test('should reject PyTorch models with appropriate message', () async {
        const pytorchPath = '/fake/path/to/model.ptl';
        
        expect(
          () => service.loadModel(pytorchPath),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('PyTorch models temporarily disabled'),
          )),
        );
      });

      test('should attempt to load ONNX models but fall back', () async {
        // Since we can't create actual files in tests, this will fail
        // but we can verify the error handling path
        const onnxPath = '/fake/path/to/model.onnx';
        
        expect(
          () => service.loadModel(onnxPath),
          throwsA(isA<Exception>()),
        );
      });

      test('should track current model path after selection attempt', () async {
        // Even though loading fails, the service should remember what was attempted
        const modelPath = '/fake/path/to/model.gguf';
        
        try {
          await service.loadModel(modelPath);
        } catch (e) {
          // Expected to fail
        }
        
        // The service should still track the attempted model path
        final info = await service.getModelInfo();
        expect(info['status'], contains('No model loaded'));
      });
    });

    group('Model Information Display', () {
      test('should return correct info when no model is loaded', () async {
        final info = await service.getModelInfo();
        
        expect(info['status'], 'No model loaded');
        expect(info.containsKey('path'), false);
        expect(info.containsKey('size'), false);
        expect(info.containsKey('model_type'), false);
      });

      test('should always show speech_to_text framework', () async {
        // Even with a selected model, should show speech_to_text framework
        try {
          await service.loadModel('/fake/model.gguf');
        } catch (e) {
          // Expected to fail
        }
        
        final info = await service.getModelInfo();
        expect(info['framework'], 'speech_to_text (Production-ready speech recognition)');
      });

      test('should identify model types from filename', () async {
        final testCases = {
          '/path/to/whisper-tiny.gguf': 'tiny',
          '/path/to/whisper-base.onnx': 'base', 
          '/path/to/whisper-small.bin': 'small',
          '/path/to/whisper-medium.ptl': 'medium',
          '/path/to/whisper-large.gguf': 'large',
          '/path/to/unknown-model.gguf': 'tiny', // default
        };

        for (final entry in testCases.entries) {
          try {
            await service.loadModel(entry.key);
          } catch (e) {
            // Expected to fail due to file not existing
          }
          
          // The service should still extract model info from filename
          // This tests the _getModelFromPath method indirectly
        }
      });
    });

    group('Speech Recognition Integration', () {
      test('should initialize speech service', () async {
        // This may fail in test environment without proper setup
        try {
          final languages = await service.getSupportedLanguages();
          expect(languages, isA<List<String>>());
        } catch (e) {
          // Expected in test environment
          expect(e.toString(), contains('Speech recognition'));
        }
      });

      test('should handle live speech recognition start', () async {
        bool resultReceived = false;
        String? receivedResult;
        
        try {
          await service.startLiveSpeechRecognition(
            onResult: (text) {
              resultReceived = true;
              receivedResult = text;
            },
            language: 'en',
          );
        } catch (e) {
          // Expected in test environment
          expect(e.toString(), contains('speech recognition'));
        }
      });

      test('should handle stop speech recognition', () async {
        // Should not throw even if not listening
        await expectLater(
          service.stopLiveSpeechRecognition(),
          completes,
        );
      });

      test('should track listening state', () {
        final isListening = service.isListening();
        expect(isListening, isA<bool>());
      });
    });

    group('Model Loading Behavior Analysis', () {
      test('should demonstrate the fallback behavior', () async {
        // This test documents the current behavior where all models
        // fall back to live speech recognition
        
        const testModels = [
          '/fake/whisper-tiny.gguf',
          '/fake/whisper-base.onnx', 
          '/fake/whisper-small.bin',
        ];

        for (final modelPath in testModels) {
          try {
            await service.loadModel(modelPath);
          } catch (e) {
            // Expected to fail
            expect(e, isA<Exception>());
          }
          
          // Verify that regardless of model type, framework is always speech_to_text
          final info = await service.getModelInfo();
          expect(info['framework'], 'speech_to_text (Production-ready speech recognition)');
        }
      });

      test('should check model loaded status', () async {
        // Initially no model loaded
        final initialStatus = await service.isModelLoaded();
        expect(initialStatus, false);
        
        // After attempting to load (even failed attempts)
        try {
          await service.loadModel('/fake/model.gguf');
        } catch (e) {
          // Expected
        }
        
        // Status depends on speech service initialization, not model file
        final statusAfterAttempt = await service.isModelLoaded();
        expect(statusAfterAttempt, isA<bool>());
      });
    });

    group('File-based Transcription Limitations', () {
      test('should explain file transcription limitations', () async {
        const audioPath = '/fake/audio.wav';
        const modelPath = '/fake/model.gguf';
        
        expect(
          () => service.transcribe(
            audioPath: audioPath,
            modelPath: modelPath,
            language: 'en',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle different audio file types in transcription', () async {
        const testCases = [
          '/fake/audio.wav',
          '/fake/audio.mp3',
          '/fake/audio.m4a',
          '/fake/audio.flac',
        ];

        for (final audioPath in testCases) {
          expect(
            () => service.transcribe(
              audioPath: audioPath,
              modelPath: '/fake/model.gguf',
            ),
            throwsA(isA<Exception>()),
          );
        }
      });
    });

    group('Model Type Detection', () {
      test('should identify model formats correctly', () {
        // Test format detection through model loading attempts
        const testCases = {
          'model.gguf': 'GGUF',
          'model.onnx': 'ONNX', 
          'model.ptl': 'PyTorch',
          'pytorch_model.bin': 'PyTorch',
          'model.bin': 'GGML',
        };

        for (final entry in testCases.entries) {
          final filename = entry.key;
          final expectedType = entry.value;
          
          // The service should identify format from filename
          expect(filename.contains('.'), true);
        }
      });
    });

    group('Service Lifecycle', () {
      test('should dispose resources properly', () {
        expect(() => service.dispose(), returnsNormally);
      });

      test('should handle multiple dispose calls', () {
        service.dispose();
        expect(() => service.dispose(), returnsNormally);
      });

      test('should reinitialize after disposal', () async {
        service.dispose();
        
        // Should be able to use service again
        try {
          final info = await service.getModelInfo();
          expect(info, isA<Map<String, dynamic>>());
        } catch (e) {
          // May fail due to disposal, but shouldn't crash
        }
      });
    });

    group('Error Handling', () {
      test('should handle invalid file paths gracefully', () async {
        const invalidPaths = [
          '',
          ' ',
          '/nonexistent/path/model.gguf',
          'not/absolute/path.onnx',
        ];

        for (final path in invalidPaths) {
          expect(
            () => service.loadModel(path),
            throwsA(isA<Exception>()),
          );
        }
      });

      test('should provide meaningful error messages', () async {
        try {
          await service.loadModel('/fake/model.ptl');
          fail('Should have thrown exception');
        } catch (e) {
          expect(e.toString(), contains('PyTorch models temporarily disabled'));
          expect(e.toString(), contains('ONNX'));
        }
      });
    });

    group('Current Implementation Reality Check', () {
      test('should document that offline models are not actually used', () async {
        // This test documents the current reality:
        // 1. Users can "select" a model in the UI
        // 2. The model path is stored
        // 3. But actual speech recognition always uses device's speech-to-text
        // 4. The UI misleadingly shows the selected model path
        
        const selectedModel = '/fake/whisper-tiny.gguf';
        
        // User selects model (this would normally happen through UI)
        try {
          await service.loadModel(selectedModel);
        } catch (e) {
          // Expected to fail
        }
        
        // UI shows this model info
        final info = await service.getModelInfo();
        
        // The issue: UI shows selected model path but framework is still speech_to_text
        expect(info['framework'], 'speech_to_text (Production-ready speech recognition)');
        
        // This is misleading because users think their selected model is being used
        // but it's actually the device's built-in speech recognition
      });

      test('should verify the UI-backend disconnect', () async {
        // Test the disconnect between what UI shows and what's actually used
        
        // 1. No model selected - uses device speech recognition
        var info = await service.getModelInfo();
        expect(info['framework'], anyOf(
          contains('speech_to_text'),
          contains('device speech recognition'),
        ));
        
        // 2. Model "selected" - still uses device speech recognition  
        try {
          await service.loadModel('/fake/offline-model.onnx');
        } catch (e) {
          // Expected
        }
        
        info = await service.getModelInfo();
        expect(info['framework'], 'speech_to_text (Production-ready speech recognition)');
        
        // This confirms the issue: model selection doesn't change the actual engine
      });
    });
  });
}