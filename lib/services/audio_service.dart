import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import '../config/app_constants.dart';
import '../utils/app_logger.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentRecordingPath;
  bool _isRecording = false;

  Future<bool> checkPermissions() async {
    final microphoneStatus = await Permission.microphone.status;
    if (microphoneStatus != PermissionStatus.granted) {
      final result = await Permission.microphone.request();
      return result == PermissionStatus.granted;
    }
    return true;
  }

  Future<void> startRecording() async {
    try {
      if (_isRecording) {
        await stopRecording();
      }

      // Check permissions
      if (!await checkPermissions()) {
        throw Exception('Microphone permission not granted');
      }

      // Get temporary directory for audio files
      final Directory tempDir = await getTemporaryDirectory();
      final String audioDir = path.join(tempDir.path, 'recordings');
      
      // Create audio directory if it doesn't exist
      final Directory audioDirPath = Directory(audioDir);
      if (!await audioDirPath.exists()) {
        await audioDirPath.create(recursive: true);
      }

      // Generate unique filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = '${AppConstants.tempRecordingPrefix}$timestamp${AppConstants.recordingFileExtension}';
      _currentRecordingPath = path.join(audioDir, fileName);

      // Configure recording settings for Whisper compatibility
      const RecordConfig config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000, // Whisper prefers 16kHz
        bitRate: 256000,
        numChannels: 1, // Mono
      );

      // Start recording
      await _recorder.start(config, path: _currentRecordingPath!);
      _isRecording = true;

    } catch (e) {
      _isRecording = false;
      _currentRecordingPath = null;
      throw Exception('Failed to start recording: $e');
    }
  }

  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        return null;
      }

      // Stop recording
      final String? recordedPath = await _recorder.stop();
      _isRecording = false;

      if (recordedPath == null || _currentRecordingPath == null) {
        throw Exception('Recording failed - no audio data');
      }

      // Verify the file exists and has content
      final File audioFile = File(_currentRecordingPath!);
      if (!await audioFile.exists()) {
        throw Exception('Recording failed - audio file not found');
      }

      final int fileSize = await audioFile.length();
      if (fileSize == 0) {
        throw Exception('Recording failed - audio file is empty');
      }

      return _currentRecordingPath;
    } catch (e) {
      _isRecording = false;
      throw Exception('Failed to stop recording: $e');
    }
  }

  Future<bool> isRecording() async {
    return _isRecording && await _recorder.isRecording();
  }

  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.cancel();
        _isRecording = false;
      }

      // Clean up current recording file
      if (_currentRecordingPath != null) {
        final File audioFile = File(_currentRecordingPath!);
        if (await audioFile.exists()) {
          await audioFile.delete();
        }
        _currentRecordingPath = null;
      }
    } catch (e) {
      // Log error but don't throw - cleanup should be resilient
      AppLogger.error('Error during recording cleanup', error: e);
    }
  }

  Future<List<String>> getRecordingHistory() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String audioDir = path.join(tempDir.path, 'recordings');
      final Directory audioDirPath = Directory(audioDir);

      if (!await audioDirPath.exists()) {
        return [];
      }

      final List<FileSystemEntity> files = await audioDirPath.list().toList();
      return files
          .where((file) => file is File && file.path.endsWith('.wav'))
          .map((file) => file.path)
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearRecordingHistory() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String audioDir = path.join(tempDir.path, 'recordings');
      final Directory audioDirPath = Directory(audioDir);

      if (await audioDirPath.exists()) {
        await audioDirPath.delete(recursive: true);
      }
    } catch (e) {
      AppLogger.error('Error clearing recording history', error: e);
    }
  }

  String? getCurrentRecordingPath() {
    return _currentRecordingPath;
  }

  void dispose() {
    _recorder.dispose();
  }
}