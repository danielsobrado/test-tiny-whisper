import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../services/model_download_service.dart';

class ModelManagementWidget extends StatefulWidget {
  final String? currentModelPath;
  final Function(String) onModelSelected;
  final Function() onModelDeleted;
  final Function(String)? onModelReplace;

  const ModelManagementWidget({
    super.key,
    this.currentModelPath,
    required this.onModelSelected,
    required this.onModelDeleted,
    this.onModelReplace,
  });

  @override
  State<ModelManagementWidget> createState() => _ModelManagementWidgetState();
}

class _ModelManagementWidgetState extends State<ModelManagementWidget> {
  final ModelDownloadService _downloadService = ModelDownloadService();
  List<String> _downloadedModels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloadedModels();
  }

  Future<void> _loadDownloadedModels() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final models = await _downloadService.getDownloadedModels();
      setState(() {
        _downloadedModels = models;
      });
    } catch (e) {
      _showSnackBar('Failed to load models: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteModel(String modelPath) async {
    final confirmed = await _showDeleteConfirmation(modelPath);
    if (!confirmed) return;

    try {
      await _downloadService.deleteModel(modelPath);
      await _loadDownloadedModels();
      
      // If the deleted model was the currently selected one, notify parent
      if (widget.currentModelPath == modelPath) {
        widget.onModelDeleted();
      }
      
      _showSnackBar('Model deleted successfully');
    } catch (e) {
      _showSnackBar('Failed to delete model: $e');
    }
  }

  Future<bool> _showDeleteConfirmation(String modelPath) async {
    final fileName = path.basename(modelPath);
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Model'),
          content: Text('Are you sure you want to delete "$fileName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<void> _showModelInfo(String modelPath) async {
    final info = await _downloadService.getModelInfo(modelPath);
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Model Information'),
          content: Text(info),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _getModelDisplayName(String modelPath) {
    String fileName = path.basename(modelPath);
    
    // Remove timestamp prefix if present (e.g., "1234567890_ggml-tiny.bin" -> "ggml-tiny.bin")
    if (fileName.contains('_')) {
      final parts = fileName.split('_');
      if (parts.length > 1 && RegExp(r'^\d+$').hasMatch(parts[0])) {
        fileName = parts.sublist(1).join('_');
      }
    }
    
    return fileName;
  }

  String _getModelType(String modelPath) {
    final fileName = _getModelDisplayName(modelPath).toLowerCase();
    
    if (fileName.contains('tiny')) return 'Tiny';
    if (fileName.contains('base')) return 'Base';
    if (fileName.contains('small')) return 'Small';
    if (fileName.contains('medium')) return 'Medium';
    if (fileName.contains('large')) return 'Large';
    
    return 'Unknown';
  }

  String _getModelFormat(String modelPath) {
    return _downloadService.getModelFormat(modelPath);
  }

  Color _getFormatColor(String format) {
    switch (format) {
      case 'GGUF':
        return Colors.purple;
      case 'GGML':
        return Colors.blue;
      case 'PyTorch':
        return Colors.orange;
      case 'Config':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Downloaded Models',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: _loadDownloadedModels,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh models list',
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_downloadedModels.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              children: [
                Icon(Icons.folder_open, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'No models downloaded yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Download a model using the form above',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _downloadedModels.length,
              itemBuilder: (context, index) {
                final modelPath = _downloadedModels[index];
                final fileName = _getModelDisplayName(modelPath);
                final modelType = _getModelType(modelPath);
                final isSelected = widget.currentModelPath == modelPath;
                
                return FutureBuilder<File>(
                  future: Future.value(File(modelPath)),
                  builder: (context, snapshot) {
                    final file = snapshot.data;
                    final fileSize = file?.lengthSync() ?? 0;
                    final modelFormat = _getModelFormat(modelPath);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isSelected ? Colors.green.shade50 : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? Colors.green : Colors.blue,
                          child: Text(
                            modelType[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                fileName,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getFormatColor(modelFormat).withOpacity(0.1),
                                border: Border.all(color: _getFormatColor(modelFormat)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                modelFormat,
                                style: TextStyle(
                                  color: _getFormatColor(modelFormat),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Type: $modelType'),
                            Text('Size: ${_formatFileSize(fileSize)}'),
                            if (isSelected)
                              const Text(
                                'Currently selected',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'select':
                                widget.onModelSelected(modelPath);
                                break;
                              case 'info':
                                _showModelInfo(modelPath);
                                break;
                              case 'replace':
                                widget.onModelReplace?.call(modelPath);
                                break;
                              case 'delete':
                                _deleteModel(modelPath);
                                break;
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            if (!isSelected)
                              const PopupMenuItem<String>(
                                value: 'select',
                                child: ListTile(
                                  leading: Icon(Icons.check_circle),
                                  title: Text('Select'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            const PopupMenuItem<String>(
                              value: 'info',
                              child: ListTile(
                                leading: Icon(Icons.info),
                                title: Text('Info'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            if (widget.onModelReplace != null)
                              const PopupMenuItem<String>(
                                value: 'replace',
                                child: ListTile(
                                  leading: Icon(Icons.download, color: Colors.orange),
                                  title: Text('Replace', style: TextStyle(color: Colors.orange)),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete, color: Colors.red),
                                title: Text('Delete', style: TextStyle(color: Colors.red)),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                        onTap: isSelected ? null : () => widget.onModelSelected(modelPath),
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}