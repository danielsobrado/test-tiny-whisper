import 'package:flutter/material.dart';
import '../services/model_download_service.dart';

class ModelDownloadWidget extends StatefulWidget {
  final Function(String) onModelDownloaded;
  final Function()? onModelReplaced;
  final String? replaceModelPath;

  const ModelDownloadWidget({
    super.key,
    required this.onModelDownloaded,
    this.onModelReplaced,
    this.replaceModelPath,
  });

  @override
  State<ModelDownloadWidget> createState() => _ModelDownloadWidgetState();
}

class _ModelDownloadWidgetState extends State<ModelDownloadWidget> {
  final TextEditingController _urlController = TextEditingController();
  final ModelDownloadService _downloadService = ModelDownloadService();
  
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _downloadStatus;

  @override
  void initState() {
    super.initState();
    // Example HuggingFace URL
    _urlController.text = 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin';
  }

  Future<void> _downloadModel() async {
    if (_urlController.text.trim().isEmpty) {
      _showSnackBar('Please enter a valid HuggingFace URL');
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadStatus = 'Starting download...';
    });

    try {
      final modelPath = await _downloadService.downloadModel(
        url: _urlController.text.trim(),
        replaceModelPath: widget.replaceModelPath,
        onProgress: (progress, status) {
          setState(() {
            _downloadProgress = progress;
            _downloadStatus = status;
          });
        },
      );

      setState(() {
        _downloadStatus = 'Download completed successfully!';
      });

      widget.onModelDownloaded(modelPath);
      
      // Check if this was a replacement
      if (_downloadStatus?.contains('Replacing') == true) {
        widget.onModelReplaced?.call();
        _showSnackBar('Model replaced successfully');
      } else {
        _showSnackBar('Model downloaded successfully');
      }
      
    } catch (e) {
      setState(() {
        _downloadStatus = 'Download failed: $e';
      });
      _showSnackBar('Download failed: $e');
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
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
        const Text(
          'Download Whisper Model',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        TextField(
          controller: _urlController,
          decoration: const InputDecoration(
            labelText: 'HuggingFace Model URL',
            hintText: 'https://huggingface.co/...',
            border: OutlineInputBorder(),
          ),
          enabled: !_isDownloading,
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        
        if (_isDownloading) ...[
          LinearProgressIndicator(
            value: _downloadProgress > 0 ? _downloadProgress : null,
          ),
          const SizedBox(height: 8),
          Text(
            _downloadStatus ?? '',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
        ],
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isDownloading ? null : _downloadModel,
            child: Text(_isDownloading ? 'Downloading...' : 'Download Model'),
          ),
        ),
        
        const SizedBox(height: 8),
        const Text(
          'Supported formats: GGML (.bin), GGUF (.gguf), PyTorch (.ptl, pytorch_model.bin)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}