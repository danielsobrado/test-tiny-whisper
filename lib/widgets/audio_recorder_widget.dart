import 'package:flutter/material.dart';

class AudioRecorderWidget extends StatefulWidget {
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
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
        if (widget.isRecording) ...[
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: const Icon(
                  Icons.mic,
                  size: 64,
                  color: Colors.red,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Listening Continuously - Speak Anytime',
            style: TextStyle(
              fontSize: 16,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ] else if (widget.isTranscribing) ...[
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
            onPressed: widget.isTranscribing 
                ? null 
                : (widget.isRecording ? widget.onStopRecording : widget.onStartRecording),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isRecording ? Colors.red : Colors.blue,
              foregroundColor: Colors.white,
            ),
            icon: Icon(
              widget.isRecording ? Icons.stop : Icons.mic,
              size: 24,
            ),
            label: Text(
              widget.isRecording ? 'Stop Listening' : 'Start Listening',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        Text(
          widget.isRecording 
              ? 'Listening continuously - tap Stop to finish'
              : 'Tap Start to begin live speech recognition',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}