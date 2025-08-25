import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/audio_service.dart';
import '../services/whisper_service.dart';
import '../widgets/model_download_widget.dart';
import '../widgets/model_management_widget.dart';
import '../widgets/audio_recorder_widget.dart';
import '../widgets/transcription_display_widget.dart';
import '../widgets/language_management_widget.dart';
import '../widgets/summarization_settings_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final AudioService _audioService = AudioService();
  final WhisperService _whisperService = WhisperService();
  
  String? _currentModelPath;
  String? _modelToReplace;
  String _transcriptionText = '';
  String? _selectedLanguage;
  bool _isRecording = false;
  bool _isTranscribing = false;
  double _currentSoundLevel = 0.0;
  List<String> _supportedLanguages = [];
  final GlobalKey _downloadWidgetKey = GlobalKey();
  
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    _requestPermissions();
    _loadSupportedLanguages();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _audioService.dispose();
    super.dispose();
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
    // Check current permissions
    Map<Permission, PermissionStatus> permissions = await [
      Permission.microphone,
      Permission.storage,
    ].request();
    
    // Handle denied permissions
    if (permissions[Permission.microphone]?.isDenied == true) {
      _showPermissionDialog(
        'Microphone Permission Required',
        'This app needs microphone access to record your voice for speech recognition.',
        Permission.microphone,
      );
    }
    
    if (permissions[Permission.storage]?.isDenied == true) {
      _showPermissionDialog(
        'Storage Permission Required',
        'This app needs storage access to download and manage speech recognition models.',
        Permission.storage,
      );
    }
  }
  
  void _showPermissionDialog(String title, String message, Permission permission) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                // Check if permission is permanently denied
                if (await permission.isPermanentlyDenied) {
                  // Open app settings
                  openAppSettings();
                } else {
                  // Request permission again
                  await permission.request();
                }
              },
              child: const Text('Grant Permission'),
            ),
          ],
        );
      },
    );
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
    // Check microphone permission before starting
    final micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      _showPermissionDialog(
        'Microphone Permission Required',
        'Please grant microphone permission to use speech recognition.',
        Permission.microphone,
      );
      return;
    }

    setState(() {
      _isRecording = true;
      _transcriptionText = '';
    });

    // Start live speech recognition
    try {
      print('Starting speech recognition from UI...');
      
      final transcription = await _whisperService.startLiveSpeechRecognition(
        language: _selectedLanguage,
        onResult: (text) {
          print('Home screen received transcription: "$text"');
          if (text.isNotEmpty) {
            setState(() {
              _transcriptionText = text;
            });
          }
        },
        onSoundLevelChange: (level) {
          print('Home screen received sound level: $level'); // Debug logging
          setState(() {
            _currentSoundLevel = level;
          });
        },
        onListeningStopped: () {
          print('Speech recognition stopped from callback');
          setState(() {
            _isRecording = false;
            _currentSoundLevel = 0.0;
          });
          _showSnackBar('Listening stopped. Tap Start to continue.');
        },
      );
      
      print('Speech recognition started successfully');
      _showSnackBar('Speech recognition started. Start speaking...');
      
    } catch (e) {
      print('Error starting speech recognition: $e');
      _showSnackBar('Failed to start speech recognition: $e\n\nEnsure Google Speech Services is enabled on your device.');
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _stopRecording() async {
    setState(() {
      _isRecording = false;
      _currentSoundLevel = 0.0;
    });

    // Stop live speech recognition
    try {
      await _whisperService.stopLiveSpeechRecognition();
    } catch (e) {
      _showSnackBar('Failed to stop speech recognition: $e');
    }
  }

  void _onLanguageDetected(String? detectedLanguageCode) {
    if (detectedLanguageCode != null && 
        _supportedLanguages.contains(detectedLanguageCode) && 
        detectedLanguageCode != _selectedLanguage) {
      setState(() {
        _selectedLanguage = detectedLanguageCode;
      });
      _showSnackBar('Language auto-updated to: ${detectedLanguageCode.toUpperCase()}');
    }
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
        title: const Text('Tiny Whisper Tester'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.mic_rounded), text: 'Speech'),
            Tab(icon: Icon(Icons.storage_rounded), text: 'Models'),
            Tab(icon: Icon(Icons.translate_rounded), text: 'Languages'),
            Tab(icon: Icon(Icons.settings_rounded), text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSpeechTab(),
          _buildModelsTab(),
          _buildLanguagesTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildSpeechTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Current Model Status & Language Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.settings_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Current Model',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                    FutureBuilder<Map<String, dynamic>>(
                      future: _whisperService.getModelInfo(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final info = snapshot.data!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentModelPath ?? 'No model file selected',
                                style: TextStyle(
                                  color: _currentModelPath != null ? Colors.green : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                info['framework'] ?? 'Using device speech recognition',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                ),
                              ),
                              if (_currentModelPath != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Status: ${info['status'] ?? 'Unknown'}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          );
                        } else {
                          return const Text(
                            'Using device speech recognition (no model file needed)',
                            style: TextStyle(
                              color: Colors.blue,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(
                          Icons.language_rounded,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Language',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedLanguage,
                      decoration: const InputDecoration(
                        hintText: 'Select language',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Auto-detect'),
                        ),
                        ..._supportedLanguages.map((String language) {
                          return DropdownMenuItem<String>(
                            value: language,
                            child: Text(language.toUpperCase()),
                          );
                        }),
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedLanguage = newValue;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Audio Recording Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: AudioRecorderWidget(
                  isRecording: _isRecording,
                  isTranscribing: _isTranscribing,
                  onStartRecording: _startRecording,
                  onStopRecording: _stopRecording,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Transcription Display with Translation
            Card(
              child: Container(
                constraints: const BoxConstraints(minHeight: 300),
                padding: const EdgeInsets.all(20.0),
                child: TranscriptionDisplayWidget(
                  transcriptionText: _transcriptionText,
                  showTranslation: true,
                  onLanguageDetected: _onLanguageDetected,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildModelsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            // Model Download Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
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
            const SizedBox(height: 24),
            
            // Model Management Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: ModelManagementWidget(
                  currentModelPath: _currentModelPath,
                  onModelSelected: _onModelSelected,
                  onModelDeleted: _onModelDeleted,
                  onModelReplace: _onModelReplace,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguagesTab() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: LanguageManagementWidget(),
    );
  }

  Widget _buildSettingsTab() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SummarizationSettingsWidget(),
    );
  }
}