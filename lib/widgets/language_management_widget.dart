import 'package:flutter/material.dart';
import '../services/translation_service.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class LanguageManagementWidget extends StatefulWidget {
  const LanguageManagementWidget({super.key});

  @override
  State<LanguageManagementWidget> createState() => _LanguageManagementWidgetState();
}

class _LanguageManagementWidgetState extends State<LanguageManagementWidget> {
  final TranslationService _translationService = TranslationService();
  Set<String> _downloadedModels = {};
  final Set<String> _downloadingModels = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadModels();
  }

  @override
  void dispose() {
    _translationService.dispose();
    super.dispose();
  }

  Future<void> _initializeAndLoadModels() async {
    try {
      await _translationService.initialize();
      await _loadDownloadedModels();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing translation service: $e')),
        );
      }
    }
  }

  Future<void> _loadDownloadedModels() async {
    try {
      final models = await _translationService.getDownloadedModels();
      if (mounted) {
        setState(() {
          _downloadedModels = models;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading models: $e')),
        );
      }
    }
  }

  Future<void> _downloadModel(String languageCode) async {
    setState(() {
      _downloadingModels.add(languageCode);
    });

    try {
      final success = await _translationService.downloadModel(languageCode);
      if (mounted) {
        setState(() {
          _downloadingModels.remove(languageCode);
          if (success) {
            _downloadedModels.add(languageCode);
          }
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_translationService.getLanguageName(languageCode)} model downloaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to download ${_translationService.getLanguageName(languageCode)} model'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadingModels.remove(languageCode);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading model: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteModel(String languageCode) async {
    try {
      final success = await _translationService.deleteModel(languageCode);
      if (mounted) {
        if (success) {
          setState(() {
            _downloadedModels.remove(languageCode);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_translationService.getLanguageName(languageCode)} model deleted'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete ${_translationService.getLanguageName(languageCode)} model'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting model: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<TranslateLanguage> _getSortedLanguages() {
    final languages = _translationService.getAvailableLanguages().toList();
    languages.sort((a, b) => _translationService.getLanguageName(a.bcpCode)
        .compareTo(_translationService.getLanguageName(b.bcpCode)));
    return languages;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading language models...'),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.translate, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  const Text(
                    'Translation Language Models',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Download language models for offline translation. Models are used to automatically translate non-English speech to English.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Downloaded: ${_downloadedModels.length} models',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Language list
        Expanded(
          child: ListView.separated(
            itemCount: _getSortedLanguages().length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final language = _getSortedLanguages()[index];
              final languageCode = language.bcpCode;
              final languageName = _translationService.getLanguageName(languageCode);
              final isDownloaded = _downloadedModels.contains(languageCode);
              final isDownloading = _downloadingModels.contains(languageCode);
              final isEnglish = languageCode == 'en';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isEnglish 
                      ? Colors.green[100]
                      : isDownloaded 
                          ? Colors.blue[100] 
                          : Colors.grey[200],
                  child: Icon(
                    isEnglish
                        ? Icons.star
                        : isDownloaded 
                            ? Icons.check 
                            : Icons.language,
                    color: isEnglish
                        ? Colors.green[700]
                        : isDownloaded 
                            ? Colors.blue[700] 
                            : Colors.grey[600],
                    size: 20,
                  ),
                ),
                
                title: Text(
                  languageName,
                  style: TextStyle(
                    fontWeight: isEnglish ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Code: ${languageCode.toUpperCase()}'),
                    if (isEnglish)
                      Text(
                        'Default target language',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else if (isDownloaded)
                      Text(
                        'Ready for translation',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                        ),
                      )
                    else
                      Text(
                        'Not downloaded',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                
                trailing: isEnglish
                    ? Icon(Icons.star, color: Colors.green[700])
                    : isDownloading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : isDownloaded
                            ? IconButton(
                                onPressed: () => _showDeleteConfirmation(languageCode, languageName),
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Delete model',
                              )
                            : IconButton(
                                onPressed: () => _downloadModel(languageCode),
                                icon: const Icon(Icons.download),
                                tooltip: 'Download model',
                              ),
                
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(String languageCode, String languageName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Language Model'),
          content: Text(
            'Are you sure you want to delete the $languageName language model?\n\n'
            'You will need to download it again to use translation for this language.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteModel(languageCode);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}