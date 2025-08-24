import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
// import 'pytorch_model_downloader.dart';  // Temporarily disabled for Android build

class ModelDownloadService {
  final Dio _dio = Dio();
  // final PyTorchModelDownloader _pytorchDownloader = PyTorchModelDownloader();  // Temporarily disabled

  Future<String> downloadModel({
    required String url,
    required Function(double progress, String status) onProgress,
    String? replaceModelPath,
  }) async {
    try {
      // Check if this is a PyTorch model repository URL
      // Temporarily disabled for Android build
      // if (PyTorchModelDetector.isHuggingFacePyTorchUrl(url)) {
      //   return await _pytorchDownloader.downloadPyTorchModel(
      //     huggingFaceUrl: url,
      //     onProgress: onProgress,
      //   );
      // }
      // Get app documents directory
      final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
      final String modelsDir = path.join(appDocumentsDir.path, 'models');
      
      // Create models directory if it doesn't exist
      final Directory modelsDirPath = Directory(modelsDir);
      if (!await modelsDirPath.exists()) {
        await modelsDirPath.create(recursive: true);
      }

      String filePath;
      
      if (replaceModelPath != null) {
        // Replace existing model
        filePath = replaceModelPath;
        onProgress(0.0, 'Replacing existing model...');
      } else {
        // Extract filename from URL
        final Uri uri = Uri.parse(url);
        String fileName = path.basename(uri.path);
        
        // If no extension, try to determine format or default to .bin
        if (!fileName.contains('.')) {
          // Check if URL suggests GGUF format
          if (url.toLowerCase().contains('gguf')) {
            fileName = '$fileName.gguf';
          } else {
            fileName = '$fileName.bin'; // Default to GGML format
          }
        }

        // Check if a model with the same base name already exists
        final existingModel = await _findExistingModel(modelsDir, fileName);
        
        if (existingModel != null) {
          // Ask to replace or create new
          filePath = existingModel;
          onProgress(0.0, 'Replacing existing model with same name...');
        } else {
          // Generate unique filename to avoid conflicts
          final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          final String uniqueFileName = '${timestamp}_$fileName';
          filePath = path.join(modelsDir, uniqueFileName);
        }
      }

      onProgress(0.0, 'Connecting to server...');

      // Download with progress tracking
      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            final receivedMB = (received / (1024 * 1024)).toStringAsFixed(1);
            final totalMB = (total / (1024 * 1024)).toStringAsFixed(1);
            onProgress(
              progress,
              'Downloading: ${receivedMB}MB / ${totalMB}MB (${(progress * 100).toStringAsFixed(1)}%)',
            );
          } else {
            final receivedMB = (received / (1024 * 1024)).toStringAsFixed(1);
            onProgress(0.0, 'Downloaded: ${receivedMB}MB');
          }
        },
        options: Options(
          followRedirects: true,
          maxRedirects: 5,
          receiveTimeout: const Duration(minutes: 30),
          sendTimeout: const Duration(minutes: 5),
        ),
      );

      // Verify the file was downloaded
      final File downloadedFile = File(filePath);
      if (!await downloadedFile.exists()) {
        throw Exception('Download failed: File not found after download');
      }

      final int fileSize = await downloadedFile.length();
      if (fileSize == 0) {
        throw Exception('Download failed: Downloaded file is empty');
      }

      onProgress(1.0, 'Download completed: ${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB');

      return filePath;
    } on DioException catch (e) {
      String errorMessage;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          errorMessage = 'Connection timeout. Please check your internet connection.';
          break;
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Download timeout. The file might be too large.';
          break;
        case DioExceptionType.badResponse:
          errorMessage = 'Server error (${e.response?.statusCode}). Please check the URL.';
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'Connection error. Please check your internet connection.';
          break;
        default:
          errorMessage = 'Download failed: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<List<String>> getDownloadedModels() async {
    try {
      final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
      final String modelsDir = path.join(appDocumentsDir.path, 'models');
      final Directory modelsDirPath = Directory(modelsDir);

      if (!await modelsDirPath.exists()) {
        return [];
      }

      final List<FileSystemEntity> files = await modelsDirPath.list().toList();
      return files
          .where((file) => file is File && _isSupportedModelFile(file.path))
          .map((file) => file.path)
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteModel(String modelPath) async {
    try {
      final File modelFile = File(modelPath);
      if (await modelFile.exists()) {
        await modelFile.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete model: $e');
    }
  }

  Future<String> getModelInfo(String modelPath) async {
    try {
      final File modelFile = File(modelPath);
      if (!await modelFile.exists()) {
        return 'Model file not found';
      }

      final int fileSize = await modelFile.length();
      final String fileName = path.basename(modelPath);
      final String sizeString = (fileSize / (1024 * 1024)).toStringAsFixed(1);
      final DateTime lastModified = await modelFile.lastModified();

      final String format = getModelFormat(modelPath);
      return 'File: $fileName\nFormat: $format\nSize: ${sizeString}MB\nDownloaded: ${_formatDate(lastModified)}';
    } catch (e) {
      return 'Error reading model info: $e';
    }
  }

  Future<String?> _findExistingModel(String modelsDir, String fileName) async {
    try {
      final Directory modelsDirPath = Directory(modelsDir);
      if (!await modelsDirPath.exists()) {
        return null;
      }

      final List<FileSystemEntity> files = await modelsDirPath.list().toList();
      
      // Look for files that end with the same base filename
      for (final file in files) {
        if (file is File && _isSupportedModelFile(file.path)) {
          final existingFileName = path.basename(file.path);
          
          // Remove timestamp prefix if present
          String cleanExistingName = existingFileName;
          if (existingFileName.contains('_')) {
            final parts = existingFileName.split('_');
            if (parts.length > 1 && RegExp(r'^\d+$').hasMatch(parts[0])) {
              cleanExistingName = parts.sublist(1).join('_');
            }
          }
          
          if (cleanExistingName == fileName) {
            return file.path;
          }
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  bool _isSupportedModelFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    final fileName = path.basename(filePath).toLowerCase();
    return extension == '.bin' || 
           extension == '.gguf' || 
           extension == '.ptl' ||
           fileName == 'pytorch_model.bin' ||
           fileName.contains('config.json');
  }

  String getModelFormat(String modelPath) {
    final extension = path.extension(modelPath).toLowerCase();
    final fileName = path.basename(modelPath).toLowerCase();
    
    if (fileName == 'pytorch_model.bin' || extension == '.ptl') {
      return 'PyTorch';
    }
    
    switch (extension) {
      case '.bin':
        return 'GGML';
      case '.gguf':
        return 'GGUF';
      case '.ptl':
        return 'PyTorch';
      case '.json':
        return 'Config';
      default:
        return 'Unknown';
    }
  }

  bool isGGUFModel(String modelPath) {
    return path.extension(modelPath).toLowerCase() == '.gguf';
  }

  bool isGGMLModel(String modelPath) {
    return path.extension(modelPath).toLowerCase() == '.bin' && 
           path.basename(modelPath).toLowerCase() != 'pytorch_model.bin';
  }

  bool isPyTorchModel(String modelPath) {
    final extension = path.extension(modelPath).toLowerCase();
    final fileName = path.basename(modelPath).toLowerCase();
    return extension == '.ptl' || fileName == 'pytorch_model.bin';
  }

  void dispose() {
    _dio.close();
    // _pytorchDownloader.dispose();  // Temporarily disabled for Android build
  }
}