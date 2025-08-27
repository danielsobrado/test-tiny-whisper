import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import '../config/app_constants.dart';
import '../utils/app_logger.dart';
import '../services/audio_service.dart';
import '../services/whisper_service.dart';
import '../widgets/model_download_widget.dart';
import '../widgets/model_management_widget.dart';
import '../widgets/audio_recorder_widget.dart';
import '../widgets/transcription_display_widget.dart';
import '../widgets/language_management_widget.dart';
import '../widgets/summarization_settings_widget.dart';
import '../widgets/summarization_prompts_widget.dart';

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
  final bool _isTranscribing = false;
  double _currentSoundLevel = AppConstants.defaultSoundLevel;
  List<String> _supportedLanguages = [];
  final GlobalKey _downloadWidgetKey = GlobalKey();
  
  late TabController _tabController;
  int _currentTabIndex = AppConstants.initialTabIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: AppConstants.maxTabCount, vsync: this);
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
    AppLogger.logMethodEntry('HomeScreen', '_loadSupportedLanguages');
    try {
      final languages = await _whisperService.getSupportedLanguages();
      setState(() {
        _supportedLanguages = languages;
      });
      AppLogger.uiInfo('Loaded ${languages.length} supported languages');
      AppLogger.logMethodExit('HomeScreen', '_loadSupportedLanguages', result: 'Success');
    } catch (e) {
      AppLogger.uiError('Failed to load supported languages', error: e);
    }
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> permissions = await [
      Permission.microphone,
      Permission.storage,
    ].request();
    
    if (permissions[Permission.microphone]?.isDenied == true) {
      _showPermissionDialog(
        'Microphone Permission Required',
        AppConstants.ErrorMessages.microphonePermissionRequired,
        Permission.microphone,
      );
    }
    
    if (permissions[Permission.storage]?.isDenied == true) {
      _showPermissionDialog(
        'Storage Permission Required',
        AppConstants.ErrorMessages.storagePermissionRequired,
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
                
                if (await permission.isPermanentlyDenied) {
                  openAppSettings();
                } else {
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
      _modelToReplace = null;
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
    _showSnackBar(AppConstants.SuccessMessages.replaceModeActivated);
  }
  
  void _onModelReplaced() {
    setState(() {
      _modelToReplace = null;
    });
  }

  Future<void> _startRecording() async {
    final micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      _showPermissionDialog(
        'Microphone Permission Required',
        AppConstants.ErrorMessages.microphonePermissionRequired,
        Permission.microphone,
      );
      return;
    }

    setState(() {
      _isRecording = true;
      _transcriptionText = '';
    });

    try {
      AppLogger.uiInfo('Starting speech recognition from UI...');
      
      final transcription = await _whisperService.startLiveSpeechRecognition(
        language: _selectedLanguage,
        onResult: (text) {
          AppLogger.uiInfo('Home screen received transcription: "$text"');
          if (text.isNotEmpty) {
            setState(() {
              _transcriptionText = text;
            });
          }
        },
        onSoundLevelChange: (level) {
          if (AppConstants.Logging.enableDebugLogs) {
            AppLogger.uiInfo('Home screen received sound level: $level');
          }
          setState(() {
            _currentSoundLevel = level;
          });
        },
        onListeningStopped: () {
          AppLogger.uiInfo('Speech recognition stopped from callback');
          setState(() {
            _isRecording = false;
            _currentSoundLevel = AppConstants.defaultSoundLevel;
          });
          _showSnackBar(AppConstants.SuccessMessages.listeningStopped);
        },
      );
      
      AppLogger.uiInfo('Speech recognition started successfully');
      _showSnackBar(AppConstants.SuccessMessages.speechRecognitionStarted);
      
    } catch (e) {
      AppLogger.uiError('Error starting speech recognition', error: e);
      _showSnackBar('${AppConstants.ErrorMessages.speechRecognitionFailed}: $e\n\nEnsure Google Speech Services is enabled on your device.');
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _stopRecording() async {
    setState(() {
      _isRecording = false;
      _currentSoundLevel = AppConstants.defaultSoundLevel;
    });

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
            Tab(icon: Icon(Icons.edit_note_rounded), text: 'Prompts'),
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
          _buildPromptsTab(),
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
                        final bool isOfflineActive = info['is_offline_active'] == true;
                        final bool fileExists = info['file_exists'] == true;
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Model file path display
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _currentModelPath != null 
                                        ? path.basename(_currentModelPath!) 
                                        : 'No model file selected',
                                    style: TextStyle(
                                      color: _currentModelPath != null && fileExists
                                          ? (isOfflineActive ? Colors.green : Colors.orange)
                                          : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (_currentModelPath != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isOfflineActive 
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.orange.withOpacity(0.1),
                                      border: Border.all(
                                        color: isOfflineActive ? Colors.green : Colors.orange,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isOfflineActive ? 'ACTIVE' : 'NOT USED',
                                      style: TextStyle(
                                        color: isOfflineActive ? Colors.green : Colors.orange,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Framework/Engine information
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isOfflineActive 
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isOfflineActive 
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.blue.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        isOfflineActive ? Icons.offline_bolt : Icons.cloud,
                                        size: 16,
                                        color: isOfflineActive ? Colors.green : Colors.blue,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          info['framework'] ?? 'Using device speech recognition',
                                          style: TextStyle(
                                            color: isOfflineActive ? Colors.green.shade700 : Colors.blue.shade700,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_currentModelPath != null && !isOfflineActive) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      info['offline_model_status'] ?? 'Offline model not active',
                                      style: TextStyle(
                                        color: Colors.orange.shade700,
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            
                            // Additional model details
                            if (_currentModelPath != null) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  if (info['model_format'] != null)
                                    _buildInfoChip('Format', info['model_format']),
                                  if (info['model_type'] != null)
                                    _buildInfoChip('Type', info['model_type']),
                                  if (info['size'] != null)
                                    _buildInfoChip('Size', _formatBytes(info['size'])),
                                ],
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
    );
  }

  Widget _buildLanguagesTab() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: LanguageManagementWidget(),
    );
  }

  Widget _buildPromptsTab() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SummarizationPromptsWidget(),
    );
  }

  Widget _buildSettingsTab() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SummarizationSettingsWidget(),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}