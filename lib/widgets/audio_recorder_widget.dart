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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.mic_rounded,
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Audio Recording',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Recording Status with modern design
        Container(
          height: 120,
          width: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getStatusBackgroundColor(colorScheme),
          ),
          child: Center(
            child: _buildStatusIcon(colorScheme),
          ),
        ),
        
        const SizedBox(height: 16),
        
        Text(
          _getStatusText(),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: _getStatusTextColor(colorScheme),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 24),
        
        // Modern Recording Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: widget.isTranscribing 
                ? null 
                : (widget.isRecording ? widget.onStopRecording : widget.onStartRecording),
            style: FilledButton.styleFrom(
              backgroundColor: widget.isRecording 
                  ? colorScheme.error
                  : colorScheme.primary,
              foregroundColor: widget.isRecording
                  ? colorScheme.onError
                  : colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: widget.isRecording ? 2 : 1,
            ),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                widget.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                size: 24,
                key: ValueKey(widget.isRecording),
              ),
            ),
            label: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                widget.isRecording ? 'Stop Listening' : 'Start Listening',
                style: theme.textTheme.labelLarge,
                key: ValueKey(widget.isRecording),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        Text(
          widget.isRecording 
              ? 'Listening continuously - tap Stop to finish'
              : 'Tap Start to begin live speech recognition',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatusIcon(ColorScheme colorScheme) {
    if (widget.isRecording) {
      return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Icon(
              Icons.mic_rounded,
              size: 48,
              color: colorScheme.error,
            ),
          );
        },
      );
    } else if (widget.isTranscribing) {
      return SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          color: colorScheme.primary,
          strokeWidth: 3,
        ),
      );
    } else {
      return Icon(
        Icons.mic_off_rounded,
        size: 48,
        color: colorScheme.onSurfaceVariant,
      );
    }
  }

  Color _getStatusBackgroundColor(ColorScheme colorScheme) {
    if (widget.isRecording) {
      return colorScheme.errorContainer;
    } else if (widget.isTranscribing) {
      return colorScheme.primaryContainer;
    } else {
      return colorScheme.surfaceContainerHighest;
    }
  }

  Color _getStatusTextColor(ColorScheme colorScheme) {
    if (widget.isRecording) {
      return colorScheme.error;
    } else if (widget.isTranscribing) {
      return colorScheme.primary;
    } else {
      return colorScheme.onSurfaceVariant;
    }
  }

  String _getStatusText() {
    if (widget.isRecording) {
      return 'Listening Continuously - Speak Anytime';
    } else if (widget.isTranscribing) {
      return 'Transcribing...';
    } else {
      return 'Ready to record';
    }
  }
}