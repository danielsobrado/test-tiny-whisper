import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/audio_service.dart';
import '../services/whisper_service.dart';
import '../widgets/model_download_widget.dart';
import '../widgets/model_management_widget.dart';
import '../widgets/audio_recorder_widget.dart';
import '../widgets/transcription_display_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioService _audioService = AudioService();
  final WhisperService _whisperService = WhisperService();
  
  String? _currentModelPath;
  String? _modelToReplace;
  String _transcriptionText = '';
  String _selectedLanguage = 'auto';
  bool _isRecording = false;
  bool _isTranscribing = false;
  List<String> _supportedLanguages = [];
  final GlobalKey _downloadWidgetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _loadSupportedLanguages();
  }
  
  Future<void> _loadSupportedLanguages() async {
    try {
      final languages = await _whisperService.getSupportedLanguages();
      setState(() {
        _supportedLanguages = languages;
      });
    } catch (e) {
      print('Failed to load supported languages: $e');
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.microphone,
      Permission.storage,
    ].request();
  }

  void _onModelDownloaded(String modelPath) {
    setState(() {
      _currentModelPath = modelPath;
      _modelToReplace = null; // Clear replace mode
    });
  }
  
  void _onModelSelected(String modelPath) {
    setState(() {
      _currentModelPath = modelPath;
    });
  }
  
  void _onModelDeleted() {
    setState(() {
      _currentModelPath = null;
    });
  }
  
  void _onModelReplace(String modelPath) {
    setState(() {
      _modelToReplace = modelPath;
    });
    _showSnackBar('Replace mode activated. Download a new model to replace the selected one.');
  }
  
  void _onModelReplaced() {
    setState(() {
      _modelToReplace = null;
    });
  }

  Future<void> _startRecording() async {
    if (_currentModelPath == null) {
      _showSnackBar('Please download a model first');
      return;
    }

    setState(() {
      _isRecording = true;
      _transcriptionText = '';
    });

    await _audioService.startRecording();
  }

  Future<void> _stopRecording() async {
    setState(() {
      _isRecording = false;
      _isTranscribing = true;
    });

    final audioPath = await _audioService.stopRecording();
    
    if (audioPath != null && _currentModelPath != null) {
      try {
        final transcription = await _whisperService.transcribe(
          audioPath: audioPath,
          modelPath: _currentModelPath!,
          language: _selectedLanguage == 'auto' ? null : _selectedLanguage,
        );
        
        setState(() {
          _transcriptionText = transcription;
        });
      } catch (e) {
        _showSnackBar('Transcription failed: $e');
      }
    }

    setState(() {
      _isTranscribing = false;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Tiny Whisper Tester'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Model Download Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ModelDownloadWidget(
                      key: _downloadWidgetKey,
                      onModelDownloaded: _onModelDownloaded,
                      onModelReplaced: _onModelReplaced,
                      replaceModelPath: _modelToReplace,
                    ),
                    if (_modelToReplace != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.orange.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Replace mode: Next download will replace the selected model',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _modelToReplace = null;
                                });
                              },
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Model Management Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ModelManagementWidget(
                  currentModelPath: _currentModelPath,
                  onModelSelected: _onModelSelected,
                  onModelDeleted: _onModelDeleted,
                  onModelReplace: _onModelReplace,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Current Model Status & Language Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Model:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentModelPath ?? 'No model loaded',
                      style: TextStyle(
                        color: _currentModelPath != null 
                            ? Colors.green 
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Language:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedLanguage,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _supportedLanguages.map((String language) {
                        return DropdownMenuItem<String>(
                          value: language,
                          child: Text(language == 'auto' ? 'Auto-detect' : language.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedLanguage = newValue;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Audio Recording Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: AudioRecorderWidget(
                  isRecording: _isRecording,
                  isTranscribing: _isTranscribing,
                  onStartRecording: _startRecording,
                  onStopRecording: _stopRecording,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Transcription Display
            Card(
              child: Container(
                height: 200,
                padding: const EdgeInsets.all(16.0),
                child: TranscriptionDisplayWidget(
                  transcriptionText: _transcriptionText,
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}