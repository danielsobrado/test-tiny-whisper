import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'dart:math' as math;

class AudioVisualizerWidget extends StatefulWidget {
  final bool isListening;
  final double soundLevel;
  
  const AudioVisualizerWidget({
    super.key,
    required this.isListening,
    required this.soundLevel,
  });

  @override
  State<AudioVisualizerWidget> createState() => _AudioVisualizerWidgetState();
}

class _AudioVisualizerWidgetState extends State<AudioVisualizerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late RecorderController _recorderController;
  List<double> _frequencyBands = [];
  final int _frequencyBandCount = 8;
  double _simulatedLevel = 0.0;
  DateTime _lastUpdateTime = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    // Initialize audio waveform recorder
    _recorderController = RecorderController();
    _frequencyBands = List.filled(_frequencyBandCount, 0.0);
    
    // Start animation and recording if listening
    if (widget.isListening) {
      _animationController.repeat();
      _startAudioVisualization();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _recorderController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AudioVisualizerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle listening state changes
    if (widget.isListening != oldWidget.isListening) {
      if (widget.isListening) {
        _animationController.repeat();
        _startAudioVisualization();
      } else {
        _animationController.stop();
        _stopAudioVisualization();
        // Reset frequency bands when stopping
        setState(() {
          _frequencyBands = List.filled(_frequencyBandCount, 0.0);
          _simulatedLevel = 0.0;
        });
      }
    }
    
    if (widget.isListening && widget.soundLevel != oldWidget.soundLevel) {
      _updateAudioLevel(widget.soundLevel);
    }
  }

  void _updateAudioLevel(double level) {
    // Normalize the level and update frequency bands
    double normalizedLevel = math.max(0.0, math.min(1.0, level / 100.0));
    _updateFrequencyBands(normalizedLevel);
  }
  
  Future<void> _startAudioVisualization() async {
    try {
      // Don't start actual recording to avoid conflict with speech recognition
      // Use simulated visualization instead to prevent microphone conflicts
      print('Using simulated audio visualization to avoid microphone conflict');
      _startSimulatedVisualization();
    } catch (e) {
      print('Failed to start audio visualization: $e');
      // Fall back to simulated visualization
      _startSimulatedVisualization();
    }
  }

  Future<void> _stopAudioVisualization() async {
    try {
      if (_recorderController.isRecording) {
        await _recorderController.stop();
        print('Audio waveform recording stopped');
      }
    } catch (e) {
      print('Failed to stop audio waveform recording: $e');
    }
  }
  
  void _startSimulatedVisualization() {
    // Fallback: Create a periodic timer to simulate audio levels
    _animationController.addListener(() {
      if (widget.isListening && mounted) {
        DateTime now = DateTime.now();
        
        // Generate simulated realistic audio level
        double time = now.millisecondsSinceEpoch / 1000.0;
        _simulatedLevel = 0.3 + 0.4 * math.sin(time * 2.0) * math.sin(time * 0.7) + 
                         0.2 * math.sin(time * 5.0) * math.cos(time * 1.3);
        _simulatedLevel = math.max(0.0, math.min(1.0, _simulatedLevel));
        
        // Only update if enough time has passed
        if (now.difference(_lastUpdateTime).inMilliseconds > 100) {
          _updateAudioLevel(_simulatedLevel * 100);
          _lastUpdateTime = now;
        }
      }
    });
  }

  void _updateFrequencyBands(double currentLevel) {
    for (int i = 0; i < _frequencyBandCount; i++) {
      // Create more realistic frequency distribution
      double targetLevel;
      if (currentLevel == 0.0) {
        targetLevel = 0.0;
      } else {
        // Different frequencies respond differently
        double baseLevel = currentLevel * 0.8;
        double variation = currentLevel * 0.4 * math.sin((DateTime.now().millisecondsSinceEpoch / 200.0) + i * 0.5);
        targetLevel = math.max(0.0, math.min(1.0, baseLevel + variation.abs()));
        
        // Lower frequencies (0-2) are usually stronger in speech
        if (i < 3) {
          targetLevel *= 1.1;
        }
        // Higher frequencies (6-7) are usually weaker
        if (i > 5) {
          targetLevel *= 0.7;
        }
      }
      
      // Smooth transition to avoid blinking
      double smoothingFactor = 0.3;
      _frequencyBands[i] = (_frequencyBands[i] * (1.0 - smoothingFactor)) + (targetLevel * smoothingFactor);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.isListening ? Colors.black12 : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isListening ? Colors.red.withOpacity(0.3) : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: widget.isListening 
          ? _buildActiveVisualizer()
          : _buildInactiveVisualizer(),
    );
  }

  Widget _buildActiveVisualizer() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          const Text(
            'Voice Spectrogram',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                // Waveform display - using simulated to avoid microphone conflicts
                Expanded(
                  flex: 2,
                  child: _buildSimulatedWaveform(),
                ),
                const SizedBox(width: 8),
                // Frequency bars
                Expanded(
                  flex: 1,
                  child: _buildFrequencyBars(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          _buildVolumeIndicator(),
        ],
      ),
    );
  }

  Widget _buildInactiveVisualizer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.graphic_eq,
                size: 24,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.show_chart,
                size: 24,
                color: Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Voice Spectrogram',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Real-time audio visualization',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          // Show preview of inactive bars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(8, (index) {
              return Container(
                width: 4,
                height: 8 + (index % 3) * 4,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRealWaveform() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: AudioWaveforms(
        size: Size(double.infinity, 80),
        recorderController: _recorderController,
        enableGesture: false,
        waveStyle: const WaveStyle(
          waveColor: Colors.red,
          extendWaveform: true,
          showMiddleLine: true,
          middleLineColor: Colors.grey,
          middleLineThickness: 1,
          waveThickness: 2,
          waveCap: StrokeCap.round,
        ),
      ),
    );
  }

  Widget _buildWaveformChart() {
    // Fallback chart for when audio_waveforms isn't available
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          'Audio Waveform\n(Real-time visualization)',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFrequencyBars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: _frequencyBands.asMap().entries.map((entry) {
        int index = entry.key;
        double level = entry.value;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200), // Slower animation to reduce blinking
          width: 6,
          height: math.max(5.0, level * 60), // Min height of 5, max of 65
          decoration: BoxDecoration(
            color: level > 0.7 ? Colors.red :
                   level > 0.4 ? Colors.orange :
                   level > 0.2 ? Colors.yellow : 
                   level > 0.05 ? Colors.green : Colors.grey[400]!,
            borderRadius: BorderRadius.circular(3),
            boxShadow: level > 0.1 ? [
              BoxShadow(
                color: (level > 0.7 ? Colors.red : Colors.orange).withOpacity(0.2),
                blurRadius: 1,
                spreadRadius: 0.5,
              ),
            ] : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVolumeIndicator() {
    double currentLevel = widget.soundLevel / 100.0;
    return Row(
      children: [
        const Text(
          'Level: ',
          style: TextStyle(fontSize: 10, color: Colors.grey),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: currentLevel,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              currentLevel > 0.7 ? Colors.red : 
              currentLevel > 0.3 ? Colors.orange : Colors.green,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(currentLevel * 100).toInt()}%',
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        const SizedBox(width: 8),
        const Text(
          '🎤',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}