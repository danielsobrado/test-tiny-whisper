import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TranscriptionDisplayWidget extends StatelessWidget {
  final String transcriptionText;

  const TranscriptionDisplayWidget({
    super.key,
    required this.transcriptionText,
  });

  void _copyToClipboard(BuildContext context) {
    if (transcriptionText.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: transcriptionText));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transcription copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Transcription',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (transcriptionText.isNotEmpty)
              IconButton(
                onPressed: () => _copyToClipboard(context),
                icon: const Icon(Icons.copy),
                tooltip: 'Copy to clipboard',
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: SingleChildScrollView(
              child: Text(
                transcriptionText.isEmpty 
                    ? 'Transcription will appear here...'
                    : transcriptionText,
                style: TextStyle(
                  fontSize: 16,
                  color: transcriptionText.isEmpty 
                      ? Colors.grey[600] 
                      : Colors.black,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
        
        if (transcriptionText.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                'Length: ${transcriptionText.length} characters',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}