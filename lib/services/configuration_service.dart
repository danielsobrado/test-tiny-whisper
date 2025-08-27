import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../config/app_constants.dart';
import '../utils/app_logger.dart';
import '../utils/app_exceptions.dart';

/// Service for managing application configuration and settings
class ConfigurationService {
  static const String _configFileName = 'app_config.json';
  static ConfigurationService? _instance;
  
  Map<String, dynamic> _config = {};
  bool _isInitialized = false;
  
  ConfigurationService._();
  
  /// Get singleton instance
  static ConfigurationService get instance {
    _instance ??= ConfigurationService._();
    return _instance!;
  }
  
  /// Initialize configuration service
  Future<void> initialize() async {
    AppLogger.logMethodEntry('ConfigurationService', 'initialize');
    
    try {
      await _loadConfiguration();
      _isInitialized = true;
      AppLogger.info('Configuration service initialized successfully');
      AppLogger.logMethodExit('ConfigurationService', 'initialize', result: 'Success');
    } catch (e) {
      AppLogger.error('Failed to initialize configuration service', error: e);
      throw ConfigurationException(
        'Failed to initialize configuration service',
        details: 'Could not load or create configuration file',
        originalError: e,
      );
    }
  }
  
  /// Load configuration from file or create default
  Future<void> _loadConfiguration() async {
    try {
      final File configFile = await _getConfigFile();
      
      if (await configFile.exists()) {
        AppLogger.info('Loading configuration from file: ${configFile.path}');
        final String content = await configFile.readAsString();
        _config = json.decode(content) as Map<String, dynamic>;
        AppLogger.info('Configuration loaded successfully');
      } else {
        AppLogger.info('No configuration file found, creating default configuration');
        _config = _createDefaultConfiguration();
        await _saveConfiguration();
      }
      
      // Validate configuration
      _validateConfiguration();
      
    } catch (e) {
      AppLogger.error('Error loading configuration', error: e);
      // Create default configuration on error
      _config = _createDefaultConfiguration();
      await _saveConfiguration();
    }
  }
  
  /// Create default configuration
  Map<String, dynamic> _createDefaultConfiguration() {
    return {
      'app': {
        'version': AppConstants.appVersion,
        'name': AppConstants.appName,
        'first_run': true,
        'last_updated': DateTime.now().toIso8601String(),
      },
      'logging': {
        'enable_debug_logs': AppConstants.Logging.enableDebugLogs,
        'enable_network_logs': AppConstants.Logging.enableNetworkLogs,
        'enable_model_logs': AppConstants.Logging.enableModelLogs,
        'enable_speech_logs': AppConstants.Logging.enableSpeechLogs,
        'enable_summarization_logs': AppConstants.Logging.enableSummarizationLogs,
        'enable_translation_logs': AppConstants.Logging.enableTranslationLogs,
      },
      'features': {
        'enable_pytorch_models': AppConstants.Features.enablePyTorchModels,
        'enable_offline_transcription': AppConstants.Features.enableOfflineTranscription,
        'enable_real_time_transcription': AppConstants.Features.enableRealTimeTranscription,
        'enable_model_download': AppConstants.Features.enableModelDownload,
        'enable_translation': AppConstants.Features.enableTranslation,
        'enable_summarization': AppConstants.Features.enableSummarization,
        'enable_audio_visualization': AppConstants.Features.enableAudioVisualization,
      },
      'network': {
        'receive_timeout_minutes': AppConstants.networkReceiveTimeout.inMinutes,
        'send_timeout_minutes': AppConstants.networkSendTimeout.inMinutes,
        'short_timeout_minutes': AppConstants.shortNetworkTimeout.inMinutes,
      },
      'speech': {
        'listen_duration_minutes': AppConstants.speechListenDuration.inMinutes,
        'pause_duration_seconds': AppConstants.speechPauseDuration.inSeconds,
        'confidence_threshold': AppConstants.languageDetectionConfidenceThreshold,
        'default_target_language': AppConstants.defaultTargetLanguage,
      },
      'ui': {
        'max_tab_count': AppConstants.maxTabCount,
        'initial_tab_index': AppConstants.initialTabIndex,
        'default_sound_level': AppConstants.defaultSoundLevel,
      },
      'user_preferences': {
        'selected_model_path': null,
        'selected_language': null,
        'selected_prompt_style': 'bullet_points',
        'auto_cleanup_recordings': true,
      }
    };
  }
  
