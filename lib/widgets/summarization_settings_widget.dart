import 'package:flutter/material.dart';
import '../services/summarization_service.dart';

class SummarizationSettingsWidget extends StatefulWidget {
  const SummarizationSettingsWidget({super.key});

  @override
  State<SummarizationSettingsWidget> createState() => _SummarizationSettingsWidgetState();
}

class _SummarizationSettingsWidgetState extends State<SummarizationSettingsWidget> {
  final SummarizationService _summarizationService = SummarizationService();
  List<String> _downloadedModels = [];
  final Map<String, double> _downloadProgress = {};
  Map<String, dynamic> _storageInfo = {};
  bool _isLoading = true;
  String? _currentModel;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadModels();
  }

  @override
  void dispose() {
    _summarizationService.dispose();
    super.dispose();
  }

  Future<void> _initializeAndLoadModels() async {
    try {
      await _summarizationService.initialize();
      await _loadDownloadedModels();
      await _loadStorageInfo();
      _loadCurrentModel();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing summarization service: $e')),
        );
      }
    }
  }

  Future<void> _loadDownloadedModels() async {
    try {
      final models = await _summarizationService.getDownloadedModels();
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

  Future<void> _loadStorageInfo() async {
    try {
      final info = await _summarizationService.getStorageInfo();
      if (mounted) {
        setState(() {
          _storageInfo = info;
        });
      }
    } catch (e) {
      print('Error loading storage info: $e');
    }
  }

  void _loadCurrentModel() {
    final modelInfo = _summarizationService.getCurrentModelInfo();
    if (modelInfo['name'] != 'None') {
      setState(() {
        _currentModel = modelInfo['name'];
      });
    }
  }

  Future<void> _downloadModel(String modelKey) async {
    setState(() {
      _downloadProgress[modelKey] = 0.0;
    });

    try {
      final success = await _summarizationService.downloadModel(
        modelKey,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress[modelKey] = progress;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _downloadProgress.remove(modelKey);
          if (success) {
            _downloadedModels.add(modelKey);
          }
        });

        await _loadStorageInfo(); // Refresh storage info

        if (success) {
          final modelInfo = SummarizationService.availableModels[modelKey];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${modelInfo?.name} downloaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          // If this is the first model downloaded, load it automatically
          if (_downloadedModels.length == 1) {
            await _loadModel(modelKey);
          }
        } else {
          final modelInfo = SummarizationService.availableModels[modelKey];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to download ${modelInfo?.name}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadProgress.remove(modelKey);
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

  Future<void> _deleteModel(String modelKey) async {
    try {
      final success = await _summarizationService.deleteModel(modelKey);
      if (mounted) {
        if (success) {
          setState(() {
            _downloadedModels.remove(modelKey);
            if (_currentModel?.contains(modelKey) == true) {
              _currentModel = null;
            }
          });
          
          await _loadStorageInfo(); // Refresh storage info
          
          final modelInfo = SummarizationService.availableModels[modelKey];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${modelInfo?.name} deleted'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          final modelInfo = SummarizationService.availableModels[modelKey];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete ${modelInfo?.name}'),
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

  Future<void> _loadModel(String modelKey) async {
    try {
      final success = await _summarizationService.loadModel(modelKey);
      if (mounted) {
        if (success) {
          final modelInfo = SummarizationService.availableModels[modelKey];
          setState(() {
            _currentModel = modelInfo?.name ?? modelKey;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${modelInfo?.name} loaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          final modelInfo = SummarizationService.availableModels[modelKey];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load ${modelInfo?.name}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading model: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading AI models...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'AI Summarization',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Download and manage Gemma 3 models for on-device AI text summarization. All processing happens locally for privacy.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                if (_currentModel != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: colorScheme.onPrimary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Active: $_currentModel',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Storage Info
          if (_storageInfo.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.storage_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Storage Used: ${_storageInfo['formattedSize']} • ${_storageInfo['modelCount']} models',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Models List
          Text(
            'Available Gemma Models',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          ...SummarizationService.availableModels.entries.map((entry) {
            final modelKey = entry.key;
            final modelInfo = entry.value;
            final isDownloaded = _downloadedModels.contains(modelKey);
            final isDownloading = _downloadProgress.containsKey(modelKey);
            final downloadProgress = _downloadProgress[modelKey] ?? 0.0;
            final isActive = _currentModel?.contains(modelInfo.name) == true;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Model header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: modelInfo.isDefault 
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.psychology_rounded,
                            color: modelInfo.isDefault 
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      modelInfo.name,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (modelInfo.isDefault) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: colorScheme.secondary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Default',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (isActive) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: colorScheme.tertiary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Active',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onTertiary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                modelInfo.description,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Model details
                    Row(
                      children: [
                        Icon(
                          Icons.storage_rounded,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Size: ${modelInfo.size}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.memory_rounded,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          modelInfo.format,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          isDownloaded ? Icons.check_circle_rounded : Icons.cloud_download_rounded,
                          size: 16,
                          color: isDownloaded ? Colors.green : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isDownloaded ? 'Downloaded' : 'Not downloaded',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDownloaded ? Colors.green : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Download progress
                    if (isDownloading) ...[
                      LinearProgressIndicator(value: downloadProgress),
                      const SizedBox(height: 8),
                      Text(
                        'Downloading... ${(downloadProgress * 100).toInt()}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Action buttons
                    Row(
                      children: [
                        if (isDownloaded && !isActive)
                          FilledButton.icon(
                            onPressed: () => _loadModel(modelKey),
                            icon: const Icon(Icons.play_arrow_rounded, size: 18),
                            label: const Text('Load Model'),
                          ),
                        if (isDownloaded && !isActive) const SizedBox(width: 12),
                        if (!isDownloaded && !isDownloading)
                          FilledButton.icon(
                            onPressed: () => _downloadModel(modelKey),
                            icon: const Icon(Icons.cloud_download_rounded, size: 18),
                            label: const Text('Download'),
                          ),
                        if (isDownloaded && !isActive) ...[
                          const Spacer(),
                          IconButton(
                            onPressed: () => _showDeleteConfirmation(modelKey, modelInfo.name),
                            icon: const Icon(Icons.delete_outline_rounded),
                            tooltip: 'Delete model',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String modelKey, String modelName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete AI Model'),
          content: Text(
            'Are you sure you want to delete "$modelName"?\n\n'
            'This will free up storage space but you will need to download it again to use AI summarization.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteModel(modelKey);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}