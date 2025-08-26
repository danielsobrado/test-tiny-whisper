import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class PyTorchModelDownloader {
  final Dio _dio = Dio();

  Future<String> downloadPyTorchModel({
    required String huggingFaceUrl,
    required Function(double progress, String status) onProgress,
  }) async {
    try {
      // Parse HuggingFace URL to extract repo info
      final repoInfo = _parseHuggingFaceUrl(huggingFaceUrl);
      if (repoInfo == null) {
        throw Exception('Invalid HuggingFace URL format');
      }

      onProgress(0.0, 'Analyzing PyTorch model repository...');

      // Get app documents directory
      final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
      final String modelsDir = path.join(appDocumentsDir.path, 'models');
      final Directory modelsDirPath = Directory(modelsDir);
      if (!await modelsDirPath.exists()) {
        await modelsDirPath.create(recursive: true);
      }

      // Create model-specific directory
      final String modelDir = path.join(modelsDir, '${repoInfo['repo']}_pytorch');
      final Directory modelDirPath = Directory(modelDir);
      if (await modelDirPath.exists()) {
        await modelDirPath.delete(recursive: true);
      }
      await modelDirPath.create(recursive: true);

      // List of essential PyTorch Whisper files
      final List<String> essentialFiles = [
        'pytorch_model.bin',
        'config.json',
        'preprocessor_config.json',
        'tokenizer.json',
        'vocab.json',
        'merges.txt',
        'normalizer.json',
      ];

      double totalProgress = 0;
      int completedFiles = 0;

      onProgress(0.1, 'Downloading PyTorch model files...');

      // Download each essential file
      for (String fileName in essentialFiles) {
        try {
          final String fileUrl = 'https://huggingface.co/${repoInfo['repo']}/resolve/main/$fileName';
          final String filePath = path.join(modelDir, fileName);

          await _dio.download(
            fileUrl,
            filePath,
            onReceiveProgress: (received, total) {
              if (total != -1) {
                final fileProgress = received / total;
                final overallProgress = (completedFiles + fileProgress) / essentialFiles.length;
                onProgress(
                  0.1 + (overallProgress * 0.8), // 10% to 90%
                  'Downloading $fileName... ${(fileProgress * 100).toStringAsFixed(1)}%',
                );
              }
            },
            options: Options(
              followRedirects: true,
              maxRedirects: 5,
              receiveTimeout: const Duration(minutes: 10),
            ),
          );

          completedFiles++;
          onProgress(
            0.1 + (completedFiles / essentialFiles.length * 0.8),
            'Downloaded $fileName successfully',
          );
        } catch (e) {
          print('Warning: Could not download $fileName - $e');
          // Continue with other files, some may not exist for all models
        }
      }

      // Verify we got the essential files
      final String mainModelPath = path.join(modelDir, 'pytorch_model.bin');
      final String configPath = path.join(modelDir, 'config.json');

      if (!await File(mainModelPath).exists()) {
        throw Exception('Failed to download main model file (pytorch_model.bin)');
      }

      if (!await File(configPath).exists()) {
        throw Exception('Failed to download model configuration (config.json)');
      }

      onProgress(0.95, 'Creating model metadata...');

      // Create a metadata file for the downloaded model
      await _createModelMetadata(modelDir, repoInfo);

      onProgress(1.0, 'PyTorch model download completed!');

      return mainModelPath; // Return path to main model file
    } catch (e) {
      throw Exception('PyTorch model download failed: $e');
    }
  }

  Map<String, String>? _parseHuggingFaceUrl(String url) {
    try {
      // Handle different HuggingFace URL formats
      final uri = Uri.parse(url);
      
      if (uri.host == 'huggingface.co') {
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 2) {
          final String owner = pathSegments[0];
          final String model = pathSegments[1];
          return {
            'owner': owner,
            'model': model,
            'repo': '$owner/$model',
          };
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _createModelMetadata(String modelDir, Map<String, String> repoInfo) async {
    final metadata = {
      'format': 'PyTorch',
      'source': 'HuggingFace',
      'repository': repoInfo['repo'],
      'downloaded_at': DateTime.now().toIso8601String(),
      'files': await _listDownloadedFiles(modelDir),
      'note': 'This PyTorch model requires conversion to TorchScript (.ptl) for mobile inference',
    };

    final metadataFile = File(path.join(modelDir, 'model_metadata.json'));
    await metadataFile.writeAsString(json.encode(metadata));
  }

  Future<List<String>> _listDownloadedFiles(String modelDir) async {
    final Directory dir = Directory(modelDir);
    if (!await dir.exists()) return [];

    final files = await dir.list().toList();
    return files
        .whereType<File>()
        .map((f) => path.basename(f.path))
        .toList();
  }

  void dispose() {
    _dio.close();
  }
}

// Helper class for PyTorch model utilities
class PyTorchModelDetector {
  static bool isHuggingFacePyTorchUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host == 'huggingface.co' && 
             uri.pathSegments.length >= 2 &&
             !url.contains('.bin') &&
             !url.contains('.gguf') &&
             !url.contains('.ptl');
    } catch (e) {
      return false;
    }
  }

  static bool isPyTorchModelDirectory(String dirPath) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return false;

    final files = dir.listSync().map((f) => path.basename(f.path)).toList();
    return files.contains('pytorch_model.bin') && files.contains('config.json');
  }

  static String getModelNameFromPath(String modelPath) {
    final parentDir = path.dirname(modelPath);
    return path.basename(parentDir);
  }
}