  /// Validate configuration structure
  void _validateConfiguration() {
    final requiredSections = ['app', 'logging', 'features', 'network', 'speech', 'ui'];
    
    for (final section in requiredSections) {
      if (!_config.containsKey(section)) {
        throw ConfigurationException(
          'Invalid configuration: missing required section',
          details: 'Missing section: $section',
        );
      }
    }
    
    AppLogger.info('Configuration validation passed');
  }
  
  /// Save configuration to file
  Future<void> _saveConfiguration() async {
    try {
      final File configFile = await _getConfigFile();
      _config['app']['last_updated'] = DateTime.now().toIso8601String();
      
      final String jsonContent = const JsonEncoder.withIndent('  ').convert(_config);
      await configFile.writeAsString(jsonContent);
      
      AppLogger.info('Configuration saved to: ${configFile.path}');
    } catch (e) {
      AppLogger.error('Error saving configuration', error: e);
      throw ConfigurationException(
        'Failed to save configuration',
        details: 'Could not write to configuration file',
        originalError: e,
      );
    }
  }
  
  /// Get configuration file
  Future<File> _getConfigFile() async {
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    final String configPath = path.join(appDocumentsDir.path, _configFileName);
    return File(configPath);
  }
  
  /// Get configuration value
  T? getValue<T>(String key, {T? defaultValue}) {
    if (!_isInitialized) {
      AppLogger.warning('Configuration service not initialized, returning default value');
      return defaultValue;
    }
    
    final keys = key.split('.');
    dynamic current = _config;
    
    for (final k in keys) {
      if (current is Map<String, dynamic> && current.containsKey(k)) {
        current = current[k];
      } else {
        return defaultValue;
      }
    }
    
    return current as T?;
  }
  
  /// Set configuration value
  Future<void> setValue(String key, dynamic value) async {
    if (!_isInitialized) {
      throw ConfigurationException(
        'Configuration service not initialized',
        details: 'Call initialize() before setting values',
      );
    }
    
    final keys = key.split('.');
    Map<String, dynamic> current = _config;
    
    for (int i = 0; i < keys.length - 1; i++) {
      final k = keys[i];
      if (!current.containsKey(k)) {
        current[k] = <String, dynamic>{};
      }
      current = current[k] as Map<String, dynamic>;
    }
    
    current[keys.last] = value;
    
    AppLogger.info('Configuration value updated: $key = $value');
    await _saveConfiguration();
  }
  
  /// Get all configuration
  Map<String, dynamic> getAllConfiguration() {
    if (!_isInitialized) {
      throw ConfigurationException(
        'Configuration service not initialized',
        details: 'Call initialize() before accessing configuration',
      );
    }
    
    return Map<String, dynamic>.from(_config);
  }
  
  /// Reset configuration to defaults
  Future<void> resetToDefaults() async {
    AppLogger.info('Resetting configuration to defaults');
    
    _config = _createDefaultConfiguration();
    await _saveConfiguration();
    
    AppLogger.info('Configuration reset completed');
  }
  
  /// Check if this is the first run
  bool isFirstRun() {
    return getValue<bool>('app.first_run') ?? true;
  }
  
  /// Mark first run as completed
  Future<void> completeFirstRun() async {
    await setValue('app.first_run', false);
  }
  
  /// Get user preferences
  Map<String, dynamic> getUserPreferences() {
    return getValue<Map<String, dynamic>>('user_preferences') ?? {};
  }
  
  /// Update user preference
  Future<void> setUserPreference(String key, dynamic value) async {
    await setValue('user_preferences.$key', value);
  }
  
  /// Export configuration to string
  String exportConfiguration() {
    if (!_isInitialized) {
      throw ConfigurationException(
        'Configuration service not initialized',
        details: 'Call initialize() before exporting configuration',
      );
    }
    
    return const JsonEncoder.withIndent('  ').convert(_config);
  }
  
  /// Import configuration from string
  Future<void> importConfiguration(String jsonString) async {
    try {
      final Map<String, dynamic> importedConfig = json.decode(jsonString) as Map<String, dynamic>;
      
      // Validate imported configuration
      final tempConfig = _config;
      _config = importedConfig;
      _validateConfiguration();
      
      await _saveConfiguration();
      AppLogger.info('Configuration imported successfully');
      
    } catch (e) {
      AppLogger.error('Error importing configuration', error: e);
      throw ConfigurationException(
        'Failed to import configuration',
        details: 'Invalid configuration format or validation failed',
        originalError: e,
      );
    }
  }
  
  /// Dispose resources
  void dispose() {
    _config.clear();
    _isInitialized = false;
    AppLogger.info('Configuration service disposed');
  }
}