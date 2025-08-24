import 'package:flutter/material.dart';

class AudioRecorderWidget extends StatelessWidget {
  final bool isRecording;
  final bool isTranscribing;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;

  const AudioRecorderWidget({
    super.key,
    required this.isRecording,
    required this.isTranscribing,
    required this.onStartRecording,
    required this.onStopRecording,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Audio Recording',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        
        // Recording Status
        if (isRecording) ...[
          const Icon(
            Icons.mic,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          const Text(
            'Recording...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ] else if (isTranscribing) ...[
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(),
          ),
          const SizedBox(height: 12),
          const Text(
            'Transcribing...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ] else ...[
          const Icon(
            Icons.mic_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          const Text(
            'Ready to record',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
        
        const SizedBox(height: 20),
        
        // Recording Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: isTranscribing 
                ? null 
                : (isRecording ? onStopRecording : onStartRecording),
            style: ElevatedButton.styleFrom(
              backgroundColor: isRecording ? Colors.red : Colors.blue,
              foregroundColor: Colors.white,
            ),
            icon: Icon(
              isRecording ? Icons.stop : Icons.mic,
              size: 24,
            ),
            label: Text(
              isRecording ? 'Stop Recording' : 'Start Recording',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        const Text(
          'Tap and hold to record, release to transcribe',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}